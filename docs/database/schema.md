# Secure SoR — Database Schema

This document defines the **logical schema** for the Secure SoR database. It is the source of truth for table and column definitions. The **runnable SQL** that implements this schema for Supabase is in [supabase-schema.sql](./supabase-schema.sql).

**Architecture:** [../architecture/architecture.md](../architecture/architecture.md) — Phase 1 (Supabase) entity list and invariants.

**Invariants (from architecture):**

- Every account-scoped row includes `account_id`.
- Documents are never stored as binary in the DB; use `documents` + storage bucket.
- Evidence is always linked via `evidence_attachments` (record ↔ document).
- Audit events record actor + timestamp.

---

## 1. How to create the DB (Supabase)

1. **Create a Supabase project** at [supabase.com](https://supabase.com) (Sign in → New project → choose org, name, password, region).
2. **Open the SQL Editor** in the Supabase dashboard (left sidebar → SQL Editor).
3. **Run the schema:** copy the contents of [supabase-schema.sql](./supabase-schema.sql) into a new query and click **Run**. This creates all tables, indexes, and RLS policies.
4. **Create the storage bucket:** Storage → New bucket → name: `secure-documents`, set to **Private** (RLS will control access).
5. **Optional:** Store your project URL and anon key in env (e.g. `.env.local` in the Lovable app) as `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` so the app can connect.

To **reset** and re-run: drop tables in reverse dependency order (or drop schema public and recreate), then run the SQL again. Prefer using **Supabase migrations** (e.g. `supabase migration new init`) and pasting the SQL into the generated file for versioned changes.

---

### 1.1 Post sign-up flow (Lovable integration)

Supabase Auth creates the user; the `handle_new_user` trigger creates a row in `profiles`. For the user to see and create account-scoped data (properties, spaces, systems, etc.), the **app must** create a row in `accounts` and one in `account_memberships`. Because RLS requires membership to read accounts (chicken-and-egg for the first account), the **Lovable app does this via a Supabase Edge Function** `create-account` that uses the **service role** client to bypass RLS and insert into both tables. The Edge Function validates the user's JWT, checks name uniqueness via `check_account_name_exists`, then inserts and returns the account. **RLS policy:** There are **no permissive INSERT policies** for `accounts` or `account_memberships` for authenticated clients — creation is exclusively via the Edge Function, which hardens security. All policies are PERMISSIVE (not RESTRICTIVE) so that SELECT/UPDATE/DELETE work as intended. Security-definer functions (`check_account_name_exists`, `handle_new_user`) use `SET search_path = public` to avoid search-path hijacking. Until both rows exist, RLS will block access to `properties`, `systems`, `data_library_records`, etc.

---

## 2. Table Overview

| Table                  | Purpose                                      | Account-scoped |
|------------------------|----------------------------------------------|----------------|
| profiles               | User profile (extends Supabase Auth)         | No (user-scoped) |
| accounts               | Tenant/organisation                          | —              |
| account_memberships    | User ↔ Account, role                         | Yes (via account_id) |
| properties             | Property (building)                          | Yes            |
| spaces                 | Space within a property                      | Via property   |
| systems                | Building system (HVAC, Power, etc.)          | Yes            |
| meters                 | Meter (first-class)                          | Yes            |
| end_use_nodes          | End-use node linked to system                | Yes            |
| data_library_records    | Data Library record                          | Yes            |
| documents              | Stored file metadata (file in bucket)        | Yes            |
| evidence_attachments    | Links record ↔ document                      | Via record     |
| agent_runs             | One agent invocation                         | Yes            |
| agent_findings         | Findings from one run                        | Via run        |
| audit_events            | Append-only audit log                         | Yes            |

---

## 3. Table Definitions

### 3.1 profiles

Extends Supabase `auth.users`. One row per user.

| Column       | Type      | Nullable | Description |
|-------------|-----------|----------|-------------|
| id          | uuid      | NO       | PK; = auth.users.id |
| display_name| text      | YES      | Display name |
| avatar_url  | text      | YES      | Profile image URL |
| created_at  | timestamptz | NO    | |
| updated_at  | timestamptz | NO    | |

---

### 3.2 accounts

Top-level tenant (organisation). No `account_id` on this table.

| Column              | Type      | Nullable | Description |
|--------------------|-----------|----------|-------------|
| id                 | uuid      | NO       | PK |
| name               | text      | NO       | Account name |
| account_type       | text      | NO       | `corporate_occupier` \| `asset_manager` |
| enabled_modules    | text[]    | YES      | Module list |
| reporting_boundary | jsonb     | YES      | { reportingYear, reportingPeriodStart, reportingPeriodEnd, boundaryApproach, includedPropertyIds, ... } |
| created_at         | timestamptz | NO    | |
| updated_at         | timestamptz | NO    | |

**RLS:** SELECT for members; UPDATE for admins. **No client INSERT** — creation is only via the `create-account` Edge Function (service role).

---

### 3.3 account_memberships

User membership in an account (role).

| Column      | Type      | Nullable | Description |
|------------|-----------|----------|-------------|
| id         | uuid      | NO       | PK |
| account_id | uuid      | NO       | FK → accounts.id |
| user_id    | uuid      | NO       | FK → auth.users.id |
| role       | text      | NO       | `admin` \| `member` \| `viewer` |
| created_at | timestamptz | NO    | |
| updated_at | timestamptz | NO    | |

Unique on `(account_id, user_id)`.

**RLS:** SELECT for own memberships; UPDATE/DELETE for admins in their account. **No client INSERT** — rows are created only by the `create-account` Edge Function (service role).

**RPC (Lovable):** `check_account_name_exists(account_name text)` — returns true if an account with that name exists (case-insensitive). Used during onboarding to warn if the org is already registered. Implemented in [supabase-schema.sql](./supabase-schema.sql) as `SECURITY DEFINER` with `SET search_path = public`.

---

### 3.4 properties

Property (building/site). Account-scoped.

| Column      | Type      | Nullable | Description |
|------------|-----------|----------|-------------|
| id         | uuid      | NO       | PK |
| account_id | uuid      | NO       | FK → accounts.id |
| name       | text      | NO       | |
| address    | text      | YES      | |
| country    | text      | YES      | |
| floors     | jsonb     | YES      | Array of floor identifiers |
| total_area | numeric   | YES      | |
| created_at | timestamptz | NO    | |
| updated_at | timestamptz | NO    | |

---

### 3.5 spaces

Space within a property. References property.

| Column           | Type      | Nullable | Description |
|-----------------|-----------|----------|-------------|
| id              | uuid      | NO       | PK |
| property_id     | uuid      | NO       | FK → properties.id |
| name            | text      | NO       | |
| space_class     | text      | NO       | `tenant` \| `base_building` |
| control         | text      | NO       | `landlord_controlled` \| `tenant_controlled` \| `shared` |
| space_type      | text      | YES      | |
| area            | numeric   | YES      | |
| floor_reference | text      | YES      | |
| in_scope        | boolean   | NO       | Default true |
| net_zero_included| boolean   | YES      | |
| gresb_reporting | boolean   | YES      | |
| created_at      | timestamptz | NO    | |
| updated_at      | timestamptz | NO    | |

---

### 3.6 systems

Building system (HVAC, Power, Lighting, etc.). Taxonomy: [data-model/building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md).

| Column            | Type      | Nullable | Description |
|-------------------|-----------|----------|-------------|
| id                | uuid      | NO       | PK |
| account_id        | uuid      | NO       | FK → accounts.id (for RLS) |
| property_id       | uuid      | NO       | FK → properties.id |
| name              | text      | NO       | |
| system_category   | text      | NO       | Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring, Other |
| system_type       | text      | YES      | e.g. GridLVSupply, Boilers, TenantLighting |
| space_class       | text      | YES      | `tenant` \| `base_building` |
| controlled_by     | text      | NO       | `tenant` \| `landlord` \| `shared` |
| maintained_by     | text      | YES      | |
| metering_status   | text      | NO       | `none` \| `partial` \| `full` |
| allocation_method | text      | NO       | `measured` \| `area` \| `estimated` |
| allocation_notes  | text      | YES      | |
| serves_space_ids  | uuid[]    | YES      | Array of space.id |
| created_at        | timestamptz | NO    | |
| updated_at        | timestamptz | NO    | |

---

### 3.7 meters

First-class meter entity. Can be linked to a system.

| Column       | Type      | Nullable | Description |
|-------------|-----------|----------|-------------|
| id          | uuid      | NO       | PK |
| account_id  | uuid      | NO       | FK → accounts.id |
| property_id | uuid      | NO       | FK → properties.id |
| system_id   | uuid      | YES      | FK → systems.id (nullable) |
| name        | text      | NO       | |
| meter_type  | text      | YES      | e.g. electricity, gas, water |
| unit        | text      | YES      | e.g. kWh, m³ |
| external_id | text      | YES      | Supplier/meter ID |
| created_at  | timestamptz | NO    | |
| updated_at  | timestamptz | NO    | |

---

### 3.8 end_use_nodes

End-use node linked to a system. Taxonomy: nodeCategory, utilityType in [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md).

| Column               | Type      | Nullable | Description |
|----------------------|-----------|----------|-------------|
| id                   | uuid      | NO       | PK |
| account_id           | uuid      | NO       | FK → accounts.id |
| property_id          | uuid      | NO       | FK → properties.id |
| system_id            | uuid      | NO       | FK → systems.id |
| node_id              | text      | NO       | Business key (e.g. E_TENANT_PLUG) |
| node_category        | text      | NO       | e.g. tenant_plug_load, tenant_lighting |
| utility_type         | text      | NO       | electricity, heating, cooling, water, waste, occupancy, access |
| control_override     | text      | YES      | TENANT \| LANDLORD \| SHARED |
| allocation_weight    | numeric   | YES      | 0..1 |
| applies_to_space_ids  | uuid[]    | YES      | |
| notes                | text      | YES      | |
| created_at           | timestamptz | NO    | |
| updated_at           | timestamptz | NO    | |

Unique on `(property_id, node_id)`.

---

### 3.9 data_library_records

Data Library record (utility, evidence, governance, etc.). Evidence linked via `evidence_attachments`.

| Column                 | Type      | Nullable | Description |
|------------------------|-----------|----------|-------------|
| id                     | uuid      | NO       | PK |
| account_id             | uuid      | NO       | FK → accounts.id |
| property_id            | uuid      | YES      | FK → properties.id (nullable for account-level) |
| subject_category       | text      | NO       | e.g. scope2, waste, policy |
| data_type              | text      | YES      | |
| value_numeric          | numeric   | YES      | |
| value_text             | text      | YES      | |
| unit                   | text      | YES      | |
| reporting_period_start | date      | YES      | |
| reporting_period_end   | date      | YES      | |
| source_type            | text      | NO       | `connector` \| `upload` \| `manual` |
| confidence              | text      | YES      | measured \| allocated \| estimated |
| allocation_method      | text      | YES      | |
| allocation_notes       | text      | YES      | |
| created_at             | timestamptz | NO    | |
| updated_at             | timestamptz | NO    | |

---

### 3.10 documents

Metadata for a file stored in Supabase Storage. **No binary in DB.**

| Column          | Type      | Nullable | Description |
|-----------------|-----------|----------|-------------|
| id              | uuid      | NO       | PK |
| account_id      | uuid      | NO       | FK → accounts.id |
| storage_path    | text      | NO       | Key in bucket (e.g. account/{id}/property/{id}/2026/02/{docId}-file.pdf) |
| file_name       | text      | NO       | Original filename |
| mime_type       | text      | YES      | |
| file_size_bytes | bigint    | YES      | |
| created_at      | timestamptz | NO    | |
| updated_at      | timestamptz | NO    | |

Storage path format (invariant): `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}`.

---

### 3.11 evidence_attachments

Links a Data Library record to a document. Many-to-many possible (one record, many docs).

| Column                 | Type      | Nullable | Description |
|------------------------|-----------|----------|-------------|
| id                     | uuid      | NO       | PK |
| data_library_record_id | uuid      | NO       | FK → data_library_records.id |
| document_id            | uuid      | NO       | FK → documents.id |
| created_at             | timestamptz | NO    | |

Unique on `(data_library_record_id, document_id)`.

---

### 3.12 agent_runs

One invocation of an agent (e.g. Data Readiness, Boundary).

| Column          | Type      | Nullable | Description |
|-----------------|-----------|----------|-------------|
| id              | uuid      | NO       | PK |
| account_id      | uuid      | NO       | FK → accounts.id |
| property_id     | uuid      | YES      | FK → properties.id (nullable) |
| agent_type     | text      | NO       | `data_readiness` \| `boundary` |
| status         | text      | NO       | `pending` \| `completed` \| `failed` |
| context_snapshot| jsonb     | YES      | Input context (optional, for audit) |
| created_by      | uuid      | YES      | auth.users.id |
| created_at      | timestamptz | NO    | |
| updated_at      | timestamptz | NO    | |

---

### 3.13 agent_findings

Findings produced by one agent run. Payload is agent-specific JSON.

| Column       | Type      | Nullable | Description |
|-------------|-----------|----------|-------------|
| id          | uuid      | NO       | PK |
| agent_run_id| uuid      | NO       | FK → agent_runs.id |
| finding_type| text      | YES      | e.g. controllability, scope_readiness |
| payload     | jsonb     | NO       | Agent output payload |
| created_at  | timestamptz | NO    | |

---

### 3.14 audit_events

Append-only audit log. Before/after state for traceability.

| Column      | Type      | Nullable | Description |
|------------|-----------|----------|-------------|
| id         | uuid      | NO       | PK |
| account_id | uuid      | NO       | FK → accounts.id |
| entity_type| text      | NO       | e.g. data_library_records, systems |
| entity_id   | uuid      | NO       | Target row id |
| action     | text      | NO       | `create` \| `update` \| `delete` |
| actor_id   | uuid      | YES      | auth.users.id |
| before_state| jsonb     | YES      | |
| after_state | jsonb     | YES      | |
| created_at | timestamptz | NO    | |

---

## 4. Relationships (ER summary)

- **accounts** ← account_memberships (user_id → auth.users)
- **accounts** ← properties ← spaces
- **accounts** ← properties ← systems ← end_use_nodes
- **accounts** ← properties ← meters (optional system_id → systems)
- **accounts** ← data_library_records (optional property_id)
- **data_library_records** ← evidence_attachments → documents
- **accounts** ← agent_runs ← agent_findings
- **accounts** ← audit_events

All account-scoped tables are protected by RLS so that `auth.uid()` is required and rows are filtered by membership in the row’s `account_id`.

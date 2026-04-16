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


| Table                | Purpose                                            | Account-scoped       |
| -------------------- | -------------------------------------------------- | -------------------- |
| profiles             | User profile (extends Supabase Auth)               | No (user-scoped)     |
| accounts             | Tenant/organisation                                | —                    |
| account_memberships  | User ↔ Account, role                               | Yes (via account_id) |
| properties           | Property (building)                                | Yes                  |
| dc_metadata          | Data centre metadata (one row per DC property)     | Yes                  |
| sitdeck_risk_config  | SitDeck risk widgets enabled per property          | Yes                  |
| risk_diagnosis       | Risk assessment snapshot per property (DC)         | Yes                  |
| physical_risk_flags  | Physical risk flags (SitDeck / manual / agent)     | Via risk_diagnosis   |
| spaces               | Space within a property                            | Via property         |
| systems              | Building system (HVAC, Power, etc.)                | Yes                  |
| meters               | Meter (first-class)                                | Yes                  |
| end_use_nodes        | End-use node linked to system                      | Yes                  |
| data_library_records | Data Library record                                | Yes                  |
| documents            | Stored file metadata (file in bucket)              | Yes                  |
| evidence_attachments | Links record ↔ document                            | Via record           |
| agent_runs           | One agent invocation                               | Yes                  |
| agent_findings       | Findings from agent runs or SitDeck webhooks       | Yes (`account_id`)   |
| audit_events         | Append-only audit log                              | Yes                  |
| at_floors            | Asset Tracking: floor plans / levels per property  | Yes                  |
| at_zones             | Asset Tracking: zone polygons on a floor           | Yes                  |
| at_asset_types       | Asset Tracking: account / property asset taxonomy  | Yes                  |
| at_assets            | Asset Tracking: trackable instances                | Yes                  |
| at_asset_tags        | Asset Tracking: Wirepas tags (not `systems`)       | Yes                  |
| at_gateways          | Asset Tracking: Wirepas gateways                   | Yes                  |
| at_position_events   | Asset Tracking: position time series (append-only) | Yes                  |
| at_alerts            | Asset Tracking: alerts (status transitions)        | Yes                  |
| at_device_state      | Asset Tracking: DALI live state per `systems` row  | Yes                  |
| at_dali_commands     | Asset Tracking: DALI command queue                 | Yes                  |
| at_facility_settings | Asset Tracking: thresholds per property            | Yes                  |


**Spec:** [secure-asset-tracking-spec-v2.0.md](../specs/secure-asset-tracking-spec-v2.0.md). **Migrations:** [migrations/](migrations/) files prefixed `add-at-`, `create-at-`, `extend-systems-type-dalilight`, `seed-at-asset-types-mining`.

---

## 3. Table Definitions

### 3.1 profiles

Extends Supabase `auth.users`. One row per user.


| Column       | Type        | Nullable | Description         |
| ------------ | ----------- | -------- | ------------------- |
| id           | uuid        | NO       | PK; = auth.users.id |
| display_name | text        | YES      | Display name        |
| avatar_url   | text        | YES      | Profile image URL   |
| created_at   | timestamptz | NO       |                     |
| updated_at   | timestamptz | NO       |                     |


---

### 3.2 accounts

Top-level tenant (organisation). No `account_id` on this table.


| Column             | Type        | Nullable | Description                                                                                             |
| ------------------ | ----------- | -------- | ------------------------------------------------------------------------------------------------------- |
| id                 | uuid        | NO       | PK                                                                                                      |
| name               | text        | NO       | Account name                                                                                            |
| account_type       | text        | NO       | `corporate_occupier` | `asset_manager`                                                                  |
| enabled_modules    | text[]      | YES      | Module list                                                                                             |
| reporting_boundary | jsonb       | YES      | { reportingYear, reportingPeriodStart, reportingPeriodEnd, boundaryApproach, includedPropertyIds, ... } |
| created_at         | timestamptz | NO       |                                                                                                         |
| updated_at         | timestamptz | NO       |                                                                                                         |


**RLS:** SELECT for members; UPDATE for admins. **No client INSERT** — creation is only via the `create-account` Edge Function (service role).

---

### 3.3 account_memberships

User membership in an account (role).


| Column     | Type        | Nullable | Description                   |
| ---------- | ----------- | -------- | ----------------------------- |
| id         | uuid        | NO       | PK                            |
| account_id | uuid        | NO       | FK → accounts.id              |
| user_id    | uuid        | NO       | FK → auth.users.id            |
| role       | text        | NO       | `admin` | `member` | `viewer` |
| created_at | timestamptz | NO       |                               |
| updated_at | timestamptz | NO       |                               |


Unique on `(account_id, user_id)`.

**RLS:** SELECT for own memberships; UPDATE/DELETE for admins in their account. **No client INSERT** — rows are created only by the `create-account` Edge Function (service role).

**RPC (Lovable):** `check_account_name_exists(account_name text)` — returns true if an account with that name exists (case-insensitive). Used during onboarding to warn if the org is already registered. Implemented in [supabase-schema.sql](./supabase-schema.sql) as `SECURITY DEFINER` with `SET search_path = public`.

---

### 3.4 properties

Property (building/site). Account-scoped.


| Column             | Type        | Nullable | Description                                                                                                                                            |
| ------------------ | ----------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| id                 | uuid        | NO       | PK                                                                                                                                                     |
| account_id         | uuid        | NO       | FK → accounts.id                                                                                                                                       |
| name               | text        | NO       |                                                                                                                                                        |
| address            | text        | YES      | Street/address line                                                                                                                                    |
| city               | text        | YES      | City                                                                                                                                                   |
| region             | text        | YES      | Region / state                                                                                                                                         |
| postcode           | text        | YES      | Postcode / ZIP                                                                                                                                         |
| country            | text        | YES      |                                                                                                                                                        |
| nla                | text        | YES      | Net lettable area (or similar)                                                                                                                         |
| asset_type         | text        | YES      | e.g. Office, Retail, Industrial; Lovable may default to `'Office'`                                                                                     |
| year_built         | integer     | YES      | Year built (4-digit)                                                                                                                                   |
| last_renovation    | integer     | YES      | Year of last major renovation (4-digit)                                                                                                                |
| operational_status | text        | YES      | e.g. operational, under_construction, vacant                                                                                                           |
| occupancy_scope    | text        | YES      | Tenant footprint: `whole_building` | `partial_building` (spaces subpage)                                                                               |
| floors             | jsonb       | YES      | All floor identifiers in the building (property overview)                                                                                              |
| floors_in_scope    | jsonb       | YES      | Subset of floors the tenant occupies; saved from "Floors in Scope" tile (spaces subpage)                                                               |
| in_scope_area      | numeric     | YES      | Tenant footprint area (e.g. m²); editable in Floors in Scope tile (migration: add-property-in-scope-area.sql)                                          |
| total_area         | numeric     | YES      |                                                                                                                                                        |
| latitude           | numeric     | YES      | Property latitude for maps and SitDeck widgets (migration: add-properties-lat-lng.sql)                                                                 |
| longitude          | numeric     | YES      | Property longitude for maps and SitDeck widgets (migration: add-properties-lat-lng.sql)                                                                |
| at_enabled         | boolean     | NO       | Default false; when true, Asset Tracking is active for this facility ([add-at-enabled-to-properties.sql](migrations/add-at-enabled-to-properties.sql)) |
| created_at         | timestamptz | NO       |                                                                                                                                                        |
| updated_at         | timestamptz | NO       |                                                                                                                                                        |


**Migration (existing DBs):** If `properties` was created before these updates, add columns in SQL Editor: `ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS city text, ADD COLUMN IF NOT EXISTS region text, ADD COLUMN IF NOT EXISTS postcode text, ADD COLUMN IF NOT EXISTS nla text, ADD COLUMN IF NOT EXISTS asset_type text DEFAULT 'Office', ADD COLUMN IF NOT EXISTS year_built integer, ADD COLUMN IF NOT EXISTS last_renovation integer, ADD COLUMN IF NOT EXISTS operational_status text, ADD COLUMN IF NOT EXISTS occupancy_scope text, ADD COLUMN IF NOT EXISTS floors_in_scope jsonb;` For latitude/longitude: see [add-properties-lat-lng.sql](./migrations/add-properties-lat-lng.sql).

---

### 3.4a dc_metadata

Data centre–specific metadata. One row per property with `asset_type = 'data_centre'`. Spec: [docs/specs/secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §2.2.


| Column                           | Type        | Nullable | Description                                        |
| -------------------------------- | ----------- | -------- | -------------------------------------------------- |
| id                               | uuid        | NO       | PK                                                 |
| account_id                       | uuid        | NO       | FK → accounts.id                                   |
| property_id                      | uuid        | NO       | FK → properties.id (UNIQUE)                        |
| tier_level                       | text        | YES      | Uptime Institute Tier (I | II | III | IV)          |
| design_capacity_mw               | numeric     | YES      | Total IT load capacity (MW)                        |
| current_it_load_mw               | numeric     | YES      | Live or last-known IT load (MW)                    |
| total_white_floor_sqm            | numeric     | YES      | Total raised floor / white floor area              |
| cooling_type                     | text[]      | YES      | air_cooled | liquid_cooled | hybrid | free_cooling |
| power_supply_redundancy          | text        | YES      | N | N+1 | 2N | 2N+1                                |
| target_pue                       | numeric     | YES      | Design or target PUE (e.g. 1.3)                    |
| renewable_energy_pct             | numeric     | YES      | % of power from renewables (0–100)                 |
| water_usage_effectiveness_target | numeric     | YES      | Target WUE (L/kWh)                                 |
| certifications                   | text[]      | YES      | ISO 50001 | ISO 14001 | LEED | BREEAM | EU CoC     |
| sitdeck_site_id                  | text        | YES      | SitDeck site identifier                            |
| created_at                       | timestamptz | NO       |                                                    |
| updated_at                       | timestamptz | NO       |                                                    |


**RLS:** account-scoped (SELECT, INSERT, UPDATE, DELETE for members). **Migration:** [add-dc-metadata.sql](./migrations/add-dc-metadata.sql).

---

### 3.4b sitdeck_risk_config

Per-property configuration for **SitDeck** risk intelligence widgets (e.g. geopolitical, climate, cyber). One row per property (`UNIQUE(property_id)`). The app populates this from **Data Library → Connectors** (SitDeck connector: Connect / Refresh), not from Account Settings → Integrations. Spec context: [docs/specs/secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §6 (Risk Intelligence / SitDeck).


| Column              | Type        | Nullable | Description                                                                             |
| ------------------- | ----------- | -------- | --------------------------------------------------------------------------------------- |
| id                  | uuid        | NO       | PK                                                                                      |
| account_id          | uuid        | NO       | FK → accounts.id                                                                        |
| property_id         | uuid        | NO       | FK → properties.id (UNIQUE)                                                             |
| active_widget_types | text[]      | YES      | Enabled widget type identifiers (app-defined; e.g. geopolitical, climate_hazard, cyber) |
| last_synced_at      | timestamptz | YES      | Last successful sync with SitDeck (if tracked server-side)                              |
| created_at          | timestamptz | NO       |                                                                                         |
| updated_at          | timestamptz | NO       |                                                                                         |


**RLS:** account-scoped (SELECT, INSERT, UPDATE, DELETE for members). **Migration:** [add-sitdeck-risk-config.sql](./migrations/add-sitdeck-risk-config.sql).

---

### 3.4c risk_diagnosis

Per-property **risk assessment** snapshot for the Data Centre Risk Diagnosis flow. One row per property (`UNIQUE(property_id)`). Populated or updated from SitDeck widgets, webhooks (`agent_findings`), manual entry, or agents. Spec: [secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §6, §10.


| Column                 | Type        | Nullable | Description                                          |
| ---------------------- | ----------- | -------- | ---------------------------------------------------- |
| id                     | uuid        | NO       | PK                                                   |
| account_id             | uuid        | NO       | FK → accounts.id                                     |
| property_id            | uuid        | NO       | FK → properties.id (UNIQUE)                          |
| summary                | text        | YES      | Human-readable assessment summary                    |
| overall_risk_level     | text        | YES      | `unknown` | `low` | `moderate` | `high` | `critical` |
| diagnosis_json         | jsonb       | YES      | Structured diagnosis (app-defined shape)             |
| assessed_at            | timestamptz | YES      | When assessment was last run or materially updated   |
| sitdeck_last_synced_at | timestamptz | YES      | When SitDeck-driven physical flags were last merged  |
| created_at             | timestamptz | NO       |                                                      |
| updated_at             | timestamptz | NO       |                                                      |


**RLS:** account-scoped (SELECT, INSERT, UPDATE, DELETE for members). **Migration:** [add-risk-diagnosis.sql](./migrations/add-risk-diagnosis.sql).

---

### 3.4d physical_risk_flags

Individual **physical / location** risk flags (flood, wildfire, extreme weather, etc.) attached to a `risk_diagnosis` row. `**source`** distinguishes SitDeck-derived data from manual or agent input.


| Column            | Type        | Nullable | Description                                          |
| ----------------- | ----------- | -------- | ---------------------------------------------------- |
| id                | uuid        | NO       | PK                                                   |
| risk_diagnosis_id | uuid        | NO       | FK → risk_diagnosis.id (ON DELETE CASCADE)           |
| flag_type         | text        | NO       | e.g. flood, wildfire, extreme_weather, earthquake    |
| source            | text        | NO       | `sitdeck` | `manual` | `agent`                       |
| severity          | text        | YES      | `unknown` | `low` | `moderate` | `high` | `critical` |
| title             | text        | YES      | Short label                                          |
| detail            | text        | YES      | Longer explanation                                   |
| payload           | jsonb       | YES      | Raw or normalised payload from SitDeck or agent      |
| external_ref      | text        | YES      | External id (e.g. SitDeck event id)                  |
| created_at        | timestamptz | NO       |                                                      |
| updated_at        | timestamptz | NO       |                                                      |


**RLS:** SELECT/INSERT/UPDATE/DELETE when the linked `risk_diagnosis` row belongs to the user’s account (subquery on `risk_diagnosis.account_id`). **Migration:** [add-risk-diagnosis.sql](./migrations/add-risk-diagnosis.sql).

---

### 3.5 spaces

Space within a property. Can be top-level (parent_space_id null) or a **subspace** (parent_space_id set). Hierarchy: (1) Tenant spaces vs Base building spaces; (2) under each, control (tenant_controlled / landlord_controlled / shared); (3) under any space, subspaces (e.g. "meeting rooms", "common areas"). References property; optional parent for subspaces.


| Column            | Type        | Nullable | Description                                            |
| ----------------- | ----------- | -------- | ------------------------------------------------------ |
| id                | uuid        | NO       | PK                                                     |
| property_id       | uuid        | NO       | FK → properties.id                                     |
| parent_space_id   | uuid        | YES      | FK → spaces.id; null = top-level space                 |
| name              | text        | NO       |                                                        |
| space_class       | text        | NO       | `tenant` | `base_building`                             |
| control           | text        | NO       | `landlord_controlled` | `tenant_controlled` | `shared` |
| space_type        | text        | YES      | e.g. common_area, shared_space, meeting_room, office   |
| area              | numeric     | YES      |                                                        |
| floor_reference   | text        | YES      |                                                        |
| in_scope          | boolean     | NO       | Default true                                           |
| net_zero_included | boolean     | YES      |                                                        |
| gresb_reporting   | boolean     | YES      |                                                        |
| created_at        | timestamptz | NO       |                                                        |
| updated_at        | timestamptz | NO       |                                                        |


**Migration (existing DBs):** To add subspaces support: `ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS parent_space_id uuid REFERENCES public.spaces(id) ON DELETE CASCADE;` then `CREATE INDEX IF NOT EXISTS idx_spaces_parent_space_id ON public.spaces(parent_space_id);`

---

### 3.6 systems

Building system (HVAC, Power, Lighting, etc.). Taxonomy: [data-model/building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md).


| Column                    | Type        | Nullable | Description                                                                                                     |
| ------------------------- | ----------- | -------- | --------------------------------------------------------------------------------------------------------------- |
| id                        | uuid        | NO       | PK                                                                                                              |
| account_id                | uuid        | NO       | FK → accounts.id (for RLS)                                                                                      |
| property_id               | uuid        | NO       | FK → properties.id                                                                                              |
| name                      | text        | NO       |                                                                                                                 |
| system_category           | text        | NO       | Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring, Other                                   |
| system_type               | text        | YES      | e.g. GridLVSupply, Boilers, TenantLighting                                                                      |
| space_class               | text        | YES      | `tenant` | `base_building`                                                                                      |
| controlled_by             | text        | NO       | `tenant` | `landlord` | `shared`                                                                                |
| maintained_by             | text        | YES      |                                                                                                                 |
| metering_status           | text        | NO       | `none` | `partial` | `full`                                                                                     |
| allocation_method         | text        | NO       | `measured` | `area` | `estimated` | `mixed` (part measured, part allocated; describe split in allocation_notes) |
| allocation_notes          | text        | YES      |                                                                                                                 |
| key_specs                 | text        | YES      | Key specs from building systems register (e.g. meter IDs, plant specs)                                          |
| spec_status               | text        | YES      | e.g. REAL, PLACEHOLDER (from register)                                                                          |
| serves_space_ids          | uuid[]      | YES      | Array of space.id                                                                                               |
| serves_spaces_description | text        | YES      | Human-readable "Serves Spaces" (e.g. "Ground, 4th, 5th", "Whole Building") for register alignment               |
| created_at                | timestamptz | NO       |                                                                                                                 |
| updated_at                | timestamptz | NO       |                                                                                                                 |


---

### 3.7 meters

First-class meter entity. Can be linked to a system.


| Column      | Type        | Nullable | Description                  |
| ----------- | ----------- | -------- | ---------------------------- |
| id          | uuid        | NO       | PK                           |
| account_id  | uuid        | NO       | FK → accounts.id             |
| property_id | uuid        | NO       | FK → properties.id           |
| system_id   | uuid        | YES      | FK → systems.id (nullable)   |
| name        | text        | NO       |                              |
| meter_type  | text        | YES      | e.g. electricity, gas, water |
| unit        | text        | YES      | e.g. kWh, m³                 |
| external_id | text        | YES      | Supplier/meter ID            |
| created_at  | timestamptz | NO       |                              |
| updated_at  | timestamptz | NO       |                              |


---

### 3.8 end_use_nodes

End-use node linked to a system. Taxonomy: nodeCategory, utilityType in [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md).


| Column               | Type        | Nullable | Description                                                                  |
| -------------------- | ----------- | -------- | ---------------------------------------------------------------------------- |
| id                   | uuid        | NO       | PK                                                                           |
| account_id           | uuid        | NO       | FK → accounts.id                                                             |
| property_id          | uuid        | NO       | FK → properties.id                                                           |
| system_id            | uuid        | NO       | FK → systems.id                                                              |
| node_id              | text        | NO       | Business key (e.g. E_TENANT_PLUG)                                            |
| node_category        | text        | NO       | e.g. tenant_plug_load, tenant_lighting                                       |
| utility_type         | text        | NO       | electricity, heating, cooling, water, waste, occupancy, access               |
| control_override     | text        | YES      | TENANT | LANDLORD | SHARED                                                   |
| allocation_weight    | numeric     | YES      | 0..1                                                                         |
| applies_to_space_ids | uuid[]      | YES      |                                                                              |
| notes                | text        | YES      |                                                                              |
| auto_generated       | boolean     | YES      | true if node was created by archetype/default generator (portfolio scalable) |
| created_at           | timestamptz | NO       |                                                                              |
| updated_at           | timestamptz | NO       |                                                                              |


Unique on `(property_id, node_id)`. Full spec (v1 + engineer rules): [end-use-nodes-spec.md](../data-model/end-use-nodes-spec.md).

---

### 3.9 data_library_records

Data Library record (utility, evidence, governance, etc.). Evidence linked via `evidence_attachments`.


| Column                 | Type        | Nullable | Description                                                                                     |
| ---------------------- | ----------- | -------- | ----------------------------------------------------------------------------------------------- |
| id                     | uuid        | NO       | PK                                                                                              |
| account_id             | uuid        | NO       | FK → accounts.id                                                                                |
| property_id            | uuid        | YES      | FK → properties.id (nullable for account-level)                                                 |
| subject_category       | text        | NO       | e.g. energy, waste, certificates, governance, targets (see data-library-implementation-context) |
| name                   | text        | YES      | Display name for UI ("Record Name")                                                             |
| data_type              | text        | YES      |                                                                                                 |
| value_numeric          | numeric     | YES      |                                                                                                 |
| value_text             | text        | YES      |                                                                                                 |
| unit                   | text        | YES      |                                                                                                 |
| reporting_period_start | date        | YES      |                                                                                                 |
| reporting_period_end   | date        | YES      |                                                                                                 |
| source_type            | text        | NO       | `connector` | `upload` | `manual` | `rule_chain`                                                |
| confidence             | text        | YES      | measured | allocated | estimated | cost_only                                                    |
| allocation_method      | text        | YES      |                                                                                                 |
| allocation_notes       | text        | YES      |                                                                                                 |
| created_at             | timestamptz | NO       |                                                                                                 |
| updated_at             | timestamptz | NO       |                                                                                                 |


---

### 3.10 documents

Metadata for a file stored in Supabase Storage. **No binary in DB.**


| Column          | Type        | Nullable | Description                                                              |
| --------------- | ----------- | -------- | ------------------------------------------------------------------------ |
| id              | uuid        | NO       | PK                                                                       |
| account_id      | uuid        | NO       | FK → accounts.id                                                         |
| storage_path    | text        | NO       | Key in bucket (e.g. account/{id}/property/{id}/2026/02/{docId}-file.pdf) |
| file_name       | text        | NO       | Original filename                                                        |
| mime_type       | text        | YES      |                                                                          |
| file_size_bytes | bigint      | YES      |                                                                          |
| created_at      | timestamptz | NO       |                                                                          |
| updated_at      | timestamptz | NO       |                                                                          |


Storage path format (invariant): `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}`.

---

### 3.11 evidence_attachments

Links a Data Library record to a document. Many-to-many possible (one record, many docs). Optional columns for Lovable Evidence panel: tag (invoice, contract, methodology, certificate, report, other), description — see [add-evidence-attachment-tag-and-description.sql](migrations/add-evidence-attachment-tag-and-description.sql).


| Column                 | Type        | Nullable | Description                                                          |
| ---------------------- | ----------- | -------- | -------------------------------------------------------------------- |
| id                     | uuid        | NO       | PK                                                                   |
| data_library_record_id | uuid        | NO       | FK → data_library_records.id                                         |
| document_id            | uuid        | NO       | FK → documents.id                                                    |
| tag                    | text        | YES      | Optional: invoice, contract, methodology, certificate, report, other |
| description            | text        | YES      | Optional description for this attachment                             |
| created_at             | timestamptz | NO       |                                                                      |


Unique on `(data_library_record_id, document_id)`.

---

### 3.12 agent_runs

One invocation of an agent (e.g. Data Readiness, Boundary).


| Column           | Type        | Nullable | Description                         |
| ---------------- | ----------- | -------- | ----------------------------------- |
| id               | uuid        | NO       | PK                                  |
| account_id       | uuid        | NO       | FK → accounts.id                    |
| property_id      | uuid        | YES      | FK → properties.id (nullable)       |
| agent_type       | text        | NO       | `data_readiness` | `boundary`       |
| status           | text        | NO       | `pending` | `completed` | `failed`  |
| context_snapshot | jsonb       | YES      | Input context (optional, for audit) |
| created_by       | uuid        | YES      | auth.users.id                       |
| created_at       | timestamptz | NO       |                                     |
| updated_at       | timestamptz | NO       |                                     |


---

### 3.13 agent_findings

Findings from an **agent run** or from the **SitDeck alerts webhook** (no run). Payload is agent-specific JSON or the raw SitDeck event envelope.


| Column       | Type        | Nullable | Description                                                              |
| ------------ | ----------- | -------- | ------------------------------------------------------------------------ |
| id           | uuid        | NO       | PK                                                                       |
| agent_run_id | uuid        | YES      | FK → agent_runs.id; **null** when `source = 'sitdeck'`                   |
| account_id   | uuid        | NO       | FK → accounts.id; denormalized from `agent_runs` or set for webhook rows |
| property_id  | uuid        | YES      | FK → properties.id; optional scope (e.g. SitDeck alert for one property) |
| source       | text        | YES      | `sitdeck` for webhook-delivered alerts; otherwise null with an agent run |
| finding_type | text        | YES      | e.g. controllability, scope_readiness, or SitDeck-derived type string    |
| payload      | jsonb       | NO       | Agent output or SitDeck JSON body                                        |
| created_at   | timestamptz | NO       |                                                                          |


**Constraints:** Either (`agent_run_id` set and `source` is not `sitdeck`) or (`agent_run_id` null, `source = 'sitdeck'`, `account_id` set). **RLS:** members read by `account_id`; members insert only rows tied to their agent runs. Webhook inserts use the **service role** (Edge Function).

**Migration (existing projects):** [add-agent-findings-sitdeck-webhook.sql](./migrations/add-agent-findings-sitdeck-webhook.sql). **Webhook handler (Edge Function):** [sitdeck-webhook/index.ts](../../supabase/functions/sitdeck-webhook/index.ts) — see [implementation-guide-phase-3-dc.md](../specs/implementation-guide-phase-3-dc.md) Step 3.6b.

---

### 3.14 audit_events

Append-only audit log. Before/after state for traceability.


| Column       | Type        | Nullable | Description                        |
| ------------ | ----------- | -------- | ---------------------------------- |
| id           | uuid        | NO       | PK                                 |
| account_id   | uuid        | NO       | FK → accounts.id                   |
| entity_type  | text        | NO       | e.g. data_library_records, systems |
| entity_id    | uuid        | NO       | Target row id                      |
| action       | text        | NO       | `create` | `update` | `delete`     |
| actor_id     | uuid        | YES      | auth.users.id                      |
| before_state | jsonb       | YES      |                                    |
| after_state  | jsonb       | YES      |                                    |
| created_at   | timestamptz | NO       |                                    |


---

### 3.15 Asset Tracking tables (v2.0)

Canonical column list and behaviour: [secure-asset-tracking-spec-v2.0.md](../specs/secure-asset-tracking-spec-v2.0.md) §6. **Naming note:** `at_zones.space_id` references `spaces.id` (optional). The v2.0 prose table used the label `spaces_id`; the implemented FK column is `space_id`.

**at_floors** — `id`, `account_id`, `property_id`, `name`, `level_index`, `floor_plan_image_url`, `floor_plan_width_px`, `floor_plan_height_px`, `coord_system` (`pixel`  `local_metres`  `gps`), `gps_calibration`, `created_at`, `updated_at`.

**at_zones** — `id`, `account_id`, `floor_id` → `at_floors`, `property_id`, `name`, `zone_type` (`public`  `restricted`  `staff_entry`), `polygon` (jsonb), `space_id` → `spaces` (optional), `description`, `created_at`, `updated_at`.

**at_asset_types** — `id`, `account_id`, `property_id` (null = account master), `name`, `category`, `icon_key`, `description`, `created_at`. Unique: `(account_id, name)` where `property_id` is null; `(account_id, property_id, name)` where `property_id` is set (partial unique indexes).

**at_assets** — `id`, `account_id`, `property_id`, `name`, `asset_type_id`, `user_id`, `default_zone_id`, `tag_id` → `at_asset_tags`, `status`, `serial_number`, `created_at`, `updated_at`.

**at_asset_tags** — `id`, `account_id`, `property_id`, `wirepas_node_id`, `mac_address`, `tag_model`, `has_panic_button`, `panic_button_action`, `battery_level_pct`, `firmware_version`, `status`, `assigned_asset_id` → `at_assets`, `last_seen_at`, `created_at`, `updated_at`. Unique `(property_id, wirepas_node_id)`; partial unique on `assigned_asset_id` where not null.

**at_gateways** — `id`, `account_id`, `property_id`, `floor_id`, `name`, `wirepas_gateway_id`, `mac_address`, `firmware_version`, `ip_address`, `online`, `connected_node_count`, `last_heartbeat_at`, `created_at`, `updated_at`. Unique `(property_id, wirepas_gateway_id)`.

**at_position_events** — `id`, `account_id`, `property_id`, `asset_id`, `tag_id`, `floor_id`, `zone_id`, `x_pos`, `y_pos`, `accuracy_m`, `source`, `recorded_at`, `created_at`. Append-only; RLS: SELECT + INSERT for members (no client UPDATE/DELETE).

**at_alerts** — `id`, `account_id`, `property_id`, `asset_id`, `alert_type`, `zone_id`, `floor_id`, `message`, `idle_minutes`, `status`, `acknowledged_by`, `acknowledged_at`, `triggered_at`, `created_at`. Trigger `at_alerts_audit_trigger` appends `audit_events` on insert and on status/ack fields update.

**at_device_state** — `id`, `account_id`, `system_id` → `systems` (unique), `online`, `light_on`, `dim_level_pct`, `als_value`, `daylight_harvesting_active`, `daylight_harvesting_pct`, `behaviour_mode_index`, `power_watts`, `last_updated_at`.

**at_dali_commands** — `id`, `account_id`, `system_id`, `command_type`, `payload`, `status`, `created_by`, `created_at`, `sent_at`, `acknowledged_at`.

**at_facility_settings** — `id`, `account_id`, `property_id` (unique), `position_update_interval_sec` (5–60), `prolonged_idle_threshold_min`, `panic_button_default_action`, `out_of_zone_enabled`, `restricted_entry_enabled`, `dali_motion_timeout_sec`, `dali_dh_setpoint_als`, `created_at`, `updated_at`.

---

## 4. Relationships (ER summary)

- **accounts** ← account_memberships (user_id → auth.users)
- **accounts** ← properties ← spaces
- **accounts** ← properties ← dc_metadata (one row per data_centre property)
- **accounts** ← properties ← sitdeck_risk_config (one row per property; SitDeck widgets)
- **accounts** ← properties ← risk_diagnosis (one row per property) ← physical_risk_flags
- **accounts** ← properties ← systems ← end_use_nodes
- **accounts** ← properties ← meters (optional system_id → systems)
- **accounts** ← data_library_records (optional property_id)
- **data_library_records** ← evidence_attachments → documents
- **accounts** ← agent_runs → agent_findings (optional FK); **accounts** ← agent_findings (`account_id`); optional **properties** ← agent_findings (`property_id`)
- **accounts** ← audit_events
- **accounts** ← properties ← at_floors ← at_zones; **spaces** optional from `at_zones.space_id`
- **accounts** ← at_asset_types; **properties** optional for property-scoped types
- **accounts** ← at_assets → at_asset_types, at_zones, at_asset_tags (`tag_id`), auth.users (`user_id`)
- **accounts** ← at_asset_tags → at_assets (`assigned_asset_id`)
- **accounts** ← at_gateways → at_floors (optional)
- **accounts** ← at_position_events → at_assets, at_asset_tags, at_floors, at_zones
- **accounts** ← at_alerts → at_assets, at_zones, at_floors
- **accounts** ← at_device_state → **systems** (DALI fixture row)
- **accounts** ← at_dali_commands → **systems**
- **accounts** ← at_facility_settings → **properties** (one row per property)

All account-scoped tables are protected by RLS so that `auth.uid()` is required and rows are filtered by membership in the row’s `account_id`.
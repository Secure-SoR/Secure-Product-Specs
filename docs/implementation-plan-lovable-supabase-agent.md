# Step-by-step: Lovable + Supabase + AI Agent

Goal: Create properties, add spaces/systems and data library (bills, governance), then run the AI agent (Data Readiness / Boundary) with real data from Supabase.

---

## Overview

| Phase | What | Where |
|-------|------|--------|
| 1 | Account + membership in Supabase after sign-up | Lovable + Supabase |
| 2 | Properties, spaces, systems read/write from Supabase | Lovable + Supabase |
| 3 | Data library records + file uploads (bills, governance) | Lovable + Supabase Storage |
| 4 | Optional: End-use nodes in Supabase | Lovable + Supabase |
| 5 | Build agent context from Supabase and call agent | Lovable (+ optional: persist agent_runs) |

---

## Phase 1: Account + membership in Supabase

**Why:** Until the user has a row in `accounts` and `account_memberships`, RLS blocks access to properties, systems, data library, etc.

### Supabase

- Already done if you ran [supabase-schema.sql](../database/supabase-schema.sql): policy **"Authenticated users can create accounts"** allows INSERT into `accounts`. Policy **"Users can add themselves as member"** allows INSERT into `account_memberships` with `user_id = auth.uid()`.
- If you haven’t, run in SQL Editor:
  ```sql
  CREATE POLICY "Authenticated users can create accounts"
    ON public.accounts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  ```

### Lovable

**Current behaviour (in sync with backend):** Sign-up is one step (email, name, password) then redirect to `/onboarding/account`. Account name and type are collected on the CreateAccount page (`/onboarding/create`). That page can call `supabase.rpc('check_account_name_exists', { account_name })` on blur to warn if the org is already registered and direct the user to "Join an existing account" (`/onboarding/join`). **Account creation** is done via a **Supabase Edge Function** `create-account` (not direct client inserts), because RLS would block the first membership. The frontend calls `supabase.functions.invoke('create-account', { body: { name, account_type, enabled_modules } })`; the Edge Function validates the user's JWT, then uses the **service role** client to insert into `accounts` and `account_memberships` and returns the created account. The app stores `currentAccountId`. On load, account is resolved from `account_memberships`; if none, redirect to `/onboarding/account`.

1. **Account creation:** Via Edge Function `create-account` (see Current behaviour above). Request body: `{ name, account_type, enabled_modules }`. Function returns the created account; frontend stores `currentAccountId`.
2. **Load current account:** On app init, `supabase.from('account_memberships').select('account_id, role').eq('user_id', session.user.id)`. Use the first `account_id` as current account. **Sign-in redirect:** The effect that loads membership must set `accountLoading = true` at the start (when `authUser` is set) before the async fetch; otherwise a race can leave `accountLoading = false` and `currentAccount = null` briefly, and `ProtectedRoute` will redirect existing users to `/onboarding/account`. ProtectedRoute should treat `loading || accountLoading` as "show spinner" and only redirect when loading is done and there is no membership.

3. **Guard onboarding routes:** In `AccountSetup.tsx` (or equivalent), destructure `currentAccount` from `useAccount()` and add a `useEffect` that redirects to `/` (dashboard) when `currentAccount` is set — so users who already have an account don't stay on the account-setup page (e.g. after a direct link or refresh).

4. **Sign-out before navigate:** In the context switcher (or wherever sign-out is triggered), call `await signOut()` before `navigate('/signin')` so the auth state is cleared before the redirect and the next page doesn't see a stale session.

**Done when:** New user signs up → completes account step (CreateAccount calls Edge Function) → you see one row in `accounts` and one in `account_memberships` in Supabase. The Edge Function lives in the Lovable project (`supabase/functions/create-account`); it must be deployed to the same Supabase project (e.g. `supabase functions deploy create-account`).

---

## Phase 2: Properties, spaces, systems from Supabase

**Why:** So property/space/system data lives in the DB and can be used to build the agent context.

### Supabase

- No schema change. Tables `properties`, `spaces`, `systems` and RLS are already in place. Use the column names from [schema.md](../database/schema.md).

### Lovable

1. **Properties**
   - **Create:** When user adds a property, `supabase.from('properties').insert({ account_id: currentAccountId, name, address, city, region, postcode, country, nla, asset_type, year_built, last_renovation, operational_status, floors, total_area })`. Use returned `id` as `propertyId`.
   - **List:** `supabase.from('properties').select('*').eq('account_id', currentAccountId)`.
   - **Update / delete:** Use `.update()` / `.delete()` with the property `id`. RLS will allow only if `account_id` matches the user’s membership.
2. **Spaces** (hierarchy: top-level spaces and subspaces via parent_space_id)
   - **Create:** `supabase.from('spaces').insert({ property_id, parent_space_id: null | parentId, name, space_class, control, space_type, area, floor_reference, in_scope })`. Level 1: `space_class` = `tenant` | `base_building`. Level 2: `control` = `tenant_controlled` | `landlord_controlled` | `shared`. Base building can use `space_type` e.g. common_area, shared_space. Subspaces: set `parent_space_id` to the parent space id.
   - **List:** `supabase.from('spaces').select('*').eq('property_id', propertyId)`; build tree in app using `parent_space_id` (null = root).
   - **Update / delete:** Include `parent_space_id` in update; on delete of a space, cascade deletes children (or reassign).
3. **Systems**
   - **Create:** `supabase.from('systems').insert({ account_id: currentAccountId, property_id, name, system_category, system_type, controlled_by, metering_status, allocation_method, serves_space_ids })`. `system_category`: e.g. Power, HVAC, Lighting, Water, Waste, BMS, Lifts (see [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md)). `controlled_by`: `tenant` | `landlord` | `shared`. `serves_space_ids`: array of space UUIDs.
   - **List:** `supabase.from('systems').select('*').eq('property_id', propertyId)`.

**Field mapping (Lovable UI → Supabase):**

| Supabase column   | Example value / notes |
|-------------------|------------------------|
| properties.name   | Property name |
| properties.address | Street/address line (optional) |
| properties.city, .region, .postcode, .country, .nla | Optional; city, region, postcode, nla persisted separately (not concatenated into address) |
| properties.asset_type | Optional; e.g. Office, Retail, Industrial; default `'Office'` in DB |
| properties.year_built, .last_renovation | Optional; integer (4-digit year) |
| properties.operational_status | Optional; e.g. operational, under_construction, vacant |
| properties.occupancy_scope | Optional; `whole_building` \| `partial_building` — tenant footprint at this property (selected on spaces subpage) |
| properties.floors | All floor identifiers in the building (property overview) |
| properties.floors_in_scope | Optional; subset of floors the tenant occupies (saved from "Floors in Scope" tile on spaces subpage; persist on Save) |
| properties.total_area | Optional |
| spaces.parent_space_id | null = top-level; set to parent space id for subspaces (e.g. meeting rooms under a floor) |
| spaces.space_class | `tenant` \| `base_building` |
| spaces.control    | `tenant_controlled` \| `landlord_controlled` \| `shared` |
| spaces.space_type  | e.g. common_area, shared_space, meeting_room, office (for base building and subspaces) |
| systems.system_category | Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring |
| systems.system_type | e.g. GridLVSupply, Boilers, TenantLighting |
| systems.controlled_by | tenant, landlord, shared |
| systems.metering_status | none, partial, full |
| systems.allocation_method | measured, area, estimated |

**Demo properties:** For demo/mock property IDs (e.g. Aldersgate), the app may keep field-level overrides in localStorage (`demoPropertyOverrides`) so edits to GFA, asset type, last renovation, etc. persist across re-renders and refreshes; the `propertiesById` memo merges these overrides onto the mock property. Supabase-backed properties are the source of truth for non-demo IDs.

**Done when:** You can create a property, add spaces and systems in the app, and see them in Supabase Table Editor.

### Optional: Ownership / tenure (“ownership structure”)

**What it means:** “Ownership structure” usually means one or both of:

1. **Property-level:** Does your organisation **own** this property, **lease** it, or hold it in a **joint venture**? (Sometimes called *tenure* or *ownership type*.) That can be a single field per property (e.g. `ownership_type`: `owned` | `leased` | `joint_venture`) or plus an optional **equity share %** for JVs.
2. **Account-level:** *How* you draw the reporting boundary — **operational control**, **financial control**, or **equity share**. That’s already in **`account.reporting_boundary`** (e.g. `boundaryApproach`), not on the property.

**What you already have:** Landlord vs tenant **control** is on **spaces** (`control`) and **systems** (`controlled_by`). The **reporting boundary** (operational / financial / equity-share) is on the **account** (`reporting_boundary`). So for the Boundary/Data Readiness agent you don’t *need* a separate “ownership structure” at property level for the MVP.

**Recommendation:**  
- **MVP:** You can **skip** persisting property-level “ownership structure” until the UI or reporting clearly needs it. Focus on properties, spaces, systems, then data library and the agent.  
- **Later:** If the Lovable UI has a field like “Own or lease?” or “Equity share %”, add a column to `properties` (e.g. `ownership_type` text or `tenure` text, and optionally `equity_share` numeric), wire it in the Supabase hook and `useProperties` like `asset_type`, and document it in [schema.md](../database/schema.md) and here.

### For the AI agent

- Property data is read from Supabase table `properties` (by `account_id`). When Lovable builds the agent context (Phase 5), it will fetch properties from Supabase; the **context shape** (propertyId, propertyName, spaces, systems, etc.) is unchanged. No agent code change required for Phase 2; keep using the same context schema.

---

## Lovable prompt for Phase 2 (properties)

You can paste this into Lovable to implement **properties** in Supabase (create, list, update, delete). Use this first; add spaces and systems in a follow-up if needed.

```
Use Supabase for properties instead of localStorage.

1. When the user creates a property, insert into the Supabase table "properties" with: account_id = currentAccountId (from AccountContext), name (required), and optionally address, city, region, postcode, country, nla, asset_type (e.g. 'Office', default in DB), year_built (integer), last_renovation (integer), operational_status (text), floors (JSON array of floor identifiers), total_area (number). Keep city, region, postcode, nla as separate columns (do not concatenate into address). Use .select('id').single() or .select().single() to get the new row and use its id as the property id in the app.

2. When loading the list of properties, use: supabase.from('properties').select('*').eq('account_id', currentAccountId). Use the returned rows as the source of truth; do not read the property list from localStorage.

3. When the user updates a property, use supabase.from('properties').update({ name, address, city, region, postcode, country, nla, asset_type, year_built, last_renovation, operational_status, occupancy_scope, floors, floors_in_scope, total_area, updated_at: new Date().toISOString() }).eq('id', propertyId). When they delete a property, use supabase.from('properties').delete().eq('id', propertyId).

4. Ensure currentAccountId is set (from account_memberships after login) before any property query. Use the same Supabase client and auth session you already use for account creation and login.
```

---

## Lovable prompt for Phase 2 (spaces)

Use this in Lovable after properties are in Supabase. It wires **spaces** (within a property) to the Supabase table `spaces`.

```
Use Supabase for spaces within a property instead of localStorage.

1. When the user creates a space for a property, insert into the Supabase table "spaces" with: property_id = the current property's id, parent_space_id = null for top-level or the parent space's id for a subspace, name (required), space_class (required: "tenant" or "base_building"), control (required: "landlord_controlled", "tenant_controlled", or "shared"), and optionally space_type (e.g. common_area, shared_space, meeting_room, office), area, floor_reference, in_scope (default true), net_zero_included, gresb_reporting. Use .select('id').single() or .select().single() to get the new row and use its id in the app.

2. When loading the list of spaces for a property, use: supabase.from('spaces').select('*').eq('property_id', propertyId). Build a tree in the app: rows with parent_space_id null are top-level; rows with parent_space_id = X are children of space X. Use the returned rows as the source of truth; do not read the space list from localStorage.

3. When the user updates a space, use supabase.from('spaces').update({ parent_space_id, name, space_class, control, space_type, area, floor_reference, in_scope, net_zero_included, gresb_reporting, updated_at: new Date().toISOString() }).eq('id', spaceId). When they delete a space, use supabase.from('spaces').delete().eq('id', spaceId). Deleting a parent will cascade to children if ON DELETE CASCADE is set on parent_space_id.

4. Only load or mutate spaces when you have a valid propertyId that belongs to the current account (the property should already be loaded from Supabase). Use the same Supabase client you use for properties.
```

---

## Lovable prompt: Whole building vs partial building tenant (occupancy scope)

The property overview already captures building info (e.g. 5 floors, total area). The tenant’s **footprint** at that property — whole building or partial — is one value per property and is captured on the **spaces subpage**. Add a `properties.occupancy_scope` column and a selector in the UI; use the prompt below in Lovable.

**Supabase (run once if the column is missing):**  
`ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS occupancy_scope text;`

**Prompt to paste into Lovable:**

```
Add "Whole building tenant" vs "Partial building tenant" for the current property and persist it in Supabase.

1. Database: Ensure the properties table has a column occupancy_scope (text, nullable). If not, run in Supabase SQL Editor: ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS occupancy_scope text;

2. On the spaces subpage (the page where the user manages spaces for a property), add a selector or radio group: "Whole building tenant" and "Partial building tenant". This describes whether the tenant (the logged-in account) occupies the whole building at this property or only part of it. Place it near the top of the spaces section so the user selects it before or while defining spaces.

3. Persist to Supabase: When the user selects an option, update the current property row: supabase.from('properties').update({ occupancy_scope: 'whole_building' | 'partial_building', updated_at: new Date().toISOString() }).eq('id', propertyId). When loading the property (e.g. on property overview or spaces page), include occupancy_scope in the select so the UI can show the current selection.

4. Wire the data layer: Add occupancy_scope to the Supabase property interface and to the useProperties converter (e.g. occupancyScope: row.occupancy_scope ?? null). On update, map the UI value (e.g. occupancyScope) to occupancy_scope in the Supabase update payload.
```

---

## Lovable prompt: Floors in Scope tile — save to Supabase

The property has a total number of floors (from property overview); on the spaces subpage the **Floors in Scope** tile shows all building floors and lets the tenant select which are in scope. Those selections are not persisted. Add `properties.floors_in_scope` (jsonb) and a Save action so the selection is stored in Supabase.

**Supabase (run once if the column is missing):**  
`ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS floors_in_scope jsonb;`

**Prompt to paste into Lovable:**

```
The "Floors in Scope" tile on the spaces subpage shows all floors of the building (from the property) and lets the tenant select which floors are in scope. Right now there is no way to save that selection. Add persistence to Supabase.

1. Database: Ensure the properties table has a column floors_in_scope (jsonb, nullable). It stores the list of floor identifiers the tenant has selected as in scope (e.g. ["Ground", "1", "2"]). If the column is missing, run in Supabase SQL Editor: ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS floors_in_scope jsonb;

2. Add a Save button (or "Save floors in scope" action) to the Floors in Scope tile. When the user has selected which floors are in scope and clicks Save, update the current property: supabase.from('properties').update({ floors_in_scope: <array of selected floor identifiers>, updated_at: new Date().toISOString() }).eq('id', propertyId).

3. Load and display: When loading the property for the spaces page, include floors_in_scope in the select. When the tile renders, pre-select the floors that are in floors_in_scope (if any) so the UI reflects the saved state. The list of all floors still comes from the property (e.g. property.floors); the selected subset is property.floorsInScope from row.floors_in_scope.

4. Data layer: Add floors_in_scope to the Supabase property interface and to the useProperties converter (e.g. floorsInScope: row.floors_in_scope ?? null). Include floors_in_scope (or floorsInScope mapped to floors_in_scope) in the property update payload when saving so the Save action persists correctly.
```

---

## Lovable prompt: Create the spaces (hierarchy + subspaces)

Under **Spaces**, a new category **"Create the spaces"** lets the user define which spaces exist on each floor in a two-level hierarchy, then add **subspaces** (e.g. meeting rooms under a tenant floor). All data is stored in Supabase table `spaces`; subspaces use `parent_space_id`. Ensure the `spaces` table has column `parent_space_id` (uuid, nullable, FK to spaces.id). If missing, run: `ALTER TABLE public.spaces ADD COLUMN IF NOT EXISTS parent_space_id uuid REFERENCES public.spaces(id) ON DELETE CASCADE;` and `CREATE INDEX IF NOT EXISTS idx_spaces_parent_space_id ON public.spaces(parent_space_id);`

**Prompt to paste into Lovable:**

```
Under Spaces, add a "Create the spaces" flow that builds spaces dynamically and saves everything to Supabase.

1. **Button / entry:** Add a clear entry point (e.g. "Create the spaces" button) that starts the flow. The idea: first define which spaces we have on each floor (tenant vs base building, then control type), then optionally add subspaces under any space (e.g. "Tenant space Floor 2, tenant_controlled" can have subspaces "meeting rooms", "office").

2. **Level 1 — Tenant spaces vs Base building spaces:** When the user adds a space, they choose space_class: "tenant" or "base_building". For base building spaces, allow naming or typing common areas and shared spaces (use space_type e.g. "common_area", "shared_space" or name).

3. **Level 2 — Control:** For each space (tenant or base building), they choose control: "tenant_controlled", "landlord_controlled", or "shared". So we get e.g. "Tenant space, tenant_controlled" or "Base building, landlord_controlled (common areas)".

4. **Subspaces:** Allow the user to add subspaces under any existing space. Example: "Tenant space Floor 2, tenant_controlled" → add subspace "Meeting rooms" or "Office". In Supabase, store these with parent_space_id = the parent space's id. Top-level spaces have parent_space_id = null. When creating a subspace, insert with property_id = current property, parent_space_id = selected parent space id, name, space_class (can inherit or choose), control, space_type (e.g. meeting_room, office).

5. **Persistence:** All create/update/delete go to Supabase table "spaces". Include parent_space_id in insert and update. When loading spaces for the property, use supabase.from('spaces').select('*').eq('property_id', propertyId). Build a tree in the UI by grouping rows where parent_space_id is null as roots, and rows where parent_space_id = X as children of space X. Show the hierarchy (e.g. indented or nested) so the user sees tenant vs base building, control type, and subspaces.

6. **Data layer:** Add parent_space_id to the Supabase space interface and to the spaces converter. When creating a subspace, pass parent_space_id; when creating a top-level space, pass parent_space_id: null. List and update must handle parent_space_id so the hierarchy is correct after refresh.
```

---

## Phase 3: Data library records + file uploads (bills, governance)

**Why:** So the agent has data library records and evidence (e.g. bills, governance docs) to reason over.

### Supabase

1. **Storage RLS (bucket `secure-documents`):** Allow authenticated users to upload/list/read in paths scoped by their account. Example policy (run in SQL Editor):
   - “Users can upload to their account folder”:
     - Policy name: e.g. `Users can upload documents for their account`
     - Allowed operation: INSERT (upload)
     - With check: `bucket_id = 'secure-documents' AND (storage.foldername(name))[1] = 'account' AND (storage.foldername(name))[2] = auth.uid()::text` (or use a path like `account/{account_id}/...` and check that `account_id` is in the user’s memberships). Simpler: allow authenticated users to upload to `secure-documents` with a path that starts with `account/{account_id}/` and enforce `account_id` in app code.
   - For read: allow SELECT for same path pattern so users can get signed URLs for their account’s files.
   - Supabase Storage RLS uses `storage.objects`; see [Supabase Storage RLS docs](https://supabase.com/docs/guides/storage/security/access-control). Example:
     ```sql
     -- Allow authenticated users to insert into secure-documents (path structure: account/{account_id}/...)
     CREATE POLICY "Users can upload to own account path"
       ON storage.objects FOR INSERT TO authenticated
       WITH CHECK (bucket_id = 'secure-documents');

     -- Allow users to read objects in secure-documents (refine by path if needed)
     CREATE POLICY "Users can read documents"
       ON storage.objects FOR SELECT TO authenticated
       USING (bucket_id = 'secure-documents');
     ```
   - You can tighten later by parsing path and checking `account_id` against `account_memberships`.
2. **Tables:** `data_library_records`, `documents`, `evidence_attachments` already exist. Use [schema.md §3.9–3.11](../database/schema.md) for column names.

### Lovable

1. **Data library records**
   - **Create:** `supabase.from('data_library_records').insert({ account_id: currentAccountId, property_id: propertyIdOrNull, subject_category, source_type, confidence, value_numeric or value_text, unit, reporting_period_start, reporting_period_end })`. `subject_category`: e.g. scope2, scope3, waste, policy. `source_type`: connector | upload | manual.
   - **List:** `supabase.from('data_library_records').select('*').eq('account_id', currentAccountId)` (and optionally filter by `property_id`).
2. **Upload a file (e.g. bill or governance doc)**
   - Build storage path: e.g. `account/${currentAccountId}/property/${propertyId}/${year}/${month}/${uuid()}-${fileName}` (align with [architecture invariant](architecture/architecture.md)).
   - Upload file: `supabase.storage.from('secure-documents').upload(path, file, { upsert: false })`.
   - Insert document: `supabase.from('documents').insert({ account_id: currentAccountId, storage_path: path, file_name: file.name, mime_type: file.type, file_size_bytes: file.size })`. Get returned `id` as `documentId`.
   - If the file is evidence for a data library record: `supabase.from('evidence_attachments').insert({ data_library_record_id, document_id })`.
3. **List records with evidence:** Query `data_library_records` and join or query `evidence_attachments` and `documents` to show attached files. For agent context, you only need record metadata + document IDs or paths; the agent can receive signed URLs if it needs to read files (optional).

**Done when:** You can create a data library record (e.g. “Electricity Jan 2026”, “Sustainability policy”), upload a PDF, attach it to the record, and see rows in `data_library_records`, `documents`, and `evidence_attachments`.

---

## Phase 4: End-use nodes (optional but improves agent)

**Why:** The Data Readiness / Boundary agent uses nodes (e.g. E_TENANT_PLUG, W_TOILETS) linked to systems for controllability. If you have these in Supabase, you can include them in the agent context.

### Supabase

- Table `end_use_nodes` exists. Columns: `property_id`, `system_id`, `node_id` (e.g. E_TENANT_PLUG), `node_category`, `utility_type`, `control_override`, `allocation_weight`, `applies_to_space_ids`.

### Lovable

- **Create/list nodes:** Same as systems: insert and select by `property_id`. Link to `system_id` (UUID from `systems`) and optionally `applies_to_space_ids` (array of space UUIDs). Use node IDs and categories from [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) or the [140 Aldersgate register](sources/140-aldersgate/building-systems-register.md).
- You can start without nodes and still run the agent with a minimal context (property, spaces, systems, data library records); add nodes when you’re ready for full controllability output.

---

## Phase 5: Build agent context and call the agent

**Why:** So the app can run the AI agent (Data Readiness / Boundary) with the property’s real data and show (and optionally store) results.

### Agent context shape (what the agent expects)

The agent expects a JSON body like the example in the AI Agents repo: `agent/contexts/140-aldersgate-2026.json` (propertyId, propertyName, reportingYear, spaces, systems, nodes, dataLibraryRecords, evidence). Minimal shape:

- `propertyId`, `propertyName`, `reportingYear`
- `reportingBoundary` (optional): e.g. `{ boundaryApproach, includedPropertyIds, methodologyFramework }`
- `floorsInScope` (optional): array of floor identifiers the tenant occupies (from `properties.floors_in_scope`); helps agent reason about reporting boundary
- `spaces`: array of `{ id, name, spaceClass, control, inScope, area, floorReference, spaceType, parentSpaceId }`; optional `parentSpaceId` for hierarchy (subspaces); optional `children` array when sending a tree. Flat list is fine; agent can build tree from parentSpaceId.
- `systems`: array of `{ id, category, controlledBy, meteringStatus, allocationMethod, servesSpaces }` (agent accepts `category`; DB has `system_category` + `system_type` — map when building context)
- `nodes` (optional): array of `{ id, systemId, type, controlOverride, allocationWeight, spaceIds }`
- `dataLibraryRecords`: array of `{ id, category, reportingYear, propertyId, confidenceLevel }` (and optionally more fields)
- `evidence`: array of `{ id, recordId, recordType, recordName, fileName }` (for display; agent may use for references)
- Optional: `workforceDatasets`, `certificates` (can be empty arrays)

**ID format:** Agent is flexible. You can use Supabase UUIDs as `id` for spaces/systems and map `servesSpaces` / `spaceIds` to those same UUIDs (or to short ids like `sp-gf` if you store them). Keep `systemId` in nodes as the system’s `id` (UUID or string).

### Lovable

1. **“Run agent” (e.g. from a property or Data Library page)**
   - Fetch for the selected property and current account:
     - `properties` (one row by id)
     - `spaces` (by property_id)
     - `systems` (by property_id)
     - `end_use_nodes` (by property_id) if you have them
     - `data_library_records` (by property_id or account)
     - `evidence_attachments` + `documents` for those records (to build `evidence` list)
   - Build the context object that matches the agent’s expected shape (map DB column names to the agent’s: e.g. `system_category` → `category`, `space_class` → `spaceClass`, `control` → same or map to tenant_controlled etc.).
   - Choose agent type: Data Readiness or Boundary (different endpoints or same endpoint with a type flag, depending on how you host the agent).
2. **Call the agent**
   - POST to your agent URL (e.g. `https://your-agent.onrender.com/api/data-readiness` or `/api/boundary`) with body = context JSON. Use the same request/response contract as the agent (see Agent repo `AGENT-SUMMARY.md` and API).
   - Display the agent’s response (summary, payload, next actions, etc.) in the UI.
3. **Optional: persist run in Supabase**
   - Before or after the POST: `supabase.from('agent_runs').insert({ account_id: currentAccountId, property_id: propertyId, agent_type: 'data_readiness' | 'boundary', status: 'pending' })`. Get `runId`.
   - After success: `supabase.from('agent_runs').update({ status: 'completed' }).eq('id', runId)`, then `supabase.from('agent_findings').insert({ agent_run_id: runId, finding_type: '...', payload: responsePayload })`.
   - This gives you a history of runs and findings in the DB.

### Supabase

- No extra schema. `agent_runs` and `agent_findings` already exist and RLS allows members to insert/read.

### Secure backend repo (this repo)

- No code changes. Keep [schema.md](../database/schema.md) and [architecture](architecture/architecture.md) as the reference. This plan lives in `docs/implementation-plan-lovable-supabase-agent.md`. For **every change** that affects the agent (data shape, context, API), update [docs/for-agent/README.md](for-agent/README.md) and the AI agent project so the agent stays in sync.

### AI Agents folder

- No change. The agent already accepts context and returns findings. Ensure the deployed agent URL is the one Lovable calls. If you run the agent locally, use a tunnel (e.g. ngrok) or deploy to Render (or similar) and point Lovable at that URL. When you work in the agent repo, use [docs/for-agent/README.md](for-agent/README.md) as the sync checklist.

---

## Order of work (summary)

1. **Lovable:** Wire onboarding to create `accounts` + `account_memberships` in Supabase. Load current account from memberships.
2. **Lovable:** Replace property/space/system reads and writes with Supabase (`properties`, `spaces`, `systems`). Use currentAccountId and schema column names.
3. **Supabase:** Add Storage RLS for `secure-documents` so authenticated users can upload and read.
4. **Lovable:** Data library: create records in `data_library_records`; upload files to Storage and link via `documents` and `evidence_attachments`.
5. **Lovable:** “Run agent” flow: fetch property, spaces, systems, nodes (if any), data library records, evidence; build context JSON; POST to agent; show result; optionally save to `agent_runs` and `agent_findings`.

After that you can create a property, add spaces/systems, add data library records and attach bills/governance files, and run the AI agent with that data.

---

## Lovable prompt for Phase 1 (account + membership)

You can paste this into Lovable to implement Phase 1:

```
When the user completes the account setup step in onboarding (account name and type), write to Supabase instead of localStorage:

1. Insert into the accounts table: name = account name they entered, account_type = their choice (corporate_occupier or asset_manager). Use .select('id').single() to get the new account id.

2. Insert into the account_memberships table: account_id = that new account id, user_id = current Supabase auth user id (session.user.id), role = 'admin'.

3. Store the account_id in app state (and in localStorage as currentAccountId) so the rest of the app uses it for all Supabase queries. When the app loads and the user is logged in, load their current account by querying account_memberships where user_id = session.user.id and use the first account_id as current account.
```

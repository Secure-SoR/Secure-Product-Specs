# Step-by-step: Lovable + Supabase + AI Agent

Goal: Create properties, add spaces/systems and data library (bills, governance), then run the AI agent (Data Readiness / Boundary) with real data from Supabase.

---

## Next priorities (when you return)

**Order of work:**

1. **Create the Nodes part** — End-use nodes linked to systems (table `end_use_nodes`). Schema and taxonomy in [building-systems-taxonomy.md §2](../data-model/building-systems-taxonomy.md) and [building-systems-register.md §B](../sources/140-aldersgate/building-systems-register.md). Implementation plan: Phase 4 “End-use nodes” and “After systems: Nodes”.
2. **Data Library** — Data library records + file uploads (bills, governance), Storage, documents, evidence. Implementation plan: Phase 3.
3. **Scope 1, 2, 3 calculation** — Ensure Scope 1, 2, 3 are calculated correctly (data model, reporting, boundaries). Align with canonical and docs (e.g. data-library, allocation, metering).
4. **Then move on to agent** — Build agent context from Supabase, call the agent, persist runs/findings. Implementation plan: Phase 5; for-agent: [README.md](../for-agent/README.md), [AGENT-TASKS.md](../for-agent/AGENT-TASKS.md).

*Note added: systems + upload register are working; DB triggers normalize controlled_by, allocation_method, metering_status for imports.*

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
| *(app-only)* | For "My Tenant Spaces" filter: when mapping Supabase→BuildingSpace, set tenantAccountId (and tenant) from currentUser for rows where space_class === 'tenant'; DB does not store these on spaces. |
| systems.system_category | Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring (from [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md)) |
| systems.system_type | Per category: e.g. GridLVSupply, ElectricitySubmeters, GasSupply (Power); CentralPlant_Unknown, ZoneControls (HVAC); TenantLighting, OccupancySensors (Lighting); see taxonomy |
| systems.controlled_by | tenant, landlord, shared |
| systems.maintained_by | Free text (e.g. "Landlord", "Tenant (local) / Landlord (plant)") |
| systems.metering_status | none, partial, full |
| systems.allocation_method | measured, area, estimated |
| systems.allocation_notes | Free text |
| systems.key_specs | Key specs from register (e.g. meter IDs, plant specs) |
| systems.spec_status | e.g. REAL, PLACEHOLDER |
| systems.serves_space_ids | Array of space UUIDs (optional) |
| systems.serves_spaces_description | Human-readable "Serves Spaces" (e.g. "Ground, 4th, 5th", "Whole Building") |

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

**Implemented in Lovable (current behaviour):** The "Create the spaces" flow with subspace support is in place.

---

## Physical and Technical page — Building Systems (taxonomy + register)

The **Physical and Technical** page hosts **building systems**. The UI must follow the **Building Systems Taxonomy** (categories and system types) and support all data fields from the **Building Systems Register** so users can create and edit systems that match the register, save them to Supabase, and later add **nodes** linked to systems.

**References:**
- [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) — system categories and system types per category.
- [building-systems-register.md](../sources/140-aldersgate/building-systems-register.md) — example register with columns: System Name, systemCategory, systemType, Controlled By, Maintained By, Serves Spaces, Metering Status, Allocation Method, Key Specs, Spec Status.

**DB:** Table `systems` has columns: name, system_category, system_type, space_class, controlled_by, maintained_by, metering_status, allocation_method, allocation_notes, key_specs, spec_status, serves_space_ids, serves_spaces_description. For existing DBs run: `ALTER TABLE public.systems ADD COLUMN IF NOT EXISTS key_specs text, ADD COLUMN IF NOT EXISTS spec_status text, ADD COLUMN IF NOT EXISTS serves_spaces_description text;`

### UI: Categories from Building Systems Taxonomy

Use these **system categories** as the top-level structure on the Physical and Technical page (e.g. sections or tabs): **Power**, **HVAC**, **Lighting**, **PlugLoads**, **Water**, **Waste**, **BMS**, **Lifts**, **Monitoring**. For each category, the **system types** are fixed per taxonomy (e.g. Power: GridLVSupply, ElectricitySubmeters, GasSupply, UPS, Generator, PVInverter; HVAC: CentralPlant_Unknown, Boilers, ZoneControls, …; Lighting: TenantLighting, LegacyLightingControl, OccupancySensors, …). See [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) for the full table.

### Register fields (per system)

When creating or editing a building system, the form should include all fields that appear in the building systems register: **Name**, **System category** (dropdown from taxonomy), **System type** (dropdown dependent on category), **Controlled by** (dropdown: tenant | landlord | shared; default from selected "Serves spaces" when set, user can override), **Maintained by** (text), **Serves spaces** (text description e.g. "Ground, 4th, 5th" or "Whole Building", and optionally link to space IDs), **Metering status** (none | partial | full), **Allocation method** (measured | area | estimated | **mixed** — part measured, part allocated; use Allocation notes to describe the split), **Allocation notes** (text), **Key specs** (text, e.g. meter IDs, plant specs), **Spec status** (e.g. REAL, PLACEHOLDER). Save all of these to the `systems` table in Supabase.

### Lovable prompt: Physical and Technical — Building Systems (taxonomy + register + save)

Paste the following into Lovable to align the Physical and Technical page with the taxonomy and register and persist systems to Supabase.

```
On the Physical and Technical page (building systems):

1. **UI structure by taxonomy:** Organise the page by the Building Systems Taxonomy categories: Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring. Each category is a section (or tab). Within each section, list the systems that belong to that category (system_category = that category). When adding a new system, the user selects the category first; then the system type dropdown shows only the types for that category (from the taxonomy — e.g. Power: GridLVSupply, ElectricitySubmeters, GasSupply, UPS, Generator, PVInverter; HVAC: CentralPlant_Unknown, Boilers, Chillers, ZoneControls, …; Lighting: TenantLighting, LegacyLightingControl, OccupancySensors, EnvironmentalSensors, GatewayDevices, …). Use the full list from docs/data-model/building-systems-taxonomy.md or the backend repo.

2. **Form fields (building systems register):** When creating or editing a system, the form must include: Name (required), System category (required, from taxonomy), System type (required, dependent on category), Controlled by (dropdown: tenant | landlord | shared — when user selects Serves spaces, default this from the selected spaces' control; user can override), Maintained by (text), Serves spaces (text description, e.g. "Ground, 4th, 5th" or "Whole Building" — store in serves_spaces_description; optionally also link to space IDs in serves_space_ids), Metering status (none | partial | full), Allocation method (measured | area | estimated | mixed), Allocation notes (text; when allocation is "mixed", describe the split e.g. part service charge / part measured), Key specs (text), Spec status (text, e.g. REAL, PLACEHOLDER). All of these must be saved to the Supabase "systems" table. Map form field names to DB columns: system_category, system_type, controlled_by, maintained_by, metering_status, allocation_method, allocation_notes, key_specs, spec_status, serves_spaces_description, serves_space_ids. See [nodes-attribution-and-control.md](../data-model/nodes-attribution-and-control.md).

3. **Persistence:** Create: supabase.from('systems').insert({ account_id: currentAccountId, property_id: propertyId, name, system_category, system_type, space_class (optional), controlled_by, maintained_by, metering_status, allocation_method, allocation_notes, key_specs, spec_status, serves_space_ids, serves_spaces_description }).select().single(). List: supabase.from('systems').select('*').eq('property_id', propertyId). Update and delete by id. After create/update/delete, refetch the systems list so the UI updates.

4. **Database columns:** Ensure the systems table has key_specs, spec_status, and serves_spaces_description. If not, run in Supabase: ALTER TABLE public.systems ADD COLUMN IF NOT EXISTS key_specs text, ADD COLUMN IF NOT EXISTS spec_status text, ADD COLUMN IF NOT EXISTS serves_spaces_description text; To allow allocation_method = 'mixed' (part measured, part allocated), run in Supabase SQL Editor: `ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_allocation_method_check; ALTER TABLE public.systems ADD CONSTRAINT systems_allocation_method_check CHECK (allocation_method IN ('measured', 'area', 'estimated', 'mixed'));`

5. **Next step (nodes):** After systems are in place, we will add the ability to create end-use nodes linked to systems (node_id, node_category, utility_type, system_id, control_override, allocation_weight, etc.). For now, focus on systems only.
```

### Systems creation: save and category checklist (if systems don’t save or don’t show under the right category)

- **Save failing:** Ensure every insert includes `account_id` (current account) and `property_id` (current property). Both are required and have FK constraints. Check the browser network tab: the request body must contain these; if the UI uses different names (e.g. accountId), map them to `account_id` / `property_id`. Ensure all required fields are sent: `name`, `system_category`, `system_type`, `controlled_by`, `metering_status`, `allocation_method` (use one of: measured, area, estimated, mixed). Check Supabase RLS: the `systems` table must have a policy allowing INSERT for rows where `account_id` is in the user’s memberships (and SELECT for list). If the insert returns an error, surface it in the UI so you can see the exact DB message.
- **Not showing in DB:** After a successful insert, refetch the list with `supabase.from('systems').select('*').eq('property_id', propertyId)` and update state so the new system appears. If the list is filtered or grouped by `system_category`, ensure the saved row’s `system_category` matches the category the user selected (e.g. "HVAC" not "Hvac" or a different key). Store and send `system_category` exactly as in the taxonomy (Power, HVAC, Lighting, etc.).
- **Not showing under correct category:** The UI must group or filter the list by `system_category`. When rendering by category, use the same string as stored (e.g. `system.system_category === 'HVAC'`). If the form sends a different value (e.g. from a dropdown that stores an id instead of the category name), fix the mapping so the DB stores the taxonomy category string.

### Debug: systems insert not working

Use this when "Add system" does nothing or fails without a clear error.

**1. Exact payload Supabase expects**

The `systems` table requires these columns on insert (snake_case; values must match exactly):

| Column | Required | Allowed values |
|--------|----------|----------------|
| account_id | Yes (FK → accounts) | UUID of an account the current user is a member of |
| property_id | Yes (FK → properties) | UUID of a property in that account |
| name | Yes | Any non-empty text |
| system_category | Yes | One of: Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring, Other |
| system_type | Yes (can be null in schema but often needed in UI) | e.g. CentralPlant_Unknown, Boilers, ZoneControls (see taxonomy) |
| controlled_by | Yes | **Exactly** `tenant` or `landlord` or `shared` (lowercase) |
| metering_status | Yes | **Exactly** `none` or `partial` or `full` (lowercase) |
| allocation_method | Yes | **Exactly** `measured` or `area` or `estimated` or `mixed` (lowercase) |

Optional: maintained_by, allocation_notes, key_specs, spec_status, serves_space_ids (uuid[]), serves_spaces_description, space_class (`tenant` \| `base_building`).

**2. Typical failures**

- **`systems_controlled_by_check` violated:** The app is sending a value for `controlled_by` that isn't exactly `tenant`, `landlord`, or `shared` (lowercase). For example the UI might send "Tenant", "Landlord", "Shared", or "tenant_controlled" / "landlord_controlled" (from spaces). **Fix:** When building the insert payload, map the form value to lowercase: e.g. if the dropdown shows "Tenant", send `controlled_by: 'tenant'`; if it shows "Landlord", send `controlled_by: 'landlord'`; if "Shared", send `controlled_by: 'shared'`. Do not send space control values (`tenant_controlled` etc.) — those are for the `spaces` table only.
- **RLS / no row inserted:** User must be **signed in with Supabase Auth** (so `auth.uid()` is set). The `account_id` in the insert must be in `account_memberships` for that user. If the app uses anon key and never signs in, or sends a different account id, insert is blocked.
- **Other constraint violations:** If the UI sends "Measured" instead of `measured`, or "Partial" instead of `partial`, the CHECK constraints fail. Use **lowercase** enum values in the request body for `metering_status` and `allocation_method` too.
- **FK violation:** `account_id` must exist in `accounts`; `property_id` must exist in `properties`. Get real IDs from the same Supabase project (e.g. from `properties` table for the current property).
- **allocation_method:** If your DB was created before we added `mixed`, the CHECK may still only allow measured/area/estimated. Run:  
  `ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_allocation_method_check;`  
  `ALTER TABLE public.systems ADD CONSTRAINT systems_allocation_method_check CHECK (allocation_method IN ('measured', 'area', 'estimated', 'mixed'));`

**3. Test insert in Supabase (SQL Editor)**

Run this **after** replacing `YOUR_ACCOUNT_UUID` and `YOUR_PROPERTY_UUID` with real IDs from your `accounts` and `properties` tables (same account for both). If this succeeds, the table and RLS allow the insert; the bug is then in the app (payload or missing auth).

```sql
INSERT INTO public.systems (
  account_id,
  property_id,
  name,
  system_category,
  system_type,
  controlled_by,
  metering_status,
  allocation_method
) VALUES (
  'YOUR_ACCOUNT_UUID'::uuid,
  'YOUR_PROPERTY_UUID'::uuid,
  'Test HVAC System',
  'HVAC',
  'CentralPlant_Unknown',
  'landlord',
  'partial',
  'mixed'
)
RETURNING id, name, system_category, created_at;
```

- If you get "permission denied" or 0 rows: you're likely running as a role that doesn't pass RLS. Run the same INSERT from the **Lovable app** (e.g. via a temporary "Debug" button that does this insert and shows the result/error).
- If you get "violates check constraint": fix the value shown in the error (e.g. allocation_method or controlled_by).
- If it succeeds: check in the app that you're sending the same snake_case columns and lowercase enum values, and that `account_id` / `property_id` are the ones from the current context.

**4. In the Lovable app**

- In the handler that creates a system, log or display the **exact object** you pass to `supabase.from('systems').insert(...)` and the **error** from `.then()/.catch()` (e.g. `error.message` and `error.details`). That shows whether payload or RLS is wrong.
- Ensure the insert uses the **current** account and property (e.g. from context/route), e.g. `account_id: currentAccountId`, `property_id: currentPropertyId`, and that both are UUID strings.

### Short Lovable prompt (copy-paste: allocation, control, save)

Paste this into Lovable when fixing or implementing the building systems form:

```
Building systems form — fix/implement:

**Allocation method:** Dropdown with exactly four options: Measured, Area, Estimated, Mixed. "Mixed" = part measured and part allocated (e.g. part in service charge, part from submeters). When user selects Mixed, show Allocation notes and prompt them to describe the split (e.g. "Part service charge allocation, part direct meter"). Save as allocation_method: 'measured' | 'area' | 'estimated' | 'mixed'. DB must allow 'mixed' — if insert fails on allocation_method, run in Supabase: ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_allocation_method_check; ALTER TABLE public.systems ADD CONSTRAINT systems_allocation_method_check CHECK (allocation_method IN ('measured', 'area', 'estimated', 'mixed'));

**Controlled by:** Dropdown with Tenant, Landlord, Shared. When the user selects "Serves spaces" (one or more spaces), default the Controlled by dropdown from those spaces' control field: if all selected spaces have the same control (e.g. tenant_controlled), set dropdown to Tenant; if mixed, set to Shared. User can always change the dropdown (override).

**Save and display:** (1) Every insert must include account_id (current account) and property_id (current property). (2) After a successful insert, refetch the systems list with .eq('property_id', propertyId) and update state so the new system appears. (3) Store system_category exactly as the taxonomy string (e.g. "HVAC", "Power") so the system appears under the correct category section. (4) When grouping the list by category, use system.system_category (e.g. filter or group by system_category). (5) If insert fails, show the error message in the UI (e.g. toast or inline) so we can see the Supabase error.
```

**Quick fix prompt (insert still failing):** Paste this in Lovable:

```
The "Add system" insert is failing. Fix it:

1. When calling supabase.from('systems').insert(...), the body MUST use snake_case and exact values: account_id (UUID of current account), property_id (UUID of current property), name, system_category (e.g. "HVAC"), system_type (e.g. "CentralPlant_Unknown"), controlled_by ("tenant"|"landlord"|"shared" — lowercase), metering_status ("none"|"partial"|"full" — lowercase), allocation_method ("measured"|"area"|"estimated"|"mixed" — lowercase). Optional: maintained_by, allocation_notes, key_specs, spec_status, serves_space_ids, serves_spaces_description.

2. Get account_id and property_id from the same place other pages use (e.g. current account and selected property). Do not send camelCase (e.g. accountId) — Supabase expects account_id, property_id.

3. On insert, use .then() and .catch(). On error, show the full error to the user (e.g. error.message or JSON.stringify(error)) in a toast or alert so we can see the real Supabase message. On success, refetch the systems list with .eq('property_id', propertyId) and update state.

4. If the error says "violates check constraint", the value for controlled_by, metering_status, or allocation_method is wrong — ensure lowercase and one of the allowed values. **Specifically:** If you see "systems_controlled_by_check", the app is sending something other than exactly "tenant", "landlord", or "shared" (e.g. "Tenant" or "tenant_controlled"). Map the dropdown value to lowercase before sending: controlled_by must be one of tenant | landlord | shared.
```

### After systems: Nodes

Once building systems are created and saved, the next step is **nodes** (end-use nodes linked to systems). The schema and taxonomy for nodes are in [building-systems-taxonomy.md §2](../data-model/building-systems-taxonomy.md) and [building-systems-register.md §B](../sources/140-aldersgate/building-systems-register.md). For how nodes are **attributed**, **linked to consumption**, and how **control** is derived from spaces, see [nodes-attribution-and-control.md](../data-model/nodes-attribution-and-control.md). Nodes will be added in a follow-up (table `end_use_nodes`, fields: system_id, node_id, node_category, utility_type, control_override, allocation_weight, applies_to_space_ids).

### Upload building systems register (CSV / Excel) — recommended next

Add a button on the Physical and Technical page (e.g. **"Upload register"** or **"Import from file"**) so users can upload a **Building Systems Register** as CSV or Excel and have rows extracted and inserted into the `systems` table. This is **feasible without a backend** by parsing in the browser.

#### Column mapping (spreadsheet → DB)

Match headers case-insensitively and trim spaces. Support these header variants:

| Spreadsheet header (any variant) | DB column | Required | Notes |
|----------------------------------|-----------|----------|--------|
| System Name, Name | name | Yes | |
| systemCategory, System Category, Category | system_category | Yes | One of: Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring, Other. Pass through as-is if already valid; else leave blank and skip row or default to Other. |
| systemType, System Type, Type | system_type | No | e.g. GridLVSupply, CentralPlant_Unknown |
| Controlled By, Controlled by | controlled_by | Yes | Normalize with table below |
| Maintained By, Maintained by | maintained_by | No | |
| Serves Spaces, Serves spaces | serves_spaces_description | No | |
| Metering Status, Metering status | metering_status | Yes | Normalize with table below |
| Allocation Method, Allocation method | allocation_method | Yes | Normalize with table below |
| Key Specs, Key specs | key_specs | No | |
| Spec Status, Spec status | spec_status | No | e.g. REAL, PLACEHOLDER |

#### Normalization rules (before insert)

Apply these so the DB CHECK constraints pass. Use lowercase and exact values.

**controlled_by** (output must be `tenant` | `landlord` | `shared`):

- If cell (after trim/lower) contains or equals: tenant, tenant_controlled → `tenant`
- If contains or equals: landlord, landlord_controlled, landlord (billing) → `landlord`
- If contains or equals: shared → `shared`
- Else default to `shared`

**metering_status** (output must be `none` | `partial` | `full`):

- If cell suggests no/not metered: "not tenant-metered", "not metered", "fiscal only", "n/a", "data-only", "included in electricity" → `none`
- If cell suggests partial: "submetered", "partial", "single fiscal meter", "measured by weight", "direct measured" (when building-level) → `partial`
- If cell suggests full tenant metering: "submetered" (tenant), "direct measured" (tenant) → `full`
- Else default to `partial`

**allocation_method** (output must be `measured` | `area` | `estimated` | `mixed`):

- "direct measured", "direct billed", "measured" → `measured`
- "area allocation", "service charge", "embedded in service charge", "allocation" → `area`
- "estimated" → `estimated`
- "mixed", "part measured part allocated", "electricity + service charge" → `mixed`
- Else default to `estimated`

#### Step-by-step implementation

1. **Button:** On Physical and Technical page, add "Upload register" (or "Import from file"). On click: open file input accepting `.csv`, `.xlsx`.
2. **Read file:** Use `FileReader` or pass `File` to parser. CSV: Papa Parse with `header: true`. Excel: SheetJS — read first sheet, row 0 = headers, rows 1+ = data; build array of objects `{ [header]: value }`.
3. **Map columns:** For each row object, build a new object with DB keys. Find each DB column by checking header keys (case-insensitive). Apply normalization for controlled_by, metering_status, allocation_method.
4. **Validate rows:** Skip or collect errors for rows missing required fields (name, system_category, controlled_by, metering_status, allocation_method). Optionally skip blank rows (all cells empty).
5. **Preview:** Set state with parsed rows. Show a table (e.g. first 20 rows) with columns: Name, Category, Type, Controlled by, Metering, Allocation. Show total count and "X rows will be imported, Y skipped".
6. **Confirm:** Buttons "Import" and "Cancel". On Cancel, clear state and close.
7. **Insert:** On Import, for each valid row call `supabase.from('systems').insert({ account_id: currentAccountId, property_id: currentPropertyId, name, system_category, system_type, controlled_by, metering_status, allocation_method, maintained_by: maintained_by || null, serves_spaces_description: serves_spaces_description || null, key_specs: key_specs || null, spec_status: spec_status || null })`. Use current account and property from app context. Optionally batch (e.g. 10 at a time) to avoid timeouts. Collect errors per row if any.
8. **Result:** Toast or modal: "N systems added." If any failed: "M failed: [first error message]." Refetch systems list and close preview.
9. **Optional:** Upload the file to Storage path `account/{accountId}/property/{propertyId}/register-imports/{ISO date}-{sanitized filename}` and insert into `documents` with that path so the register is kept as evidence.

#### Template

A sample CSV with expected headers is in [docs/templates/building-systems-register-template.csv](../templates/building-systems-register-template.csv). Users can export their register to CSV with the same column names (or use the template and fill in).

#### PDF register

Extracting from a **PDF** (scanned or digital) would require a backend or Edge Function (e.g. PDF table extraction) or an AI step. Defer to a later phase; MVP is CSV/Excel only.

#### Import fails: `systems_allocation_method_check`

If the import shows **"Import failed: new row for relation 'systems' violates check constraint 'systems_allocation_method_check'"**, the file’s "Allocation Method" column has values the DB doesn’t accept (e.g. "Service charge allocation", "Direct measured"). The DB only accepts exactly: `measured`, `area`, `estimated`, `mixed` (lowercase).

**Fix (choose one or both):**

1. **Database:** Run the migration that normalizes allocation_method on insert so any phrase is converted to one of the four. In Supabase SQL Editor, run the contents of [docs/database/migrations/fix-systems-allocation-method-import.sql](../database/migrations/fix-systems-allocation-method-import.sql). That adds a trigger to map e.g. "Service charge allocation" → `area`, "Direct measured" → `measured`, etc.
2. **Lovable:** In the register-import code, normalize the Allocation Method column before calling insert: convert the cell value (case-insensitive) to one of `measured`, `area`, `estimated`, `mixed` using the rules in the "Normalization rules" table above (e.g. "Direct measured"/"Direct billed" → measured; "Service charge"/"Area allocation"/"Embedded in service charge" → area; "mixed"/"part measured" → mixed; else estimated). Then the payload always sends a valid value.

**If you see "systems_metering_status_check":** The "Metering Status" column has values the DB doesn't accept (e.g. "Submetered", "Fiscal only", "Not tenant-metered"). Run in Supabase SQL Editor the contents of [fix-systems-metering-status-import.sql](../database/migrations/fix-systems-metering-status-import.sql) — that trigger normalizes them to `none` | `partial` | `full`.

**If the error persists after running the DB migration:** Paste the **full** Lovable prompt below (the long one starting with "Implement 'Upload register'…") so the import flow is reimplemented with explicit normalization. Or paste this **allocation-only fix** into Lovable if you already have the upload button and preview:

```
In the register import (Upload register) code: before calling supabase.from('systems').insert() for each row, normalize allocation_method so the payload always has exactly one of: "measured", "area", "estimated", "mixed" (lowercase). Do not send the raw CSV value. Use a function: take the "Allocation Method" cell string (e.g. "Service charge allocation", "Direct measured"), convert to lowercase, then if it includes "direct" and "measured" or "direct" and "billed" → use "measured"; if it includes "service charge" or "area allocation" or "embedded" or "whole building" or "submeter" → use "area"; if it includes "mixed" or "part measured" → use "mixed"; if it includes "estimated" → use "estimated"; otherwise use "estimated". Set the insert payload field allocation_method to this normalized value. Same for metering_status: must be "none", "partial", or "full"; and controlled_by: must be "tenant", "landlord", or "shared" (normalize from Tenant/Landlord/Shared or tenant_controlled/landlord_controlled).
```

---

**Lovable prompt (full) — paste into Lovable to implement the upload flow:**

```
Implement "Upload register" on the Physical and Technical (building systems) page.

1. Add an "Upload register" button. On click, open a file input that accepts .csv and .xlsx. Parse the file in the browser: use Papa Parse for CSV (Papa.parse(file, { header: true })) and a library like xlsx/sheetjs for Excel (first sheet, first row = headers). Result: array of objects, each keyed by column header.

2. Map columns to DB (match headers case-insensitively, trim). Map: System Name or Name → name; systemCategory or System Category or Category → system_category; systemType or System Type → system_type; Controlled By → controlled_by; Maintained By → maintained_by; Serves Spaces → serves_spaces_description; Metering Status → metering_status; Allocation Method → allocation_method; Key Specs → key_specs; Spec Status → spec_status.

3. Normalize before insert: controlled_by: Tenant/tenant_controlled → "tenant", Landlord/landlord_controlled → "landlord", else "shared". metering_status: "Not tenant-metered"/"Not metered"/"Fiscal only"/"N/A"/"Data-only" → "none"; "Submetered"/"Direct measured" → "partial" or "full"; else "partial". allocation_method: "Direct measured"/"Direct billed" → "measured"; "Service charge"/"Area allocation"/"Embedded in service charge" → "area"; "mixed"/"part measured" → "mixed"; else "estimated". All values must be lowercase in the payload.

4. Skip rows missing required fields: name, system_category, controlled_by, metering_status, allocation_method. Show how many rows are valid and how many skipped.

5. Show a preview table (e.g. first 20 rows) with: Name, Category, Type, Controlled by, Metering, Allocation. Buttons: "Import" and "Cancel".

6. On Import: for each valid row, insert into supabase.from('systems') with account_id (current account), property_id (current property), and the mapped fields (name, system_category, system_type, controlled_by, metering_status, allocation_method, maintained_by, serves_spaces_description, key_specs, spec_status). Use .insert() per row or in small batches. On success, show "N systems added", refetch the systems list, and close the preview. On error, show the error message and which row failed if possible.

7. Optional: upload the file to supabase.storage.from('secure-documents').upload() under account/{accountId}/property/{propertyId}/register-imports/{date}-{filename} and create a row in documents table for evidence.
```

**Lovable prompt (short):** Same as before, for quick reference:

```
On the Physical and Technical (building systems) page, add an "Upload register" button. When clicked, the user selects a CSV or Excel file (.csv, .xlsx). Parse the file in the browser (e.g. Papa Parse for CSV, xlsx/sheetjs for Excel). Map columns to systems table: System Name → name, systemCategory or System Category → system_category, systemType or System Type → system_type, Controlled By → controlled_by (normalize to tenant|landlord|shared), Maintained By → maintained_by, Serves Spaces → serves_spaces_description, Metering Status → metering_status (normalize to none|partial|full), Allocation Method → allocation_method (normalize to measured|area|estimated|mixed), Key Specs → key_specs, Spec Status → spec_status. Normalize enum values (lowercase; Tenant/tenant_controlled → tenant, Landlord/landlord_controlled → landlord). Show a preview table and "Import" / "Cancel". On Import, insert each row into supabase.from('systems') with account_id and property_id set to the current account and property. Show how many were added and refetch the systems list. Skip rows missing required fields (name, system_category, controlled_by, metering_status, allocation_method).
```

---

## Phase 3: Data library records + file uploads (bills, governance)

**Why:** So the agent has data library records and evidence (e.g. bills, governance docs) to reason over.

**Data Library structure (Lovable):** Canonical taxonomy: [Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md](../sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md) (four layers, access IDs, reporting rules). [data-library-implementation-context.md](../data-library-implementation-context.md) maps Lovable to backend; [sources/lovable-data-library-context.md](../sources/lovable-data-library-context.md) (overview) and [sources/lovable-data-library-spec.md](../sources/lovable-data-library-spec.md) (detailed spec: routes, record creation by category, evidence tags, limitations). Use canonical `subject_category`: energy, water, waste, indirect_activities, certificates, esg, governance, targets, occupant_feedback. Records: optional `name`; `source_type`: connector | upload | manual | rule_chain; `confidence`: measured | allocated | estimated | cost_only. Evidence: optional `tag` and `description` on evidence_attachments (migration in docs). Run [add-data-library-record-name-and-enums.sql](../database/migrations/add-data-library-record-name-and-enums.sql) if not already applied.

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
   - **Create:** `supabase.from('data_library_records').insert({ account_id: currentAccountId, property_id: propertyIdOrNull, subject_category, name (optional), source_type, confidence, value_numeric or value_text, unit, reporting_period_start, reporting_period_end })`. `subject_category`: use canonical list (energy, waste, certificates, esg, governance, targets, occupant_feedback). `source_type`: connector | upload | manual | rule_chain. `confidence`: measured | allocated | estimated | cost_only.
   - **List:** `supabase.from('data_library_records').select('*').eq('account_id', currentAccountId)` (and optionally filter by `property_id`, subject_category).
2. **Upload a file (e.g. bill or governance doc)**
   - Build storage path: e.g. `account/${currentAccountId}/property/${propertyId}/${year}/${month}/${uuid()}-${fileName}` (align with [architecture invariant](architecture/architecture.md)).
   - Upload file: `supabase.storage.from('secure-documents').upload(path, file, { upsert: false })`.
   - Insert document: `supabase.from('documents').insert({ account_id: currentAccountId, storage_path: path, file_name: file.name, mime_type: file.type, file_size_bytes: file.size })`. Get returned `id` as `documentId`.
   - If the file is evidence for a data library record: `supabase.from('evidence_attachments').insert({ data_library_record_id, document_id })`.
3. **List records with evidence:** Query `data_library_records` and join or query `evidence_attachments` and `documents` to show attached files. For agent context, you only need record metadata + document IDs or paths; the agent can receive signed URLs if it needs to read files (optional).

**Done when:** You can create a data library record (e.g. “Electricity Jan 2026”, “Sustainability policy”), upload a PDF, attach it to the record, and see rows in `data_library_records`, `documents`, and `evidence_attachments`.

**Step-by-step guide (Lovable):** [data-library-lovable-supabase-step-by-step.md](../data-library-lovable-supabase-step-by-step.md) — ordered steps to make the Data Library UI dynamic: migrations, Storage bucket, replace mock list, create record, upload + attach evidence, evidence panel, property scoping, optional period filter, Governance/Targets.

**What to do next (order of work):** [data-library-what-to-do-next.md](../data-library-what-to-do-next.md) — confirms for-agent is updated; ordered Data Library steps (2.1–2.10); then move to **Dashboards (KPI coverage)**; quick reference to all key Data Library / Emissions / Coverage docs.

---

## Phase 4: End-use nodes (optional but improves agent)

**Why:** The Data Readiness / Boundary agent uses nodes (e.g. E_TENANT_PLUG, W_TOILETS) linked to systems for controllability. If you have these in Supabase, you can include them in the agent context.

**Single source of truth:** [end-use-nodes-spec.md](../data-model/end-use-nodes-spec.md) — merges 140 Aldersgate End-Use Nodes v1 with our schema, space placeholders, control resolution rule, validation/weight rules, and JSON for agent context.

### Supabase

- Table `end_use_nodes` exists. Columns: `property_id`, `system_id`, `node_id` (e.g. E_TENANT_PLUG), `node_category`, `utility_type`, `control_override`, `allocation_weight`, `applies_to_space_ids`, `notes`, `auto_generated` (optional). Unique on `(property_id, node_id)`. For existing DBs: `ALTER TABLE public.end_use_nodes ADD COLUMN IF NOT EXISTS auto_generated boolean DEFAULT false;` if you need the autogeneration flag.

### Lovable

- **Create/list nodes:** Same as systems: insert and select by `property_id`. Link to `system_id` (UUID from `systems`) and `applies_to_space_ids` (array of space UUIDs; replace placeholders like SPACE_TENANT_DEMISE with real space IDs). Use node IDs and categories from [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) or the [140 Aldersgate register §B](sources/140-aldersgate/building-systems-register.md). **Control resolution:** node.control_override ?? system.controlled_by (mapped to TENANT/LANDLORD/SHARED) ?? dominantSpace.control (tenant_controlled→TENANT, etc.). **Validation:** each node has exactly one system_id; ≥1 applies_to_space_ids; same property as system; allocation_weight 0..1; per-utility weights sum to ~1.0 when present. See [end-use-nodes-spec.md](../data-model/end-use-nodes-spec.md).
- **Lovable prompts for nodes:** Full copy-paste prompts for list/create/edit/delete nodes and optional "Seed default nodes" are in [docs/lovable-prompts/nodes-implementation.md](lovable-prompts/nodes-implementation.md). Paste Prompt 1 into Lovable to implement the nodes UI; optionally Prompt 2 for seeding from the 140A register.
- **Yes — update the Lovable UI to add nodes.** The app needs flows to list nodes by property (and optionally by system), create a node (system, node_id, node_category, utility_type, applies_to_space_ids, control_override, allocation_weight, notes), and edit/delete. Optionally: “Add default nodes” seeded from the 140A register (§B), resolving system by name and placeholders by spaces. **Multiple nodes per system is normal** (e.g. plug loads and process loads on the same system). When **bills are invoices only** (no end-use breakdown), use node **allocation_weights** to split the system/meter total into end-uses for reporting — see [nodes-attribution-and-control.md](../data-model/nodes-attribution-and-control.md) §4.
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

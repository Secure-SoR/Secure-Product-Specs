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
   - **Create:** When user adds a property, `supabase.from('properties').insert({ account_id: currentAccountId, name, address, country, floors, total_area })`. Use returned `id` as `propertyId`.
   - **List:** `supabase.from('properties').select('*').eq('account_id', currentAccountId)`.
   - **Update / delete:** Use `.update()` / `.delete()` with the property `id`. RLS will allow only if `account_id` matches the user’s membership.
2. **Spaces**
   - **Create:** `supabase.from('spaces').insert({ property_id, name, space_class, control, space_type, area, floor_reference, in_scope })`. `space_class`: `tenant` | `base_building`. `control`: `landlord_controlled` | `tenant_controlled` | `shared`.
   - **List:** `supabase.from('spaces').select('*').eq('property_id', propertyId)`.
3. **Systems**
   - **Create:** `supabase.from('systems').insert({ account_id: currentAccountId, property_id, name, system_category, system_type, controlled_by, metering_status, allocation_method, serves_space_ids })`. `system_category`: e.g. Power, HVAC, Lighting, Water, Waste, BMS, Lifts (see [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md)). `controlled_by`: `tenant` | `landlord` | `shared`. `serves_space_ids`: array of space UUIDs.
   - **List:** `supabase.from('systems').select('*').eq('property_id', propertyId)`.

**Field mapping (Lovable UI → Supabase):**

| Supabase column   | Example value / notes |
|-------------------|------------------------|
| properties.name   | Property name |
| properties.address, .country, .floors, .total_area | Optional |
| spaces.space_class | `tenant` \| `base_building` |
| spaces.control    | `tenant_controlled` \| `landlord_controlled` \| `shared` |
| systems.system_category | Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring |
| systems.system_type | e.g. GridLVSupply, Boilers, TenantLighting |
| systems.controlled_by | tenant, landlord, shared |
| systems.metering_status | none, partial, full |
| systems.allocation_method | measured, area, estimated |

**Done when:** You can create a property, add spaces and systems in the app, and see them in Supabase Table Editor.

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
- `spaces`: array of `{ id, name, spaceClass, control, inScope, area }`
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

- No code changes. Keep [schema.md](../database/schema.md) and [architecture](architecture/architecture.md) as the reference. This plan lives in `docs/implementation-plan-lovable-supabase-agent.md`.

### AI Agents folder

- No change. The agent already accepts context and returns findings. Ensure the deployed agent URL is the one Lovable calls. If you run the agent locally, use a tunnel (e.g. ngrok) or deploy to Render (or similar) and point Lovable at that URL.

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

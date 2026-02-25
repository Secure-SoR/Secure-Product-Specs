# Data Library — Step-by-step: Dynamic UI in Lovable with Supabase

Follow these steps in order to replace mock Data Library data and localStorage evidence with **Supabase** (tables + Storage). Schema and flows are in [data-library-implementation-context.md](data-library-implementation-context.md) and [implementation-plan-lovable-supabase-agent.md](implementation-plan-lovable-supabase-agent.md).

**Canonical taxonomy:** [Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md](sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md) defines the four layers (Activity, Emissions, Governance & Strategy, Compliance & Disclosure), access IDs per tile, and reporting rules. Use it so tiles, routes, and permissions stay aligned (e.g. **targets** uses access ID `targets`, not `esg_governance`; **Emissions** is read-only).

**Energy & Waste page design:** [Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md](sources/Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md) — when making `/data-library/energy` and `/data-library/waste` dynamic, follow the component-based layout (coverage summary, Tenant Electricity / Landlord Utilities / Heating / Water; Waste contractor and streams), upload auto-tagging, and space awareness. Do not mix waste UI inside the Energy page.

---

## Prerequisites

- Lovable app is **connected to your Supabase project** (env: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` or equivalent).
- You have **account creation** working (e.g. Edge Function or service role so users get `accounts` + `account_memberships`).
- **Current account ID** and **selected property ID** (or null) are available in the app (e.g. from context or hooks).

---

## Step 1: Run migrations in Supabase

In the Supabase SQL Editor, run these **once** (in order):

1. **Record name and enums** (so the UI can use Record Name, Rule Chain, Cost Only):
   - Copy and run: [docs/database/migrations/add-data-library-record-name-and-enums.sql](database/migrations/add-data-library-record-name-and-enums.sql)
   - This adds `name` to `data_library_records` and extends `source_type` (rule_chain) and `confidence` (cost_only).

2. **Evidence tag and description** (optional; for Evidence panel tags like Invoice, Contract):
   - Copy and run: [docs/database/migrations/add-evidence-attachment-tag-and-description.sql](database/migrations/add-evidence-attachment-tag-and-description.sql)

If you are creating the DB from scratch, use [docs/database/supabase-schema.sql](database/supabase-schema.sql) instead; it already includes these columns.

**Check:** In Table Editor, `data_library_records` has columns `name`, and `source_type` / `confidence` accept the new values. `evidence_attachments` has optional `tag` and `description` if you ran the second migration.

---

## Step 2: Create Storage bucket and RLS

1. In Supabase Dashboard → **Storage**, create a bucket named **`secure-documents`** (if it doesn’t exist). Make it **private** (not public).

2. In **SQL Editor**, run **[docs/database/migrations/add-storage-secure-documents-policies.sql](database/migrations/add-storage-secure-documents-policies.sql)** to add the two Storage RLS policies (upload + read for authenticated users). Path format from the app: `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}` (or `account/{accountId}/account-level/...` when there is no property). You can tighten later by restricting paths to the current user’s `account_id` (e.g. via a function that checks `account_memberships`).

**Check:** From your app (or Storage UI), you can upload a test file to `secure-documents` and list it.

---

## Step 3: Replace the records list with Supabase

**Goal:** The Data Library sub-pages (e.g. Water, Waste, Certificates, ESG, Indirect Activities) and any category that uses the generic table should show **real rows from `data_library_records`**, not hardcoded mock data.

1. **Create a hook or query** that loads records for the current account (and optionally property and category):
   - Table: `data_library_records`
   - Filter: `account_id = currentAccountId`
   - Optional: `property_id = selectedPropertyId` (or `property_id.is.null` when “All” / account-level)
   - Optional: `subject_category = categorySlug` (e.g. `water`, `waste`, `certificates`, `esg`, `indirect_activities`)

   Example (conceptual):

   ```ts
   const { data: records } = await supabase
     .from('data_library_records')
     .select('*')
     .eq('account_id', currentAccountId)
     .order('updated_at', { ascending: false });
   ```

   If you have a selected property and want to filter by it:

   ```ts
   .eq('property_id', selectedPropertyId)  // or .is('property_id', null) for account-level
   ```

   For a single category page (e.g. `/data-library/waste`):

   ```ts
   .eq('subject_category', 'waste')
   ```

2. **Map columns to the table:**
   - **Record Name** → `record.name` (or fallback: `record.subject_category + ' ' + period` if name is null)
   - **Ingestion Method** → `record.source_type` (show as Upload / Manual / Connector / Rule Chain)
   - **Confidence Level** → `record.confidence` (Measured / Allocated / Estimated / Cost Only)
   - **Linked Report** → leave as placeholder or future field
   - **Last Updated** → `record.updated_at`
   - **Actions** → “View” opens the drawer for that record `id`

3. **Wire the table** so it uses this data instead of the mock array. Keep the same UI (columns, View button, drawer).

**Check:** When you add a row via Supabase (Table Editor or next step), it appears in the Data Library list for that account/category.

---

## Step 4: Create a record (Manual Entry)

**Goal:** “Add Data” → “Manual Entry” (or a category-specific “Add record”) creates a row in `data_library_records`.

1. **Add a form** (dialog or inline) with at least:
   - **Name** (optional but recommended) — maps to `name`
   - **Subject category** — fixed per page (e.g. `waste`) or dropdown; maps to `subject_category`
   - **Source type** — Upload | Manual | Connector | Rule Chain → `source_type` (use `manual` for Manual Entry)
   - **Confidence** — Measured | Allocated | Estimated | Cost Only → `confidence`
   - **Reporting period** — start/end dates → `reporting_period_start`, `reporting_period_end`
   - **Property** (optional) — current selected property or “Account-level” (null) → `property_id`

   Optional: `value_numeric`, `value_text`, `unit`, `allocation_method`, `allocation_notes` for energy/waste etc.

2. **On submit:**
   - `account_id` = current account ID
   - `property_id` = selected property ID or null
   - Insert into `data_library_records` with the form values. Use canonical `subject_category` values: `energy`, `water`, `waste`, `indirect_activities`, `certificates`, `esg`, `governance`, `targets`, `occupant_feedback`.

   Example (conceptual):

   ```ts
   const { data: newRecord } = await supabase
     .from('data_library_records')
     .insert({
       account_id: currentAccountId,
       property_id: selectedPropertyId || null,
       subject_category: 'waste',
       name: form.name || null,
       source_type: 'manual',
       confidence: form.confidence,
       reporting_period_start: form.periodStart,
       reporting_period_end: form.periodEnd,
     })
     .select('id')
     .single();
   ```

3. **After insert:** Refetch the records list (or invalidate the query) and optionally open the new record’s drawer so the user can attach evidence.

**Check:** Click “Manual Entry”, fill the form, submit; a new row appears in the table and in Supabase `data_library_records`.

---

## Step 5: Upload a file and attach it to a record (Evidence)

**Goal:** In the record drawer, “Evidence & Attachments” → “Upload” stores the file in **Supabase Storage** and links it to the record via `documents` and `evidence_attachments`.

Flow: **record exists** → user selects file (+ optional tag and description) → upload file → insert `documents` → insert `evidence_attachments`.

1. **Build the storage path:**
   - Format: `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}`
   - If no property: `account/{accountId}/account-level/{yyyy}/{mm}/{documentId}-{fileName}`
   - Use the **document id** you will create in step 3 (e.g. generate a UUID in the client so the path is unique and you can use it when inserting `documents`).

2. **Upload the file:**
   - Bucket: `secure-documents`
   - Path: as above (e.g. `account/${accountId}/property/${propertyId}/${year}/${month}/${docId}-${file.name}`).
   - Use `supabase.storage.from('secure-documents').upload(path, file, { upsert: false })`.

3. **Insert document row:**
   - Table: `documents`
   - Fields: `account_id`, `storage_path`, `file_name`, `mime_type`, `file_size_bytes` (from the File object).

   ```ts
   const docId = crypto.randomUUID();
   const path = `account/${accountId}/property/${propertyId}/${year}/${month}/${docId}-${file.name}`;
   await supabase.storage.from('secure-documents').upload(path, file, { upsert: false });
   await supabase.from('documents').insert({
     id: docId,
     account_id: accountId,
     storage_path: path,
     file_name: file.name,
     mime_type: file.type,
     file_size_bytes: file.size,
   });
   ```

   (If your `documents.id` is auto-generated, create the row first with `.insert(...).select('id').single()` and use the returned `id` in the storage path and in step 4.)

4. **Attach to record:**
   - Table: `evidence_attachments`
   - Fields: `data_library_record_id` (the record in the drawer), `document_id` (from step 3). Optionally `tag` (invoice, contract, methodology, certificate, report, other) and `description` if you ran that migration.

   ```ts
   await supabase.from('evidence_attachments').insert({
     data_library_record_id: recordId,
     document_id: docId,
     tag: form.tag || null,
     description: form.description || null,
   });
   ```

5. **Validation:** Max file size (e.g. 10MB), allowed types (e.g. PDF, images, Excel, CSV) in the UI before upload.

**Check:** Open a record → Upload a file with optional tag → file appears in the Evidence list; rows appear in `documents` and `evidence_attachments` in Supabase.

---

## Step 6: Show evidence in the drawer

**Goal:** When the user clicks “View” on a record, the drawer shows **attachments from Supabase** (not localStorage).

1. **Load evidence for the selected record:**
   - Query `evidence_attachments` for `data_library_record_id = recordId`, and join or second-query `documents` to get `file_name`, `storage_path`, `file_size_bytes`, `created_at`, and optional `tag`, `description`.

   Example:

   ```ts
   const { data: attachments } = await supabase
     .from('evidence_attachments')
     .select(`
       id,
       tag,
       description,
       created_at,
       documents (id, file_name, storage_path, file_size_bytes, mime_type)
     `)
     .eq('data_library_record_id', recordId);
   ```

2. **Display** the list in the Evidence & Attachments panel (file name, tag, date, size). Optionally:
   - **Download:** use `supabase.storage.from('secure-documents').createSignedUrl(storage_path, 60)` to get a temporary URL and open or download.
   - **Delete:** remove the row from `evidence_attachments` (and optionally the object from Storage and the row from `documents` if you don’t reuse documents elsewhere).

**Check:** Open a record that has attachments; the list matches Supabase; download works if you implemented signed URLs.

---

## Step 7: Property scoping (optional but recommended)

**Goal:** When the user changes the **property selector** in the header, the Data Library list filters by that property (or shows account-level records when “All” is selected).

1. Use the **selected property ID** from your global state/context (same as other property-scoped pages).
2. When loading records (Step 3):
   - If a property is selected: filter `property_id = selectedPropertyId`.
   - If “All” or no property: either show all records for the account (including `property_id` null and any property) or only account-level (`property_id` is null)—choose one and document it.
3. When **creating** a record (Step 4), set `property_id` to `selectedPropertyId` or null when adding at account level.

**Check:** Switching property changes the list; new records are created for the selected property (or account-level).

---

## Step 8: Reporting period filter (optional)

**Goal:** Let users filter the records table by reporting period (e.g. year or date range).

1. Add a **period filter** (e.g. year dropdown or start/end date) on the sub-page.
2. When loading records, add filters, e.g.:
   - By year: `reporting_period_start.gte('2025-01-01')`, `reporting_period_start.lt('2026-01-01')`
   - Or by range: `reporting_period_end.gte(filterStart)`, `reporting_period_start.lte(filterEnd)`
3. Keep “no filter” as default (show all) so existing behaviour is unchanged.

**Check:** Changing the period filter narrows the list to matching records.

---

## Step 9: Governance and Targets (if still on localStorage)

If **Governance** and **Targets** are currently stored in localStorage with their own dialogs:

1. **Governance:** Map “Add Governance Item” to `data_library_records` with `subject_category: 'governance'`. Store category (oversight, accountability, policy, risk-management, engagement), title, description, status, responsible person in `value_text` (e.g. JSON) or in dedicated columns if you add them later.
2. **Targets:** Map “Add Target” to `data_library_records` with `subject_category: 'targets'`. Store category, scope, baseline/target values and years, unit, status in `value_numeric`, `value_text`, `unit`, and optionally JSON in `value_text` for the rest until you have a dedicated targets table.

Then load Governance/Targets lists from `data_library_records` filtered by `subject_category` and parse the stored fields for the table and forms.

**Check:** Adding a governance item or target creates a row in `data_library_records` and appears in the list.

---

## Summary checklist

| Step | What you did | Verify |
|------|----------------|--------|
| 1 | Run migrations (name, enums, optional evidence tag/description) | Columns exist in Supabase |
| 2 | Create bucket `secure-documents` + RLS policies | Upload/read from app works |
| 3 | Replace mock list with Supabase `data_library_records` (by account, optional property/category) | Table shows real data |
| 4 | Manual Entry (or Add record) form → insert `data_library_records` | New row in table and DB |
| 5 | Upload file → Storage path → insert `documents` → insert `evidence_attachments` | File linked to record |
| 6 | Drawer loads evidence from `evidence_attachments` + `documents`, optional download/delete | Evidence list and actions work |
| 7 | Filter list by selected property | List updates with property |
| 8 | Optional period filter on list | List filters by period |
| 9 | Governance/Targets backed by `data_library_records` | CRUD in Supabase |

When all steps are done, the Data Library is **dynamic in Lovable with storage in Supabase**: records and evidence are persisted in Supabase tables and Storage, and the UI reads/writes them via your existing routes and components.

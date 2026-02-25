# Data Library — What to do next (step-by-step)

Use this **in order** to get the Data Library dynamic in Lovable with Supabase. When Data Library is done, you move on to **Dashboards**, where **KPI coverage** (Complete / Partial / Unknown) is needed.

**Full technical steps:** [data-library-lovable-supabase-step-by-step.md](data-library-lovable-supabase-step-by-step.md)  
**Context and alignment:** [data-library-implementation-context.md](data-library-implementation-context.md)

---

## 1. Confirm AI agents folder is up to date

- [x] **docs/for-agent/README.md** — Phase 3 updated with Data Library taxonomy, subject categories, Energy/Waste component architecture, Emissions Engine mapping, KPI Coverage spec; agent note: subject_category, no emissions as records, optional coverage.
- [x] **docs/for-agent/AGENT-TASKS.md** — Data library tasks updated (subject_category, emissions-not-stored, optional coverage); Last sync updated with Data Library specs and next order (Data Library → Dashboards → Emissions Engine → Agent).

**You’re good:** the for-agent folder now reflects everything from the Data Library / Emissions / Coverage work.

---

## 2. Data Library — ordered steps (do these next)

Do these in sequence. Each step builds on the previous.

| Step | What to do | Done when |
|------|------------|-----------|
| **2.1** | **Run Supabase migrations** for Data Library. Run [add-data-library-record-name-and-enums.sql](database/migrations/add-data-library-record-name-and-enums.sql). Optionally run [add-evidence-attachment-tag-and-description.sql](database/migrations/add-evidence-attachment-tag-and-description.sql). | `data_library_records` has `name`; `source_type` allows `rule_chain`; `confidence` allows `cost_only`. Optional: `evidence_attachments` has `tag`, `description`. |
| **2.2** | **Create Storage bucket and RLS.** (1) In Supabase Dashboard → Storage, create a bucket named `secure-documents` (private). (2) In SQL Editor, run [add-storage-secure-documents-policies.sql](database/migrations/add-storage-secure-documents-policies.sql). Path format when uploading from the app: `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}` (or `account/{accountId}/account-level/...` if no property). | You can upload and list a test file from the app. |
| **2.3** | **Replace mock records list with Supabase (Lovable).** This is a **change in the Lovable app**, not SQL: stop using hardcoded mock rows and instead fetch from Supabase table `data_library_records` (filter by `account_id`; optionally `property_id`, `subject_category`). Map DB columns to table: Record Name ← `name`, Ingestion Method ← `source_type`, Confidence ← `confidence`, Last Updated ← `updated_at`, Actions (View). See **Lovable prompt** below if you want to paste instructions into Lovable. | Table shows real rows from Supabase. |
| **2.4** | **Wire “Manual Entry” (or Add record).** Form: name, subject category, source type, confidence, reporting period, property. On submit, insert into `data_library_records`. Use canonical `subject_category` (energy, water, waste, etc.). | New record appears in table and in DB. |
| **2.5** | **Implement evidence upload.** In the record drawer, Evidence panel: build storage path, upload file to `secure-documents`, insert `documents`, insert `evidence_attachments` (with optional tag, description). | Uploading a file attaches it to the record; rows appear in `documents` and `evidence_attachments`. |
| **2.6** | **Load evidence in the drawer.** For the selected record, query `evidence_attachments` + `documents`; show list. Optional: signed URL for download; delete attachment. | Drawer shows attached files; download/delete work if implemented. |
| **2.7** | **Property scoping (optional).** When the user changes the property selector, filter the records list by `property_id`. Set `property_id` when creating records. | List and create respect selected property. |
| **2.8** | **Reporting period filter (optional).** Add a period/year filter on sub-pages; filter records by `reporting_period_start` / `reporting_period_end`. | List filters by period. |
| **2.9** | **Governance & Targets (optional).** If still on localStorage, back them by `data_library_records` with `subject_category` governance / targets; store dialog fields in value_text (JSON) or dedicated columns. | Governance and Targets rows in Supabase. |
| **2.10** | **Energy & Waste pages (optional but recommended).** When making `/data-library/energy` and `/data-library/waste` dynamic, follow [Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md](sources/Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md): coverage summary grid, component sections (Tenant Electricity, Landlord Utilities, Heating, Water; Waste contractor and streams), upload auto-tagging. Do not mix waste UI inside Energy. | Energy and Waste pages match component architecture; coverage can later come from CoverageEngine. |

**Policies are in:** [database/migrations/add-storage-secure-documents-policies.sql](database/migrations/add-storage-secure-documents-policies.sql) — run that file in Supabase SQL Editor after creating the bucket. It includes **upload**, **read**, and **delete** (so evidence cleanup works when a user removes an attachment). You can tighten later by restricting paths to the current user’s account. Full detail: [data-library-lovable-supabase-step-by-step.md](data-library-lovable-supabase-step-by-step.md) § Step 2.

**Note:** Steps **2.3–2.7** are **Lovable app work** (code/UI changes). Each step has its **own** Lovable prompt below: **2.3** = list from Supabase, **2.4** = Manual Entry form, **2.5** = evidence upload, **2.6** = evidence in drawer, **2.7** = property scoping (filter list + set property on create). Scroll to **“Lovable prompt for step 2.7”** to enable switching property in Data Library.

---

### Lovable prompt for step 2.3 (replace mock list with Supabase)

Paste this into Lovable when you want it to implement step 2.3:

```
Data Library sub-pages (Water, Waste, Certificates, ESG, Indirect Activities) currently show hardcoded mock rows. Change them to load records from Supabase instead.

1. Create a hook or query that fetches from the table `data_library_records`:
   - Filter by `account_id` = current account ID (from app context).
   - Optionally filter by `property_id` when the user has selected a property (or show account-level when null).
   - On a category page (e.g. /data-library/waste), also filter by `subject_category` (e.g. "waste", "water", "certificates", "esg", "indirect_activities").
   - Order by `updated_at` descending.

2. Use the Supabase client: supabase.from('data_library_records').select('*').eq('account_id', currentAccountId) ... and pass the result to the existing table component.

3. Map the columns: Record Name → record.name (or fallback to subject_category + period if name is null), Ingestion Method → record.source_type (show as Upload/Manual/Connector/Rule Chain), Confidence Level → record.confidence, Last Updated → record.updated_at, Actions → keep the View button that opens the drawer for that record's id.

4. Remove the mock data array so the table only shows the Supabase response. Handle loading and empty state (no records yet).
```

---

### Lovable prompt for step 2.4 (Manual Entry — create record)

Paste this into Lovable to implement **step 2.4** (form that creates a Data Library record). Do this after 2.3 so the new record appears in the list.

```
Add a "Manual Entry" or "Add record" flow for Data Library that inserts into Supabase.

1. Add a form (dialog or inline) with: Name (optional), Subject category (dropdown or fixed per page: energy, water, waste, indirect_activities, certificates, esg, governance, targets), Source type (Upload | Manual | Connector | Rule Chain — use "manual" for this flow), Confidence (Measured | Allocated | Estimated | Cost Only), Reporting period (start date, end date), and optionally Property (current selected property or "Account-level" = null).

2. On submit, call supabase.from('data_library_records').insert({ account_id: currentAccountId, property_id: selectedPropertyId || null, subject_category, name: form.name || null, source_type: 'manual', confidence: form.confidence, reporting_period_start: form.periodStart, reporting_period_end: form.periodEnd }).select('id').single().

3. After successful insert, refetch the records list (or invalidate the query) so the new row appears. Optionally open the new record's drawer so the user can attach evidence next.
```

---

### Lovable prompt for step 2.5 (evidence upload — Storage + documents + evidence_attachments)

Paste this into Lovable to implement **step 2.5** (upload file in the record drawer and link to the record). Requires step 2.3 (drawer has a record id).

```
In the Data Library record drawer, implement the Evidence upload so files are stored in Supabase Storage and linked to the record.

1. In the Evidence & Attachments panel, when the user clicks Upload and selects a file:
   - Build the storage path: account/${accountId}/property/${propertyId}/${year}/${month}/${docId}-${file.name} (or account/${accountId}/account-level/${year}/${month}/... if no property). Use a new UUID for docId.
   - Upload: supabase.storage.from('secure-documents').upload(path, file, { upsert: false }).
   - Insert a row in `documents`: supabase.from('documents').insert({ account_id: accountId, storage_path: path, file_name: file.name, mime_type: file.type, file_size_bytes: file.size }). Get the returned id (or use the same docId you put in the path).
   - Insert a row in `evidence_attachments`: { data_library_record_id: recordId (the record in the drawer), document_id: docId }. Optionally add tag (invoice, contract, methodology, certificate, report, other) and description if the form has them.

2. Validate file type (e.g. PDF, images, Excel, CSV) and max size (e.g. 10MB) before upload.

3. After success, refetch the evidence list for this record so the new file appears in the panel.
```

---

### Lovable prompt for step 2.6 (load evidence in the drawer)

Paste this into Lovable to implement **step 2.6** (drawer shows attached files from Supabase). Do after 2.5 so there is something to show.

```
In the Data Library record drawer, load the evidence list from Supabase instead of localStorage or mock data.

1. When a record is selected (drawer open), query evidence for that record: supabase.from('evidence_attachments').select('id, tag, description, created_at, documents(id, file_name, storage_path, file_size_bytes, mime_type)').eq('data_library_record_id', recordId).

2. Display the list in the Evidence & Attachments panel: file name, tag (if present), date, size. Use the documents relation for file_name, file_size_bytes, etc.

3. Optional: Add a Download action that creates a signed URL: supabase.storage.from('secure-documents').createSignedUrl(row.documents.storage_path, 60) and open or download. Optional: Add Delete that removes the row from evidence_attachments (and optionally the file from Storage and the row from documents if you don't reuse documents elsewhere).
```

---

### Lovable prompt for step 2.7 (property scoping — switch property in Data Library)

Paste this into Lovable so the Data Library **list and create** respect the **header property selector**. Then you can switch between properties and see only that property’s records; new records get the selected property.

```
Data Library should respect the global property selector so users can switch between properties.

1. When loading data_library_records (step 2.3), filter by the currently selected property when the user has chosen one: .eq('property_id', selectedPropertyId). When "All" or no property is selected, either show all records for the account (property_id any) or only account-level records (.is('property_id', null)) — choose one and keep it consistent.

2. When creating a new record (Manual Entry / step 2.4), set property_id to the currently selected property ID, or null when the user chose "Account-level" or no property.

3. Ensure the Data Library page (or the component that fetches records) receives the selected property from the same context/state as the header property selector, and refetches records when the selection changes.
```

---

## Lovable changes to Supabase (when it implemented 2.5–2.6)

When Lovable wired evidence upload, it may have applied migrations or policies in your Supabase project. For the backend repo to stay in sync:

- **Storage DELETE policy** — Evidence “delete” in the UI removes the `evidence_attachments` row and (if implemented) the file from Storage. That requires a **DELETE** policy on `storage.objects` for the `secure-documents` bucket. Our migration [add-storage-secure-documents-policies.sql](database/migrations/add-storage-secure-documents-policies.sql) now includes that policy (`"Users can delete from secure-documents"`). If Lovable already added it, no need to run again; if you clone the repo on a new project, run the migration to get upload + read + delete.
- **Evidence flow** — Files go to `secure-documents` at `account/{id}/property/{id}/{year}/{month}/{docId}-{filename}`; `documents` row stores metadata; `evidence_attachments` links document to record (optional tag & description); validation e.g. max 10 MB, PDF/images/Excel/CSV; download via 60s signed URL; delete removes attachment row (and optionally Storage object). The app may use a hook like `useRecordEvidence` and no longer use the old localStorage-based `useDataLibraryEvidence` for these pages.

If Lovable added any **other** tables or policies (e.g. extra RLS), note them here or in the implementation plan so the repo stays the single source of truth.

---

## How to test steps 2.3–2.6

Use this checklist to confirm everything is correct.

**In the app**

1. **List (2.3)** — Open a Data Library category (e.g. Waste, Water). The table should show rows. If you have no rows yet, the table is empty (not mock rows with fake names).
2. **Create (2.4)** — Use Manual Entry / Add record. Fill name, category, confidence, period; submit. The new row appears in the table.
3. **Evidence (2.5 + 2.6)** — Click **View** on that row to open the drawer. In Evidence & Attachments, click **Upload**, choose a file (e.g. PDF), optionally tag; upload. The file appears in the list in the drawer. Optional: use Download if implemented.

**In Supabase (source of truth)**

1. **Table Editor → `data_library_records`** — You should see the row you created (same name, subject_category, account_id, property_id). Everything here is **real** data (created by the app). There is no “mock” data in Supabase; mock data lived only in the frontend before 2.3.
2. **Table Editor → `documents`** — You should see one row per uploaded file (storage_path, file_name, account_id).
3. **Table Editor → `evidence_attachments`** — You should see one row linking that document to the data_library_record (data_library_record_id, document_id).
4. **Storage → `secure-documents`** — You should see the file in the path `account/.../property/.../yyyy/mm/...`.

If all of the above match, 2.3–2.6 are working correctly.

---

## Property switching and mock vs real data

**Why you can’t switch property yet**  
Step **2.7 (property scoping)** is not done. The list and create flow don’t yet use the header property selector, so everything appears under one context (e.g. 140 Apex). Use the **Lovable prompt for 2.7** above so that: (1) the records list filters by selected property, and (2) new records get the selected `property_id`.

**How to tell mock from real**

- **Real data** = rows that exist in **Supabase** (`data_library_records`, `documents`, `evidence_attachments`) and were created by your app (Manual Entry, upload). You can see them in Table Editor and they have your `account_id` and real UUIDs.
- **Mock data** = data that **never** went through Supabase. It was hardcoded in the frontend (e.g. fake names, fake rows). After 2.3, the table is driven by Supabase, so any row in the table that has a matching row in `data_library_records` is real. If you still see rows that don’t exist in `data_library_records`, those would be leftover mock — remove that source so the table only uses the Supabase query.

**If you remove “140 Apex” later**  
- All **real** data is in Supabase. You can export or note which rows have `property_id` = 140 Apex’s ID before deleting the property.  
- To keep things clear: add a **second property** (e.g. “Real portfolio building”), implement **2.7**, then switch to that property and create records there. That way you can tell “140 Apex” = original/mockup property, “Real portfolio building” = new real data. You can later delete the 140 Apex property (and optionally reassign or delete its records) when you’re ready.

---

## Deleting a property (e.g. 140 Apex) and the agent

**Is it recommended to delete 140?** It’s up to you. If 140 was only for mockup and you want a clean slate, you can delete it. The agent does **not** depend on any specific property — it works on **whatever property context you send** (propertyId, spaces, systems, dataLibraryRecords). So **deleting 140 does not break the agent**; you’ll just run the agent on other properties.

**What happens when you delete a property** (from [schema](database/schema.md) / [supabase-schema.sql](database/supabase-schema.sql)): Rows in **spaces**, **systems**, **meters**, **end_use_nodes** that reference that property are **deleted** (ON DELETE CASCADE). Rows in **data_library_records** and **agent_runs** are **not** deleted — their `property_id` is set to **NULL** (ON DELETE SET NULL), so those records become account-level.

**If you do delete 140:** (1) Create a new property first if you want somewhere to run the agent. (2) Optionally reassign Data Library records: `UPDATE data_library_records SET property_id = '<new_property_uuid>' WHERE property_id = '<140_property_uuid>'`. (3) Delete the 140 property from the app or Supabase. Any records you didn’t reassign will stay in Supabase with `property_id` = null (account-level).

---

## 3. After Data Library — move to Dashboards (KPI coverage)

When the steps above are done (at least 2.1–2.6 so records and evidence are dynamic), the **next focus is Dashboards**, where **KPI coverage** is needed.

- **CoverageEngine** (see [Secure_KPI_Coverage_Logic_Spec_v1.md](sources/Secure_KPI_Coverage_Logic_Spec_v1.md)) computes **Complete / Partial / Unknown** per KPI from component state and KPI requirements.
- **Dashboard behaviour:** Show a **completeness badge** next to each KPI and a **tooltip** (e.g. “Includes tenant electricity only; landlord utilities not disclosed”) from the coverage assessment.
- **Persistence:** When you implement the engine, cache output in `coverage_assessments` (schema draft in the Coverage spec §13); dashboards read from that.

So the order is:

1. **Now:** Data Library (steps 2.1–2.10 above).  
2. **Next:** Dashboards + KPI coverage (CoverageEngine, badges, tooltips).  
3. **Later:** Emissions Engine backend (when you need real calculated emissions instead of mock); then agent Phase 5 if needed.

---

## 4. Quick reference — key docs

| Topic | Doc |
|-------|-----|
| Data Library taxonomy (four layers, access IDs) | [Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md](sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md) |
| Energy & Waste component UI | [Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md](sources/Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md) |
| Emissions (Calculated) page — read-only | [Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md](sources/Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md) |
| Emissions Engine logic (Activity → Scope) | [Secure_Emissions_Engine_Mapping_v1.md](sources/Secure_Emissions_Engine_Mapping_v1.md) |
| Emissions Engine DB (runs, factors, line items) | [Secure_Emissions_Engine_Schema_Draft_v1.md](sources/Secure_Emissions_Engine_Schema_Draft_v1.md) |
| KPI coverage (Complete / Partial / Unknown) | [Secure_KPI_Coverage_Logic_Spec_v1.md](sources/Secure_KPI_Coverage_Logic_Spec_v1.md) |
| Data Library routes & responsibilities | [data-library-routes-and-responsibilities.md](data-library-routes-and-responsibilities.md) |
| Full technical step-by-step (Lovable + Supabase) | [data-library-lovable-supabase-step-by-step.md](data-library-lovable-supabase-step-by-step.md) |

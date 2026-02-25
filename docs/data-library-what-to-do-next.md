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

### Lovable prompt: Data Library cleanup + dynamic property dropdown (use if mock/localStorage remain)

Use this when **mock data or localStorage are still present** and there is **no dynamic property selector** under My Data. Paste into Lovable so it removes all mock/localStorage and adds a property dropdown that loads from Supabase.

```
Data Library must use only Supabase — no mock data and no localStorage for records or evidence. Also add a dynamic property selector under My Data.

PART 1 — Remove mock and localStorage

1. Records list: Remove every hardcoded mock array or static data used for Data Library tables (Water, Waste, Certificates, ESG, Indirect Activities, etc.). The only source for table rows must be supabase.from('data_library_records').select('*').eq('account_id', currentAccountId) with optional .eq('property_id', selectedPropertyId) and .eq('subject_category', category). Handle loading and empty state; do not show mock rows.

2. Evidence (drawer): Remove any use of localStorage or useDataLibraryEvidence (or similar) for the Evidence & Attachments panel. The only source for evidence must be supabase.from('evidence_attachments').select('..., documents(...)').eq('data_library_record_id', recordId). Upload must go to Supabase Storage (bucket secure-documents) and insert into documents + evidence_attachments. Delete must remove evidence_attachments row (and optionally the Storage object). No fallback to mock files or local storage.

3. Search the codebase for "mock", "localStorage", "useDataLibraryEvidence", and any Data Library–specific hardcoded arrays; remove or replace with Supabase queries so Data Library is 100% Supabase-backed.

PART 2 — Dynamic property dropdown under My Data

4. Add a property selector dropdown in the Data Library section, under the "My Data" tab (or in the Data Library header so it is visible on all Data Library sub-pages). The dropdown must:
   - Load the list of properties from Supabase: supabase.from('properties').select('id, name').eq('account_id', currentAccountId).order('name').
   - Show options: e.g. "All properties" or "Account-level" (value null), plus one option per property (value = property id, label = property name).
   - When the user selects a property (or "All"), store the selected value in state (e.g. dataLibrarySelectedPropertyId) and refetch data_library_records filtered by that property_id (or show all records for the account if "All").
   - When creating a new record (Manual Entry), set property_id to the currently selected property from this dropdown (or null if "All" / "Account-level" is selected).

5. Ensure the records list and the create-record form both use this same selected property so that switching the dropdown updates the list and new records are assigned to the selected property.
```

---

### Lovable prompt: Remove mock data from every Data Library nested page

Use this when **nested pages** (Water, Waste, Certificates, ESG, etc.) still show mock data. Paste into Lovable so **every** Data Library sub-page loads from Supabase with the correct `subject_category` and no hardcoded rows.

```
Every Data Library nested (category) page must load its table from Supabase only — no mock or hardcoded rows on any of these routes.

Apply this to every page that lists Data Library records:

1. For each route below, the records table must query:
   supabase.from('data_library_records').select('*').eq('account_id', currentAccountId).eq('subject_category', <category_for_route>)
   plus .eq('property_id', selectedPropertyId) when a property is selected (or omit filter for "All"). Order by updated_at descending.

2. Route → subject_category mapping (use exactly these values in the query):
   - /data-library/water        → subject_category: "water"
   - /data-library/waste        → subject_category: "waste"
   - /data-library/certificates → subject_category: "certificates"
   - /data-library/esg          → subject_category: "esg"
   - /data-library/indirect-activities → subject_category: "indirect_activities"
   - /data-library/governance   → subject_category: "governance"
   - /data-library/targets      → subject_category: "targets"
   - /data-library/occupant-feedback → subject_category: "occupant_feedback"
   - /data-library/energy       → subject_category: "energy" (if the energy page has a records table; otherwise keep component-based UI but any record list must come from Supabase with subject_category "energy")

3. Remove from each of these pages/components: any hardcoded array of records, any mock rows, any static placeholder data. Replace with the Supabase query above. Show loading state while fetching; show empty state when the query returns zero rows. Do not show mock data as fallback.

4. If a shared component (e.g. DataLibrarySubPage) is used by multiple routes, pass the subject_category as a prop or derive it from the route (e.g. from pathname or route params) so each nested page filters by the correct category. Ensure every instance of that component uses Supabase with the right category — no mock data in the shared component either.

5. Verify: WaterDataPage, WasteDataPage, CertificatesDataPage, ESGDataPage, IndirectActivitiesPage, GovernanceDataPage, TargetsDataPage, OccupantFeedbackList, and any other Data Library category page must all use the same pattern: fetch from data_library_records with account_id + subject_category (+ property_id when selected). No mock data on any nested page.
```

---

### Lovable prompt: Wire property dropdown to Data Library data (filter list by selected property)

Use this when the **property dropdown exists but switching properties does not change the data** — the same records appear for every property. Paste into Lovable so the selected property actually filters the records on every Data Library page.

```
The Data Library property dropdown must drive the data: when the user selects a different property, the records list on every Data Library page (Water, Waste, Certificates, ESG, Governance, Targets, etc.) must update to show only records for that property.

1. Single source of truth for "selected property in Data Library": Use one state or context value (e.g. dataLibraryPropertyId or selectedPropertyId) that is set when the user changes the property dropdown in the Data Library section. Every Data Library category page (and the hub if it shows counts) must read this value.

2. Every query for data_library_records must depend on this selected property:
   - When a property is selected (dropdown value is a property id): add .eq('property_id', selectedPropertyId) to the Supabase query so only records for that property are returned.
   - When "All" or "Account-level" is selected (dropdown value is null): either .is('property_id', null) to show only account-level records, or omit the property filter to show all records for the account. Be consistent across all pages.

3. Refetch when selection changes: The queries (or hooks) that load data_library_records must have the selected property id in their dependency array (e.g. useEffect or React Query key). When the user changes the dropdown, the selected property state updates and the query runs again with the new property_id filter, so the table shows different data for each property.

4. Apply everywhere: Every nested page that shows a list of Data Library records (Water, Waste, Certificates, ESG, Indirect Activities, Governance, Targets, Energy if it has a record list, etc.) must use the same selected property in its query. No page should ignore the dropdown and show all account records regardless of selection.

5. Manual Entry / Add record: When creating a new record, set property_id to the currently selected property from this dropdown (or null if "All" / "Account-level"). So new records belong to the property the user has selected.
```

---

### Lovable prompt: Restore Add/Upload buttons and Energy page sections

Use this when **Add Data / Upload buttons were removed** from Data Library pages or when the **Energy page lost its component sections** (Tenant Electricity, Landlord Utilities, Scope 1, Heating, Water). Paste into Lovable to restore them while keeping data from Supabase.

**Live reference (for you when testing):** [Energy page](https://www.securetigre.co.uk/data-library/energy) — check the structure (sections, Add Data dropdown, upload buttons) after each Lovable change. Do not share credentials in the repo; keep them in a secure place.

```
Data Library must keep the ability to add records and upload files. Restore the following — without re-adding mock data; keep loading records from Supabase.

PART 1 — Add/Upload buttons on every category page

1. On every Data Library category page (Water, Waste, Certificates, ESG, Indirect Activities, Governance, Targets, etc.), ensure there is an "Add Data" dropdown or equivalent with options such as: Upload Documents, Manual Entry, (and optionally Connect Platform, Rule Chain). Users must be able to add records and upload files from each section. Do not remove these actions when wiring Supabase.

2. In the record drawer (when user clicks View on a row), the Evidence & Attachments panel must have an "Upload" (or "Add file") button so users can attach files to that record. Upload should use Supabase Storage + documents + evidence_attachments. Restore this button if it was removed.

3. Each tile/section should have a clear way to add or upload (e.g. "Add record", "Upload invoice", "Manual Entry") so the Data Library remains upload-friendly. Data comes from Supabase; actions to create and upload must remain visible.

PART 2 — Restore Energy page component sections

4. The Energy & Utilities page (/data-library/energy) must not be a single flat table. Restore the multi-section layout:

   - **Page header:** Title "Energy & Utilities", subtitle (e.g. tenant electricity, landlord recharges, heating and water coverage). **Add Data dropdown** with: Upload Tenant Electricity Invoice, Upload Service Charge / Landlord Recharge, Upload Heating Submeter, Upload Water Submeter, Manual Entry.

   - **Component Coverage Summary** (top grid): Rows for Component | Control | Status | Coverage | Latest | Action. Components in this order: (1) Tenant Electricity, (2) Landlord Utilities, (3) Heating, (4) Water. Each row can have an action (e.g. View / Upload). Data for this grid can come from Supabase (e.g. data_library_records with subject_category "energy", aggregated or grouped by component type if you have it) or from a coverage API; if only flat records exist, derive or show placeholders until CoverageEngine exists.

   - **Expandable Component Detail Sections** (below the summary), one section per component:
     - **Tenant Electricity (Direct — Submetered):** Table with Period, kWh, Cost, Confidence, Evidence, Actions. Upload / Add button in this section.
     - **Landlord Utilities (Service Charge / Recharge):** Table with Period, Cost, Breakdown Level, Allocation Method, Evidence. Upload / Add button.
     - **Heating:** Table or message (e.g. "Heating included in landlord recharge" if no separate meter). Upload / Add if applicable.
     - **Water:** Table with Period, m³, Cost, Source, Confidence, Evidence. Upload / Add button.
     - **Scope 1 / Direct Emissions** (if you had it): Subsection or tab for stationary combustion, mobile combustion, refrigerants, process emissions — with table and Upload/Add. Restore this section if it was present.

5. Each Energy section should allow uploads or manual entry and show records from Supabase (subject_category "energy"; you can use data_type or a custom field to distinguish Tenant Electricity vs Landlord vs Heating vs Water if needed). Do not replace the section layout with a single undifferentiated table. Keep the component-based structure so users see Tenant Electricity, Landlord Utilities, Heating, Water (and Scope 1) as separate areas with their own tables and add/upload actions.
```

---

### Lovable prompt: Restore full operational structure (Scope 1 calculators, upload on all pages)

Use this when **other Data Library operational pages** (Water, Waste, Certificates, ESG, Indirect Activities) **lost their upload buttons**, or when the **previous UI structure** (component sections, Scope 1 subsection with calculators and upload) **disappeared** and was replaced by a single flat table or minimal layout.

**Important — do not overwrite the working Energy upload:** If "Upload energy record" / "Upload Tenant Electricity Invoice" already opens a **file upload** (file picker → Storage → documents → records → evidence), leave that behaviour unchanged. This prompt only restores missing structure and buttons; it must **not** route Energy Upload to Manual Entry or replace the file upload flow.

```
Data Library operational pages must restore the previous structure and actions. Do not leave any operational category as a single undifferentiated table without upload/add.

**Compatibility:** On the Energy page, if "Upload" already opens a file picker and creates records from uploaded files, keep that behaviour. Do not change Upload to open Manual Entry. Only add or restore missing sections (e.g. Scope 1, other operational pages) and their Upload/Add buttons; the Energy Upload action must remain file upload, not form entry.

PART 1 — Upload and Add Data on every operational page

1. On EVERY Data Library category page that holds operational data, ensure there is an "Add Data" dropdown (or equivalent) with at least: **Upload Documents**, **Manual Entry**. Pages to fix: Water (/data-library/water), Waste (/data-library/waste), Certificates (/data-library/certificates), ESG (/data-library/esg), Indirect Activities (/data-library/indirect-activities), and Energy (/data-library/energy). Each must have a visible way to upload files and to add records manually. Wire these to Supabase (data_library_records + documents + evidence_attachments) where applicable; do not remove the buttons when wiring.

2. Each category page should keep (or restore) its previous layout: summary blocks, component/tile sections, tables per component where that was the design. Do not collapse everything into one flat table. Examples:
   - **Waste:** Summary block (Component | Contracted By | Status | Coverage | Latest), Contractor block (name, contract type, upload: Invoice / Weight report / Diversion certificate), Waste streams breakdown (streams + period table with kg, method, evidence). Upload and Add actions in each relevant block.
   - **Water:** Component-based or table with Period, m³, Cost, Source, Confidence, Evidence; Upload / Add in the section.
   - **Certificates, ESG, Indirect Activities:** Table plus Add Data (Upload Documents, Manual Entry) so users can add and attach evidence.

PART 2 — Energy page: restore Scope 1 section with calculators and upload

3. The Energy page (/data-library/energy) must include a dedicated **Scope 1 / Direct Emissions** section (not only Tenant Electricity, Landlord, Heating, Water). Restore it as an expandable subsection or tab with:
   - **Sub-sections** (or sub-tabs): Stationary combustion (gas, oil, LPG, diesel), Mobile combustion (fleet), Refrigerants (fugitive emissions), Process emissions (if applicable). Each sub-section has: a table of records (period, quantity, unit, source, evidence, actions) and **Upload** + **Add** / Manual entry.

4. **Scope 1 calculators:** Where the previous UI had calculator-style inputs (e.g. enter fuel type + quantity in kWh, or refrigerant type + kg to derive or store activity data / estimated tCO₂e), restore those. For example:
   - Stationary combustion: form or inline calculator for fuel type (gas, oil, LPG, etc.), quantity (kWh or volume), period; optional display of estimated emissions (quantity × factor) if you have factors.
   - Refrigerants: form or calculator for refrigerant type (e.g. R410A, R134a), quantity (kg), GWP if needed; store as activity record and optionally show estimated tCO₂e.
   - Mobile / Process: similar data-entry or calculator UIs if they existed.
   So Scope 1 has both (a) **upload** of invoices/records and (b) **manual/data entry or calculators** for direct input of quantities. Restore both; do not remove the calculators in favour of upload-only.

5. After restoration, Energy page structure should be: Page header + Add Data dropdown → Component Coverage Summary (Tenant Electricity, Landlord Utilities, Heating, Water, Scope 1) → Expandable detail sections for each, with **Scope 1** containing sub-areas (stationary, mobile, refrigerants, process), each with table + Upload + Add/Calculator as above. Data from Supabase (subject_category "energy"; use a field or data_type to distinguish Scope 1 sub-types if needed). No single flat table replacing this component layout.
```

---

### Lovable prompt: Upload energy record = file upload (not Manual Entry)

Use this when **"Upload energy record"** or **"Upload Tenant Electricity Invoice"** (or similar) opens **Manual Entry** instead of a **file upload**. The user must be able to select one or more PDFs (e.g. 5 energy bills) and have them uploaded and stored as records with attached evidence.

```
"Upload energy record" and the other Energy upload options (Upload Tenant Electricity Invoice, Upload Service Charge / Landlord Recharge, Upload Heating Submeter, Upload Water Submeter) must open a FILE UPLOAD flow, not the Manual Entry form.

1. When the user clicks "Upload energy record" or "Upload Tenant Electricity Invoice" (or "Upload Documents" in the Energy section), open a file picker dialog that:
   - Accepts PDF files (and optionally images, Excel, CSV per your validation rules).
   - Allows MULTIPLE file selection so the user can add several bills at once (e.g. 5 PDFs).
   - Validates file type and size (e.g. max 10 MB per file) before uploading.

2. For each selected file, in order:
   - Upload the file to Supabase Storage (bucket secure-documents), path: account/{accountId}/property/{propertyId}/{year}/{month}/{docId}-{fileName}.
   - Insert a row into `documents` (account_id, storage_path, file_name, mime_type, file_size_bytes).
   - Insert a row into `data_library_records` with: account_id, property_id (current selected property or null), subject_category "energy", source_type "upload", name (e.g. the file name without extension, or "Energy bill - [filename]"), and optionally reporting_period_start/end if you can derive or leave null.
   - Insert a row into `evidence_attachments` linking that record to that document (data_library_record_id, document_id), with optional tag "invoice".

3. So if the user selects 5 PDFs, create 5 records (each with one attached bill). After upload, refetch the records list so the new rows appear in the Energy table. Show a success message (e.g. "5 files uploaded").

4. Keep "Manual Entry" as a SEPARATE action: it opens the form for entering record details by hand (no file). Do not route "Upload" or "Upload energy record" to Manual Entry. Upload = file picker → upload files → create records + documents + evidence. Manual Entry = form → insert record only.
```

---

## Extracting data from energy PDFs

**Current behaviour:** Upload stores the PDF in Storage, creates a `documents` row, creates a `data_library_record` (with `name` e.g. from filename, `subject_category` "energy", `source_type` "upload"), and links them via `evidence_attachments`. **No automatic extraction** runs yet — we did **not** create a sample PDF to upload; we only documented the *shape* of data from the bill you shared (in [data-library-energy-bill-sample-payload.md](data-library-energy-bill-sample-payload.md)). So no upload (including the sample bill) will auto-fill period, kWh, or cost; the record stays mostly null until you **edit the record** in the app (see "Edit Energy record" prompt below) or until extraction is built later.

**Ways to get data from PDFs:**

1. **Manual entry (today)** — After uploading, open the record in the drawer and use Edit / Manual Entry to fill reporting period, quantity (kWh), unit, cost, confidence. The record already has `value_numeric`, `unit`, `reporting_period_start`, `reporting_period_end` in the schema.
2. **Sample payload for one property (recommended next step)** — Define the target shape for “one energy bill as data” so that when you add extraction (or a human creates a sample), the app and backend know what to store. You can create a sample as JSON or as one row in Supabase and we document it; see below.
3. **Future: PDF extraction** — Options include: (a) OCR + parsing (e.g. extract text, then regex or rules for period, kWh, £), (b) an external document-intelligence API, or (c) an AI/agent step that reads the PDF and returns structured fields. The backend can expose an endpoint or Edge Function that accepts a document ID, runs extraction, and updates the corresponding `data_library_record` with the extracted fields.

**Target schema for one energy bill (for sample or extraction):**

The `data_library_records` table already supports the needed fields. For one electricity/gas bill, the target shape is:

| Field | Example | Notes |
|-------|--------|--------|
| name | "Electricity Jan 2026" or from filename | Display name |
| subject_category | "energy" | |
| source_type | "upload" (or "manual" if entered by hand) | |
| reporting_period_start | 2026-01-01 | Bill period start |
| reporting_period_end | 2026-01-31 | Bill period end |
| value_numeric | 1250.5 | Consumption (kWh) or cost |
| unit | "kWh" or "GBP" | |
| data_type | "tenant_electricity" / "gas" / "landlord_recharge" etc. | Optional; distinguishes component |
| confidence | "measured" / "allocated" / "estimated" / "cost_only" | |
| value_text | Meter number, MPAN, supplier name | Optional; free text |

**Sample bill documented:** The sample electricity invoice (UrbanGrid Energy Ltd, January 2026, Lumen Technology HQ) is documented in [data-library-energy-bill-sample-payload.md](data-library-energy-bill-sample-payload.md). That doc maps every bill field to the database (e.g. Total Consumption → `value_numeric` + `unit` kWh, period → `reporting_period_start`/`end`, supplier/invoice → `value_text`), gives a canonical JSON payload for one record, extraction hints for OCR/parser/AI, and a manual-entry checklist. Use it for manual entry after upload or as the target for future PDF extraction.

---

### Lovable prompt: Edit Energy record — form to fill and save bill data to Supabase

Use this when **uploaded energy records in Supabase have null for period, consumption, cost, etc.** (only name is set). The user must be able to open a record, edit those fields, and save so the `data_library_records` row is updated in Supabase.

```
When a user opens an Energy (or other Data Library) record in the drawer (View), they must be able to EDIT the record and save the following fields to Supabase so the record is no longer mostly null.

1. Add an "Edit" mode or "Edit record" action in the record drawer (the same drawer that shows Evidence & Attachments). When the user clicks Edit, show a form with these fields, pre-filled from the current record:

   - **Record name** (name) — text
   - **Reporting period start** (reporting_period_start) — date picker
   - **Reporting period end** (reporting_period_end) — date picker
   - **Consumption / quantity** (value_numeric) — number
   - **Unit** (unit) — dropdown or text, e.g. kWh, GBP, m³
   - **Confidence** (confidence) — dropdown: measured, allocated, estimated, cost_only
   - **Notes / supplier / cost** (value_text) — textarea, for supplier name, invoice ref, net cost, total due (e.g. "Supplier: UrbanGrid; Invoice: UGE-0126-LTHQ; Net £7,918.74; Total £9,684.89")
   - Optional: **Data type** (data_type) — e.g. tenant_electricity, gas, landlord_recharge

2. On Save, call Supabase to update the record:
   supabase.from('data_library_records').update({
     name,
     reporting_period_start,
     reporting_period_end,
     value_numeric,
     unit,
     confidence,
     value_text,
     data_type,
     updated_at: new Date().toISOString()
   }).eq('id', recordId)

3. After a successful update, refetch the record (or invalidate the query) so the drawer and any table show the new values. The row in Supabase should now have these columns populated instead of null.

4. Apply this pattern for Energy records at minimum; ideally the same Edit form (with the same Supabase columns) is available for other subject_category values (e.g. waste, water) so any uploaded record can be completed with period, quantity, and notes.
```

**What you do:** Paste this prompt into Lovable. After it’s implemented, open an uploaded energy record → Edit → fill Reporting period (e.g. 2026-01-01 to 2026-01-31), Consumption (e.g. 30340), Unit (kWh), Confidence (Measured), and Notes (supplier/cost) → Save. The record in Supabase will then have those fields populated instead of null.

---

### Lovable prompt: Delete Data Library record (from UI and DB)

Use this when you need to **remove records** the user has added (e.g. test uploads) from both the UI and Supabase. The user must be able to delete a record and have it removed from the list and from the database (including attachments and optionally the stored file).

```
Data Library records must be deletable from the UI. When the user deletes a record, remove it from Supabase and from the UI so it no longer appears.

1. Add a "Delete record" (or "Remove record") action:
   - In the record drawer (when viewing a record): a Delete button, e.g. in the header or footer.
   - And/or in the table: a row action (e.g. kebab menu or icon) "Delete" per row.

2. On Delete, show a confirmation dialog: e.g. "Delete this record? This will remove the record and its evidence links. The uploaded file(s) can optionally be removed from storage." User confirms or cancels.

3. When the user confirms, perform in order:
   (a) Get all evidence_attachments for this record: supabase.from('evidence_attachments').select('document_id').eq('data_library_record_id', recordId).
   (b) For each linked document_id, optionally delete the file from Storage (bucket secure-documents, path from documents.storage_path) and then delete the row from documents. If you prefer to keep files and only unlink, you can skip Storage + documents delete and only delete evidence_attachments.
   (c) Delete all evidence_attachments for this record: supabase.from('evidence_attachments').delete().eq('data_library_record_id', recordId).
   (d) Delete the record: supabase.from('data_library_records').delete().eq('id', recordId).

4. After successful delete, close the drawer if open, refetch the records list (or invalidate the query), and show a success message (e.g. "Record deleted"). The record disappears from the table and from Supabase.

5. Apply to all Data Library category pages (Energy, Water, Waste, Certificates, ESG, etc.) so any record can be deleted the same way.
```

**What you do:** Paste this prompt into Lovable. After it is implemented, open each of the 3 uploaded records (or use the row action) → Delete → confirm. The records will be removed from the UI and from Supabase. If the app also deletes the linked documents and Storage files, those PDFs will be removed too; otherwise only the record and evidence links are removed (the files stay in Storage until you clean them up manually in Supabase Dashboard if needed).

**To delete existing records only in Supabase (without UI):** In Supabase Table Editor, for each record id: (1) delete rows in `evidence_attachments` where `data_library_record_id` = that id; (2) delete the row in `data_library_records` with that id. Optionally delete the corresponding `documents` rows and the files in Storage → secure-documents.

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
4. **Upload energy record (file upload)** — On the Energy page, click **Upload energy record** or **Upload Tenant Electricity Invoice**. A file picker should open (not the Manual Entry form). Select 5 energy bill PDFs; upload. You should see 5 new rows in the Energy table and in Supabase (`data_library_records` + `documents` + `evidence_attachments`). Manual Entry remains a separate action.
5. **Other operational pages + Scope 1** — Open Water, Waste, Certificates, ESG, Indirect Activities: each should have an Add Data dropdown with Upload and Manual Entry, and their previous structure (e.g. Waste: summary + contractor + streams; not a single bare table). On Energy, the Scope 1 / Direct Emissions section should be present with sub-areas (stationary, mobile, refrigerants, process), each with table + Upload + Add, and calculator-style inputs (e.g. fuel/refrigerant quantity entry) where restored.

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

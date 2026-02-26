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
| **2.1** | **Run Supabase migrations** for Data Library. Run [add-data-library-record-name-and-enums.sql](database/migrations/add-data-library-record-name-and-enums.sql). Optionally run [add-evidence-attachment-tag-and-description.sql](database/migrations/add-evidence-attachment-tag-and-description.sql). If **Manual Entry** fails with **data_library_records_confidence_check**, run [fix-data-library-records-confidence-import.sql](database/migrations/fix-data-library-records-confidence-import.sql) so the DB accepts "Measured", "Cost Only", etc. (trigger normalizes to measured\|allocated\|estimated\|cost_only). | `data_library_records` has `name`; `source_type` allows `rule_chain`; `confidence` allows `cost_only`. Optional: `evidence_attachments` has `tag`, `description`. |
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

### Lovable prompt: Waste — Manual Entry, Delete, CSV extraction, and streams tile

Use this when the **Waste** page: has no Manual Entry button; has no way to delete uploaded records; does not extract CSV data into the UI; does not show a segregation streams breakdown on the same page; or has inconsistent Add Data buttons (e.g. two upload options). This prompt covers all of that and how property_id ("all" vs one property) works.

**Where "all properties" / account-level is in the DB:** When the user has "All" or "Account-level" selected in the Data Library property dropdown, new records should get `property_id` = **null**. Those rows are account-level and appear when "All" is selected; they do not belong to a single property. When a specific property is selected, use that property's UUID so the record is scoped to that property. To fix records that were created as "all": either leave them as account-level (property_id null) or add an Edit on the record and set property_id to the correct property UUID.

---

```
On the Data Library Waste page (/data-library/waste) implement the following.

Button consistency: Use exactly three Add Data options — Upload, Manual Entry, Connect. Remove any duplicate such as "Upload CSV" as a second button; the single "Upload" action should accept both documents and CSV files.

Wrong CSV parsing: Do NOT create one record per stream. One invoice (one CSV row) = one record with total kg, total cost, and the streams JSON stored in value_text; the Segregation/Streams tile only displays that JSON from the record — it must not be fed by separate per-stream records.

1. **Add Data: consistent with Data Library (Upload, Manual Entry, Connect)**
   - The "Add Data" dropdown must match the rest of Data Library with exactly three options: **Upload** (or "Upload Documents"), **Manual Entry**, **Connect** (placeholder/stub is fine). Do NOT show both "Upload" and "Upload CSV" as separate buttons — that duplicates upload. Have a single **Upload** action that opens a file picker and accepts documents and CSV; when the user selects a CSV, use the CSV parsing and Streams_breakdown logic below; when they select PDFs/images, upload to Storage and create records with evidence as for other categories.
   - **property_id:** Use the currently selected property from the Data Library property selector. If the user has selected a specific property (e.g. 140 Aldersgate), set property_id to that property's UUID. If "All" or "Account-level" is selected, set property_id to **null** (account-level record). Never use a number like 1; always use the real UUID or null.

2. **Manual Entry**
   - When the user clicks "Manual Entry", open a form with: Name, Reporting period start, Reporting period end, Contractor/Notes (value_text), Total kg (value_numeric), Unit (kg), Confidence (Measured/Allocated/Estimated/Cost only — normalize to lowercase before insert).
   - On submit: supabase.from('data_library_records').insert({ account_id: currentAccountId, property_id: selectedPropertyId || null, subject_category: 'waste', source_type: 'manual', name, reporting_period_start, reporting_period_end, value_numeric, unit: 'kg', confidence: normalizedConfidence, value_text }). Refetch the list.

3. **Delete record**
   - Add a "Delete" action on every waste record: in the record drawer (when viewing a record) add a Delete button; and in the table add a row action (e.g. kebab menu or icon) "Delete" per row.
   - On Delete: show confirmation ("Delete this record? This will remove the record and its evidence links."). On confirm: (a) delete evidence_attachments for this record, (b) optionally delete linked documents and Storage files, (c) delete the data_library_records row. Refetch the list and close the drawer. **After delete, the Segregation Streams tile must update:** it reads from the same waste records list — refetch that list and re-render the tile; if no records remain, the tile must show an empty state (e.g. "No waste records" or "Upload data to see stream breakdown"), not the previous streams. Apply the same Delete behaviour on Waste as on other Data Library pages (Energy, Water, etc.).

4. **CSV upload: one invoice row → one record (do not create one record per stream)**
   - **Critical:** Number of records to create = **number of CSV data rows only** (exclude the header row). One data row = one record. Do NOT create one record per item in the Streams_breakdown column — that column is a single JSON array string; store it whole in value_text for that row's record. Example: invoice CSV with 1 header + 1 data row → insert 1 record. The main table shows one row per invoice; the Streams breakdown tile reads the streams from that single record's value_text and displays them.
   - When the user uploads a CSV, parse it (headers: Name, Reporting period start, Reporting period end, Contractor, Total kg, Total cost GBP, Confidence, Notes, Streams_breakdown — map case-insensitively). **For each CSV data row**: insert **exactly one** row into data_library_records with: account_id, property_id (current selected property UUID or null if "All"), subject_category: 'waste', source_type: 'upload', name from the Name column (e.g. "Waste Jan 2026 – Recorra"), reporting_period_start, reporting_period_end, value_numeric = **Total kg** from that row, unit: 'kg', confidence (normalized), value_text containing at least the Streams_breakdown value (and optionally total cost, notes).
   - **Total cost:** Store Total cost GBP in the same record — e.g. in value_text as structured JSON or key-value (e.g. `{"total_cost_gbp": 333.12, "streams_breakdown": [...]}`) or in a dedicated column if the schema has one. The record must represent the full invoice: one record = one period, one total kg, one total cost, and the streams breakdown for the tile.
   - **Streams_breakdown column:** The sample CSV has a column **Streams_breakdown** containing a JSON array, e.g. [{"stream":"Household waste","kg":420,"method":"measured"},{"stream":"Mixed paper & card","kg":285,"method":"measured"},...]. Store this **entire JSON array in value_text** for that single record (e.g. as the value for key "streams_breakdown" if value_text is an object, or as the sole/minor part of value_text). The Streams breakdown tile will read this record's value_text and render the stream table — no extra records. If the CSV has no Streams_breakdown column but has Notes with text like "Streams: household 420 kg; ...", parse that and build the same JSON array, then store in value_text.
   - If the CSV has multiple rows (multiple invoices), create one record per row; each record still has its own total kg, total cost, and its own streams_breakdown in value_text. Never split one row into multiple records by stream.
   - Optionally upload the CSV file to Storage and link it to the new record via evidence_attachments.

5. **Segregation streams tile — must be populated from records**
   - On the Waste page, the **"Streams breakdown"** / **"Segregation streams"** tile must display stream-level data from waste records. It must not be left empty when records have streams data.
   - **Data source:** Use the same data_library_records loaded for the Waste page (subject_category 'waste'), filtered by current property. For each record, if value_text contains a streams breakdown (JSON array of objects with "stream", "kg", and optionally "method"), parse it and show a table: **Stream | kg | Method**. Prefer showing the breakdown for the record currently selected or in focus (e.g. the row selected or the record open in the drawer); if none is selected, show the most recent record's breakdown. If that record has no structured streams in value_text, show the record's total (value_numeric + unit) and the message "No stream breakdown for this record" or "Add stream breakdown in Edit"; do not leave the tile blank when there are waste records.
   - **Stored format:** Streams are stored in value_text as JSON, e.g. [{"stream":"Household waste","kg":420,"method":"measured"},...]. The tile must read from value_text (or from the same record object that holds value_text) and render the table. If value_text holds both general notes and streams, use a convention (e.g. a key "streams_breakdown" or detect the array) so the tile reliably finds and displays the streams.

6. **List and property filter**
   - Load waste records with supabase.from('data_library_records').select(...).eq('subject_category', 'waste').eq('account_id', currentAccountId). When a specific property is selected, add .eq('property_id', selectedPropertyId). When "All" is selected, either omit the property filter (so all records including property_id null are shown) or explicitly include .or('property_id.eq.' + selectedPropertyId + ',property_id.is.null') depending on desired behaviour. New Manual Entry and CSV-created records must appear in this list.
```

**Sample CSV:** [sample-waste-invoice-jan2026-recorra-140-aldersgate.csv](templates/sample-waste-invoice-jan2026-recorra-140-aldersgate.csv) — **one row = one invoice = one record.** Columns: Name, Reporting period start/end, Contractor, Total kg, Total cost GBP, Confidence, Streams_breakdown (JSON array). Create exactly one data_library_record per CSV row; put Total kg in value_numeric, total cost and Streams_breakdown in value_text; the Streams breakdown tile reads value_text from that record. Do not use the streams CSV ([sample-waste-streams-140-aldersgate.csv](templates/sample-waste-streams-140-aldersgate.csv)) to create one record per stream — that file is only for reference; the canonical upload is the invoice CSV with one row per invoice.

---

### Lovable prompt: Waste CSV — fix “one record per stream” (implementation steps)

Use this when the Waste page **creates 5 records** (e.g. "Waste — CSV row 1" … "Waste — CSV row 5") **instead of 1 record** when uploading the invoice CSV that has **one data row**, or when the **Segregation Streams** tile shows only "48 kg total" and "Add stream breakdown in Edit" instead of the full streams table.

**Root cause:** The parser is either (a) creating one record per element in the Streams_breakdown JSON array, or (b) treating a 5-row streams file as 5 invoices. The invoice CSV has **1 header row + 1 data row** → must produce **1 record**. The Streams_breakdown column is **one string** (a JSON array) to be stored whole in value_text; do not loop over that array to create records.

```
Fix Waste CSV import and Segregation tile

1. CSV parsing — records = CSV data rows only
   - Read the uploaded CSV. Count only the DATA rows (exclude the header row). Example: if the file has 1 header line and 1 data line, you must insert exactly 1 row into data_library_records.
   - For each CSV data row, create exactly one record. Map: Name → name, Reporting period start → reporting_period_start, Reporting period end → reporting_period_end, Total kg → value_numeric, Unit → "kg", Total cost GBP → store in value_text (see below), Confidence → confidence, Streams_breakdown column → store as-is (the whole string) in value_text. Do NOT parse the Streams_breakdown column into separate objects and do NOT create one record per stream. The Streams_breakdown cell is one column with one value (a JSON array string); copy it into value_text for that single record.
   - value_text format: Store a JSON string so the Segregation tile can parse it. Recommended: value_text = JSON.stringify({ streams_breakdown: <parsed array from the Streams_breakdown column>, total_cost_gbp: <Total cost GBP>, notes: <Notes or Contractor/Invoice ref> }). So the record has one value_text that contains both cost and the streams array. If your schema only allows a single string, store at least the streams array: either the raw string from the Streams_breakdown column, or JSON.stringify([...]) of the parsed array.

2. Segregation Streams tile — read value_text and render the table
   - For the record selected in the table (or the most recent waste record if none selected), read its value_text.
   - Parse value_text: if it's a string, JSON.parse(it). If the result has a key "streams_breakdown", use that (it's an array of { stream, kg, method }). If the result is directly an array of such objects, use it.
   - Render a table: one row per element: Stream name | kg | Method. So for streams_breakdown with 5 items you show 5 rows in the tile (Household waste 420 kg, Mixed paper & card 285 kg, etc.), not 5 separate records in the main table.
   - If value_text is null or has no streams_breakdown / no array: show the record's value_numeric (total kg) and the message "No stream breakdown for this record" or "Add stream breakdown in Edit".

3. Accept only invoice CSV format; show clear error for wrong format
   - Required columns (case-insensitive): Name, Reporting period start, Reporting period end, Contractor, Total kg, Total cost GBP, Confidence, and Streams_breakdown (a column whose cell is a JSON array string). If the CSV has columns like "Stream", "kg", "Method" as the first columns (streams-per-row format), do NOT create one record per row. Instead show a friendly validation error next to the file: "Use an invoice CSV with columns: Name, Total kg, Total cost GBP, Streams_breakdown. This file looks like a streams breakdown (one row per stream) — use the invoice file instead, e.g. sample-waste-invoice-jan2026-recorra-140-aldersgate.csv."
   - So: if the file has a "Stream" column and no "Streams_breakdown" column, treat it as wrong format and show the error (red icon + message). Do not parse it as 5 invoices.

4. Upload dialog copy
   - In the "Upload Waste Data" modal, replace any text that says "rows are created as waste records" (which suggests every CSV row becomes a record). Use instead: "Upload invoices, certificates, images or a CSV file. For CSV: use the **invoice format** (one row per invoice, with columns Name, Total kg, Total cost GBP, Streams_breakdown). One invoice row creates one waste record; stream breakdown appears in the Segregation tile."

5. Check after fix
   - Delete the existing 5 waste records (use Delete on each, or Supabase: delete from evidence_attachments where data_library_record_id in (select id from data_library_records where subject_category = 'waste'); delete from data_library_records where subject_category = 'waste';).
   - Re-upload the **invoice** CSV (sample-waste-invoice-jan2026-recorra-140-aldersgate.csv — 1 header row, 1 data row). You must see exactly 1 new record in "Waste Records", with name like "Waste Jan 2026 – Recorra", Total kg 968, and the Segregation Streams tile must show the 5 streams (Household waste 420, Mixed paper & card 285, Plastics 120, Mixed glass 95, Food tins & drink cans 48) in a table. If the user uploads sample-waste-streams-140-aldersgate.csv instead, the app must show the validation error (step 3) and not create 5 records.
```

**To delete waste records already uploaded:** After implementing step 3 (Delete), open each waste record and use Delete, or use the row action in the table. If Delete is not yet in the app, in Supabase Table Editor: delete from `evidence_attachments` where `data_library_record_id` in (select id from data_library_records where subject_category = 'waste' and ...); then delete from `data_library_records` where subject_category = 'waste' and property_id is null (or the ids you want to remove).

---

### Lovable prompt: Waste — when you delete a record, clear the Segregation tile

Use this when **deleting waste records (bills) leaves the Segregation Streams tile still showing the old streams**. There are no separate "segregation records" in the DB — streams live inside each waste record's value_text. The tile must always derive from the current waste records list; when that list is empty after delete, the tile must show empty.

```
On the Data Library Waste page (/data-library/waste):

1. Segregation tile reads only from the waste records list
   - The Segregation Streams tile must have a single source of truth: the list of waste records (data_library_records with subject_category 'waste' for the current account and property). It must not keep its own copy of "segregation data" that outlives the records. When the list is refetched (e.g. after a delete), the tile must re-render from the new list.

2. On Delete of a waste record
   - After successfully deleting the record (evidence_attachments, then data_library_records row), refetch the waste records list (same query as the Waste Records table).
   - Pass the refetched list (or trigger the same state/query that the Segregation tile uses) so the tile re-renders. If the refetched list is empty, the tile must show an empty state: e.g. "No waste records" or "Upload or add data to see stream breakdown" or "No stream data — add waste records above". Do not leave the previous month's streams or totals visible when there are no records.

3. No separate segregation records to delete
   - Streams are stored in each waste record's value_text (streams_breakdown). Deleting the record removes that data from the DB. The fix is purely UI: ensure the tile always reflects the current list and shows empty when the list is empty.
```

---

### Lovable prompt: Waste Segregation tile — dropdown by month (Jan 2026, Feb 2026, All)

Use this when the **Segregation Streams** tile needs a dropdown that lists **actual months from the uploaded data** (e.g. Jan 2026, Feb 2026) plus **All**, so the user can pick which month to view or see the total. The month must come from the record’s period (reporting_period_start), not a generic "By month" label.

```
On the Data Library Waste page, update the Segregation Streams tile as follows.

1. Month comes from the data (reporting_period_start)
   - When saving a waste record from CSV or Manual Entry, ensure reporting_period_start (and reporting_period_end) are set from the CSV columns "Reporting period start" / "Reporting period end". That is how we know which month each record is for. Format the period for display as "Jan 2026", "Feb 2026" (e.g. from reporting_period_start: month name + year).

2. Dropdown options = one per month + "All"
   - Build the dropdown from the current property's waste records (same list as the Waste Records table).
   - For each record, derive a month label from reporting_period_start (e.g. "Jan 2026", "Feb 2026"). Deduplicate and sort chronologically (oldest first). Then add **"All"** as the last option.
   - Example: if you have one record for Jan 2026 and one for Feb 2026, the dropdown options are: **Jan 2026** | **Feb 2026** | **All**. Default to the most recent month (e.g. Feb 2026) or "All" if you prefer.

3. When a specific month is selected (e.g. "Jan 2026")
   - Find the waste record(s) whose reporting_period_start falls in that month (same year and month). Usually one record per month. Show that record's streams: read value_text, parse streams_breakdown, render table Stream | kg | Method. Show a **summary line** for that month: **Total kg** (value_numeric) and **Total cost** (from value_text: total_cost_gbp, or from a dedicated column if the schema has one). Format cost as e.g. "£333.12" or "Total cost £333.12". If there are multiple records for the same month, aggregate their streams (sum kg by stream name) and sum their costs for the summary.

4. When "All" is selected
   - Take all waste records for the current property. For each record that has streams_breakdown in value_text, parse and collect { stream, kg, method }. Aggregate by stream name (sum kg across all records). Render table: Stream | kg (total) | Method, with a **total row** at the bottom (e.g. "Total" | sum of all stream kg | —). Also show **Total cost** for the combined period: sum total_cost_gbp (or equivalent) across all records and display e.g. "Total cost £654.96" (Jan + Feb). So the tile always shows both total kg and total cost for the selected view (one month or all).

5. Labels
   - Dropdown label can be "Period" or "View by month". When a month is selected, the tile can show that period in the subtitle (e.g. "Jan 2026" or "Streams — Jan 2026"). When "All" is selected, use "All months (aggregated)" or "Total".
```

**Cost in the data:** The invoice CSVs include **Total cost GBP** (Jan £333.12, Feb £321.84). When parsing the CSV, store it in value_text (e.g. `total_cost_gbp: 333.12`) so the Segregation tile can display it. Show **total cost for each month** when that month is selected, and **combined total cost** when "All" is selected (e.g. £654.96).

**Sample data:** Upload [sample-waste-invoice-jan2026-recorra-140-aldersgate.csv](templates/sample-waste-invoice-jan2026-recorra-140-aldersgate.csv) and [sample-waste-invoice-feb2026-recorra-140-aldersgate.csv](templates/sample-waste-invoice-feb2026-recorra-140-aldersgate.csv). Each has Reporting period start and **Total cost GBP**. Dropdown: **Jan 2026** | **Feb 2026** | **All**. Jan 2026 → streams table + "Total kg 968, Total cost £333.12"; Feb 2026 → "Total kg 932, Total cost £321.84"; All → aggregated streams + "Total cost £654.96".

---

### Lovable prompt: Energy Tenant Electricity — show records like Waste (and CSV or Manual Entry)

Use this when the **Tenant Electricity** section shows "No records yet" / 0 records even after the user has added data via Manual Entry or upload, or when you want **Tenant Electricity to work like Waste** (records visible in the section, Manual Entry and optionally CSV import that create records that appear there).

**Why it fails:** The Tenant Electricity section and Component Coverage Summary must load records from Supabase with **subject_category = 'energy'** and **data_type = 'tenant_electricity'** (or equivalent), filtered by the **current property**. Manual Entry from that section must set **data_type = 'tenant_electricity'** and **property_id = current selected property**; otherwise the record exists but does not appear in the Tenant Electricity list.

```
On the Data Library Energy page (/data-library/energy), make Tenant Electricity (and the Coverage Summary) show records from Supabase like the Waste page does.

1. Tenant Electricity section — load records and bind table cells to record fields (values must show)
   - The "Tenant Electricity (Direct — Submetered)" section must query data_library_records where subject_category = 'energy' AND (data_type = 'tenant_electricity' OR data_type is null), filtered by the current property. Ensure the query returns reporting_period_start, reporting_period_end, value_numeric, unit, confidence, value_text, name, id. Use the same account_id and property filter as the rest of Data Library.
   - The table **must** render each row from the **record object** — no placeholders or empty cells for period/value/unit. Bind explicitly:
     - **Period** column: use record.reporting_period_start and record.reporting_period_end (e.g. format as "Jan 2026" or "01 Jan 2026 – 31 Jan 2026"). If the column is empty, the row binding is wrong; fix so the cell shows the record's period.
     - **Value** (or "Consumption") column: use **only** record.value_numeric. This is **consumption in kWh** (e.g. 25883). Do **not** use the same source as Cost. If the column shows a dash, the record has null value_numeric — fix by parsing CSV on upload or by Edit.
     - **Unit** column: use record.unit (e.g. "kWh"). The cell must display it.
     - **Cost** column: use **only** the total cost in GBP — parse record.value_text for TotalCostGBP:... or a dedicated cost field. This is **money** (e.g. £8,536). Do **not** use value_numeric for Cost. Value and Cost are different: Value = kWh, Cost = £. Never bind both columns to the same field.
     - **Confidence** column: use record.confidence. Display **"Measured"** when record.confidence === "measured" (title case in UI). The cell must show it.
     - **Evidence**, **Actions** (View, Edit, Delete).
   - Update the Component Coverage Summary so "Records" and "Latest" reflect this query. If no records, show "No records yet" and the Add/Upload buttons.

2. Manual Entry from Tenant Electricity section
   - When the user clicks "+ Manual Entry" (or "Add" / "Manual Entry") from within the Tenant Electricity section, open a form that creates a record with: subject_category = 'energy', data_type = 'tenant_electricity', property_id = current selected property (the one shown in the page header/selector, e.g. "140 Aldersgate London"). Do not leave property_id null unless the user explicitly chose "All" / account-level.
   - Form fields: Name (e.g. "Tenant Electricity Jan 2026 – MAPP"), Reporting period start, Reporting period end, Total kWh (value_numeric), Unit (default "kWh"), Total cost GBP (store in value_text, e.g. "TotalCostGBP:8536; Supplier:MAPP; Invoice:MAPP-0126-140ALD"), **Confidence** (dropdown: Measured, Allocated, Estimated, Cost only — default **Measured**; store in DB as lowercase "measured"). Optional Notes. On submit: insert into data_library_records with subject_category 'energy', data_type 'tenant_electricity', property_id, name, reporting_period_start, reporting_period_end, value_numeric, unit 'kWh', **confidence 'measured'** (or user selection, normalized to lowercase), value_text. Refetch the Tenant Electricity list so the new row appears immediately. The new row must show Period, Value, Unit, and Confidence (e.g. "Measured") in the table as in step 1.

3. CSV upload for Tenant Electricity — parse and fill so Value and Cost show (like Waste)
   - When the user uploads a **CSV** in the Tenant Electricity section (e.g. sample-energy-tenant-electricity-jan2026-mapp-140-aldersgate.csv), **parse the file** and for each data row create one record with **all fields populated**: name (Name column), reporting_period_start, reporting_period_end, **value_numeric = Total kWh** (so the Value column shows the number), **unit = "kWh"**, **value_text** containing e.g. "TotalCostGBP:8536; Supplier:MAPP; Invoice:MAPP-0126-140ALD" (so the Cost column can parse and show £8,536), **confidence** from column (default "measured"). Do not create a record from CSV with only name set and leave value_numeric/value_text null — that causes the table to show dashes. Columns (case-insensitive): Name, Reporting period start, Reporting period end, Supplier, Total kWh, Total cost GBP, Unit, Confidence, Invoice ref, Property, data_type. After import, refetch so the table shows Period, Value (kWh), Unit, Cost (£).
   - If the user uploaded a **file** (e.g. the CSV) and the record was created with name from filename but value_numeric and value_text are null, the table will show dashes. Fix: either (a) when the uploaded file is CSV, parse it as above and insert with value_numeric and value_text set, or (b) allow the user to open the record → Edit and fill Period, Value (kWh), Cost, Confidence so the table can display them.

4. Property match
   - Ensure the Energy page uses the same property selector as the rest of Data Library. When the user has "140 Aldersgate London" selected, property_id must be that property's UUID. Records created with that property_id must then appear in the Tenant Electricity section when that property is selected.

5. Period dropdown (like Waste): "Jan 2026" | "Feb 2026" | "All"
   - Add a **dropdown** in the Tenant Electricity section header (same pattern as the Waste Segregation tile). Label: "Period" or "View by month".
   - **Options:** Build from the loaded tenant electricity records for the current property. For each record, derive a month label from reporting_period_start (e.g. "Jan 2026", "Feb 2026"). Deduplicate and sort chronologically (oldest first). Add **"All"** as the last option. Example: **Jan 2026** | **Feb 2026** | **All**. Default to the most recent month or "All".
   - **When a month is selected:** Filter the table to show only record(s) whose reporting_period_start is in that month (same year and month). Show those rows with Period, Value, Unit, Cost, Confidence as in step 1. Optionally show a summary line for that month (e.g. "Total: 25,883 kWh, £8,536").
   - **When "All" is selected:** Show all tenant electricity records for the property in the table (each row one record). Optionally show an aggregated summary (total kWh, total cost across all records).
   - The table must still bind Period, Value, Unit, Confidence to each record as in step 1; the dropdown only filters which records are shown.
```

**Why the table shows dashes:** The row "Energy bill — sample-energy-tenant-electricity-jan2026-mapp-140-aldersgate" was created by **upload** but the upload did **not** parse the CSV to fill value_numeric, reporting_period_start/end, value_text (cost). So the record has nulls and the table shows dashes. Fix: when the uploaded file is an energy CSV, parse it and insert the record with value_numeric = Total kWh, value_text = TotalCostGBP:...; Supplier:...; Invoice:..., reporting_period_start/end, unit, confidence. Then Value will show kWh and Cost will show £ (from value_text). And ensure **Value** and **Cost** are two separate columns: Value = value_numeric (kWh), Cost = parsed from value_text (£). Never use the same field for both.

**Quick check:** Create one record via Manual Entry (e.g. "Tenant Electricity Jan 2026 – MAPP", 25883 kWh, £8536, period Jan 2026, confidence Measured). The table must show that row with **Period** (e.g. Jan 2026), **Value** (25883), **Unit** (kWh), **Cost** (£8536), **Confidence** (Measured). Value and Cost must be different numbers. Add a second record for Feb 2026; the dropdown must offer Jan 2026, Feb 2026, All.

---

### Rule: Section-specific data — each section has its own query and its own Period dropdown

**Problem:** If the app uses one shared query or one shared Period dropdown for the whole Energy page (or for Indirect Activities), then Scope 1 can show Tenant Electricity (Scope 2) rows, or the Scope 1 dropdown can show months that only exist in other sections. Manual Entry for Scope 1 must not create records that appear in Tenant Electricity.

**Rule:** Every Energy section, and every Scope 3 subsection, must:

1. **Load records** with a query that filters by **data_type** (and subject_category) so only that section’s records are returned.
2. **Build the Period dropdown** from the **records in that section only** (e.g. distinct `reporting_period_start` from the section’s filtered result set). Do not use a global “all energy records” list to build dropdown options for Scope 1.
3. **Manual Entry** in that section must set **data_type** to that section’s value so the new record appears only in that section.

**Energy page — data_type filter per section:**

| Section | Query filter (subject_category = 'energy' AND …) | data_type for Manual Entry |
|---------|--------------------------------------------------|----------------------------|
| Tenant Electricity | data_type = 'tenant_electricity' | tenant_electricity |
| Landlord Utilities (Service Charge) | data_type = 'landlord_recharge' | landlord_recharge |
| Heating | data_type = 'heating' | heating |
| Water | data_type = 'water' | water |
| **Scope 1 / Direct Emissions** | data_type IN ('scope1', 'scope1_stationary', 'scope1_mobile', 'scope1_refrigerants', 'scope1_process') OR data_type LIKE 'scope1%' | scope1_stationary (or chosen sub-type) |

**Scope 3 / Indirect Activities:**

| Subsection | Query filter (subject_category = 'indirect_activities' AND …) | data_type for Manual Entry |
|------------|----------------------------------------------------------------|----------------------------|
| Employee Commuting | data_type IN ('employee_commuting_train', 'employee_commuting_bus', 'employee_commuting_car') | from Mode (train→employee_commuting_train, etc.) |
| Business Travel | data_type IN ('business_travel_flights', 'business_travel_rail', 'business_travel_bus', 'business_travel_car') | from Activity type (flights→business_travel_flights, etc.) |
| Other indirect activities | data_type NOT IN (commuting + business_travel list above) | from Activity type dropdown (e.g. homeworking, upstream_transport, other_indirect) |

**Implementation:** For each section, use a **separate** query (or a single query with a **data_type** parameter). Do not pass “all energy” records into every section and then try to filter in the UI — filter in the query. The Period dropdown in Scope 1 must be built from Scope 1 records only (same for Tenant Electricity, Landlord, Heating, Water, and for Commuting, Business Travel, and Other indirect activities on Indirect Activities).

---

### Lovable prompt: Section-specific tables and dropdowns (Scope 1 ≠ Scope 2; Scope 3 only indirect)

Use this when **Scope 1** shows **Scope 2** options or rows (e.g. "Tenant Direct Electricity" in the Scope 1 table or dropdown), or when **Scope 3 / Indirect Activities** shows Energy records, or when the **Period dropdown** in one section lists months from other sections.

```
On the Data Library Energy page and Indirect Activities page, each section must show only its own records and its own period options. Fix as follows.

1. Energy page — separate query per section
   - Tenant Electricity: load records where subject_category = 'energy' AND data_type = 'tenant_electricity' (and current property). Table and Period dropdown must use only this result set. Period dropdown options = distinct reporting_period_start from these records only (e.g. "Jan 2026", "Feb 2026", "All").
   - Landlord Utilities: subject_category = 'energy' AND data_type = 'landlord_recharge'. Same: table and Period dropdown from this set only.
   - Heating: subject_category = 'energy' AND data_type = 'heating'. Table and Period dropdown from this set only.
   - Water: subject_category = 'energy' AND data_type = 'water'. Table and Period dropdown from this set only.
   - Scope 1 / Direct Emissions: subject_category = 'energy' AND (data_type IN ('scope1', 'scope1_stationary', 'scope1_mobile', 'scope1_refrigerants', 'scope1_process') OR data_type LIKE 'scope1%'). Do NOT include tenant_electricity or landlord_recharge here. Table and Period dropdown from Scope 1 records only. So Scope 1 must never show "Tenant Direct Electricity" or other Scope 2 rows.

2. Manual Entry must set the section's data_type
   - When the user adds data via Manual Entry from the Scope 1 section, set data_type = 'scope1_stationary' (or the chosen sub-type: scope1_mobile, scope1_refrigerants, scope1_process). Do not set tenant_electricity. That way the new record appears only in the Scope 1 table.
   - When the user adds data via Manual Entry from Tenant Electricity, set data_type = 'tenant_electricity'; from Landlord Utilities set 'landlord_recharge'; from Heating set 'heating'; from Water set 'water'.

3. Add Data / type dropdown (if present)
   - If there is an "Add Data" or type dropdown that lists options like "Upload Tenant Electricity", "Manual Entry", "Scope 1 Upload", etc., make it section-aware: when the user is in the Scope 1 section, the dropdown should only show Scope 1 options (e.g. Upload Scope 1, Manual Entry Scope 1, Calculator). When in Tenant Electricity, only Tenant Electricity options. Do not show "Tenant Direct Electricity" in the Scope 1 dropdown.

4. Indirect Activities (Scope 3) page
   - Employee Commuting: load only records where subject_category = 'indirect_activities' AND data_type IN ('employee_commuting_train', 'employee_commuting_bus', 'employee_commuting_car'). Table and Period dropdown from this set only.
   - Business Travel: load only records where subject_category = 'indirect_activities' AND data_type IN ('business_travel_flights', 'business_travel_rail', 'business_travel_bus', 'business_travel_car'). Table and Period dropdown from this set only.
   - Other indirect activities: load records where subject_category = 'indirect_activities' AND data_type is not in the commuting or business_travel lists above. Table and Period dropdown from this set only. Manual Entry in this section sets data_type from an Activity type dropdown (e.g. homeworking, upstream_transport). Adding a new activity type does not create a new accordion — it appears in "Other indirect activities".
   - Do not show Energy or Scope 1/2 records on the Indirect Activities page. Manual Entry in Commuting must set data_type to the chosen mode (e.g. employee_commuting_train); in Business Travel set data_type to the chosen activity (e.g. business_travel_flights).

5. Period dropdown per section
   - Each section (and each Scope 3 subsection) must build its Period dropdown from the records returned for that section only. For example: Scope 1 Period dropdown = distinct reporting_period_start from the Scope 1 query result, not from all energy records. Same for Tenant Electricity, Landlord, Heating, Water, Commuting, Business Travel.
```

**Quick check:** Add one Manual Entry in Scope 1 (e.g. stationary combustion, 100 kWh). It must appear only in the Scope 1 table. The Scope 1 Period dropdown must not list months that exist only in Tenant Electricity. The Tenant Electricity section must not show that Scope 1 record.

---

### Lovable prompt: Energy Tenant Electricity — Value vs Cost (different columns) + parse CSV on upload so table shows data

Use this when **(1)** the table shows **dashes** for Period, Value, Unit, Cost even though a record exists, **(2)** **Value** and **Cost** show the same thing or both empty, or **(3)** uploading the energy CSV creates a record but the table does not show kWh or cost.

```
Tenant Electricity section — fix columns and CSV upload

1. Value and Cost are different
   - **Value** column = consumption in **kWh** only. Data source: record.value_numeric. Example: 25883. Do not use value_numeric for Cost.
   - **Cost** column = total cost in **£ (GBP)** only. Data source: parse record.value_text for "TotalCostGBP:8536" or similar, or a dedicated cost field. Example: £8,536. Do not use value_numeric for Cost. Never bind Value and Cost to the same field — they are different (kWh vs £).

2. Why the table shows dashes
   - Records created by "Upload" without parsing have only name set; value_numeric, reporting_period_start/end, value_text are null. So Period, Value, Unit, Cost show as dash. Fix: when the user uploads a **CSV** file in the Tenant Electricity section, parse it and create the record with all fields filled.

3. When user uploads an energy CSV (e.g. sample-energy-tenant-electricity-jan2026-mapp-140-aldersgate.csv)
   - Parse the CSV. For each data row: insert into data_library_records with name (Name column), reporting_period_start, reporting_period_end, **value_numeric = Total kWh** (number, e.g. 25883), **unit = "kWh"**, **value_text = "TotalCostGBP:8536; Supplier:MAPP; Invoice:MAPP-0126-140ALD"** (or equivalent so Cost column can parse and display £8,536), confidence (from column, default "measured"), subject_category "energy", data_type "tenant_electricity", property_id = current property. Do not create the record with value_numeric and value_text null.
   - After insert, the table will show: Period (from reporting_period_start/end), Value (from value_numeric, e.g. 25883), Unit (kWh), Cost (parsed from value_text, e.g. £8,536), Confidence (Measured). Value and Cost will be different numbers.

4. Table binding (if still showing dashes after data exists)
   - Period cell → record.reporting_period_start, record.reporting_period_end.
   - Value cell → record.value_numeric only (kWh).
   - Cost cell → parse record.value_text for TotalCostGBP or cost; format as currency. Do not use record.value_numeric for Cost.
   - If the record was created before this fix (value_numeric/value_text null), the user can open it → Edit and fill Consumption (kWh), Cost (£), Period, Confidence; save. Then the table will show them.
```

---

### Lovable prompt: Energy Tenant Electricity — table values + period dropdown (like Waste)

Use this when **(1)** the Tenant Electricity **table still does not show** period, value (kWh), or unit, or **(2)** you want a **dropdown to filter by month or All** (like the Waste page).

```
On the Data Library Energy page, Tenant Electricity (Direct — Submetered) section:

PART A — Table must show real values (no empty cells for period/value/unit)
1. Bind each table row to the record object. Each cell must display the record field:
   - **Period:** record.reporting_period_start and record.reporting_period_end — format as "Jan 2026" or "01 Jan 2026 – 31 Jan 2026". Do not leave this cell empty.
   - **Value / Consumption:** record.value_numeric — show the number (e.g. 25883). Do not leave empty.
   - **Unit:** record.unit — show e.g. "kWh". Do not leave empty.
   - **Cost:** from record.value_text only — parse TotalCostGBP:... or similar. This is **money in GBP** (e.g. £8,536). Do **not** use value_numeric for Cost. Value and Cost must be two different columns with different data: Value = consumption (kWh), Cost = total cost (£).
   - **Confidence:** record.confidence — show "Measured" when value is "measured". Do not leave empty.
2. Ensure the query that loads records for this section includes reporting_period_start, reporting_period_end, value_numeric, unit, confidence, value_text. If the table is bound to a different shape (e.g. only name/id), extend the data so each row has these fields and the table uses them. If Value and Cost currently show the same value or both show a dash, fix the binding: Value column → record.value_numeric only; Cost column → parsed cost from record.value_text only.

PART B — Period dropdown (Jan 2026 | Feb 2026 | All), like Waste
3. Add a dropdown in the section header. Label: "Period" or "View by month".
4. Options: from the tenant electricity records for the current property, derive month labels from reporting_period_start (e.g. "Jan 2026", "Feb 2026"). Deduplicate, sort chronologically, then add "All" at the end. Example: Jan 2026 | Feb 2026 | All.
5. When user selects a month: filter the table to records whose reporting_period_start is in that month. When user selects "All": show all records. The table still shows Period, Value, Unit, Cost, Confidence for each row; only which rows are shown changes.
6. Default confidence for Manual Entry in this section: **Measured** (store "measured" in DB).
```

---

### Lovable prompt: Energy Tenant Electricity table — show Period, Value, Unit, Confidence (Measured)

Use this when the **Tenant Electricity** table does not show **period**, **value** (kWh), or **unit**, or when **confidence** is not displayed or does not show as "Measured".

```
On the Data Library Energy page, in the Tenant Electricity (Direct — Submetered) section table:

1. Map table columns to the record fields
   - **Period** column: display reporting_period_start and reporting_period_end (e.g. "Jan 2026" or "01 Jan 2026 – 31 Jan 2026"). Must be visible.
   - **Value** (or "Consumption" / "kWh") column: display value_numeric. Must be visible.
   - **Unit** column: display unit (e.g. "kWh"). Must be visible.
   - **Confidence** column: display the confidence field. When the stored value is "measured" (lowercase in DB), show **"Measured"** (title case) in the UI. Must be visible.

2. Default confidence for new records
   - When creating a record via Manual Entry in this section, default Confidence to **Measured** and store as "measured" (lowercase) in data_library_records. The table will then show "Measured" for that row.
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
   - Insert a row into `data_library_records` with: account_id, property_id (current selected property or null), subject_category "energy", source_type "upload", name (e.g. the file name without extension, or "Energy bill - [filename]"), and optionally reporting_period_start/end if you can derive or leave null. When the user chose **"Upload Tenant Electricity Invoice"**, set data_type = "tenant_electricity" so the record appears in the Tenant Electricity section; similarly for other upload options (e.g. landlord_recharge for Landlord Utilities) if your app filters by data_type.
   - Insert a row into `evidence_attachments` linking that record to that document (data_library_record_id, document_id), with optional tag "invoice".

3. So if the user selects 5 PDFs, create 5 records (each with one attached bill). After upload, refetch the records list so the new rows appear in the Energy table. Show a success message (e.g. "5 files uploaded").

4. Keep "Manual Entry" as a SEPARATE action: it opens the form for entering record details by hand (no file). Do not route "Upload" or "Upload energy record" to Manual Entry. Upload = file picker → upload files → create records + documents + evidence. Manual Entry = form → insert record only.
```

---

### Service Charge (Landlord Utilities) — same as Waste and Tenant Electricity

**Data:** subject_category **energy**, data_type **landlord_recharge**. Confidence **allocated** (not measured). Primary value = **cost in GBP**; unit is **N/A** or **—** (bundled utilities: heat pump, electricity base building, water; full breakout pending). Sample for 140 Aldersgate: Jan 2026 £3,068.05, Feb 2026 £2,980.00.

**Samples:** [sample-service-charge-jan2026-140-aldersgate.csv](templates/sample-service-charge-jan2026-140-aldersgate.csv), [sample-service-charge-feb2026-140-aldersgate.csv](templates/sample-service-charge-feb2026-140-aldersgate.csv) — one row per period, columns: Name, Reporting period start/end, Total cost GBP, Unit (N/A), Confidence (allocated), Invoice ref, Property, data_type, Notes.

---

### Lovable prompt: Service Charge / Landlord Utilities — upload, table, delete, dropdown (like Waste and Tenant Electricity)

Use this to give the **Landlord Utilities (Service Charge / Recharge)** section the same behaviour as Waste and Tenant Electricity: upload (CSV or file), table with values, Manual Entry, Delete, and Period dropdown (Jan 2026 | Feb 2026 | All). Service Charge records are **allocated** (not measured) and have **cost only** (unit N/A).

```
On the Data Library Energy page (/data-library/energy), Landlord Utilities (Service Charge / Recharge) section — implement the same functionality as Tenant Electricity and Waste.

1. Load records and show them in the table
   - Query data_library_records where subject_category = 'energy' AND data_type = 'landlord_recharge' (or equivalent), filtered by current property. Return reporting_period_start, reporting_period_end, value_numeric, unit, confidence, value_text, name, id.
   - Table columns (bind to record):
     - **Period** — record.reporting_period_start, record.reporting_period_end (e.g. "Jan 2026").
     - **Cost** — record.value_numeric (this is the total cost in GBP, e.g. 3068.05). Display as currency (£3,068.05). Do not leave empty when data exists.
     - **Unit** — record.unit; for Service Charge show "N/A" or "—" (bundled utilities; no single consumption unit).
     - **Confidence** — record.confidence. Display **"Allocated"** when stored as "allocated" (title case). Default for new records: **allocated** (not measured).
     - **Notes** (optional) — from value_text (e.g. "Includes heat pump; electricity base building; water. Full breakout pending.").
     - **Evidence**, **Actions** (View, Edit, Delete).
   - Add **Upload** and **Manual Entry** buttons. **Delete** in row or drawer: same as Waste/Energy (confirm, delete evidence_attachments, then data_library_records row; refetch list).

2. Manual Entry
   - Form: Name (e.g. "Service Charge Jan 2026"), Reporting period start, Reporting period end, **Total cost GBP** (value_numeric), Unit (default "N/A"), **Confidence** (default **Allocated**; store "allocated"), Notes (value_text). On submit: insert with subject_category 'energy', data_type 'landlord_recharge', property_id = current property, confidence 'allocated'. Refetch so the new row appears with Period, Cost, Unit (N/A), Confidence (Allocated).

3. CSV upload
   - When the user uploads a CSV in this section, parse it. Columns (case-insensitive): Name, Reporting period start, Reporting period end, Total cost GBP, Unit, Confidence, Invoice ref, Property, data_type, Notes. For each row: insert one record with value_numeric = Total cost GBP, unit = "N/A" (or from column), confidence = "allocated" (or from column), value_text = Notes, reporting_period_start/end, name, subject_category 'energy', data_type 'landlord_recharge', property_id = current property. Do not create records with null value_numeric — parse and fill so the table shows Cost.

4. Period dropdown (Jan 2026 | Feb 2026 | All)
   - Add a dropdown in the section header. Build options from the section's records: month labels from reporting_period_start (e.g. "Jan 2026", "Feb 2026"), sort chronologically, then "All". When a month is selected, filter the table to that month; when "All", show all records. Same pattern as Tenant Electricity and Waste.

5. When user chooses "Upload Service Charge / Landlord Recharge" from the main Add Data dropdown (file upload)
   - If they upload a file, create the record with data_type = "landlord_recharge" so it appears in this section. If the file is a CSV, parse it as in step 3 and fill value_numeric (cost), reporting_period, value_text, confidence = allocated.
```

**Quick check:** Upload [sample-service-charge-jan2026-140-aldersgate.csv](templates/sample-service-charge-jan2026-140-aldersgate.csv) or add via Manual Entry: "Service Charge Jan 2026", £3,068.05, period Jan 2026, confidence Allocated. The table must show Period (Jan 2026), Cost (£3,068.05), Unit (N/A), Confidence (Allocated). Add Feb 2026; dropdown must offer Jan 2026, Feb 2026, All. Delete must remove the record and refresh the list.

---

### Heating — same components as Tenant Electricity (upload, table, delete, dropdown)

**Data:** subject_category **energy**, data_type **heating**. value_numeric = consumption (kWh), unit = kWh, value_text = TotalCostGBP:...; Notes. Confidence typically **measured** (heat meter). Samples: [sample-heating-jan2026-140-aldersgate.csv](templates/sample-heating-jan2026-140-aldersgate.csv) (5,200 kWh, £780), [sample-heating-feb2026-140-aldersgate.csv](templates/sample-heating-feb2026-140-aldersgate.csv) (4,900 kWh, £735). Columns: Name, Reporting period start/end, Supplier, Total kWh, Total cost GBP, Unit (kWh), Confidence, Invoice ref, Property, data_type (heating), Notes.

---

### Lovable prompt: Heating — upload, table, delete, dropdown (like Tenant Electricity)

Use this to give the **Heating** section the same behaviour as Tenant Electricity: upload (CSV or file), table with Period, Value (kWh), Unit, Cost, Confidence, Manual Entry, Delete, Period dropdown (Jan 2026 | Feb 2026 | All).

```
On the Data Library Energy page (/data-library/energy), Heating section — implement the same functionality as Tenant Electricity.

1. Load records and show them in the table
   - Query data_library_records where subject_category = 'energy' AND data_type = 'heating' (or equivalent), filtered by current property. Return reporting_period_start, reporting_period_end, value_numeric, unit, confidence, value_text, name, id.
   - Table columns (bind to record): **Period** (reporting_period_start/end), **Value** (value_numeric — consumption in kWh), **Unit** (unit, e.g. kWh), **Cost** (parse value_text for TotalCostGBP), **Confidence** (e.g. "Measured"), **Evidence**, **Actions** (View, Edit, Delete). Value and Cost are different (kWh vs £); bind Value → value_numeric, Cost → from value_text.
   - Add **Upload** and **Manual Entry** buttons. **Delete** in row or drawer: confirm, delete evidence_attachments then data_library_records row, refetch list.

2. Manual Entry
   - Form: Name, Reporting period start/end, Total kWh (value_numeric), Unit (kWh), Total cost GBP (store in value_text as TotalCostGBP:...), Confidence (default Measured). Insert with subject_category 'energy', data_type 'heating', property_id = current property. Refetch list.

3. CSV upload
   - When the user uploads a CSV in this section, parse it. Columns (case-insensitive): Name, Reporting period start, Reporting period end, Supplier, Total kWh, Total cost GBP, Unit, Confidence, Invoice ref, Property, data_type, Notes. One row = one record. Set value_numeric = Total kWh, unit = kWh, value_text = "TotalCostGBP:xxx; Supplier:...; Invoice:...; " + Notes, confidence (default "measured"), reporting_period_start/end, name, subject_category 'energy', data_type 'heating', property_id = current property. Parse and fill so the table shows Period, Value, Unit, Cost.

4. Period dropdown (Jan 2026 | Feb 2026 | All)
   - Add a dropdown in the section header. Options from records' reporting_period_start (month labels), sort chronologically, then "All". Filter table by selected month; "All" shows all records.

5. When user chooses "Upload Heating Submeter" (or similar) from the main Add Data dropdown
   - Create the record with data_type = "heating". If the file is CSV, parse as in step 3 and fill value_numeric, value_text, reporting_period, unit, confidence.
```

**Samples:** [sample-heating-jan2026-140-aldersgate.csv](templates/sample-heating-jan2026-140-aldersgate.csv), [sample-heating-feb2026-140-aldersgate.csv](templates/sample-heating-feb2026-140-aldersgate.csv).

---

### Water — same components as Tenant Electricity (upload, table, delete, dropdown)

**Data:** subject_category **energy**, data_type **water**. value_numeric = consumption (m³), unit = m³, value_text = TotalCostGBP:...; Notes. Confidence typically **measured**. Samples: [sample-water-jan2026-140-aldersgate.csv](templates/sample-water-jan2026-140-aldersgate.csv) (85 m³, £420), [sample-water-feb2026-140-aldersgate.csv](templates/sample-water-feb2026-140-aldersgate.csv) (82 m³, £405). Columns: Name, Reporting period start/end, Supplier, Total m3 (or Total m³), Total cost GBP, Unit (m³), Confidence, Invoice ref, Property, data_type (water), Notes.

---

### Lovable prompt: Water — upload, table, delete, dropdown (like Tenant Electricity)

Use this to give the **Water** section the same behaviour as Tenant Electricity: upload (CSV or file), table with Period, Value (m³), Unit, Cost, Confidence, Manual Entry, Delete, Period dropdown (Jan 2026 | Feb 2026 | All).

```
On the Data Library Energy page (/data-library/energy), Water section — implement the same functionality as Tenant Electricity.

1. Load records and show them in the table
   - Query data_library_records where subject_category = 'energy' AND data_type = 'water' (or equivalent), filtered by current property. Return reporting_period_start, reporting_period_end, value_numeric, unit, confidence, value_text, name, id.
   - Table columns (bind to record): **Period** (reporting_period_start/end), **Value** (value_numeric — consumption in m³), **Unit** (unit, e.g. m³), **Cost** (parse value_text for TotalCostGBP), **Confidence** (e.g. "Measured"), **Evidence**, **Actions** (View, Edit, Delete). Value and Cost are different (m³ vs £); bind Value → value_numeric, Cost → from value_text.
   - Add **Upload** and **Manual Entry** buttons. **Delete** in row or drawer: confirm, delete evidence_attachments then data_library_records row, refetch list.

2. Manual Entry
   - Form: Name, Reporting period start/end, Total m³ (value_numeric), Unit (m³), Total cost GBP (store in value_text as TotalCostGBP:...), Confidence (default Measured). Insert with subject_category 'energy', data_type 'water', property_id = current property. Refetch list.

3. CSV upload
   - When the user uploads a CSV in this section, parse it. Columns (case-insensitive): Name, Reporting period start, Reporting period end, Supplier, **Total m3** or **Total m³** (value_numeric), Total cost GBP, Unit, Confidence, Invoice ref, Property, data_type, Notes. One row = one record. Set value_numeric = Total m3 (consumption), unit = "m³", value_text = "TotalCostGBP:xxx; Supplier:...; Invoice:...; " + Notes, confidence (default "measured"), reporting_period_start/end, name, subject_category 'energy', data_type 'water', property_id = current property. Parse and fill so the table shows Period, Value (m³), Unit, Cost.

4. Period dropdown (Jan 2026 | Feb 2026 | All)
   - Add a dropdown in the section header. Options from records' reporting_period_start (month labels), sort chronologically, then "All". Filter table by selected month; "All" shows all records.

5. When user chooses "Upload Water Submeter" (or similar) from the main Add Data dropdown
   - Create the record with data_type = "water". If the file is CSV, parse as in step 3 and fill value_numeric, value_text, reporting_period, unit, confidence.
```

**Samples:** [sample-water-jan2026-140-aldersgate.csv](templates/sample-water-jan2026-140-aldersgate.csv), [sample-water-feb2026-140-aldersgate.csv](templates/sample-water-feb2026-140-aldersgate.csv). CSV column for consumption is "Total m3" or "Total m³".

---

### Scope 1 (Direct Emissions) — upload, manual entry, calculator + table, delete, dropdown

**Data:** subject_category **energy**, data_type **scope1_stationary** (or **scope1_mobile**, **scope1_refrigerants**, **scope1_process** for sub-types). value_numeric = quantity (e.g. kWh gas, kg refrigerant), unit = kWh / kg / m³, value_text = TotalCostGBP:...; Fuel type: ...; Notes. **Three ways to add data:** (1) **Upload** (bill or CSV), (2) **Manual Entry** (form), (3) **Calculator** (enter fuel/refrigerant type + quantity; app stores activity and optionally computes tCO₂e). Samples: [sample-scope1-stationary-jan2026-140-aldersgate.csv](templates/sample-scope1-stationary-jan2026-140-aldersgate.csv) (1,200 kWh gas, £360), [sample-scope1-stationary-feb2026-140-aldersgate.csv](templates/sample-scope1-stationary-feb2026-140-aldersgate.csv) (1,150 kWh, £345). Columns: Name, Reporting period start/end, Fuel type, Quantity, Unit, Total cost GBP, Confidence, Invoice ref, Property, data_type, Notes.

---

### Lovable prompt: Scope 1 (Direct Emissions) — upload, manual entry, calculator; table, delete, dropdown

Use this to give the **Scope 1 / Direct Emissions** section the same table, delete, and Period dropdown as other Energy sections, plus **three ways to add data: Upload, Manual Entry, and Calculator**.

```
On the Data Library Energy page (/data-library/energy), Scope 1 / Direct Emissions section — implement the same functionality as Tenant Electricity, Heating, and Water, with one addition: **three** ways to add data (Upload, Manual Entry, **Calculator**).

1. Load records and show them in the table
   - Query data_library_records where subject_category = 'energy' AND (data_type = 'scope1' OR data_type = 'scope1_stationary' OR data_type = 'scope1_mobile' OR data_type = 'scope1_refrigerants' OR data_type = 'scope1_process' or equivalent), filtered by current property. Return reporting_period_start, reporting_period_end, value_numeric, unit, confidence, value_text, name, id.
   - Table columns (bind to record): **Period** (reporting_period_start/end), **Value** (value_numeric — quantity: kWh, kg, or m³), **Unit** (unit), **Cost** (parse value_text for TotalCostGBP), **Fuel / type** (optional; from value_text, e.g. "Natural gas"), **Confidence**, **Evidence**, **Actions** (View, Edit, Delete). Value and Cost are different (quantity vs £).
   - Add **Upload**, **Manual Entry**, and **Calculator** buttons (or "Add" dropdown with three options). **Delete** in row or drawer: confirm, delete evidence_attachments then data_library_records row, refetch list.

2. **Upload** (bill or CSV)
   - When the user uploads a file in this section, create the record with data_type = "scope1" or "scope1_stationary" (or from CSV). If the file is a CSV, parse it. Columns (case-insensitive): Name, Reporting period start, Reporting period end, Fuel type, Quantity, Unit, Total cost GBP, Confidence, Invoice ref, Property, data_type, Notes. One row = one record. Set value_numeric = Quantity, unit = Unit, value_text = "TotalCostGBP:xxx; Fuel type: ...; " + Notes, reporting_period_start/end, name, subject_category 'energy', data_type from column or default scope1_stationary, property_id = current property. Parse and fill so the table shows Period, Value, Unit, Cost.

3. **Manual Entry**
   - Form: Name (e.g. "Scope 1 Gas Jan 2026"), Reporting period start/end, **Quantity** (value_numeric), **Unit** (kWh, kg, m³), Total cost GBP (store in value_text as TotalCostGBP:...), Fuel type (in value_text), Confidence (default Measured). Insert with subject_category 'energy', data_type 'scope1_stationary' (or user-selectable: stationary / mobile / refrigerants / process), property_id = current property. Refetch list.

4. **Calculator**
   - Provide a **Calculator** (or "Add via calculator") flow: user selects or enters **fuel / refrigerant type** (e.g. Natural gas, Diesel, R410A, R134a), **quantity** (number), **unit** (kWh, kg, m³, litres), **reporting period** (start/end). Optionally the app can compute estimated tCO₂e (quantity × emission factor) and show it or store it in value_text; the primary stored record is the **activity data**: value_numeric = quantity, unit = unit, value_text = TotalCostGBP if entered; Fuel type: ...; optionally "Estimated tCO2e: X". Save as a new data_library_record with subject_category 'energy', data_type = scope1_stationary / scope1_mobile / scope1_refrigerants / scope1_process (from fuel type or user choice), source_type = 'manual', so it appears in the Scope 1 table. Refetch list. The calculator is a third way to add data alongside Upload and Manual Entry — do not remove Upload or Manual Entry.

5. Period dropdown (Jan 2026 | Feb 2026 | All)
   - Add a dropdown in the section header. Options from records' reporting_period_start (month labels), sort chronologically, then "All". Filter table by selected month; "All" shows all records.

6. When user chooses "Scope 1" or "Direct Emissions" upload from the main Add Data dropdown
   - Create the record with data_type = "scope1" or "scope1_stationary". If the file is CSV, parse as in step 2.
```

**Samples:** [sample-scope1-stationary-jan2026-140-aldersgate.csv](templates/sample-scope1-stationary-jan2026-140-aldersgate.csv), [sample-scope1-stationary-feb2026-140-aldersgate.csv](templates/sample-scope1-stationary-feb2026-140-aldersgate.csv) — stationary combustion (gas), 140 Aldersgate. Sub-areas (stationary, mobile, refrigerants, process) can share the same table filtered by data_type, or show as sub-sections; ensure all three add options (Upload, Manual Entry, Calculator) are available.

---

## Scope 3 — Indirect Activities (Employee Commuting + Business Travel)

**Route:** `/data-library/indirect-activities`. **Data:** subject_category **indirect_activities**, data_type one of: **employee_commuting_train**, **employee_commuting_bus**, **employee_commuting_car**, **business_travel_flights**, **business_travel_rail**, **business_travel_bus**, **business_travel_car**. value_numeric = quantity (km), unit = km, value_text = trip details or notes. Confidence typically **estimated** (commuting) or **measured** (business travel from expense/travel data). Scope 3 Category 7 = commuting; Category 6 = business travel. Emissions Engine uses these for Scope 3 calculation.

**Page structure (same pattern as Waste / Energy):** Two fixed sub-sections with tables: (1) **Employee Commuting** — load records where data_type starts with employee_commuting_*; (2) **Business Travel** — load records where data_type starts with business_travel_*; (3) **Other indirect activities** — catch-all for other data_types. Each section: **Upload**, **Manual Entry**, table (Period, Type/Mode, Quantity km, Unit, Confidence, Evidence, Actions), **Delete**, and a **Period dropdown** so the user can choose **which month** (e.g. Jan 2026, Feb 2026) or **All**. The dropdown options must be built from that section’s records only (distinct reporting_period_start → month labels, plus "All"). Add Data dropdown: Upload Commuting Data, Upload Business Travel (Flights / Rail / Bus / Car), Manual Entry.

**Other activities:** The UI does **not** auto-create a new accordion when the user adds a new activity type. To avoid orphaned data, add a third accordion: **Other indirect activities**. It shows all records where subject_category = 'indirect_activities' AND data_type is **not** in the commuting/business-travel lists (e.g. homeworking, upstream_transport, downstream_transport, waste_operations, or any other Scope 3 category). That section has its own table, Period dropdown, Manual Entry (with an "Activity type" or data_type choice), and optionally Upload. New activity types then appear there until you add dedicated sections for them.

**Commuting CSV columns (case-insensitive):** Name, Reporting period start, Reporting period end, Mode (Train/Bus/Car), Quantity km (or value_numeric), Unit (km), Confidence, Property, data_type (employee_commuting_train | employee_commuting_bus | employee_commuting_car), Notes. One row per mode per period = one record.

**Business travel CSV columns (case-insensitive):** Name, Reporting period start, Reporting period end, Employee, Trip description, Origin, Destination, Quantity km, Unit (km), Confidence, Property, data_type (business_travel_flights | business_travel_rail | business_travel_bus | business_travel_car), Notes. One row per trip = one record.

---

### Lovable prompt: Scope 3 Indirect Activities — Employee Commuting and Business Travel (upload, table, manual entry, delete, dropdown)

Use this to give the **Indirect Activities** page (`/data-library/indirect-activities`) the same behaviour as Waste and Energy: upload CSV, manual entry, table with Period dropdown, delete.

```
On the Data Library Indirect Activities page (/data-library/indirect-activities), implement the same component pattern as Waste and Energy.

1. **Page structure**
   - **Three** collapsible or tabbed sections: **Employee Commuting**, **Business Travel**, and **Other indirect activities**.
   - **Commuting** and **Business Travel** are fixed; **Other indirect activities** is a catch-all for any indirect_activities record whose data_type is not commuting or business travel (e.g. homeworking, upstream_transport, waste_operations). Adding a new activity type does **not** create a new accordion — it appears in "Other indirect activities" until you add a dedicated section.
   - Each section has: a table of records, **Upload** and **Manual Entry** buttons, **Period** dropdown (Jan 2026 | Feb 2026 | All), and row actions (View, Delete). Add Data dropdown at page or section level: "Upload Commuting Data", "Upload Business Travel (Flights)", "Upload Business Travel (Rail)", "Upload Business Travel (Bus)", "Upload Business Travel (Car)", "Manual Entry" (for Commuting/Business Travel), and in the Other section: "Manual Entry" with an Activity type dropdown (e.g. Homeworking, Upstream transport, Downstream transport, Other — stored as data_type).

2. **Load records**
   - Query data_library_records where subject_category = 'indirect_activities', filtered by current property.
   - **Commuting section:** filter where data_type IN ('employee_commuting_train', 'employee_commuting_bus', 'employee_commuting_car'). Table columns: **Period** (reporting_period_start/end), **Mode** (from data_type or value_text), **Quantity (km)** (value_numeric), **Unit** (km), **Confidence**, **Actions** (View, Delete).
   - **Business Travel section:** filter where data_type IN ('business_travel_flights', 'business_travel_rail', 'business_travel_bus', 'business_travel_car'). Table columns: **Period**, **Type** (flights/rail/bus/car from data_type), **Employee** (from value_text or name), **Trip** (value_text or Notes), **Quantity (km)** (value_numeric), **Unit**, **Confidence**, **Actions** (View, Delete).
   - **Other indirect activities section:** filter where data_type is **not** in the commuting or business_travel lists above (e.g. data_type NOT IN ('employee_commuting_train', 'employee_commuting_bus', 'employee_commuting_car', 'business_travel_flights', 'business_travel_rail', 'business_travel_bus', 'business_travel_car')). Table columns: **Period**, **Activity type** (from data_type, e.g. homeworking, upstream_transport), **Name**, **Quantity** (value_numeric), **Unit**, **Confidence**, **Actions** (View, Delete). This is the catch-all for any other Scope 3 activity the user adds.

3. **Upload CSV — Commuting**
   - When the user uploads a CSV in the Commuting section (or selects "Upload Commuting Data"), parse it. Columns (case-insensitive): Name, Reporting period start, Reporting period end, Mode, Quantity km (or "Quantity km"), Unit, Confidence, Property, data_type (employee_commuting_train | employee_commuting_bus | employee_commuting_car), Notes. One row = one record. Set value_numeric = Quantity km, unit = "km", subject_category = 'indirect_activities', data_type from column (or infer from Mode: Train→employee_commuting_train, Bus→employee_commuting_bus, Car→employee_commuting_car), reporting_period_start/end, name, confidence (default "estimated"), value_text = Notes, property_id = current property. Insert each row into data_library_records. Refetch list.

4. **Upload CSV — Business Travel**
   - When the user uploads a CSV in the Business Travel section (or selects "Upload Business Travel (Flights)" etc.), parse it. Columns (case-insensitive): Name, Reporting period start, Reporting period end, Employee, Trip description, Origin, Destination, Quantity km, Unit, Confidence, Property, data_type (business_travel_flights | business_travel_rail | business_travel_bus | business_travel_car), Notes. One row = one record. Set value_numeric = Quantity km, unit = "km", subject_category = 'indirect_activities', data_type from column, reporting_period_start/end, name, confidence (default "measured"), value_text = "Employee: ...; Trip: ...; Origin: ...; Destination: ...; " + Notes, property_id = current property. Insert each row. Refetch list.

5. **Manual Entry**
   - **Commuting:** Form: Name, Reporting period start/end, Mode (Train | Bus | Car), Quantity (km), Unit (km), Confidence (default Estimated). data_type = employee_commuting_train | employee_commuting_bus | employee_commuting_car from Mode. Insert with subject_category 'indirect_activities', property_id = current property.
   - **Business Travel:** Form: Name, Reporting period start/end, Activity type (Flights | Rail | Bus | Car), Employee name, Trip description, Origin, Destination, Quantity (km), Unit (km), Confidence (default Measured). data_type = business_travel_flights | business_travel_rail | business_travel_bus | business_travel_car. value_text = Employee; Trip; Origin; Destination. Insert with subject_category 'indirect_activities', property_id = current property.
   - **Other indirect activities:** Form: Name, Reporting period start/end, **Activity type** (dropdown: e.g. Homeworking, Upstream transport, Downstream transport, Waste from operations, Other — store as data_type, e.g. homeworking, upstream_transport, downstream_transport, waste_operations, other_indirect). Quantity (value_numeric), Unit (e.g. km, tCO2e, or N/A), Confidence. Insert with subject_category 'indirect_activities', property_id = current property. The new record then appears in the "Other indirect activities" table only.

6. **Delete**
   - When the user deletes a record, delete evidence_attachments for that record, then delete the data_library_records row. Refetch list. If the section shows both Commuting and Business Travel in one table with a Type column, delete still works per record.

7. **Period dropdown (required — so the user knows which month or All)**
   - **Each** Scope 3 section (Employee Commuting, Business Travel, Other indirect activities) must have its **own** Period dropdown in that section’s header. Label: "Period" or "View by month".
   - **Options:** From that section’s records only, derive month labels from reporting_period_start (e.g. "Jan 2026", "Feb 2026"). Deduplicate and sort chronologically (oldest first). Add **"All"** as the last option. Example: **Jan 2026** | **Feb 2026** | **All**. Default to the most recent month or "All".
   - **Behaviour:** When the user selects a month (e.g. Jan 2026), filter the table in that section to records whose reporting_period_start is in that month. When the user selects "All", show all records in that section. The user always sees which month they are viewing (or "All" for aggregated).
   - Ensure CSV upload and Manual Entry set reporting_period_start and reporting_period_end so the dropdown has correct month options.

8. **Add Data dropdown**
   - Options: Upload Commuting Data, Upload Business Travel (Flights), Upload Business Travel (Rail), Upload Business Travel (Bus), Upload Business Travel (Car), Manual Entry (for Commuting/Business Travel). In the **Other indirect activities** section, offer "Manual Entry" with Activity type dropdown so the user can add e.g. Homeworking, Upstream transport, etc.; those records appear in the Other accordion. Each upload option opens file picker for CSV; parse as in steps 3 or 4 and create one record per row.
```

**Quick check (Scope 3 Period):** Upload or add Commuting data for Jan 2026 and Feb 2026. Each section (Commuting, Business Travel, Other) must show a **Period** dropdown with options **Jan 2026** | **Feb 2026** | **All**. Selecting a month must filter the table to that month; "All" must show all records. The user must always be able to see which month (or All) they are viewing.

---

### Lovable prompt: Scope 3 Indirect Activities — add Period dropdown (which month or All)

Use this when the **Indirect Activities** page (/data-library/indirect-activities) is missing a **Period** dropdown, or when you need the user to be able to choose **which month** (e.g. Jan 2026, Feb 2026) or **All** for each section.

```
On the Data Library Indirect Activities page (/data-library/indirect-activities), add a Period dropdown to each section (Employee Commuting, Business Travel, Other indirect activities) so the user always knows which month they are viewing or "All".

1. **One Period dropdown per section**
   - In the **Employee Commuting** section header, add a dropdown. Label: "Period" or "View by month".
   - In the **Business Travel** section header, add a dropdown. Same label.
   - In the **Other indirect activities** section header, add a dropdown. Same label.
   - Each section has its own dropdown; options are built from that section's records only (not shared across sections).

2. **Dropdown options**
   - From the records loaded for that section only, get distinct values of reporting_period_start. For each, format as a month label (e.g. "Jan 2026", "Feb 2026" — month name + year).
   - Deduplicate, sort chronologically (oldest first), then add "All" as the last option. Example: **Jan 2026** | **Feb 2026** | **All**.
   - If the section has no records yet, show only "All" or "No data" as appropriate.

3. **Behaviour**
   - When the user selects a specific month (e.g. "Jan 2026"): filter the table in that section to show only records whose reporting_period_start falls in that month (same year and month).
   - When the user selects "All": show all records in that section (no month filter).
   - The selected value should be visible so the user always knows whether they are viewing one month or all months.

4. **Data**
   - Ensure records have reporting_period_start and reporting_period_end set when created via Manual Entry or CSV upload, so the dropdown can derive the correct month options. If existing records lack these, the dropdown may show "All" only until data with periods is added.
```

**Quick check:** Add or upload Commuting data for Jan 2026 and Feb 2026. The Commuting section must show a Period dropdown with **Jan 2026** | **Feb 2026** | **All**. Choosing Jan 2026 must filter the table to January records; "All" must show both months.

---

**Samples — Commuting (140 Aldersgate, 500 employees, 50% desk-based, min 3 days/week, mostly public transport):**  
[sample-scope3-commuting-jan2026-140-aldersgate.csv](templates/sample-scope3-commuting-jan2026-140-aldersgate.csv) (Train 255,000 km, Bus 91,000 km, Car 18,000 km), [sample-scope3-commuting-feb2026-140-aldersgate.csv](templates/sample-scope3-commuting-feb2026-140-aldersgate.csv) (Train 250,000, Bus 89,000, Car 17,500).

**Samples — Business Travel (140 Aldersgate, fictive names, all employees):**  
[sample-scope3-business-travel-flights-jan2026-140-aldersgate.csv](templates/sample-scope3-business-travel-flights-jan2026-140-aldersgate.csv) (8 trips: Sarah Chen, James Wright, Priya Sharma, etc.), [sample-scope3-business-travel-rail-jan2026-140-aldersgate.csv](templates/sample-scope3-business-travel-rail-jan2026-140-aldersgate.csv) (8 trips), [sample-scope3-business-travel-car-jan2026-140-aldersgate.csv](templates/sample-scope3-business-travel-car-jan2026-140-aldersgate.csv) (5 trips), [sample-scope3-business-travel-bus-jan2026-140-aldersgate.csv](templates/sample-scope3-business-travel-bus-jan2026-140-aldersgate.csv) (4 trips).

---

## Utility applicability and service charge includes (for coverage and agent)

**Purpose:** So that **energy/water/heating coverage** (Complete vs Partial) and the **agent** can infer correctly whether data is complete, the backend stores per-property:

1. **Utility applicability** — For each component (tenant electricity, landlord recharge, heating, water, waste), how it is supplied: **separate bill only**, **included in service charge only** (no separate tenant bill), **both** (separate + in service charge), or **not applicable**.
2. **Service charge includes** — Whether the landlord service charge is known to include **energy**, **water**, and/or **heating**.

Example: at 140 Aldersgate, water and heating are **not** separate tenant bills — they are included in the service charge. So we need to mark heating and water as **included_in_service_charge** (and set **service charge includes: water, heating**) so that (a) the agent knows not to expect separate water/heating bills, and (b) the Water KPI is **complete** when the service charge (that includes water) is uploaded.

**Backend:** Run the migration [add-property-utility-applicability-and-service-charge-includes.sql](database/migrations/add-property-utility-applicability-and-service-charge-includes.sql). It creates `property_utility_applicability` and `property_service_charge_includes` with RLS. See [Coverage and applicability for agent](architecture/coverage-and-applicability-for-agent.md) for how the agent and CoverageEngine use these.

### Lovable prompt: Property utility applicability and service charge includes

Use this so the **app** can record “included in service charge” and “service charge includes” for each property. The agent and CoverageEngine read this from the DB.

```
Add a way for users to configure, per property, (1) how each utility component is supplied, and (2) what the service charge includes. This drives KPI coverage (Complete/Partial) and the agent's reasoning.

1. **Run the backend migration** (if not already run): docs/database/migrations/add-property-utility-applicability-and-service-charge-includes.sql. This creates tables property_utility_applicability and property_service_charge_includes.

2. **Utility applicability (per property):**
   - Add a section or modal, e.g. under Property settings or Data Library / Energy (property-scoped), titled e.g. "Utility billing" or "What bills apply to this property".
   - For each component: **Tenant electricity**, **Landlord recharge (service charge)**, **Heating**, **Water**, **Waste** — let the user choose:
     - **Separate bill only** — data comes only from separate bills (e.g. tenant electricity).
     - **Included in service charge only** — no separate bill; data comes only from the service charge (e.g. "Water and heating not applicable as separate bills — included in service charge").
     - **Both** — both separate bill and service charge can contain this (e.g. water: direct meter + water in SC; complete only when both uploaded if both expected).
     - **Not applicable** — component not relevant for this property.
   - Persist in Supabase: supabase.from('property_utility_applicability').upsert({ account_id, property_id, component, applicability }, { onConflict: 'property_id,component' }). Components: tenant_electricity | landlord_recharge | heating | water | waste. Applicability: separate_bill | included_in_service_charge | both | not_applicable.

3. **Service charge includes (per property):**
   - In the same area or a subsection, add three checkboxes (or toggles): "Service charge includes: Energy", "Service charge includes: Water", "Service charge includes: Heating".
   - **For each checked utility, add an inclusion scope:** When "Service charge includes: Water" is checked, show a dropdown or radio: "Base building spaces only" (value: base_building_only) or "Complete tenant consumption (base building shared + tenant space)" (value: tenant_consumption_included). Same for Energy and Heating when their checkbox is checked. This indicates whether the SC covers only common areas or the tenant's full share; only tenant_consumption_included triggers the double-count rule (see docs/architecture/coverage-and-applicability-for-agent.md).
   - Persist in Supabase: supabase.from('property_service_charge_includes').upsert({ account_id, property_id, includes_energy, includes_water, includes_heating, energy_inclusion_scope, water_inclusion_scope, heating_inclusion_scope }, { onConflict: 'property_id' }). One row per property. Run migration add-service-charge-inclusion-scope.sql if the columns are not yet present.

4. **Load existing values:** When the user opens the form for a property, fetch property_utility_applicability (filter by property_id) and property_service_charge_includes (filter by property_id); pre-fill the dropdowns and checkboxes. Create rows on first save if none exist.

5. **Agent and coverage:** These tables are read by the backend CoverageEngine and the AI agent to infer whether e.g. Water KPI is complete (e.g. if water is "included in service charge only" and "service charge includes water", then uploading the service charge bill is enough for water to be complete). No need to build the CoverageEngine in the app — just persist and display these settings.

6. **Double-counting warning:** When the user is about to upload (or add) a **water** or **heating** record for a property, check property_utility_applicability and property_service_charge_includes for that property: if water (or heating) is "included in service charge only" **and** the inclusion scope for that utility is **tenant_consumption_included** (complete tenant consumption), show a warning: "Water [or Heating] is configured as complete tenant consumption via service charge at this property. Adding a separate water [heating] record may cause double counting; use only the service charge for water [heating]." If the scope is **base_building_only**, do not show this warning (separate record = tenant's own space). Optionally allow upload with warning so the user can correct the scope if needed.
```

**What you do:** Run the migration in Supabase SQL Editor, then paste the prompt into Lovable so the app can set and save "included in service charge" and "service charge includes" per property. The agent and future CoverageEngine will read these tables from the DB.

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

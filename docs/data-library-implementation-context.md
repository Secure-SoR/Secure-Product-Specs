# Data Library — What the backend has and what we need from Lovable

Use this before implementing the backend/upload for the Data Library: it summarises what exists in the repo and what we need from you (Lovable UI and logic) so the implementation matches.

---

## 1. What the backend / repo already has

### Schema (Supabase)

- **data_library_records:** id, account_id, property_id (nullable), subject_category, data_type, value_numeric, value_text, unit, reporting_period_start, reporting_period_end, source_type (connector | upload | manual), confidence (measured | allocated | estimated), allocation_method, allocation_notes, created_at, updated_at.  
  **No `name` column** — records are identified by category + period (and optional value); if the UI shows a "record name", we may need to add a `name` or `title` field, or derive display label in the app.

- **documents:** id, account_id, storage_path, file_name, mime_type, file_size_bytes, created_at, updated_at. Metadata only; the file binary lives in **Supabase Storage** (bucket `secure-documents`).

- **evidence_attachments:** id, data_library_record_id, document_id, created_at. Links a record to a document. One record can have many documents; one document can be attached to one record (or we treat it as one record per attachment; schema allows many-to-many).

### Flow (from implementation plan Phase 3)

1. Create a **data library record** (insert into `data_library_records` with account_id, property_id, subject_category, source_type, confidence, etc.).
2. **Upload file** to Storage: path like `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{uuid}-{fileName}`.
3. Insert a row in **documents** with that storage_path, file_name, mime_type, file_size_bytes.
4. **Attach** record to document: insert into **evidence_attachments** (data_library_record_id, document_id).

### Docs in repo

- [schema.md §3.9–3.11](database/schema.md) — data_library_records, documents, evidence_attachments.
- [data-library.md](data-model/data-library.md) — billing source, confidence, bills as structured records, evidence rules.
- [implementation-plan Phase 3](implementation-plan-lovable-supabase-agent.md) — Data library records + file uploads (high-level steps).
- [bills-register.md](sources/140-aldersgate/bills-register.md) — example mapping (Data Library Category, Confidence, Allocation Method, etc.).

### Gaps in the schema (to confirm with you)

- **Record name/title:** The table has no `name` or `title`. If the UI shows "Electricity Jan 2026" or "Sustainability policy", that is either derived (e.g. category + period) or we should add a `name` column.
- **Subject categories:** The plan mentions scope2, scope3, waste, policy; bills-register uses "Energy & Utilities", "Waste". We need a single list of allowed or suggested **subject_category** values for the UI and for validation (and optionally an enum or check in DB).

---

## 2. What we need from you (Lovable UI and logic)

To implement the backend/upload so it matches the product, please share or confirm:

### A) Navigation and scope

- Where does **Data Library** live in the app? (e.g. top-level nav, under a property, under "Reporting", both account-level and property-level?)
- When creating a record, is it always tied to a **property** (property_id set) or can it be **account-level** (property_id null)? The schema allows both.

### B) Record creation flow

- Does the user **create a record first** (form: category, period, confidence, etc.) and **then** attach file(s)?  
  Or **upload a file first** and then create/link a record (e.g. "This upload is the bill for Electricity Jan 2026")?  
  Or both flows?
- What **fields** does the user see when creating/editing a record? (e.g. name/title, subject category, reporting period start/end, source type, confidence, allocation method, allocation notes, value_numeric/value_text, unit?)
- Do you want a **display name** for the record (e.g. "Electricity Jan 2026")? If yes, we should add a `name` or `title` column to `data_library_records` and document it.

### C) Categories and types

- What **subject_category** values does the UI use or plan to use? (e.g. scope2, scope3, waste, policy, energy_utilities, governance, targets, other?) A fixed list helps for dropdowns and for the agent context.
- Is **data_type** used in the UI (e.g. bill, governance_doc, fm_confirmation)? If so, what values?

### D) File upload and evidence

- **One file per record** or **multiple files per record**? (Schema supports multiple via evidence_attachments.)
- Accepted file types: PDF only, or also images (e.g. photos of bills), Excel, etc.?
- After upload, does the user **attach** the file to an existing record (choose record from list), or is the file always uploaded in the context of a record they just created?

### E) List and filter

- How are records **listed**? (e.g. by property, by category, by year, search?)
- Do you need to show **evidence count** or list of **attached files** per record in the list view?

### F) Storage path and RLS

- Storage path is assumed: `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}`. If property_id is null, use e.g. `account/{accountId}/account-level/{yyyy}/{mm}/...`. Confirm or tell us the path rule you want.
- RLS for Storage: we have example policies in the implementation plan (authenticated users, bucket `secure-documents`). Do you need stricter rules (e.g. path must start with current user’s account_id)?

---

## 3. What we’ll produce once we have the above

- **Schema changes** (if any): e.g. add `name` to data_library_records; optional enum or check for subject_category.
- **Storage:** Bucket and RLS (or SQL snippets) for `secure-documents` with path rules.
- **Upload flow (backend side):** Exact steps and field mapping (create record → upload file → insert document → insert evidence_attachment).
- **Lovable prompts** for Data Library: create record, upload file, attach to record, list records with evidence (so you can paste into Lovable and get UI that matches the backend).

---

## 4. Quick answers you can give

If you prefer to answer in one go, you can fill something like this and paste it:

- **Data Library location:** e.g. "Under Property" / "Top-level" / "Both".
- **Record scope:** "Always property" / "Can be account-level".
- **Flow:** "Record first, then attach file" / "Upload first, then tag as record" / "Both".
- **Record fields in UI:** list the fields (and whether you need a name/title).
- **Subject categories:** list or "use schema + bills-register".
- **Files per record:** one / multiple.
- **File types:** PDF only / PDF + images / other.
- **Record name:** "We need a name field" / "Derive from category + period".

Once we have this, we can lock the backend behaviour and give you the full steps and prompts for uploading files and linking them to records.

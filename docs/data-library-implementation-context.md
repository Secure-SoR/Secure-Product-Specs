# Data Library — What the backend has and what we need from Lovable

Use this before implementing the backend/upload for the Data Library: it summarises what exists in the repo, the **Lovable Data Library structure** (tiles, routes, record model), and the mapping to backend schema and upload flow.

---

## Lovable Data Library structure (reference)

Reference docs:

- **[Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md](sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md)** — **Canonical taxonomy:** four layers (Activity, Emissions, Governance & Strategy, Compliance & Disclosure), scope-as-classification principle, access control IDs, reporting rules, migration notes. Use for alignment of tiles, routes, and backend.
- **[lovable-data-library-context.md](sources/lovable-data-library-context.md)** — Lovable Cursor-ready overview: tiles, routes, record model, engines, 140A, non-goals.
- **[lovable-data-library-spec.md](sources/lovable-data-library-spec.md)** — Lovable detailed spec: where it appears, screens/flows, route map, record creation by category, evidence (record-first + tags), categories, filtering, current limitations.
- **[data-library-routes-and-responsibilities.md](data-library-routes-and-responsibilities.md)** — Backend view: each route, subject responsibilities, per-component fields (energy), and engine pipeline (Activity → Coverage → Emissions → Controllability → Dashboards).
- **[Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md](sources/Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md)** — **Energy & Waste page design (v1):** component-based architecture for `/data-library/energy` and `/data-library/waste`; coverage summary grid, component detail sections (Tenant Electricity, Landlord Utilities, Heating, Water; Waste streams, Contractor); status enums, upload auto-tagging, space awareness, data gaps panel; aligns with CoverageEngine and EmissionsEngine. Use for UI implementation and upload flows.
- **[Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md](sources/Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md)** — **Emissions (Calculated) page (Layer 2, read-only):** React component hierarchy + state logic for `/data-library/scope-data`; data contracts (ScopeSummary, CalculationMeta, EmissionsLineItem, EmissionsPageVM), component tree (ScopeSummaryCard, CalculationMetaStrip, ScopeBreakdownAccordion, TraceabilityDrawer), state/selectors, read-only rules, empty states, styling (Scope 1=amber, 2=green, 3=blue). MVP: mock VM; later: Emissions Engine API.
- **[Secure_Emissions_Engine_Mapping_v1.md](sources/Secure_Emissions_Engine_Mapping_v1.md)** — **Emissions Engine logic (Activity → Scope):** mapping matrix v1 — philosophy (never store emissions as primary; derive from activity; deterministic scope; factor by methodology+version; confidence). Activity→Scope tables (Energy & Utilities, Waste & Recycling, Indirect Activities); factor resolution; calculation formula; scope aggregation; confidence scoring; factor versioning; 140 Aldersgate example. Use for engine implementation and for aligning Emissions (Calculated) UI with classification rules.
- **[Secure_Emissions_Engine_Schema_Draft_v1.md](sources/Secure_Emissions_Engine_Schema_Draft_v1.md)** — **Emissions Engine DB draft:** tables for emission_factor_sets, emission_calculation_runs, emission_line_items; factor versioning and recalculation; mapping to EmissionsPageVM; optional note on CoverageEngine persistence.
- **[Secure_KPI_Coverage_Logic_Spec_v1.md](sources/Secure_KPI_Coverage_Logic_Spec_v1.md)** — **CoverageEngine (KPI completeness):** Complete / Partial / Unknown from component state; utility component profile (per property, per period); inference rules (tenant electricity, service charge, heating, water, waste); KPI requirement mapping; pseudocode for `CoverageEngine.evaluate()`; dashboard tooltips; schema draft for coverage_assessments.

Summary from both:

- **Location:** Top-level sidebar at `/data-library`; gated by auth and `data_library` module flag. Property selector filters context (cross-portfolio view).
- **Hub:** Three tabs — My Data (tile grid), Shared Data (table), Connectors (grid). "Add Data" dropdown: Connect Platform, Upload Documents, Manual Entry, Rule Chain.
- **Subpages:** Generic table pattern (Water, Waste, Certificates, ESG, Indirect Activities) or custom (Energy, Scope data, Governance, Targets, Occupant Feedback). Table columns: Record Name, Ingestion Method, Confidence, Linked Report, Last Updated, Actions. **View** → drawer with Evidence & Attachments panel (upload + tags), Audit History.
- **Record creation:** No universal form — Governance (dialog: category, title, status, responsible person), Targets (dialog: category, scope, baseline/target, unit, status), others currently mock/stub.
- **Evidence:** Record-first, then attach files. One record → many files. Upload dialog: file (PDF/Excel/CSV/Images, max 10MB), **tag** (invoice, contract, methodology, certificate, report, other), optional description. Evidence is currently localStorage; backend will use Storage + `documents` + `evidence_attachments`.
- **Emissions:** Read-only calculated at `/data-library/scope-data` — never stored as primary records.

---

## Alignment with Data Library Taxonomy v3

The **[Data Library Taxonomy v3](sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md)** is the source of truth for layers and access control. Summary:

| Layer | Content | Routes / tiles | Storage |
|-------|--------|----------------|---------|
| **Layer 1 — Activity** | Energy & Utilities, Waste & Recycling, **Indirect Activities** | `/energy`, `/waste`, `/water`, `/indirect-activities` | `data_library_records` (evidence-backed, editable, property-scoped) |
| **Layer 2 — Emissions** | Emissions (Calculated) — scope breakdown, factor source, methodology | `/scope-data` only | **Read-only**; no manual records. Output of Emissions Engine from Activity + Waste + Indirect. |
| **Layer 3 — Governance & Strategy** | Governance & Accountability, Targets & Commitments | `/governance`, `/targets` | `data_library_records` (subject_category governance / targets) |
| **Layer 4 — Compliance & Disclosure** | ESG Disclosures (document archive), Certificates | `/esg`, `/certificates` | `data_library_records` + evidence; disclosures = document storage only |

**Principle:** Scope is a **classification outcome**, not a primary data category. Reports pull from Activity and Emissions Engine; they must not store emissions or duplicate datasets.

**Access control (Lovable):** Use these **access IDs** for per-tile permissions (from Taxonomy v3 §7). Ensure the **targets** page uses `targets`, not `esg_governance`.

| Tile | Access ID |
|------|-----------|
| Energy & Utilities | `energy_utilities` |
| Waste & Recycling | `waste` |
| Indirect Activities | `indirect_activities` |
| Emissions (Calculated) | `scope_123` (read-only) |
| Governance & Accountability | `governance` |
| Targets & Commitments | `targets` |
| ESG Disclosures | `esg` |
| Certificates | `certificates` |

---

## Lovable → Backend mapping

| Lovable concept | Backend (current) | Action |
|-----------------|-------------------|--------|
| **Record Name** | No column | Add `name` (or `title`) to `data_library_records` — see [migration](database/migrations/add-data-library-record-name-and-enums.sql). |
| **Ingestion Method** | `source_type`: connector, upload, manual | Extend to allow `rule_chain` (Lovable “Rule Chain” in Add Data). |
| **Confidence** | measured, allocated, estimated | Extend to allow `cost_only` (Energy: “Cost Only” for landlord recharge). |
| **Subject / category** | `subject_category` (text) | Use canonical list below for UI and validation; no DB enum required. |
| **Period** | `reporting_period_start`, `reporting_period_end` | Already aligned. |
| **Evidence** | `documents` + `evidence_attachments` | One record, many files. Lovable upload has **tag** (invoice, contract, methodology, certificate, report, other) and **description** — add optional `tag`, `description` on `evidence_attachments` if UI needs them stored (see [optional migration](database/migrations/add-evidence-attachment-tag-and-description.sql)). |
| **Audit** | `audit_events` (entity_type = `data_library_records`) | Use for record create/update and evidence attach. |
| **Linked Report** | — | Not in schema; optional/future. |

### Canonical subject categories (aligned with Taxonomy v3 + Lovable)

Use these for dropdowns, filters, and agent context. **Emissions (scope-data)** is Layer 2 — calculated only; do not store as a record category.

| Tile ID / route | Suggested `subject_category` |
|-----------------|------------------------------|
| energy | `energy` |
| water | `water` |
| waste | `waste` |
| indirect-activities | `indirect_activities` |
| certificates | `certificates` |
| esg | `esg` |
| governance | `governance` |
| targets | `targets` |
| occupant-feedback | `occupant_feedback` |

Evidence record types (Lovable) map to same categories: `energy`, `scope1`, `scope2`, `scope3`, `waste`, `water`, `governance`, `target`, `certificate`, `policy`, `general`.

---

## Upload flow (backend)

1. **Create record:** `INSERT INTO data_library_records` with `account_id`, `property_id` (or null), `subject_category`, `source_type`, `confidence`, `name` (if present), `reporting_period_start`/`_end`, etc.
2. **Upload file to Storage:** bucket `secure-documents`, path `account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}` (or `account/{accountId}/account-level/{yyyy}/{mm}/...` if no property).
3. **Register document:** `INSERT INTO documents` with `account_id`, `storage_path`, `file_name`, `mime_type`, `file_size_bytes`.
4. **Attach to record:** `INSERT INTO evidence_attachments` (`data_library_record_id`, `document_id`).
5. **Audit:** Insert into `audit_events` for record create/update and (optionally) for evidence attach (entity_type `data_library_records` or a dedicated evidence action).

**Flow choice:** Lovable pattern is “record first, then attach file(s)” in the Evidence panel; the backend supports multiple files per record via `evidence_attachments`.

### Limitations from Lovable spec (what to build)

From [lovable-data-library-spec.md §7](sources/lovable-data-library-spec.md): (1) Most record data is hardcoded mock — wire generic and Energy categories to Supabase. (2) Evidence is localStorage-only — implement Storage + documents + evidence_attachments. (3) "Add Data" actions are stubs — connect Upload Documents / Manual Entry to create record + upload flow. (4) No per-property scoping — backend has `property_id`; list/filter by selected property when Lovable is ready. (5) No reporting period filter — backend has `reporting_period_start`/`_end`; add date range filter on sub-pages. (6) Scope data is hardcoded — emissions remain calculated elsewhere; do not store as Data Library records.

---

## Prompt to paste into Lovable (get a description of the Data Library)

Paste this into Lovable so it describes what the Data Library section currently has. Then copy Lovable’s reply and share it (e.g. paste here or into this doc) so we can align the backend.

```
Please describe the Data Library section in this app in detail so we can document it for the backend team. Include:

1. Where Data Library appears in the app (navigation: top-level, under a property, under Reporting, etc.).
2. What screens or flows exist (e.g. list of records, create record, upload file, attach evidence).
3. For creating or editing a "data library record": what fields does the user see and fill in? (e.g. name/title, category, reporting period, confidence, source type, allocation method, etc.)
4. How files are added: does the user create a record first and then attach a file, or upload a file first and then link it to a record? Can one record have multiple files?
5. What categories or types are used for records (e.g. scope2, waste, policy, energy & utilities).
6. How the list of records is shown and filtered (by property, by category, by year, etc.).

Reply in a clear, structured way (numbered or with headings) so we can use it as a spec.
```

---

## 1. What the backend / repo already has

### Schema (Supabase)

- **data_library_records:** id, account_id, property_id (nullable), subject_category, **name** (optional), data_type, value_numeric, value_text, unit, reporting_period_start, reporting_period_end, source_type (connector | upload | manual | rule_chain), confidence (measured | allocated | estimated | cost_only), allocation_method, allocation_notes, created_at, updated_at. See [migration](database/migrations/add-data-library-record-name-and-enums.sql).

- **documents:** id, account_id, storage_path, file_name, mime_type, file_size_bytes, created_at, updated_at. Metadata only; the file binary lives in **Supabase Storage** (bucket `secure-documents`).

- **evidence_attachments:** id, data_library_record_id, document_id, created_at. Optional: **tag**, **description** for Evidence panel (invoice, contract, methodology, etc.) — [add-evidence-attachment-tag-and-description.sql](database/migrations/add-evidence-attachment-tag-and-description.sql). One record can have many documents.

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

### Schema changes applied (from Lovable alignment)

- **Record name:** Added `name text` to `data_library_records` (nullable). Use for "Record Name" in the table/drawer. Migration: [add-data-library-record-name-and-enums.sql](database/migrations/add-data-library-record-name-and-enums.sql).
- **source_type:** Extended to allow `rule_chain` (in addition to connector, upload, manual).
- **confidence:** Extended to allow `cost_only` (in addition to measured, allocated, estimated).
- **Subject categories:** Canonical list is in the [Lovable → Backend mapping](#lovable--backend-mapping) table above; use for UI and validation (no DB enum).

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

- **Schema:** Migration [add-data-library-record-name-and-enums.sql](database/migrations/add-data-library-record-name-and-enums.sql) adds `name` and extends `source_type` and `confidence` checks.
- **Storage:** Bucket `secure-documents`; path format in [schema.md §3.10](database/schema.md). RLS: implementation plan Phase 3; path under `account/{accountId}/...`.
- **Upload flow:** See [Upload flow (backend)](#upload-flow-backend) above.
- **Lovable reference:** Full structure in [lovable-data-library-context.md](sources/lovable-data-library-context.md). Use for Cursor project instructions or prompts so backend and UI stay aligned.
- **Step-by-step (Lovable + Supabase):** [data-library-lovable-supabase-step-by-step.md](data-library-lovable-supabase-step-by-step.md) — make the UI dynamic: run migrations, Storage, replace mock list, create record, upload evidence, evidence panel, property scoping, optional filters.

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

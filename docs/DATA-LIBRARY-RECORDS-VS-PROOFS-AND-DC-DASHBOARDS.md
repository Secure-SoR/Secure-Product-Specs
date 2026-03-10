# Data Library: records vs proofs, shared upload, and DC dashboard data

**Branch:** `feature/dc-dashboards-data-library`  
**Purpose:** Single source of truth for (1) how the data library is structured (records vs proofs), (2) that upload is one shared component across the data library, and (3) that data library data populates the Data Centre dashboards. Use this when implementing or refining the data library and DC dashboards so they stay aligned.

**Backend schema:** [database/schema.md](database/schema.md) §3.9 data_library_records, §3.10 documents, §3.11 evidence_attachments. **Data library context:** [data-library-implementation-context.md](data-library-implementation-context.md).

---

## 1. Data library structure: records vs proofs

### Records (structured data)

**Table:** `data_library_records`

- **What they are:** The actual data entries — energy readings, water consumption, waste tonnage, governance items, targets, certificates, etc. Each row is one “record” in the data library (e.g. “January 2026 electricity”, “Q4 waste”, “Net zero target”).
- **Key columns:** `account_id`, `property_id` (optional), `subject_category` (energy, water, waste, governance, targets, …), `source_type` (connector | upload | manual | rule_chain), `confidence`, `name`, `value_numeric`, `value_text`, `unit`, `reporting_period_start`, `reporting_period_end`, etc.
- **Used for:** Listing in Data Library tiles/tables, filtering by category/property/period, and **feeding dashboards** (e.g. Energy YTD, PUE, carbon) when aggregated or filtered by property/category.

### Proofs (evidence / documents)

**Tables:** `documents` + `evidence_attachments`; file binary in **Supabase Storage** (bucket `secure-documents`).

- **What they are:** Files (PDFs, Excel, CSV, images) that support or prove a record. A record can have zero or many proofs.
- **Flow:** Upload file → store in Storage → insert row in `documents` → link to record via `evidence_attachments` (data_library_record_id, document_id). Optional: `tag` (invoice, contract, methodology, certificate, report, other) and `description` on `evidence_attachments`.
- **Used for:** Evidence panel in the Data Library (view/attach proofs per record), audit, and compliance — not for numeric aggregation on dashboards. Dashboards use **records**; proofs are for traceability.

**Rule:** Records hold the data that populates dashboards. Proofs support records; they do not replace records. Every “Add Data” / “Upload” flow that creates or updates a number (e.g. energy, water) must create or update a **record** and may attach **proofs** to it.

**Planned (future):** A feature is to be built where a **human reviewer validates proofs** — e.g. confirming that an attached document is accepted as evidence for the record, with optional status (e.g. pending / validated / rejected) and audit trail. Not in current scope; schema and UI to be defined when the feature is scheduled.

---

## 2. Upload: one shared component across the data library

- **Requirement:** There must be **one** shared upload flow (component/hook) used everywhere in the data library: Energy, Water, Waste, Certificates, Governance, Manual Entry, “Upload Documents”, etc. No separate or stub flows that bypass it.
- **Flow (same everywhere):**
  1. User creates a new record (or selects an existing one).
  2. User selects file(s) — PDF, Excel, CSV, images; max size per app policy (e.g. 10MB).
  3. Optional: tag (invoice, contract, methodology, certificate, report, other), description.
  4. Upload to Supabase Storage → insert `documents` → insert `evidence_attachments` linking to the record.
  5. If the flow also creates/updates numeric or text data from the file (e.g. “extract from CSV”), create/update `data_library_records` accordingly and optionally attach the uploaded file as proof.
- **Backend steps:** See [data-library-implementation-context.md § Upload flow](data-library-implementation-context.md) — create record, upload to Storage, register document, attach to record, audit.
- **Do not:** Use different upload logic per tile (e.g. Energy with one implementation, Water with another). Reuse one component so behaviour and data shape are consistent and every entry point writes to the same tables.

---

## 3. How data library data populates the DC dashboards

- **Data Centre dashboards** (portfolio and property-level) read from:
  - **`data_library_records`** — for energy YTD, PUE, carbon, water, renewable %, coverage, etc. Filter by `property_id` (and optionally `subject_category`, `reporting_period_start`/`_end`).
  - **`dc_metadata`** — for target PUE, design capacity, current IT load, renewable %, WUE target, etc. (one row per DC property.)
  - **`properties`** — for name, address, asset_type.
- **There is no separate “dashboard data” store.** If the data library has the right records (energy, emissions, water, etc.) for a DC property, the DC dashboards should show that data when wired to the same Supabase tables. Proofs (documents) are not read by dashboards; they are for evidence and audit.
- **Implication:** To have data on the DC dashboards, ensure (1) records exist in `data_library_records` for the right property and subject categories, and (2) DC dashboard queries use the same tables and filters (property_id, subject_category, period). The shared upload and “create record + attach proof” flow ensures that when users add data via the data library, that data is available for the dashboards.

---

## 4. Checklist for implementation (Lovable)

- [ ] **Records vs proofs:** Every data library screen treats “records” as rows in `data_library_records` and “proofs” as documents linked via `evidence_attachments`. No mixing (e.g. using a document as the only source of a KPI).
- [ ] **Single upload component:** One upload/attach flow used by all “Add Data” / “Upload Documents” / “Manual Entry” entry points in the data library. Same Storage path pattern, same `documents` + `evidence_attachments` writes.
- [ ] **DC dashboards:** Dashboard tiles and charts for Data Centre read from `data_library_records` (and `dc_metadata`, `properties`). No mock or hardcoded data; empty state when no records exist.
- [ ] **Subject categories:** Records use consistent `subject_category` values (e.g. energy, water, waste, governance, targets) so filters and dashboard queries can rely on them. See [data-library-implementation-context.md § Canonical subject categories](data-library-implementation-context.md).

---

## 5. Lovable prompt (optional): unify upload and wire data library to DC dashboards

Use this when you want Lovable to implement or refactor the data library and DC dashboard wiring.

```
Data library and Data Centre dashboards — structure and shared upload.

1) Records vs proofs
- Records = data_library_records (the structured data: energy, water, waste, governance, etc.). Proofs = documents in Storage + evidence_attachments linking files to records. Dashboards must read from records (and dc_metadata for DC), not from documents. Ensure every data library screen clearly separates “record” (row in data_library_records) from “evidence” (attached files).

2) One shared upload component
- Use a single upload/attach flow for the entire data library: Energy, Water, Waste, Certificates, Manual Entry, Upload Documents, etc. Same steps: create/select record → upload file → Storage + documents + evidence_attachments. Do not keep separate or stub upload logic per tile. Reuse one component so all entry points write to the same backend tables.

3) DC dashboards fed by data library
- Data Centre dashboards (portfolio and property-level) must read from Supabase: data_library_records (filter by property_id, subject_category, reporting period), dc_metadata, properties. Remove any mock or hardcoded data. When no data exists, show proper empty state. Data that users add via the data library (records) should appear on the DC dashboards where relevant (e.g. energy → Energy YTD, PUE-related records → PUE tile).
```

---

*Branch: feature/dc-dashboards-data-library. Backend repo: Secure-SoR-backend.*

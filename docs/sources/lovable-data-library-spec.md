# Data Library — Detailed Specification (from Lovable)

This document is the **detailed spec** returned by Lovable (where Data Library appears, screens/flows, record creation by category, evidence model, filtering, limitations). Use it with [lovable-data-library-context.md](lovable-data-library-context.md) for full alignment.

---

## 1. Where Data Library Appears in the App

- **Top-level sidebar item**: "Data Library" at `/data-library`. First-class module, not nested under a property or Reporting.
- Gated behind authentication (`ProtectedRoute`) and the `data_library` module flag (Account Settings → Modules).
- **Property selector** in the header filters context (which property's data is shown); Data Library is a cross-portfolio view.

---

## 2. Screens and Flows

### 2.1 Data Library Hub (`/data-library`)

Three tabs:

| Tab | Purpose |
|-----|--------|
| **My Data** | Tile grid in four sections (§5). Each tile links to a category sub-page. Coverage stats, item counts, source-method breakdown. |
| **Shared Data** | Table of items shared with the user (owner, role, source method, locked/active). Currently mock/read-only. |
| **Connectors** | Grid of integrations (Power BI, Google Sheets, SAP, Envizi). Currently mock. |

- **"Add Data"** dropdown: Connect Platform, Upload Documents, Manual Entry, Rule Chain (placeholder stubs).
- Admins: **"Manage Access"** → Account Settings.

### 2.2 Category Sub-Pages — Two Patterns

**Pattern A: Generic Table Sub-Page** (`DataLibrarySubPage`)

- Routes: `/data-library/water`, `/waste`, `/certificates`, `/esg`, `/indirect-activities`
- Table columns: Record Name, Ingestion Method, Confidence Level, Linked Report, Last Updated, Actions (View).
- **View** → slide-over drawer: record metadata, **Evidence & Attachments** panel (list + upload), **Audit History** panel.

**Pattern B: Custom Sub-Pages**

- **`/data-library/energy`** — Multi-section: Tenant Electricity, Landlord Utilities, Scope 1 (Stationary/Mobile/Refrigerants/Process), Heating, Water. Upload / Create Data Request (stubs).
- **`/data-library/scope-data`** — Read-only calculated emissions (Scope 1/2/3).
- **`/data-library/governance`** — Table: Category, Title/Description, Status, Responsible Person. "Add Governance Item" dialog.
- **`/data-library/targets`** — Table: Category, Scope, Baseline, Target, Status. "Add Target" dialog.
- **`/data-library/occupant-feedback`** — Survey flows: create/view/submission.

### 2.3 Full Route Map

```
/data-library                          Hub (3 tabs)
/data-library/energy                   Energy & Utilities (custom)
/data-library/water                    Water (generic table)
/data-library/waste                    Waste & Recycling (generic table)
/data-library/certificates             Certificates (generic table)
/data-library/esg                      ESG Disclosures (generic table)
/data-library/scope-data                Emissions — Calculated (read-only)
/data-library/governance               Governance & Accountability (custom)
/data-library/targets                  Targets & Commitments (custom)
/data-library/indirect-activities      Indirect Activities (generic table)
/data-library/occupant-feedback        Occupant Feedback (custom)
/data-library/occupant-feedback/create Create Feedback Request
/data-library/occupant-feedback/submission/:id  View Submission
```

---

## 3. Creating or Editing a Record

**No universal create form.** Creation is category-specific.

### 3.1 Generic Table Categories (Water, Waste, Certificates, ESG, Indirect Activities)

- Currently **hardcoded mock** — no create/edit form.
- "Add Data" dropdown = toast stubs.

### 3.2 Governance (AddGovernanceItemDialog)

| Field | Type | Required |
|-------|-----|----------|
| Category | oversight, accountability, policy, risk-management, engagement | Yes |
| Title | Text | Yes |
| Description | Textarea | No |
| Status | in-place, in-progress, planned | Yes |
| Responsible Person | Text | No |
| Evidence Reference | Text | No |

### 3.3 Targets (AddTargetDialog)

| Field | Type | Required |
|-------|-----|----------|
| Category | carbon, energy, waste, water, social, governance | Yes |
| Scope Type | scope-1, scope-2, scope-3 | No |
| Baseline Year, Baseline Value | Number | Yes / No |
| Target Year, Target Value | Number | Yes / No |
| Unit | Text (tCO₂e, %, m³) | Yes |
| Status | on-track, at-risk, behind | Yes |
| Linked Metric Type, Notes | Text/Textarea | No |

### 3.4 Energy

- Mock invoice rows; Upload / Create Data Request = stubs.

### 3.5 Occupant Feedback

- Dedicated create flow (CreateFeedbackRequest).

---

## 4. How Files Are Added (Evidence Attachments)

**Model: Record-first, then attach files.**

1. User clicks **View** on a record row → drawer opens.
2. **Evidence & Attachments** panel: list of files + **Upload** (if edit access).
3. Upload dialog: **File picker** (PDF, Excel, CSV, Images; max 10MB), **Tag** (Invoice, Contract, Methodology, Certificate, Report, Other), **Description** (optional).
4. File is attached to the record (`recordId` + `recordType`).

**Characteristics:**

- **One record, multiple files** — panel lists all evidence for that record.
- **Files always linked to a record** — no upload without record context.
- Evidence (currently mock): `id`, `recordId`, `recordType`, `recordName`, `fileName`, `fileReference`, `uploadedBy`, `uploadedByName`, `uploadedAt`, `tags[]`, `description`.
- Evidence: delete, download (stub). Reports reference evidence read-only; no report-level upload.

---

## 5. Categories and Types

### Section A — Operational Activity Data

| Tile ID | Title | Route |
|---------|-------|-------|
| energy | Energy & Utilities | /data-library/energy |
| waste | Waste & Recycling | /data-library/waste |
| indirect-activities | Indirect Activities | /data-library/indirect-activities |
| certificates | Certificates | /data-library/certificates |

### Section B — Emissions (Calculated)

| Tile ID | Title | Route |
|---------|-------|-------|
| scope-data | Emissions (Calculated) | /data-library/scope-data |

### Section C — Governance & Strategy

| Tile ID | Title | Route |
|---------|-------|-------|
| governance | Governance & Accountability | /data-library/governance |
| targets | Targets & Commitments | /data-library/targets |

### Section D — Compliance

| Tile ID | Title | Route |
|---------|-------|-------|
| esg | ESG Disclosures | /data-library/esg |

### Additional

- **Water** — /data-library/water (generic table; tile in Section A in context doc).
- **Occupant Feedback** — /data-library/occupant-feedback (not in hub tile grid in this spec).

### Evidence Record Types (for attachments)

`energy`, `scope1`, `scope2`, `scope3`, `waste`, `water`, `governance`, `target`, `certificate`, `policy`, `general`

### Evidence Tags

`invoice`, `contract`, `methodology`, `certificate`, `report`, `other`

---

## 6. List and Filtering

- **Hub:** Context badges (Portfolio, Property, Organization) from header — display only.
- **Sub-pages:** Same badges; **text search** by name and ingestion method (case-insensitive). No date/category/advanced filters yet.
- **Governance/Targets:** Filter by title, category, responsible person, notes.
- **Sorting:** None (hardcoded/insertion order).

### Access per category (mock map)

| Category | Default Access |
|----------|----------------|
| scope_123 | edit |
| energy_utilities | view |
| water | view |
| waste | view |
| certificates | edit |
| esg_governance | view |
| governance | edit |
| targets | edit |
| occupant_feedback | view |

---

## 7. Current Limitations (for backend)

1. **Record data** — Phase 1 Supabase is implemented for data_library_records (energy, water, waste, certificates, ESG, etc.) and Governance/Targets where wired.
2. **Evidence** — Supabase Storage (bucket `secure-documents`) + `documents` + `evidence_attachments` are implemented; upload and link flow in place.
3. **"Add Data" actions** — some may still be stubs; connect to create record + upload flow where needed.
4. **Per-property scoping** — backend has `property_id`; list/filter by selected property when Lovable is ready.
5. **No reporting period / date range filter** on sub-pages.
6. **Scope data (emissions) is hardcoded** — no calculation engine.

# Data Library Specifications
**Secure SoR — Data Library Module**
*Version 1.0 | February 2026 | Owner: Anne*

---

## Overview

The Data Library is the single source of structured activity data and evidence for the Secure platform. It is available at top-level navigation `/data-library`, gated by auth and the `data_library` module flag. A property selector filters context (cross-portfolio view).

**Structure:** Four layers (from [Data Library Taxonomy v3](sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md)):

- **Layer 1 — Activity:** Energy & Utilities, Waste & Recycling, Water, Indirect Activities. Editable records; evidence-backed. Stored in `data_library_records`; proofs in `documents` + `evidence_attachments`.
- **Layer 2 — Emissions:** Emissions (Calculated) — read-only; derived by Emissions Engine from Activity + factors. No manual records.
- **Layer 3 — Governance & Strategy:** Governance & Accountability, Targets & Commitments. Stored in `data_library_records`.
- **Layer 4 — Compliance & Disclosure:** ESG Disclosures, Certificates. Records + evidence; disclosures = document archive.

**Records vs proofs:** Records = rows in `data_library_records` (the data that feeds dashboards and engines). Proofs = files in Supabase Storage + `documents` + `evidence_attachments` linking files to records. One record can have many proofs. See [DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md](../DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md).

**Upload:** One shared upload/attach component must be used across all Data Library entry points (Energy, Water, Waste, Certificates, Manual Entry, Upload Documents, etc.). Same flow: create/select record → upload file → Storage + `documents` + `evidence_attachments`.

**Planned (future):** A feature is to be built where a **human reviewer validates proofs** — e.g. a user reviews attached evidence and marks it as validated (or rejected), with status and audit trail. Not in current scope; schema and UI to be defined when the feature is scheduled.

---

## Routes

| Section | Route | Layer | Storage |
|--------|-------|-------|---------|
| Hub | `/data-library` | — | — |
| My Data (tile grid) | (hub tab) | — | — |
| Shared Data (table) | (hub tab) | — | — |
| Connectors | (hub tab) | — | — |
| Energy & Utilities | `/data-library/energy` | 1 | `data_library_records` |
| Waste & Recycling | `/data-library/waste` | 1 | `data_library_records` |
| Water | `/data-library/water` | 1 | `data_library_records` |
| Indirect Activities | `/data-library/indirect-activities` | 1 | `data_library_records` |
| Emissions (Calculated) | `/data-library/scope-data` | 2 | Read-only (Emissions Engine) |
| Governance & Accountability | `/data-library/governance` | 3 | `data_library_records` |
| Targets & Commitments | `/data-library/targets` | 3 | `data_library_records` |
| ESG Disclosures | `/data-library/esg` | 4 | `data_library_records` + evidence |
| Certificates | `/data-library/certificates` | 4 | `data_library_records` + evidence |
| Occupant Feedback | `/data-library/occupant-feedback` | — | (survey/wellness) |

---

## Layer 1 — Activity

### Section 1: Energy & Utilities

**Route:** `/data-library/energy`  
**Subject category:** `energy` (canonical); UI may use sub-types: `electricity`, `heat`, `service_charge`, etc.  
**Purpose:** Record and evidence energy consumption; feeds CoverageEngine, EmissionsEngine, ControllabilityEngine, and dashboards (Office and Data Centre).

#### Record model (data_library_records)

| Field | Use |
|-------|-----|
| account_id, property_id | Scoping |
| subject_category | `energy` (or sub-type) |
| name | Record name in table/drawer |
| source_type | connector \| upload \| manual \| rule_chain |
| confidence | measured \| allocated \| estimated \| cost_only |
| value_numeric, value_text, unit | Consumption / cost |
| reporting_period_start, reporting_period_end | Period |
| allocation_method, allocation_notes | Where applicable |

#### Components (UI)

- Tenant Electricity (submetered), Landlord Utilities (service charge / recharge), Heating (optional), Water (optional), Direct Emissions (Scope 1 if applicable).
- Per component: Control badge, Confidence badge, Coverage status, KPI summary, Evidence drawer, Audit history.
- Table columns: Record Name, Ingestion Method, Confidence, Linked Report, Last Updated, Actions. View → drawer with Evidence & Attachments (upload + tags), Audit History.

#### Evidence

- Record-first; then attach files. Upload: PDF/Excel/CSV/Images (max 10MB), tag (invoice, contract, methodology, certificate, report, other), optional description. Storage: bucket `secure-documents`; link via `evidence_attachments`.

#### Data sources (backend)

- **Records:** `data_library_records` WHERE subject_category IN ('energy', 'electricity', 'heat', 'service_charge', …) AND property_id / account_id.
- **Proofs:** `documents` JOIN `evidence_attachments` ON data_library_record_id.

#### Feeds

- CoverageEngine, EmissionsEngine, ControllabilityEngine; Office dashboards; Data Centre dashboards (Energy YTD, PUE-related).

---

### Section 2: Waste & Recycling

**Route:** `/data-library/waste`  
**Subject category:** `waste`  
**Purpose:** Record waste streams and contractor data; Scope 3 Category 5 at emissions layer.

#### Record model

- Same core fields as Energy; subject_category = `waste`. Stream-specific: kg, method, cost per period.

#### Components

- Contractor block (e.g. Recorra — direct tenant / landlord-managed).
- Waste streams: Plastics, Mixed glass, Food tins & drink cans, Mixed paper & card, Household waste.
- Period table: kg, method, cost, evidence. Confidence: Measured / Allocated / Estimated / Cost only.

#### Evidence & data sources

- Same pattern: one shared upload; Storage + documents + evidence_attachments. Records from `data_library_records` WHERE subject_category = 'waste'.

#### Feeds

- EmissionsEngine (Scope 3); CoverageEngine; dashboards where waste KPIs are shown.

---

### Section 3: Water

**Route:** `/data-library/water`  
**Subject category:** `water`  
**Purpose:** Record water consumption; evidence-backed.

#### Record model

- Same core fields; subject_category = `water`. value_numeric / unit for volume (m³, etc.).

#### Components

- Generic table pattern: Record Name, Ingestion Method, Confidence, Last Updated, Actions. View → Evidence & Attachments, Audit History.

#### Evidence & data sources

- Shared upload component. Records: `data_library_records` WHERE subject_category = 'water'.

#### Feeds

- EmissionsEngine; Data Centre dashboards (WUE, cooling water where relevant).

---

### Section 4: Indirect Activities

**Route:** `/data-library/indirect-activities`  
**Subject category:** `indirect_activities`  
**Purpose:** Scope 3 activity data (business travel, supply chain, etc.).

#### Record model

- Same core fields; subject_category = `indirect_activities`.

#### Components

- Generic table pattern; Evidence & Attachments in drawer.

#### Evidence & data sources

- Shared upload. Records: `data_library_records` WHERE subject_category = 'indirect_activities'.

#### Feeds

- EmissionsEngine (Scope 3); reporting and dashboards.

---

## Layer 2 — Emissions (Calculated)

### Section 5: Emissions — Scope Data (Read-Only)

**Route:** `/data-library/scope-data`  
**Purpose:** Display Scope 1/2/3 breakdown and methodology; no manual records. Output of Emissions Engine from Activity + factors.

#### Behaviour

- **No "Add Data"** for scope data. All values derived from `data_library_records` (Activity) + emission factors + calculation runs.
- UI: Scope cards with totals, confidence mix bar; metadata strip (factor set, timestamp); collapsible tables per scope; row click → traceability drawer (factor, formula, source record links, evidence list view-only).

#### Data sources

- Emissions Engine API / tables (e.g. emission_calculation_runs, emission_line_items); source records from `data_library_records` for traceability.

#### Feeds

- Dashboards (carbon tiles); reporting; TCFD/GRESB disclosure.

---

## Layer 3 — Governance & Strategy

### Section 6: Governance & Accountability

**Route:** `/data-library/governance`  
**Subject category:** `governance`  
**Purpose:** Structured governance registry (oversight, policy, commitment, engagement, risk).

#### Record model

- subject_category = `governance`. Fields: name/title, status, responsible person, category (oversight, policy, commitment, engagement, risk). Dialog for create/edit.

#### Components

- Table; create/edit dialog (category, title, status, responsible person). Evidence drawer per record.

#### Evidence & data sources

- Shared upload. Records: `data_library_records` WHERE subject_category = 'governance'.

---

### Section 7: Targets & Commitments

**Route:** `/data-library/targets`  
**Subject category:** `targets`  
**Purpose:** Target register (carbon, energy, waste, water).

#### Record model

- subject_category = `targets`. Fields: category, scope, baseline/target, unit, status. Dialog for create/edit.

#### Components

- Table; create/edit dialog (category, scope, baseline, target, unit, status). Evidence drawer.

#### Evidence & data sources

- Shared upload. Records: `data_library_records` WHERE subject_category = 'targets'.

---

## Layer 4 — Compliance & Disclosure

### Section 8: ESG Disclosures

**Route:** `/data-library/esg`  
**Subject category:** `esg`  
**Purpose:** Policies & disclosures (Environmental Policy, Net Zero Commitment, GRESB, CDP, TCFD, Supplier Code). Document archive + optional structured fields.

#### Record model

- subject_category = `esg`. Record per disclosure type or document set; evidence is primary (PDFs).

#### Components

- Table; Evidence & Attachments; document-centric view.

#### Evidence & data sources

- Shared upload. Records: `data_library_records` WHERE subject_category = 'esg'. Proofs drive disclosure evidence.

---

### Section 9: Certificates

**Route:** `/data-library/certificates`  
**Subject category:** `certificates`  
**Purpose:** EPC, BREEAM, ISO, WELL, etc. Evidence-driven.

#### Record model

- subject_category = `certificates`. Name, type, validity period, evidence.

#### Components

- Table; Evidence & Attachments (certificate PDFs, etc.).

#### Evidence & data sources

- Shared upload. Records: `data_library_records` WHERE subject_category = 'certificates'.

---

## Canonical subject categories

Use for dropdowns, filters, and backend queries. Emissions (scope-data) is Layer 2 — do not store as a record category.

| Tile / route | subject_category |
|--------------|------------------|
| Energy & Utilities | `energy` |
| Waste & Recycling | `waste` |
| Water | `water` |
| Indirect Activities | `indirect_activities` |
| Governance & Accountability | `governance` |
| Targets & Commitments | `targets` |
| ESG Disclosures | `esg` |
| Certificates | `certificates` |
| Occupant Feedback | `occupant_feedback` |

---

## Access control (Taxonomy v3)

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

## Engine flow

```
Activity records (data_library_records)
  → CoverageEngine (Complete / Partial / Unknown)
  → EmissionsEngine (Activity → Scope 1/2/3)
  → ControllabilityEngine
  → Dashboards & Recommendations
```

---

## Future features

| Feature | Description |
|--------|-------------|
| **Human validation of proofs** | A human reviewer validates proofs — e.g. reviews attached evidence and marks it as validated (or rejected), with status and audit trail. Schema and UI to be defined when the feature is scheduled. |

---

## References

- [data-library-implementation-context.md](../data-library-implementation-context.md) — Backend mapping, upload flow, Lovable prompts.
- [DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md](../DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md) — Records vs proofs, shared upload, DC dashboard data flow.
- [data-library-routes-and-responsibilities.md](../data-library-routes-and-responsibilities.md) — Per-route responsibilities and engine relationships.
- [esg-report-specifications.md](esg-report-specifications.md) — ESG Report module (routes: `/esg`, `/esg/corporate`, `/esg/secr`, `/esg/advisor`). Governance and Targets tabs use Data Library live; Energy & Carbon / Waste & Water to be wired.
- [database/schema.md](../database/schema.md) — data_library_records, documents, evidence_attachments.

---

*Secure SoR — Data Library — v1.0 — February 2026*

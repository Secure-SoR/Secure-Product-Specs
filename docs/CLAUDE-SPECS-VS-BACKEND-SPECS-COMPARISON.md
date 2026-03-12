# Claude Specs vs docs/specs — Data Library and ESG Report

**Purpose:** Compare the specs created with Claude (in `docs/sources/Claude Specs/` — .docx) with the backend specs in `docs/specs/` (data-library-specifications.md, esg-report-specifications.md). The two are **not the same**. This doc lists the main differences and what appears only in Claude Specs (misalignments / gaps).

**Claude Specs (sources):**
- `docs/sources/Claude Specs/secure-data-library-spec-v3.docx`
- `docs/sources/Claude Specs/secure-esg-report-spec-v2.docx`

**Backend specs (canonical for current implementation):**
- `docs/specs/data-library-specifications.md`
- `docs/specs/esg-report-specifications.md`

---

## 1. Data Library — Summary

| Aspect | Claude Spec (v3) | Backend spec (docs/specs) |
|--------|------------------|---------------------------|
| **Data access** | **REST API** under `/api/v1` (GET/POST/PATCH/DELETE for records, evidence, validation, coverage, import, audit) | **No REST API** — app uses **Supabase** directly (tables, RLS, Storage) |
| **Human validation** | **First-class**: `record_validations` table, validation_status lifecycle (unvalidated → evidence_attached → approved \| rejected \| flagged_for_review), validator role, POST /validate | **Planned (future)** — “human reviewer validates proofs” noted; no schema or workflow in current spec |
| **Coverage** | **Dedicated**: `coverage_assessments` table, GET/POST coverage endpoints, Coverage Engine triggers on record/validation/evidence changes | **Referenced** — CoverageEngine reads records; no coverage table or API in schema |
| **Records schema** | `quantity`, `period_start`/`period_end`, `data_source`, `confidence_level`, `validation_status`, `deleted_at`, `created_by` | `value_numeric`/`value_text`, `reporting_period_start`/`end`, `source_type`, `confidence`, **no** validation_status, **no** deleted_at |
| **subject_category** | Granular enum (e.g. energy_electricity, energy_gas, water_mains, waste_general, emissions_scope1/2/3, refrigerant_loss) with unit rules; emissions_* write-blocked | Canonical list (energy, waste, water, governance, targets, esg, etc.); emissions read-only from Emissions Engine |
| **Evidence** | `evidence_role`: primary_source \| methodology \| verification \| certificate; `period_covered_start`/`end`; storage path invariant; bucket `secure-evidence` | `evidence_attachments` with optional tag/description; bucket `secure-documents`; no evidence_role enum in schema |
| **Bulk import** | POST /data-library/import, CSV template, dry_run preview, max 2000 rows, per-row validation, Coverage trigger | Optional future RPC; “extract from CSV” in UI; no formal import API |
| **Soft delete** | `deleted_at` on records; DELETE is soft-delete only | No deleted_at in current schema |
| **Audit** | Full audit_events schema (entity_type, entity_id, action, actor_id, diff, ip_address, user_agent); append-only | audit_events referenced; no detailed shape in Data Library spec |
| **Roles** | member, validator, admin, service_role (agent), auditor (read-only) | RLS + account; module flag; per-tile access IDs (governance, targets, esg) |
| **NFRs** | Rate limits, P95 latency targets, retention (e.g. agent_findings 2 years), CSV security (formula injection), scale ceiling 5k properties / 500k records | Performance and file size (10MB) noted; no rate limits or retention in spec |

---

## 2. Data Library — What Claude Specs Add (misalignments if we follow backend only)

- **record_validations table** — Append-only; action (approved \| rejected \| flagged_for_review), validator_id, rejection_reason, validated_at. Backend schema has **no** such table.
- **coverage_assessments table** — property_id, period_start/end, coverage_pct, missing_categories[], confidence_breakdown. Backend schema has **no** coverage table.
- **validation_status on data_library_records** — Lifecycle: unvalidated → evidence_attached → under_review → approved (or rejected). Backend schema has **no** validation_status column.
- **REST API surface** — All of §2 in Claude (records CRUD, evidence CRUD, validate, coverage GET/POST, import, audit). Backend assumes Supabase client only.
- **Emissions in Data Library** — Claude: Emissions Engine **writes** emissions_* records into data_library_records; API blocks user writes to emissions_*. Backend: Emissions are derived; “no manual records” for scope data; no emissions_* in data_library_records in current schema.
- **Evidence bucket name** — Claude: `secure-evidence`. Backend: `secure-documents`.
- **Storage path** — Both use account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}. Aligned.
- **Bulk import** — Claude: full workflow with dry_run, row limit, duplicate detection. Backend: shared “extract from CSV” flow in UI; no import API.
- **Agent write-back** — Claude: agent writes agent_findings; triggers Coverage; record detail shows “AI Findings” tab. Backend: agent_findings exist; no formal “AI Findings” panel in Data Library spec.

---

## 3. ESG Report — Summary

| Aspect | Claude Spec (v2) | Backend spec (docs/specs) |
|--------|------------------|---------------------------|
| **Entry / UX** | **Wizard**: “New Report” at `/reports/esg` → Step 1 (framework, period) → Step 2 (scope, boundary) → Step 3 (coverage preview, Generate) | **Hub + tabs**: `/esg` (or `/reports`) hub with cards; `/esg/corporate` (7 tabs), `/esg/secr`, `/esg/advisor` — no wizard |
| **Persistence** | **report_instances**, **report_sections**, **report_evidence_links** tables; status (draft → under_review → published → archived) | **No report tables** in schema; report instance in **localStorage**; “future: report_versions or report_instances” |
| **API** | **REST** `/api/v1/reports`: GET/POST reports, GET/PATCH sections, evidence links, submit/publish/archive, export PDF/CSV, gap-analysis | **Supabase** for data; **POST /api/reporting-copilot** (agent) from AI Agents dashboard; **client-side** PDF export |
| **Report generation** | **Server-side engine**: load boundary, activity data, emissions, coverage, governance, evidence; framework mapping; confidence_summary; gaps; evidence links; write report_instances/sections/evidence_links | **Client-side**: load governance/targets from Supabase; mock for Energy & Carbon / Scope 3 / Waste & Water; Reporting Copilot separate (agent) |
| **Frameworks** | SECR, GRESB, GRI (Horizon 1); TCFD, SFDR, CRREM (Horizon 2); each with scope description | SECR, GRESB, TCFD, CDP, SFDR; no CRREM; no Horizon split in spec |
| **Publish rules** | Publish blocked if mandatory section has has_gaps = true and gap_severity = blocking; RLS UPDATE revoked for published reports | Status Draft → Requested → In Review → Approved in localStorage; no server-side publish lock |
| **Export** | GET /reports/:id/export/pdf and /export/csv; server-generated; 202 + job_id if deferred | Client-side PDF (useExport / pdfGenerator); no CSV export in spec |
| **Gap analysis** | POST /reports/gap-analysis; report_readiness agent; returns agent_run_id | Reporting Copilot from /ai-agents; dataReadinessOutput/boundaryOutput passed when available |

---

## 4. ESG Report — What Claude Specs Add (misalignments if we follow backend only)

- **report_instances table** — id, account_id, report_type, report_name, reporting_year, period_start/end, status, scope2_method, boundary_approach, included_property_ids, coverage_snapshot, confidence_summary, generated_at, published_at, created_by, created_at, updated_at. Backend schema has **none** of this.
- **report_sections table** — report_instance_id, section_key, framework, display_order, content (jsonb), has_gaps, gap_notes, source_record_ids, etc. Backend has **no** report_sections.
- **report_evidence_links table** — Links report sections to documents. Backend has **no** such table.
- **Wizard flow** — Claude: 3-step wizard at `/reports/esg`. Backend: hub at `/esg` or `/reports` with cards; no wizard.
- **Server-side report generation** — Claude: engine that loads all data, applies framework mapping, writes sections and evidence links. Backend: no server-side engine; report built in UI from Supabase + mock.
- **Status workflow** — Claude: draft → under_review → published → archived; publish and archive endpoints; immutable published reports. Backend: Draft/Requested/In Review/Approved in localStorage only.
- **Export API** — Claude: GET export/pdf and export/csv with optional 202 + job_id. Backend: client-side PDF only; no export API.
- **Gap analysis endpoint** — Claude: POST /reports/gap-analysis. Backend: gap analysis via Reporting Copilot / Data Readiness from AI Agents dashboard; no dedicated reports gap endpoint.

---

## 5. Are they the same?

**No.** The Claude Specs describe a **REST API–based, server-side** product with:

- Data Library: validation lifecycle, coverage_assessments, record_validations, bulk import API, rate limits, and a richer record schema (quantity, validation_status, deleted_at, etc.).
- ESG Report: report_instances/sections/evidence_links, wizard, server-side generation, publish/archive workflow, and export API.

The **docs/specs** (backend) describe the **current Secure setup**: Supabase-only data access, no REST API, no record_validations or coverage_assessments, no report tables, report state in localStorage, client-side PDF export, and Lovable UI (hub + tabs, no wizard).

---

## 6. How to use this

- **To implement the current product (Lovable + Supabase):** Use **docs/specs/** as canonical. Treat Claude Specs as a **target or future** reference; any adoption of Claude’s API or schema would require migrations and backend work.
- **To align with Claude Specs later:** Use this doc as a gap list: add record_validations, coverage_assessments, validation_status, report_instances/sections/evidence_links, REST API (or equivalent via Edge Functions + RPCs), and the wizard/generation/publish flow. Then update docs/specs and schema to match.

---

*Generated from Claude Specs (.docx) and docs/specs/*.md. Update this file when either side changes.*

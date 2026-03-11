# ESG Report Specifications
**Secure SoR — Sustainability Reporting / ESG Report Module**
*Version 1.0 | February 2026 | Owner: Anne*

This spec follows [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) (10 required sections).

---

## Note for the engineering team (production build)

This spec integrates the **Lovable UI description** of the ESG Report feature (routes, screens, data sources, and connections). Use it as the canonical reference for production. When the Lovable app repo is available, align code with these routes and flows. For backend-only work, see Data sources (backend) and References.

---

## 1. Feature Overview

The **ESG Report** (Sustainability Reporting) is a platform module that produces and presents ESG-related outputs for disclosure and export. It consumes data from the Data Library, Emissions Engine, and AI agents (Data Readiness, Boundary, Reporting Copilot). It supports frameworks such as SECR, GRESB, TCFD, CDP, and SFDR.

**Purpose:** Provide a single place to view, generate, and export sustainability/ESG report content — structured SoR data only — for regulatory (e.g. SECR), voluntary (GRESB, CDP, TCFD), and investor (SFDR) use.

**Relationship to other modules:**

- **Data Library** — Source of activity data (energy, waste, water, governance, targets, ESG disclosures, certificates). Governance and Targets tabs pull live data from `data_library_records`. See [data-library-specifications.md](data-library-specifications.md).
- **Emissions (Calculated)** — Scope 1/2/3 from Emissions Engine; read-only. Report uses this for carbon/emissions sections (Energy & Carbon tab to be wired to real data).
- **Reporting Copilot** — AI agent (POST `/api/reporting-copilot`) invoked from **AI Agents** dashboard (`/ai-agents`), not from the report page. App should pass `dataReadinessOutput` and `boundaryOutput` when available. Generated report is displayed in the AI Agents dashboard.
- **DC dashboards** — The Data Centre **ESG & Reporting Readiness** dashboard (`/dashboards/data-centre/:propertyId/esg`) is separate; this spec is for the **ESG Report** module under `/esg`.

**Who uses it:** Sustainability / ESG teams, asset managers, and report preparers. Access behind auth; report scope is account-level (reporting boundary). **Business problem:** Single place to view, generate, and export sustainability/ESG content for regulatory (SECR), voluntary (GRESB, CDP, TCFD), and investor (SFDR) use without duplicating data entry.

---

## 2. Functional Requirements

- User opens Reports from sidebar → hub at `/esg` (or `/reports`) with report cards (Sustainability & Energy Report, UK SECR, Reporting Advisor, optional Landlord Pack).
- User clicks "Open Report" on Sustainability & Energy Report → `/esg/corporate` with 7 tabs (Executive Summary, Organisational Boundary, Energy & Carbon, Scope 3, Waste & Water, Governance & Data Quality, Targets). User can edit narratives, request review, print, export PDF. System shows live data from Data Library (Governance, Targets) and Emissions Engine where wired; mock data for Energy & Carbon, Scope 3, Waste & Water until wired.
- User opens UK SECR → `/esg/secr` (preview mode); sample data only; Print/Export disabled. User opens Reporting Advisor → `/esg/advisor` for AI-powered recommendations (hardcoded list for now).
- Report instance status (Draft → Requested → In Review → Approved) stored in localStorage; data change detection shows "Re-open as Draft" when source data changes after approval. Expected system response: tabs load correct data; export produces PDF; back button returns to hub.

---

## 3. API Endpoints / Data Surface

- **Supabase tables:** `data_library_records` (governance, targets), `documents`, `evidence_attachments`, `accounts` (reporting boundary). Queries scoped by `account_id`. No report-specific tables yet; report instance in localStorage.
- **External:** POST `/api/reporting-copilot` — AI agent; invoked from AI Agents dashboard (`/ai-agents`). Request: property context, reporting year, optionally `dataReadinessOutput`, `boundaryOutput`. Response: generated report payload (structure TBD). Status codes: 200 OK, 4xx/5xx on failure.
- **Export:** Client-side PDF generation (`useExport` / `pdfGenerator`); no dedicated export endpoint.

---

## 4. Database Schema

- **Read from:** `data_library_records` (subject_category IN ('governance', 'targets')), `evidence_attachments`, `documents`, `accounts`. See [docs/database/schema.md](../database/schema.md).
- **Report instance (future):** Consider `report_versions` or `report_instances` table (id, account_id, report_type, reporting_year, status, narrative_snapshot, created_at, updated_at) for persistence and audit. Not in current schema; currently localStorage.

---

## 5. Business Logic & Validation Rules

- Report scope = account-level; no property selector on report pages. Reporting year and boundary approach from `accounts.reportingBoundary`.
- Governance and Targets tabs: only display records where subject_category = 'governance' | 'targets'. Energy & Carbon / Waste & Water: when wired, use data_library_records + Emissions Engine output; no manual override of calculated emissions in report.
- Export PDF: only for Sustainability & Energy Report and (from hub) Landlord Pack. SECR export disabled. Report instance status transitions: Draft ↔ Requested ↔ In Review ↔ Approved; data fingerprint change after approval → show "Re-open as Draft".

---

## 6. Authentication & Authorization

- All report routes behind **ProtectedRoute**. RLS on underlying tables (data_library_records, accounts) enforces account scope. No role-based restriction on viewing reports; any account member can open report. Export and "Request Review" follow same auth. Reporting Copilot invoked from AI Agents dashboard; agent API may require API key or session (implementation-specific).

---

## 7. State & Workflow

- **Report instance status:** Draft → Requested → In Review → Approved. Stored in localStorage (`useReportInstance`). Trigger: user clicks "Request Review" or admin updates status. Data change detection: when governance/targets record set or timestamps change after approval, show "Re-open as Draft" and allow user to reset to Draft.
- **Sequence:** User opens report → loads data from Supabase (governance, targets) and optionally Emissions Engine; mock for unwired tabs. User edits narratives → save to localStorage. User exports PDF → client-side generation. Reporting Copilot run is separate flow from AI Agents dashboard.

---

## 8. Error Handling

- **Data load failure:** If Supabase query for governance/targets fails, show inline error in tab ("Unable to load data. Try refreshing."); do not surface raw error. Fallback: empty table or placeholder.
- **Export failure:** If PDF generation fails, show toast or inline message ("Export failed. Try again.").
- **Reporting Copilot:** On 4xx/5xx, show error in AI Agents dashboard; do not update report page. No retry logic specified.
- **No specific error codes** in spec; use generic user-facing messages.

---

## 9. External Integrations & Events

- **Reporting Copilot:** POST `/api/reporting-copilot` (AI agent). Invoked from `/ai-agents`; not from report page. Consumes Data Readiness and Boundary outputs when passed. No webhooks or events from report module to agent.
- **Data Library:** Report reads governance and targets from Data Library; "Manage in Data Library" links. No push from Data Library to report.
- **Emissions Engine:** Report consumes Scope 1/2/3 output when wired; read-only. No events.
- **Account Settings:** Report reads reporting boundary from account; "Edit in Account Settings" link.

---

## 10. Non-Functional Requirements

- **Performance:** Report page should load governance and targets in a single or few queries; avoid N+1. PDF export may take several seconds for large reports; show progress or spinner.
- **Data retention:** Report instance in localStorage is per-browser; no retention policy. If report_versions table is added, define retention (e.g. keep last 5 versions per report type per year).
- **Logging:** Consider logging report export and status changes in `audit_events` (entity_type e.g. `esg_report`, `report_export`) when moving to server-side persistence.
- **Security:** No report-specific rate limits in spec. Export and view subject to same RLS as underlying data.

---

## Routes (Lovable UI — confirmed)

**Sidebar label:** "Reports" (icon: Leaf), under `moduleId: "esg_reports"`. All routes are protected (auth required). ESG and SECR are part of the **Reports** section, so the hub should be at **`/reports`**; Back from report pages goes to `/reports`.

| Route | Component | Description |
|-------|-----------|-------------|
| **`/reports`** | `Reports` (hub page) | Report catalogue / landing page (canonical hub URL) |
| `/esg` | (optional) | Redirect to `/reports` or alias — hub may be implemented at `/esg`; prefer exposing as `/reports` |
| `/esg/corporate` | `ESGReportPage` | Sustainability & Energy Report (full report view) |
| `/esg/secr` | `SECRReportPage` | UK SECR Energy & Carbon Statement (preview mode) |
| `/esg/advisor` | `ReportingAdvisor` | AI-powered reporting recommendations page |

---

## Screens and flows

### Report hub (`/esg`)

Catalogue page listing available reports as cards in a 2-column grid.

**Primary reports (always visible):**
- **Sustainability & Energy Report** — status badge ("Ready"), "Open Report" → `/esg/corporate`, "Export PDF" button.
- **UK SECR Energy & Carbon Statement** — "Coming Soon" badge, "Open Report" → `/esg/secr`; Export PDF hidden.

**Advanced / optional reports (collapsed section):**
- **Landlord Engagement & Lease ESG Pack** — "Limited data available" warning, muted styling.

Each card shows: icon, title, description, audience, framework tags (e.g. TCFD, ISSB, UK SECR), last generated date, action buttons.

### Sustainability & Energy Report (`/esg/corporate`)

Full tabbed report view with 7 tabs:

| Tab | Content |
|-----|---------|
| **Executive Summary** | 4 KPI summary cards (Scope 1+2 tCO2e, Scope 3 tCO2e, Social/Occupancy %, Governance items count). Editable executive summary textarea. Target Progress Summary table (live `useTargetsData`). |
| **Organisational Boundary** | Company name, reporting year, period, boundary approach, methodology, entities included, exclusions. From `AccountContext.currentAccount.reportingBoundary`. Link to Account Settings to edit. |
| **Energy & Carbon** | Scope 1 (Direct) and Scope 2 (Indirect) tables: metric name, value, target, trend, DataSourceBadge. **Currently mock** `environmental` array — to be wired to real data. |
| **Scope 3** | Workforce dataset banner. Table of Scope 3 emissions (business travel, commuting) with methodology and data source. **Currently mock.** |
| **Waste & Water** | Table of waste and water metrics (value, target, trend, data source). **Currently mock.** |
| **Governance & Data Quality** | **Live** governance from `useGovernanceData()` (Supabase). Auto-generated "Data Scope & Limitations" narrative. Evidence panel and Audit Trail panel. |
| **Targets** | **Live** targets from `useTargetsData()` (Supabase). Table with category, target description, baseline/target, status. Editable "Forward Actions" textarea. |

**Header actions:** "Request Review", "Print", "Export PDF"; audit status badge (Draft / Requested / In Review / Approved); "Voluntary" tag.  
**Banners:** Role indicator; data change warning (when source data fingerprint differs from approved) with "Re-open as Draft" button.

### UK SECR Report (`/esg/secr`) — preview mode

Tabbed report with 6 tabs: Overview, Energy Consumption, Emissions, Intensity Ratios, Narrative Sections, Audit & Evidence.

- "Coming Soon" and "Preview Mode" badges; orange disclaimer: "Sample Preview — Not for Regulatory Submission".
- Print and Export PDF **disabled** (tooltip: future release).
- All data mock/hardcoded (`mockSECRReport`). ValidationAssumptions component for headcount, floor area, operating hours, occupancy rate.

### Reporting Advisor (`/esg/advisor`)

AI-powered recommendation/assessment page (does not generate reports).

- Grid of 9 report/certification recommendations (SECR, GRESB, CSRD, BREEAM In-Use, EU Taxonomy, TCFD, EPC, NABERS UK, ISO 50001).
- Each card: name, mandatory/recommended/optional badge, status (Covered/Gap/Upcoming/Not Applicable), data readiness %, gaps, deadline.
- Filter tabs: All, Covered, Gap, Upcoming, Not Applicable. Context banner (geography, role, asset types). **Currently hardcoded.**

---

## Data sources

### Backend (canonical — what the report should read)

All queries scoped by `account_id`. Report scope is account-level and reporting boundary (no property selector on report pages).

| Data | Source | Use in report |
|------|--------|----------------|
| Governance items | `data_library_records` WHERE subject_category = 'governance' | Governance & Data Quality tab |
| Targets & commitments | `data_library_records` WHERE subject_category = 'targets' | Executive Summary, Targets tab |
| Evidence attachments | `evidence_attachments` + `documents` (via data library evidence) | Evidence panel |
| Organisational boundary | `accounts.reportingBoundary` (or equivalent account-level config) | Organisational Boundary tab |
| Activity (energy, water, waste) | `data_library_records` (energy, water, waste) | Energy & Carbon, Waste & Water tabs — **to be wired** |
| Emissions (Scope 1/2/3) | Emissions Engine output | Energy & Carbon, Scope 3 — **to be wired** |
| Property context | `properties` (when property-scoped data is added) | Optional future scope |

### Live data (Lovable — currently wired)

| Data | Hook | Source |
|------|------|--------|
| Governance items | `useGovernanceData()` | `data_library_records` WHERE subject_category = 'governance' |
| Targets & commitments | `useTargetsData()` | `data_library_records` WHERE subject_category = 'targets' |
| Evidence attachments | `useDataLibraryEvidence()` | Data library evidence metadata |
| Organisational boundary | `useAccount()` → `currentAccount.reportingBoundary` | `accounts` table (reporting boundary JSON) |
| Report instance (status, narratives, audit trail) | `useReportInstance()` | **localStorage** (keyed by `report_instances_{type}_{year}`) — not Supabase |

### Mock / not yet connected (Lovable)

| Data | Location |
|------|----------|
| Environmental metrics (energy, carbon, water, waste) | `mockESGReport.environmental` in ESGReport |
| Scope 3 metrics (travel, commuting) | `mockESGReport.scope3` |
| Social metrics (occupancy, wellbeing) | `mockESGReport.social` |
| Executive summary, forward actions, data scope narratives | Defaults in `mockESGReport`; overridden by localStorage via `useReportInstance` |
| Entire SECR report | `mockSECRReport` in SECRReport |
| SECR assumptions | `mockAssumptions` in SECRReport |
| Reporting Advisor recommendations | Hardcoded `reportRecommendations` in ReportingAdvisor |
| Report hub card metadata | Hardcoded `primaryReports`, `optionalReports` in Reports hub |

---

## Frameworks and report content

| Framework | Typical content from platform |
|-----------|------------------------------|
| **SECR** | Energy consumption, emissions (Scope 1/2), intensity metrics, narrative; from Data Library + Emissions Engine (SECR page currently mock). |
| **GRESB** | Energy, GHG, water, waste; governance; targets; evidence coverage. Reporting Advisor lists GRESB. |
| **TCFD** | Governance, strategy, risk; emissions; Reporting Advisor lists TCFD. |
| **CDP** | Emissions, energy, water, targets; evidence-backed. |
| **SFDR (PAI)** | Carbon, energy, environmental indicators. |
| **EED Article 12 (DC)** | DC-specific; see [dc-dashboard-specifications.md](dc-dashboard-specifications.md). |

Report sections should map platform data to each framework’s required fields. Where a field does not exist in the schema, use a placeholder and a code comment (e.g. `// MISSING_SCHEMA: GRESB field XYZ`).

---

## Reporting Copilot integration

- **Endpoint:** POST `/api/reporting-copilot` (AI agent; see [AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](../AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md)).
- **Invocation:** From the **AI Agents** dashboard (`/ai-agents`) via `useSustainabilityReportingAgent` hook — **not** from the report page (`/esg/corporate`). The generated report payload is displayed in the AI Agents dashboard.
- **Payload:** Property context, reporting year, optionally `dataReadinessOutput` and `boundaryOutput`. When the user has run Data Readiness and/or Boundary for the same context, the app must pass these so the report shows linked agent context.
- **Persistence:** Report instance status (Draft → Requested → In Review → Approved) and narratives are stored in **localStorage** via `useReportInstance`. Consider persisting to Supabase (e.g. `agent_runs` or a dedicated report_versions table) for production.

---

## Export (Lovable UI — confirmed)

| Report | Export available | Format | Notes |
|--------|-------------------|--------|-------|
| Sustainability & Energy Report | Yes | PDF | "Export PDF" in header; `useExport` / `pdfGenerator`. Print available. |
| UK SECR | No | — | Print and Export PDF **disabled**; tooltip: "SECR export will be enabled in a future release." |
| Landlord Engagement Pack | Yes (from hub) | PDF | "Export PDF" on hub card; `generateLandlordReport` from `pdfGenerator`. |
| Reporting Advisor | No | — | Advisory only. |

No Excel, CSV, or GRESB-format export on report pages. Export dialog (PDF/CSV/XLSX) is used on dashboards, not reports.

---

## Filters and scope (Lovable UI — confirmed)

**There are no property or date range selectors on the report pages.** Scope is determined by:

- **Account:** All queries scoped to current account via `useAccount()`.
- **Reporting year:** From `currentAccount.reportingBoundary.reportingYear` (corporate) or hardcoded in mock (SECR).
- **Boundary approach:** Configured in Account Settings → Organisation tab.

Reporting Advisor uses hardcoded user context (geography, role, asset types).

---

## Connections to other features

| Connection | Direction | Detail |
|------------|-----------|--------|
| **Data Library → Reports** | Governance and Targets tabs pull live data. "Manage in Data Library" links on Governance, Targets, Evidence. |
| **Account Settings → Reports** | Organisational Boundary tab reads account-level reporting boundary. "Edit in Account Settings" link. |
| **AI Agents → Reports** | Sustainability Reporting Agent (`/ai-agents`) generates full report via POST `/api/reporting-copilot`. Generated report shown in AI Agents dashboard, not in `/esg/corporate`. Consumes Data Readiness and Boundary outputs when passed. |
| **Report hub → Reporting Advisor** | Advisor has back button to `/esg`; add link from hub to `/esg/advisor` (implementation note). |
| **Dashboards** | No direct connection; dashboards have separate export flows. |

---

## Implementation notes / gaps (from Lovable)

- **Add Reporting Advisor link to ESG hub** — So users can navigate from `/esg` to `/esg/advisor`.
- **Wire Energy & Carbon tab to real data** — Replace `mockESGReport.environmental` with `data_library_records` and Emissions Engine output.
- **Wire Scope 3, Waste & Water** — Replace mock with `data_library_records` and Emissions Engine where applicable.
- **Add filters to ESG report page** — If property- or period-level scope is required (e.g. for portfolio reports), add property/date selectors and scope backend queries accordingly.
- **Persist report instance to Supabase** — Replace or supplement localStorage with a report_versions or report_instances table for audit and multi-device use.

---

## Access control and audit

- Report view and export respect account access; use existing RLS and app-level checks.
- Report instance status workflow (Draft → Requested → In Review → Approved) is tracked via `useReportInstance` (localStorage). Data change detection uses a fingerprint of governance + targets record IDs and timestamps; when fingerprint changes after approval, show "Re-open as Draft" banner.
- Consider logging report generation and export in `audit_events` (entity_type e.g. `esg_report` or `report_export`) for traceability when moving to server-side persistence.

---

## References

- [data-library-specifications.md](data-library-specifications.md) — Data Library structure; ESG Disclosures tile; subject categories.
- [dc-dashboard-specifications.md](dc-dashboard-specifications.md) — ESG & Reporting Readiness dashboard (DC); GRESB DC module, EED Article 12.
- [DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md](../DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md) — Records vs proofs; data flow to dashboards.
- [AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](../AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md) — Reporting Copilot; passing prior agent outputs.
- [APP-ROUTE-MAP.md](../APP-ROUTE-MAP.md) — App routes; Reports under `/esg`.
- [database/schema.md](../database/schema.md) — data_library_records, properties, accounts, dc_metadata, audit_events.

---

## Prompt to paste into Lovable (for future updates)

Use this to ask Lovable for an updated description of the ESG Report feature; then integrate the reply into this spec.

```
Please describe the ESG Report / Sustainability Reporting feature in this app in full detail so we can document it for the engineering team. Include: (1) Where it appears and exact route path(s). (2) What screens or flows exist and main UI elements. (3) What data is shown in each section and whether it is live or mock. (4) How the user generates or refreshes the report and any AI/Reporting Copilot usage. (5) Export options and formats. (6) Filters and scope (property, period). (7) Connections to Data Library, Account Settings, AI Agents, dashboards. Reply in a clear, structured way (numbered or with headings) so we can use it as the canonical spec.
```

---

*Secure SoR — ESG Report — v1.0 — February 2026*

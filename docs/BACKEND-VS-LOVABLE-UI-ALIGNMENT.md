# Backend vs Lovable UI — alignment and gaps

**Source:** Lovable repo at `[Apex TIGRE]/1_Secure/Repositories/Lovable` (App.tsx and key pages). Backend specs: APP-ROUTE-MAP, specs (ESG, Data Library, DC dashboards), AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.  
**Purpose:** Single place to see (1) whether the backend is up to date with the UI in Lovable, and (2) what functionality is not built yet. Update this doc when Lovable or backend specs change.

---

## 1. Is the backend up to date with the UI?

### Routes — aligned

Lovable’s router matches the backend route map for the areas we spec:

| Area | Backend spec | Lovable (App.tsx) | Status |
|------|--------------|-------------------|--------|
| **Entry / auth** | `/` Landing, redirect to dashboard when logged in | `/` → LandingPage; `/signin`, `/signup`; `/dashboard` → Index | **Minor:** Backend doc says `/login`; Lovable uses `/signin`. Update backend APP-ROUTE-MAP to note actual path is `/signin` if that is canonical. |
| **Dashboard** | `/dashboard` (or `/app`) | `/dashboard` → Index | ✅ |
| **Data Library** | `/data-library`, `/data-library/energy`, water, waste, certificates, esg, scope-data, governance, targets, indirect-activities, occupant-feedback | All present; same paths | ✅ |
| **ESG Report** | `/esg`, `/esg/corporate`, `/esg/secr`, `/esg/advisor` | All present; same paths | ✅ |
| **DC dashboards** | `/dashboards/data-centre`, portfolio, `:propertyId`, pue, capacity, cooling, esg, geopolitical, climate-hazard, cyber-infrastructure | All 9 routes present | ✅ |
| **Office dashboards** | `/dashboards`, carbon, energy, responsibility, people | All present | ✅ |
| **Properties** | `/properties`, `/properties/:id`, `:id/stakeholders` | Present | ✅ |
| **AI Agents** | `/ai-agents` | `/ai-agents` → AIAgentsDashboard | ✅ |

**Conclusion:** Backend route documentation is **up to date** with Lovable for Data Library, ESG Report, DC dashboards, and main app structure. Only nuance: auth path is `/signin` in Lovable, not `/login` — document in APP-ROUTE-MAP if you want backend to reflect that.

---

### Dashboards module — filter bar

- **Backend:** Spec calls for a filter bar (Asset Type → Property) at the top of the Dashboards module; when Data Centre is selected, show DC landing and use asset type/property in the flow.
- **Lovable:** `DashboardsIndex` uses `AssetTypeFilterBar` and `useDashboardAssetFilter()`; when `selectedAssetType === "data_centre"` it redirects to `/dashboards/data-centre` with query params. So the **filter bar and DC redirect are built**.

---

### DC dashboards — data source

- **Lovable:** DC pages (PUE, Capacity, Cooling, ESG, Geopolitical, Climate, Cyber) use **Supabase** (`supabase.from("properties")`, `supabase.from("dc_metadata")`) for property name and DC metadata. No mock data in those components for core fields.
- **Backend:** Spec says DC dashboards read from `data_library_records`, `dc_metadata`, `properties`. Lovable is aligned for `properties` and `dc_metadata`; **data_library_records** (e.g. energy YTD, PUE from records) may still be partial or placeholder in some DC views — confirm per dashboard if energy/carbon numbers come from `data_library_records` or only from `dc_metadata`.

---

### ESG Report — data

- **Backend (esg-report-specifications):** Governance and Targets tabs use **live** data (Supabase); Energy & Carbon, Scope 3, Waste & Water are **mock**; report instance in **localStorage**; SECR page fully mock.
- **Lovable:** Matches that: governance/targets from hooks; environmental/scope3/waste-water from `mockESGReport`; `useReportInstance` → localStorage. So backend spec is **up to date** with what’s implemented.

---

### Data Library — upload and records

- **Backend:** One shared upload component (record → Storage → documents → evidence_attachments); same flow for all “Add Data” entry points.
- **Lovable:** Evidence upload (Storage + documents + evidence_attachments) is implemented; whether **every** Data Library tile (Energy, Water, Waste, etc.) uses the **same** shared component or still has stubs is not verified here. Audit doc states: “Evidence upload wired; Energy/others may be stubs or different flows.” So backend spec is the **target**; full alignment (single shared upload everywhere) may not be done yet — see “Functionality not built yet” below.

---

## 2. What functionality is not built yet

Below is a single list of **not built / not fully built** items, from backend specs and the audit. “Not built” means either missing in Lovable or only partially implemented (e.g. mock instead of real data, or stub instead of shared flow).

### ESG Report (see [specs/esg-report-specifications.md](specs/esg-report-specifications.md))

| Item | Status |
|------|--------|
| Wire **Energy & Carbon** tab to real data (`data_library_records` + Emissions Engine) | Not built — still mock |
| Wire **Scope 3** and **Waste & Water** tabs to real data | Not built — still mock |
| **Persist report instance** to Supabase (report_versions / report_instances table) instead of or in addition to localStorage | Not built |
| **Add filters** to ESG report page (property, date range) if needed for portfolio reports | Not built — scope is account + reporting boundary only today |
| **Add link from ESG hub to Reporting Advisor** (`/esg` → `/esg/advisor`) | Verify in Lovable; spec said “add link” |

### Data Library (see [specs/data-library-specifications.md](specs/data-library-specifications.md), [DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md](DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md))

| Item | Status |
|------|--------|
| **Single shared upload component** used by every “Add Data” / “Upload Documents” / Manual Entry entry point (Energy, Water, Waste, Certificates, Governance, etc.) | Unclear — Evidence upload wired; other entry points may still be stubs or different flows |
| **“Extract from CSV” → create records + attach evidence** as one shared flow used everywhere it’s needed | Not confirmed — may be partial or missing in some tiles |
| **Human validation of proofs** (reviewer marks evidence as validated/rejected, status, audit trail) | Not built — future feature |

### DC / Spaces (see [AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md))

| Item | Status |
|------|--------|
| **Spaces save → summary tiles update** for Data Centre (same behaviour as Office: refetch spaces after mutation, tiles update) | Known gap — DC tiles don’t update; single spaces data flow for all asset types not confirmed |
| **Spaces list** for Data Centre: render full list (not only count), refetch after template/delete | Known gap |
| **Whole/partial selector** and template button behaviour (save before template, etc.) per LOVABLE prompts | Verify in Lovable against backend prompts |
| **DC dashboards** reading energy/carbon from `data_library_records` (not only `dc_metadata`) where spec says so | Partially built — DC pages use `dc_metadata` and `properties`; confirm if energy YTD etc. come from `data_library_records` in each view |

### AI Agents and reporting (see [AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md))

| Item | Status |
|------|--------|
| **Data Readiness Run** — app must send **POST** with context to agent (not only OPTIONS) | Known risk — fix doc exists; verify in Lovable |
| **Persist agent_runs and agent_findings** after each agent call | Not built — tables exist; app may not insert |
| **Reporting Copilot:** pass **dataReadinessOutput** and **boundaryOutput** when user already ran those agents for same property | Not confirmed — required for “linked” report summary |
| **Property change → clear agent results** on AI agents page | Not confirmed |
| **Run-all** (POST /api/run-all + “Run all” button) | Optional; not built |

### Meters infrastructure (see [METERS-INFRASTRUCTURE.md](METERS-INFRASTRUCTURE.md))

| Item | Status |
|------|--------|
| **Backend:** `meters` table exists (property_id, system_id, name, meter_type, unit, external_id); RLS and indexes in place. **Systems** have `metering_status` (none/partial/full) and `key_specs` (e.g. meter IDs). | ✅ Schema and migrations in backend |
| **Lovable:** Property Detail has a **Meters** tab under Physical & Technical; content is a **placeholder** only (“Metering data is displayed within Building Systems above”). No CRUD or list from `meters` table. | **Not built** — no UI that reads/writes the `meters` table |
| **Building Systems** in Lovable shows systems (with metering_status); no dedicated “Meters” list or link from system → meter(s). | Meters table is **unused** in the app today |

### Other

| Item | Status |
|------|--------|
| **Building systems register import** via RPC `insert_system_from_register` (not direct insert) to avoid invalid UUIDs | Migration exists; Lovable may still use direct insert — verify |
| **Back button** on ESG and SECR report pages → **`/reports`** (Reports hub; ESG/SECR are part of Reports) | Ensure hub at `/reports` and Back → `/reports`. Use [LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md](LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md). Do not push local Cursor edits. |
| **Auth route naming:** backend doc says `/login`; Lovable uses `/signin` | Update backend to “/signin” if that is canonical |

---

## 3. Summary

- **Backend is up to date with the UI** for: route structure (Data Library, ESG Report, DC dashboards, dashboards filter, auth/dashboard), and for what’s documented as “live” vs “mock” in the ESG report. Only small doc tweak: auth path `/signin` vs `/login`.
- **Functionality not built or not fully built:** (1) ESG: Energy & Carbon, Scope 3, Waste & Water to real data; report instance persistence; optional filters. (2) Data Library: one shared upload and one shared “extract from CSV” flow everywhere; human proof validation (future). (3) DC/Spaces: single spaces data flow so DC tiles and list update like Office; full list render and refetch. (4) AI Agents: POST for Data Readiness; persist agent_runs/agent_findings; pass prior outputs to Reporting Copilot; optional run-all.

Use this doc and [LOVABLE-BACKEND-ALIGNMENT.md](LOVABLE-BACKEND-ALIGNMENT.md) (for code-level alignment) together when prioritising what to build next in Lovable or what to document in the backend.

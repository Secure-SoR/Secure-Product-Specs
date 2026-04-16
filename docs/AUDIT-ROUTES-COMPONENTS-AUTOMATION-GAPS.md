# Audit: Backend routes, AI agent routes, and frontend — consistency and automation gaps

**Scope:** Secure SoR platform (backend = Supabase + docs; AI Agents = agent API; frontend = Lovable app, inferred from docs).  
**Date:** From workspace analysis.  
**Note:** Frontend code is not in this workspace; component and automation gaps are inferred from backend/agent docs and known issues (e.g. LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC, data-library-implementation-context).

**Strategy reference:** [docs/sources/Secure_platform-strategy-building-data-infrastructure.md](sources/Secure_platform-strategy-building-data-infrastructure.md) defines the platform model (primitives, modules, horizons). §7 below maps that strategy to current state and to-dos.

---

## 1. Route alignment audit

### 1.1 Backend “routes” (Supabase data surface)

The backend repo has **no REST API**; the platform uses **Supabase** (Postgres + RLS + Storage). Data access is via:

| Backend data surface | Type | Purpose |
|----------------------|------|---------|
| `profiles` | Table | User profile (Auth extension) |
| `accounts` | Table | Tenant; no client INSERT — via Edge Function |
| `account_memberships` | Table | User ↔ account; no client INSERT — via Edge Function |
| `properties` | Table | CRUD by app |
| `spaces` | Table | CRUD by app |
| `systems` | Table | CRUD; optional RPC for register import |
| `meters` | Table | CRUD |
| `end_use_nodes` | Table | CRUD |
| `data_library_records` | Table | CRUD |
| `documents` | Table | Insert on upload; Storage bucket `secure-documents` |
| `evidence_attachments` | Table | Link record ↔ document |
| `agent_runs` | Table | Insert/update by app when persisting runs |
| `agent_findings` | Table | Insert when persisting findings |
| `audit_events` | Table | Append-only audit |
| `check_account_name_exists(name)` | RPC | Onboarding name uniqueness |
| `insert_system_from_register(payload)` | RPC | Building systems register import (optional migration) |
| `create-account` | Edge Function | Account + membership creation (Lovable project) |

### 1.2 AI agent routes (from agent/src/server.ts)

| Route | Method | Backend counterpart | Status |
|-------|--------|---------------------|--------|
| `/` | GET | — | OK (discovery) |
| `/health` | GET | — | OK (health) |
| `/api/data-readiness` | POST | Supabase: properties, spaces, systems, nodes, data_library_records, evidence | **Aligned** — app builds context from Supabase, POSTs here |
| `/api/boundary` | POST | Same Supabase data | **Aligned** |
| `/api/action-prioritisation` | POST | Same Supabase data | **Aligned** |
| `/api/reporting-copilot` | POST | Same + optional prior agent outputs | **Aligned** |
| OPTIONS for each POST | OPTIONS | — | OK (CORS) |
| `/api/run-all` | POST | — | **Missing** — recommended optional batch endpoint; not implemented |

### 1.3 Route mismatches and unwired

| Route / capability | Backend | Agent | Status |
|-------------------|---------|-------|--------|
| Agent context build | Supabase tables + (optional) RPC `get_property_records_with_evidence` | Expects single JSON body | **Gap:** RPC not in schema; app does 2+ fetches (records + evidence). Optional RPC would align one-call context. |
| Persist agent runs | `agent_runs`, `agent_findings` tables exist | Agent does not write to DB | **Unwired:** Tables exist; app may not persist runs/findings after agent call. Doc says “optional: persist agent_runs”. |
| Data Readiness POST | — | POST /api/data-readiness | **Doc bug:** Lovable fix doc says “only OPTIONS sent, no POST” — UI must send POST; no backend route for this (agent is external). |
| Run-all (batch) | — | No endpoint | **Missing:** Optional; would reduce round-trips if implemented. |

**Summary (routes):** Agent and backend are aligned for the four agent endpoints (context comes from Supabase; agent does not touch DB). Gaps: optional RPC for context not in schema; optional run-all endpoint not implemented; agent_runs/agent_findings persistence possibly unwired in app.

---

## 2. Component inconsistency audit

*(Inferred from docs and known issues; Lovable code not in workspace.)*

### 2.1 Upload files and extract from CSV (Data Library / Energy)

| Feature | Locations affected | Current state | Expected unified behaviour |
|---------|--------------------|---------------|----------------------------|
| **Upload files & extract from CSV** (energy / data library) | Data Library: Evidence panel (record-first upload); Energy: “Upload / Create Data Request” (stubs); possibly other “Add Data” entry points (Upload Documents, Manual Entry) | Spec: Evidence upload is Supabase Storage + documents + evidence_attachments; Energy upload/create = stubs. Multiple entry points may use different upload or “extract from CSV” flows. | **Single shared component:** One “Upload file” flow: (1) file picker (PDF, Excel, CSV, images; max 10MB), (2) tag (invoice, contract, etc.), (3) optional description, (4) upload to Storage, insert documents + evidence_attachments when linked to a record; and one “Extract from CSV” flow that creates/updates data_library_records from CSV and optionally links one document as evidence. Every button that “uploads and extracts” (Energy components, Data Library categories) should use the same component/hook so behaviour and backend calls are identical. |

### 2.2 Spaces summary tiles (Office vs Data Centre)

| Feature | Locations affected | Current state | Expected unified behaviour |
|---------|--------------------|---------------|----------------------------|
| **Spaces summary tiles** (e.g. count, list, or tiles that reflect spaces) | Property → Spaces: summary/count tiles; Office property vs Data Centre property | **Known issue:** Saving spaces in an **Office** property updates the summary tiles; the same action in a **Data Centre** property does not update the tiles (or list does not render). Docs (LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC) describe: spaces list not rendering (only count), refetch after template, whole/partial selector. | **Unified behaviour:** One source of truth: `supabase.from('spaces').select('*').eq('property_id', propertyId)`. One shared component or hook for “spaces for current property”: fetch, store in state, derive tenant vs base_building. **All property types** (Office, Data Centre, Retail, etc.) must use the same logic: after create/update/delete/template, refetch spaces and set state so the same summary tiles and list update regardless of asset_type. No branching by asset_type for “do we refetch / do we update tiles”. |

### 2.3 Spaces list and tenant/landlord sections

| Feature | Locations affected | Current state | Expected unified behaviour |
|---------|--------------------|---------------|----------------------------|
| **Spaces list (tenant vs landlord sections)** | Spaces screen for any property | Doc (LOVABLE-PROMPT-RESTORE-SPACES-UI-TENANT-AND-LANDLORD): After DC template fix, “My Landlord / Base Building Spaces” was removed or hidden; must show both sections for all asset types. | **Unified:** One layout: “My Tenant Spaces” (space_class === 'tenant') and “My Landlord / Base Building Spaces” (space_class === 'base_building') for **every** property. Same component or filter logic; no asset_type-based hide of base_building section. |

### 2.4 Whole/partial and template button (Data Centre)

| Feature | Locations affected | Current state | Expected unified behaviour |
|---------|--------------------|---------------|----------------------------|
| **Whole building / Partial building selector** | Spaces subpage (Data Centre flow) | LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC: Add selector + Save for occupancy_scope; template button only after save. Prevents template running without whole/partial. | Keep DC-specific **only** for “when to show template button” and “when to show DC space types”. The **save** and **refetch** behaviour (update property, refetch spaces, update tiles) should use the same persistence and state flow as any other property so tiles/list stay in sync. |

---

## 3. Automation gaps

*(Prioritised: broken behaviour first, missing automation second, cosmetic third.)*

### 3.1 Broken or unreliable behaviour (high)

| Action | Location | Gap description | Suggested fix |
|--------|----------|------------------|----------------|
| **Spaces save → summary tiles update** | Property (Data Centre) → Spaces | Saving or adding spaces for a Data Centre property does not update the summary tiles (whereas Office does). Indicates different state/refetch path by asset_type. | Use a single spaces data flow for all properties: after any spaces mutation (create, update, delete, template), refetch `spaces` for current propertyId and update the same state that feeds both the list and the summary tiles. Remove any branch that skips refetch or uses different state for Data Centre. Apply LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC if not already applied. |
| **Data Readiness Run → no POST** | AI agents tile (Lovable) | Doc (lovable-fix-data-readiness-post): App sometimes sends only OPTIONS to the agent; no POST with context, so agent never runs. | Ensure the Run Data Readiness handler builds context, then sends **POST** to `${VITE_AGENT_API_URL}/api/data-readiness` with body = context JSON. Do not rely on preflight only. |
| **Spaces list not rendering (only count)** | Spaces screen (Data Centre) | User sees e.g. “12 spaces” but list of spaces does not render; delete not possible. | Render every space from the same fetch: filter by space_class for tenant vs base_building, map to rows/cards with Delete. Refetch after template and after delete. Same as LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC §3–4. |

### 3.2 Missing or partial automation (medium)

| Action | Location | Gap description | Suggested fix |
|--------|----------|------------------|----------------|
| **Persist agent runs and findings** | After Run Data Readiness / Boundary / etc. | Backend has `agent_runs` and `agent_findings`; agent does not write to DB. App may not persist run metadata or findings after agent response. | After each successful agent response: insert `agent_runs` (account_id, property_id, agent_type, status, context_snapshot optional); insert `agent_findings` with payload. Use for history and audit. |
| **Upload + create record + attach evidence** | Data Library “Add Data” / Energy upload | Spec: “Add Data” actions “some may still be stubs”. Upload to Storage + documents + evidence_attachments is implemented; “create record from upload/CSV” may not be wired everywhere. | Wire every “Upload Documents” / “Add Data” entry that should create records: use shared flow (create data_library_record → upload file → insert documents → insert evidence_attachments). Same for “extract from CSV” where applicable (one shared extract + create-records flow). |
| **Building systems register import** | Systems / register upload | If app uses direct `.from('systems').insert()` with spreadsheet data, invalid UUIDs (e.g. “1”) can cause errors. | Run migration add-insert-system-from-register-rpc.sql; use `supabase.rpc('insert_system_from_register', { payload })` for each row so backend sanitizes and validates. |
| **Report: pass prior agent outputs** | Sustainability Reporting tile | If Reporting Copilot is called without dataReadinessOutput and boundaryOutput when user already ran those agents, report summary cannot show “linked” agents. | When user has run Data Readiness and/or Boundary for the **same** property, pass their full response objects in the request body to POST /api/reporting-copilot so payload.report.previous_agents_summary is populated. |

### 3.3 Cosmetic / consistency (lower)

| Action | Location | Gap description | Suggested fix |
|--------|----------|------------------|----------------|
| **Property change → clear agent results** | AI agents page | If property dropdown change does not clear stored agent results, user may see previous property’s result. | On property change: clear all stored agent results (and report) so user must Run again for the new property. |
| **Run-all agents** | AI agents page | No single “Run all” endpoint; user runs each agent separately. | Optional: add POST /api/run-all and “Run all” button that sends one request and displays all tiles from one response; reduces round-trips. |

---

## 4. Summary tables (requested format)

### 4.1 Route mismatches

| Route | Backend | Agent | Status |
|-------|---------|-------|--------|
| POST /api/data-readiness | Context from Supabase (app builds) | Implemented | Aligned |
| POST /api/boundary | Context from Supabase | Implemented | Aligned |
| POST /api/action-prioritisation | Context from Supabase | Implemented | Aligned |
| POST /api/reporting-copilot | Context + optional prior outputs | Implemented | Aligned |
| GET /health | — | Implemented | OK |
| create-account | Edge Function (Lovable) | — | Backend surface; no agent |
| check_account_name_exists | RPC in schema | — | Backend only |
| insert_system_from_register | RPC (migration) | — | Backend only; app should use for register import |
| get_property_records_with_evidence | Not in schema (recommended) | — | Missing; would align one-call context |
| POST /api/run-all | — | Not implemented | Missing (optional) |
| agent_runs / agent_findings | Tables exist | Agent does not write | Persistence unwired if app does not insert |

### 4.2 Component inconsistencies

| Feature | Locations affected | Current state | Expected unified behaviour |
|---------|--------------------|---------------|----------------------------|
| Upload files & extract from CSV | Data Library (Evidence, Energy, other “Add Data” buttons) | Evidence upload wired; Energy/others may be stubs or different flows | One shared upload component and one shared “extract from CSV → create records + evidence” flow; same for every entry point |
| Spaces summary tiles | Property → Spaces (Office vs Data Centre) | Office: tiles update on save; Data Centre: tiles do not update | Single data flow: one fetch for spaces by propertyId; after any mutation, refetch and set same state for all asset types so tiles and list update |
| Spaces list (tenant / landlord) | Spaces screen | Risk of different layout or missing base_building section by property type | One layout: tenant section + landlord section for all properties; same filter (space_class) |
| Whole/partial + template | Data Centre spaces | Selector + Save + template; refetch after template | Same refetch/state update as other property flows so tiles stay in sync |

### 4.3 Automation gaps (prioritised)

| Priority | Action | Location | Gap description | Suggested fix |
|----------|--------|----------|------------------|----------------|
| **1 – Broken** | Save spaces | Data Centre property → Spaces | Summary tiles do not update | Single spaces state/refetch for all asset types; refetch after any mutation |
| **1 – Broken** | Run Data Readiness | AI agents tile | Only OPTIONS sent, no POST | Implement POST with context in click handler |
| **1 – Broken** | View/delete spaces | Data Centre → Spaces | List not rendering, only count | Render all spaces from fetch; refetch after template/delete |
| **2 – Missing** | Persist agent runs | After Run agent | agent_runs/agent_findings may not be written | Insert run + findings after each successful agent response |
| **2 – Missing** | Add Data / Upload | Data Library, Energy | Some stubs; extract from CSV may differ by entry point | Shared “create record + upload + attach” and “CSV extract” components |
| **2 – Missing** | Systems register import | Building systems upload | Invalid UUIDs can break insert | Use insert_system_from_register RPC |
| **2 – Missing** | Report linked agents | Reporting tile | Prior agent outputs not passed | Pass dataReadinessOutput, boundaryOutput when available for same property |
| **3 – Cosmetic** | Property change | AI agents page | Stale result from previous property | Clear agent results on property change |
| **3 – Optional** | Run all agents | AI agents page | No batch endpoint | Optional: add /api/run-all and Run all button |

---

## 5. Next steps — backend actions and existing prompts

Use this to decide what to do from the backend repo. Frontend (Lovable) and agent changes are done via prompts or agent repo; backend-only = migrations/schema/docs.

| Gap (from §3–4) | Owner | Backend action | Existing prompt / doc (if any) |
|-----------------|--------|-----------------|---------------------------------|
| **Spaces save → tiles not updating (DC)** | Lovable | None | [LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md](lovable-prompts/LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md); [LOVABLE-PROMPT-RESTORE-SPACES-UI-TENANT-AND-LANDLORD.md](lovable-prompts/LOVABLE-PROMPT-RESTORE-SPACES-UI-TENANT-AND-LANDLORD.md) |
| **Data Readiness: only OPTIONS, no POST** | Lovable | None | [lovable-fix-data-readiness-post.md](lovable-prompts/lovable-fix-data-readiness-post.md) |
| **Spaces list not rendering (only count)** | Lovable | None | Same as first row; ensure one refetch/state for all asset types |
| **Persist agent_runs / agent_findings** | Lovable | Schema exists ([schema.md](database/schema.md) §agent_runs, §agent_findings). No migration needed. | Add to Lovable prompt: after each successful agent response, insert into agent_runs and agent_findings |
| **Upload + create record + attach (unified)** | Lovable | None | [data-library-implementation-context.md](data-library-implementation-context.md); wire all “Add Data” entry points to same flow |
| **Systems register import (invalid UUIDs)** | Backend + Lovable | Run migration if not done: [add-insert-system-from-register-rpc.sql](database/migrations/add-insert-system-from-register-rpc.sql) | Lovable: use `supabase.rpc('insert_system_from_register', { payload })` instead of direct insert |
| **Report: pass prior agent outputs** | Lovable | None | When calling Reporting Copilot, include dataReadinessOutput and boundaryOutput in body when available for same property |
| **Property change → clear agent results** | Lovable | None | On property dropdown change, clear stored agent results |
| **Run-all endpoint** | Agent repo | None (backend has no API) | Optional: implement POST /api/run-all in agent; add “Run all” button in Lovable |
| **get_property_records_with_evidence RPC** | Backend | Optional: add RPC to schema + migration for one-call context | Would reduce app to one fetch for agent context |

**Backend-only checklist:** (1) Ensure [add-insert-system-from-register-rpc.sql](database/migrations/add-insert-system-from-register-rpc.sql) is run in Supabase if systems register import is used. (2) No other new migrations required for the gaps above; agent_runs and agent_findings tables already exist.

---

## 6. References

- Backend schema: [docs/database/schema.md](database/schema.md), [docs/database/supabase-schema.sql](database/supabase-schema.sql)
- Implementation plan: [docs/implementation-plan-lovable-supabase-agent.md](implementation-plan-lovable-supabase-agent.md)
- Data Library: [docs/data-library-implementation-context.md](data-library-implementation-context.md), [docs/sources/lovable-data-library-spec.md](sources/lovable-data-library-spec.md)
- Spaces (DC): [LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md](lovable-prompts/LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md), [LOVABLE-PROMPT-DATA-CENTRE-SPACE-TEMPLATE.md](lovable-prompts/LOVABLE-PROMPT-DATA-CENTRE-SPACE-TEMPLATE.md), [LOVABLE-PROMPT-RESTORE-SPACES-UI-TENANT-AND-LANDLORD.md](lovable-prompts/LOVABLE-PROMPT-RESTORE-SPACES-UI-TENANT-AND-LANDLORD.md)
- Data Readiness POST fix: [lovable-prompts/lovable-fix-data-readiness-post.md](lovable-prompts/lovable-fix-data-readiness-post.md)
- **All Lovable prompts:** [lovable-prompts/README.md](lovable-prompts/README.md) (index by feature)
- ESG Report (Sustainability Reporting): [docs/specs/esg-report-specifications.md](specs/esg-report-specifications.md) — routes `/esg`, `/esg/corporate`, `/esg/secr`, `/esg/advisor`; Reporting Copilot invoked from `/ai-agents`.
- **Platform strategy:** [docs/sources/Secure_platform-strategy-building-data-infrastructure.md](sources/Secure_platform-strategy-building-data-infrastructure.md) — primitives, modules, horizons, GTM; use for alignment and roadmap.

---

## 7. Strategy alignment — where we are and what we need to build

**Source:** [docs/sources/Secure_platform-strategy-building-data-infrastructure.md](sources/Secure_platform-strategy-building-data-infrastructure.md). This section maps the strategy to current specs/schema and lists gaps and to-dos in one place.

### 7.1 Is the strategy file in the right place?

**Yes.** Strategy and positioning docs belong in **`docs/sources`**. They are reference/input material: they inform specs and roadmap but are not the canonical implementation spec. Canonical behaviour lives in `docs/specs/` and schema in `docs/database/`. See [docs/sources/README.md](sources/README.md) and [CURSOR-MEMORY-AND-WORKFLOW.md](CURSOR-MEMORY-AND-WORKFLOW.md) § Difference between docs/sources and docs/specs.

### 7.2 Platform primitives (strategy §1.1) vs current state

| Primitive | Strategy definition | Current state (schema + specs) | Gap / note |
|-----------|---------------------|--------------------------------|------------|
| **Property Graph** | Spaces, systems, meters, end-use nodes, IoT. Physical building as structured model. | `properties`, `spaces`, `systems`, `meters`, `end_use_nodes` in schema; DC template in [secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md); building-systems taxonomy, end-use nodes spec. | **Aligned.** IoT/sensors referenced; dedicated IoT table or SitDeck sync per DC spec. |
| **Stakeholder Registry** | Accounts, roles, boundary relationships. Who controls/pays/reports. | `accounts`, `account_memberships`; roles in app. Boundary logic in [landlord-tenant-boundary-logic.md](architecture/landlord-tenant-boundary-logic.md). | **Aligned.** Multi-stakeholder “data exchange” as product (invite landlord, FM) may be partial in UI. |
| **Evidence Store** | Documents with provenance, confidence, audit. | `documents`, `evidence_attachments`, Storage bucket; Data Library spec. | **Aligned.** Human proof validation (future) noted in Data Library spec. |
| **Activity Data** | Utility readings, consumption, waste. Structured by source, confidence, period. | `data_library_records`; Data Library spec (energy, waste, water, indirect, etc.). | **Aligned.** |
| **Boundary Engine** | Attribution: control, billing, metering → who owns what. | Logic in architecture docs; agent `/api/boundary`. No dedicated “boundary” table; uses Property Graph + Activity. | **Aligned.** Persist boundary output / pass to Reporting Copilot per §5. |
| **Coverage Engine** | Completeness: what exists, missing, estimated. Per property, per period. | Referenced in handover/agent docs; CoverageEngine logic not a single service in repo. | **Gap:** No single “Coverage Engine” spec or API; completeness implied in Data Library and agent context. Consider doc that frames Coverage as a primitive and maps to current logic. |
| **Emissions Engine** | Scope 1/2/3 from activity; deterministic, traceable. | Referenced in Data Library and ESG spec; sources/Secure_Emissions_Engine_*. Schema: emission tables optional. | **Gap:** Emissions Engine as a documented primitive (inputs, outputs, versioning) and any emission_calculation_runs / line_items schema to be explicit in schema.md if used. |
| **Audit Trail** | Append-only log of every data mutation. | `audit_events` table; RLS and triggers. | **Aligned.** Ensure agent runs and report exports write to audit_events where strategy requires (see §5). |

### 7.3 Strategy §6 “What This Means for the Repo” — alignment

| Strategy item | Current state | Gap / to-do |
|---------------|---------------|-------------|
| **1. Canonical spec frames data matrix primitives explicitly** | Schema and data-model docs exist; architecture has domain entities. Primitives (Property Graph, Stakeholder Registry, etc.) are not named as such in one canonical doc. | **To-do:** Add or update an architecture doc (or schema overview) that explicitly maps strategy primitives to schema and specs (one table: Primitive → tables/specs). |
| **2. Architecture docs describe platform layer vs module layer** | [architecture/architecture.md](architecture/architecture.md) describes current stack and domain; no explicit “platform (primitives) vs modules (applications)” split. | **To-do:** Add a short section “Platform vs modules” that lists primitives as platform and Compliance Tracker, Risk Diagnosis, Sustainability Reporting, Data Exchange, AI Agents as modules that consume them. |
| **3. API design — modules consume primitives via clean interfaces** | No REST API in repo; app uses Supabase client directly. Strategy says modules should consume via API. | **Gap (future):** When opening to third parties or multi-service, define API layer (e.g. REST or GraphQL) over primitives. Not required for current single-app setup; document as Horizon 2+ intent. |
| **4. Schema documentation as publishable artefact** | schema.md, supabase-schema.sql, taxonomy docs exist. | **To-do:** If “schema as product” is pursued, maintain a single publishable schema spec (versioned, e.g. Secure_Building_Data_Schema_v1.md in sources or a dedicated folder) and link from strategy. |
| **5. Module boundaries — what’s primitive vs module** | Specs are feature-focused (Data Library, ESG Report, DC). No single “module map” that says “Compliance Tracker consumes X, strengthens Y”. | **To-do:** Add a “Module map” table (module name → primitives consumed, primitives strengthened, spec doc) to architecture or to this audit doc, using strategy §1.2–1.3 and §8.3 as source. |

### 7.4 Platform modules vs current implementation

**Canonical module list (with status):** [docs/modules/MODULE-LIST.md](modules/MODULE-LIST.md). Summary below.

| Module | Strategy: requires / strengthens | Status | Current implementation | Gap / to-do |
|--------|----------------------------------|--------|-------------------------|------------|
| **Reports** | Emissions, Activity Data, Evidence, Boundary, Audit | **Partial** | ESG Report (hub, corporate, SECR, advisor). | Wire to real data; persist report instance; extend to full Reports (GRESB, etc.). |
| **Projects** | Property Graph, Activity Data, Emissions | **Pending** | — | Implement (ROI / Retrofit Scenarios). |
| **Net Zero** | Activity Data, Emissions, Evidence | **Pending** | — | Implement (decarbonisation pathway). |
| **Stakeholders Management** | Stakeholder Registry, Boundary Engine | **Pending** | Landlord/tenant boundary; invite/data exchange may be partial. | Confirm UI; build full Stakeholder Data Exchange. |
| **Asset Tracking** | Property Graph | **Pending** | Systems register, meters. | Implement as module (asset lifecycle). |
| **Digital Twin** | Property Graph, Activity Data | **Pending** | — | Implement. |
| **Automation** | All (cross-cutting) | **Pending** | — | Implement (workflows, triggers). |
| **AI Agents** | All primitives (read) → Coverage | **Built** | Data Readiness, Boundary, Action Prioritisation, Reporting Copilot. | Fix POST (§3.1); persist agent_runs/agent_findings (§3.2). |
| **Diagnosis** | All primitives → Property Graph | **Pending** | — | Implement (Risk Diagnosis). |
| **Risk & Finance** | All, risk/finance | **Pending** | — | Implement. |
| **Valuation Impact** | Risk Diagnosis, Compliance, Property Graph | **Pending** | — | Implement (or third-party). |


### 7.5 Combined to-do: implementation gaps + strategy-driven items

Use this as the single checklist for “where we are and what we need to build.” Items from §3–5 (implementation) and §7.2–7.4 (strategy) are merged; owner and doc references are in §5.

| # | To-do | Source | Owner | Priority |
|---|-------|--------|-------|----------|
| 1 | Spaces save → summary tiles update (DC); spaces list render; single refetch/state for all asset types | §3.1, §4.3 | Lovable | Broken |
| 2 | Data Readiness: send POST with context (not only OPTIONS) | §3.1 | Lovable | Broken |
| 3 | Persist agent_runs and agent_findings after each agent call | §3.2, strategy (Audit Trail) | Lovable | Missing |
| 4 | One shared upload + “extract from CSV” flow for all Data Library / Add Data entry points | §3.2, §4.2 | Lovable | Missing |
| 5 | Use insert_system_from_register RPC for building systems register import | §3.2 | Backend + Lovable | Missing |
| 6 | Pass dataReadinessOutput and boundaryOutput to Reporting Copilot when available | §3.2 | Lovable | Missing |
| 7 | Wire ESG Report Energy & Carbon, Scope 3, Waste & Water to real data; persist report instance to Supabase | §7.4, esg-report-spec | Lovable + Backend | Missing |
| 8 | Clear agent results on property change; optional Run-all endpoint | §3.3 | Lovable / Agent | Cosmetic / optional |
| 9 | **Strategy:** Doc that maps primitives (Property Graph, Stakeholder Registry, …) to schema and specs | §7.3 | Backend | Strategy |
| 10 | **Strategy:** Architecture “Platform vs modules” section (primitives vs Compliance Tracker, Risk, Reporting, etc.) | §7.3 | Backend | Strategy |
| 11 | **Strategy:** Module map table (module → primitives consumed, strengthened, spec) — see [docs/modules/MODULE-LIST.md](modules/MODULE-LIST.md) | §7.3 | Backend | Strategy |
| 12 | **Strategy:** Confirm or build Stakeholder Data Exchange (invite landlord, structured requests) | §7.4 | Product + Lovable | Strategy |
| 13 | **Strategy:** Coverage Engine and Emissions Engine as explicit primitives (doc + schema if needed) | §7.2 | Backend | Strategy |
| 14 | **Pending modules (roadmap):** Projects, Net Zero, Stakeholders Management, Asset Tracking, Digital Twin, Automation, Diagnosis, Risk & Finance, Valuation Impact — see [docs/modules/MODULE-LIST.md](modules/MODULE-LIST.md) | §7.4 | Product + Eng | Roadmap |

**Backend-only next steps:** (1) Run insert_system_from_register migration if not done. (2) Add or update architecture doc with primitives map and platform-vs-modules. (3) Module map and full module list with status are in [docs/modules/MODULE-LIST.md](modules/MODULE-LIST.md); reference from architecture if desired. (4) Optionally add publishable schema artefact and Coverage/Emissions primitive docs when prioritised.

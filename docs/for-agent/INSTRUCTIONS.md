# Handoff: Instructions for the AI agent (Data Readiness / Boundary)

Use this when you work in the **AI agent** project. The **backend repo** (Secure-SoR-backend) is the source of truth for context shape, DB columns, and how Lovable builds the context from Supabase.

---

## 1. What the agent should do

- **Apply to new property records:** The agent runs in the context of a **property** (and optionally account). When users create new properties in the app, those properties are stored in Supabase; the agent should receive context for **any** such property (not only a fixed demo). Lovable (or your orchestration) will fetch that property's data from the DB and build the context JSON.
- **Use context from the DB:** All context (property, spaces, systems, data library records, evidence, **utility applicability**, **service charge includes**) comes from **Supabase**. The agent does not need to read the DB directly; it receives a **single context JSON** in the request body. When the backend adds **property_utility_applicability** and **property_service_charge_includes** to the context (or the agent reads them via an API), use them to reason about water/heating completeness (see COVERAGE-AND-APPLICABILITY-FOR-AGENT.md). Ensure your input schema matches what the backend specifies (Phase 5 "Agent context shape" — see CONTEXT-SOURCE.md).
- **Stay in sync with backend:** When the backend adds or changes columns or context fields (e.g. new property fields, data library subject_category, coverage, utility applicability), re-read this handover folder and update the agent's expected input schema and logic if needed.

---

## 2. Files in this folder (read in order)

| Priority | File | Purpose |
|----------|------|--------|
| 1 | INSTRUCTIONS.md (this file) | What the agent should do and where to read next. |
| 2 | CONTEXT-SOURCE.md | Exact "Agent context shape" (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence, optional floorsInScope, etc.). |
| 3 | AGENT-TASKS.md | Concrete to-do: context input, API contract, data library, coverage and applicability. |
| 4 | BACKEND-SYNC-NOTES.md | Property/spaces/systems/Data Library columns; utility applicability and service charge includes tables. |
| 5 | COVERAGE-AND-APPLICABILITY-FOR-AGENT.md | How to reason about water/heating completeness using property_utility_applicability and property_service_charge_includes. |

**Optional (in backend repo):** docs/implementation-plan-lovable-supabase-agent.md (full Phase 5); docs/database/schema.md (table definitions); docs/sources/Secure_KPI_Coverage_Logic_Spec_v1.md (full KPI coverage spec).

---

## 3. How to use this folder

**Option A — Copy into agent repo:** Copy this entire folder into the agent repo (e.g. `agent/backend-instructions/` or `docs/backend-instructions/`). All references in these files point to other files **in this folder**, so the agent has a single self-contained instruction set.

**Option B — Path in agent repo:** In the agent project, add a short README that says: "Context shape and DB alignment: read from the **backend repo** at [path]/Secure-SoR-backend/docs/for-agent/. Start with README.md and INSTRUCTIONS.md; then CONTEXT-SOURCE.md and AGENT-TASKS.md."

**Option C — Cursor / AI instructions:** When you run the agent (or an AI in the agent repo), give it: "Use the files in [path]/for-agent/ for context and API contract. Read README.md first, then INSTRUCTIONS.md, CONTEXT-SOURCE.md, AGENT-TASKS.md, BACKEND-SYNC-NOTES.md, and COVERAGE-AND-APPLICABILITY-FOR-AGENT.md. Apply the agent to whatever property context is sent; context is built from Supabase. When reasoning about water/heating completeness, use the coverage-and-applicability doc."

---

## 4. Quick checklist for the agent

- [ ] Input schema matches Phase 5 "Agent context shape" (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence; optional floorsInScope, reportingBoundary).
- [ ] Agent accepts context for **any** property id (UUID from Supabase), not only a hardcoded demo property.
- [ ] dataLibraryRecords use **subject_category** (energy, water, waste, etc.); emissions are not stored as records.
- [ ] **Coverage:** When reasoning about water/heating completeness, agent uses **property_utility_applicability** and **property_service_charge_includes** (in context or via API); see COVERAGE-AND-APPLICABILITY-FOR-AGENT.md.
- [ ] API contract (request/response) is documented so Lovable can call the agent (endpoint, body, response format).
- [ ] After backend or Lovable changes, re-read this folder and update the agent if the context shape or fields change.

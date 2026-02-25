# Handoff: Instructions for the AI agent (Data Readiness / Boundary)

Use this when you work in the **AI agent** project. The **backend repo** (Secure-SoR-backend) is the source of truth for context shape, DB columns, and how Lovable builds the context from Supabase.

---

## 1. What the agent should do

- **Apply to new property records:** The agent runs in the context of a **property** (and optionally account). When users create new properties in the app, those properties are stored in Supabase; the agent should receive context for **any** such property (not only a fixed demo). Lovable (or your orchestration) will fetch that property’s data from the DB and build the context JSON.
- **Use context from the DB:** All context (property, spaces, systems, data library records, evidence) comes from **Supabase** (properties, spaces, systems, data_library_records, evidence_attachments, documents). The agent does not need to read the DB directly; it receives a **single context JSON** in the request body. Ensure your input schema matches what the backend doc specifies (Phase 5 “Agent context shape”).
- **Stay in sync with backend:** When the backend adds or changes columns or context fields (e.g. new property fields, data library subject_category, coverage), re-read the backend’s for-agent notes and update the agent’s expected input schema and logic if needed.

---

## 2. Where the agent gets its instructions (backend folder)

**Path to the backend repo (on this machine):**  
`/Users/anamariaspulber/Documents/Secure-SoR-backend`  
(or the path where you cloned Secure-SoR-backend).

**Files to read in the backend repo (in order):**

| Priority | Path (relative to backend repo root) | Purpose |
|----------|--------------------------------------|--------|
| 1 | `docs/for-agent/README.md` | Sync notes: property/spaces/systems/Data Library columns, context source, Phase 5 pointer. |
| 2 | `docs/for-agent/AGENT-TASKS.md` | Concrete to-do: context input (floorsInScope, optional fields), API contract, data library (subject_category, no emissions as records). |
| 3 | `docs/implementation-plan-lovable-supabase-agent.md` | **Phase 5** section: exact “Agent context shape” (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence), ID format, and how Lovable builds context from Supabase. |
| 4 | `docs/database/schema.md` | Table definitions (properties, spaces, systems, data_library_records, documents, evidence_attachments) when you need column-level detail. |
| 5 | `Secure_Canonical_v5.md` (if present in repo root or docs) | Product/domain and reporting boundary; single source of truth for principles. |

**Optional for Data Library / coverage:**  
`docs/data-library-what-to-do-next.md` (current UI steps); `docs/sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md`; `docs/sources/Secure_KPI_Coverage_Logic_Spec_v1.md` if the agent later receives coverage.

---

## 3. How to refer the agent project to this backend folder

**Option A — Path in agent repo:**  
In the agent project, add a short README or `CONTEXT-SOURCE.md` that says:

- “Context shape and DB alignment: read from the **backend repo** at  
  `[path]/Secure-SoR-backend/docs/for-agent/`  
  Start with `README.md` and `AGENT-TASKS.md`; then `docs/implementation-plan-lovable-supabase-agent.md` Phase 5.”

Replace `[path]` with the actual path (e.g. `../Secure-SoR-backend` if the agent repo is next to it, or the full path above).

**Option B — Cursor / AI instructions:**  
When you run the other agent (or an AI in the agent repo), give it:

- “Use the backend repo for context and API contract. Read these files in order:  
  `[backend-repo-path]/docs/for-agent/README.md`,  
  `[backend-repo-path]/docs/for-agent/AGENT-TASKS.md`,  
  and the Phase 5 section of `[backend-repo-path]/docs/implementation-plan-lovable-supabase-agent.md`.  
  Apply the agent to whatever property context is sent; context is built from Supabase (properties, spaces, systems, data_library_records, evidence).”

**Option C — Symlink or shared docs:**  
If the agent repo and backend repo live side by side, you can add a symlink in the agent repo, e.g. `backend-docs -> ../Secure-SoR-backend/docs/for-agent`, and tell the agent to read `backend-docs/README.md` and `backend-docs/AGENT-TASKS.md`.

---

## 4. Quick checklist for the agent

- [ ] Input schema matches Phase 5 “Agent context shape” (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence; optional floorsInScope, reportingBoundary).
- [ ] Agent accepts context for **any** property id (UUID from Supabase), not only a hardcoded demo property.
- [ ] dataLibraryRecords use **subject_category** (energy, water, waste, etc.); emissions are not stored as records.
- [ ] API contract (request/response) is documented so Lovable can call the agent (endpoint, body, response format).
- [ ] After backend or Lovable changes, re-read `docs/for-agent/README.md` and `AGENT-TASKS.md` and update the agent if the context shape or fields change.

---

*Backend last updated: Data Library dynamic UI + upload/edit/delete prompts; for-agent README and AGENT-TASKS in sync with subject_category, no-emissions-as-records, optional coverage; Phase 5 context shape in implementation plan.*

# Instructions for the AI agent (Data Readiness / Boundary)

Use this when implementing or updating the **AI agent**. The **backend repo** (Secure-SoR-backend) is the source of truth for context shape, DB columns, and how Lovable builds the context from Supabase.

---

## 1. What the agent should do

### Apply to new property records

- The agent runs in the context of a **property** (and optionally account). When users create new properties in the app, those properties are stored in Supabase.
- The agent must accept context for **any** such property (not only a fixed demo). Lovable (or your orchestration) will fetch that property’s data from the DB and build the context JSON and POST it to the agent.
- Do not hardcode a single property id; the agent should work for whatever `propertyId` is sent in the context.

### Use context from the DB

- All context (property, spaces, systems, data library records, evidence) comes from **Supabase** (tables: properties, spaces, systems, data_library_records, evidence_attachments, documents).
- The agent **does not** read the DB directly. It receives a **single context JSON** in the request body. Ensure your input schema matches what the backend specifies: **Phase 5 “Agent context shape”** in `docs/implementation-plan-lovable-supabase-agent.md` in the backend repo (see **CONTEXT-SOURCE.md** for the path).

### Stay in sync with the backend

- When the backend (or Lovable) adds or changes columns or context fields (e.g. new property fields, data library subject_category, coverage), re-read the backend’s for-agent notes and update the agent’s expected input schema and logic if needed.
- Backend for-agent folder: `[backend-repo-path]/docs/for-agent/` — start with `README.md` and `AGENT-TASKS.md`, then the Phase 5 section of the implementation plan.

---

## 2. Quick checklist for the agent

- [ ] **Input schema** matches Phase 5 “Agent context shape” (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence; optional floorsInScope, reportingBoundary).
- [ ] **Any property:** Agent accepts context for **any** property id (UUID from Supabase), not only a hardcoded demo property.
- [ ] **Data library:** dataLibraryRecords use **subject_category** (energy, water, waste, etc.); **emissions are never stored as Data Library records** — they are derived (Emissions Engine).
- [ ] **API contract:** Request/response (endpoint, body shape, response format) are documented so Lovable can call the agent correctly (e.g. in `AGENT-SUMMARY.md` or API docs in the agent repo).
- [ ] **After backend/Lovable changes:** Re-read `docs/for-agent/README.md` and `docs/for-agent/AGENT-TASKS.md` in the backend repo and update the agent if the context shape or fields change.

---

## 3. Referring the agent project to the backend folder

**Backend repo path (typical):**  
`/Users/anamariaspulber/Documents/Secure-SoR-backend`  
(or `../Secure-SoR-backend` if the agent repo is next to it).

**When using Cursor / AI in the agent repo**, you can say:

- “Use the backend repo for context and API contract. Read these files in order:  
  `[backend-repo-path]/docs/for-agent/README.md`,  
  `[backend-repo-path]/docs/for-agent/AGENT-TASKS.md`,  
  and the Phase 5 section of `[backend-repo-path]/docs/implementation-plan-lovable-supabase-agent.md`.  
  Apply the agent to whatever property context is sent; context is built from Supabase (properties, spaces, systems, data_library_records, evidence).”

Replace `[backend-repo-path]` with the actual path to Secure-SoR-backend.

---

## 4. Optional: symlink to backend docs

If the agent repo and backend repo live side by side, you can add a symlink in the agent repo, e.g.:

```bash
backend-docs -> ../Secure-SoR-backend/docs/for-agent
```

Then tell the agent (or yourself) to read `backend-docs/README.md` and `backend-docs/AGENT-TASKS.md` when checking context shape and tasks.

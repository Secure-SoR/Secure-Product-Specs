# Handover: AI agent (Data Readiness / Boundary)

**Copy this entire folder into your AI agent project** (e.g. `Documents/AI Agents/agent`). It contains everything the agent needs to align with the backend (Secure-SoR-backend) and Lovable.

---

## What’s in this folder

| File | Purpose |
|------|--------|
| **README.md** (this file) | Overview and entry point for the agent project. |
| **CONTEXT-SOURCE.md** | Where context comes from (Supabase via Lovable), which backend files define the context shape, and the path to the backend repo. |
| **INSTRUCTIONS.md** | What the agent must do: apply to new property records, use context from the DB, stay in sync with backend. |
| **AGENT-TASKS.md** | Concrete to-do list: context input (floorsInScope, optional fields), API contract, data library (subject_category, no emissions as records). |
| **BACKEND-SYNC-NOTES.md** | Condensed backend sync notes (properties, spaces, systems, Data Library, Phase 5) so the agent has the same reference as `docs/for-agent/` in the backend. |

---

## What the agent does

- **Runs in the context of a property.** Lovable (or your orchestration) fetches that property’s data from Supabase and sends you a **single context JSON** in the request body. The agent does not query the database; it only receives and processes that payload.
- **Must work for any property.** When users create new properties in the app, those are stored in Supabase. The agent should accept context for **any** property id (UUID from Supabase), not only a fixed demo property.
- **Context shape** is defined in the backend: see **CONTEXT-SOURCE.md** and the Phase 5 “Agent context shape” section in the backend’s implementation plan. Your input schema must match that (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence; optional floorsInScope, reportingBoundary).

---

## Quick start

1. Read **INSTRUCTIONS.md** for behaviour and rules.
2. Read **CONTEXT-SOURCE.md** to see where context comes from and which backend files to read for the exact schema.
3. Use **AGENT-TASKS.md** as a checklist when implementing or updating the agent.
4. When the backend or Lovable change context or APIs, re-read the backend’s `docs/for-agent/` (see CONTEXT-SOURCE.md for the path) and update the agent’s schema and logic if needed.

---

## Backend repo location

Context shape and API contract are defined in the **Secure-SoR-backend** repo. Default path (adjust if your clone is elsewhere):

```
/Users/anamariaspulber/Documents/Secure-SoR-backend
```

See **CONTEXT-SOURCE.md** for the exact list of files to read in that repo (e.g. `docs/for-agent/README.md`, `docs/for-agent/AGENT-TASKS.md`, Phase 5 of the implementation plan).

# Agent project — tasks / to-do

When you work in the **AI agent** project, use this list to keep the agent in sync with the backend and Lovable. Tick items as you complete them.

**Source of truth for context shape and APIs:** In the **backend repo**, see `docs/implementation-plan-lovable-supabase-agent.md` (Phase 5 “Agent context shape”) and `docs/for-agent/README.md`. Path to backend: see **CONTEXT-SOURCE.md** in this folder.

---

## Context input (property and reporting boundary)

- [ ] **Accept optional `floorsInScope`** in the agent context: array of floor identifiers the tenant occupies (from `properties.floors_in_scope`). Use it when reasoning about reporting boundary / which floors are in scope.
- [ ] **Accept optional property fields** if Lovable sends them: e.g. `occupancyScope` (`whole_building` | `partial_building`), `yearBuilt`, `lastRenovation`, `operationalStatus`. No change to required schema; document which optional fields the agent uses.
- [ ] **Context shape:** Ensure the agent’s expected input schema matches the backend’s Phase 5 “Agent context shape” (propertyId, propertyName, reportingYear, reportingBoundary, floorsInScope, spaces, systems, nodes, dataLibraryRecords, evidence).
- [ ] **Spaces hierarchy:** Accept optional `parentSpaceId` (and if sent, nested `children`) on spaces in the context. Lovable stores and sends spaces with parent_space_id; context can be a flat list with parentSpaceId or a tree. Use for boundary/scope reasoning if relevant.

---

## API and deployment

- [ ] **API contract:** Document request/response (e.g. in `AGENT-SUMMARY.md` or API docs) so Lovable knows the exact endpoint, body shape, and response format.
- [ ] **Deployed URL:** Confirm the URL Lovable calls (e.g. Render) is the one you deploy to; update Lovable env if you change it.
- [ ] **IDs:** Document whether the agent expects UUIDs (from Supabase) or string ids for property/spaces/systems; keep consistent with what Lovable sends.

---

## Data library and evidence

- [ ] **dataLibraryRecords / evidence:** If the agent uses these, ensure field names match what Lovable sends (see backend implementation plan Phase 5). Handle optional or empty arrays. Records have **subject_category** (energy, water, waste, indirect_activities, certificates, esg, governance, targets, occupant_feedback); **emissions are never stored as Data Library records** — they are derived (Emissions Engine).
- [ ] **Building systems context:** Systems in context follow the Building Systems Taxonomy (categories + types). Optional fields per system: keySpecs, specStatus, servesSpacesDescription (from register). Ensure agent can use category/type and optional register fields if sent.
- [ ] **Coverage (optional):** If the agent later receives KPI coverage (Complete/Partial/Unknown), it will align with the backend’s KPI Coverage spec. No change to context shape until dashboards and CoverageEngine are wired.

---

## When the backend or Lovable change

- [ ] Re-read the backend’s `docs/for-agent/README.md` and `docs/for-agent/AGENT-TASKS.md` for the latest property columns and context notes.
- [ ] Add any new optional context fields to this task list and to the agent’s input schema docs.
- [ ] If the agent logic changes (e.g. new finding types), document it in the agent repo and note in the backend for-agent folder if Lovable needs to change how it displays results.

---

*This file is a copy of the backend’s `docs/for-agent/AGENT-TASKS.md` for use inside the agent project. When in doubt, prefer the backend repo as the source of truth.*

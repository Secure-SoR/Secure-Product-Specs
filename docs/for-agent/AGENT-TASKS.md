# Agent project — tasks / to-do when you switch to the agent repo

When you move on to the **AI agent** project, use this list to keep the agent in sync with the backend and Lovable. Tick items as you complete them.

**Source of truth for context shape and APIs:** `docs/implementation-plan-lovable-supabase-agent.md` (Phase 5 “Agent context shape”) and this folder’s [README.md](./README.md).

---

## Context input (property and reporting boundary)

- [ ] **Accept optional `floorsInScope`** in the agent context: array of floor identifiers the tenant occupies (from `properties.floors_in_scope`). Use it when reasoning about reporting boundary / which floors are in scope.
- [ ] **Accept optional property fields** if Lovable sends them: e.g. `occupancyScope` (`whole_building` | `partial_building`), `yearBuilt`, `lastRenovation`, `operationalStatus`. No change to required schema; document which optional fields the agent uses.
- [ ] **Context shape:** Ensure the agent’s expected input schema matches `docs/implementation-plan-lovable-supabase-agent.md` Phase 5 “Agent context shape” (propertyId, propertyName, reportingYear, reportingBoundary, floorsInScope, spaces, systems, nodes, dataLibraryRecords, evidence).
- [ ] **Spaces hierarchy:** Accept optional `parentSpaceId` (and if sent, nested `children`) on spaces in the context. Lovable now stores and sends spaces with parent_space_id; context can be a flat list with parentSpaceId or a tree. Spaces can be top-level (tenant vs base building, then control) or subspaces (e.g. meeting rooms under a floor). Use for boundary/scope reasoning if relevant.

---

## API and deployment

- [ ] **API contract:** Document request/response (e.g. in `AGENT-SUMMARY.md` or API docs) so Lovable knows the exact endpoint, body shape, and response format.
- [ ] **Deployed URL:** Confirm the URL Lovable calls (e.g. Render) is the one you deploy to; update Lovable env if you change it.
- [ ] **IDs:** Document whether the agent expects UUIDs (from Supabase) or string ids for property/spaces/systems; keep consistent with what Lovable sends.

---

## Data library and evidence (when Phase 3 is done)

- [ ] **dataLibraryRecords / evidence:** If the agent uses these, ensure field names match what Lovable sends (see implementation plan Phase 5). Handle optional or empty arrays. Records have **subject_category** (energy, water, waste, indirect_activities, certificates, esg, governance, targets, occupant_feedback); **emissions are never stored as Data Library records** — they are derived (Emissions Engine).
- [ ] **Building systems context:** Systems in context follow the Building Systems Taxonomy (categories + types). Optional fields per system: keySpecs, specStatus, servesSpacesDescription (from register). Context shape already has systems array; ensure agent can use category/type and optional register fields if sent.
- [ ] **Coverage (optional):** If the agent later receives KPI coverage (Complete/Partial/Unknown), it will align with `docs/sources/Secure_KPI_Coverage_Logic_Spec_v1.md` (component states, utilityComponentProfile, kpiAssessments). No change to context shape until dashboards and CoverageEngine are wired.

---

## When you add new backend/Lovable features

- [ ] Re-read [README.md](./README.md) in this folder for the latest property columns and context notes.
- [ ] Add any new optional context fields to this task list and to the agent’s input schema docs.
- [ ] If the agent logic changes (e.g. new finding types), document it in the agent repo and note here if Lovable needs to change how it displays results.

---

*Last sync: Backend has property fields (occupancy_scope, floors_in_scope); spaces have parent_space_id; systems + upload register working; end_use_nodes (Phase 4) and nodes spec/prompts in place. **Data Library:** Taxonomy v3, Energy/Waste component architecture, step-by-step + Lovable prompts (upload file flow, restore structure, Edit record, Delete record), sample energy bill payload doc; for-agent README and tasks updated with subject_category, no-emissions-as-records, optional coverage. **Handoff:** [HANDOFF-FOR-AGENT.md](./HANDOFF-FOR-AGENT.md) — instructions for the other agent (apply to new property records, use context from DB, how to refer agent project to this backend folder). **Next:** (1) Continue Data Library in Lovable (Edit/Delete if not done), (2) Dashboards + KPI coverage, (3) Agent Phase 5 + ensure agent reads backend for-agent docs. Update this file when you add tasks or complete them.*

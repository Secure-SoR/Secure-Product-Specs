# Agent project — tasks / to-do when you switch to the agent repo

When you move on to the **AI agent** project, use this list to keep the agent in sync with the backend and Lovable. Tick items as you complete them.

**Source of truth for context shape and APIs:** CONTEXT-SOURCE.md in this folder and the backend repo docs/implementation-plan-lovable-supabase-agent.md (Phase 5 "Agent context shape").

---

## Context input (property and reporting boundary)

- [ ] **Accept optional `floorsInScope`** in the agent context: array of floor identifiers the tenant occupies (from `properties.floors_in_scope`). Use it when reasoning about reporting boundary / which floors are in scope.
- [ ] **Accept optional property fields** if Lovable sends them: e.g. `occupancyScope` (whole_building | partial_building), `yearBuilt`, `lastRenovation`, `operationalStatus`. No change to required schema; document which optional fields the agent uses.
- [ ] **Context shape:** Ensure the agent's expected input schema matches Phase 5 "Agent context shape" (propertyId, propertyName, reportingYear, reportingBoundary, floorsInScope, spaces, systems, nodes, dataLibraryRecords, evidence).
- [ ] **Spaces hierarchy:** Accept optional `parentSpaceId` (and if sent, nested `children`) on spaces in the context. Lovable now stores and sends spaces with parent_space_id; context can be a flat list with parentSpaceId or a tree.

---

## API and deployment

- [ ] **API contract:** Document request/response (e.g. in AGENT-SUMMARY.md or API docs) so Lovable knows the exact endpoint, body shape, and response format.
- [ ] **Deployed URL:** Confirm the URL Lovable calls (e.g. Render) is the one you deploy to; update Lovable env if you change it.
- [ ] **IDs:** Document whether the agent expects UUIDs (from Supabase) or string ids for property/spaces/systems; keep consistent with what Lovable sends.

---

## Data library and evidence

- [ ] **dataLibraryRecords / evidence:** If the agent uses these, ensure field names match what Lovable sends (see CONTEXT-SOURCE.md). Handle optional or empty arrays. Records have **subject_category** (energy, water, waste, indirect_activities, certificates, esg, governance, targets, occupant_feedback); **emissions are never stored as Data Library records** — they are derived (Emissions Engine).
- [ ] **Building systems context:** Systems in context follow the Building Systems Taxonomy (categories + types). Optional fields per system: keySpecs, specStatus, servesSpacesDescription (from register).
- [ ] **Coverage (optional):** If the agent later receives KPI coverage (Complete/Partial/Unknown), it will align with the KPI Coverage spec (component states, utilityComponentProfile, kpiAssessments).

---

## Coverage and applicability (for agent and inference)

- [ ] **Read property_utility_applicability and property_service_charge_includes:** When reasoning about water/heating completeness or advising "upload water bill", the agent should use these tables (in context or via API). See COVERAGE-AND-APPLICABILITY-FOR-AGENT.md in this folder.
- [ ] **Water KPI logic:** If water is `included_in_service_charge` and `includes_water` is true, water is complete when the service charge (that includes water) is uploaded. If water is `both`, complete only when both water source(s) and service charge that includes water are present.
- [ ] **Heating:** Same idea as water; use includes_heating and applicability for heating.

---

## When you add new backend/Lovable features

- [ ] Re-read README.md and BACKEND-SYNC-NOTES.md in this folder for the latest property columns and context notes.
- [ ] Add any new optional context fields to this task list and to the agent's input schema docs.
- [ ] If the agent logic changes (e.g. new finding types), document it in the agent repo and note here if Lovable needs to change how it displays results.

---

*Last sync: Backend has property_utility_applicability and property_service_charge_includes; for-agent updated with coverage/applicability. Data Library: Taxonomy v3, Energy/Waste component architecture, upload/edit/delete, sample CSVs. Next: Dashboards + KPI coverage, Agent Phase 5.*

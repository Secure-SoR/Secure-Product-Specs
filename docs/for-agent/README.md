# For the AI agent — sync with backend and Lovable

The **AI agent** (Data Readiness / Boundary) lives in a **separate project** (e.g. `Documents/AI Agents/agent` or similar). This folder holds short notes so that when you work in the agent repo, you can keep it in sync with what the backend and Lovable expect.

**When you move on to the agent project:** Use **[AGENT-TASKS.md](./AGENT-TASKS.md)** for a concrete to-do list (context fields, API contract, deployment) to work through.

**Rule:** For every change that affects data shape or API (properties, spaces, systems, data library, agent context), update this section and the agent project so the agent stays up to date.

---

## Phase 2: Properties (and spaces, systems) in Supabase

**Backend / Lovable:** Properties are stored in Supabase table `properties` (columns: id, account_id, name, address, city, region, postcode, country, nla, asset_type, year_built, last_renovation, operational_status, occupancy_scope, floors, floors_in_scope, total_area, created_at, updated_at). occupancy_scope: 'whole_building' | 'partial_building' (tenant footprint). floors: all floor identifiers in the building; floors_in_scope: jsonb array of floor identifiers the tenant occupies (saved from "Floors in Scope" tile on spaces subpage). City, region, postcode, and nla are persisted separately (not concatenated into address). `asset_type` defaults to `'Office'` in DB; app maps `assetType` ↔ `asset_type`, `yearBuilt` ↔ `year_built`, `lastRenovation` ↔ `last_renovation`, `operationalStatus` ↔ `operational_status`. GFA/total_area uses `??` when mapping so 0 is preserved. Demo property IDs use localStorage overrides (`demoPropertyOverrides`) for field-level edits. Lovable creates/lists/updates/deletes via the Supabase client with `account_id = currentAccountId`.

**Spaces hierarchy (implemented in Lovable):** Spaces can be top-level (parent_space_id null) or subspaces (parent_space_id = parent space id). Lovable has "Create the Spaces" button, CreateSpaceDialog with parentSpace for subspaces, buildSpaceTree, SpaceTreeList with Add subspace and indented rendering. Two levels: (1) space_class = tenant | base_building; (2) control = tenant_controlled | landlord_controlled | shared. Base building can use space_type e.g. common_area, shared_space; subspaces (e.g. meeting rooms under a floor) use parent_space_id. See implementation plan “Create the spaces” prompt.

**Building systems (Physical and Technical):** Systems follow the Building Systems Taxonomy (Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring). Each system has name, system_category, system_type, controlled_by, maintained_by, metering_status, allocation_method, allocation_notes, key_specs, spec_status, serves_spaces_description (and optionally serves_space_ids). **Control** is defaulted from the space(s) the system serves (serves_space_ids → space.control) with override on the system. **Upload register:** CSV/Excel import with column mapping and normalization is in the implementation plan; template: docs/templates/building-systems-register-template.csv. See building-systems-register, building-systems-taxonomy, and **nodes-attribution-and-control** in the backend repo.

**Agent:** When building the agent context (Phase 5), the property object can include optional `floorsInScope` (array of floor identifiers the tenant occupies), mapped from `properties.floors_in_scope`. Spaces array can include optional `parentSpaceId` (and optionally nested `children`) so the agent can reason about space hierarchy. The agent still receives **context JSON** with `propertyId`, `propertyName`, `spaces`, `systems`, etc. Lovable will build that context by **fetching from Supabase** (properties, spaces, systems) instead of localStorage. The **context shape** is unchanged; only the source of the data changes. Keep the agent’s expected input schema as in `agent/contexts/` and the API contract in the agent repo.

---

## Phase 3: Data library + evidence in Supabase

**Backend / Lovable:** Data library records in `data_library_records` (with `name`, `subject_category`, `source_type` connector|upload|manual|rule_chain, `confidence` including cost_only; canonical categories: energy, water, waste, indirect_activities, certificates, esg, governance, targets, occupant_feedback). Files in Storage bucket `secure-documents`; links in `documents` and `evidence_attachments` (optional `tag`, `description`). **Emissions are never stored as primary data** — they are calculated (Layer 2); Data Library is Activity + Governance + Compliance only. Step-by-step to make UI dynamic: `docs/data-library-lovable-supabase-step-by-step.md`. Key specs: Taxonomy v3 (`docs/sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md`), Energy/Waste component architecture (`docs/sources/Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md`), Emissions Engine mapping (`docs/sources/Secure_Emissions_Engine_Mapping_v1.md`), KPI Coverage (`docs/sources/Secure_KPI_Coverage_Logic_Spec_v1.md`).

**Agent:** Context may include `dataLibraryRecords` and `evidence` (record id, type, name, file name, subject_category). Use **subject_category** to reason about activity layer (energy, waste, etc.); do not expect emissions as records. If the agent ever receives **coverage** (Complete/Partial/Unknown per KPI), it will come from CoverageEngine output (utilityComponentProfile, kpiAssessments); see KPI Coverage spec. Ensure field names match what Lovable sends (implementation plan Phase 5 “Agent context shape”).

---

## Phase 5: Build agent context and call the agent

**Lovable:** Fetches property, spaces, systems, nodes (if any), data library records, evidence from Supabase; builds the context JSON; POSTs to the agent; optionally saves to `agent_runs` and `agent_findings`.

**Agent:** Accept the same context shape as documented in the implementation plan (§ Phase 5 “Agent context shape”). Map DB column names to the agent’s expected names (e.g. `system_category` → `category`, `space_class` → `spaceClass`). Ensure the deployed agent URL is the one Lovable calls; no change to agent logic unless you add new fields to the context.

---

## Checklist when you open the agent project

- [ ] Context input schema matches `docs/implementation-plan-lovable-supabase-agent.md` Phase 5 “Agent context shape”.
- [ ] Property/spaces/systems IDs: agent accepts UUIDs (from Supabase) or string ids; document which the agent expects.
- [ ] API endpoint and request/response contract are documented (e.g. in agent repo `AGENT-SUMMARY.md` or API docs) so Lovable can call the agent correctly.
- [ ] Data library: agent expects `dataLibraryRecords` with `subject_category` (energy, waste, etc.); does not treat emissions as stored records. If coverage is added to context later, it follows `docs/sources/Secure_KPI_Coverage_Logic_Spec_v1.md`.

# Backend sync notes (condensed from Secure-SoR-backend)

This file is a condensed copy of the backend’s `docs/for-agent/README.md` so the agent project has the same reference. For the full, up-to-date version, read the backend repo: `[backend-repo-path]/docs/for-agent/README.md` (see **CONTEXT-SOURCE.md** for the path).

---

## Properties (Supabase)

Table `properties`: id, account_id, name, address, city, region, postcode, country, nla, asset_type, year_built, last_renovation, operational_status, occupancy_scope, floors, floors_in_scope, total_area, created_at, updated_at.

- `occupancy_scope`: 'whole_building' | 'partial_building' (tenant footprint).
- `floors`: all floor identifiers in the building.
- `floors_in_scope`: jsonb array of floor identifiers the tenant occupies (→ context `floorsInScope`).
- City, region, postcode, nla are separate columns (not concatenated into address). `asset_type` defaults to `'Office'` in DB. App maps: assetType ↔ asset_type, yearBuilt ↔ year_built, lastRenovation ↔ last_renovation, operationalStatus ↔ operational_status.

---

## Spaces

Spaces can be top-level (parent_space_id null) or subspaces (parent_space_id = parent space id). Two levels: (1) space_class = tenant | base_building; (2) control = tenant_controlled | landlord_controlled | shared. Subspaces (e.g. meeting rooms under a floor) use parent_space_id. Context can send optional `parentSpaceId` and optionally nested `children`.

---

## Systems

Building systems follow the Building Systems Taxonomy (Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring). Each system: name, system_category, system_type, controlled_by, maintained_by, metering_status, allocation_method, allocation_notes, key_specs, spec_status, serves_spaces_description (and optionally serves_space_ids). Control is defaulted from the space(s) the system serves, with override on the system. When building context, map `system_category` → `category` for the agent.

---

## Data library + evidence

- **data_library_records:** name, subject_category, source_type (connector | upload | manual | rule_chain), confidence (including cost_only). Canonical subject_category: energy, water, waste, indirect_activities, certificates, esg, governance, targets, occupant_feedback. **Emissions are never stored as primary data** — they are calculated (Layer 2); Data Library is Activity + Governance + Compliance only.
- Files in Storage bucket `secure-documents`; metadata in `documents`; links in `evidence_attachments` (optional tag, description).
- **Agent:** Context may include dataLibraryRecords and evidence (record id, type, name, file name, subject_category). Use **subject_category** to reason about activity layer; do not expect emissions as records. If coverage is added later, it will follow the KPI Coverage spec.

---

## Phase 5: Build agent context and call the agent

**Lovable:** Fetches property, spaces, systems, nodes (if any), data library records, evidence from Supabase; builds the context JSON; POSTs to the agent; optionally saves to agent_runs and agent_findings.

**Agent:** Accept the same context shape as in the backend’s implementation plan Phase 5 “Agent context shape”. Map DB column names to the agent’s expected names (e.g. system_category → category, space_class → spaceClass). Ensure the deployed agent URL is the one Lovable calls.

---

*When in doubt, re-read the backend repo’s `docs/for-agent/README.md` and `docs/for-agent/AGENT-TASKS.md`.*

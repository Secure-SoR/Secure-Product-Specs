# Backend sync notes — property, spaces, systems, data library, coverage

Summary of what the backend and Lovable store and send. Keep the agent's expected input schema aligned with these.

---

## Properties (Supabase: `properties`)

Columns: id, account_id, name, address, city, region, postcode, country, nla, asset_type, year_built, last_renovation, operational_status, occupancy_scope, floors, floors_in_scope, total_area, created_at, updated_at.

- **occupancy_scope:** whole_building | partial_building (tenant footprint).
- **floors:** all floor identifiers in the building.
- **floors_in_scope:** jsonb array of floor identifiers the tenant occupies (saved from "Floors in Scope" tile). Map to context as `floorsInScope` (array).
- **asset_type** defaults to 'Office' in DB; app maps assetType, yearBuilt, etc.

---

## Spaces (Supabase: `spaces`)

Top-level (parent_space_id null) or subspaces (parent_space_id = parent space id). **space_class:** tenant | base_building. **control:** tenant_controlled | landlord_controlled | shared. **space_type:** e.g. common_area, shared_space, meeting_room. Subspaces use parent_space_id. Context can send flat list with **parentSpaceId** or a tree with **children**.

---

## Systems (Supabase: `systems`)

Building Systems Taxonomy: Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring. Each system: name, system_category, system_type, controlled_by, metering_status, allocation_method, allocation_notes, key_specs, spec_status, serves_spaces_description, serves_space_ids. Map **system_category** to **category** in context.

---

## Data library (Supabase: `data_library_records`)

**name**, **subject_category** (energy, water, waste, indirect_activities, certificates, esg, governance, targets, occupant_feedback), **source_type** (connector | upload | manual | rule_chain), **confidence** (measured | allocated | estimated | cost_only). Files in Storage bucket secure-documents; links in documents and evidence_attachments. **Emissions are never stored as primary data** — they are calculated (Layer 2). Use **subject_category** in context as record category.

---

## Coverage and applicability (Supabase: `property_utility_applicability`, `property_service_charge_includes`)

**property_utility_applicability:** One row per property × component. **component:** tenant_electricity | landlord_recharge | heating | water | waste. **applicability:** separate_bill | included_in_service_charge | both | not_applicable. Tells whether e.g. water/heating are separate bills only, included in service charge only, or both.

**property_service_charge_includes:** One row per property. **includes_energy**, **includes_water**, **includes_heating** (booleans). Optional **energy_inclusion_scope**, **water_inclusion_scope**, **heating_inclusion_scope** (each `base_building_only` | `tenant_consumption_included`): when a utility is included, whether the SC covers base building only or complete tenant consumption (base building shared + tenant space). Affects double-counting: only tenant_consumption_included means do not add separate records.

The agent and CoverageEngine use these to infer KPI completeness (e.g. water complete when service charge that includes water is uploaded if water is "included in service charge only"). Full rules: COVERAGE-AND-APPLICABILITY-FOR-AGENT.md.

---

## When backend adds or changes

Re-read this file and AGENT-TASKS.md. Update the agent's input schema and logic if new fields are added to context (e.g. propertyUtilityApplicability, propertyServiceChargeIncludes).

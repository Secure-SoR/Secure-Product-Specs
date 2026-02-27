# Agent context shape (Phase 5 — source: Supabase)

Context is built by **Lovable** (or your orchestration) from Supabase and sent to the agent in the request body. The agent does not read the DB directly.

---

## Where context comes from

- **properties** (one row by property id)
- **spaces** (by property_id)
- **systems** (by property_id)
- **end_use_nodes** (by property_id), if present
- **data_library_records** (by property_id or account)
- **evidence_attachments** + **documents** (for those records → evidence list)
- **property_utility_applicability** (by property_id) — optional; for coverage/completeness reasoning
- **property_service_charge_includes** (by property_id) — optional; for coverage/completeness reasoning

Map DB column names to the agent's expected names (e.g. `system_category` → `category`, `space_class` → `spaceClass`).

---

## Minimal context shape (what the agent expects)

- `propertyId`, `propertyName`, `reportingYear`
- `reportingBoundary` (optional): e.g. `{ boundaryApproach, includedPropertyIds, methodologyFramework }`
- `floorsInScope` (optional): array of floor identifiers the tenant occupies (from `properties.floors_in_scope`); helps agent reason about reporting boundary
- `spaces`: array of `{ id, name, spaceClass, control, inScope, area, floorReference, spaceType, parentSpaceId }`; optional `parentSpaceId` for hierarchy (subspaces); optional `children` array when sending a tree. Flat list is fine; agent can build tree from parentSpaceId.
- `systems`: array of `{ id, category, controlledBy, meteringStatus, allocationMethod, servesSpaces }` (agent accepts `category`; DB has `system_category` + `system_type` — map when building context)
- `nodes` (optional): array of `{ id, systemId, type, controlOverride, allocationWeight, spaceIds }`
- `dataLibraryRecords`: array of `{ id, category, reportingYear, propertyId, confidenceLevel }` — use **subject_category** from DB as category (energy, water, waste, etc.). Emissions are never stored as records; they are derived.
- `evidence`: array of `{ id, recordId, recordType, recordName, fileName }` — **recordId** must be the data_library_record id (UUID) so the agent can match evidence to records. Build from `evidence_attachments` + `documents` for the selected property’s records. See backend repo [step-by-step-evidence-in-context.md](../step-by-step-evidence-in-context.md).
- Optional: `workforceDatasets`, `certificates` (can be empty arrays)
- **Optional for coverage:** `propertyUtilityApplicability` (array of `{ component, applicability }` per property), `propertyServiceChargeIncludes` (e.g. `{ includesEnergy, includesWater, includesHeating }`) — see COVERAGE-AND-APPLICABILITY-FOR-AGENT.md

**ID format:** Agent is flexible. You can use Supabase UUIDs as `id` for spaces/systems and map `servesSpaces` / `spaceIds` to those same UUIDs. Keep `systemId` in nodes as the system's `id` (UUID or string).

---

## Full reference

The full Phase 5 section (Lovable fetch steps, optional agent_runs/agent_findings) lives in the backend repo: docs/implementation-plan-lovable-supabase-agent.md. This file is the extracted "context shape" so the agent project has it in one place.

# Agent context extension — Data Centre properties

**Purpose:** Satisfy [implementation-guide-phase-2-dc.md](../specs/implementation-guide-phase-2-dc.md) Step 2.5: when `properties.asset_type = 'data_centre'`, the payload sent to Data Readiness, Boundary, and related agents must include DC-specific SoR data.

**Full checklist (migrations, Lovable prompt order, agents):** [implementation-guide-agent-context-data-centre.md](../specs/implementation-guide-agent-context-data-centre.md)

**All SQL + Lovable prompts on one page:** [data-centre-agent-context-COPY-PASTE.md](../specs/data-centre-agent-context-COPY-PASTE.md)

**Lovable file copy:** [LOVABLE-PROMPT-AGENT-CONTEXT-DATA-CENTRE.md](../lovable-prompts/LOVABLE-PROMPT-AGENT-CONTEXT-DATA-CENTRE.md)

**Spec:** [secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §7 (agents), §2.2 (`dc_metadata`), §3 (spaces / `space_type`).

---

## When it applies

If the selected property has `asset_type === 'data_centre'` (exact string), treat the context as **extended**. For other asset types, behaviour stays unchanged.

---

## Fields to add (Lovable / client context builder)

Add alongside existing AgentContext fields (property id, name, reporting year, spaces, systems, end_use_nodes, data library, evidence, etc.):

| Field | Type | Source | Notes |
|--------|------|--------|--------|
| `dcMetadata` | object \| null | `dc_metadata` where `property_id` = selected property | At most one row (UNIQUE on `property_id`). `null` if no row yet. |
| `propertyAssetType` | string | `properties.asset_type` | Lets agents branch without re-inferring. |

**Spaces and systems:** No separate duplicate list is required if the existing `spaces` array already includes all spaces for the property with **`space_type`** set, and `systems` already lists all `systems` rows for the property. For DC properties, those rows may use DC `space_type` and DC `system_type` values per [space-types-taxonomy.md](../data-model/space-types-taxonomy.md) and [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) §4.

---

## Example shape (illustrative)

```json
{
  "propertyId": "…",
  "propertyName": "…",
  "propertyAssetType": "data_centre",
  "dcMetadata": {
    "tier_level": "III",
    "design_capacity_mw": 12.5,
    "target_pue": 1.35,
    "cooling_type": ["liquid_cooled"],
    "sitdeck_site_id": null
  },
  "spaces": [ { "id": "…", "name": "Hall A", "space_type": "data_hall", "space_class": "tenant", "control": "tenant_controlled" } ],
  "systems": [ { "id": "…", "name": "UPS A", "system_category": "Power", "system_type": "UPS_System" } ]
}
```

---

## Implementation ownership

| Layer | Action |
|--------|--------|
| **Lovable** | After loading property, if `data_centre`, query `dc_metadata` and set `dcMetadata` on the object passed to agent POST bodies and to `agent_runs.context_snapshot` if the app logs runs. |
| **AI Agents** | Optionally consume `dcMetadata` and `propertyAssetType` in prompts or scoring; backward compatible if fields are omitted for non-DC properties. |

**Future:** When `dc_sensor_readings`, `dc_rack_assets`, or sync tables exist, extend this doc with optional `dcSensorRollup` / `rackSummary` per [secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §7.

---

## Done criteria (Phase 2 Step 2.5)

- [ ] Lovable (or whichever client builds agent context) sets `dcMetadata` and ensures `spaces` / `systems` are populated for the property when `asset_type` is `data_centre`.
- [ ] This document is the reference for what “extended context” means until the Agent API publishes a formal OpenAPI schema.

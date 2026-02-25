# End-Use Nodes — Spec (v1 aligned with Building Systems Register)

**Purpose:** Canonical mapping of **End-Use Nodes → Systems → Spaces** for controllability, reporting, and AI agents. This doc merges the 140 Aldersgate End-Use Nodes v1 with the current backend schema and engineer rules.

**We have this data in repo:** Node definitions match [building-systems-register.md §B](../sources/140-aldersgate/building-systems-register.md) (same nodeIds, categories, linked systems, weights, control). Taxonomy: [building-systems-taxonomy.md §2](building-systems-taxonomy.md). DB: [schema.md §3.8](../database/schema.md), [supabase-schema.sql](../database/supabase-schema.sql) table `end_use_nodes`.

---

## 1. Alignment with Building Systems Register

The **Building Systems Register** (140 Aldersgate) Section B lists the same nodes as your End-Use Nodes v1 Section C:

- **Electricity:** E_TENANT_PLUG, E_TENANT_LIGHT, E_HVAC_SERVE_TENANT, E_BASE_LIGHT, E_LIFTS_PLANT  
- **Heating:** H_TENANT_ZONE, H_BASE_BUILDING, H_SHARED  
- **Water:** W_PANTRY, W_TOILETS, W_SHARED  
- **Waste:** WA_OFFICE, WA_RECYCLING_INFRA  
- **Monitoring:** O_PEOPLE_COUNT, A_ACCESS  

Linked system names (e.g. "Tenant Electricity Submeters (6 total)", "Base Building HVAC Plant") map to `systems.id` in the DB by matching `systems.name` (or by a chosen system record). **So: still aligned.** No node renames needed.

---

## 2. Space ID placeholders (replace with real IDs)

When creating nodes in the app or importing, replace placeholders with **real space UUIDs** from the `spaces` table for the property.

| Placeholder | Meaning |
|-------------|---------|
| SPACE_GROUND | Ground floor (tenant demise) |
| SPACE_4F | 4th floor (tenant demise) |
| SPACE_5F | 5th floor (tenant demise) |
| SPACE_TENANT_DEMISE | Convenience: Ground + 4F + 5F (tenant spaces) |
| SPACE_BASE_BUILDING | Base building (landlord-controlled: toilets, cores, plantrooms, common areas) |
| SPACE_WHOLE_BUILDING | Whole property (all spaces) |

In Supabase, `applies_to_space_ids` is `uuid[]` — store actual `spaces.id` values. The UI or seed script should resolve placeholders using the property's spaces (e.g. filter by `space_class` / `control` or by name/floor).

---

## 3. Node model (required and optional fields)

**DB table:** `end_use_nodes`. Our schema vs your v1 model:

| Your v1 / Register | Our DB column | Type | Required |
|--------------------|---------------|------|----------|
| nodeId | node_id | text | Yes (business key, e.g. E_TENANT_PLUG) |
| category | node_category | text | Yes (e.g. tenant_plug_load) |
| systemIdOrName | system_id | uuid | Yes (FK → systems.id) |
| utilityType | utility_type | text | Yes (electricity, heating, cooling, water, waste, occupancy, access) |
| appliesToSpaceIds | applies_to_space_ids | uuid[] | Yes (≥1 space; DB allows null but validation should require ≥1) |
| controlOverride | control_override | text | No (TENANT \| LANDLORD \| SHARED) |
| allocationWeight | allocation_weight | numeric | No (0..1) |
| notes | notes | text | No |
| — | id | uuid | PK (auto) |
| — | account_id | uuid | Yes (RLS) |
| — | property_id | uuid | Yes (FK → properties.id) |

**Unique:** `(property_id, node_id)` — one node_id per property.

**Optional for later:** `auto_generated` (boolean) to mark nodes created by an archetype/default generator; see §7 below.

---

## 4. Systems and spaces (what we have)

Your engineer instructions say systems must have `utility_type` and `applies_to_space_ids`. In our schema:

- **Systems** have: `controlled_by` (tenant | landlord | shared), `serves_space_ids` (uuid[]). We do **not** have `utility_type` on systems — utility is per **node** (each node has `utility_type`). So one system (e.g. Base Building HVAC Plant) can be linked to both electricity and heating nodes.
- **Spaces** have: `control` = `tenant_controlled` | `landlord_controlled` | `shared` (slightly different naming than systems' `controlled_by`; see §5 for resolution).

This is consistent with the register: systems are plant/meters; nodes are the end-use breakdown (electricity vs heating vs water, etc.) and link to one system each.

---

## 5. Control resolution (hard rule)

Use this order when resolving "who controls this end-use?" for reporting or the agent:

```
resolvedControl =
  node.control_override
  ?? mapSystemControl(system.controlled_by)
  ?? mapSpaceControl(dominantSpace.control)
```

- **node.control_override:** If set (TENANT | LANDLORD | SHARED), use it.
- **system.controlled_by:** Our DB has `tenant` | `landlord` | `shared` (lowercase). Map to **TENANT** | **LANDLORD** | **SHARED** for the agent/UI.
- **dominantSpace.control:** Our DB has `tenant_controlled` | `landlord_controlled` | `shared`. Map to **TENANT** | **LANDLORD** | **SHARED** (e.g. tenant_controlled → TENANT). "Dominant" = e.g. first space in `applies_to_space_ids`, or majority control if you have multiple spaces.

So: **node overrides system; system overrides dominant space.** Same rule as your v1.

---

## 6. Validation and weight rules (engineer instructions)

- Each node references **exactly one** `system_id` (FK to `systems.id`).
- Each node has **at least one** `applies_to_space_ids` (validate in app; DB allows null for flexibility but UI/API should require ≥1).
- `allocation_weight` must be between 0 and 1 (DB CHECK already).
- Nodes must belong to the **same property** as the linked system (enforce in app: node.`property_id` = system.`property_id`; our FKs don't cross properties).
- **Weights:** If any nodes for a given `utility_type` (and optionally same scope) have `allocation_weight`, normalize so weights within that group sum to ~1.0 (tolerate rounding). If no weights: use archetype defaults or equal weights. Persist whether weights were **explicit** vs **defaulted** if you need the agent to label "Estimated controllability" (e.g. via a flag or convention).

---

## 7. Autogeneration (portfolio scalable)

If a property has **systems but no end_use_nodes**:

- You can **generate default nodes** per utility type (e.g. office archetype from taxonomy).
- Mark them with **auto_generated = true** (add column to `end_use_nodes` if you want this; optional).
- Allow later editing without breaking historical calculations (e.g. keep a snapshot or run id for "as at" reporting).

The schema and Supabase table include optional `auto_generated` (boolean, default false) for when you implement archetype default nodes.

---

## 8. JSON format for agent context

When building context for the agent (Phase 5), send a **nodes** array. Each node:

```json
{
  "id": "E_TENANT_PLUG",
  "systemId": "<systems.id UUID or string>",
  "type": "tenant_plug_load",
  "controlOverride": "TENANT",
  "allocationWeight": 0.45,
  "spaceIds": ["<space-uuid-1>", "<space-uuid-2>"]
}
```

- **id** = `node_id` (business key).
- **systemId** = `system_id` (UUID from `systems`).
- **type** = `node_category`.
- **spaceIds** = `applies_to_space_ids` (UUIDs).
- Use **resolvedControl** (from §5) if the agent expects a single control field; otherwise send `controlOverride` and let the agent resolve.

---

## 9. Minimal acceptance checks (engineering)

1. Every node references exactly **one** system (`system_id`).
2. Every node has ≥1 `applies_to_space_ids`.
3. Control resolution: `node.control_override ?? system.controlled_by (mapped) ?? dominantSpace.control (mapped)`.
4. Per-utility (and scope) weights, when present, sum to ~1.0 (tolerate rounding).
5. Node's `property_id` = linked system's `property_id`.

---

## 10. References

- Node definitions (140A): [building-systems-register.md §B](../sources/140-aldersgate/building-systems-register.md)
- Taxonomy (categories, utility types): [building-systems-taxonomy.md §2](building-systems-taxonomy.md)
- Attribution and control from spaces: [nodes-attribution-and-control.md](nodes-attribution-and-control.md)
- Schema: [schema.md §3.8](../database/schema.md), [supabase-schema.sql](../database/supabase-schema.sql) (`end_use_nodes`)

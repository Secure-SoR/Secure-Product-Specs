# Lovable prompt: Dashboards filter bar + Data Centre dashboards

**Use this when:** Extending the existing Dashboards module with (1) a filter bar (Asset Type → Property) and route params, and (2) a new Data Centre dashboard variant. Do not replace or change existing office dashboards.

**Backend references:** [APP-ROUTE-MAP.md](APP-ROUTE-MAP.md) § Dashboards module; [specs/secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md) §5; [specs/implementation-guide-phase-2-dc.md](specs/implementation-guide-phase-2-dc.md); [database/schema.md](database/schema.md) (properties.asset_type, dc_metadata, data_library_records).

---

## Task 1 — Add filter bar to the Dashboards module

At the **top** of the Dashboards module add two **chained** dropdowns:

1. **First dropdown — Asset Type:** Dynamically populated from the existing property type taxonomy (Data Centre, Office, Retail, Industrial, etc.). Source: distinct values of `properties.asset_type` in the account, or the app’s canonical asset type list if you have one.
2. **Second dropdown — Property:** Dynamically populated based on the selected asset type — list only properties where `asset_type` matches the selection (from DB).

When a combination is selected, render the dashboard that corresponds to that asset type. **Existing dashboards** (e.g. Office) must load when their asset type is selected — **do not modify** them.

**Routes:** Check existing dashboard routes first. **Extend** them with **asset type** and **property** as params (query or path), e.g. `?assetType=Office&propertyId=...` or path segments. Do not create duplicate or conflicting routes; extend the current entry so the same module can show Office vs Data Centre based on filter.

---

## Task 2 — Create Data Centre dashboards (new variant)

Using the **existing** dashboard component structure, layout system, and design language (do not introduce new patterns), build the **Data Centre** dashboard variant.

- **Specifications and field structure:** Use the Data Centre property sample and backend specs: [specs/secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md) §5 (Dashboard Architecture, §5.2–5.7), [specs/implementation-guide-phase-2-dc.md](specs/implementation-guide-phase-2-dc.md). Sections and KPIs must reflect Data Centre–specific specs (PUE, IT load, capacity, cooling, WUE, renewable %, ESG readiness, etc.).
- **Data:** Pull all data dynamically from existing DB records — `dc_metadata`, `properties`, `data_library_records` (and spaces/systems if needed). Where a field does **not** yet exist in the schema, use a **placeholder** in the UI and add a **code comment** flagging it as missing (e.g. `// MISSING_SCHEMA: live PUE from sensors — dc_sensor_readings not in schema yet`).

**DC data sources (existing):**

| Source | Use for |
|--------|--------|
| `dc_metadata` | target_pue, design_capacity_mw, current_it_load_mw, total_white_floor_sqm, cooling_type, power_supply_redundancy, renewable_energy_pct, water_usage_effectiveness_target, certifications, tier_level |
| `data_library_records` | Actual PUE, IT load, energy, water (filter by property_id and subject_category/name as appropriate) |
| `properties` | name, asset_type, address (for headers and context) |

---

## Constraints

- **Do not change** existing dashboards or their routes — only extend with filter and params.
- **Do not change** any UI patterns — match existing dashboard components exactly (cards, layout, typography).
- Dashboards are **read-only** (no edit/delete of data from dashboard).
- **Check agent memory** (and existing dashboard code) for dashboard logic before writing anything new — reuse hooks, components, and data fetches where possible.

---

## Prompt to paste into Lovable

```
Dashboards module — two tasks. Do not replace or modify existing office dashboards.

**1) Filter bar**
- At the top of the Dashboards module add two chained dropdowns: (1) Asset Type — options from property type taxonomy (Data Centre, Office, Retail, Industrial, etc.), e.g. distinct properties.asset_type; (2) Property — list properties where asset_type = selected type.
- On selection, render the dashboard for that asset type. Existing office dashboards load when Office (+ optional property) is selected; do not change them.
- Extend existing dashboard routes with asset type and property as params (query or path). Check current routes first; extend, do not duplicate.

**2) Data Centre dashboards**
- Add Data Centre dashboard variant using the same component structure, layout, and design as existing dashboards. Follow backend specs: docs/specs/secure-dc-spec-v2.md §5 and docs/specs/implementation-guide-phase-2-dc.md. Sections/KPIs: PUE, IT load, capacity utilisation, cooling, WUE, renewable %, ESG readiness — from dc_metadata and data_library_records. All data from DB; where a field is not in schema, show placeholder and add code comment: // MISSING_SCHEMA: <description>.
- Read-only. Reuse existing dashboard logic and components.
```

---

## Output checklist (after implementing in Lovable)

When done, list in the backend (or in chat):

1. **Files modified or created** — link each file (or path) and state whether modified or created.
2. **Missing schema fields** — any KPI or field that required a placeholder because it is not yet in the schema; add a code comment in the app and list here so a migration can be added later.

**Missing schema fields (pre-emptive list from backend):**

| Field / concept | Status | Note |
|-----------------|--------|------|
| Live PUE / real-time sensor PUE | Not in schema | `dc_sensor_readings` table is Phase 3. Use placeholder + comment; data from `data_library_records` where available. |
| PUE / IT load in data_library_records | Convention only | No dedicated table. Use `subject_category` and/or `name` to identify PUE, IT load (MW), cooling energy records. If no convention exists, document or use placeholder. |
| Capacity utilisation % | Derived | current_it_load_mw ÷ design_capacity_mw from dc_metadata; both columns exist. |
| WUE actual | From data_library_records | Water + energy records; no dedicated WUE column. Derive or placeholder. |

All other DC dashboard KPIs in §5 can be sourced from `dc_metadata` and `data_library_records` as documented above; add placeholders only where a concrete field is missing.

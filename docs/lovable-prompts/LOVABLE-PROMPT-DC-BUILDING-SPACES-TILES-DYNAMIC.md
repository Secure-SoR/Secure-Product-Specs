# Lovable prompt: Data Centre — Building Spaces summary tiles (use shared component)

**Use this when:** On the Data Centre property space creation page, the **Building Spaces** section shows summary tiles that are static/hardcoded (e.g. 0.0k, 0%) and do not update when spaces are created, edited, or deleted. Other property types use a shared component that updates reactively.

**Goal:** Use the same shared Building Spaces summary component as other property types; wire it to Data Centre space records so all five tiles update reactively. Do not rebuild or modify the shared component.

**Backend:** Spaces data from `spaces` table, filtered by `property_id`. For DC, also respect `tenancy_type` if the page is scoped (see [LOVABLE-PROMPT-TENANCY-TYPE-SELECTOR-AND-SPACE-SCOPE.md](LOVABLE-PROMPT-TENANCY-TYPE-SELECTOR-AND-SPACE-SCOPE.md)). Schema: [database/schema.md](database/schema.md) §3.5 spaces.

---

## Context

In the Data Centre property, the space creation page has a section called **Building Spaces** containing summary tiles that are currently static/hardcoded:

- Building Spaces — showing `0.0k`
- Total Area (m²) — showing `0.0k`
- Base Building — showing `0.0k`
- Tenant Spaces — showing `0.0k`
- LL / Tenant Control — showing `0% / 0%`

These same tiles exist in the space creation page of other property types and are **fully dynamic** there — they reactively update as spaces are populated. The Data Centre implementation is not using the shared component and is instead hardcoded.

---

## Task

1. **Locate** the shared Building Spaces summary tile component used in the other property types — do not rebuild it, use exactly that component.
2. **Replace** the hardcoded Data Centre version with the shared component.
3. **Wire** the data bindings to the correct Data Centre space records in the DB, following the same pattern used by the other property types (same fetch: `spaces` filtered by current `property_id`; if DC uses tenancy_type scoping, filter by current `tenancy_type` as well).
4. **Verify** all five tiles update reactively when spaces are created, edited, or deleted under the Data Centre property.

---

## Constraints

- Do not modify the shared component — only consume it.
- Do not change any UI, layout, or styling.
- Do not touch other property type implementations.
- Check agent memory (and existing code) for Building Spaces summary logic before writing anything new.

---

## Prompt to paste into Lovable

```
Data Centre property — space creation page: the Building Spaces section has summary tiles that are static/hardcoded (Building Spaces 0.0k, Total Area 0.0k, Base Building 0.0k, Tenant Spaces 0.0k, LL/Tenant Control 0%/0%). Other property types use a shared Building Spaces summary component that updates reactively.

1) Locate the shared Building Spaces summary tile component used for other property types. Do not rebuild it.
2) Replace the hardcoded Data Centre Building Spaces tiles with that shared component.
3) Wire the data to the same source as other property types: spaces from the DB for the current property (e.g. supabase.from('spaces').select('*').eq('property_id', propertyId); if the DC page is scoped by tenancy_type, filter by tenancy_type as well so the tiles match the visible list).
4) Ensure all five tiles (Building Spaces count, Total Area, Base Building, Tenant Spaces, LL/Tenant Control) update reactively when spaces are created, edited, or deleted on the Data Centre property.

Do not modify the shared component, UI, layout, or styling. Do not change other property types. Reuse the same fetch/state pattern as the working property types so one refetch updates both the list and the tiles.
```

---

## Output (to complete after implementation in Lovable)

Fill this in after applying the prompt so the backend has a record of what was used and changed.

| Item | Value |
|------|--------|
| **Shared component file** | *(Link to the shared Building Spaces summary component — e.g. path in Lovable repo)* |
| **Data Centre file(s) modified** | *(Link each modified file that was DC-specific and now consumes the shared component)* |
| **Data source** | `spaces` table, filtered by `property_id` = current DC property; optionally `tenancy_type` = current selection if page is scoped. Same as other property types. |

**Data source per tile (backend reference):**

| Tile | Derivation from `spaces` |
|------|---------------------------|
| Building Spaces | Count of rows (or distinct spaces) for property. |
| Total Area (m²) | Sum of `area` for property (nullable; treat null as 0). |
| Base Building | Count where `space_class = 'base_building'`. |
| Tenant Spaces | Count where `space_class = 'tenant'`. |
| LL / Tenant Control | Percentages derived from `control`: e.g. landlord_controlled vs tenant_controlled (and optionally shared); same logic as other property types. |

Schema: [database/schema.md](database/schema.md) §3.5 — `spaces.property_id`, `spaces.space_class`, `spaces.control`, `spaces.area`, `spaces.tenancy_type`.

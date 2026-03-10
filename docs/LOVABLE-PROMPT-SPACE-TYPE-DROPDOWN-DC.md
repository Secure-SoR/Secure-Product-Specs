# Lovable prompt: Add data centre space_type values to space type dropdown

**Use this when:** The space form has a space type dropdown (or select). You need it to include the **data centre** space types when the property is a data centre, so users can assign types like data_hall, data_suite, plant_room, etc.

**Taxonomy:** [docs/data-model/space-types-taxonomy.md](data-model/space-types-taxonomy.md). **Spec:** [docs/specs/secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md) §3.3.

---

## Prompt to paste into Lovable

```
The space type dropdown (or allowed values for space_type when creating/editing a space) must include the data centre space types when the current property's asset_type is 'data_centre'.

Add these options to the space type dropdown when property.asset_type === 'data_centre' (in addition to any existing options like common_area, shared_space, meeting_room, office):

- data_hall — Primary raised-floor data hall / white floor
- data_suite — Sub-division of a hall (caged or open)
- data_pod — Pre-fabricated or modular POD
- data_row — Row within a hall or suite
- plant_room — Mechanical or electrical plant room
- cooling_plant — Cooling tower yard, CRAC/CRAH room
- ups_room — UPS / battery room
- generator_room — Diesel or gas generator room
- hv_room — High voltage switchroom
- lv_room — Low voltage switchroom
- loading_bay — Loading / receiving area
- security_gatehouse — Security post
- noc — Network Operations Centre
- meet_me_room — Cross-connect / colocation meet-me room

Store the value in spaces.space_type exactly as above (e.g. data_hall, plant_room). You can show a human-readable label in the UI (e.g. "Data hall", "Plant room") while saving the value. When the property is not a data centre, keep the existing space type options; when it is a data centre, show both the existing options and these 14 data centre types (or only these if you prefer a dedicated DC list).
```

---

## Backend

- **Taxonomy doc:** [docs/data-model/space-types-taxonomy.md](data-model/space-types-taxonomy.md) lists all allowed space_type values (general + data centre). No DB migration — space_type remains free text.

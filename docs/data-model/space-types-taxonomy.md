# Space types taxonomy (spaces.space_type)

**Purpose:** Allowed values for `spaces.space_type` in the UI (dropdown or allowed list). The DB column is free text; this doc is the source of truth for consistent labelling and for data centre templates.

**Schema:** [../database/schema.md](../database/schema.md) §3.5 spaces. **DC spec:** [../specs/secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §3.3.

---

## 1) General / office (all asset types)

| space_type value   | Description |
|--------------------|-------------|
| common_area        | Common / shared areas |
| shared_space       | Shared space |
| meeting_room       | Meeting room |
| office             | Office space |
| other              | Other (unspecified) |

---

## 2) Data centre (asset_type = data_centre)

When the property is a data centre, the space type dropdown (or allowed values) should also include:

| space_type value   | Description |
|--------------------|-------------|
| data_hall          | Primary raised-floor data hall / white floor |
| data_suite         | Sub-division of a hall (caged or open) |
| data_pod           | Pre-fabricated or modular POD |
| data_row           | Row within a hall or suite |
| plant_room         | Mechanical or electrical plant room |
| cooling_plant      | Cooling tower yard, CRAC/CRAH room |
| ups_room           | UPS / battery room |
| generator_room     | Diesel or gas generator room |
| hv_room            | High voltage switchroom |
| lv_room            | Low voltage switchroom |
| loading_bay        | Loading / receiving area |
| security_gatehouse | Security post |
| noc                | Network Operations Centre |
| meet_me_room       | Cross-connect / colocation meet-me room |

**Implementation:** In the app, when `property.asset_type === 'data_centre'`, show the combined list (general + data centre) in the space type field. When asset type is not data_centre, show only the general list (or both; both are valid in the DB).

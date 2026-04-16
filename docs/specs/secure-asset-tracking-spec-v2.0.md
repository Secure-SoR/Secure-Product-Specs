# SECURE SoR — Asset Tracking Module
## Product Specification v2.0

| Field | Value |
|---|---|
| **Status** | DRAFT v2.0 |
| **Supersedes** | v1.0 (March 2026) |
| **Date** | March 2026 |
| **Module** | Asset Tracking (AT) |
| **Platform** | Secure SoR |
| **Pilot Facility** | Mining Site A — Kolomela Mine (Iron Ore), Postmasburg, Northern Cape |
| **Hardware Partner** | INGY BV / BlueUp (Wirepas Mesh + DALI lighting) |
| **Owner** | Secure Platform Team |

---

## 0. Executive Summary

The Asset Tracking Module (AT Module) is a first-class module within the Secure System of Record (SoR) platform. It adds real-time and historical positioning of people and assets inside complex physical environments — starting with underground mining — on top of Secure's existing property hierarchy, user management, audit trail, and device management.

The pilot deployment is Kolomela Mine (Iron Ore), Postmasburg, Northern Cape, South Africa. Primary use case: personnel safety tracking underground (position + panic). Secondary: equipment location, time-and-attendance, geofencing alerts, and smart lighting control tied to occupancy. Hardware: INGY BV BlueUp Wirepas Mesh tags and DALI luminaires.

**Design Principle (unchanged from v1.0):** Asset Tracking is a module on top of Secure SoR. It does not replace or duplicate existing platform entities. Every tracking record is persisted to the database for full audit-readiness.

**Key v2.0 changes from v1.0:**

- Sensor domain is split into two explicitly separate models: fixed building sensors live in `Property > Physical & Technical > Sensors`; mobile asset tags live in `Asset Tracking > Tracking Sensors`. These must never be merged.
- Asset type governance is formalised: account-level `at_asset_types` is the master taxonomy; property-specific types are optional extensions only.
- AT tracking devices (tags, gateways) are **not** stored in the existing `systems` table. They use dedicated AT tables to prevent collision with existing building-systems and meter workflows.
- DALI lighting fixtures remain in `systems` (system_category: Lighting) with an AT-specific live-state cache (`at_device_state`). This is a controlled sharing boundary, not a general merge.
- Floors and zone polygons are stored in dedicated AT tables (`at_floors`, `at_zones`) referencing `properties`. The existing `spaces` table is unchanged.
- Navigation follows the canonical Secure URL structure: `/asset-tracking`, `/asset-tracking/admin`, `/asset-tracking/analytics`.
- A Phase 0 validation gate is added before any schema migration.
- Non-regression guardrails are explicit: Data Library, Data Centre dashboards, and Physical & Technical screens are untouched.

The AT Module covers six capability areas:

- Real-time position tracking of personnel and equipment on floor plans
- Geofencing — restricted areas, out-of-zone detection, prolonged idle, panic
- Tracking device management — Wirepas tags and gateways (AT-owned tables)
- Smart lighting control integrated with occupancy and daylight harvesting (DALI via `systems` + `at_device_state`)
- Historical playback and dwell-time reporting
- Alert management with full audit persistence via `audit_events`

---

## 1. Context and Strategic Fit

### 1.1 Why Asset Tracking on Secure SoR

Asset and personnel tracking inside complex built environments generates high-frequency position data that must be audit-ready, tied to real-world spaces, and analysable over time. Secure SoR already provides the authoritative record for property hierarchy, users, devices, and audit events. Building the AT Module on this foundation means:

- Position events are always referenced to a named zone (not floating raw coordinates).
- Alerts are persisted to the same `audit_events` infrastructure used by all Secure modules.
- Workers are the same `auth.users` records already on the platform — no separate identity silo.
- AT floor plans and zone polygons reference `properties` but do not modify the existing `spaces` table or its FK relationships.
- DALI lighting telemetry reuses the existing `systems` record (the canonical source for the fixture) and writes live state to `at_device_state` (AT-owned, fast-read cache) — no duplication of the fixture definition.

### 1.2 Pilot: Kolomela Underground Mine

| Attribute | Detail |
|---|---|
| Facility Name | Mining Site A |
| Address | Kolomela Mine (Iron Ore): Postmasburg, Northern Cape, South Africa |
| Facility Type | Mine / Underground |
| Timezone | (UTC+02:00) EET |
| Capacity | 20 tracked assets/personnel (POC scope) |
| Primary Use Case | Human safety tracking underground (position + panic) |
| Secondary Use Cases | Equipment location, time-and-attendance, smart lighting |
| Hardware | BlueUp Wirepas tags + DALI luminaires (INGY BV) |
| Positioning Technology | Wirepas Mesh RTLS |

### 1.3 Hardware Stack

| Layer | Device / Component | Role |
|---|---|---|
| Asset Tags | BlueUp Wirepas tags (badge / clip) | Worn by workers or attached to equipment; broadcast position beacons; include panic button |
| Gateways | Wirepas gateway (border router) | Bridge between Wirepas mesh and IP network; forward position events to backend |
| Lighting | DALI luminaires with INGY BV driver | Smart lighting with motion detection, daylight harvesting (ALS), occupancy scenes |
| Positioning | Wirepas Mesh RTLS engine | Computes (x, y) from mesh signal strengths; delivered as JSON stream |
| Backend | Secure SoR (Supabase Phase 1 / Azure Phase 2) | Receives events, persists to DB, drives dashboards, alerts, reports |

> **INGY BV constraint (from email thread, Feb 2026):** Lights are mains-powered — no battery or voltage field. Actual lux is technically impossible to measure; show energy consumption in watts. Daylight Harvesting active: brightness slider must be greyed out. Behaviour mode shown as chips (Motion, Daylight, Eco, Scene).

---

## 2. Sensor Domain Split (Mandatory Boundary)

This section establishes the most critical architectural boundary in the AT Module. **This boundary must never be collapsed.**

### 2.1 Two Separate Sensor Domains

| Dimension | Property › Physical & Technical › Sensors | Asset Tracking › Tracking Sensors |
|---|---|---|
| **What** | Fixed infrastructure sensors: BMS, IoT environmental, HVAC, energy, IAQ, occupancy counters | Mobile asset tags: Wirepas tags worn by workers or attached to equipment |
| **Examples** | Temperature/humidity sensors, energy submeters, CO₂ sensors, occupancy sensors (people-counting), gateway devices listed in the building systems register | BlueUp badge, BlueUp clip, any Wirepas RTLS tag |
| **DB Table** | `systems` (system_category: Monitoring / Power / HVAC) | `at_asset_tags` (AT-owned table, introduced in §3) |
| **UI Location** | `Property > Physical & Technical > Sensors` (existing Secure screen) | `Asset Tracking > Tracking Sensors` (new AT screen) |
| **API Namespace** | Existing `/systems`, `/meters` endpoints | New `/at/tags`, `/at/gateways` endpoints |
| **Owner Entity** | Building / landlord / property | Mobile — assigned to a specific `at_asset` |
| **Position Semantics** | Fixed position (known at install time) | Dynamic position (updated continuously by RTLS) |
| **Data Flow** | BMS / IoT connectors → `data_library_records` or `systems` telemetry | Wirepas gateway → `at_position_events` |

### 2.2 Enforcement Rules

1. An `at_asset_tag` record must **never** also appear as a row in `systems`. These are exclusive.
2. The `at_asset_tags` ingest endpoint (`POST /at/ingest/position`) must reject payloads that reference a `systems.id` as the tag identifier.
3. The `systems` table must not gain any column prefixed `at_` — AT state for DALI lights is stored in `at_device_state`, not on `systems` rows.
4. The "Sensors" tab under `Property > Physical & Technical` and the "Tracking Sensors" tab under `Asset Tracking` must be rendered from different data sources and must not share a component.
5. Wirepas gateways (network infrastructure) are stored in `at_gateways` (AT-owned). They are not stored in `systems`.

> **Rationale:** The existing `systems` table drives building-systems workflows (Data Library evidence linking, Boundary Agent context, energy allocation, meter assignment). Contaminating it with mobile RTLS tags would break those workflows and the agent context payload.

### 2.3 DALI Lighting: Controlled Shared Boundary

DALI light fixtures are an exception to the strict separation because they are both **fixed infrastructure** (legitimately owned by `systems`) and **AT-actuated** (controlled by occupancy events from the AT Module).

The boundary is:

- **Fixture definition** → `systems` row (system_category: `Lighting`, system_type: `DALILight`). This is the canonical, authoritative record. It is read by Physical & Technical, energy reporting, and the Building Systems Register. **AT does not write to this row.**
- **Live telemetry state** → `at_device_state` row (AT-owned). Upserted on every DALI telemetry event. Used exclusively by the AT Module UI (Devices › Lights tab). Energy reporting reads `at_device_state.power_watts` via a read-only join — it does not own this table.
- **Control commands** → issued via a separate `at_dali_commands` queue, not via `systems` update.

---

## 3. Asset Type Governance

### 3.1 Canonical Rule

`at_asset_types` defines the master taxonomy of trackable asset types. The hierarchy is:

1. **Account-level types** (`property_id IS NULL`): the default master taxonomy, visible and usable across all properties in the account. Created and managed in `Asset Tracking > Administration > Asset Types`.
2. **Property-specific types** (`property_id IS NOT NULL`): optional extensions for a specific facility. They supplement — never replace — account-level types. They appear only for that property's asset registry.

A property's asset registry (`at_assets`) references `at_asset_types.id`. The query for valid types for a property is:

```sql
SELECT * FROM at_asset_types
WHERE account_id = $account_id
  AND (property_id IS NULL OR property_id = $property_id)
ORDER BY property_id NULLS FIRST, name;
```

Account-level types appear first. Property-specific types appear below with a visual indicator ("Custom to this facility").

### 3.2 Pre-seeded Account-Level Types (Mining POC)

These are created at account setup for accounts with `facility_type = mine_underground`:

| Name | Category | Icon Key |
|---|---|---|
| Worker | workers | `icon_worker` |
| Drilling Jumbos | drilling_equipments | `icon_drilling_jumbo` |
| Jacklegs | drilling_equipments | `icon_jackleg` |
| Rocker Shovel Loaders | loading_equipments | `icon_rsl` |
| First Aid Box | medical_kit | `icon_first_aid` |

### 3.3 Governance Rules

- Icon keys are **immutable after creation**. A type's icon can never be changed because it is used across historical position playback, maps, and analytics where visual consistency is mandatory.
- Deleting an account-level type is blocked if any `at_assets` row references it via `asset_type_id`.
- Deleting a property-specific type is blocked if any `at_assets` row for that property references it.
- Renaming is permitted; the `id` is the stable foreign key reference, not the name.

### 3.4 UI Placement

| Screen | Path | Action |
|---|---|---|
| Asset Categories | `Asset Tracking > Administration > Asset Categories` | Create / edit / delete categories (scope: account or property) |
| Asset Types | `Asset Tracking > Administration > Asset Types` | Create / edit types with icon (immutable after save); toggle account vs property scope |
| Asset Registry | `Asset Tracking > Assets` | Register individual asset instances referencing account- or property-level types |

---

## 4. Systems Table Boundary

### 4.1 What AT Owns vs What Building Systems Owns

| Artefact | Owner | Table | Notes |
|---|---|---|---|
| DALI light fixture definition | Building Systems | `systems` | system_category: Lighting, system_type: DALILight. AT reads; never writes. |
| DALI live telemetry state | AT Module | `at_device_state` | Upserted by DALI ingest function. |
| DALI control commands | AT Module | `at_dali_commands` | Queued commands; executed by DALI ingest function; acknowledged back. |
| Wirepas gateway (border router) | AT Module | `at_gateways` | Never in `systems`. |
| Wirepas asset tag | AT Module | `at_asset_tags` | Never in `systems`. |
| Fixed building sensors | Building Systems | `systems` | OccupancySensors, EnvironmentalSensors, GatewayDevices — untouched by AT. |
| Energy meters | Building Systems | `meters` | Untouched by AT. |
| End-use nodes | Building Systems | `end_use_nodes` | Untouched by AT. |

### 4.2 Permitted Read-Joins from AT to Building Systems

AT is allowed to **read** from `systems` in the following cases only:

1. Join `at_device_state.system_id → systems.id` to display the light fixture's name and `serves_space_ids` in the Devices › Lights tab.
2. Join `systems.id` to derive which physical space a DALI fixture is associated with (for lighting-by-room grouping).

AT must not issue UPDATE or DELETE against any `systems`, `meters`, `end_use_nodes`, or `data_library_records` row.

### 4.3 Non-Regression Guard: Do Not Break Existing Flows

The following existing Secure workflows must continue working identically after AT Module deployment:

| Workflow | Tables Used | Guard |
|---|---|---|
| Data Library evidence upload | `data_library_records`, `documents`, `evidence_attachments` | No AT migration touches these tables |
| Building Systems Register | `systems`, `end_use_nodes` | AT does not add columns to `systems`; new `system_type` values are additive |
| Meter CRUD | `meters` | No AT migration touches `meters` |
| Boundary Agent context | `systems`, `end_use_nodes`, `spaces`, `properties` | AT does not modify `spaces` schema; AT adds new standalone tables |
| Data Centre dashboards | `dc_metadata`, `dc_sensor_readings` | Completely separate module; no AT table overlaps |
| Energy/carbon reports | `data_library_records`, `audit_events` | AT appends to `audit_events`; never modifies existing rows |

---

## 5. Spaces and Floor Plan Boundary

### 5.1 Problem Statement

v1.0 proposed adding `zone_type`, `floor_plan_polygon`, `floor_plan_image_url`, and `gps_calibration` directly to the `spaces` table. This creates two problems:

1. **Schema coupling:** The `spaces` table is used by the Boundary Agent, building systems allocation, energy reporting, and GRESB reporting. Adding AT-specific columns to it pollutes those workflows and makes RLS policies more complex.
2. **Semantic mismatch:** A Secure `space` represents a logical occupancy boundary (tenant demise, base building, sub-space) with control and allocation semantics. An AT zone represents a physical polygon on a floor plan image. These are related but not identical — an AT zone may not correspond 1:1 to a Secure space.

### 5.2 Preferred Approach: AT-Specific Floor and Zone Tables

AT uses two standalone tables (`at_floors`, `at_zones`) that reference `properties.id` directly. This fully isolates AT schema from the existing `spaces` table.

```
properties.id
    └── at_floors.property_id   (one row per floor plan / level)
            └── at_zones.floor_id   (one row per polygon zone)
```

An `at_zone` may optionally reference a `spaces.id` to link to the canonical Secure space for cross-module reporting (e.g. "assets in the Storage Office"). This link is **optional and read-only from the AT side** — the `spaces` row is not modified.

**Preferred approach table definitions:** see §6.2 (`at_floors`) and §6.3 (`at_zones`).

### 5.3 Fallback Approach (if Preferred is Blocked)

If the Lovable implementation cannot support two new AT floor/zone tables in the required timeframe, the fallback is to add AT-specific columns to `spaces` with strict isolation rules:

- New columns: `at_zone_type`, `at_floor_plan_polygon` (jsonb), `at_floor_plan_image_url`, `at_gps_calibration` (jsonb). All nullable; all prefixed `at_` to signal module ownership.
- **AT APIs read and write only the `at_`-prefixed columns.** They must never modify `name`, `space_class`, `control`, `area`, `floor_reference`, `in_scope`, `net_zero_included`, `gresb_reporting`.
- The AT module UI must render zone polygons from `at_floor_plan_polygon` only; it must not use or render the logical space hierarchy used by the rest of Secure.
- The Building Systems Register, Boundary Agent, and energy allocation workflows must not read or depend on the `at_`-prefixed columns.

**The preferred approach (§5.2) is strongly recommended.** Use the fallback only if a hard technical constraint prevents creating `at_floors` and `at_zones`.

---

## 6. Database Schema

### 6.1 Schema Design Principles

- Every AT table includes `account_id` for RLS — identical pattern to all existing Secure SoR tables.
- Position events (`at_position_events`) are append-only. No UPDATE or DELETE within the 90-day retention window.
- Alerts (`at_alerts`) transition through states only (unread → acknowledged → dismissed). Never deleted.
- Every alert status change writes an `audit_events` row with `actor_id`, `timestamp`, `before_state`, `after_state`.
- DALI fixture definitions live in `systems`; DALI telemetry state lives in `at_device_state`. No column is duplicated across both.
- Wirepas gateways and tags are in `at_gateways` and `at_asset_tags` respectively. Never in `systems`.
- Floor plan images: Supabase Storage bucket `at-floor-plans` (separate from `secure-documents`); only the storage path in DB.

### 6.2 `at_floors`

One row per physical floor level in a facility. This replaces the v1.0 approach of adding columns to `spaces`.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | Auto-generated |
| account_id | uuid FK → accounts | NO | RLS scope |
| property_id | uuid FK → properties | NO | Parent facility |
| name | text | NO | Display name, e.g. "Level 1" |
| level_index | integer | YES | Numeric order (0 = ground), for sorting |
| floor_plan_image_url | text | YES | Storage path in `at-floor-plans` bucket |
| floor_plan_width_px | integer | YES | Image width in pixels (for coordinate scaling) |
| floor_plan_height_px | integer | YES | Image height in pixels |
| coord_system | text | NO | `pixel` \| `local_metres` \| `gps` |
| gps_calibration | jsonb | YES | Array of `{pixel_x, pixel_y, lat, lng}` anchor points |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

### 6.3 `at_zones`

One row per zone polygon on a floor plan. Zones drive geofencing alert rules.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | Auto-generated |
| account_id | uuid FK → accounts | NO | RLS scope |
| floor_id | uuid FK → at_floors | NO | Parent floor |
| property_id | uuid FK → properties | NO | Denormalised for fast RLS queries |
| name | text | NO | Display name, e.g. "Storage Office", "Strong Room" |
| zone_type | text | NO | `public` \| `restricted` \| `staff_entry` |
| polygon | jsonb | NO | Array of `{x, y}` vertices in floor plan coordinate space |
| spaces_id | uuid FK → spaces | YES | Optional link to canonical Secure space (read-only cross-reference) |
| description | text | YES | |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

Index: `(floor_id)`, `(property_id, zone_type)`.

### 6.4 `at_asset_types`

Account-level and property-specific asset type taxonomy. See §3 for governance rules.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK → accounts | NO | RLS scope |
| property_id | uuid FK → properties | YES | NULL = account-level master; set = property extension |
| name | text | NO | e.g. "Worker", "Drilling Jumbos" |
| category | text | NO | `workers` \| `drilling_equipments` \| `loading_equipments` \| `medical_kit` |
| icon_key | text | NO | Immutable after creation |
| description | text | YES | |
| created_at | timestamptz | NO | |

Unique: `(account_id, property_id, name)`. `property_id` nullable so account-level types are `(account_id, NULL, name)`.

### 6.5 `at_assets`

Individual trackable asset instances (persons or equipment).

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK → accounts | NO | RLS scope |
| property_id | uuid FK → properties | NO | Facility |
| name | text | NO | Display name, e.g. "Chris", "JL-01" |
| asset_type_id | uuid FK → at_asset_types | YES | References type; NULL if type deleted |
| user_id | uuid FK → auth.users | YES | Linked platform user account (workers only) |
| default_zone_id | uuid FK → at_zones | YES | Home zone |
| tag_id | uuid FK → at_asset_tags | YES | Currently assigned tracking tag (NULL if unassigned) |
| status | text | NO | `active` \| `inactive` \| `in_maintenance` |
| serial_number | text | YES | Physical serial or employee ID |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

### 6.6 `at_asset_tags`

Wirepas sensor tags. **Not stored in `systems`.** One tag → one asset at a time.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK → accounts | NO | RLS scope |
| property_id | uuid FK → properties | NO | |
| wirepas_node_id | text | NO | Unique within the mesh network |
| mac_address | text | YES | Hardware MAC |
| tag_model | text | YES | e.g. "BlueUp Badge", "BlueUp Clip" |
| has_panic_button | boolean | NO | Whether tag model includes panic button |
| panic_button_action | text | YES | `panic` \| `movement_detection` \| `custom_scene` |
| battery_level_pct | numeric | YES | Last reported battery % |
| firmware_version | text | YES | |
| status | text | NO | `active` \| `inactive` \| `unassigned` |
| assigned_asset_id | uuid FK → at_assets | YES | Current assignment; NULL if unassigned |
| last_seen_at | timestamptz | YES | Timestamp of last received position event |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

Unique: `(property_id, wirepas_node_id)`. Partial unique on `assigned_asset_id WHERE assigned_asset_id IS NOT NULL` — enforces one active assignment per asset.

### 6.7 `at_gateways`

Wirepas border routers. **Not stored in `systems`.**

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK → accounts | NO | RLS scope |
| property_id | uuid FK → properties | NO | |
| floor_id | uuid FK → at_floors | YES | Floor gateway is installed on |
| name | text | NO | Display name |
| wirepas_gateway_id | text | NO | Wirepas network gateway ID |
| mac_address | text | YES | |
| firmware_version | text | YES | |
| ip_address | text | YES | Last known IP |
| online | boolean | NO | `true` if heartbeat received within last 2 minutes |
| connected_node_count | integer | YES | Number of Wirepas nodes currently reporting |
| last_heartbeat_at | timestamptz | YES | |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

### 6.8 `at_position_events`

Time-series table of raw position fixes. Append-only. This is the highest write-volume table.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK | NO | RLS scope |
| property_id | uuid FK | NO | |
| asset_id | uuid FK → at_assets | NO | |
| tag_id | uuid FK → at_asset_tags | YES | Tag that generated event |
| floor_id | uuid FK → at_floors | YES | Floor (from gateway mapping) |
| zone_id | uuid FK → at_zones | YES | Zone derived from polygon containment check |
| x_pos | numeric | YES | X in floor plan coordinate space |
| y_pos | numeric | YES | Y in floor plan coordinate space |
| accuracy_m | numeric | YES | Estimated accuracy in metres |
| source | text | NO | `wirepas` \| `manual` \| `simulated` |
| recorded_at | timestamptz | NO | Timestamp from device/gateway |
| created_at | timestamptz | NO | DB insert time |

**Required indexes:**
- `(asset_id, recorded_at DESC)` — latest position per asset
- `(property_id, floor_id, recorded_at DESC)` — floor-level live view
- `(asset_id, recorded_at)` — historical playback range scans
- `(property_id, zone_id, recorded_at)` — dwell time and zone occupancy queries

**Retention:** Raw events kept 90 days. Scheduled job archives to `at_position_archive` (hourly aggregates) then deletes raw rows. `at_position_archive` schema: `(asset_id, floor_id, zone_id, hour_bucket timestamptz, event_count int, avg_x numeric, avg_y numeric)`.

### 6.9 `at_alerts`

Persisted alert records. Status transitions only — never deleted.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK | NO | RLS scope |
| property_id | uuid FK | NO | |
| asset_id | uuid FK → at_assets | NO | |
| alert_type | text | NO | `restricted_entry` \| `out_of_zone` \| `prolonged_idle` \| `panic` \| `custom` |
| zone_id | uuid FK → at_zones | YES | Zone where alert was triggered |
| floor_id | uuid FK → at_floors | YES | |
| message | text | NO | e.g. "Asset has been idle for 1722 minutes" |
| idle_minutes | integer | YES | For prolonged_idle: minutes since last movement |
| status | text | NO | `unread` \| `acknowledged` \| `dismissed` |
| acknowledged_by | uuid FK → auth.users | YES | |
| acknowledged_at | timestamptz | YES | |
| triggered_at | timestamptz | NO | When condition first detected |
| created_at | timestamptz | NO | |

Index: `(property_id, status)`, `(asset_id, triggered_at DESC)`, `(account_id, alert_type, status)`.

Every INSERT to `at_alerts` and every UPDATE to `at_alerts.status` must write a corresponding row to `audit_events`:

```sql
INSERT INTO audit_events (account_id, entity_type, entity_id, action, actor_id, before_state, after_state)
VALUES ($account_id, 'at_alerts', $alert_id, 'create'|'update', $actor_id, $before, $after);
```

### 6.10 `at_device_state`

Live telemetry cache for DALI light fixtures. AT-owned. Updated on every DALI telemetry event via upsert.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK | NO | RLS scope |
| system_id | uuid FK → systems | NO | References the DALI fixture's `systems` row (read-only cross-reference) |
| online | boolean | NO | Reachable in last 2 minutes |
| light_on | boolean | YES | Current on/off state |
| dim_level_pct | numeric | YES | 0–100% |
| als_value | numeric | YES | Raw ALS reading (not calibrated to Lux) |
| daylight_harvesting_active | boolean | YES | DH currently controlling brightness |
| daylight_harvesting_pct | numeric | YES | % of target met by natural light |
| behaviour_mode_index | integer | YES | Active behaviour mode (see §8 Q8 for enum) |
| power_watts | numeric | YES | Current energy consumption in watts |
| last_updated_at | timestamptz | NO | Last telemetry timestamp |

Unique: `(system_id)` — one state row per fixture.

### 6.11 `at_dali_commands`

Control commands queued for DALI devices. Decouples UI action from device execution.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK | NO | RLS scope |
| system_id | uuid FK → systems | NO | Target DALI fixture |
| command_type | text | NO | `set_on_off` \| `set_dim_level` \| `set_scene` \| `set_dh_enabled` |
| payload | jsonb | NO | Command parameters, e.g. `{"on": true}` or `{"dim_level_pct": 80}` |
| status | text | NO | `queued` \| `sent` \| `acknowledged` \| `failed` |
| created_by | uuid FK → auth.users | YES | User who issued the command |
| created_at | timestamptz | NO | |
| sent_at | timestamptz | YES | |
| acknowledged_at | timestamptz | YES | |

### 6.12 `at_facility_settings`

Per-facility AT configuration. One row per property with `at_enabled = true`.

| Column | Type | Nullable | Description |
|---|---|---|---|
| id | uuid PK | NO | |
| account_id | uuid FK | NO | RLS scope |
| property_id | uuid FK → properties | NO | UNIQUE — one row per facility |
| position_update_interval_sec | integer | NO | Default 15; range 5–60 |
| prolonged_idle_threshold_min | integer | NO | Default 60 |
| panic_button_default_action | text | NO | `panic` \| `movement_detection` \| `custom_scene` |
| out_of_zone_enabled | boolean | NO | Default true |
| restricted_entry_enabled | boolean | NO | Default true |
| dali_motion_timeout_sec | integer | YES | Seconds before lights off after last motion |
| dali_dh_setpoint_als | integer | YES | ALS target for DH setpoint |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

### 6.13 Extensions to Existing Tables (Minimal)

| Table | Column | Type | Description |
|---|---|---|---|
| `properties` | `at_enabled` | `boolean DEFAULT false` | Activates AT Module for this facility |
| `systems` | `system_type` | (existing text) | Additive: allow new value `'DALILight'` in CHECK constraint. No column added. |

**No other existing table is modified.** The v1.0 proposal to add `zone_type`, `floor_plan_polygon`, `floor_plan_image_url`, `gps_calibration` to `spaces` is withdrawn. The v1.0 proposal to add `floor_plan_coord_system` to `properties` is withdrawn (moved to `at_floors.coord_system`).

---

## 7. Navigation and UI Placement

### 7.1 URL Structure

The AT Module follows Secure's canonical route pattern. It does **not** extend the existing sidebar items (Facility Profile, Floors & Spaces, etc.) with AT-specific content. Instead, AT has its own top-level module section.

| Route | Page | Access |
|---|---|---|
| `/asset-tracking` | AT Module landing — select facility (if multi-property account) | All AT roles |
| `/asset-tracking/live` | Live Tracking — floor plan + asset positions + alert sidebar | Viewer, Manager, Admin |
| `/asset-tracking/alerts` | Alert Management — history, filters, acknowledge/dismiss | Viewer, Manager, Admin |
| `/asset-tracking/devices` | Device Management — Lights, Gateways, Tracking Sensors tabs | Manager, Admin |
| `/asset-tracking/analytics` | Reporting — dwell time, zone occupancy, T&A, alert summary | Manager, Admin |
| `/asset-tracking/analytics/playback` | Historical Playback — asset replay on floor plan | Manager, Admin |
| `/asset-tracking/admin` | AT Administration — floors, zones, assets, types, settings | Admin |
| `/asset-tracking/admin/floors` | Floor plan upload + zone drawing | Admin |
| `/asset-tracking/admin/assets` | Asset Registry (instances) | Admin |
| `/asset-tracking/admin/configuration` | Asset Categories + Asset Types | Admin |
| `/asset-tracking/admin/settings` | AT Facility Settings | Admin |

### 7.2 Property-Level Tab Integration

On the existing Property detail page (`/properties/:id`), a new tab "Asset Tracking" appears when `properties.at_enabled = true`. This tab is a summary entry point only: it shows the AT Readiness tile (§7.3) and links to the full `/asset-tracking/*` routes. It does not embed the full AT module inside the property page.

### 7.3 AT Readiness Tile (Property Overview and AT Landing)

| Tile | Metric | Source |
|---|---|---|
| Active Assets | `at_assets` where `status = active` | `at_assets` |
| Tracked Now | Assets with position event in last 5 min | `at_position_events` |
| Online Gateways | `at_gateways` where `online = true` | `at_gateways` |
| Unread Alerts | `at_alerts` where `status = unread` | `at_alerts` |
| Missing Tag Assignment | `at_assets` where `tag_id IS NULL AND status = active` | `at_assets` |
| System Readiness % | Floors uploaded + zones drawn + tags assigned / total expected | Computed |

### 7.4 Account Settings Integration

In Secure's Account Settings (`/account/settings`), a new section "Asset Tracking Permissions" appears when the account has at least one property with `at_enabled = true`:

- **Module Access**: toggle AT Module on/off per user (maps to `account_memberships` with an `at_access` flag — see §6.13 extended).
- **AT Role Assignment**: Viewer / Manager / Admin (separate from main platform role).
- **Notification preferences** for AT alerts: email, push (reuses existing notification settings infrastructure).

AT settings that are **facility-level** (update interval, idle threshold, panic action) remain at `/asset-tracking/admin/settings` — they do not appear in Account Settings.

### 7.5 Modules That Must Not Be Touched

The following Secure modules are entirely unaffected by AT Module deployment. No routes, tables, or UI components in these modules may be modified, removed, or wrapped:

| Module | Routes | Tables |
|---|---|---|
| Data Library | `/data-library/*` | `data_library_records`, `documents`, `evidence_attachments` |
| Data Centre Dashboards | `/dashboards/data-centre/*` | `dc_metadata` |
| Physical & Technical | `/properties/:id/physical-technical/*` | `systems`, `meters`, `end_use_nodes` |
| AI Agents | `/ai-agents/*` | `agent_runs`, `agent_findings` |
| Governance & Targets | `/governance/*` | (data library backed) |
| Reports | `/reports/*` | (data library backed) |

---

## 8. Module Pages — Screen Specification

### 8.1 `/asset-tracking/live` — Live Tracking

**Purpose:** Primary operational view for safety monitors and managers.

**Summary tiles (top row):** Active Assets, In Maintenance, Lost / Missing (no position event in configurable period, default 30 min), Most Active Floor, Total Tracked.

**Floor plan panel:**
- Floor selector dropdown (from `at_floors` for the current property)
- Asset type filter, status filter (All / Available / Reserved)
- Asset count: "N assets on this floor"
- Left panel: scrollable list of assets on selected floor (name, type, zone, status badge)
- Right panel: floor plan image with asset marker overlay using `at_asset_types.icon_key`. Markers rendered at `(at_position_events.x_pos, at_position_events.y_pos)` scaled to image dimensions. Click marker → asset tooltip (name, type, zone, last seen).

**Live update:** Supabase Realtime subscription on `at_position_events` filtered by `property_id`. Falls back to polling at `at_facility_settings.position_update_interval_sec`.

**Alerts panel:** Slide-in from right, triggered by clicking unread alert badge. Shows `at_alerts` for current property filtered to `status = unread`, ordered by `triggered_at DESC`. Each card: alert type badge, message, asset name, floor, timestamp. Actions: acknowledge (checkmark → `status = acknowledged`), dismiss (X → `status = dismissed`). Both actions write to `audit_events`.

**Historical View toggle:** Opens `at_position_events` playback modal (see §8.6).

### 8.2 `/asset-tracking/alerts` — Alert Management

**Summary tiles:** Total Alerts (all time), Restricted Entry count, Out of Zone count, Prolonged Idle count.

**Alert History table:** Columns: Type badge, Message, Asset, Floor, Zone, Triggered At, Status, Actions. Filters: Time range (15 min / 1h / 24h / 7d / All), Alert Type, Status.

**Alert Types reference panel** (right side): describes each alert type and its trigger condition. Sourced from spec — not from a DB table.

> **Audit Note:** All alert records are append-only. Status changes (acknowledge, dismiss) are the only mutations permitted and every one writes to `audit_events`.

### 8.3 `/asset-tracking/devices` — Device Management

Three tabs:

**Lights tab** — reads `at_device_state` joined to `systems` for fixture name and location.

Each light card displays:

| Field | Source | Note |
|---|---|---|
| Device ID | `systems.key_specs` (wirepas_id or DALI address) | e.g. 1875321997 |
| Room | `systems.serves_spaces_description` or join to `spaces.name` | e.g. Office 4 |
| Online | `at_device_state.online` | Green badge |
| On/Off | `at_device_state.light_on` | Toggle → queues `at_dali_commands` |
| Dim Level % | `at_device_state.dim_level_pct` | Slider; greyed out when DH active |
| Power (W) | `at_device_state.power_watts` | Not lux — technically not possible |
| ALS Reading | `at_device_state.als_value` | Label: "not calibrated to Lux" |
| Daylight Harvesting | `at_device_state.daylight_harvesting_active` + `_pct` | Active badge + % natural light |
| Behaviour Mode | `at_device_state.behaviour_mode_index` | Chips: Motion / Daylight / Eco / Scene |
| DALI Diagnostics | Expandable | Fault codes; sourced from DALI telemetry payload |

Room-level grouping: lights grouped by `systems.serves_spaces_description`. Room view has two click-through screens:
1. Graphs — energy usage over time, ALS levels, presence events per sensor.
2. Settings — DH setpoint, motion timeout, light levels per behaviour mode, scene assignment.

**Gateways tab** — reads `at_gateways`. Columns: Name, Floor, Online status, Connected Nodes, Last Heartbeat. "No gateways configured" state when table empty. Add Gateway form: name, `wirepas_gateway_id`, floor, MAC, notes → inserts to `at_gateways`.

**Tracking Sensors tab** (replaces "Asset Tags" from v1.0 for naming clarity):

Section 1 — Recent Updates: time-series table from `at_position_events`. Columns: Asset, Floor, Zone, Position (x,y), Time. Filters: Asset Type, Floor, Time Range. Shows "No updates yet" when empty.

Section 2 — Sensor Assignments: table of all `at_asset_tags` joined to `at_assets`. Columns: Asset, Floor, Zone, Position, Status. Status = Active (green) when `at_asset_tags.last_seen_at > now() - interval '5 minutes'`.

### 8.4 `/asset-tracking/admin/floors` — Floor & Zone Management

**Floor list:** All `at_floors` for property. Add Floor: name, level_index, coord_system.

**Per-floor detail:**
- Floor Plan tab: upload PNG/SVG → stores to `at-floor-plans` bucket → sets `floor_plan_image_url`, `floor_plan_width_px`, `floor_plan_height_px`.
- Zones tab: list of `at_zones` for this floor. Draw Zone button: interactive polygon tool on floor plan image. Zone form: name, zone_type (`public` / `restricted` / `staff_entry`), optional link to `spaces.id`. Each zone listed as: name, type badge, vertex count, optional Secure space link, edit/delete.
- GPS Calibration tab: set GPS anchor points mapped to pixel coordinates → stored in `at_floors.gps_calibration`.

### 8.5 `/asset-tracking/admin/assets` — Asset Registry

Asset Registry table: Icon, Name, Type, Default Zone, Status, Tag Assigned, Actions. Search by name or serial.

Add Asset form:
- Name (text)
- Asset Type (dropdown from `at_asset_types` for this account + property)
- Default Zone (dropdown from `at_zones` for this property)
- Serial Number / Employee ID
- Link to User Account (dropdown of `auth.users` in account — for worker assets)
- Assign Tag (dropdown of `at_asset_tags` where `assigned_asset_id IS NULL` for this property)

### 8.6 `/asset-tracking/analytics/playback` — Historical Playback

Accessible from Live Tracking page (Historical View button) or directly via URL.

- Asset selector (dropdown of all `at_assets` for property)
- Date/time from–to
- Play / Pause / Step Forward / Step Back controls
- Speed selector: 1× / 2× / 5× / 10×
- Timeline scrubber with timestamps
- Floor plan renders asset marker at position from `at_position_events` ordered by `recorded_at`
- Asset info panel: current zone, coordinates, timestamp
- "No history available for this asset in the selected time range. Try selecting a longer time range." — message when query returns 0 rows

### 8.7 `/asset-tracking/admin/settings` — AT Facility Settings

| Setting | UI Control | Maps To | Default |
|---|---|---|---|
| Position Update Interval | Dropdown: 5s / 10s / 15s / 30s / 60s | `at_facility_settings.position_update_interval_sec` | 15 |
| Prolonged Idle Threshold | Number input (minutes) | `at_facility_settings.prolonged_idle_threshold_min` | 60 |
| Panic Button Action | Select: Panic Alert / Movement Detection / Custom Scene | `at_facility_settings.panic_button_default_action` | `panic` |
| Out-of-Zone Alerts | Toggle | `at_facility_settings.out_of_zone_enabled` | true |
| Restricted Entry Alerts | Toggle | `at_facility_settings.restricted_entry_enabled` | true |
| DALI Motion Timeout | Number input (seconds) | `at_facility_settings.dali_motion_timeout_sec` | 300 |
| DALI DH Setpoint (ALS) | Number input | `at_facility_settings.dali_dh_setpoint_als` | 500 |

---

## 9. Real-Time Architecture

### 9.1 Position Event Pipeline

| Stage | Component | Description |
|---|---|---|
| 1. Tag | BlueUp Wirepas tag | Broadcasts at `position_update_interval_sec` (default 15s, min 5s) |
| 2. Gateway | Wirepas border router | Aggregates beacons; computes (x, y) via RTLS engine; packages as JSON; forwards to backend |
| 3. Transport | MQTT or HTTP POST | JSON payload per §9.2 |
| 4. Ingest | Edge Function `at-position-ingest` | Validates payload; resolves `asset_id` from `wirepas_node_id`; inserts `at_position_events` |
| 5. Zone Derivation | Point-in-polygon check | Tests (x, y) against `at_zones.polygon` for the resolved `floor_id`; sets `zone_id` |
| 6. Alert Engine | Edge Function or DB trigger `at-alert-engine` | Evaluates rules (§9.4); inserts `at_alerts`; writes `audit_events` |
| 7. Frontend | Supabase Realtime + polling | Subscribes to `at_position_events` and `at_alerts` for live updates |

### 9.2 Position Event JSON Schema (Wirepas → Secure)

```json
{
  "node_id": "1875321997",
  "timestamp": "2026-03-31T10:15:30Z",
  "floor_id": "<at_floors.id uuid>",
  "x": 8.60,
  "y": 2.98,
  "accuracy_m": 0.5,
  "battery_pct": 85,
  "rssi": -72,
  "source": "wirepas"
}
```

The ingest function resolves `asset_id` by joining `at_asset_tags.wirepas_node_id = node_id`. `floor_id` in the payload is the Secure `at_floors.id` UUID — the gateway must be configured with this mapping at device provisioning time.

### 9.3 DALI Telemetry JSON Schema (INGY BV → Secure)

```json
{
  "device_id": "1875321997",
  "timestamp": "2026-03-31T10:15:30Z",
  "online": true,
  "light_on": false,
  "dim_level_pct": 100,
  "als_value": 129,
  "daylight_harvesting_active": true,
  "daylight_harvesting_pct": 13,
  "behaviour_mode_index": 7,
  "power_watts": 18.5
}
```

The DALI ingest function resolves `system_id` by joining `systems.key_specs->>'dali_device_id' = device_id`. Then upserts `at_device_state`.

> **Pending:** Sample JSON payloads from INGY BV required to finalise field names. See §11 Q1.

### 9.4 Alert Engine Rules

| Alert Type | Trigger Condition | Deduplication |
|---|---|---|
| `restricted_entry` | New `at_position_events` row has `zone_id` where `at_zones.zone_type = 'restricted'` | One `unread` alert per `(asset_id, zone_id)` per 30-minute window |
| `out_of_zone` | New `at_position_events` row has `zone_id IS NULL` (no polygon matched) | One `unread` alert per `asset_id` per 5-minute window |
| `prolonged_idle` | Time elapsed since last position event where `(x_pos, y_pos)` moved more than 1m exceeds `prolonged_idle_threshold_min` | Alert updated (message regenerated with current idle minutes) every minute while condition persists; not duplicated |
| `panic` | Gateway payload contains panic flag or dedicated panic topic | No deduplication — every panic press creates a new alert |

---

## 10. Reporting and Historical Data

### 10.1 Available Reports (`/asset-tracking/analytics`)

| Report | Description | Data Source | Filters |
|---|---|---|---|
| Asset Position History | Sequence of zones visited with entry/exit times | `at_position_events` | Asset, Date range |
| Dwell Time by Zone | Duration in each zone per asset per period | `at_position_events` (computed) | Asset(s), Zone(s), Date range |
| Zone Occupancy Summary | Concurrent asset count per zone over time | `at_position_events` (aggregated) | Floor, Zone type, Date range |
| Alert Summary | Total alerts by type, asset, zone, trend over time | `at_alerts` | Alert type, Asset, Date range |
| Device Status Report | Online/offline history for lights and gateways, uptime % | `at_device_state` + `audit_events` | Device type, Date range |
| Time & Attendance | Per-worker first/last position event per day, total hours | `at_position_events` (first/last per day per worker) | Worker, Date range |
| Energy Usage (Lighting) | kWh per light fixture (watts × hours) | `at_device_state.power_watts` time-series | Room, Date range |

---

## 11. Open Decisions Table

| # | Decision / Question | Owner | Priority | Impact if Unresolved | Target Date |
|---|---|---|---|---|---|
| Q1 | INGY BV JSON stream: confirm exact field names and types for Wirepas position events and DALI telemetry. Spec assumes `node_id`, `floor_id`, `x`, `y`, `power_watts`, `behaviour_mode_index` — any divergence requires ingest function rewrite. | INGY BV (Bastiaan) | **P0** | Ingest functions cannot be finalised | Before Phase 1 end |
| Q2 | Panic button wiring: is panic a dedicated MQTT topic/flag or a special field in the standard position event? Does pressing panic also send a position fix? | INGY BV | **P0** | Alert engine panic rule cannot be implemented | Before Phase 3 start |
| Q3 | DALI `behaviour_mode_index` enum: what does index 7 mean? Provide full index → label mapping (e.g. 7 = "Motion+Daylight+Eco+Scene combined"). Screenshots show index 7 with all four chips active. | INGY BV | **P1** | Behaviour mode chips may be mislabelled in UI | Before Phase 2 UI build |
| Q4 | Wirepas RTLS accuracy: typical position accuracy (metres) underground. Affects out-of-zone alert threshold — if accuracy is ±3m, a 1m movement threshold for prolonged_idle is useless. | INGY BV | **P1** | Alert thresholds need tuning | Before Phase 3 start |
| Q5 | 5-second update interval viability: can the Wirepas mesh sustain 5s updates for 20 nodes without congestion? What is the minimum safe interval? | INGY BV | **P1** | `position_update_interval_sec` default may need adjusting | Before Phase 1 end |
| Q6 | Floor plan files: confirm format (PNG, SVG, DXF) and whether GPS anchor points are available for Kolomela Level 1. | Mine Operator / Apex Group | **P1** | GPS calibration tab cannot be validated | Before Phase 2 start |
| Q7 | `at_floors.floor_id` provisioning: the Wirepas gateway must be configured with the Secure `at_floors.id` UUID to include `floor_id` in position payloads. Confirm INGY BV can configure gateway with this value at provisioning time; otherwise Secure must derive floor from gateway MAC → floor mapping table. | INGY BV / Retransform | **P1** | Ingest function floor resolution logic differs | Before Phase 1 end |
| Q8 | Time & Attendance scope: is T&A a reporting output only (dwell time queries on `at_position_events`) or does it require integration with an HR/payroll system at the mine? | Apex Group / Mine Operator | **P2** | Scope of analytics module differs | Before Phase 4 start |
| Q9 | `at_access` flag on `account_memberships`: does Account Settings need a separate AT role (Viewer / Manager / Admin) independent of the main platform role, or is main platform role sufficient for POC? | Retransform / Client | **P2** | Account Settings UI scope changes | Before Phase 2 start |
| Q10 | Building Systems Register: should existing `system_type = 'OccupancySensors'` (Wirepas-based environmental sensors, if any exist for this property) be migrated to `at_asset_tags`? Or are they fixed sensors under Building Systems? Clarify for this property. | Retransform | **P2** | Sensor domain split classification for existing data | Before Phase 0 |

---

## 12. Non-Regression Guardrails

This section is mandatory. All items are blocking — AT Module deployment must not proceed past Phase 0 unless all of these are verified.

### 12.1 Immutable Existing Features

The following features, pages, and data flows must remain fully functional and unchanged after AT Module deployment:

| Module | Feature | Verification Step |
|---|---|---|
| Data Library | Upload evidence, create records, confidence levels, evidence linking | Run existing Data Library e2e test suite |
| Data Library | Agent Readiness + Boundary Agent context | Agent context payload must not change structure |
| Physical & Technical | Systems Register (CRUD on `systems`) | No new required columns; `system_type` CHECK constraint extends additive only |
| Physical & Technical | Meters CRUD | No AT migration touches `meters` |
| Physical & Technical | End-use nodes | No AT migration touches `end_use_nodes` |
| Data Centre | DC dashboards, PUE tiles, `dc_metadata` | No AT table references `dc_metadata` |
| Spaces | Space CRUD, allocation, floor references | No AT migration adds required columns to `spaces` |
| Audit Events | Existing `audit_events` rows | AT only appends; never updates or deletes existing rows |
| Users | Existing `profiles`, `account_memberships` | AT links `at_assets.user_id → auth.users.id` only |

### 12.2 Additive-Only Rule

Every AT Module change to an existing table must be additive:

- New columns: always `NULLABLE` with a `DEFAULT` — never `NOT NULL` without a default on an existing table.
- New `system_type` values: added to the CHECK constraint list — the existing values are never removed.
- New `audit_events` action values: currently `create | update | delete` — AT does not add new `action` values; it uses these three.

### 12.3 RLS Continuity

Every AT table has RLS enabled with the same `account_id IN (SELECT account_id FROM account_memberships WHERE user_id = auth.uid())` pattern. No AT migration may disable or weaken RLS on existing tables.

---

## 13. Implementation Plan

### Phase 0 — Validation Gate (Week 0, Before Any Migration)

Phase 0 must complete before any schema migration runs. It is a checklist — all items must pass.

| Check | What to Verify | Pass Criterion |
|---|---|---|
| Schema compatibility | Run `at_floors`, `at_zones`, `at_assets`, `at_asset_tags`, `at_gateways`, `at_position_events`, `at_alerts`, `at_device_state`, `at_dali_commands`, `at_facility_settings` DDL against Supabase in a staging environment | All migrations execute without error; no FK violations against existing tables |
| `systems` constraint extension | Add `'DALILight'` to `systems_allocation_method_check` (additive) and verify existing `systems` rows are unaffected | Zero rows updated; existing systems queries return same results |
| RLS check | Enable RLS on all 10 new AT tables; verify existing table RLS policies are unchanged | Supabase RLS audit shows no policy removals or modifications |
| UI route ownership | Verify no existing Secure route conflicts with `/asset-tracking/*` | Route map shows no collisions |
| Ingest payload contract | Validate §9.2 and §9.3 JSON schemas against sample data from INGY BV | Q1 from §11 must be answered; schema validated against actual sample |
| Data library non-regression | Run a smoke test: upload a data library record, create evidence attachment, confirm it appears correctly | Pass |
| Building systems non-regression | Run a smoke test: create a `systems` row, assign meter, verify boundary agent context includes it | Pass |

If Q1 (INGY BV JSON format) is not yet answered, Phase 0 passes conditionally — ingest functions are scaffolded but not deployed to production until Q1 is resolved.

### Phase 1 — Schema and Core Entities (Week 1–2)

| Step | Task | Migration File |
|---|---|---|
| 1.1 | Add `at_enabled` to `properties` | `add-at-enabled-to-properties.sql` |
| 1.2 | Create `at_floors` with RLS | `create-at-floors.sql` |
| 1.3 | Create `at_zones` with RLS | `create-at-zones.sql` |
| 1.4 | Create `at_asset_types` with RLS | `create-at-asset-types.sql` |
| 1.5 | Create `at_assets` with RLS | `create-at-assets.sql` |
| 1.6 | Create `at_asset_tags` with partial unique index | `create-at-asset-tags.sql` |
| 1.7 | Create `at_gateways` with RLS | `create-at-gateways.sql` |
| 1.8 | Create `at_position_events` with all required indexes | `create-at-position-events.sql` |
| 1.9 | Create `at_alerts` with RLS + audit_events trigger | `create-at-alerts.sql` |
| 1.10 | Create `at_device_state` with unique on `system_id` | `create-at-device-state.sql` |
| 1.11 | Create `at_dali_commands` with RLS | `create-at-dali-commands.sql` |
| 1.12 | Create `at_facility_settings` with UNIQUE on `property_id` | `create-at-facility-settings.sql` |
| 1.13 | Extend `systems` CHECK constraint to allow `'DALILight'` system_type | `extend-systems-type-dalilight.sql` |
| 1.14 | Create Storage bucket `at-floor-plans` with RLS policies | Supabase dashboard + `add-at-floor-plans-storage-policies.sql` |
| 1.15 | Seed account-level `at_asset_types` for Mining POC account | `seed-at-asset-types-mining.sql` |
| 1.16 | Update `docs/database/schema.md` and `supabase-schema.sql` | Manual |

### Phase 2 — Administration UI (Week 2–3)

| Step | Task |
|---|---|
| 2.1 | Build `/asset-tracking/admin/floors`: floor list, floor plan upload to `at-floor-plans`, zone drawing tool, zone_type selector, GPS calibration |
| 2.2 | Build `/asset-tracking/admin/configuration`: Asset Categories + Asset Types UI with account/property scope toggle |
| 2.3 | Build `/asset-tracking/admin/assets`: Asset Registry with tag assignment |
| 2.4 | Build `/asset-tracking/admin/settings`: AT Facility Settings form |
| 2.5 | Build `/asset-tracking/devices`: Lights tab (from `at_device_state` + `systems`), Gateways tab (from `at_gateways`), Tracking Sensors tab (from `at_asset_tags` + `at_position_events`) |
| 2.6 | Add "Asset Tracking" tab to Property detail page (summary tile only when `at_enabled = true`) |
| 2.7 | Add AT Permissions section to Account Settings |

### Phase 3 — Live Tracking and Alerts (Week 3–4)

| Step | Task |
|---|---|
| 3.1 | Build `/asset-tracking/live`: summary tiles, floor plan SVG renderer, asset marker overlay, filter controls |
| 3.2 | Implement Supabase Realtime subscription on `at_position_events` and `at_alerts` |
| 3.3 | Build `/asset-tracking/alerts`: summary tiles, alert history table, filters, acknowledge/dismiss |
| 3.4 | Implement alert slide-in panel on Live Tracking |
| 3.5 | Build `/asset-tracking/analytics/playback`: Historical Playback modal with play controls |

### Phase 4 — Ingest, Alert Engine, Reporting (Week 4–5)

| Step | Task |
|---|---|
| 4.1 | Deploy Edge Function `at-position-ingest`: validate Wirepas JSON, resolve `asset_id`, point-in-polygon zone derivation, insert `at_position_events` |
| 4.2 | Deploy Edge Function `at-dali-ingest`: validate DALI JSON, resolve `system_id`, upsert `at_device_state`, process `at_dali_commands` queue |
| 4.3 | Deploy `at-alert-engine`: restricted_entry, out_of_zone, prolonged_idle, panic rules; deduplication logic; write `at_alerts` + `audit_events` |
| 4.4 | Build `/asset-tracking/analytics`: all reports listed in §10.1 |
| 4.5 | Build `at_position_archive` table and scheduled archival job (90-day retention) |
| 4.6 | Validate ingest functions against confirmed INGY BV JSON sample (Q1 resolved) |

### Acceptance Criteria

| Feature | Criterion |
|---|---|
| Phase 0 | All 7 Phase 0 checks pass; Q1 conditionally resolved |
| Facility Setup | `at_enabled = true` for Mining Site A; floor plan uploaded to `at-floor-plans`; 9 zones drawn on Level 1 |
| Asset Types | 5 account-level types seeded (Worker, Drilling Jumbos, Jacklegs, RSL, First Aid Box) |
| Asset Registry | 7 assets registered with types and tags assigned |
| Devices — Lights | 3 DALI lights visible with live dim level, ALS, DH status, power in watts; dim slider greyed when DH active |
| Devices — Gateways | Gateway tab shows "No gateways configured" state (correct for POC state) |
| Devices — Tracking Sensors | 7 tag assignments shown; JL-01, Mobius, RSL-01 show Active with coordinates |
| Live Tracking | Floor plan renders; 3 assets on Level 1 at correct positions; alert badge shows unread count |
| Alerts | 2707+ unread alerts visible; filters work; acknowledge action clears unread badge and writes `audit_events` |
| Historical Playback | Asset with data shows replay; asset without data shows "No history" message |
| Alert Engine | Prolonged idle fires at configured threshold; restricted_entry fires on zone entry |
| Audit Trail | Every alert status change appears in `audit_events` with `actor_id` and `before_state`/`after_state` |
| Non-Regression | Data Library upload, systems CRUD, and Data Centre dashboard all pass smoke tests after AT deployment |

---

## 14. Architectural Invariants

These rules are permanent and must not be changed across any future AT Module release:

1. Every AT table includes `account_id` — no exceptions.
2. `at_position_events` is append-only. No UPDATE or DELETE within the 90-day window.
3. `at_alerts` transitions state only (unread → acknowledged → dismissed). Never deleted.
4. Every `at_alerts` status change writes to `audit_events` with `actor_id`, `timestamp`, `before_state`, `after_state`.
5. `at_asset_tag` records are never duplicated in `systems`. These are mutually exclusive.
6. `at_gateways` records are never in `systems`.
7. AT does not write to `systems`, `meters`, `end_use_nodes`, `spaces`, `data_library_records`, `documents`, or `evidence_attachments`.
8. Floor plan images live in the `at-floor-plans` Storage bucket — never as binary in DB.
9. Asset type icons (`at_asset_types.icon_key`) are immutable after creation.
10. One tag → one asset at a time. Enforced by partial unique index on `at_asset_tags.assigned_asset_id`.
11. Dwell time, zone occupancy, and T&A are always derived from `at_position_events` queries — never pre-computed and stored as mutable facts.
12. AT settings are always read from `at_facility_settings` — never hardcoded in frontend.
13. The `spaces` table is not modified by AT Module migrations (preferred approach). If the fallback is used, only `at_`-prefixed nullable columns may be added, and AT APIs must only read/write those columns.

---

## Appendix A — Delta from v1.0

| Change | v1.0 Approach | v2.0 Approach | Rationale |
|---|---|---|---|
| **Sensor domain split** | Not addressed; tags implied as `systems` rows | Explicit §2: `at_asset_tags` and `at_gateways` are separate from `systems` always | Prevents collision with Building Systems Register, Boundary Agent context, meter flows |
| **Asset type governance** | `at_asset_types.property_id` nullable with brief mention | §3: formal hierarchy — account-level master, property extensions optional; UI placement defined | Ensures consistent taxonomy across multi-property accounts; prevents type proliferation |
| **Tags in `systems`** | v1.0 suggested `system_type: 'AssetTag'` in `systems` | `at_asset_tags` is a dedicated table; tags never in `systems` | Collision with building systems workflows; tags have fundamentally different lifecycle and semantics |
| **Gateways in `systems`** | v1.0 suggested `system_type: 'WirepasGateway'` in `systems` | `at_gateways` is a dedicated table | Same rationale as tags |
| **DALI lights in `systems`** | v1.0 suggested `system_type: 'DALILight'` as full system entry | DALI fixture definition stays in `systems`; live state in `at_device_state`; commands in `at_dali_commands` | Lights are fixed building infrastructure — correctly owned by `systems`. State and commands are AT-owned to avoid polluting the building systems record. |
| **Floor / zone schema** | Add `zone_type`, `floor_plan_polygon`, `floor_plan_image_url`, `gps_calibration` to `spaces` | Preferred: new `at_floors` + `at_zones` tables referencing `properties`. Fallback: add `at_`-prefixed columns to `spaces` | Existing `spaces` table drives Boundary Agent, energy allocation, GRESB. Contaminating it with AT polygon data breaks those workflows. |
| **`properties` extension** | Add `floor_plan_coord_system` to `properties` | Removed from `properties`; moved to `at_floors.coord_system` | Per-floor coordinate system is more correct than per-property |
| **Navigation** | AT items injected into existing sidebar (Overview, Facility Profile, Devices, etc.) | Standalone `/asset-tracking/*` routes; Property detail gains a summary tab only | Keeps module boundaries clean; avoids entangling AT state with existing property sidebar |
| **Phase 0** | Not present | Added as mandatory validation gate before any migration | Prevents schema regressions and payload mismatches from reaching production |
| **Non-regression section** | Not present | Explicit §12 with blocking guardrails per module | Makes regression risk visible and testable |
| **`at_dali_commands` table** | DALI commands written directly to `at_device_state` pending queue | Dedicated `at_dali_commands` table with status lifecycle | Separates state from commands; enables retry and audit of control actions |
| **`at_position_archive`** | Mentioned as `at_position_archive` | Same — added archive schema definition | Clarifies archive row structure |
| **Open decisions table** | 8 questions in flat list | Structured table with owner, priority, impact, target date | Actionable — enables tracking |
| **Lovable implementation prompts** | Not present | Added as Appendix C | Enables direct use with Cursor/Lovable |

---

## Appendix B — Lovable Implementation Prompts

These prompts are written for direct use with Cursor against the Lovable codebase. Each prompt is self-contained.

---

### Prompt 1 — Phase 0 Schema Validation Gate

```
Run the following checks against the Supabase staging environment before any AT Module 
migration is applied:

1. Verify that no existing table has a column prefixed `at_`. If any do, report them — 
   they may be from a previous incomplete migration.

2. Test the following DDL in a transaction, then ROLLBACK (do not commit):
   - CREATE TABLE at_floors (...) as defined in docs/specs/secure-asset-tracking-spec-v2.0.md §6.2
   - CREATE TABLE at_zones (...) §6.3
   - CREATE TABLE at_asset_types (...) §6.4
   - CREATE TABLE at_assets (...) §6.5
   - CREATE TABLE at_asset_tags (...) §6.6
   - CREATE TABLE at_gateways (...) §6.7
   - CREATE TABLE at_position_events (...) §6.8
   - CREATE TABLE at_alerts (...) §6.9
   - CREATE TABLE at_device_state (...) §6.10
   - CREATE TABLE at_dali_commands (...) §6.11
   - CREATE TABLE at_facility_settings (...) §6.12

3. Verify that after the rollback, the following tables are completely unmodified:
   systems, meters, end_use_nodes, spaces, data_library_records, documents, 
   evidence_attachments, audit_events, properties (except at_enabled column).

4. Run a SELECT on systems, spaces, data_library_records, and confirm row counts are 
   unchanged.

5. Run the existing Data Library upload smoke test (upload a file, create a record, 
   link evidence). Confirm pass.

Output a report: PASS/FAIL per check with any error messages.
```

---

### Prompt 2 — AT Floor and Zone Management UI

```
Build the page at route `/asset-tracking/admin/floors` in the Lovable app.

Data sources:
- `at_floors` table (see schema in docs/specs/secure-asset-tracking-spec-v2.0.md §6.2)
- `at_zones` table (§6.3)
- Storage bucket `at-floor-plans`

Requirements:
1. Floor List: show all `at_floors` for the current `property_id`. Each row: name, 
   level_index, has floor plan (boolean), zone count. Add Floor button → modal form 
   (name, level_index, coord_system dropdown: pixel / local_metres / gps).

2. Floor Detail (click a floor): three tabs:
   a. Floor Plan tab: 
      - Upload button → uploads PNG/SVG to `at-floor-plans` bucket at path 
        `account/{accountId}/property/{propertyId}/floors/{floorId}/{filename}`
      - Stores storage path in `at_floors.floor_plan_image_url`
      - Stores image dimensions in `floor_plan_width_px`, `floor_plan_height_px`
      - Renders uploaded image once stored
   
   b. Zones tab:
      - List all `at_zones` for this floor: name, zone_type badge 
        (public=green, restricted=red, staff_entry=amber), vertex count, 
        optional spaces.name link, edit/delete actions
      - "Draw Zone" button: interactive polygon tool overlaid on floor plan image
        (click to add vertex, double-click to close polygon)
      - Zone form: name (text), zone_type (select: public/restricted/staff_entry), 
        optional spaces_id (searchable dropdown of existing spaces for this property)
      - Save stores polygon vertices as JSON array [{x, y}, ...] in `at_zones.polygon`
   
   c. GPS Calibration tab:
      - Table of anchor points: pixel_x, pixel_y, lat, lng. Add/remove rows.
      - Save stores as JSON array in `at_floors.gps_calibration`
      - Only show this tab when `at_floors.coord_system = 'gps'`

3. All operations use the Supabase client with RLS (account_id filter). 
   No direct SQL — use .from('at_floors').select/insert/update/delete.

4. Do NOT modify the existing Floors & Spaces page at the property level. 
   This is a completely separate page in the AT module.
```

---

### Prompt 3 — AT Asset Registry and Type Management UI

```
Build two pages in the Lovable app under the Asset Tracking admin section:

PAGE 1: `/asset-tracking/admin/configuration`
Tabs: Asset Categories | Asset Types

Asset Categories tab:
- Shows categories: workers, drilling_equipments, loading_equipments, medical_kit
- Add Category: name (text), description (text)
- Categories are stored as distinct `category` text values in `at_asset_types`
- No separate categories table — derive unique categories from at_asset_types

Asset Types tab:
- Table: Icon (rendered from icon_key), Name, Category, Scope (Account-wide / This facility), Actions
- Scope derived from: property_id IS NULL = "Account-wide", property_id = current property = "This facility"
- Add Asset Type button → modal:
  - Name (text)
  - Category (select from existing categories)
  - Scope (radio: Account-wide / This facility only)
  - Icon selector (grid of available icons — render icon_key as an image or emoji)
  - IMPORTANT: once saved, icon cannot be changed. Show warning: 
    "Icon cannot be changed after saving. This ensures consistency across historical maps and playback."
- Delete: blocked with error message if any at_assets reference this type_id
- The query for types to show: WHERE account_id = $account_id AND (property_id IS NULL OR property_id = $property_id)

PAGE 2: `/asset-tracking/admin/assets`
Asset Registry:
- Table: Icon (from asset_type.icon_key), Name, Type name, Default Zone, Status badge, Tag Assigned (tag wirepas_node_id or "Unassigned"), Actions (edit, delete)
- Search bar: filter by name or serial_number
- "Add Asset" button → modal form:
  - Name (text, required)
  - Asset Type (dropdown from at_asset_types for this account+property; account-wide types listed first)
  - Default Zone (dropdown from at_zones for this property; show zone_type badge next to name)
  - Serial Number (text, optional)
  - Link to User (dropdown of profiles.display_name for users in this account; optional; label: "Link worker to platform user account")
  - Assign Tag (dropdown of at_asset_tags WHERE assigned_asset_id IS NULL AND property_id = $property_id; show wirepas_node_id + tag_model; label: "Assign tracking tag")
- Edit: opens same form pre-filled
- When assigning a new tag to an asset that already has one, warn: "This will unassign the current tag. Continue?"
- Unassigning a tag sets at_assets.tag_id = NULL and at_asset_tags.assigned_asset_id = NULL in the same transaction
```

---

### Prompt 4 — Live Tracking Page

```
Build the page at route `/asset-tracking/live` in the Lovable app.

Data sources:
- `at_position_events` (latest position per asset_id)
- `at_assets` joined to `at_asset_types` (for icon_key and name)
- `at_floors` (for floor plan image)
- `at_zones` (for zone polygon overlay)
- `at_alerts` where status = 'unread'
- `at_facility_settings` (for position_update_interval_sec)

Layout:
- Top row: 5 summary tiles: Active Assets, In Maintenance, Lost/Missing, Most Active Floor, Total Tracked
  - Lost/Missing = at_assets where status=active AND last position event > 30 min ago
- Below: filter bar: Floor selector (at_floors dropdown), Asset Type filter, Status filter (All/Available/Reserved)
- Asset count: "N assets on this floor"
- Left panel (40%): scrollable list of assets on selected floor. Each row: icon (from at_asset_types.icon_key), name, type, zone name, status badge. Click row → highlights asset on floor plan.
- Right panel (60%): floor plan image from at_floors.floor_plan_image_url. Asset markers at (x_pos, y_pos) scaled by (image_width_px, image_height_px). Click marker → tooltip: name, type, zone, last seen timestamp.
- Top right buttons: "Live" indicator (green dot + "Live"), "Historical View" button, "Alerts" button with unread count badge

Live updates:
- Subscribe to Supabase Realtime on at_position_events where property_id = current property
- On new event: update marker position for the affected asset_id
- Poll interval fallback: use at_facility_settings.position_update_interval_sec

Alerts slide-in panel (when "Alerts" button clicked or badge > 0):
- Right-side overlay panel, dismissible
- Header: "Alerts (N unread)" with All Types dropdown and time range dropdown (15 min, 1h, 24h)
- List of at_alerts where property_id = current and status = 'unread', ordered by triggered_at DESC
- Each card: clock icon, alert_type label, message, asset name, triggered_at relative time, checkmark (acknowledge) and X (dismiss) buttons
- Acknowledge: UPDATE at_alerts SET status='acknowledged', acknowledged_by=$user_id, acknowledged_at=now() WHERE id=$alert_id
  + INSERT INTO audit_events (account_id, entity_type, entity_id, action, actor_id, before_state, after_state)

Historical View modal (when Historical View button clicked):
- Modal overlay
- Asset dropdown (all at_assets for property)
- Date-time range picker (from/to)
- "No history available for this asset in the selected time range." when 0 rows returned
- When data exists: play button (steps through at_position_events ordered by recorded_at), speed selector 1x/2x/5x/10x
- Shows asset marker moving across floor plan

IMPORTANT: This page must NOT modify, include, or wrap any component from:
- /properties/:id/floors-spaces
- /data-library/*
- /dashboards/data-centre/*
```

---

### Prompt 5 — AT Ingest Edge Functions

```
Create two Supabase Edge Functions in the AT Module. Both follow the Secure SoR 
convention: validate input, enforce account_id via RLS, write to AT-owned tables only.

FUNCTION 1: `at-position-ingest`
Route: POST /functions/v1/at-position-ingest
Auth: Bearer token (Supabase anon key from gateway config, validated against a 
property-level API key stored in at_facility_settings or Supabase secrets)

Input (§9.2):
{
  "node_id": "string",        // wirepas_node_id in at_asset_tags
  "timestamp": "ISO string",  // device timestamp
  "floor_id": "uuid",         // at_floors.id (configured in gateway)
  "x": number,
  "y": number,
  "accuracy_m": number | null,
  "battery_pct": number | null,
  "rssi": number | null,
  "source": "wirepas"
}

Steps:
1. Validate input shape. Return 400 if node_id or timestamp missing.
2. Resolve: SELECT id, assigned_asset_id, property_id, account_id 
   FROM at_asset_tags WHERE wirepas_node_id = $node_id LIMIT 1
   If not found: return 404 {"error": "tag_not_found"}
   If assigned_asset_id IS NULL: return 200 {"status": "tag_unassigned"} (no-op)
3. Zone derivation: SELECT id, polygon FROM at_zones WHERE floor_id = $floor_id
   For each zone, test if (x, y) is inside polygon (point-in-polygon check, use 
   ray casting algorithm). Set zone_id to first matching zone or NULL if none.
4. INSERT INTO at_position_events (account_id, property_id, asset_id, tag_id, 
   floor_id, zone_id, x_pos, y_pos, accuracy_m, source, recorded_at)
5. UPDATE at_asset_tags SET battery_level_pct=$battery_pct, last_seen_at=$timestamp 
   WHERE id = $tag_id
6. Invoke at-alert-engine logic (or trigger it via DB function) with the new event.
7. Return 200 {"status": "ok", "event_id": "<uuid>"}

FUNCTION 2: `at-dali-ingest`
Route: POST /functions/v1/at-dali-ingest

Input (§9.3):
{
  "device_id": "string",      // maps to systems.key_specs->>'dali_device_id'
  "timestamp": "ISO string",
  "online": boolean,
  "light_on": boolean,
  "dim_level_pct": number,
  "als_value": number,
  "daylight_harvesting_active": boolean,
  "daylight_harvesting_pct": number,
  "behaviour_mode_index": number,
  "power_watts": number
}

Steps:
1. Resolve: SELECT id, account_id FROM systems 
   WHERE key_specs->>'dali_device_id' = $device_id 
   AND system_category = 'Lighting' LIMIT 1
   If not found: return 404.
2. UPSERT at_device_state ON CONFLICT (system_id) DO UPDATE SET 
   online=$online, light_on=$light_on, dim_level_pct=$dim_level_pct,
   als_value=$als_value, daylight_harvesting_active=$dh_active,
   daylight_harvesting_pct=$dh_pct, behaviour_mode_index=$mode,
   power_watts=$power_watts, last_updated_at=$timestamp
3. Check at_dali_commands for queued commands for this system_id WHERE status='queued':
   - Execute each command (set_on_off, set_dim_level etc.) via DALI API
   - Update at_dali_commands.status to 'sent' or 'acknowledged'
4. Return 200 {"status": "ok"}

IMPORTANT: Neither function may write to systems, meters, end_use_nodes, 
data_library_records, documents, or evidence_attachments.
```

---

### Prompt 6 — AT Alert Engine and Audit Integration

```
Implement the AT Alert Engine as a Supabase Database Function called from 
at-position-ingest after each new at_position_events row is inserted.

Function signature: at_check_alerts(p_event_id uuid)
Language: plpgsql

Inputs (fetched from the event row):
- asset_id, property_id, account_id, zone_id, floor_id, x_pos, y_pos, recorded_at

Logic:

1. RESTRICTED ENTRY check:
   If zone_id IS NOT NULL:
     SELECT zone_type FROM at_zones WHERE id = zone_id
     If zone_type = 'restricted':
       Check: SELECT id FROM at_alerts 
         WHERE asset_id=$asset_id AND zone_id=$zone_id AND alert_type='restricted_entry'
           AND status='unread' AND triggered_at > now() - interval '30 minutes'
       If no recent unacknowledged alert:
         INSERT INTO at_alerts (account_id, property_id, asset_id, alert_type, zone_id, 
           floor_id, message, status, triggered_at)
         VALUES (..., 'restricted_entry', ..., 
           'Asset entered restricted area: ' || zone_name, 'unread', now())
         INSERT INTO audit_events (account_id, entity_type, entity_id, action, 
           before_state, after_state)
         VALUES ($account_id, 'at_alerts', $new_alert_id, 'create', NULL, 
           to_jsonb(new_alert_row))

2. OUT OF ZONE check:
   If zone_id IS NULL:
     Check: SELECT id FROM at_alerts
       WHERE asset_id=$asset_id AND alert_type='out_of_zone' AND status='unread'
         AND triggered_at > now() - interval '5 minutes'
     If no recent unacknowledged alert:
       INSERT at_alerts for out_of_zone + INSERT audit_events

3. PROLONGED IDLE check:
   SELECT recorded_at, x_pos, y_pos FROM at_position_events
   WHERE asset_id=$asset_id ORDER BY recorded_at DESC LIMIT 100
   Find first event where position differed by more than 1m from current (x,y).
   Idle minutes = (now() - that_event.recorded_at) / 60
   Read threshold from: SELECT prolonged_idle_threshold_min FROM at_facility_settings 
     WHERE property_id=$property_id
   If idle_minutes >= threshold:
     UPSERT at_alerts: if an unresolved prolonged_idle alert exists for this asset,
       UPDATE message='Asset has been idle for ' || idle_minutes || ' minutes', 
              idle_minutes=$idle_minutes
       + INSERT audit_events for the update (before_state = old row, after_state = new)
     Else:
       INSERT new prolonged_idle alert + audit_events

4. PANIC: handled separately by at-position-ingest when payload contains panic flag.
   At-position-ingest checks for panic field in payload and calls:
   INSERT INTO at_alerts (..., alert_type='panic', ...) — no deduplication.
   + INSERT audit_events.

IMPORTANT:
- All at_alerts INSERTs must be followed immediately by an audit_events INSERT.
- The audit_events row must use: entity_type='at_alerts', action='create', 
  before_state=NULL, after_state=to_jsonb(new_alert_row).
- This function must NOT touch systems, meters, data_library_records, or spaces.
- Test: deploy to staging, insert a test position event with zone_type='restricted',
  verify at_alerts row appears with correct type and audit_events row appears with 
  entity_type='at_alerts'.
```

---

*End of Specification — Secure SoR Asset Tracking Module v2.0 — March 2026*

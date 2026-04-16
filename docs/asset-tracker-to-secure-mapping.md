# Asset Tracker v1 → Secure SoR Lovable Mapping

This document maps the **Asset-tracker-v1** module into Secure SoR modules in the same style as the Data Centre mapping.

**Target platform:** Secure SoR backend (Supabase) + Lovable frontend  
**Source:** `/Users/anamariaspulber/Documents/[Apex TIGRE]/1_Secure/Repositories/Asset-tracker-v1`

---

## 0. What this module is

`Asset-tracker-v1` is an operations module for **live indoor asset tracking** at facility/floor/space level.

Core capabilities:
- Role-based app (`super_admin`, `admin`, `manager`, `viewer`)
- Facility configuration + floor plans + geo calibration
- Space polygons + point-in-polygon logic for zone detection
- Asset registry (categories, types, assets) + sensors
- Live tracking map (WebSocket + fallback polling)
- Reservations and alerting workflows
- Admin Console with operational dashboards and analytics dashboard

Main routes:
- `/admin` (Admin Console)
- `/dashboard` (Live tracking UI)
- `/settings`, `/profile`, `/help`
- `/super-admin` (impersonation/multi-facility)

---

## 1. Architecture fit vs Secure SoR

| Asset Tracker concept | Secure SoR equivalent | Fit |
|---|---|---|
| `facility` | `property` / `account` | Partial (property maps best) |
| `floors` | `properties.floors`, `spaces.floor_reference` | Partial |
| `spaces` polygons | `spaces` table (no polygon geometry today) | Gap |
| `assets` tracked items | no first-class tracked movable asset table | Gap |
| `sensors` (linked to assets) | IoT concepts exist in UI; limited backend table support | Partial/Gap |
| `current_locations`, `location_history` | no equivalent time-series location model | Gap |
| `reservations` | no equivalent | Gap |
| `alerts` (tracking events) | alerting exists in DC/dashboard contexts; different model | Partial |
| WebSocket location stream | no dedicated tracking stream in Secure backend | Gap |

Bottom line: this is a **new module domain** for Secure, not a small extension.

---

## 2. Recommended Secure module placement

### 2.1 New module
Add a new Secure module section: **Asset Tracking**.

Recommended top-level routes:
- `/asset-tracking` (operator dashboard)
- `/asset-tracking/admin` (admin console)
- `/asset-tracking/analytics` (long-range analytics)

### 2.2 Property-level integration
Embed relevant parts at property level:
- Property detail tab: **Asset Tracking**
- Sub-tabs: Floors & Spaces, Asset Registry, Live Map, Alerts

### 2.3 Account-level integration
- Add Asset Tracking module toggle in Account Settings → Modules
- Add role permissions under Account Settings → People/Teams

### 2.4 Sensor domain split (important for UI)

Keep two distinct sensor domains in Secure:

1. **Physical & Technical > Sensors** (existing property section)
   - Purpose: fixed building/infrastructure sensors
   - Examples: HVAC probes, metering devices, plant telemetry, fixed environment sensors
   - Ownership: building operations / technical systems

2. **Asset Tracking > Tracking Sensors** (new module)
   - Purpose: mobile tracking tags/beacons linked to tracked assets
   - Examples: asset tags, BLE/Wirepas beacons, location transmitters
   - Ownership: operational asset tracking workflows

**Rule:** Do not merge these into one list. They can share UI patterns, but must remain separate data models, pages, and APIs.

### 2.5 Where Asset Types should live

Add **Asset Types** under the **Asset Tracking** module, not under Physical & Technical.

Recommended governance:
- **Account-level Asset Type master list** (shared taxonomy across properties)
- Property-level usage/filtering when assigning assets in a property

Recommended UI placement:
- `Asset Tracking > Configuration > Asset Types`
- `Asset Tracking > Configuration > Asset Categories`
- `Asset Tracking > Assets` (uses category/type for each asset row)

---

## 3. Backend mapping (Secure SoR)

Minimum additional entities needed (Supabase):
- `tracking_floors` (or enrich existing floor model)
- `tracking_spaces` with polygon bounds
- `tracking_asset_categories`
- `tracking_asset_types`
- `tracking_assets`
- `tracking_sensors`
- `tracking_current_locations`
- `tracking_location_history`
- `tracking_reservations`
- `tracking_alerts`
- `tracking_devices` (optional first phase)

Also needed:
- WebSocket/event ingest path for live updates
- Point-in-polygon + geofence rules pipeline
- RLS scoping by `account_id` and `property_id`

---

## 4. Migration strategy (phased)

### Phase 1 — UI shell + mocked data
- Add Asset Tracking routes and sidebar entry
- Add Live Map page shell and Asset list panel
- Add Admin console shell sections

### Phase 2 — Core CRUD
- Floors/Spaces (with bounds)
- Asset categories/types/assets
- Sensors + asset linking
- Alerts list/ack/dismiss

### Phase 3 — Live tracking
- WebSocket ingest + current location updates
- History playback
- Reservation workflows

### Phase 4 — Advanced analytics
- Operational dashboards (heatmap/timeline/inactive)
- Analytics dashboard (7d/30d/90d/1yr)

---

## 5. Lovable prompts (copy-paste ready)

### Prompt 1: Create Asset Tracking module shell

```
Create a new Secure module named "Asset Tracking".

1. Add routes:
   - /asset-tracking
   - /asset-tracking/admin
   - /asset-tracking/analytics

2. Add sidebar entry "Asset Tracking" under modules, linking to /asset-tracking.

3. Build page shells using existing Secure layout patterns (Header, Sidebar, GradientBackground/Card style).

4. /asset-tracking should contain:
   - Left panel: Asset list with filters (search, status, category, availability)
   - Main panel: Live floor map placeholder and selected floor picker
   - Top-right: alerts bell and profile dropdown (reuse Secure patterns)

5. Keep this phase frontend-only with mock data and TODO comments for backend wiring.
```

---

### Prompt 2: Add Property-level Asset Tracking tab

```
On Property Detail (/properties/:id), add a new main tab: "Asset Tracking".

Inside this tab add sub-tabs:
- Floors & Spaces
- Asset Registry
- Live Tracking
- Alerts

Behavior:
1. Scope everything to the current propertyId.
2. Floors & Spaces: list floors and spaces with simple create/edit forms (mock or Supabase if available).
3. Asset Registry: list tracked assets with category/type/status + create/edit.
4. Live Tracking: map placeholder + current asset positions list.
5. Alerts: list with severity/status and actions acknowledge/dismiss.

Do not change existing Property tabs behavior.
```

---

### Prompt 3: Add Admin console section for Asset Tracking

```
Add an Asset Tracking Admin Console route at /asset-tracking/admin, inspired by Asset-tracker-v1 AdminConsole.

Sections in sidebar:
- Overview
- Facility/Profile Settings (rename to Property/Tracking Settings in Secure language)
- Floors & Spaces
- Assets Configuration
- Devices
- Live Tracking
- Alerts
- Dashboards (sub-menu: Operational, Analytics)
- Users/Roles

Requirements:
1. Use Secure design system and components.
2. Keep section state in URL query param (?section=...) or route segments.
3. Start with mocked data and isolate data hooks for later backend integration.
```

---

### Prompt 4: Add operational dashboards for Asset Tracking

```
Under /asset-tracking/admin dashboards, add an "Operational" dashboard page with three blocks:
- Asset Heatmap
- Asset Movement Timeline
- Inactive Sensors

Requirements:
1. Add short range selectors: 15m, 1h, 24h.
2. Add floor selector.
3. Keep chart cards consistent with Secure dashboard style.
4. Use mock data now; add TODO adapter hooks for backend data.
```

---

### Prompt 5: Add analytics dashboard (long range)

```
Add an "Analytics" dashboard page under Asset Tracking admin with long-range controls.

Requirements:
1. Time presets: 7d, 30d, 90d, 1yr, plus custom range.
2. Floor selector.
3. Tabs:
   - Utilization Trends
   - Asset Comparison
   - Space Analysis
4. Metrics cards at top: Avg Utilization, Peak Hour, Most Used Space, Total Distance.
5. Use Recharts and Secure card styling.
6. Mock data for now; structure hooks for future API integration.
```

---

### Prompt 6: Wire secure backend adapter layer (non-breaking)

```
Prepare data access adapters for Asset Tracking without breaking existing Secure modules.

1. Create hooks namespace: src/hooks/asset-tracking/*
2. Add interfaces for:
   - floors, spaces, assets, sensors, current locations, history, reservations, alerts
3. Implement mock adapters first with the same response shapes expected by UI.
4. Add clear TODO blocks for Supabase table wiring and RLS filtering by account/property.
5. Ensure no existing Data Library/Data Centre routes are modified.
```

---

## 6. Practical recommendation

Use `Asset_Tracker_Backend_API_Specification.md` as the source for domain behavior and endpoint shapes, and use `Asset_Tracker_Component_Migration_Guide.md` as the source for reusable component inventory.

For Secure mapping, do **not** copy the module 1:1 as a separate app. Instead:
- keep Secure layout/navigation,
- port the tracking domain concepts,
- and implement via phased integration under a new **Asset Tracking** module.

---

## 7. Key source references

- `Asset-tracker-v1/src/App.tsx`
- `Asset-tracker-v1/src/pages/AdminConsole.tsx`
- `Asset-tracker-v1/src/pages/Dashboard.tsx`
- `Asset-tracker-v1/src/components/admin/AdminSidebar.tsx`
- `Asset-tracker-v1/docs/Asset_Tracker_Backend_API_Specification.md`
- `Asset-tracker-v1/docs/Asset_Tracker_Component_Migration_Guide.md`
- `Asset-tracker-v1/.lovable/plan.md`

---

*Last updated: 2026-03-31*

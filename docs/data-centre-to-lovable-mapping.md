# Data Centre Rakesh Specs → Secure SoR Lovable Mapping

This document compares the **Data Centre Rakesh Specs** UI (`center-view-io`) with the **Secure SoR Lovable** UI and outlines what can be mapped in, with Lovable prompts where applicable.

**Target platform:** Secure SoR backend (Supabase) + Lovable frontend  
**Source:** Data Centre Rakesh Specs (`/Users/anamariaspulber/Documents/[Apex TIGRE]/1_Secure/Repositories/Data Centre Rakesh Specs/center-view-io`)

---

## 0. Clarified Placement (Summary)

| Feature | Where to add in Lovable |
|---------|-------------------------|
| **Spaces** | ✅ Already exists under Property → Spaces tab (TenancyScopeTab) |
| **Racks** | Property Detail → add as new tab **next to** Spaces |
| **Equipment** | Property Detail → Physical & Technical → add **after** Building Systems (new sub-tab) |
| **Dashboard Home** | Add **asset-type dropdown** on current landing (/dashboard). Office → current Index; Data Centre → HomeV2 from Rakesh |
| **Tenants** | Add as a **new section** in Secure (dedicated Tenants area) |
| **Alerts** | Add under **Account Settings** (new tab) |
| **Funds** | Defer – add later |

---

## 1. Feature Comparison

| Feature | Data Centre (Rakesh) | Lovable (Secure SoR) | Mapping Action |
|---------|----------------------|----------------------|----------------|
| **Home / Dashboard** | Metrics, Grafana, alerts, facilities (HomeV2) | Index at /dashboard | **Add dropdown** – switch by asset type: Office → Index; Data Centre → HomeV2 |
| **Properties** | CRUD, bulk import, property detail | PropertiesIndex, PropertyDetail | ✅ Align – both have |
| **Property Detail** | Tabs, tenants | PropertyDetail (Overview, Spaces, Physical, Integrations) | Add Racks tab, Equipment sub-tab, Tenants section |
| **Spaces** | Full CRUD, floor, area_sqm | ✅ **TenancyScopeTab** under Property → Spaces | No change – already present |
| **Racks** | Full CRUD, space-linked | Not present | **Add** tab under Property, next to Spaces |
| **Equipment** | Full CRUD, UPS/Server/Network/Storage | Not present | **Add** sub-tab under Physical & Technical, after Building Systems |
| **Sensors** | Full CRUD, telemetry | IoTSection under Property | Replace / enhance IoTSection with Data Centre Sensors pattern |
| **Tenants** | Dedicated Tenants page, CRUD | PropertyStakeholders | **Add** Tenants as new section in Secure |
| **Alerts** | Dedicated Alerts page | Not present | **Add** under Account Settings (new tab) |
| **Funds** | FundsList, FundDetail | Not present | **Defer** – add later |

---

## 1a. Dashboard Comparison: Rakesh vs Lovable Data Centre

| Rakesh Dashboard | Content | Lovable Equivalent | Gap / Action |
|------------------|---------|--------------------|--------------|
| **Sustainability** (`/sustainability`) | Full drill-down: 8 tabs (PUE, Ranking, Carbon, Water, Payback, ERF, Grid, Permits). Each tab has Recharts (Line, Bar, Pie), KPI cards, breakdown tables. Property filter. Mock data. | **None.** DCLanding has ESG tile → DCEsgDashboard (placeholder). DCPortfolioOverview and DCPropertyDashboard have KPIs but no Sustainability-style drill-down. | **Add** Sustainability Drill-Down as a new dashboard (or integrate into DCLanding / property flow). Rakesh SustainabilityDrilldown is ~1000 lines; can be ported as a new route. |
| **Dashboard → Overview** (`/dashboard/overview`) | Single Grafana panel "System Overview" (600px height). Property filter. | **None.** DCLanding is a card hub. DCPortfolioOverview has KPI cards, no Grafana. | **Add** System Overview page or embed Grafana panel in DCLanding / DCPortfolioOverview when Data Centre selected. |
| **Dashboard → Alerts** (`/dashboard/alerts`) | Alert summary cards (Critical, Warning, Info, Total). Grafana "Real-time Alerts Dashboard" panel. AlertsPanel (recent 5 alerts). Property filter. 30s refresh. | **None** (per user: add Alerts under Account Settings). | Alerts **placement** differs: Rakesh = under Dashboard; Lovable = under Account Settings. **Content** (summary cards + list) can match; Grafana Alerts panel optional. |
| **Home V2** (`/home-v2`) | Sustainability metrics (PUE, Carbon Intensity, WUE, Payback, ERF, Grid). Grafana panels (Energy, Temp/Humidity, Occupancy, Real-time). Alerts panel. Facilities overview. | Used when user selects **Data Centre** on landing dropdown (Prompt 1). | Already mapped in Prompt 1. |
| **DCLanding** (Lovable) | Card hub: Portfolio, Property, PUE, Capacity, Cooling, ESG, Geopolitical, Climate, Cyber. | — | Rakesh has no equivalent card hub. Lovable’s structure is richer (9 dashboards) but most are placeholders. |
| **DCPortfolioOverview** (Lovable) | KPI cards from Supabase (PUE, IT Load, Renewable, etc.) + property list. | — | Rakesh Home/HomeV2 have metric cards but different source (API vs Supabase). Rakesh SustainabilityDrilldown has deeper PUE/Carbon/Water content. |
| **DCPueDashboard** (Lovable) | Placeholder: Annualised PUE, PUE Benchmark. "Requires time-series" notes. | — | Rakesh SustainabilityDrilldown **PUE tab** has: Current PUE, consumption, IT load, trend chart, power breakdown. Rakesh content can enrich DCPueDashboard. |
| **DCCoolingDashboard** (Lovable) | Placeholder. | — | Rakesh SustainabilityDrilldown **Water tab** has WUE, cooling types, trend. Partial overlap. |
| **DCEsgDashboard** (Lovable) | Placeholder (GRESB, EED, Scope 2). | — | Rakesh SustainabilityDrilldown **Carbon** and **Permits** tabs have related content (carbon intensity, permits compliance). |

### Dashboard comparison summary

- **Sustainability Drill-Down (Rakesh)** is the richest DC dashboard. Lovable has no equivalent. Recommend porting as a new route (e.g. `/dashboards/data-centre/sustainability`) or as a new tile on DCLanding.
- **Dashboard Overview (Rakesh)** is a single Grafana panel. Add to Lovable as a Grafana embed (in DCLanding or a dedicated Overview page) when Data Centre view is active.
- **Dashboard Alerts (Rakesh)** → Already mapped to Account Settings. Content (summary cards + list) can mirror Rakesh; Grafana Alerts panel optional.
- **Rakesh SustainabilityDrilldown** can feed content into Lovable’s DCPueDashboard, DCCoolingDashboard, DCEsgDashboard (PUE tab → PUE, Water tab → Cooling, Carbon/Permits → ESG).

---

## 2. Backend Schema Alignment

### 2.1 What Secure SoR Already Has (Supabase)

| Table | Use for Data Centre |
|-------|----------------------|
| `properties` | ✅ Use as-is; has address, city, country, asset_type, etc. |
| `spaces` | ⚠️ Use with mapping: `floor_reference` ↔ floor, `area` ↔ area_sqm. Secure SoR has `space_class`, `control`, `parent_space_id`; Data Centre has `total_racks` (can be computed or stored). |
| `dc_metadata` | ✅ Use for DC-specific fields (tier, PUE, capacity, etc.) |
| `systems` | Building systems; not 1:1 with Data Centre Equipment |
| `meters` | Meters; can link to sensors conceptually |

### 2.2 What Secure SoR Does NOT Have (needs migrations)

| Concept | Data Centre Model | Suggested Action |
|---------|-------------------|------------------|
| **Racks** | space_id, u_height, power_capacity, status | Add `racks` table (property_id, space_id, name, u_height, power_capacity, status) |
| **Equipment** | type (UPS/Server/Network/Storage), manufacturer, model, location | Add `equipment` table (account_id, property_id?, rack_id?, type, name, manufacturer, model, serial_number, status) |
| **Sensors** | category, type, property/space/rack/equipment links, telemetry | Add `sensors` table + `sensor_telemetry` (or use existing telemetry store). See API_DOCUMENTATION.md for payloads. |

**Recommendation:** Add migrations for `racks`, `equipment`, `sensors` (and optional `sensor_telemetry`) before building full Data Centre CRUD in Lovable. Until then, you can build UI with mock data or a separate Data Centre API proxy.

---

## 3. Route & Placement Mapping (Lovable)

| Data Centre Feature | Lovable Placement | Notes |
|---------------------|-------------------|-------|
| **Landing / Home** | `/dashboard` (Index) | Add asset-type dropdown; Office → Index; Data Centre → HomeV2 |
| **HomeV2 (Data Centre)** | Component used when Data Centre selected | Port HomeV2 from Rakesh; sustainability metrics, Grafana, alerts |
| **Properties** | `/properties`, `/properties/:id` | ✅ Exists |
| **Spaces** | `/properties/:id` → **Spaces** tab | ✅ TenancyScopeTab already exists |
| **Racks** | `/properties/:id` → **Racks** tab (new, next to Spaces) | New tab; requires `racks` table |
| **Equipment** | `/properties/:id` → Physical & Technical → **Equipment** sub-tab (after Building Systems) | New sub-tab; requires `equipment` table |
| **Building Systems** | Physical & Technical → Building Systems | ✅ Exists |
| **IoT / Sensors** | Physical & Technical → IoT (Sensors & Devices) | Enhance IoTSection with Data Centre Sensors CRUD |
| **Tenants** | New **Tenants** section (route TBD: `/tenants` or under properties) | Add as section in Secure |
| **Alerts** | `/account/settings` → **Alerts** tab | Add tab to AccountSettings |
| **Funds** | Defer | Add later |

---

## 5. Lovable Prompts (Copy-Paste Ready)

Use these prompts in Lovable to implement each feature. Run in order where dependencies exist.

---

### Prompt 1: Asset-type dropdown on landing – switch between Office and Data Centre Home

**When:** You want the main landing (/dashboard) to show different content based on asset type.

```
On the dashboard landing page (/dashboard), add an asset-type dropdown that switches the main content:

1. **Dropdown placement:** In the header/toolbar area (near the property filter or AssetTypeFilterBar). Label: "View as" or "Asset type" with options: **Office** | **Data Centre**.

2. **Behaviour:**
   - When user selects **Office**: show the current Index/dashboard content (sustainability overview, KPIs, tiles, etc.).
   - When user selects **Data Centre**: show the HomeV2-style content from the Data Centre Rakesh spec — sustainability metrics (PUE, Carbon Intensity, WUE, Carbon Payback, ERF, Grid Interaction), Grafana panels (Energy, Temp/Humidity, Occupancy, Real-time), alerts panel, facilities overview, property selector.

3. **Persistence:** Store the selected asset type in state (or localStorage) so it persists across navigation. Default to Office if no preference.

4. **HomeV2 reference:** Copy the layout and components from `Data Centre Rakesh Specs/center-view-io/src/pages/HomeV2.tsx` — metric cards, Grafana iframes, AlertsPanel, property dropdown. Adapt to use Lovable's contexts (PropertyContext, AccountContext), Supabase, and styling (GradientBackground, Card, etc.).

5. **Grafana:** If VITE_GRAFANA_* env vars exist, use them for the Data Centre view. Otherwise, show placeholder panels.
```

---

### Prompt 2: Add Racks tab under Property (next to Spaces)

**When:** Backend has `racks` table. Add as a new tab on Property Detail, **next to** the existing Spaces tab.

```
On Property Detail (/properties/:id), add a "Racks" tab next to the existing "Spaces" tab.

1. **Placement:** Add <TabsTrigger value="racks">Racks</TabsTrigger> to the main tabs (alongside Overview, Spaces, Physical & Technical, Integrations & Evidence). Add <TabsContent value="racks"> with a RacksSection component.

2. **RacksSection content:**
   - List racks for this property (filter by property_id). Table: name, space (join), u_height, power_capacity, status (active | maintenance | inactive), total_equipment.
   - Filter by space_id (dropdown of spaces in this property).
   - CRUD: Add rack (name, space_id, u_height, power_capacity, status). Edit/Delete with confirmation.

3. **Supabase:** supabase.from('racks').select('*, spaces(name)').eq('property_id', propertyId). Requires `racks` table. If not present, use mock data.

4. **Styling:** Match existing property tab patterns (TenancyScopeTab, PhysicalTechnicalSection).
```

---

### Prompt 3: Add Equipment sub-tab (after Building Systems)

**When:** Backend has `equipment` table. Add under Physical & Technical, **after** Building Systems.

```
On Property Detail → Physical & Technical, add an "Equipment" sub-tab after "Building Systems".

1. **Placement:** In PhysicalTechnicalSubTabs, add <TabsTrigger value="equipment">Equipment</TabsTrigger> after Building Systems. Add <TabsContent value="equipment"> with EquipmentSection component.

2. **EquipmentSection content:**
   - List equipment for this property. Table: name, type (UPS | Server | Network | Storage), manufacturer, model, location, rack (optional), status.
   - Filter by type, rack_id.
   - CRUD: Add (name, type, manufacturer, model, serial_number, location, rack_id optional, status). Edit/Delete.

3. **Supabase:** supabase.from('equipment').select('*, racks(name)').eq('property_id', propertyId). Requires `equipment` table. If not present, use mock data.

4. **Styling:** Match Building Systems / PhysicalTechnicalSection patterns.
```

---

### Prompt 4: Enhance IoTSection with Data Centre Sensors CRUD

**When:** You want the IoT (Sensors & Devices) sub-tab under Property to match the Data Centre Sensors spec.

```
Enhance the IoTSection (Property → Physical & Technical → IoT) with full Sensors CRUD patterned after Data Centre Rakesh spec:

1. **List view:** Table of sensors: sensor_id/name, type, category (Energy & Power | Environmental | Occupancy & Access | IT Infrastructure | Water/Leak | Fire Safety), space, rack, status, last update.
2. **Filters:** category, status (active | warning | error | offline), space.
3. **Detail drawer:** On row click, open drawer with sensor details + telemetry (formatted by type: Power Meter, Temperature, etc.). Reference: center-view-io formatTelemetryForDisplay.
4. **CRUD:** Add/Edit/Delete sensors. Form: sensor_id, type, category, space_id, rack_id, equipment_id, interval_minutes, location.
5. **Data source:** Supabase `sensors` when available; else mock. CSV import optional.
6. **Styling:** Match IoTSection / property patterns.
```

---

### Prompt 5: Add Tenants section in Secure

**When:** You want a dedicated Tenants area in the app.

```
Add Tenants as a new section in Secure SoR:

1. **Route:** Add /tenants (or nest under /properties with a tenants index). Add "Tenants" to sidebar.

2. **Content:** List tenants across the account (or filter by property). Table: name, property, contact, lease dates, status. CRUD: Add tenant (property_id, name, contact, lease start/end, etc.). Edit/Delete.

3. **Backend:** Requires tenants or property_tenants table. If not present, use mock data. Align with Data Centre Rakesh AddPropertyTenantDialog / EditPropertyTenantDialog patterns.

4. **Styling:** Match Lovable patterns (GradientBackground, Sidebar, Header, Card, Table).
```

---

### Prompt 6: Add Alerts tab under Account Settings

**When:** You want Alerts to live under Account Settings.

```
In Account Settings (/account/settings), add an "Alerts" tab.

1. **Placement:** Add <TabsTrigger value="alerts">Alerts</TabsTrigger> to the AccountSettings tabs (alongside Organisation, Modules, People, Teams, Teamspaces). Add <TabsContent value="alerts"> with AlertsTab component.

2. **AlertsTab content:**
   - List alerts (from Grafana API, alerts table, or mock). Columns: severity (critical | warning | info), message, property, timestamp, state (active | resolved).
   - Filter by property, severity, state.
   - Optional: acknowledge, resolve actions.

3. **Data source:** Wire to Grafana /grafana/alerts or equivalent when available. Use mock for MVP.

4. **Styling:** Table with severity badges. Match OrganisationTab / PeopleTab patterns.
```

---

### Prompt 7: Add Sustainability Drill-Down to Data Centre Dashboards

**When:** You want the full Rakesh Sustainability Drill-Down in Lovable's Data Centre section.

```
Add a Sustainability Drill-Down page to Data Centre Dashboards.

1. **Route:** Add /dashboards/data-centre/sustainability. Add a "Sustainability Drill-Down" tile/card to DCLanding (/dashboards/data-centre) in the card grid, linking to this route.

2. **Page structure:** Port the layout and content from Data Centre Rakesh Specs/center-view-io/src/pages/SustainabilityDrilldown.tsx:
   - Header with title "Sustainability Metrics Drill-Down" and subtitle.
   - Property filter dropdown (All Properties + list from Supabase properties where asset_type = 'data_centre').
   - 8 tabs: PUE | Ranking | Carbon | Water | Payback | ERF | Grid | Permits.

3. **Tab content (use Recharts — LineChart, BarChart, PieChart):**
   - **PUE:** Current PUE, Data Center Consumption, IT Equipment (Racks) cards; PUE calculation formula; PUE trend line chart; power consumption breakdown (IT Equipment, Cooling, UPS, Lighting, Other).
   - **Ranking:** PUE ranking table by property (property, PUE, rank, efficiency).
   - **Carbon:** Current carbon intensity (gCO2/kWh), target, calculation; trend chart; sources breakdown (Grid, Solar PPA, Wind PPA, Coal).
   - **Water:** WUE (L/kWh), target, total water, cooling; trend chart; cooling types breakdown (Evaporative Towers, Adiabatic, Economizer, Humidification).
   - **Payback:** Carbon payback years, construction carbon, annual savings; breakdown by phase (Steel & Concrete, IT Equipment, MEP, Transport).
   - **ERF:** Energy Reuse Factor %, waste heat, reused heat; trend chart; applications (District Heating, Office Heating, DHW, Absorption Cooling).
   - **Grid:** Demand Response participation %, events, savings; event types breakdown.
   - **Permits:** Power, Land, Water permit cards (status, number, capacity/allocation, expiry, compliance, conditions).

4. **Data:** Use mock data generators (as in Rakesh) for MVP. Property filter drives the mock values (property-specific offsets). Later wire to Supabase/dc_metadata where applicable.

5. **Styling:** Match Lovable patterns (GradientBackground, Sidebar, Header, Card, Tabs, Progress). Use shadcn components. Recharts for charts.
```

---

### Prompt 8: Add System Overview to Data Centre Dashboards

**When:** You want the Grafana System Overview panel in the Data Centre section.

```
Add a System Overview page to Data Centre Dashboards.

1. **Route:** Add /dashboards/data-centre/overview. Add an "Overview" or "System Overview" tile/card to DCLanding (/dashboards/data-centre) in the card grid, linking to this route. If DCLanding already has a Portfolio Overview tile, add a separate "System Overview" tile for the Grafana embed.

2. **Page content:**
   - Header: "Dashboard Overview" (or "System Overview"), subtitle "Real-time monitoring and analytics from Grafana".
   - Property filter dropdown (All Properties + list from Supabase).
   - Single Grafana panel: Use GrafanaPanel component (or equivalent iframe) with dashboardId="system-overview" (or the actual Grafana dashboard ID from VITE_GRAFANA_DASHBOARD_* env vars). Height ~600px.

3. **Grafana config:** If VITE_GRAFANA_BASE_URL and a system-overview dashboard ID exist in env, use them. Otherwise show a placeholder card: "Grafana System Overview — configure VITE_GRAFANA_* env vars to embed."

4. **Styling:** Match DCPortfolioOverview / DCLanding layout. Use GradientBackground, Sidebar, Header, DCBreadcrumb.
```

---

### Prompt 9: Reuse Rakesh content to enrich DCPueDashboard, DCCoolingDashboard, DCEsgDashboard

**When:** You want to replace placeholder content in the existing DC dashboards with Rakesh-style charts and breakdowns.

```
Enrich the existing Data Centre dashboards (DCPueDashboard, DCCoolingDashboard, DCEsgDashboard) with content from Rakesh SustainabilityDrilldown.

1. **DCPueDashboard** (/dashboards/data-centre/:propertyId/pue):
   - Add KPI cards: Current PUE, Data Center Consumption (kW), IT Equipment / Racks Consumption (kW). Use dc_metadata or mock.
   - Add PUE trend line chart (Recharts LineChart) — monthly PUE over current year. Use mock trend data if no time-series.
   - Add Power Consumption Breakdown: IT Equipment, Cooling, UPS & Power Distribution, Lighting, Other — with percentages and kW. Use mock or derive from dc_metadata.
   - Reference: Rakesh SustainabilityDrilldown PUE tab (lines 382–460 in SustainabilityDrilldown.tsx).

2. **DCCoolingDashboard** (/dashboards/data-centre/:propertyId/cooling):
   - Add KPI cards: WUE (L/kWh), target, total water, cooling water.
   - Add WUE trend line chart — monthly WUE. Use mock.
   - Add Cooling Types breakdown: Evaporative Cooling Towers, Adiabatic Cooling, Air-Side Economizer, Humidification — with water usage and percentages.
   - Reference: Rakesh SustainabilityDrilldown Water tab.

3. **DCEsgDashboard** (/dashboards/data-centre/:propertyId/esg):
   - Add Carbon Intensity section: current gCO2/kWh, target, calculation formula. Add trend chart.
   - Add Carbon sources breakdown: Grid (Natural Gas), Solar PPA, Wind PPA, Grid (Coal) — with emissions and percentages.
   - Add Permits section: Power, Land, Water permit cards (status, number, capacity/allocation, expiry, compliance %, conditions). Use mock data.
   - Reference: Rakesh SustainabilityDrilldown Carbon and Permits tabs.

4. **Data:** Use mock data for charts and breakdowns until meter/telemetry data is available. Property filter (propertyId from route) should drive mock values for consistency.

5. **Styling:** Match existing DC dashboard patterns (backdrop-blur cards, apex-* colors, Recharts). Keep DCBreadcrumb, Sidebar, Header.
```

---

### Prompt 10: Add persona/audience tags to Data Centre dashboard cards (DCLanding)

**When:** You want to show which audience each dashboard is for on the DCLanding page.

```
Add persona/audience tags to each Data Centre dashboard card on the DCLanding page (/dashboards/data-centre).

1. **Tag styling:** On each dashboard card in the DCLanding grid, add a small tag row below the card title. Each tag is a compact badge: text-xs, rounded-full, px-2 py-0.5. Colours:
   - Asset Manager → bg-blue-100 text-blue-700
   - Sustainability Manager → bg-green-100 text-green-700
   - Facility Manager → bg-orange-100 text-orange-700
   - DC Operations → bg-purple-100 text-purple-700

2. **Tags per card:**

   | Card / Route | Tags |
   |---|---|
   | Portfolio Overview | Asset Manager, Sustainability Manager |
   | Single Property Overview | Asset Manager, Facility Manager |
   | PUE Deep-Dive | Facility Manager, Sustainability Manager |
   | Capacity & Power Chain | Facility Manager, Asset Manager |
   | Cooling & Water | Facility Manager |
   | ESG & Reporting Readiness | Sustainability Manager, Asset Manager |
   | Geopolitical & Conflict Risk | Asset Manager |
   | Climate & Natural Hazard Risk | Asset Manager, Sustainability Manager |
   | Cyber & Critical Infrastructure | Asset Manager |
   | Sustainability Drill-Down | Sustainability Manager, Facility Manager |
   | System Overview | Facility Manager, DC Operations |

3. **Legend:** Add a legend row above the card grid (below the page header) showing all four badge types with label "Dashboard audience:". Keep it compact — one line, flex-wrap.

4. **Display only:** Tags are display-only. No filter behaviour. Do not change card layout, routing, or any other functionality.

5. **Layout:** Tag row sits between the card title and the card description/subtitle (or below the title if no description). Maintain all existing card styling (backdrop-blur, border, hover states).
```

---

## 6. Implementation Order

1. **Backend:** Add migrations for `racks`, `equipment`, `sensors` (and `sensor_telemetry` if needed). See API_DOCUMENTATION.md in Data Centre Rakesh Specs for field definitions.
2. **Lovable – Phase 1 (no new tables):**
   - Asset-type dropdown on landing + HomeV2 for Data Centre (Prompt 1)
   - Alerts tab under Account Settings (Prompt 6)
3. **Lovable – Phase 2 (with new tables):**
   - Racks tab under Property (Prompt 2)
   - Equipment sub-tab after Building Systems (Prompt 3)
   - Enhance IoTSection with Sensors CRUD (Prompt 4)
4. **Lovable – Phase 3:**
   - Tenants section (Prompt 5)
5. **Deferred:**
   - Funds module (add later)

6. **Dashboard enrichment (from Rakesh) — Prompts 7, 8, 9:**
   - **Prompt 7:** Sustainability Drill-Down → `/dashboards/data-centre/sustainability`
   - **Prompt 8:** System Overview → `/dashboards/data-centre/overview`
   - **Prompt 9:** Enrich DCPueDashboard, DCCoolingDashboard, DCEsgDashboard with Rakesh content

7. **DCLanding UX — Prompt 10:**
   - **Prompt 10:** Add persona/audience tags (Asset Manager, Sustainability Manager, Facility Manager, DC Operations) to each dashboard card on DCLanding

---

## 7. Screenshots (Optional)

For visual alignment, capture screenshots from Data Centre Rakesh of:
- HomeV2 (Data Centre dashboard) layout
- Racks list + create dialog
- Equipment list
- Sensors list + telemetry drawer
- Alerts list

Paste into Lovable with each prompt: "Make the layout/styling match this screenshot."

---

## 8. Reference Files

| File | Purpose |
|------|---------|
| `Data Centre Rakesh Specs/center-view-io/src/pages/HomeV2.tsx` | **Primary** – Data Centre dashboard (PUE, WUE, metrics, Grafana) |
| `Data Centre Rakesh Specs/center-view-io/src/pages/SustainabilityDrilldown.tsx` | **Rich drill-down** – 8 tabs: PUE, Ranking, Carbon, Water, Payback, ERF, Grid, Permits (Recharts) |
| `Data Centre Rakesh Specs/center-view-io/src/pages/dashboard/Overview.tsx` | Grafana System Overview panel |
| `Data Centre Rakesh Specs/center-view-io/src/pages/dashboard/DashboardAlerts.tsx` | Alerts summary cards + Grafana + AlertsPanel |
| `Data Centre Rakesh Specs/center-view-io/API_DOCUMENTATION.md` | API contracts, request/response shapes |
| `Data Centre Rakesh Specs/center-view-io/API_INTEGRATION_STATUS.md` | What's wired, what's mock |
| `Data Centre Rakesh Specs/center-view-io/src/pages/Spaces.tsx` | Spaces UI reference (Lovable already has Spaces under Property) |
| `Data Centre Rakesh Specs/center-view-io/src/pages/Sensors.tsx` | Sensors UI + telemetry formatter |
| `Data Centre Rakesh Specs/center-view-io/src/pages/Home.tsx` | Original dashboard metrics, Grafana, facilities |
| `Secure-SoR-backend/docs/database/schema.md` | Supabase schema |

---

*Last updated: 2025-02-24*

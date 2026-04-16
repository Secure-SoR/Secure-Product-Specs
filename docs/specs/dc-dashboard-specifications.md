# Data Centre Dashboard Specifications
**Secure SoR — Data Centre Asset Type**
*Version 1.0 | March 2026 | Owner: Anne*

This spec follows [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) (10 required sections).

---

## 1. Feature Overview

Data centre dashboards are a new module alongside the existing Energy, Carbon, Risk, and Governance dashboards. They are available only when an account has at least one property with `asset_type = 'data_centre'`.

Dashboards are split into two groups:

- **Operational Dashboards** (Sections 1–6): Internal facility performance — PUE, capacity, cooling, energy, ESG
- **Risk Intelligence Dashboards** (Sections 7–9): External situational intelligence via SitDeck OSINT integration

**Who uses it:** Asset managers and operations for DC properties. **Business problem:** Single place to monitor PUE, capacity, cooling, water, ESG readiness, and external risk (geopolitical, climate, cyber) per DC property and portfolio.

---

## 2. Functional Requirements

- User selects Asset Type = Data Centre (and optionally a property) in Dashboards filter → DC landing at `/dashboards/data-centre`. User sees portfolio overview or selects a property → property-level overview. User navigates to a specific dashboard (PUE, Capacity, Cooling, ESG, Geopolitical, Climate, Cyber) via tabs or links. Each dashboard shows KPI tiles and charts/tables as defined in sections below. Expected system response: data from dc_metadata, data_library_records, and (when wired) SitDeck; empty states when no data.

---

## 3. API Endpoints / Data Surface

- **Supabase:** `properties`, `dc_metadata`, `data_library_records` (energy, water, etc.). Queries by account_id and property_id. No REST API in backend; app uses Supabase client. **SitDeck (optional):** External API for telemetry and OSINT; see [secure-dc-spec-v2.md](secure-dc-spec-v2.md) §4. Dashboards are read-only; no write endpoints.

---

## 4. Database Schema

- **properties:** asset_type = 'data_centre', NLA, etc. **dc_metadata:** property_id, tier_level, design_capacity_mw, current_it_load_mw, target_pue, renewable_energy_pct, water_usage_effectiveness_target, etc. **data_library_records:** subject_category (energy, water, waste) for YTD and trend. See [docs/database/schema.md](../database/schema.md) and [secure-dc-spec-v2.md](secure-dc-spec-v2.md) §2.2.

---

## 5. Business Logic & Validation Rules

- PUE = Total Facility Power ÷ IT Load; WUE = water / energy. Capacity utilisation = current_it_load_mw ÷ design_capacity_mw. Portfolio KPIs = aggregates (avg, sum) across DC properties. Risk dashboards: data from SitDeck OSINT when configured; else placeholder or empty. No user input on dashboards; display only.

---

## 6. Authentication & Authorization

- All dashboard routes behind **ProtectedRoute**. RLS on properties, dc_metadata, data_library_records by account_id. User sees only DC properties in their account. No role-based restriction beyond account membership.

---

## 7. State & Workflow

- No state machine. Dashboards reflect current snapshot of dc_metadata and data_library_records. SitDeck sync (if used) may run on schedule or on-demand; dashboard shows latest synced data. No multi-step workflow on dashboard pages.

---

## 8. Error Handling

- If Supabase query fails, show inline error or empty state ("Unable to load data") per tile or chart. If SitDeck API unavailable, risk dashboards show placeholder or "Data unavailable". No specific error codes; generic user-facing messages.

---

## 9. External Integrations & Events

- **SitDeck DCIM:** Telemetry for PUE, IT load, cooling (when integrated). **SitDeck OSINT:** Geopolitical, climate, cyber risk data for risk intelligence dashboards. No webhooks or events from dashboards to external systems; dashboards consume data only.

---

## 10. Non-Functional Requirements

- **Performance:** Queries scoped by property_id and account_id; index dc_metadata(property_id). Avoid unbounded loads; paginate or limit table rows if needed. **Logging:** Optional audit log for dashboard view or export. **Security:** RLS only; no dashboard-specific rate limits in spec.

---

## Routes

| Dashboard | Route |
|---|---|
| Portfolio Overview | `/dashboards/data-centre` |
| Single DC Property Overview | `/dashboards/data-centre/:propertyId` |
| PUE Deep-Dive | `/dashboards/data-centre/:propertyId/pue` |
| Capacity & Power Chain | `/dashboards/data-centre/:propertyId/capacity` |
| Cooling & Water | `/dashboards/data-centre/:propertyId/cooling` |
| ESG & Reporting Readiness | `/dashboards/data-centre/:propertyId/esg` |
| Geopolitical & Conflict Risk | `/dashboards/data-centre/:propertyId/geopolitical` |
| Climate & Natural Hazard Risk | `/dashboards/data-centre/:propertyId/climate-hazard` |
| Cyber & Critical Infrastructure Risk | `/dashboards/data-centre/:propertyId/cyber-infrastructure` |

---

## Operational Dashboards

### Dashboard 1: Portfolio Overview

**Audience:** Asset manager with 2+ data centres  
**Purpose:** How is the portfolio performing vs PUE targets? Where are the risks?

#### KPI Tiles

| KPI Tile | Data Source |
|---|---|
| Portfolio PUE (avg + range) | Aggregated from property-level `data_library_records` or SitDeck sync |
| Total IT Load (MW) | Sum across properties |
| Total Energy (MWh YTD) | Sum from `data_library_records` — energy subject category |
| Renewable Energy % (avg) | From `dc_metadata.renewable_energy_pct` or data library RECs |
| Carbon Intensity (kgCO₂e/kWh) | Emissions Engine output |
| Properties at PUE Risk | Where actual PUE > `target_pue` + 0.1 |
| Capacity Utilisation % (avg) | `current_it_load ÷ design_capacity` per property |
| Data Coverage Score | CoverageEngine — Complete / Partial / Unknown per property |

#### Charts & Tables
- **Chart:** PUE trend line by property (12-month rolling)
- **Table:** Property list with PUE, load, renewable %, coverage status, last updated

---

### Dashboard 2: Single DC Property — Overview

**Audience:** Asset manager for a specific property  
**Layout:** Six KPI tiles (top row), then tabbed detail below

#### KPI Tiles

| Tile | Metric |
|---|---|
| Live PUE | From SitDeck or latest data library record — with trend indicator |
| IT Load | MW — current vs design capacity |
| Total Energy | MWh YTD with year-on-year delta |
| Cooling Energy | MWh YTD + % of total energy |
| Water (WUE) | L/kWh — actual vs target |
| Renewable % | % of power from renewables — vs target |

---

### Dashboard 3: PUE Deep-Dive

**Purpose:** Detailed analysis of Power Usage Effectiveness. PUE = Total Facility Power ÷ IT Load Power.

#### Components
- **Time series chart:** PUE by day / week / month — with target PUE overlay
- **PUE component waterfall:** IT load → UPS losses → PDU losses → cooling → lighting → other
- **Temperature correlation:** PUE vs external OAT (if SitDeck provides weather correlation)
- **Annualised PUE:** Rolling 12-month vs prior year
- **PUE benchmark:** vs Tier level norms (Tier III target ~1.4, best-in-class ~1.2)

#### Data Sources
- `dc_metadata.target_pue`
- `data_library_records` for energy readings
- SitDeck sync for live/recent telemetry

---

### Dashboard 4: Capacity & Power Chain

**Audience:** Operations team and asset manager assessing utilisation and headroom

#### Components
- **Capacity gauge:** Current IT load (MW) as % of design capacity — traffic light colouring
- **Power chain diagram:** HV intake → UPS → busbars → PDU → rack (losses at each stage)
- **Hall-level breakdown:** Capacity utilisation per data hall / suite
- **Redundancy view:** N / N+1 / 2N status per power path
- **Forecast:** Capacity depletion date based on load growth trend (simple linear extrapolation)

---

### Dashboard 5: Cooling & Water

**Purpose:** Cooling efficiency and water consumption tracking

#### Components
- **Cooling energy breakdown:** CRAC/CRAH + chiller + cooling tower + free cooling share
- **WUE trend:** Water Usage Effectiveness by month — vs target
- **Cooling efficiency:** kW of cooling per kW of IT load
- **Free cooling hours:** % of hours operating in economiser mode (if available from BMS/SitDeck)
- **Water consumption absolute:** m³/year with year-on-year delta
- **Make-up water:** Volume added to cooling towers (evaporation + blowdown proxy)

---

### Dashboard 6: ESG & Reporting Readiness

**Purpose:** Maps onto existing Secure ESG architecture with data centre-specific additions

#### Components
- **GRESB Data Centre module readiness score:** energy, GHG, water, waste — DC-specific questions
- **EU Energy Efficiency Directive (EED) Article 12 reporting fields:** IT capacity, PUE, temperature, reuse of heat
- **Renewable energy breakdown:** % from direct PPAs, RECs/GOs, grid tariff
- **Scope 2 (market-based):** Based on REC/GO matched energy
- **Scope 2 (location-based):** Based on grid factor × total consumption
- **Data quality:** Evidence coverage per KPI — Complete / Partial / Unknown from CoverageEngine

---

## Risk Intelligence Dashboards (SitDeck Integration)

These three dashboards are added under a **"Risk Intelligence"** tab alongside the operational dashboards. Each is scoped to a single property via its lat/lng coordinates. Data is embedded from SitDeck (iframe or JS SDK); structured risk events that breach thresholds are written to `agent_findings` and `audit_events` via webhook.

> **Integration note:** Property lat/lng coordinates are required in the `properties` table for these dashboards to function. SitDeck account token is stored in Supabase secrets, shared across all DC properties in the account.

---

### Dashboard A: Geopolitical & Conflict Risk

**Route:** `/dashboards/data-centre/:propertyId/geopolitical`  
**Audience:** Asset owner, investment committee  
**Purpose:** Has the geopolitical risk profile of this asset's geography materially changed — and does that affect hold/sell/hedge decisions?

> Data centres are AI infrastructure and strategic targets. State and non-state actors have demonstrated intent and capability to target digital infrastructure in hybrid warfare. Owners need live geopolitical intelligence mapped against their portfolio, not a quarterly report.

#### Widgets

| SitDeck Widget / Feed | What It Shows in Secure |
|---|---|
| **Active Conflicts Map** | World map centred on the property with live conflict zone overlays. Shows proximity of active conflict events. Triggers `agent_finding` (type: `geopolitical_alert`) when a conflict event is logged within a configurable radius (default 500km) |
| **Military & Defense Activity Feed** | Live military activity events in the asset's region. Critical for EMEA and APAC assets near critical infrastructure corridors. Feeds the Risk Diagnosis geopolitical domain |
| **Geopolitical Risk Index** | Country-level political risk score for the asset's jurisdiction, trended over 12 months. Used in SFDR PAI disclosures and lender ESG questionnaires on country risk |
| **SitDeck AI Situation Report** | AI-generated sourced intelligence report for the asset's country/region, cross-referenced against all live SitDeck feeds. Surfaced as a tile in Secure with a deep-link to SitDeck for full detail |

---

### Dashboard B: Climate & Natural Hazard Risk

**Route:** `/dashboards/data-centre/:propertyId/climate-hazard`  
**Audience:** Asset owner, sustainability team, insurers  
**Purpose:** Are there live or recent physical hazard events near the asset that affect its insurance profile, TCFD disclosure, or operational continuity?

> Data centres are physically fixed and energy-intensive. Flood is the most acute threat — cooling systems, UPS, and generators are typically at ground level or in basements. Wildfire creates air quality issues that degrade CRAC filter life and cooling efficiency. Extreme heat directly drives PUE deterioration.

#### Widgets

| SitDeck Widget / Feed | What It Shows in Secure |
|---|---|
| **Flood & River Monitoring (USGS / EA)** | Live flood alert level tile (None / Watch / Warning / Emergency) for the asset location with trend. Triggers `agent_finding` when alert level rises. Permanent event log used for insurance renewal and TCFD acute physical risk disclosure |
| **Wildfire Perimeter Tracker (NASA FIRMS)** | Live wildfire detection near the asset. Relevant for assets in southern Europe, western US, or Australia. Smoke intrusion affects CRAC filter life and cooling efficiency — correlates with PUE data in the operational dashboards |
| **Extreme Weather Alerts (NOAA / Met Office)** | Heat wave, severe storm, and wind alerts. High ambient temperatures drive PUE degradation; storms affect generator fuel logistics and physical plant. Alert events logged as `agent_findings` for TCFD reporting |
| **Earthquake / Seismic Monitor (USGS)** | Recent seismic activity within 300km of the asset. Events above M4.0 trigger an `agent_finding`. Critical for assets in APAC, southern Europe, western US. Relevant for structural insurance and Tier certification compliance |
| **Risk Event History Log** | Append-only log of all SitDeck hazard events that breached alert thresholds for this property. Includes date, event type, severity, source, and `agent_finding` reference. Directly usable in TCFD disclosure and GRESB physical risk assessments |

---

### Dashboard C: Cyber & Critical Infrastructure Risk

**Route:** `/dashboards/data-centre/:propertyId/cyber-infrastructure`  
**Audience:** Asset owner, risk committee  
**Purpose:** Is the digital and energy infrastructure this asset depends on under active threat — and has that threat been documented?

> Data centres are critical national infrastructure. CISA, NCSC, and equivalent agencies publish real-time advisories on threats to digital infrastructure. A DC owner needs to know when the sector their asset sits in is under active cyber campaign or grid attack — even if their specific facility is not yet directly targeted.

#### Widgets

| SitDeck Widget / Feed | What It Shows in Secure |
|---|---|
| **CISA Advisories & Known Exploited Vulnerabilities** | Live CISA advisories filtered for energy and digital infrastructure sectors. Advisories targeting data centre BMS, UPS, or DCIM vendors flagged as high priority and written as `agent_findings` (type: `cyber_advisory`) |
| **Power Grid & Energy Infrastructure Incidents** | Grid stability and energy infrastructure attack events in the asset's country or region. Grid attacks have preceded DC outages in EMEA conflict zones. Validates the importance of N+1/2N redundancy recorded in `dc_metadata` |
| **Daily Intelligence Briefing (SitDeck AI)** | AI-generated morning briefing covering cyber, security, and climate categories for the asset's region. Surfaced as a daily tile in Secure, giving the owner a consolidated intelligence digest without leaving the platform |

---

## Integration Architecture (Risk Intelligence Dashboards)

| Component | Specification |
|---|---|
| **Widget rendering** | Embedded iframe or JS SDK from SitDeck, rendered inside Secure dashboard panels. Property lat/lng passed as map centre point. Confirm embed method with SitDeck before build |
| **Auth** | SitDeck account token stored in Supabase secrets. One token per Secure account. All DC properties under the account share the SitDeck connection |
| **Alert-to-finding pipeline** | SitDeck custom alerts POST by webhook to a Secure Edge Function. Function writes `agent_finding` + `audit_event`. Core plan supports widgets; webhook alerts require a paid SitDeck tier — confirm pricing before committing to clients |
| **Location prerequisite** | Property lat/lng coordinates required in the `properties` table. Add lat/lng fields to property creation form if not already present |

---

## Dashboard Implementation Phases

| Phase | Scope | Timeline |
|---|---|---|
| **Phase 2** | Portfolio overview, single property overview, PUE, Capacity, Cooling, ESG dashboards (wired to `data_library_records` and `dc_metadata`) | Week 2–4 |
| **Phase 3** | SitDeck connection UI, live PUE tile, rack and sensor data wired | Week 3–5 |

---

*Secure SoR — Data Centre Asset Type — v1.0 — March 2026*

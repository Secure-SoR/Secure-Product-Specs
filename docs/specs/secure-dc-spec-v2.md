# SECURE SoR — Data Centre Asset Type  
## Product Specification for Cursor

| | |
|---|---|
| **Status** | DRAFT v1.0 |
| **Date** | March 2026 |
| **Owner** | Anne |
| **Repo** | Secure-SoR-backend |

This spec follows [SPEC-TEMPLATE.md](SPEC-TEMPLATE.md) (10 required sections). Mapping: §1 Feature Overview = §0–1 below; §2 Functional Requirements = §2–5 and screens; §3 API/Data Surface = §2.2 schema, §4 SitDeck; §4 Database Schema = §2.2, §4 tables; §5 Business Logic = §2–5 rules; §6 Auth = RLS/account; §7 State & Workflow = §3 space flow; §8 Error Handling = see §8 below; §9 External = SitDeck; §10 Non-Functional = see §10 below.

---

## 0. Executive Summary

This specification defines the changes and additions required to extend Secure SoR to support **Data Centres** as a first-class asset type. It covers three distinct areas:

- **Asset type template:** property and space creation adapted for data centre topology (halls, suites, white floor, plant rooms, PODs)
- **Dashboards:** a new Data Centre Asset Manager dashboard set covering PUE, energy intensity, capacity, cooling, water, and ESG metrics
- **SitDeck integration:** connecting Secure SoR to the SitDeck DCIM platform (https://app.sitdeck.com) for operational telemetry, rack/device data, and real-time metering; plus SitDeck OSINT for risk intelligence

This spec is structured for direct handoff to Cursor. Each section includes: what to build, how it differs from the existing office/retail model, exact schema changes, UI components, and integration contracts.

---

## 1. Context & Strategic Fit

### 1.1 Why Data Centres

Data centres are one of the most complex real estate asset types for sustainability and operational data management. They are:

- **Energy-intensive:** a single hyperscale facility can consume 50–200 MW
- **Metering-rich:** extensive submeter networks already exist but data is fragmented across DCIM, BMS, and FM systems
- **Regulation-exposed:** EU Energy Efficiency Directive, SEC climate disclosure, and emerging DC-specific reporting requirements
- **Capital-markets relevant:** DC valuations are increasingly tied to PUE, RECs, and transition risk

Secure's System of Record architecture — asset-level data model, evidence chains, audit trail, AI agents — maps directly onto the data governance needs of DC asset managers and owners.

### 1.2 Who Uses This

| Role | Description |
|------|-------------|
| **Primary user** | Asset Manager / Owner of one or more data centres |
| **Secondary user** | Sustainability / ESG team producing GRESB, SFDR, or SEC reports |
| **Third user** | Operations team monitoring PUE, capacity, and critical plant |
| **Account type** | asset_manager (existing) — no new account type needed |
| **Asset type (new)** | data_centre — added to asset_type enum in properties table |

### 1.3 Relationship to Existing Architecture

The canonical Secure SoR layers remain unchanged. Data Centre is an **additive** asset type template that:

- **Reuses:** properties, spaces, systems, meters, data_library_records, evidence_attachments, agent_runs, audit_events
- **Extends:** asset_type enum, building_systems_taxonomy, space templates, dashboard module, agent context
- **Adds:** dc_metadata table, dc_rack_assets table (SitDeck sync), dc_sensor_readings, dc_sync_log, sitdeck_risk_config, new dashboard pages

---

## 1. Feature Overview (SPEC-TEMPLATE §1)

**Purpose:** Extend Secure SoR to support Data Centres as a first-class asset type: property/space template, DC dashboards (operational + SitDeck risk intelligence), and optional SitDeck DCIM integration. **Who uses it:** Asset managers, sustainability/ESG teams, operations (see §1.2). **Business problem:** DCs need PUE, capacity, cooling, water, and risk metrics with the same SoR, evidence, and audit model as other assets.

**SPEC-TEMPLATE §2–10 (summary):**  
- **§2 Functional Requirements:** See §2 (Property Creation), §3 (Spaces), §5 (Dashboards), §6 (SitDeck) for step-by-step flows and user actions.  
- **§3 API / Data Surface:** Supabase tables (properties, spaces, dc_metadata, data_library_records); SitDeck API (see §4); no REST API in backend repo.  
- **§4 Database Schema:** See §2.2 (dc_metadata), §4 (dc_rack_assets, dc_sensor_readings, dc_sync_log, sitdeck_risk_config); [docs/database/schema.md](../database/schema.md).  
- **§5 Business Logic & Validation:** asset_type = 'data_centre' triggers DC metadata step; space types per §3; tenancy_type whole/partial; PUE/WUE calculations; SitDeck sync rules.  
- **§6 Authentication & Authorization:** RLS on all tables by account_id; no extra roles; DC routes visible when account has ≥1 DC property.  
- **§7 State & Workflow:** Property create → optional DC details step; space create with DC template; SitDeck sync (schedule or on-demand); dashboard read-only.  
- **§8 Error Handling:** Validation on DC metadata form; SitDeck API failures → log and show sync status; no specific error codes in spec.  
- **§9 External Integrations:** SitDeck DCIM (telemetry, rack/device, sync); SitDeck OSINT (risk intelligence).  
- **§10 Non-Functional:** Dashboard queries scoped by property/account; index dc_metadata(property_id); SitDeck sync rate per API limits; logging for sync and audit.

---

## 2. Property Creation — Data Centre Template

### 2.1 What Changes at Property Level

Property creation today uses a generic form (name, address, asset_type, NLA, year_built etc.). When **asset_type = 'data_centre'**, a second step must appear: the **Data Centre Metadata** form.

Everything in the core `properties` table stays the same. The DC-specific fields live in a new table: **dc_metadata** (one row per property).

### 2.2 Schema: dc_metadata

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| id | uuid PK | NO | Auto-generated |
| account_id | uuid FK → accounts | NO | RLS scope |
| property_id | uuid FK → properties UNIQUE | NO | One row per property |
| tier_level | text (I\|II\|III\|IV) | YES | Uptime Institute Tier |
| design_capacity_mw | numeric | YES | Total IT load capacity (MW) |
| current_it_load_mw | numeric | YES | Live or last-known IT load (MW) |
| total_white_floor_sqm | numeric | YES | Total raised floor / white floor area |
| cooling_type | text[] | YES | air_cooled \| liquid_cooled \| hybrid \| free_cooling |
| power_supply_redundancy | text (N\|N+1\|2N\|2N+1) | YES | UPS/power redundancy class |
| target_pue | numeric | YES | Design or target PUE (e.g. 1.3) |
| renewable_energy_pct | numeric | YES | % of power from renewables (0–100) |
| water_usage_effectiveness_target | numeric | YES | Target WUE (L/kWh) |
| certifications | text[] | YES | ISO 50001 \| ISO 14001 \| LEED \| BREEAM \| EU CoC |
| sitdeck_site_id | text | YES | SitDeck site identifier for API sync |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

**RLS:** account-scoped (same pattern as all other tables). Migration file: `add-dc-metadata.sql`.

### 2.3 UI: Property Creation Flow for Data Centres

- **Step 1 (unchanged):** Core property form — name, address, asset_type = 'data_centre', country, year_built, operational_status.
- **Step 2 (NEW — conditional on asset_type = data_centre):** Data Centre Details form.

| Field | UI control |
|-------|------------|
| Tier Level | Select: Tier I / II / III / IV |
| Design Capacity (MW) | Number input |
| Total White Floor (sqm) | Number input |
| Cooling Type | Multi-select: Air \| Liquid \| Hybrid \| Free Cooling |
| Power Redundancy | Select: N / N+1 / 2N / 2N+1 |
| Target PUE | Number input (e.g. 1.3) |
| Renewable Energy % | Slider 0–100% |
| WUE Target | Number input (L/kWh) |
| Certifications | Multi-select checkbox: ISO 50001, ISO 14001, LEED, BREEAM, EU CoC |
| SitDeck Site ID | Text input (optional — used for integration) |

**Save action:** INSERT into `dc_metadata` linked to the new `property_id`. This step is **skippable** (all fields nullable) — user can complete later from the property settings page.

---

## 3. Space Creation — Data Centre Template

### 3.1 Data Centre Space Topology

Data centres have a fundamentally different space hierarchy to offices. Canonical topology:

| Level | space_class | Space type examples | control |
|-------|-------------|---------------------|---------|
| Facility / Site | base_building | Site boundary, external plant yard | landlord_controlled |
| Building shell | base_building | Building envelope, loading bay, security | landlord_controlled |
| White Floor / Hall | tenant | Hall A, Hall B, Data Hall 1 | tenant_controlled |
| Data Suite / Zone | tenant | Suite 1A, Zone North, Cage area | tenant_controlled |
| POD / Row | tenant | POD-01, Row 12, Hot aisle 3 | tenant_controlled |
| Mechanical plant | base_building | CW plant room, generator room, UPS room | landlord_controlled |
| Electrical plant | base_building | HV room, LV switchroom, transformer room | landlord_controlled |
| Office / NOC | base_building | Network Operations Centre, security office | landlord_controlled |
| Cooling zone | base_building | Cooling tower yard, CRAC/CRAH room | landlord_controlled |

**Hierarchy:** Building → Hall/Data Floor → Suite → POD/Row. Mechanical and electrical plant rooms are always base_building, landlord_controlled.

### 3.2 Space Template: Data Centre

When creating spaces for a **data_centre** property, offer a **'Use Data Centre Template'** button that pre-populates the standard space tree. Implement as a seed function triggered from the spaces onboarding step.

**Default template spaces (user edits names/areas):**

- Hall A — space_class: tenant, control: tenant_controlled, space_type: data_hall
- Suite 1, Suite 2 — space_class: tenant, control: tenant_controlled, space_type: data_suite
- Hall B — space_class: tenant, control: tenant_controlled, space_type: data_hall
- Mechanical Plant Room — space_class: base_building, control: landlord_controlled, space_type: plant_room
- Electrical Plant Room — space_class: base_building, control: landlord_controlled, space_type: plant_room
- Cooling Plant — space_class: base_building, control: landlord_controlled, space_type: cooling_plant
- Network Operations Centre — space_class: base_building, control: landlord_controlled, space_type: office

### 3.3 New space_type Values for Data Centres

Add to space_type enum / documentation (no DB constraint change if space_type is free text):

| space_type value | Description |
|------------------|-------------|
| data_hall | Primary raised-floor data hall / white floor |
| data_suite | Sub-division of a hall (caged or open) |
| data_pod | Pre-fabricated or modular POD |
| data_row | Row within a hall or suite |
| plant_room | Mechanical or electrical plant room |
| cooling_plant | Cooling tower yard, CRAC/CRAH room |
| ups_room | UPS / battery room |
| generator_room | Diesel or gas generator room |
| hv_room | High voltage switchroom |
| lv_room | Low voltage switchroom |
| loading_bay | Loading / receiving area |
| security_gatehouse | Security post |
| noc | Network Operations Centre |
| meet_me_room | Cross-connect / colocation meet-me room |

### 3.4 In-Scope Area for Data Centres

For data centres, `in_scope_area` on the property represents total IT-usable white floor area (sqm). The spaces subpage should display this as **'White Floor in Scope'** rather than generic 'Floors in Scope'. No schema change — UI label adjustment conditional on asset_type = data_centre.

---

## 4. Building Systems — Data Centre Taxonomy Extension

### 4.1 New System Types (existing categories)

**Power:** HV_Intake, UPS_System, PDU_Unit, Generator_Set, StaticTransfer_Switch, BusBars, REC_Meter  

**HVAC / Cooling:** CRAC_Unit, CRAH_Unit, Chiller_Plant, CoolingTower, AdiabatiCooler, LiquidCooling_Rack, ImmersionCooling, HotAisleColdAisle, FreeAirCooling, CRAC_EC_Fan  

**Monitoring:** DCIM_Platform, PUE_Meter, TemperatureHumidity_Sensor, Power_Chain_Monitor, WaterMeter_DC, RackPowerMeter  

**Water:** MakeupWater_Meter, TotalWater_Meter  

### 4.2 Key Metrics from Systems

| Metric | Derived from / systems |
|--------|------------------------|
| PUE | Total facility power ÷ IT load power (UPS_System + PDU_Unit readings) |
| WUE | Annual water use (L) ÷ IT energy (kWh) — from WaterMeter_DC |
| IT Load (MW) | Sum of PDU / rack meter readings |
| Cooling Energy (MWh) | CRAC/CRAH + Chiller + Cooling Tower energy readings |
| Power Chain Loss | HV_Intake → UPS → PDU → rack delta |
| Capacity Utilisation % | Current IT load ÷ Design capacity × 100 |
| Renewable % | From REC_Meter or manual entry |
| Carbon intensity | Grid factor × total energy (Emissions Engine) |

---

## 5. Data Centre Dashboards

### 5.1 Dashboard Architecture

Data centre dashboards are a new module alongside existing Energy, Carbon, Risk, Governance. Available only when account has at least one property with asset_type = 'data_centre'.

**Routes:**

- `/dashboards/data-centre` — Portfolio overview (all DC properties)
- `/dashboards/data-centre/:propertyId` — Single DC property view
- `/dashboards/data-centre/:propertyId/pue` — PUE deep-dive
- `/dashboards/data-centre/:propertyId/capacity` — Capacity and power chain
- `/dashboards/data-centre/:propertyId/cooling` — Cooling and water
- `/dashboards/data-centre/:propertyId/esg` — ESG and reporting readiness

### 5.2–5.7 Dashboard Details

- **Portfolio overview:** PUE (avg + range), Total IT Load, Total Energy YTD, Renewable %, Carbon intensity, Properties at PUE risk, Capacity utilisation, Data coverage score; PUE trend by property; property table.
- **Single DC overview:** Six KPI tiles — Live PUE, IT Load, Total Energy, Cooling Energy, Water (WUE), Renewable %.
- **PUE deep-dive:** Time series PUE vs target; PUE component waterfall; temperature correlation; annualised PUE; benchmark vs Tier norms.
- **Capacity & Power Chain:** Capacity gauge, power chain diagram, hall-level breakdown, redundancy view, capacity depletion forecast.
- **Cooling & Water:** Cooling energy breakdown, WUE trend, cooling efficiency, free cooling hours, water consumption, make-up water.
- **ESG & Reporting Readiness:** GRESB DC module readiness, EED Article 12 fields, renewable breakdown, Scope 2 (market/location), data quality from CoverageEngine.

---

## 6. SitDeck OSINT Integration

SitDeck (https://sitdeck.com) is an OSINT dashboard platform — 180+ live data providers (conflicts, geopolitical, natural hazards, cyber, climate, etc.). For Secure it serves the **Owner/Landlord** profile: asset owners who need physical, geopolitical, and climate threat intelligence in real time.

**Three new dashboards under "Risk Intelligence" tab:**

- `/dashboards/data-centre/:propertyId/geopolitical` — Geopolitical & Conflict Risk
- `/dashboards/data-centre/:propertyId/climate-hazard` — Climate & Natural Hazard Risk
- `/dashboards/data-centre/:propertyId/cyber-infrastructure` — Cyber & Critical Infrastructure Risk

**Integration:** Users connect SitDeck from **Data Library → Connectors** (not Account Settings → Integrations): Connect / Disconnect / optional Refresh; token in Supabase Vault or secrets via Edge Function; per-property widget enablement in `sitdeck_risk_config`. Embed SitDeck widgets (iframe or JS SDK) in Secure dashboard panels; property lat/lng as map centre. Alert-to-finding pipeline: SitDeck custom alerts webhook POST to Secure Edge Function → writes agent_finding + audit_event. Property lat/lng required (add to properties if not present).

---

## 7. AI Agents — Data Centre Extensions

- **Data Readiness Agent:** Add PUE, WUE, capacity, cooling as KPIs; check for SitDeck connection; flag if no PUE data.
- **Boundary Agent:** DC boundary rules — IT load always tenant; facility power includes shared services (cooling, lighting, security).
- **New agent: PUE & Efficiency Advisor** — Trigger from DC dashboard or when PUE > target + threshold. Input: dc_metadata, recent dc_sensor_readings, data_library_records (energy), tier_level, cooling_type. Outputs: executive summary, inefficiencies, recommendations, evidence gaps, next actions. Confidence from data source (SitDeck = High, manual = Moderate, estimated = Low).
- **Agent context extension:** dcMetadata, recentSensorReadings (7-day rollup from dc_sensor_readings), rackSummary (from dc_rack_assets), syncStatus (from dc_sync_log).

---

## 8. Implementation Plan for Cursor

*(Phases updated post-clarification: SitDeck OSINT only, no DCIM sync.)*

**Phase 1 (Week 1–2):** asset_type = data_centre; migration **dc_metadata** only; optional migration **properties** lat/lng (for later SitDeck widgets); property creation DC Details step (Step 2 when asset_type = data_centre); space DC template (Use Data Centre Template); building systems taxonomy doc update.

**Phase 2 (Week 2–4):** DC dashboard routes and pages; wire to data_library_records and dc_metadata (no SitDeck yet).

**Phase 3 (Week 3–5):** SitDeck OSINT only: connection UI (one SitDeck connector in **Data Library → Connectors**); sitdeck_risk_config migration; embed widgets (geopolitical/climate/cyber + physical risk map); property lat/lng editable on Integrations & Evidence; optional webhook → agent_findings; live PUE tile from data_library_records.

**Phase 4 (Week 5–6):** Risk Diagnosis + physical_risk_flags (schema and UI); extend Data Readiness and Boundary context; PUE & Efficiency Advisor agent; wire agent from DC dashboard.

**Acceptance criteria:** Property creation triggers DC form and dc_metadata; DC template populates spaces; portfolio dashboard shows PUE/IT load/energy/renewable %; PUE dashboard with time series and waterfall; SitDeck OSINT connection and widgets; PUE agent returns structured output.

---

### 8.1 Step-by-step guide by phase

Use this order within each phase. Backend (migrations, schema) first, then UI.

**Implementation guides (how to do each step):** Each phase has a separate guide that explains in plain language what each step means and how to do it (for engineers or for writing Cursor/Lovable prompts).

| Phase | Guide |
|-------|--------|
| **Phase 1** | [implementation-guide-phase-1-dc.md](./implementation-guide-phase-1-dc.md) — Schema & DC template |
| **Phase 2** | [implementation-guide-phase-2-dc.md](./implementation-guide-phase-2-dc.md) — DC dashboards |
| **Phase 3** | [implementation-guide-phase-3-dc.md](./implementation-guide-phase-3-dc.md) — SitDeck OSINT |
| **Phase 4** | [implementation-guide-phase-4-dc.md](./implementation-guide-phase-4-dc.md) — Risk Diagnosis & PUE agent |

---

#### Phase 1 (Week 1–2) — Schema & DC template

| Step | Task | Spec ref | Notes |
|------|------|----------|--------|
| 1.1 | Add `data_centre` to allowed asset_type for properties (enum or validation). | §1.2, §2.1 | Ensure property creation can set asset_type = 'data_centre'. |
| 1.2 | Create migration `add-dc-metadata.sql`: table dc_metadata with columns per §2.2; RLS policies (account-scoped); index on property_id. | §2.2 | One row per property; property_id UNIQUE. |
| 1.3 | Create migration to add `latitude` and `longitude` (numeric, nullable) to `properties`. | Clarification summary | For SitDeck widgets and risk; optional in Phase 1. |
| 1.4 | Run migrations in Supabase; update backend schema doc (e.g. schema.md) with dc_metadata and properties lat/lng. | — | Keep schema as source of truth in backend repo. |
| 1.5 | Property creation UI: when user selects asset_type = 'data_centre', show Step 2 "Data Centre Details". | §2.3 | Form fields: Tier Level, Design Capacity, White Floor, Cooling Type, Power Redundancy, Target PUE, Renewable %, WUE Target, Certifications, SitDeck Site ID (optional). All nullable; step skippable. |
| 1.6 | On save of Step 2: INSERT into dc_metadata with account_id, property_id and form values. | §2.2 | Link to the property just created in Step 1. |
| 1.7 | Spaces UI: for data_centre property, show "Use Data Centre Template" button. | §3.2 | Triggers seed that creates default space tree. |
| 1.8 | Implement DC template seed: Hall A, Hall B, Suite 1, Suite 2, Mechanical Plant Room, Electrical Plant Room, Cooling Plant, NOC — with space_class, control, space_type per §3.2. | §3.2, §3.1 | User can edit names/areas after. |
| 1.9 | Document new space_type values for DC (data_hall, data_suite, data_pod, plant_room, cooling_plant, etc.) in code or taxonomy doc. | §3.3 | No DB constraint change if space_type is free text. |
| 1.10 | Update building systems taxonomy doc with new system types: Power, HVAC/Cooling, Monitoring, Water per §4.1. | §4.1 | For reference and dropdowns in systems UI. |

**Phase 1 done when:** User can create a data_centre property, complete DC Details (or skip), apply DC space template, and see new space types/taxonomy reflected.

---

#### Phase 2 (Week 2–4) — DC dashboards (no SitDeck yet)

| Step | Task | Spec ref | Notes |
|------|------|----------|--------|
| 2.1 | Add DC dashboard routes under existing Dashboards nav (e.g. /dashboard/data-centre or per-property DC view). | §5, §8 | Decide route structure: portfolio-level vs property-level. |
| 2.2 | Portfolio DC view: list data_centre properties; show KPIs from dc_metadata + data_library_records (PUE, IT load, energy, renewable %). | §5.1 | Read from dc_metadata and data_library_records; no SitDeck. |
| 2.3 | Property-level DC dashboard: PUE card, IT load, capacity utilisation; link to data_library_records for evidence. | §5.2 | Use dc_metadata (target_pue, design_capacity_mw, etc.) and data_library_records for actuals. |
| 2.4 | PUE dashboard: time series (from data_library_records) and PUE waterfall (total power vs IT load breakdown). | §5.2 | Data source: data_library_records; structure per §5 and §7. |
| 2.5 | Data Readiness / Boundary context: ensure DC properties and dc_metadata are included in context for agents and reporting. | §7 | So Phase 4 agent has full DC context. |

**Phase 2 done when:** User can open DC dashboards, see PUE/IT load/energy/renewable % from dc_metadata and data_library_records, and see time series/waterfall where data exists.

---

#### Phase 3 (Week 3–5) — SitDeck OSINT integration

| Step | Task | Spec ref | Notes |
|------|------|----------|--------|
| 3.1 | Create migration `add-sitdeck-risk-config.sql`: table sitdeck_risk_config (account_id, property_id UNIQUE, active_widget_types text[], last_synced_at); RLS. | §10 | Token in Supabase secrets; no DCIM tables. |
| 3.2 | Data Library → Connectors: one "SitDeck" connector — connect (store token in secrets), disconnect, optional refresh to update active_widget_types. | §6, §10 | Single integration for OSINT (widgets + risk). |
| 3.3 | Integrations & Evidence (or property settings): surface property latitude/longitude; allow edit so widgets can use coordinates. | Clarification Q3 | Backed by properties.lat/lng added in Phase 1. |
| 3.4 | Property view (data_centre): embed SitDeck OSINT widgets — geopolitical, climate, cyber dashboards; anchor to property lat/lng. | §6 | iframe or JS SDK per SitDeck docs; show relation to asset location. |
| 3.5 | Property view / Risk: embed physical risk map widget (flood, wildfire, etc.); feed into Risk Diagnosis when that exists (Phase 4). | §10 | sitdeck_risk_config drives which widgets are active. |
| 3.6 | Optional: webhook receiver for SitDeck alerts → write to agent_findings (finding_type, source 'sitdeck'); extend agent_findings schema if needed (e.g. source, nullable agent_run_id). | §6, Clarification Q5 | For audit trail of threshold alerts. |
| 3.7 | Live PUE tile on main property page: source PUE from data_library_records (not SitDeck DCIM). | §8 | Display only; data from manual/file input. |

**Phase 3 done when:** User can connect SitDeck in **Data Library → Connectors**; DC property view shows OSINT and physical risk widgets; lat/lng editable; optional webhook → agent_findings.

---

#### Phase 4 (Week 5–6) — Risk Diagnosis, context, PUE agent

| Step | Task | Spec ref | Notes |
|------|------|----------|--------|
| 4.1 | Define and add Risk Diagnosis schema (e.g. risk_diagnosis or equivalent table) and physical_risk_flags (e.g. flags with source = 'sitdeck'). | §6, §10, Clarification Q4 | Backend migration; RLS. |
| 4.2 | Risk Diagnosis UI: show risk record for property; consume physical_risk_flags from SitDeck (Phase 3 widgets / config). | §6, §10 | So SitDeck risk feeds into a dedicated risk view. |
| 4.3 | Extend Data Readiness and Boundary context: include DC-specific fields (dc_metadata, space template, systems) for agent and reporting. | §7 | Full DC context in agent payload. |
| 4.4 | PUE & Efficiency Advisor agent: define input (property, dc_metadata, data_library_records, spaces, systems) and structured output (e.g. PUE insight, recommendations). | §7 | Agent logic in AI agents repo; schema/DB in backend. |
| 4.5 | Wire agent from DC dashboard: "Run PUE Advisor" (or similar); call agent with context; display result; optionally persist to agent_runs and agent_findings. | §7, §8 | Same pattern as existing agent integration. |

**Phase 4 done when:** Risk Diagnosis exists with physical_risk_flags; PUE agent runs from DC dashboard with full DC context and returns structured output; context includes Data Readiness and Boundary.

---

## 9. Open Questions & Dependencies

**SitDeck API:** Auth method (API key / OAuth / Basic)? Endpoints for power, PUE, environmental? Webhook vs polling? Rate limits? Rack-level vs site-level data?

**Design decisions (spec recommends):** Live PUE on main property page = Yes (KPI tile); dc_sensor_readings prune after 90 days = Yes (scheduled job); DC dashboards under existing Dashboards nav; PUE agent on-demand for MVP.

---

## 10. SitDeck Physical Risk & Location Intelligence

**Separate from Section 6:** This is SitDeck as **physical risk intelligence** (widget-based map) — flood, wildfire, extreme weather, geopolitical, etc. around the asset. Rendered in Secure property view and Risk Diagnosis; feeds Risk Diagnosis as physical_risk_flags with source = 'sitdeck'.

**Schema: sitdeck_risk_config** — account_id, property_id (UNIQUE), active_widget_types (text[]), last_synced_at. Token stored in Supabase secrets. Connection UI in **Data Library → Connectors** (SitDeck connector row; not Account Settings → Integrations). Refresh updates active_widget_types from SitDeck and writes to risk record. Migration: add-sitdeck-risk-config.sql.

**Implementation notes:** Confirm SitDeck embed method (iframe vs JS SDK); property lat/lng required; **one** SitDeck OSINT connector in **Data Library → Connectors** (not two cards, not Account Settings as primary).

---

*End of Specification — Secure SoR Data Centre Asset Type v1.0 — March 2026*

---

## Clarification questions (before implementation)

1. **SitDeck products and APIs**  
   The spec refers to (a) SitDeck DCIM for operational telemetry/rack data (Section 8.3, sync to dc_rack_assets, dc_sensor_readings), and (b) SitDeck OSINT / physical risk (Sections 6 and 10 — widgets, risk feeds, sitdeck_risk_config). Are these two separate SitDeck products with separate APIs and credentials, or one platform with two integration modes? Do we have (or can we get) SitDeck API/embed documentation so we can confirm auth, endpoints, and webhook support before Phase 3? 
   Answer: The SitDeck DCIM is an error. Only the SitDeck OSINT is relevant for our platform.

2. **Schema for dc_rack_assets, dc_sensor_readings, dc_sync_log**  
   The spec names these tables and their role (SitDeck sync, rollup, audit) but does not define column-level schema. Should we derive schema from the described behaviour (e.g. dc_sensor_readings: property_id, reading_at, pue, it_load_mw, total_power_mw, temp_c?, source?), or will you provide a separate schema doc? Same for dc_rack_assets (e.g. sitdeck_rack_id, property_id, hall/suite, design_kw, current_kw, utilisation_pct?) and dc_sync_log (property_id, sync_at, status, rows_synced?).
   Answer: SitDeck sync for this is not relevant as we are only using SitDeck OSINT. Do you still need to redefine the schema if we remove the SitDeck sync?

3. **properties.lat / properties.lng**  
   SitDeck widgets and risk config need property coordinates. Do we already have lat/lng (or equivalent) on the properties table? If not, should we add them in Phase 1 for all properties or only for data_centre (and optional)? 
   Answer: you can check our current db. Mostly likely not. Could be added in the page Integrations & Evidence

4. **Risk Diagnosis and physical_risk_flags**  
   Sections 6 and 10 write to “Risk Diagnosis” and “physical_risk_flags”. Does the current Secure schema already have a risk diagnosis table or physical_risk_flags structure, or should we define and add it as part of this DC work?
   Answer: It is part of this work

5. **agent_findings for SitDeck alerts**  
   The spec says geopolitical/climate/cyber alerts write to agent_findings (finding_type, source = 'sitdeck'). Does the existing agent_findings table (or equivalent) support this shape and source, or do we need new columns or a separate table for “external” findings?
   Answer: you can recommend this, I don't think we have anything about the agent on this. You can check in the ai agents folder attached in this workspace. However scheme and database needs to remain in backend folder design. 

6. **Phasing and MVP scope**  
   Should we implement all four phases in order (schema → dashboards → SitDeck sync → agents), or is there a preferred MVP that delivers value without SitDeck first (e.g. Phase 1 + Phase 2 with manual/data-library PUE input only)?
   Answer: We should develop all four in the order you wrote above

7. **Lovable vs Cursor**  
   The spec says “for Cursor”. Should all UI (property DC form, space template, DC dashboards, integration settings) be implemented in the Lovable app from Cursor-written prompts, or is any part of the DC flow intended to be built outside Lovable (e.g. separate admin or API-only)?
   Answer: yes, everything through Cursor. 

8. **Section 6 vs Section 10 — two SitDeck integrations**  
   Section 6 describes OSINT dashboards (geopolitical, climate, cyber) with embedded widgets and webhook → agent_finding. Section 10 describes physical risk map widget and sitdeck_risk_config feeding Risk Diagnosis. Are these the same SitDeck product with two UIs (dashboard widgets vs map widget), or two different products/contracts? This affects how we name and document the SitDeck connector in **Data Library → Connectors** (single OSINT integration).
   Answer: These widgets come from integration with SitDeck, an intelligence dashboard. We need to integrate with them and, using the location of our data centre property type, show how they relate to our asset: https://sitdeck.com/?utm_source=superhuman&utm_medium=newsletter&utm_campaign=sitdeck-build-cia-level-dashboards-to-monitor-events&_bhlid=d98f6d80814bfca1b514d5180178eed4ad410dab

---

### Clarification summary (post-answers)

- **All 8 questions are answered.** No further clarification is required to proceed.
- **SitDeck scope:** Only SitDeck OSINT (intelligence dashboard / risk widgets) is in scope. SitDeck DCIM and any sync of rack/sensor telemetry are **out of scope**. There is **one** SitDeck integration in **Data Library → Connectors** (OSINT), not two.
- **Schema implications:**  
  - **Drop from spec:** dc_rack_assets, dc_sensor_readings, dc_sync_log as SitDeck-sync tables.  
  - **Keep:** dc_metadata; data_library_records for PUE/energy (manual or file-based); Risk Diagnosis and physical_risk_flags to be defined and added as part of this work.  
  - **properties:** Add latitude/longitude (or lat/lng); surface and edit on Integrations & Evidence page. Current DB has no lat/lng on `properties`.  
  - **agent_findings:** Existing table has `agent_run_id` (required), `finding_type`, `payload`. For SitDeck webhook alerts, recommend adding optional `source` (e.g. `'sitdeck'`) and allowing `agent_run_id` to be nullable for “external” findings, or document creating a system agent_run per property/account for SitDeck and storing events as findings with `finding_type` + payload. Schema change to stay in backend.
- **Phasing:** Implement all four phases in order; Phase 3 is reframed as **SitDeck OSINT only** (connection UI, widgets, sitdeck_risk_config, optional webhook → agent_findings), not DCIM sync.
- **UI:** All implementation via Cursor (Lovable app). Risk Diagnosis and physical_risk_flags are part of this DC work.

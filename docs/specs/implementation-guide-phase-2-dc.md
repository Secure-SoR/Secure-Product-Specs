# How to implement Phase 2 — DC dashboards (no SitDeck yet)

This guide explains **what each step means** and **how to do it** in plain language. Use it when briefing an engineer or when using Cursor to generate prompts for Lovable.

**Link from main spec:** [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) → Section 8.1 Phase 2

---

## Step 2.1 — Add DC dashboard routes

**What it means:** Users need a way to open data centre–specific dashboards. That means new routes (URLs), e.g. a portfolio-level "Data centres" view and/or a property-level "DC dashboard" for each data centre property. These should sit under your existing "Dashboards" or "Analytics" navigation.

**How to do it:**

- **Where:** Lovable app — routing and navigation.
- **Decide:** One route for "all my data centres" (portfolio) and one for "this property’s DC dashboard" (e.g. `/properties/:id/dashboard` or `/properties/:id/data-centre`). Only show these routes (or nav items) when the account has at least one property with `asset_type === 'data_centre'`.
- **If you use Cursor:**  
  *"Add dashboard routes for data centres: a portfolio view of all data centre properties and a property-level DC dashboard. Show them in the Dashboards nav only when the account has at least one data centre property."*

**Done when:** User can navigate to DC dashboard(s) from the app; routes only appear when relevant.

---

## Step 2.2 — Portfolio DC view: list data centres and show KPIs

**What it means:** The portfolio DC view lists all properties that are data centres and shows high-level numbers for each: e.g. PUE, IT load, energy, renewable %. Data comes from `dc_metadata` and `data_library_records` (no SitDeck in this phase).

**How to do it:**

- **Where:** Lovable app — the portfolio DC dashboard page.
- **Data:** For each data centre property, read `dc_metadata` (target_pue, design_capacity_mw, current_it_load_mw, renewable_energy_pct, etc.) and, where available, `data_library_records` for actual PUE/energy so you can show "current" vs "target" if you have data.
- **If you use Cursor:**  
  *"On the portfolio Data Centre dashboard, list all properties with asset_type data_centre. For each, show KPIs from dc_metadata and data_library_records: PUE, IT load, energy, renewable %."*

**Done when:** The portfolio DC page shows the list and KPIs from the database.

---

## Step 2.3 — Property-level DC dashboard: PUE, IT load, capacity

**What it means:** When viewing a single data centre property, there should be a dedicated DC dashboard (or tab) with a PUE card, IT load, capacity utilisation, and links to the evidence (data library records) that back the numbers.

**How to do it:**

- **Where:** Lovable app — property detail / dashboard for a data centre property.
- **Data:** Read `dc_metadata` for that property (target_pue, design_capacity_mw, current_it_load_mw, etc.) and `data_library_records` linked to that property for actuals. Show capacity utilisation as current vs design if both exist. Link figures to the relevant data library records so users can see the source.
- **If you use Cursor:**  
  *"On the property view for a data centre, add a DC dashboard section with PUE, IT load, and capacity utilisation from dc_metadata and data_library_records. Link values to the supporting data library records."*

**Done when:** Opening a data centre property shows the DC dashboard with PUE/IT load/capacity and evidence links.

---

## Step 2.4 — PUE time series and waterfall

**What it means:** Where the user has time-series data in `data_library_records` (e.g. monthly PUE or power readings), show a chart (time series) and, if possible, a PUE waterfall (total power vs IT load breakdown). Data source is only `data_library_records` in this phase.

**How to do it:**

- **Where:** Lovable app — same property-level DC dashboard (or a "PUE" sub-view).
- **Data:** Query `data_library_records` for the property filtered by the right record types/names (e.g. PUE, power, IT load). Plot over time. Waterfall: e.g. total power → IT load → difference (cooling/overhead).
- **If you use Cursor:**  
  *"Add a PUE time series chart and a PUE waterfall (total power vs IT load) to the DC property dashboard. Data from data_library_records only."*

**Done when:** When data exists, the dashboard shows the PUE chart and waterfall.

---

## Step 2.5 — Include DC in Data Readiness / Boundary context

**What it means:** Later (Phase 4) an agent will use "context" about the property (data readiness, boundary, etc.). We need to ensure that for data centre properties, this context includes DC-specific data: dc_metadata, DC spaces, DC systems — so the agent has the full picture.

**How to do it:**

- **Where:** Backend or app — wherever you build the "context" payload for agents or reporting. Extend that logic so that when the property is a data centre, you also include: dc_metadata row(s), space list (with space_type for DC), and systems. Document that DC properties get this extended context.
- **If you use Cursor:**  
  *"Extend the Data Readiness / Boundary context (used for agents and reporting) to include dc_metadata, spaces, and systems when the property is a data centre."*

**Done when:** Context for a data centre property includes DC metadata, spaces, and systems.

---

## Phase 2 complete

You’re done with Phase 2 when:

- DC dashboard routes exist and are visible when the account has data centre properties.
- Portfolio DC view lists data centres and shows KPIs from dc_metadata and data_library_records.
- Property-level DC dashboard shows PUE, IT load, capacity, time series, and waterfall from data_library_records.
- DC data is included in the context used for agents/reporting.

Next: [Phase 3 — SitDeck OSINT](./implementation-guide-phase-3-dc.md).

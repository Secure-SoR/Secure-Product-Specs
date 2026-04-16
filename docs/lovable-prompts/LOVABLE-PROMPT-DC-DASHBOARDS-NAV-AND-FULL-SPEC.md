# Lovable prompt: Data Centre dashboards — navigation + full spec

**Use this when:** (1) After choosing Data Centre in the dashboards filter, clicking a property gives no way to go back to the Data Centre dashboards landing. (2) The DC dashboards built do not match the full set in [specs/secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md) §5.

**Backend spec:** [specs/secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md) §5 (DC dashboards), §6 (SitDeck Risk Intelligence dashboards — [SitDeck](https://sitdeck.com) OSINT).

---

## Problem 1 — Navigation

When the user selects **Data Centre** in the filter, they see the Data Centre dashboards **landing page** (portfolio or list of DC properties/dashboards). When they **click one** (e.g. a property or a dashboard card), they go to a single-property or detail view but **cannot get back** to that landing page.

**Required:** On every Data Centre dashboard page **except** the landing page, show a clear way to return to the Data Centre dashboards landing:

- **Breadcrumb:** e.g. "Data Centre dashboards" (link to landing) → "Property name" → "PUE" (or current page). The first segment must link to `/dashboards/data-centre` (or your exact landing route).
- **Or** a visible **"Back to Data Centre dashboards"** link/button that navigates to the landing route.

Landing route = the page that lists all DC properties / portfolio overview (see full route list below). From any child route, the user must be able to reach it in one click.

---

## Problem 2 — Full dashboard set per spec

The spec defines **nine** Data Centre dashboard views: six operational (§5) and three SitDeck Risk Intelligence (§6). All must exist and match the content below.

**Routes (canonical):**

| Route | Purpose |
|-------|--------|
| `/dashboards/data-centre` | **Portfolio overview** — landing page; all DC properties |
| `/dashboards/data-centre/:propertyId` | **Single DC property overview** — one property |
| `/dashboards/data-centre/:propertyId/pue` | **PUE deep-dive** |
| `/dashboards/data-centre/:propertyId/capacity` | **Capacity & power chain** |
| `/dashboards/data-centre/:propertyId/cooling` | **Cooling & water** |
| `/dashboards/data-centre/:propertyId/esg` | **ESG & reporting readiness** |
| `/dashboards/data-centre/:propertyId/geopolitical` | **Risk Intelligence:** Geopolitical & Conflict Risk (SitDeck embed) |
| `/dashboards/data-centre/:propertyId/climate-hazard` | **Risk Intelligence:** Climate & Natural Hazard Risk (SitDeck embed) |
| `/dashboards/data-centre/:propertyId/cyber-infrastructure` | **Risk Intelligence:** Cyber & Critical Infrastructure Risk (SitDeck embed) |

The last three are **SitDeck OSINT** dashboards ([SitDeck](https://sitdeck.com)): embed SitDeck widgets (iframe or JS SDK) in Secure panels; use property `latitude` / `longitude` as map centre. If SitDeck connection is not yet configured, show a placeholder panel with a short message (e.g. “Connect SitDeck in Data Library → Connectors to see risk intelligence”) and still provide the route and nav so the structure is complete.

**Content per dashboard (from spec §5.2–5.7):**

1. **Portfolio overview** (`/dashboards/data-centre`): PUE (avg + range), Total IT Load, Total Energy YTD, Renewable %, Carbon intensity, Properties at PUE risk, Capacity utilisation, Data coverage score; PUE trend by property; property table. This is the **landing** page — list/link to each DC property so user can click through to single-property view.

2. **Single DC overview** (`/dashboards/data-centre/:propertyId`): Six KPI tiles — Live PUE, IT Load, Total Energy, Cooling Energy, Water (WUE), Renewable %. Plus navigation to the four sub-dashboards (PUE, Capacity, Cooling, ESG).

3. **PUE deep-dive** (`/dashboards/data-centre/:propertyId/pue`): Time series PUE vs target; PUE component waterfall; temperature correlation; annualised PUE; benchmark vs Tier norms.

4. **Capacity & Power Chain** (`/dashboards/data-centre/:propertyId/capacity`): Capacity gauge, power chain diagram, hall-level breakdown, redundancy view, capacity depletion forecast.

5. **Cooling & Water** (`/dashboards/data-centre/:propertyId/cooling`): Cooling energy breakdown, WUE trend, cooling efficiency, free cooling hours, water consumption, make-up water.

6. **ESG & Reporting Readiness** (`/dashboards/data-centre/:propertyId/esg`): GRESB DC module readiness, EED Article 12 fields, renewable breakdown, Scope 2 (market/location), data quality from CoverageEngine.

7. **Geopolitical & Conflict Risk** (`/dashboards/data-centre/:propertyId/geopolitical`): SitDeck OSINT dashboard — embed widget (iframe or JS SDK); centre on property lat/lng. If SitDeck not connected: placeholder + “Connect SitDeck in Data Library → Connectors”.

8. **Climate & Natural Hazard Risk** (`/dashboards/data-centre/:propertyId/climate-hazard`): SitDeck OSINT dashboard — same as above.

9. **Cyber & Critical Infrastructure Risk** (`/dashboards/data-centre/:propertyId/cyber-infrastructure`): SitDeck OSINT dashboard — same as above.

Data for §5 dashboards from `dc_metadata`, `data_library_records`, `properties`. Where a field is not in schema, use placeholder and add `// MISSING_SCHEMA: <description>`. SitDeck dashboards: [spec §6](specs/secure-dc-spec-v2.md); implementation guide [implementation-guide-phase-3-dc.md](specs/implementation-guide-phase-3-dc.md).

---

## Prompt to paste into Lovable

```
Data Centre dashboards — fix two issues. Do not change Office or other asset-type dashboards.

**1) Navigation**
- The Data Centre dashboards landing page lists all DC properties (portfolio overview). When the user clicks a property or a dashboard card, they go to a property-level page but have no way to get back.
- Fix: On every Data Centre dashboard page except the landing page, add a clear way back to the Data Centre dashboards landing: either a breadcrumb whose first segment is "Data Centre dashboards" linking to the landing route (e.g. /dashboards/data-centre), or a "Back to Data Centre dashboards" link/button that goes to that route. One click from any DC dashboard (property overview, PUE, Capacity, Cooling, ESG) must return the user to the landing.

**2) Full dashboard set per spec**
- The backend spec (secure-dc-spec-v2.md §5 and §6) requires nine Data Centre dashboard views. Implement any that are missing and align content with the spec.
- Operational (§5): Landing /dashboards/data-centre (portfolio overview: PUE avg/range, IT load, energy YTD, renewable %, etc.; property table). Single property /dashboards/data-centre/:propertyId (six KPI tiles + links to sub-dashboards). Then: /pue (time series, waterfall, Tier benchmark), /capacity (capacity gauge, power chain, hall-level, redundancy), /cooling (cooling breakdown, WUE trend, free cooling, water), /esg (GRESB, EED Article 12, renewable, Scope 2, data quality).
- Risk Intelligence (§6 — SitDeck): /dashboards/data-centre/:propertyId/geopolitical (Geopolitical & Conflict Risk), /climate-hazard (Climate & Natural Hazard Risk), /cyber-infrastructure (Cyber & Critical Infrastructure Risk). Embed SitDeck widgets (iframe or JS SDK per https://sitdeck.com); centre on property latitude/longitude. Group these under a "Risk Intelligence" tab or section. If SitDeck is not connected yet, show a placeholder panel: "Connect SitDeck in Data Library → Connectors to see risk intelligence" and still provide the route and nav.
- Data from dc_metadata, data_library_records, properties for §5. Use placeholder + // MISSING_SCHEMA where a field is not in schema. Match existing dashboard component structure and design; read-only.
```

---

## After applying

- From any DC property or sub-dashboard (PUE, Capacity, Cooling, ESG, or SitDeck Risk Intelligence), one click returns to the Data Centre dashboards landing.
- All nine DC dashboard views exist: six operational (§5) and three SitDeck Risk Intelligence (§6); landing shows portfolio and links to each property.
- [APP-ROUTE-MAP.md](APP-ROUTE-MAP.md) § Dashboards module already references the DC spec; no backend change required unless you add new routes and want to document them.
- **Per-dashboard UI spec:** To fix dashboard content/KPIs to match the spec, use [DC-DASHBOARD-SPECS-FOR-LOVABLE.md](DC-DASHBOARD-SPECS-FOR-LOVABLE.md) (paste into Lovable with [LOVABLE-PROMPT-DC-DASHBOARDS-UI-PER-SPEC.md](LOVABLE-PROMPT-DC-DASHBOARDS-UI-PER-SPEC.md)).

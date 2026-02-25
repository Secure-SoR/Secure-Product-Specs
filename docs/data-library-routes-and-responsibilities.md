# Secure — Data Library Routes & Responsibilities

Backend reference for Data Library routes, subject responsibilities, and engine flow. The **four-layer model** (Activity → Emissions → Governance & Strategy → Compliance & Disclosure) is defined in [Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md](sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md). Aligns with [lovable-data-library-context.md](sources/lovable-data-library-context.md) and [lovable-data-library-spec.md](sources/lovable-data-library-spec.md). Lovable also has: `/data-library/water`, `/data-library/indirect-activities`, `/data-library/scope-data` (emissions, read-only), and `/data-library/occupant-feedback/create`, `/data-library/occupant-feedback/submission/:id`.

---

## /data-library

**Tabs:**

- My Data
- Shared Data
- Connectors

---

## /data-library/energy

**Subject:** Energy & Utilities

**Components:**

- Tenant Electricity (submetered)
- Landlord Utilities (service charge / recharge)
- Heating (optional)
- Water (optional)
- Direct Emissions (Scope 1 if applicable)

**Per component:**

- Control badge
- Confidence badge
- Coverage status
- KPI summary
- Evidence drawer
- Audit history

**Feeds:**

- CoverageEngine
- EmissionsEngine
- ControllabilityEngine

---

## /data-library/waste

**Subject:** Waste & Recycling

**Full component architecture:** [Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md](sources/Secure_DataLibrary_Energy_Waste_Component_Architecture_v1.md) — summary block, contractor block, streams breakdown, waste-in-service-charge case; do not mix waste UI inside Energy page.

**Content:**

- Contractor (e.g., Recorra) — contract type (direct tenant / landlord-managed)
- Waste streams (Plastics, Mixed glass, Food tins & drink cans, Mixed paper & card, Household waste)
- Period table (kg, method, cost, evidence)
- Confidence (Measured / Allocated / Estimated / Cost only)

**Scope mapping:** Scope 3 Category 5 (at emissions layer)

---

## /data-library/certificates

**Subject:** EPC, BREEAM, ISO, WELL, etc.  
Evidence-driven.

---

## /data-library/esg

Policies & disclosures:

- Environmental Policy
- Net Zero Commitment
- GRESB
- CDP
- TCFD
- Supplier Code

---

## /data-library/governance

Structured governance registry:

- Oversight
- Policy
- Commitment
- Engagement
- Risk

---

## /data-library/targets

Target register:

- Carbon
- Energy
- Waste
- Water

---

## /data-library/scope-data — Emissions (Calculated)

**Subject:** Layer 2 — Emissions (derived, read-only). No manual editing; no "Add Data".

**Engineering handoff:** [Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md](sources/Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md) — React hierarchy (ScopeSummaryCard, CalculationMetaStrip, ScopeBreakdownAccordion, TraceabilityDrawer), data contracts (EmissionsPageVM, EmissionsLineItem), state/selectors, read-only rules, empty states, scope colors (1=amber, 2=green, 3=blue). MVP: mock VM; later: Emissions Engine API.

**Engine logic:** [Secure_Emissions_Engine_Mapping_v1.md](sources/Secure_Emissions_Engine_Mapping_v1.md) — Activity → Scope mapping matrix, factor resolution, calculation formula, scope aggregation, confidence scoring, factor versioning.

**Engine schema (draft):** [Secure_Emissions_Engine_Schema_Draft_v1.md](sources/Secure_Emissions_Engine_Schema_Draft_v1.md) — emission_factor_sets, emission_calculation_runs, emission_line_items; VM mapping.

**Coverage (KPI completeness):** [Secure_KPI_Coverage_Logic_Spec_v1.md](sources/Secure_KPI_Coverage_Logic_Spec_v1.md) — Complete/Partial/Unknown from component state; utilityComponentProfile; CoverageEngine.evaluate().

**Content:** Scope 1/2/3 cards with totals + confidence mix bar; metadata strip (factor set, timestamp); collapsible tables per scope; row click → traceability drawer (factor, formula, source record links, evidence list view-only).

---

## /data-library/occupant-feedback

Survey & wellness inputs.

---

## Engine Relationships

```
Activity Record
  → CoverageEngine
  → EmissionsEngine
  → ControllabilityEngine
  → Dashboards & Recommendations
```

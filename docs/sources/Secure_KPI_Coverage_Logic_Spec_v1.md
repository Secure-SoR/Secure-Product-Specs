# Secure — KPI Coverage & Completeness Logic  
## Engineering Specification (v1)

**Date:** 2026-02-20  
**Context:** Corporate Occupier (e.g., 140 Aldersgate)  
**Purpose:** Define how the system automatically determines whether KPIs are **Complete**, **Partial**, or **Unknown**.

---

## 1. Problem Statement

In multi-tenant corporate occupier scenarios:

- Some utilities are **directly metered** (tenant electricity).
- Some are **included in landlord service charge** (water, heating, base-building electricity).
- Some are **direct third-party contracts** (waste).
- Disclosure quality varies (kWh vs cost-only vs no breakdown).

We must automatically determine whether dashboard KPIs represent:

- **Complete** coverage,
- **Partial** coverage,
- **Or Unknown** coverage.

This must scale to portfolios with hundreds or thousands of heterogeneous properties.  
**No manual per-property configuration is acceptable.**

---

## 2. Core Design Principle

**Completeness is not a property setting.**

Completeness is a **computed outcome** derived from:

- **Component expectations** (based on tenancy + billing evidence)
- **Component state** (measured / allocated / missing / unknown)
- **KPI requirements** (what components are required for that KPI)

---

## 3. Component-Based Model

Each property is evaluated using a set of **utility components**.

**Example components (energy domain):**

- `tenant_electricity_direct`
- `landlord_electricity_recharge`
- `heating_energy`
- `water`
- `waste`

Each component has a **computed state**:

- `present_measured`
- `present_allocated`
- `present_cost_only`
- `expected_missing`
- `not_applicable`
- `unknown`

This state is **computed automatically** from ingested evidence.

---

## 4. Utility Component Profile (Per Property, Per Period)

For each property and reporting period, the system builds:

```
utilityComponentProfile = {
  propertyId,
  period,
  components: {
    tenant_electricity_direct: state,
    landlord_electricity_recharge: state,
    heating_energy: state,
    water: state,
    waste: state
  }
}
```

This is **NOT** manually configured. It is **derived** from:

- Billing source records
- Tenancy model (whole building vs partial floors)
- Document classifier output (keywords: service charge, water, HVAC, kWh, etc.)
- Known vendor associations (Trio, MAPP, Recorra)

---

## 5. Inference Rules (High-Level)

**Rule A — Tenant Electricity**  
If submeter invoices (kWh) exist → `tenant_electricity_direct` = `present_measured`

**Rule B — Service Charge Presence**  
If recharge invoice exists → `landlord_electricity_recharge` = `present_allocated` or `present_cost_only` (depending on breakdown level)

**Rule C — Multi-Tenant Lease**  
If tenancy covers only part of building → landlord components are expected. If no landlord data present → landlord component = `expected_missing`

**Rule D — No Evidence**  
If no invoice or evidence exists for a component → component = `unknown` (not `expected_missing`)

**Rule E — Explicit Exclusion**  
If lease metadata confirms “no heating included” → `heating_energy` = `not_applicable`

### Heating Energy Component Inference (Service Charge)

**Do not** default `heating_energy` to `expected_missing`.

If service charge exists:

- If HVAC/heating is **not mentioned** → `heating_energy` = `unknown`
- If HVAC/heating is **mentioned but only £** → `heating_energy` = `present_cost_only`
- If HVAC/heating is **mentioned + allocation basis** → `heating_energy` = `present_allocated`
- If **kWh heat metering** exists → `heating_energy` = `present_measured`
- If **explicitly withheld/not provided** → `heating_energy` = `expected_missing`

---

## 6. KPI Requirement Mapping

Each KPI defines **required components**.

**Example:**

- **Energy Consumption (kWh) KPI** requires: `tenant_electricity_direct`, `landlord_electricity_recharge` (if expected), `heating_energy` (if expected)
- **Water KPI** requires: `water`
- **Waste KPI** requires: `waste`

---

## 7. Coverage Status Logic

Each KPI evaluates component states.

| Status | Definition |
|--------|------------|
| **COMPLETE** | All required components are `present_measured`, `present_allocated`, OR explicitly `not_applicable` |
| **PARTIAL** | At least one required component is `expected_missing` OR `present_cost_only` (for quantity-based KPI) |
| **UNKNOWN** | One or more required components are `unknown` AND not explicitly expected |

---

## 8. Example — 140 Aldersgate

**Property profile:**

- `tenant_electricity_direct` = `present_measured`
- `landlord_electricity_recharge` = `present_cost_only`
- `heating_energy` = `expected_missing` (included in service charge prorata)
- `waste` = `present_measured`

**Results:**

- **Energy Consumption KPI** → Partial (landlord energy expected but no kWh breakdown)
- **Energy Cost KPI** → Complete (cost present for tenant + service charge)
- **Waste KPI** → Complete
- **Water KPI** → Unknown or Partial (depending on evidence)

---

## 9. Why This Scales

The system does **NOT**:

- Require per-property configuration
- Assume identical buildings
- Hardcode “water always in service charge”

**Instead:**

- It infers component expectations per property
- It computes component states from data
- It evaluates KPI completeness deterministically

This works for 1 property, 1,000 properties, mixed lease structures, mixed billing models.

---

## 10. Three-Level Status Model (Critical)

Each KPI must show: **Complete** | **Partial** | **Unknown**.

- **Unknown** is distinct from **Partial**.
- **Partial** means: “We know something is missing.”
- **Unknown** means: “We cannot yet determine whether something is missing.”

---

## 11. Dashboard Integration

Dashboards must:

- Display **completeness badge** next to KPI
- Provide **tooltip explanation** (machine-generated from component state reasoning), e.g.:
  - “Includes tenant electricity only; landlord utilities not disclosed.”
  - “Water data included via service charge, no volume breakdown.”
  - “Heating source unconfirmed.”

---

## 12. Implementation Notes

- **Coverage engine runs:** On record ingestion, on month close, on lease/tenancy updates.
- **coverageAssessment** objects can be **cached**.
- No manual toggles per property.
- Exception overrides allowed but rare.

---

## Pseudocode: CoverageEngine.evaluate(propertyId, period)

**Purpose:** Compute KPI coverage statuses (Complete / Partial / Unknown) using inferred component states + KPI requirement mapping.

**Inputs:** `propertyId`, `period` (e.g. `{ startISO, endISO }` or `"YYYY-MM"`)

**Outputs:** `coverageAssessment`: `{ propertyId, period, domainAssessments, kpiAssessments, utilityComponentProfile, evaluatedAt }`

### 1) Load core context

- `tenancy` = TenancyService.getTenancyProfile(propertyId) — e.g. leasePattern, demisedAreas, landlordId
- `records` = DataLibrary.getRecords(propertyId, period, categories: energy_utilities, waste, indirect_activities, water)
- Optional: `docFlags` = EvidenceService.getInferredFlags(propertyId, period) — e.g. hasServiceCharge, includesWater, includesHVAC, hasKwhBreakdown, vendors

### 2) Infer expected component set (NOT per-property manual config)

- Start from account-type/portfolio **template** (requiredComponentsByDomain, expectedComponentsByDomain)
- If tenancy is partial floors: add landlord/recharge/heating/water to expected
- If docFlags.hasServiceCharge or existsRechargeInvoice(records): add landlord_electricity_recharge, heating_energy, water to expected
- Apply explicit N/A from lease metadata (e.g. heating_energy not applicable)

### 3) Compute component states from records + evidence

For each component:

- If marked not applicable → `not_applicable`
- If no related records: if component in expected and docFlags indicate it exists → `expected_missing`; else → `unknown`
- If records exist: if hasQuantityBreakdown → `present_measured` or `present_allocated`; else → `present_cost_only`

Compute: `componentState["tenant_electricity_direct"]`, `landlord_electricity_recharge`, `heating_energy`, `water`, `waste`.

### 4) KPI requirement mapping

- Define per-KPI: `requires` + `conditionallyRequires` (e.g. energy_consumption_kwh requires tenant_electricity_direct, conditionally landlord_electricity_recharge, heating_energy)
- **Expand** conditional requirements based on expected components for this property

### 5) Determine KPI coverage status

For each KPI and its required components:

- If any required component state is `unknown` → collect unknownReasons
- If any is `expected_missing` or `present_cost_only` (for quantity KPI) → collect partialReasons
- **Precedence:** If partialReasons not empty → status **partial**; else if unknownReasons not empty → status **unknown**; else → **complete**

### 6) Domain summary status (optional)

- domainAssessments.energy = worst of energy KPI statuses; same for water, waste

### 7) Build output

- `utilityComponentProfile` = { propertyId, period, components: componentState, expectedComponents, inferredFrom }
- `coverageAssessment` = { propertyId, period, evaluatedAt, domainAssessments, kpiAssessments, utilityComponentProfile }
- Persist/cache: CoverageStore.upsert(coverageAssessment)
- RETURN coverageAssessment

### Helper functions (sketch)

- `existsRechargeInvoice(records)` — billingSource == landlord_recharge OR vendor MAPP OR text “service charge”
- `docFlagsIndicatesComponentExists(docFlags, component)` — e.g. landlord_electricity_recharge ↔ hasServiceCharge; heating_energy ↔ includesHVAC; water ↔ includesWater; waste ↔ vendor Recorra
- `hasQuantityBreakdown(records)` — any record with units kWh/m3/kg/km and quantity > 0
- `allRecordsMeasured(records)`, `anyRecordsAllocated(records)`

**Heating energy:** Infer from service charge evidence + line items + keywords + cost breakdown (do not default to expected_missing).

---

## 13. Schema draft for persistence (CoverageEngine)

When implementing the CoverageEngine backend, cache output of `evaluate()` so dashboards and Energy/Waste pages can read coverage without recomputing every time.

**Suggested tables:**

- **coverage_assessments** — One row per property per period (or account-level). Columns: id, account_id, property_id, period_start, period_end, evaluated_at, domain_assessments (jsonb: energy, water, waste, …), kpi_assessments (jsonb: array of { kpiId, domain, status, reasons }), utility_component_profile (jsonb: components, expected_components, inferredFrom). Index: (property_id, period_start).
- **utility_component_profiles** (optional) — If querying by component state is needed without parsing JSONB: property_id, period_start, period_end, tenant_electricity_direct, landlord_electricity_recharge, heating_energy, water, waste (each text: present_measured, present_allocated, etc.).

RLS: account-scoped; user can only read/write for properties in their account. Upsert on each `CoverageEngine.evaluate()` run (on ingestion, month close, tenancy update).

---

*End of Specification*

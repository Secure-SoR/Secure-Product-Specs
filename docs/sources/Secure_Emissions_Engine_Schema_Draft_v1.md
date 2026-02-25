# Secure — Emissions Engine Schema Draft (v1)

**Purpose:** Persist calculation runs, factor sets, and line-item outputs so the Emissions (Calculated) page and reporting can consume deterministic, versioned results. Aligns with [Secure_Emissions_Engine_Mapping_v1.md](Secure_Emissions_Engine_Mapping_v1.md) and [Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md](Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md).

---

## 1. Design Principles

- **Emissions are never primary data** — they are derived and stored only as engine outputs.
- **Every result is versioned** — factor dataset, year, calculation version, `calculated_at`.
- **Traceability** — each line item can reference source `data_library_record` IDs and evidence.
- **Scope aggregation** — totals are derived from line items (no stored “scope totals” except as cached summary).

---

## 2. Table Overview

| Table | Purpose |
|-------|---------|
| `emission_factor_sets` | Emission factors by activity type, scope, geography; versioned by year/dataset. |
| `emission_calculation_runs` | One run per property (or account) per period; links to factor set and stores run-level metadata. |
| `emission_line_items` | One row per activity → scope → factor application; quantity, factor, tCO₂e, confidence, source record IDs. |

---

## 3. Table Definitions (Draft)

### 3.1 emission_factor_sets

Stores factor metadata and values used by the engine. Can be seeded from DEFRA/EEIO or supplier-specific datasets.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| id | uuid | NO | PK |
| account_id | uuid | YES | Optional: account-specific factor overrides; null = global/default set |
| name | text | NO | e.g. "UK DEFRA", "Supplier X Market" |
| factor_year | int | NO | e.g. 2023 |
| version | text | NO | e.g. "v1.0", dataset version tag |
| scope | smallint | NO | 1, 2, or 3 |
| activity_type | text | NO | e.g. electricity_kwh, gas_kwh, waste_landfill_kg, commuting_km |
| factor_value | numeric | NO | kgCO₂e per unit (or per £ for spend-based) |
| factor_unit | text | NO | e.g. "kgCO2e/kWh", "kgCO2e/kg", "kgCO2e/GBP" |
| source_label | text | YES | e.g. "DEFRA", "EEIO" |
| geography_iso | text | YES | e.g. "GB" for location-based |
| is_market_based | boolean | NO | false = location-based; true = market-based (Scope 2) |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

**Indexes:** (account_id, name, factor_year, scope, activity_type) for lookup during calculation.

---

### 3.2 emission_calculation_runs

One row per calculation invocation (per property and period). Ties together factor set, period, and high-level totals.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| id | uuid | NO | PK |
| account_id | uuid | NO | FK → accounts.id |
| property_id | uuid | YES | FK → properties.id; null = account-level rollup |
| period_start | date | NO | Reporting period start |
| period_end | date | NO | Reporting period end |
| factor_set_id | uuid | YES | FK → emission_factor_sets.id; which factor set was used |
| calculation_version | text | NO | e.g. "v1.0" (engine version) |
| factor_dataset_name | text | NO | e.g. "UK DEFRA" (denormalised for display) |
| factor_year | int | NO | e.g. 2023 |
| scope2_method | text | YES | "location" \| "market" \| "hybrid" |
| calculated_at | timestamptz | NO | When the run completed |
| status | text | NO | "completed" \| "failed" \| "partial" |
| total_scope1_tco2e | numeric | YES | Sum of Scope 1 line items (cached) |
| total_scope2_tco2e | numeric | YES | Sum of Scope 2 line items (cached) |
| total_scope3_tco2e | numeric | YES | Sum of Scope 3 line items (cached) |
| grand_total_tco2e | numeric | YES | Cached grand total |
| measured_share | numeric | YES | 0–1 overall (for metadata strip) |
| allocated_share | numeric | YES | 0–1 overall |
| estimated_share | numeric | YES | 0–1 overall |
| meta | jsonb | YES | Optional: run config, errors, recalculation trigger |
| created_at | timestamptz | NO | |
| updated_at | timestamptz | NO | |

**Indexes:** (account_id, property_id, period_start, period_end), (calculated_at). Unique constraint optional: (property_id, period_start, period_end) per account to avoid duplicate runs for same period.

---

### 3.3 emission_line_items

One row per activity record that contributed to emissions; maps to EmissionsPageVM line items and traceability.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| id | uuid | NO | PK |
| calculation_run_id | uuid | NO | FK → emission_calculation_runs.id |
| scope | smallint | NO | 1, 2, or 3 |
| activity_label | text | NO | e.g. "Tenant Electricity (Trio)" |
| dataset_id | text | NO | "energy_utilities" \| "waste" \| "indirect_activities" |
| billing_source | text | YES | tenant_direct, landlord_recharge, third_party, unknown |
| control | text | YES | tenant, landlord, shared, unknown |
| ghg_category | text | YES | Scope 3 only: cat5_waste, cat6_business_travel, cat7_employee_commuting, etc. |
| quantity | numeric | NO | Activity quantity |
| unit | text | NO | kWh, m3, kg, km, GBP, unknown |
| factor_id | uuid | YES | FK → emission_factor_sets.id (which factor was applied) |
| factor_value | numeric | NO | Denormalised kgCO2e per unit |
| factor_unit | text | NO | e.g. "kgCO2e/kWh" |
| factor_source | text | YES | e.g. "DEFRA" |
| factor_year | int | YES | Factor year |
| emissions_tco2e | numeric | NO | Result: quantity × factor ÷ 1000 (if kg→t) |
| confidence | text | NO | measured, allocated, estimated, unknown |
| period_start | date | NO | Activity period |
| period_end | date | NO | Activity period |
| source_record_ids | uuid[] | YES | data_library_records.id[] for traceability |
| evidence_file_ids | uuid[] | YES | documents.id[] or evidence_attachments (optional) |
| created_at | timestamptz | NO | |

**Indexes:** (calculation_run_id), (calculation_run_id, scope). Enables “all line items for run” and “Scope 2 only” queries for UI.

---

## 4. Factor Versioning and Recalculation

- When **factor set** or **factor version** changes:
  - Insert a new `emission_calculation_run` for the same property/period (new `calculated_at`, new run id).
  - Optionally mark previous run as superseded (e.g. `meta->>'superseded_by' = new_run_id`) or retain full history.
- **Recalculation events** can be logged in `audit_events` (entity_type = `emission_calculation_runs`, action = create) or in `emission_calculation_runs.meta`.

---

## 5. Mapping to Emissions (Calculated) Page VM

| VM field | Source |
|----------|--------|
| `meta.calculationVersion` | emission_calculation_runs.calculation_version |
| `meta.factorDatasetName` | emission_calculation_runs.factor_dataset_name |
| `meta.factorYear` | emission_calculation_runs.factor_year |
| `meta.scope2Method` | emission_calculation_runs.scope2_method |
| `meta.lastCalculatedAtISO` | emission_calculation_runs.calculated_at |
| `meta.measuredShare` / `allocatedShare` / `estimatedShare` | emission_calculation_runs.*_share |
| `totals.grandTotal_tco2e` | emission_calculation_runs.grand_total_tco2e |
| `totals.scopeSummaries` | Derived from emission_line_items grouped by scope + confidence mix |
| `lineItems` | emission_line_items rows (map columns to EmissionsLineItem type) |

---

## 6. RLS and Multi-Tenancy

- All tables **account-scoped** via `account_id` (emission_calculation_runs, emission_line_items via run; emission_factor_sets optionally).
- RLS: user can only read/write runs and line items for accounts they belong to (via `account_memberships`).
- `emission_factor_sets`: if global, no account_id; else restrict by account.

---

## 7. Optional: Coverage Engine Persistence (Reference)

For [Secure_KPI_Coverage_Logic_Spec_v1.md](Secure_KPI_Coverage_Logic_Spec_v1.md), the CoverageEngine can persist:

- **coverage_assessments** — property_id, period_start, period_end, evaluated_at, domain_assessments (jsonb), kpi_assessments (jsonb), utility_component_profile (jsonb). Cached output of `CoverageEngine.evaluate()`.
- **utility_component_profiles** — optional standalone table (property_id, period, components jsonb, expected_components jsonb) if you want to query by component state without parsing coverage_assessments.

Schema for these can be added in a separate draft (e.g. `docs/database/coverage-engine-schema-draft.md`) when implementing the CoverageEngine backend.

---

*End of Schema Draft v1*

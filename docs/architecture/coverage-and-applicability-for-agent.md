# Coverage and applicability — for agent and inference

This doc summarises how **coverage/confidence** (Complete / Partial / Unknown) is determined for energy, water, and heating, and how the backend stores **applicability** and **service charge includes** so the agent and CoverageEngine can use them.

**Full spec:** [Secure_KPI_Coverage_Logic_Spec_v1.md](../sources/Secure_KPI_Coverage_Logic_Spec_v1.md).

---

## 1. Why this matters

- **Energy consumption** when a bill is uploaded can be **complete** or **partial** depending on whether tenant electricity, landlord recharge (service charge), and heating are present and how they are supplied.
- **Water** and **heating** may be:
  - **Separate bills** only,
  - **Included in service charge only** (no separate tenant bill),
  - **Both** (separate bill + service charge includes water/heating).
- The agent and the CoverageEngine need a single source of truth: **per property**, which components are applicable and how (separate bill vs in service charge), and **what the service charge includes** (energy, water, heating).

---

## 2. Tables the agent and engine read

### 2.1 `property_utility_applicability`

One row per **property × component**. Tells how that component is supplied for this property.

| Column         | Meaning |
|----------------|--------|
| `property_id`  | Property (FK to `properties`) |
| `component`     | One of: `tenant_electricity`, `landlord_recharge`, `heating`, `water`, `waste` |
| `applicability` | One of: `separate_bill`, `included_in_service_charge`, `both`, `not_applicable` |

**Meaning of applicability:**

- **`separate_bill`** — Data comes only from separate bills (e.g. tenant electricity). No service charge for this component.
- **`included_in_service_charge`** — No separate bill; data comes **only** from the service charge (e.g. water and heating at 140 Aldersgate). Mark as “not applicable as separate bill” for tenant.
- **`both`** — Both a separate bill **and** service charge can contain this (e.g. water: direct meter + water in SC). Completeness needs both sources when both are expected.
- **`not_applicable`** — Component not relevant for this property.

**Agent use:** When reasoning about coverage or advising “upload water bill”, check `applicability` for `water` and `heating`. If `included_in_service_charge`, the tenant does **not** have a separate water/heating bill; completeness is driven by the **service charge** (and `property_service_charge_includes`).

### 2.2 `property_service_charge_includes`

One row per **property**. Describes what the landlord service charge (recharge) is known to include.

| Column            | Type    | Meaning |
|-------------------|--------|--------|
| `property_id`     | uuid   | Property (unique) |
| `includes_energy` | boolean | Service charge includes energy (e.g. base-building electricity) |
| `includes_water` | boolean | Service charge includes water |
| `includes_heating`| boolean | Service charge includes heating/HVAC |
| `energy_inclusion_scope` | text, optional | When includes_energy true: `base_building_only` \| `tenant_consumption_included` |
| `water_inclusion_scope`  | text, optional | When includes_water true: `base_building_only` \| `tenant_consumption_included` |
| `heating_inclusion_scope`| text, optional | When includes_heating true: `base_building_only` \| `tenant_consumption_included` |

**Inclusion scope:** When a utility is included in the service charge, indicate whether it is **base_building_only** (SC covers only base building/common areas; tenant demised space not in SC) or **tenant_consumption_included** (SC includes tenant full share: base building shared + measured/allocated tenant spaces). Only when scope is `tenant_consumption_included` must we avoid adding separate uploads (double-count rule). When `base_building_only`, separate tenant data is valid.

**Agent use:** If the user uploads a “service charge” or “landlord recharge” bill, these flags indicate whether that document is considered to cover energy, water, and/or heating for coverage inference. Together with `property_utility_applicability`, the engine knows whether water/heating are “complete” when only the service charge is present (e.g. water = `included_in_service_charge` and `includes_water` = true → water KPI can be complete when the service charge bill is uploaded and no separate water bill is expected).

---

## 3. Coverage rules (short form)

- **Energy consumption (kWh) KPI**  
  Requires: tenant electricity (if applicable), landlord recharge (if expected), heating (if expected).  
  Complete when all expected components are present_measured or present_allocated (or not_applicable). Partial when e.g. only cost, no kWh; or expected component missing.

- **Water KPI**  
  Requires: `water` component.  
  - If `applicability = included_in_service_charge` and `includes_water = true`: **complete** when the service charge (that includes water) is uploaded; no separate water bill needed.  
  - If `applicability = both`: **complete** only when **both** the water source(s) **and** the service charge that includes water are present (per spec).  
  - If `applicability = separate_bill`: only separate water data counts.

- **Heating**  
  Same idea: `included_in_service_charge` + `includes_heating` → service charge upload can satisfy heating; `both` → need both direct/heating data and service charge that includes heating.

- **States** (from KPI Coverage spec): `present_measured`, `present_allocated`, `present_cost_only`, `expected_missing`, `not_applicable`, `unknown`.  
  **Complete** = all required components in present_* or not_applicable. **Partial** = at least one expected_missing or present_cost_only (for quantity KPI). **Unknown** = required component unknown.

---

## 4. How inference uses these tables

1. **Expected components**  
   Use `property_utility_applicability`: e.g. if `water` is `included_in_service_charge`, do **not** expect a separate water bill; if `both`, expect both service charge and separate water when both apply.

2. **Service charge content**  
   Use `property_service_charge_includes`: when a recharge/service charge document exists, set `landlord_electricity_recharge` / `heating_energy` / `water` component state from evidence **and** these flags (e.g. if `includes_water` then that upload counts toward water).

3. **Water KPI complete**  
   - Water `included_in_service_charge` only → complete when service charge (with `includes_water`) is uploaded.  
   - Water `both` → complete when both water source(s) and service charge that includes water are uploaded.  
   - Water `separate_bill` → complete when separate water data is present.

4. **Marking “not applicable — included in service charge”**  
   Stored as `applicability = included_in_service_charge` for that component (e.g. heating, water). The UI/Lovable should allow users to set this so the DB reflects “no separate bill; included in service charge only”.

---

## 5. Avoiding double counting (critical)

When **water** (or **heating**) has applicability = **`included_in_service_charge`**, consumption for that component is **already fully represented in the service charge** (e.g. % allocation by sqm). There is no separate meter; the service charge is the single source of truth for that utility.

**Rule:** For **consumption / KPI totals** and **emissions**, the engine must **not** add separate water (or heating) records when applicability is `included_in_service_charge` **and** the service charge inclusion scope for that utility is **`tenant_consumption_included`** (i.e. the SC already represents the tenant’s full consumption). When the scope is **`base_building_only`**, the service charge does not include the tenant’s demised space, so separate tenant data is **not** double counting.

| Applicability | Inclusion scope (when in SC) | Source for consumption | Separate water/heating upload |
|---------------|------------------------------|-------------------------|-------------------------------|
| `included_in_service_charge` | `tenant_consumption_included` | **Only** the service charge. | **Must not** add to KPI total; warn user (double count). |
| `included_in_service_charge` | `base_building_only` | Service charge = base building only; tenant share may come from separate record. | **Can** add (tenant’s own space); no double count. |
| `separate_bill` | n/a | Only separate records. | Normal. |
| `both` | n/a | **Both** SC (for its portion) **and** separate (for metered portion); combine without double-counting. | Normal. |

**Implementation:** When computing water (or heating) consumption for a property/period:

1. Read `property_utility_applicability` and `property_service_charge_includes` (including *_inclusion_scope) for that property.
2. If `included_in_service_charge` **and** (e.g.) `water_inclusion_scope = 'tenant_consumption_included'`: use **only** the service charge for water. **Ignore** separate water records for that property/period for the KPI total.
3. If `included_in_service_charge` **and** `water_inclusion_scope = 'base_building_only'`: use the service charge for base building share; tenant’s share can come from separate record(s) if present (no double count).
4. If `separate_bill`: use only separate records.
5. If `both`: use both sources without double-counting.

**UI/agent:** When water is "included in service charge" with scope **tenant_consumption_included**, and the user uploads a separate water bill, show a **warning** about double counting. When scope is **base_building_only**, no such warning (separate record = tenant’s own consumption).

---

## 6. Where this is implemented

- **DB:** `property_utility_applicability`, `property_service_charge_includes` (with optional `*_inclusion_scope` columns) — migrations: `add-property-utility-applicability-and-service-charge-includes.sql`, `add-service-charge-inclusion-scope.sql`.
- **CoverageEngine (future):** Will call `evaluate(propertyId, period)`, load these tables + data library records, infer component states, then compute KPI status (Complete/Partial/Unknown).
- **Agent:** Read the same tables to reason about what’s missing and what “complete” means for water/heating (e.g. “water is complete once the service charge that includes water is uploaded”).

---

## 7. Lovable / UI (and double-count warning)

The app should allow:

- **Per property:** Set applicability per component (`separate_bill` | `included_in_service_charge` | `both` | `not_applicable`), especially for **heating** and **water** (e.g. “Not applicable as separate — included in service charge”).
- **Per property:** Set **service charge includes**: energy, water, heating (persisted in `property_service_charge_includes`).

So the backend and agent have a single source of truth for “does this property have separate water/heating bills or not?” and “does the service charge include energy/water/heating?”.

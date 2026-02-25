# Secure — Data Library Component Architecture  
## Energy & Utilities + Waste & Recycling

**Version:** v1.0  
**Date:** 2026-02-20  
**Context:** Corporate Occupier (Multi-Tenant + Whole Building Support)

---

## 1. Objective

Design Data Library pages that support:

- Multi-tenant buildings
- Whole-building tenants
- Partial floor leases
- Submetered utilities
- Service charge bundled utilities
- Optional heating/water submeters
- Landlord vs tenant control
- Base building vs demised spaces
- Third-party waste contracts
- Portfolio scalability (1000+ assets)

Architecture must be:

- **Component-based** (backend aligned)
- **Subject-grouped** (UI clarity)
- **Upload-friendly**
- Compatible with **CoverageEngine** and **EmissionsEngine**

---

## 2. Core Design Principle

**UI groups by subject:**

- Energy & Utilities
- Waste & Recycling

Within each subject, the system operates at the **component level**.

Each component must:

- Display **control** (Tenant / Landlord / Shared)
- Display **status** (Measured / Allocated / Cost Only / Unknown / Missing / N/A)
- Display **coverage** (period completeness)
- Allow uploads
- Be **space-aware**
- Feed CoverageEngine

**Billing source is metadata** — not the primary grouping logic.

---

## 3. ENERGY & UTILITIES PAGE

**Route:** `/data-library/energy`

---

### 3.1 Page Header

- **Title:** Energy & Utilities
- **Subtitle:** Tenant electricity, landlord recharges, heating and water coverage.
- **Context badges:** Portfolio, Property, Organisation
- **Add Data dropdown** (component-aware):
  - Upload Tenant Electricity Invoice
  - Upload Service Charge / Landlord Recharge
  - Upload Heating Submeter
  - Upload Water Submeter
  - Manual Entry

---

### 3.2 Component Coverage Summary

Render top summary grid:

| Component | Control | Status | Coverage | Latest | Action |

**Components (fixed order):**

1. Tenant Electricity
2. Landlord Utilities
3. Heating
4. Water

**Status enum:**

- `present_measured` → Measured
- `present_allocated` → Allocated
- `present_cost_only` → Cost Only
- `expected_missing` → Missing
- `unknown` → Unknown
- `not_applicable` → Not Applicable

**Source:** `utilityComponentProfile`

---

### 3.3 Component Detail Sections

Each component is an **expandable section**.

---

#### 3.3.1 Tenant Electricity (Direct — Submetered)

**Supports:** Whole-building tenancy, partial floors, multiple submeters.

**Display:**

- Floors covered
- Meter type (Submeter / MPAN)
- Control: Tenant
- Scope: 2
- Confidence: Measured / Allocated

**Table schema:**

| Period | kWh | Cost | Confidence | Evidence | Actions |

**Upload behavior — auto-tag:**

- `componentType` = tenant_electricity_direct
- `control` = tenant
- `scope` = 2
- `billingSource` = tenant_direct

**Space awareness:** Display applicable spaces (tenant spaces only, or entire building if inferred).

---

#### 3.3.2 Landlord Utilities (Service Charge / Recharge)

**Purpose:** Capture bundled utilities.

**Display:**

- Recharge type (Service charge / Direct recharge)
- Vendor (e.g., MAPP)
- Breakdown available? (Yes / No)
- Allocation method (Area-based / Pro-rata / Unknown)

**Included components detection:** Base-building electricity, Heating (HVAC), Water, Unknown.

**Table schema:**

| Period | Cost | Breakdown Level | Allocation Method | Evidence |

**BreakdownLevel enum:** none, cost_categories, quantity_kwh, area_based, unknown

**Upload behavior — auto-tag:**

- `componentType` = landlord_electricity_recharge
- `control` = landlord
- `billingSource` = landlord_recharge

CoverageEngine distributes state across: landlord_electricity_recharge, heating_energy, water.

---

#### 3.3.3 Heating Energy

**Supports:** Heating included in service charge, separate heat network invoice, gas submeter, tenant heat submeter (rare).

**If no separate meter:**  
Display: "Heating appears included in landlord recharge. No consumption breakdown available."

**If submeter exists:**

| Period | kWh | Cost | Confidence | Evidence |

**Upload behavior — auto-tag:**

- `componentType` = heating_energy
- scope determined by fuel type
- control inferred from meter ownership

---

#### 3.3.4 Water

**Supports:**

1. Tenant water submeter
2. Water included in service charge
3. Direct water supplier invoice
4. No water data

**Table schema:**

| Period | m³ | Cost | Source | Confidence | Evidence |

**If included in service charge:**  
Display: "Water included in landlord recharge. No volume breakdown available."

**Upload behavior — auto-tag:**

- `componentType` = water
- scope = 3 (if water treatment emissions calculated)
- control determined by source

---

### 3.4 Utilities Data Gaps Panel

Auto-generated list from **CoverageEngine**.

**Examples:**

- Heating source not confirmed
- Water allocation method not disclosed
- Service charge lacks utility breakdown

**CTA:** Create Data Request

**Source:** `coverageAssessment.kpiAssessments.reasons`

---

## 4. WASTE & RECYCLING PAGE

**Route:** `/data-library/waste`

**Supports:**

- Direct third-party contract
- Landlord-managed waste
- Weight-based data
- Cost-only data
- Mixed stream buildings
- Multi-tenant allocations

---

### 4.1 Waste Summary Block

| Component | Contracted By | Status | Coverage | Latest |

**Components:** Waste Streams, Recycling Diversion

**Status** derived from `componentState["waste"]`

---

### 4.2 Contractor Block

**Display:**

- Contractor name (e.g., Recorra)
- Contract type: Direct tenant / Landlord-managed
- Scope: 3
- Confidence: Measured / Allocated

**Upload:** Invoice, Weight report, Diversion certificate

**Auto-tag:**

- `componentType` = waste
- `control` = tenant / landlord
- `scope` = 3

---

### 4.3 Waste Streams Breakdown

**Fixed streams (configurable list):**

- Plastics
- Mixed glass
- Food tins & drink cans
- Mixed paper & card
- Household waste

**Table:**

| Stream | kg | Method | Emissions | Evidence |

**Method enum:** measured, allocated, estimated, cost_only

**If cost-only:** Display: "Weight breakdown not available — estimation applied."

---

### 4.4 Waste in Service Charge Case

If waste detected inside landlord recharge:

- Waste page displays: "Waste managed by landlord. No weight breakdown available."
- Allow user to request breakdown.

**Do NOT mix waste UI inside Energy page.**

---

## 5. Space Awareness

Each component must display **Applies to:** Tenant spaces / Base building / Both.

**Data source:** Space hierarchy from SoR: Property → Floors → Spaces → Systems

**Example:**

- **Tenant Electricity:** Applies to — Ground (Tenant Controlled), 4th (Tenant Controlled), 5th (Tenant Controlled)
- **Landlord Utilities:** Applies to — Base building systems

---

## 6. Upload Simplicity Rules

**Upload flow:**

1. User selects **component type**.
2. User uploads document.

**System auto-detects:**

- componentType
- billingSource
- control
- scope
- confidence
- applicable spaces (if detected)

**User should not need to select Scope.**

---

## 7. Backend Alignment

This UI maps directly to:

- **utilityComponentProfile** — Source: CoverageEngine; see [Secure_KPI_Coverage_Logic_Spec_v1.md](Secure_KPI_Coverage_Logic_Spec_v1.md) for component states and inference rules.
- **coverageAssessment** — Output of `CoverageEngine.evaluate(propertyId, period)`; KPI coverage status (Complete / Partial / Unknown) and domain assessments.
- **Emissions engine mapping matrix** — [Secure_Emissions_Engine_Mapping_v1.md](Secure_Emissions_Engine_Mapping_v1.md).

**No changes required to:**

- component enum
- scope classification logic
- emissions calculation formulas
- coverage inference rules

---

## 8. Supported Scenarios

| Scenario | Supported |
|----------|-----------|
| Submetered tenant electricity | Yes |
| Service charge bundled utilities | Yes |
| Heating submeter (some tenants) | Yes |
| No heating for some tenants | Yes |
| Waste third-party | Yes |
| Waste via landlord | Yes |
| Whole building lease | Yes |
| Partial floors lease | Yes |
| Base building vs tenant control | Yes |
| Portfolio scale (1000+ assets) | Yes |

---

## 9. Architectural Position

| Layer | Role |
|-------|------|
| **UI** | Subject-first grouping |
| **Backend** | Component-level evaluation |
| **CoverageEngine** | Completeness logic |
| **EmissionsEngine** | Scope mapping & calculation |

These layers must remain distinct.

---

*End of Specification*

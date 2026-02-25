# Secure Emissions Engine — Mapping Matrix v1

Formal **Activity → Scope** mapping and calculation rules. Defines how every activity dataset is classified, calculated, and versioned.

---

## 1. Engine Philosophy

The Emissions Engine:

- **Never stores emissions as primary data**
- **Always derives** emissions from activity inputs
- **Assigns Scope** via deterministic classification rules
- **Applies emission factors** by methodology + version
- **Tracks confidence** (Measured / Allocated / Estimated)

---

## 2. Layering Overview

```
Activity Dataset
      ↓
Scope Classification Logic
      ↓
Emission Factor Application
      ↓
Emissions (Calculated)
```

---

## 3. Activity → Scope Mapping Table

### A. Energy & Utilities

| Activity Type | Billing Source | Control | Scope | Logic Rule | Confidence Default |
|---------------|----------------|---------|-------|------------|--------------------|
| Electricity (kWh) | Tenant Direct | Tenant | Scope 2 | Purchased electricity consumed | Measured |
| Electricity (kWh proxy) | Landlord Recharge | Landlord | Scope 2 | Allocated purchased electricity | Allocated |
| Gas (kWh) | Tenant Direct | Tenant | Scope 1 | Direct combustion | Measured |
| Gas (kWh proxy) | Landlord Recharge | Landlord | Scope 1 | Allocated direct combustion | Allocated |
| District Heat (kWh) | Any | Any | Scope 2 | Purchased heat | Measured / Allocated |
| Water (m³) | Any | Any | Scope 3 | Water supply & treatment | Measured / Allocated |

### B. Waste & Recycling

| Activity Type | Unit | Scope | Logic Rule | Confidence |
|---------------|------|-------|------------|------------|
| Household Waste | kg | Scope 3 | Waste disposal | Measured |
| Mixed Paper & Card | kg | Scope 3 | Waste recycling | Measured |
| Plastics | kg | Scope 3 | Waste recycling | Measured |
| Glass | kg | Scope 3 | Waste recycling | Measured |
| Metal (tins/cans) | kg | Scope 3 | Waste recycling | Measured |
| Hazardous Waste | kg | Scope 3 | Special disposal factor | Measured |

### C. Indirect Activities

| Activity Type | Unit | Scope | Logic Rule | Confidence |
|---------------|------|-------|------------|------------|
| Employee Commuting | km or modelled | Scope 3 | Category 7 | Estimated |
| Business Travel (Flights) | km | Scope 3 | Category 6 | Measured / Estimated |
| Business Travel (Rail) | km | Scope 3 | Category 6 | Measured / Estimated |
| Taxi / Ride Share | km | Scope 3 | Category 6 | Estimated |
| Purchased Goods (Spend-based) | £ | Scope 3 | Category 1 | Estimated |
| Capital Goods | £ or volume | Scope 3 | Category 2 | Estimated |
| Fuel & Energy Related | kWh | Scope 3 | Category 3 | Derived from electricity |
| Upstream Transport | km | Scope 3 | Category 4 | Estimated |

---

## 4. Emission Factor Resolution Table

The engine must select emission factors based on:

| Input Type | Factor Source | Example |
|------------|---------------|---------|
| Electricity | Location-based grid factor | UK DEFRA 2023 |
| Electricity | Market-based factor | Supplier-specific |
| Gas | DEFRA combustion factor | kgCO₂e/kWh |
| Waste landfill | DEFRA waste factor | kgCO₂e/kg |
| Waste recycling | DEFRA recycling factor | kgCO₂e/kg |
| Commuting | DEFRA transport factor | kgCO₂e/km |
| Spend-based goods | EEIO factor set | kgCO₂e/£ |

---

## 5. Calculation Formula

For every activity record:

```
Emissions (tCO₂e) = Activity Quantity × Emission Factor ÷ 1000 (if kg to tonnes)
```

**Example:**

- Electricity: 7,500 kWh  
- Factor: 0.182 kgCO₂e/kWh  
- → 7,500 × 0.182 = 1,365 kgCO₂e  
- → **1.365 tCO₂e**

---

## 6. Scope Aggregation Logic

- **Scope 1 Total** = Sum(all Scope 1 activity emissions)
- **Scope 2 Total** = Sum(all Scope 2 activity emissions)
- **Scope 3 Total** = Sum(all Scope 3 activity emissions)

---

## 7. Confidence Scoring Logic

Each emission result **inherits** activity confidence:

| Activity Confidence | Emission Confidence |
|---------------------|---------------------|
| Measured | High |
| Allocated | Medium |
| Estimated | Low |

Scope totals should display: **% High / % Medium / % Low**

**Example:** Scope 2 — 70% measured, 30% allocated

---

## 8. Corporate Occupier Example — 140 Aldersgate

**Activity inputs:**

- Tenant Electricity (Measured)
- Landlord Utilities (Allocated)
- Waste (Measured)
- Commuting (Estimated)

**Engine output:**

- **Scope 1** = 0 (no direct gas confirmed)
- **Scope 2** = Tenant Electricity + Landlord Utilities
- **Scope 3** = Waste + Commuting

No duplication. No manual scope entry.

---

## 9. Factor Versioning Requirement

Engine must store:

- `calculationVersion`
- `emissionFactorDataset`
- `factorYear`
- `calculatedAt`

**If factor version changes:**

- Recalculate all emissions
- Log recalculation event

---

## 10. Future Scalability

This matrix supports:

- Multi-property portfolios
- Landlord accounts
- Corporate occupiers
- Multi-country factor sets
- Hybrid market/location Scope 2 reporting

---

## Result

After implementing this matrix:

- ✔ Scope becomes **deterministic**
- ✔ No manual emission duplication
- ✔ Full audit trail possible
- ✔ AI agents can reason from inputs
- ✔ Reporting becomes **reproducible**
- ✔ Secure becomes **technically defensible**

---

## Implementation

- **UI (Emissions Calculated page):** [Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md](Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md) — layout and matrix alignment in §10.
- **Database (engine persistence):** [Secure_Emissions_Engine_Schema_Draft_v1.md](Secure_Emissions_Engine_Schema_Draft_v1.md) — calculation runs, factor sets, line items.

---

*End of Mapping Matrix v1*

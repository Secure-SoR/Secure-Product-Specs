# Secure — Data Library Taxonomy v3  
## Activity → Emissions → Reporting Architecture

**Date:** Feb 2026  
**Context:** Corporate Occupier (Apex – 140 Aldersgate)  
**Save as / reference:** Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md

---

## 1. Architectural Principle

**Scope is a classification outcome.**  
**Scope is NOT a primary data category.**

Data Library must separate:

1. **Activity Layer** (physical inputs)
2. **Emissions Layer** (derived outputs)
3. **Governance & Strategy**
4. **Compliance & Disclosure**

---

## 2. Layer 1 — Activity Layer (Primary System of Record)

These datasets represent **operational inputs**.

They are:

- Evidence-backed
- Editable
- Property-scoped
- Time-bound
- Versioned

---

### 2.1 Energy & Utilities

**Purpose:** Utility consumption structured by billing source.

**Includes:**

- Tenant electricity (kWh)
- Landlord utilities (allocated)
- Gas (if present)
- Water (if separate later)

**Metadata required:**

- Billing source (Tenant / Landlord)
- Control (Tenant / Landlord)
- Confidence (Measured / Allocated / Estimated)
- Time period
- Units

**Feeds:** → Emissions Engine (Scope 1 or 2)

---

### 2.2 Waste & Recycling

**Purpose:** Waste streams and diversion data.

**Includes:**

- kg by stream
- Contractor
- Collection frequency
- Evidence attachment

**Feeds:** → Emissions Engine (Scope 3)

---

### 2.3 Indirect Activities (NEW)

**Purpose:** Non-utility operational activities generating emissions.

**Examples:**

- Employee commuting
- Business travel
- Purchased goods
- Capital goods
- Water supply & treatment
- Fuel & energy related activities

**Fields:**

- Activity type
- Property or org scope
- Time period
- Units
- Methodology reference
- Confidence level
- Evidence attachment

**Feeds:** → Emissions Engine (Scope 3)

---

## 3. Layer 2 — Emissions (Derived Layer)

**Rename:**  
"Scope 1 / 2 / 3 Data" → **"Emissions (Calculated)"**

This page:

- Is **read-only**
- Displays calculated outputs
- Shows scope breakdown
- Shows emission factor source
- Shows methodology version
- Shows calculation timestamp
- Shows measured vs allocated ratio

**No manual editing allowed.**

Emissions must be generated from:

- Energy & Utilities
- Waste & Recycling
- Indirect Activities

**UI implementation:** [Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md](Secure_Emissions_Calculated_Page_Engineering_Handoff_v1.md) — React component hierarchy, data contracts (EmissionsPageVM, line items), state logic, traceability drawer, read-only rules.

**Engine logic:** [Secure_Emissions_Engine_Mapping_v1.md](Secure_Emissions_Engine_Mapping_v1.md) — Activity → Scope mapping matrix, factor resolution, calculation formula, scope aggregation, confidence scoring.

---

## 4. Layer 3 — Governance & Strategy

---

### 4.1 Governance & Accountability

Structured dataset. Internal operating model.

**Includes:**

- Oversight
- Policies
- Risk management
- Responsible persons
- Accountability mapping

**Used by:** Sustainability reports, AI Governance Agent

---

### 4.2 Targets & Commitments

Structured target dataset.

**Includes:**

- Baseline (value + year)
- Target (value + year)
- Scope
- Status

**Feeds:** Reporting layer, AI Action Agent

---

## 5. Layer 4 — Compliance & Disclosure

---

### 5.1 ESG Disclosures (Renamed)

External report archive.

**Includes:**

- GRESB submission
- CDP response
- TCFD report
- Published sustainability reports
- Supplier code of conduct

**Document storage only.** Not structured governance logic.

---

### 5.2 Certificates

Property-level certifications.

**Examples:** EPC, BREEAM, LEED, ISO

Evidence-backed.

---

## 6. Reporting Ownership Rules

**Reports must:**

- Pull consumption from Activity Layer
- Pull emissions from Emissions Engine
- Pull governance from Governance dataset
- Pull targets from Targets dataset
- Reference disclosures only as attachments

**Reports must not:**

- Store emissions values internally
- Store governance text internally
- Duplicate datasets

---

## 7. Access Control Mapping (Corrected)

| Tile | Access ID |
|------|-----------|
| Energy & Utilities | `energy_utilities` |
| Waste & Recycling | `waste` |
| Indirect Activities | `indirect_activities` (NEW) |
| Emissions (Calculated) | `scope_123` (read-only) |
| Governance & Accountability | `governance` |
| Targets & Commitments | `targets` |
| ESG Disclosures | `esg` |
| Certificates | `certificates` |

**Ensure targets page does not use `esg_governance` ID.**

---

## 8. Migration Notes

**Short term:**

- Keep Scope 1/2/3 page but mark as read-only.
- Add Indirect Activities tile.
- Remove manual editing for emissions.

**Long term:**

- Deprecate manual scope input dataset entirely.
- Introduce emission factor version control table.

---

## 9. Corporate Occupier Example (140 Aldersgate)

**Activity Layer:**

- Tenant electricity (Measured)
- Landlord utilities (Allocated)
- Waste (Measured)
- Commuting (Estimated)

**Emissions Layer:**

- Scope 2 = electricity + landlord allocation
- Scope 3 = waste + commuting

**Reporting Layer:**

- Sustainability report displays totals.

---

*End of Specification*

# Secure Platform — Utility Refactor & AI Workspace Update (v4)

**Date:** 18 Feb 2026
**Owner:** Anne
**Context:** 140 Aldersgate — Corporate Occupier (Apex)

---

# 0. Canonical References

This update extends:

* Secure Canonical Architecture v5
* Data Library Specifications
* Corporate Occupier Use Case (Lakshmi)
* Account Settings Specifications
* Reports Module Specifications
* Sustainability & Energy Report Specs
* Governance & Targets Architecture v3
* AI Agents Canonical Specification Pack
* AI Agent Workspace Specification

---

# 1. Utilities Architecture Refactor (Billing Source Model)

## 1.1 Design Principle

Utilities must be classified by:

* **Billing Source**
* **Control**
* **Confidence**

NOT by commodity (energy / water / heat).

This reflects Corporate Occupier lease reality.

---

## 1.2 Final Tile Structure (140 Aldersgate)

### 1️⃣ Tenant Electricity (Direct – Measured)

* Billing Source: Tenant Direct
* Control: Tenant controlled
* Confidence: Measured
* Scope Badge: Scope 2 (Location-based)
* Floors: Ground, 4th, 5th
* Source: Trio submeters

---

### 2️⃣ Landlord Utilities (Allocated)

* Billing Source: Landlord Recharge
* Control: Landlord controlled
* Confidence: Allocated
* Includes:

  * HVAC (MAPP recharge)
  * Water (provisional allocation)
  * Base-building electrical (common services)

---

### 3️⃣ Waste & Recycling (Third-Party)

* Billing Source: Third-Party
* Control: Shared / Tenant contract
* Confidence: Measured
* Contractor: Recorra

---

### 4️⃣ Data Gaps

* Heat network confirmation
* Water allocation methodology
* Service charge disaggregation detail

---

## 1.3 Removed

* Separate “Water (Landlord)” tile
* Mixed Tenant + Landlord grouping
* Standalone “Heat” category without physical meter

---

# 2. Tenant Electricity Page (EnergyDataPage.tsx)

**Route:** `/data-library/energy`

### Default Filter

```
selectedBillingSource = "Tenant Direct"
```

---

### Header

Tenant-controlled electricity measured via Trio submeters
(Ground, 4th, 5th floors)

---

### Required Badges

* Tenant Controlled
* Measured
* Scope 2 (Location-based)

---

### Includes

* Electricity — Ground floor
* Electricity — 4th floor
* Electricity — 5th floor
* Trio supplier invoices

---

### Meter Summary

* Floors: Ground, 4th, 5th
* Meter Type: Submeter (Tenant Demise)

---

### Table Filter Rule

Include only:

```
billingSource = "Tenant Direct"
OR
supplier contains "Trio"
```

Exclude landlord recharge invoices.

---

# 3. Landlord Utilities Routing Fix (P0)

## Problem

Both Tenant Electricity and Landlord Utilities tiles route to:

```
/data-library/energy
```

Page defaults to Tenant Direct view.

---

## Required Fix

### Option A (Preferred)

Route with query param:

```
/data-library/energy?source=landlord
```

On load:

```
if source === "landlord" → set selectedBillingSource = "Landlord Recharge"
```

---

### Option B

Create dedicated route:

```
/data-library/landlord-utilities
```

---

### Acceptance Criteria

Clicking Landlord Utilities tile opens Landlord Recharge view by default.

---

# 4. Waste Page Alignment

**Route:** `/data-library/waste`

---

## Required Updates

1. Change H1 to:
   `Waste & Recycling (Third-Party)`

2. Add contractor attribution:
   `Contractor: Recorra`

3. Update demo period to:
   2025–2026

4. Add KPI summary block:

   * Records
   * Coverage
   * Latest update

5. Maintain `DataLibrarySubPage` architecture.

---

# 5. Reporting Integration Rules (Mandatory)

Reports must consume structured SoR datasets only.

| Report Section          | Source                                     |
| ----------------------- | ------------------------------------------ |
| Organisational Boundary | `account.reportingBoundary`                |
| Governance              | Data Library → Governance & Accountability |
| Targets                 | Data Library → Targets & Commitments       |
| Electricity             | Tenant Direct records                      |
| Landlord Allocation     | Landlord Utilities records                 |
| Waste                   | Third-Party records                        |

No hardcoded governance or targets allowed.

---

# 6. AI Agent Workspace Alignment

**Route:** `/ai-agents`

Workspace reflects 140 Aldersgate only.

---

## Canonical Agents (MVP)

1. Data Readiness & Evidence Agent
2. Landlord–Tenant Boundary Agent
3. Action Prioritisation Agent
4. Reporting Copilot Agent

---

## Agent Output Contract (Mandatory)

Each agent modal must include:

1. Executive Summary
2. Decision / Recommendation
3. Evidence Links (Data Library references)
4. Confidence
5. Data Gaps
6. Next Actions (Owner + Due Date)

---

# 7. Service Charge Handling Rule (140 Aldersgate)

If landlord does NOT provide physical breakdown:

Create ONE record:

```
Landlord Utilities (Allocated)
Includes: HVAC + Water
Confidence: Allocated
```

Do NOT:

* Create separate physical water record
* Create standalone heat category
* Duplicate financial allocations

If breakdown later provided → split into measured records.

---

# 8. Data Ownership Model (Post-Refactor)

## Account Layer

* Reporting Boundary & Methodology
* Workforce Master Data

## Data Library (SoR)

* Tenant Electricity (Measured)
* Landlord Utilities (Allocated)
* Waste (Measured)
* Governance & Accountability
* Targets & Commitments
* Certificates

## Reporting Layer

* Pure consumption layer
* No embedded datasets
* No static governance

---

# 9. End-to-End Verification Checklist

✔ Tenant Electricity shows only Trio invoices
✔ Landlord Utilities tile opens correctly
✔ Waste page title matches tile
✔ Recorra attribution visible
✔ 2025 reporting year consistent
✔ AI Agents reference correct data sources
✔ No double-counting of water or HVAC
✔ Reports consume structured datasets only

---

# 10. Architectural Outcome

✔ Billing-source-based utility model enforced
✔ Corporate occupier lease boundary respected
✔ Audit defensibility improved
✔ Data duplication risk removed
✔ AI Agents aligned with SoR principles
✔ Reporting layer fully de-coupled from static content

---

**Version:** v4
**Applies to:** 140 Aldersgate Corporate Occupier Account
**Next Review:** After landlord routing fix deployed



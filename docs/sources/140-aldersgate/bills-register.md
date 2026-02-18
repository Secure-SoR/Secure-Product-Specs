# 140 Aldersgate — Bills Register & SoR Mapping

This document maps real-world billing inputs and FM confirmations to Secure’s System of Record (SoR) structure.

Raw invoices are not stored in this repository.
Only structured metadata and mapping logic are documented.

---

## 1. Tenant Electricity (Direct – Measured)

| Field | Value |
|-------|-------|
| Billing Source | Tenant Direct |
| Supplier | Trio |
| Floors Covered | Ground, 4th, 5th |
| Meter Type | Submeter (Tenant Demise) |
| Confidence | Measured |
| Allocation Method | Measured |
| Linked System Category | Power |
| Linked Spaces | Tenant spaces only |
| Data Library Category | Energy & Utilities |
| Report Scope | Scope 2 (Location-Based) |

Notes:
- Direct supplier invoice.
- Not part of service charge.

---

## 2. Landlord Utilities (Allocated — Service Charge)

| Field | Value |
|-------|-------|
| Billing Source | Landlord Recharge |
| Provider | Landlord / MAPP |
| Utilities Included | HVAC + Water + Base Building Electricity |
| Confidence | Allocated |
| Allocation Method | Service Charge Allocation |
| Metering Status | No dedicated tenant meter |
| Linked System Category | HVAC, Water |
| Data Library Category | Energy & Utilities |

Notes:
- No physical breakdown provided.
- Treated as consolidated allocated record.
- Allocation logic must be documented in allocationNotes.

---

## 3. Waste & Recycling (Third-Party)

| Field | Value |
|-------|-------|
| Billing Source | Third-Party |
| Contractor | Recorra |
| Confidence | Measured |
| Allocation Method | Measured |
| Linked System Category | Waste |
| Data Library Category | Waste |

Notes:
- Independent contractor invoice.
- Not included in landlord service charge.

---

## 4. Facility Management Confirmations

FM confirmations support:

- Metering coverage statements
- Allocation logic explanations
- Confirmation of utilities included in service charge

These confirmations must be:

- Stored as structured Data Library records
- Linked to relevant systems
- Referenced in boundary explanations
- Used by AI Boundary Agent

---

## 5. SoR Integrity Rules

- Bills generate structured Data Library records.
- Reports consume structured records only.
- Evidence attachments are linked at record level.
- No duplication between Tenant Direct and Landlord Recharge.
- Allocation-based records must never be labelled as measured.


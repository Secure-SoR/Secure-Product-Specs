# Landlord–Tenant Boundary Logic Specification

This document defines how Secure determines and enforces sustainability responsibility boundaries between tenant and landlord.

This logic applies to Corporate Occupier accounts.

---

## 1. Core Boundary Principle

Responsibility is determined by:

1. Control
2. Metering availability
3. Billing source
4. Allocation method

No dataset may be attributed without passing this boundary logic.

---

## 2. Control Hierarchy

Each system must define:

- controlledBy: tenant | landlord | shared
- maintainedBy: entity name

Control determines operational responsibility.
Maintenance does not imply reporting responsibility.

Example:
HVAC controlledBy = landlord  
→ Default reporting responsibility = landlord  
Unless tenant is contractually responsible.

---

## 3. Metering Rule

If a tenant has:

- Dedicated physical meter  
→ Consumption is Tenant Direct (Measured)

If no dedicated meter exists:
→ Evaluate billing source and allocation logic.

---

## 4. Billing Source Logic

### Tenant Direct
- Supplier invoice in tenant name
- Direct contractual relationship
- Treated as measured (if metered)

### Landlord Recharge
- Service charge or recharge
- No direct supplier contract
- Treated as allocated unless breakdown provided

### Third-Party
- Independent contractor
- Responsibility determined by contract

---

## 5. Allocation Decision Tree

IF controlledBy = tenant  
AND meteringStatus = full  
→ Classification = Tenant Measured

IF controlledBy = landlord  
AND billingSource = landlord recharge  
AND no breakdown provided  
→ Classification = Landlord Allocated

IF allocationMethod = area OR estimated  
→ Confidence cannot be Measured

---

## 6. Reporting Implications

For Corporate Occupier:

- Tenant Direct → Included in Scope 2 (measured)
- Landlord Recharge → Included as allocated consumption
- Base Building Common Services → Disclosed as allocated

Reports must clearly distinguish measured vs allocated.

---

## 7. AI Boundary Agent Responsibilities

Boundary Agent must:

- Evaluate system control
- Evaluate meteringStatus
- Evaluate billingSource
- Flag unclear attribution
- Flag absence of breakdown
- Recommend metering where risk exists

Agent output must include:

- Boundary clarity status: Clear | Partial | Unclear
- Attribution explanation
- Confidence rating

---

## 8. Boundary Clarity States

| State | Definition |
|-------|------------|
| Clear | Dedicated meter and control aligned |
| Partial | Allocation present but documented |
| Unclear | No meter and no allocation explanation |

Unclear state must trigger AI recommendation.

---

## 9. Architectural Rule

No report may:

- Attribute landlord utilities as measured if allocation-based
- Hide allocation logic
- Omit boundary explanation for shared systems

Boundary transparency is mandatory.

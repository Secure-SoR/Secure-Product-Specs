# Data Confidence & Risk Matrix

This document defines how Secure evaluates data reliability, reporting defensibility, and AI decision confidence.

It applies to all Data Library records and system allocations.

---

## 1. Confidence Levels (Canonical)

Every Data Library utility record must have one of the following:

| Confidence | Definition | Example |
|------------|------------|----------|
| Measured | Direct meter reading or supplier invoice tied to tenant consumption | Trio submeter electricity |
| Allocated | Derived from service charge or landlord recharge without physical breakdown | HVAC via MAPP recharge |
| Estimated | Assumed or inferred based on floor area or proxy | % split across shared spaces |

---

## 2. Risk Classification

Each record may be assigned a risk profile based on confidence.

| Confidence | Reporting Risk | Audit Risk | AI Confidence |
|------------|----------------|------------|---------------|
| Measured | Low | Low | High |
| Allocated | Medium | Medium | Moderate |
| Estimated | High | High | Low |

---

## 3. Reporting Rules

### Measured
- May be presented as definitive consumption.
- No additional allocation disclosure required.

### Allocated
- Must include allocationNotes.
- Must be disclosed in reporting limitations section.

### Estimated
- Must be explicitly labelled as estimated.
- Must appear in data gap summary.
- Should trigger AI recommendation for metering improvement.

---

## 4. AI Agent Behaviour Rules

Agents must:

- Surface confidence level for all recommendations.
- Flag allocated datasets as potential boundary risk.
- Flag estimated datasets as improvement opportunity.
- Recommend metering where risk is High.

Example:

If HVAC allocationMethod = area  
→ AI Boundary Agent must state:  
"HVAC consumption allocated by area; no physical meter present."

---

## 5. Boundary Impact Logic

If a system:

- is landlord controlled
- has no tenant meter
- and allocationMethod ≠ measured

Then:

- Confidence cannot be High
- Boundary clarity must be labelled Partial
- Reporting Copilot must include explanatory disclosure

---

## 6. Disclosure Requirements (Corporate Occupier)

Reports must include:

- % of measured vs allocated consumption
- Explanation of service charge inclusions
- Confirmation of metering coverage

If estimated data > 20% of total footprint:
- AI must recommend data improvement plan

---

## 7. Architectural Principle

Confidence is a first-class attribute.

Reports display data.
AI evaluates data quality.
Architecture enforces defensibility.

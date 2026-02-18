# Data Library — Billing Source Model & Evidence Handling

This document defines how utilities, bills, and facility management confirmations are handled within the Data Library module.

---

## 1. Billing Source Classification (Canonical Rule)

Utilities are classified by **billing source**, not commodity type.

### Billing Source Types

- **Tenant Direct**
- **Landlord Recharge**
- **Third-Party**

This prevents artificial separation of utilities that are financially bundled under service charge.

---

## 2. Confidence Model

Each Data Library utility record must include:

- **confidence:** measured | allocated | estimated
- **allocationMethod:** measured | area | estimated
- **allocationNotes:** explanation of allocation logic (if applicable)

Examples:

- Tenant electricity via submeter → measured
- Service charge water allocation → allocated
- Estimated floor split → estimated

---

## 3. Bills as Source Records

Bills are stored as structured Data Library records.

Required fields:

- reportingPeriodStart
- reportingPeriodEnd
- supplier
- billingSource
- control
- confidence
- sourceType (upload | connector | manual)
- evidenceAttachments[]

Reports must consume these structured records only.

Reports must never store bill files directly.

---

## 4. Facility Management (FM) Confirmations

FM confirmations are treated as structured evidence inputs.

They must:

- Be stored as Data Library records (category: Governance / Allocation Support)
- Link to relevant systems
- Link to relevant utility records
- Justify meteringStatus or allocationMethod

FM confirmations are used to support:

- Reporting boundary statements
- Data confidence declarations
- AI agent boundary analysis

---

## 5. Landlord Recharge Handling Rule

If landlord provides no physical breakdown:

Create a single consolidated record:

- billingSource: Landlord Recharge
- confidence: allocated
- allocationNotes: "Service charge includes HVAC and water; no physical breakdown provided."

Do not create synthetic measured categories.

If a breakdown is later provided → split into measured records.

---

## 6. Consumption Rules

### Reports
- Consume structured records only.
- Display evidence links.
- Never store raw files.

### AI Agents
- Must reference Data Library records.
- Must reflect confidence levels.
- Must surface data gaps when allocation logic exists.


# Secure — Canonical Architecture v5

Owner: Anne
System Type: Real Estate Sustainability System of Record (SoR)
Version: 5.0
Status: Authoritative Architecture Baseline

---

# 1. Product Definition

Secure is a **real estate sustainability System of Record (SoR)** designed for Corporate Occupiers and Asset Stakeholders.

Secure provides:

* Structured sustainability data control
* Evidence-backed reporting
* Landlord–tenant boundary clarity
* AI-driven decision support
* Audit-ready traceability

Secure is **not**:

* A generic ESG dashboard
* A marketing reporting tool
* A pure IoT platform

Secure is the **control layer between building data and sustainability decisions**.

---

# 2. Architectural Principles

1. **Single Source of Truth (SoR)** — All sustainability data must exist in structured datasets.
2. **Separation of Concerns** — Data layer, reporting layer, and AI layer must remain distinct.
3. **No Hardcoded Report Data** — Reports consume structured datasets only.
4. **Evidence Centralisation** — Evidence belongs to Data Library records, never reports.
5. **Audit Traceability** — All data mutations are logged append-only.
6. **Explicit Boundary Model** — Reporting boundary stored at account level, not embedded in reports.

---

# 3. Context Model

## GLOBAL Scope

* Users
* Accounts
* Memberships
* Properties

Never auto-cleared.

## USER Scope

* Session state
* Preferences
* Default property/dashboard

Cleared on sign-out.

## ACCOUNT Scope

* Account metadata
* Reporting boundary
* Workforce master data
* Teams
* Teamspaces
* Module entitlements

Cleared on switchAccount.

## PROPERTY Scope

* Spaces
* Systems
* Data Library records
* Evidence attachments
* Dataset audit trails

Never auto-cleared automatically.

---

# 4. Core Domain Model

---

## 4.1 Account

```ts
Account {
  id
  name
  accountType: "corporate_occupier" | "asset_manager"
  enabledModules[]
  reportingBoundary
}
```

---

## 4.2 Reporting Boundary (Account-Scoped)

Stored at:

```
account.reportingBoundary
```

```ts
{
  reportingYear: number
  reportingPeriodStart: string
  reportingPeriodEnd: string
  boundaryApproach: "operational" | "financial" | "equity-share"
  includedPropertyIds: string[]
  entitiesIncluded: string
  exclusions: string
  methodologyFramework: "ghg-protocol" | "uk-secr" | "issb" | "tcfd"
  updatedAt: string
}
```

Reports reflect this read-only.

---

## 4.3 Property

```ts
Property {
  id
  name
  address
  country
  floors[]
  totalArea
}
```

---

## 4.4 Spaces Model

```ts
Space {
  id
  name
  spaceClass: "base_building" | "tenant"
  control: "landlord_controlled" | "tenant_controlled" | "shared"
  spaceType
  area
  floorReference
  inScope: boolean
  netZeroIncluded: boolean
  gresbReporting: boolean
}
```

---

## 4.5 Systems Taxonomy

Categories:

* HVAC
* Lighting
* Plug Loads
* Lifts
* Water
* Waste
* Power
* BMS

```ts
System {
  id
  category
  controlledBy: "tenant" | "landlord" | "shared"
  maintainedBy: string
  servesSpaces: string[]
  meteringStatus: "none" | "partial" | "full"
  allocationMethod: "measured" | "area" | "estimated"
}
```

---

# 5. Data Library — Canonical SoR Layer

## Purpose

The Data Library is the structured evidence-backed data repository.

Reports and dashboards consume it.
They do not own data.

---

## 5.1 Data Subjects

* Scope 1 / 2 / 3 Data
* Energy & Utilities
* Water
* Waste
* Certificates & Accreditations
* Policies & Governance
* Governance & Accountability
* Targets & Commitments
* Occupant Feedback
* Report Data Requirements

---

## 5.2 Record Structure

```ts
DataLibraryRecord {
  id
  subjectCategory
  propertyId (nullable for account-level)
  dataType
  value
  unit
  reportingPeriod
  sourceType: "connector" | "upload" | "manual"
  confidence: "measured" | "allocated" | "estimated"
  evidenceAttachments[]
  auditTrail[]
  createdAt
  updatedAt
}
```

---

# 6. Governance Dataset

Location:

```
Data Library → Policies & Governance
```

```ts
GovernanceRecord {
  id
  category: "oversight" | "policy" | "commitment" | "engagement" | "risk"
  title
  description
  status: "in-place" | "in-progress" | "planned"
  responsiblePerson
  propertyId (nullable)
  evidenceReference
}
```

Feeds:

* Sustainability Report → Governance tab

No hardcoded governance allowed.

---

# 7. Targets & Commitments Dataset

Location:

```
Data Library → Policies & Governance
```

```ts
TargetRecord {
  id
  category: "carbon" | "energy" | "waste" | "water"
  scopeType: "scope1" | "scope2" | "scope3" | null
  baselineYear
  baselineValue
  targetYear
  targetValue
  unit
  linkedMetricType
  status: "on-track" | "at-risk" | "behind"
  propertyId (nullable)
}
```

Feeds:

* Executive Summary progress bars
* Targets tab
* AI Agent prioritisation

---

# 8. Evidence Architecture

Evidence stored only at:

```
DataLibraryRecord.evidenceAttachments[]
```

Reports:

* Display referenced evidence
* Cannot upload new evidence
* Cannot store standalone attachments

---

# 9. Audit Architecture

## 9.1 Dataset Audit (Primary)

Append-only:

```ts
auditTrail[] = {
  action: "create" | "update" | "delete" | "evidence_added"
  actor
  timestamp
}
```

---

## 9.2 Report Workflow Audit (Secondary)

Tracks:

* Draft
* Requested
* In Review
* Approved
* Rejected
* Exported

If underlying data changes while report is Approved:

* Warning banner
* Option to revert to Draft
* Audit entry logged

No dataset snapshotting in v1.

---

# 10. Reporting Layer

Reports consume:

* Data Library structured records
* Governance dataset
* Targets dataset
* Reporting boundary metadata

Reports must:

* Never contain static sustainability claims
* Never store core data
* Always link evidence

---

## 10.1 Sustainability & Energy Report

Voluntary occupier-focused report.

Audience:

* Board
* Investors
* Clients

---

## 10.2 UK SECR

Status:

* Preview only until regulatory validation completed

Exports disabled until compliance sign-off.

---

# 11. AI Agents Layer

Agents are decision engines.

They must not replicate dashboards.

---

## Standard Output Contract

Every agent must return:

1. Executive Summary (3–5 bullets)
2. Decision / Recommendation
3. Evidence Links (Data Library references)
4. Confidence Level
5. Data Gaps
6. Next Actions (owner + due date)

---

## MVP Agent Set

* Data Readiness & Evidence Agent
* Landlord–Tenant Boundary Agent
* Action Prioritisation Agent
* Reporting Copilot Agent
* Audit Preparation Agent (optional)

---

# 12. Navigation Governance

Top Right Avatar (USER Scope):

* Profile
* Switch Account
* Sign Out

Sidebar (ACCOUNT / PROPERTY Scope):

* Dashboards
* Data Library
* Reports
* AI Agents
* Properties
* Account Settings (Admin only)

No duplication.

---

# 13. Backend & Infrastructure Baseline

Backend:

* Fastify (Node.js)
* MongoDB / Postgres
* OCR + Azure OpenAI
* n8n (workflow orchestration)

Frontend:

* Vue / React
* eCharts

DevOps:

* GitHub
* CI/CD automated (Staging + Production)

Secrets:

* Stored via `.env`
* Never committed

---

# 14. Strategic Positioning

Secure is:

> A Sustainability Data Control & Decision Platform for Corporate Occupiers

It ensures:

* Boundary clarity
* Evidence integrity
* Structured governance
* Audit readiness
* Actionable AI recommendations

---

# 15. Non-Negotiable Architecture Rules

* No hardcoded report governance
* No hardcoded targets
* No report-level evidence storage
* No boundary metadata inside reports
* All claims must trace to Data Library
* Agents must link evidence
* All data mutations must log audit entries

---

# End of Canonical v5

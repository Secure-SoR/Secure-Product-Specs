# Modules — application layer on top of the foundation

Per the [platform strategy](../sources/Secure_platform-strategy-building-data-infrastructure.md), Secure is **building data infrastructure** first: Property Graph, Stakeholder Registry, Evidence Store, Activity Data (Data Library), Boundary Engine, Coverage Engine, Emissions Engine, Audit Trail. **Modules** are applications built on top of that foundation — they consume primitives via the platform and must follow the five module rules (consume don’t duplicate, write back, respect boundary, audit trail, strengthen a primitive).

This folder holds **module-level** documentation. The canonical module list with implementation status is in [MODULE-LIST.md](MODULE-LIST.md). Detailed feature specs live in [../specs/](../specs/).

---

## Consumption logic

**All modules feed from the foundation/infrastructure** (Data Library, Property section, Account settings / user profile, Evidence Store, Boundary Engine). **Modules can also consume other modules** when relevant (e.g. Reports may consume AI Agents output; Diagnosis may consume Coverage or Data Library). So: foundation → modules; and module → module where the product design requires it.

---

## Platform modules (full list)

The platform’s modules, aligned with the strategy and with current build status:

| Module | Strategy alignment | Status | Spec / doc |
|--------|--------------------|--------|------------|
| **Reports** | Sustainability Reporting (SECR, ESG, GRESB) | **Partial** — ESG Report only (hub, corporate, SECR, advisor) | [../specs/esg-report-specifications.md](../specs/esg-report-specifications.md); [reports.md](reports.md) |
| **Projects** | ROI / Retrofit Scenarios (cap-ex, retrofit, interventions) | **Pending** | — |
| **Net Zero** | Decarbonisation pathway, targets (extends Reporting / Activity Data) | **Pending** | — |
| **Stakeholders Management** | Stakeholder Data Exchange (landlord ↔ tenant ↔ FM, role-gated) | **Pending** | — |
| **Asset Tracking** | Asset Tracking (systems register, asset lifecycle) | **Pending** | Property Graph; building-systems taxonomy |
| **Digital Twin** | Building digital twin (model, real-time linkage) | **Pending** | — |
| **Automation** | Workflows, triggers, scheduled actions (cross-cutting) | **Pending** | — |
| **AI Agents** | Data Readiness, Boundary, Action Prioritisation, Reporting Copilot | **Built** | [../for-agent/](../for-agent/) |
| **Diagnosis** | Risk Diagnosis (six-domain risk: regulatory, boundary, data confidence, physical, transition, operational) | **Pending** | — |
| **Risk & Finance** | Risk + finance (risk diagnosis + financial impact) | **Pending** | — |
| **Valuation Impact** | Asset Valuation Impact (sustainability risk discount, valuation) | **Pending** | Strategy: third-party / valuation firms |

**Summary:** **Built:** AI Agents. **Partial:** Reports (ESG Report only). **Pending:** Reports (full), Projects, Net Zero, Stakeholders Management, Asset Tracking, Digital Twin, Automation, Diagnosis, Risk & Finance, Valuation Impact.

---

## Foundation (what modules are built on)

The **foundation** is: **Data Library**, **Property section**, **Account settings / user profile**, **Evidence Store**, and **Boundary Engine**. These are not modules — they are the core platform surface that modules consume.

- **Data Library** — Activity Data + Evidence (records, proofs, upload). Spec: [../specs/data-library-specifications.md](../specs/data-library-specifications.md). Consumed by Reports, Dashboards, AI Agents, etc.
- **Property section** — Properties, spaces, systems, meters (Property Graph in the app). Consumed by all modules that need building data.
- **Account settings / user profile** — Account and user management, roles, access. Part of Stakeholder Registry in the strategy.
- **Evidence Store** — Documents with provenance, confidence, audit (Storage, `documents`, `evidence_attachments`). Consumed by Reports, Data Library, AI Agents, etc.
- **Boundary Engine** — Attribution logic: control, billing, metering → who owns what data. Logic in architecture; agent `/api/boundary`. Consumed by modules that need landlord/tenant scope (Reports, Diagnosis, etc.).

**Modules** (e.g. **Dashboards**, Reports, AI Agents) are built on top of this foundation. Dashboards (Office, Data Centre) consume Data Library + Property; DC: [../specs/secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md), [../specs/dc-dashboard-specifications.md](../specs/dc-dashboard-specifications.md).

---

## Module vs feature (to be clarified)

The distinction between **module** (product area that consumes foundation and possibly other modules) and **feature** (capability within a module or within the foundation) is to be clarified. Two cases to resolve:

- **Stakeholders Management** — Module (Stakeholder Data Exchange: invite landlord, data requests, role-gated access) vs feature (account/roles living in Account settings as part of the foundation). Where does “stakeholder management” stop being foundation and start being a module?
- **Dashboards** — Module (e.g. Office dashboards, Data Centre dashboards as a product area) vs feature (e.g. “dashboard view” or KPI tiles reused inside Reports or another module). Is the whole Dashboards area one module, or are dashboards a feature that multiple modules use?

Once clarified, update this section and [MODULE-LIST.md](MODULE-LIST.md) accordingly.

---

## Platform vs module

- **Architecture** ([../architecture/](../architecture/)) describes the platform layer: primitives, boundary, coverage, risk.
- **Modules** (this folder + [MODULE-LIST.md](MODULE-LIST.md)) describe what sits on top and which modules are built, partial, or pending.

When adding a new module, add it to [MODULE-LIST.md](MODULE-LIST.md), document it here, and add a spec in `../specs/` following the spec template. Ensure the module aligns with the strategy’s five rules.

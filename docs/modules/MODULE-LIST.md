# Module list — canonical status and strategy alignment

Single source of truth for platform modules, implementation status, and strategy mapping. See [README.md](README.md) for context and [../sources/Secure_platform-strategy-building-data-infrastructure.md](../sources/Secure_platform-strategy-building-data-infrastructure.md) for the strategy.

**Foundation** (what modules feed from): Data Library, Property section, Account settings / user profile, **Evidence Store**, **Boundary Engine**.

---

## Implementation status

| # | Module | Strategy name / alias | Status | Primitives consumed | Primitives strengthened | Spec / doc |
|---|--------|----------------------|--------|---------------------|--------------------------|------------|
| 1 | Reports | Sustainability Reporting | **Partial** (ESG Report only) | Emissions Engine, Activity Data, Evidence Store, Boundary, Audit | Emissions Engine, Audit Trail | [../specs/esg-report-specifications.md](../specs/esg-report-specifications.md) |
| 2 | Projects | ROI / Retrofit Scenarios | **Pending** | Property Graph, Activity Data, Emissions Engine | Property Graph | — |
| 3 | Net Zero | (Decarbonisation pathway) | **Pending** | Activity Data, Emissions Engine, Evidence | Emissions Engine | — |
| 4 | Stakeholders Management | Stakeholder Data Exchange | **Pending** | Stakeholder Registry, Boundary Engine | Stakeholder Registry, Evidence Store | — |
| 5 | Asset Tracking | Asset Tracking | **Pending** | Property Graph | Property Graph | building-systems taxonomy |
| 6 | Digital Twin | (Digital twin) | **Pending** | Property Graph, Activity Data, IoT | Property Graph | — |
| 7 | Automation | (Workflows / triggers) | **Pending** | All (cross-cutting) | Audit Trail | — |
| 8 | AI Agents | AI Agents | **Built** | All (read) | Coverage Engine | [../for-agent/](../for-agent/) |
| 9 | Diagnosis | Risk Diagnosis | **Pending** | All primitives | Property Graph | — |
| 10 | Risk & Finance | Risk Diagnosis + finance | **Pending** | All, risk/finance data | Property Graph, risk primitive | — |
| 11 | Valuation Impact | Asset Valuation Impact | **Pending** | Risk Diagnosis, Compliance, Property Graph | — | Strategy: third-party |

**Legend:** **Built** = implemented and live. **Partial** = part of the module is implemented. **Pending** = not yet implemented.

---

## Pending implementation (for roadmap and audit)

The following modules are **pending** and should be reflected in roadmap, backlog, and audit to-dos where appropriate:

- Reports (full: GRESB, full corporate reporting, additional frameworks)
- Projects
- Net Zero
- Stakeholders Management
- Asset Tracking
- Digital Twin
- Automation
- Diagnosis
- Risk & Finance
- Valuation Impact

Reference this file from [../AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](../AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md) §7.4 and §7.5 for strategy alignment and combined to-do.

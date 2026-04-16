# Lovable prompts

All ready-to-paste prompts and fix instructions for the Lovable (frontend) app live here. Paste the content into Lovable to implement or fix UI behaviour. Specs in `docs/specs/` are the source of truth for behaviour; these files are the **instructions** you give Lovable.

**Not in this folder:** [LOVABLE-BACKEND-ALIGNMENT.md](../LOVABLE-BACKEND-ALIGNMENT.md) and [LOVABLE-PUBLIC-PAGE-COPY-SECURETIGRE.md](../LOVABLE-PUBLIC-PAGE-COPY-SECURETIGRE.md) stay in `docs/` — they are alignment/copy reference, not prompts to paste.

---

## By feature / topic

### Data Centre (property, spaces, dashboards)

| File | Purpose |
|------|---------|
| [LOVABLE-PROMPT-DATA-CENTRE-DETAILS-STEP.md](LOVABLE-PROMPT-DATA-CENTRE-DETAILS-STEP.md) | DC metadata step in property creation |
| [LOVABLE-PROMPT-DATA-CENTRE-SPACE-TEMPLATE.md](LOVABLE-PROMPT-DATA-CENTRE-SPACE-TEMPLATE.md) | DC space template |
| [LOVABLE-PROMPT-SPACE-TYPE-DROPDOWN-DC.md](LOVABLE-PROMPT-SPACE-TYPE-DROPDOWN-DC.md) | Space type dropdown for DC |
| [LOVABLE-PROMPT-TENANCY-TYPE-SELECTOR-AND-SPACE-SCOPE.md](LOVABLE-PROMPT-TENANCY-TYPE-SELECTOR-AND-SPACE-SCOPE.md) | Whole/partial selector and space scope |
| [LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md](LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md) | Fix DC spaces save → tiles update, list render |
| [LOVABLE-PROMPT-FIX-SINGLE-WHOLE-PARTIAL-SELECTOR.md](LOVABLE-PROMPT-FIX-SINGLE-WHOLE-PARTIAL-SELECTOR.md) | Single whole/partial selector |
| [LOVABLE-PROMPT-DC-BUILDING-SPACES-TILES-DYNAMIC.md](LOVABLE-PROMPT-DC-BUILDING-SPACES-TILES-DYNAMIC.md) | DC building spaces summary tiles (dynamic) |
| [LOVABLE-PROMPT-DASHBOARDS-FILTER-AND-DC.md](LOVABLE-PROMPT-DASHBOARDS-FILTER-AND-DC.md) | Dashboards filter bar + DC dashboards |
| [LOVABLE-PROMPT-DC-DASHBOARDS-NAV-AND-FULL-SPEC.md](LOVABLE-PROMPT-DC-DASHBOARDS-NAV-AND-FULL-SPEC.md) | DC dashboards navigation + full spec |
| [LOVABLE-PROMPT-DC-DASHBOARDS-UI-PER-SPEC.md](LOVABLE-PROMPT-DC-DASHBOARDS-UI-PER-SPEC.md) | DC dashboards UI per spec |
| [LOVABLE-PROMPT-AGENT-CONTEXT-DATA-CENTRE.md](LOVABLE-PROMPT-AGENT-CONTEXT-DATA-CENTRE.md) | Agent POST body: `dcMetadata` + `propertyAssetType` for `data_centre` properties |
| [LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md](LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md) | SitDeck connector in **Data Library → Connectors** (legacy filename); `sitdeck_risk_config`; token via Vault/Edge Function (Phase 3). **Same file:** [../specs/LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md](../specs/LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md) |
| [LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md](LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md) | SitDeck OSINT embeds (geopolitical, climate, cyber) on DC property overview; lat/lng; visible only when connected + coords. **Same file:** [../specs/LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md](../specs/LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md) |
| [LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md](LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md) | SitDeck physical risk map on DC property/risk view; gated by `sitdeck_risk_config.active_widget_types` (+ connected, lat/lng). **Same file:** [../specs/LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md](../specs/LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md) |
| [LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md](LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md) | Risk Diagnosis UI: `risk_diagnosis` + `physical_risk_flags`; label SitDeck `source`. Phase 4. **Same file:** [../specs/LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md](../specs/LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md) |
| [LOVABLE-PROMPT-PROPERTY-LAT-LNG.md](LOVABLE-PROMPT-PROPERTY-LAT-LNG.md) | Latitude / longitude on Integrations & Evidence or property settings → `properties.latitude` / `longitude` (Phase 3, SitDeck maps). **Same file:** [../specs/LOVABLE-PROMPT-PROPERTY-LAT-LNG.md](../specs/LOVABLE-PROMPT-PROPERTY-LAT-LNG.md) |
| [LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md](LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md) | Live **PUE** KPI tile on main DC property overview from `data_library_records` (Phase 3; not SitDeck DCIM). **Same file:** [../specs/LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md](../specs/LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md) |
| [LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md](LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md) | **Site PUE** manual record type in **Data Library → Energy & Utilities** (`site_pue` → `data_library_records`). **Same file:** [../specs/LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md](../specs/LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md) |

### Spaces (all property types)

| File | Purpose |
|------|---------|
| [LOVABLE-PROMPT-RESTORE-SPACES-UI-TENANT-AND-LANDLORD.md](LOVABLE-PROMPT-RESTORE-SPACES-UI-TENANT-AND-LANDLORD.md) | Tenant vs landlord sections for all properties |

### Physical & Technical / Construction & Envelope

| File | Purpose |
|------|---------|
| [LOVABLE-PROMPT-RESTORE-CONSTRUCTION-ENVELOPE-TILE.md](LOVABLE-PROMPT-RESTORE-CONSTRUCTION-ENVELOPE-TILE.md) | Restore Construction & Envelope sub-tab |
| [LOVABLE-PROMPT-FIX-CRASH-AFTER-CONSTRUCTION-ENVELOPE.md](LOVABLE-PROMPT-FIX-CRASH-AFTER-CONSTRUCTION-ENVELOPE.md) | Fix crash after Construction & Envelope |

### Reports / ESG

| File | Purpose |
|------|---------|
| [LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md](LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md) | Back button → /reports or /esg hub |

### Data Library / Evidence

| File | Purpose |
|------|---------|
| [lovable-evidence-for-all-records-including-energy.md](lovable-evidence-for-all-records-including-energy.md) | Evidence for all records including energy |

### Home / Office / Mock data

| File | Purpose |
|------|---------|
| [LOVABLE-PROMPT-REMOVE-MOCK-DATA-OFFICE-HOME.md](LOVABLE-PROMPT-REMOVE-MOCK-DATA-OFFICE-HOME.md) | Remove mock data from home and office dashboards |

### Public page / Routing

| File | Purpose |
|------|---------|
| [LOVABLE-PROMPT-FIX-PUBLIC-PAGE-ROUTING.md](LOVABLE-PROMPT-FIX-PUBLIC-PAGE-ROUTING.md) | Fix public page routing |

### AI Agents / Data Readiness

| File | Purpose |
|------|---------|
| [lovable-fix-data-readiness-post.md](lovable-fix-data-readiness-post.md) | Fix Data Readiness: send POST with context |
| [lovable-prompts-for-agents.md](lovable-prompts-for-agents.md) | Prompts for agents (context for Lovable) |

### End-use nodes

| File | Purpose |
|------|---------|
| [nodes-implementation.md](nodes-implementation.md) | End-use nodes CRUD and seed/upload |

### Asset Tracking

| File | Purpose |
|------|---------|
| [LOVABLE-PROMPT-ASSET-TRACKING.md](LOVABLE-PROMPT-ASSET-TRACKING.md) | Ordered paste prompts: routes, property tab, admin, devices, live, alerts, analytics, hooks |

---

## Where specs link to prompts

- **Data Centre:** [specs/secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md), [specs/dc-dashboard-specifications.md](../specs/dc-dashboard-specifications.md)
- **ESG Report:** [specs/esg-report-specifications.md](../specs/esg-report-specifications.md) has an inline “Prompt to paste” section for future updates; hub/back button prompt is here.
- **Data Library:** [specs/data-library-specifications.md](../specs/data-library-specifications.md), [data-library-implementation-context.md](../data-library-implementation-context.md)
- **Audit (gaps and next steps):** [AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](../AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md) §5 links each gap to the relevant prompt in this folder.
- **Asset Tracking:** [specs/secure-asset-tracking-spec-v2.0.md](../specs/secure-asset-tracking-spec-v2.0.md) Appendix B; implementation prompts consolidated in [LOVABLE-PROMPT-ASSET-TRACKING.md](LOVABLE-PROMPT-ASSET-TRACKING.md).
- **DC agent context:** [specs/implementation-guide-agent-context-data-centre.md](../specs/implementation-guide-agent-context-data-centre.md); **full SQL + Lovable text in one page:** [specs/data-centre-agent-context-COPY-PASTE.md](../specs/data-centre-agent-context-COPY-PASTE.md); contract [architecture/agent-context-data-centre.md](../architecture/agent-context-data-centre.md).

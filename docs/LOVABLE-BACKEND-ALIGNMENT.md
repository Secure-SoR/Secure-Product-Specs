# Lovable app ↔ Backend specs alignment

**Purpose:** Record mismatches and fixes between the Lovable frontend and backend specs (Secure-SoR-backend/docs). Use this when syncing the two codebases or onboarding the engineering team.

**Context:** This doc lives in **Secure-SoR-backend** (backend repo). All spec and doc work is done in the backend. The Lovable app is in a separate workspace folder (e.g. a 4th root named “lovable” or at a path you add to the workspace). When that folder is in the workspace, alignment checks can reference it directly.

**Last checked:** Sync check run against Lovable repo at `[Apex TIGRE]/1_Secure/Repositories/Lovable` (README.md/src = app src). Inconsistencies listed in §1–§5 below; no changes made in Lovable.

---

## Sync check summary (Lovable vs backend)

| # | Area | Inconsistency | Backend expectation | Lovable current |
|---|------|----------------|---------------------|-----------------|
| 1 | Reports hub & Back button | Reports hub is at `/esg` only; no `/reports` route. Back buttons in ESGReport, SECRReport, ReportingAdvisor go to `/esg`. | Hub at **`/reports`**; Back from ESG/SECR/Advisor → `navigate("/reports")`. | Hub at `/esg`; Back → `navigate("/esg")`. No route for `/reports`. |
| 2 | Data Library access IDs | Governance, Targets, ESG Disclosures should use distinct access IDs per Taxonomy v3. | `governance`, `targets`, `esg` (see data-library-implementation-context). | All three pages use `getCategoryAccessById("esg_governance")`. useDataLibraryAccess has `governance` and `targets` in type/map but pages don’t use them. |
| 3 | subject_category (Office dashboards) | Backend schema and data-library docs use canonical categories (e.g. energy, water, waste). | Lowercase/simple: energy, water, waste, etc. | useOfficeDashboardData uses `.ilike("subject_category", "Energy%")` and `.eq("subject_category", "Energy - Water")` — verify these match stored values in DB. |
| 4 | DC dashboards — back navigation | DC property dashboard should link back to DC landing. | From `/dashboards/data-centre/:propertyId` Back → `/dashboards/data-centre`. | Not verified in this check; confirm in DCLanding/DCPropertyDashboard. |
| 5 | Projects route | Backend module list has Projects as a module; route TBD. | — | Lovable has `/projects` and `/projects/:id` but both **redirect to `/dashboard`** (Navigate to="/dashboard"). So Projects UI exists in nav but routes are stubs. |

No other structural mismatches found. Data Library routes, DC dashboard routes (all 9), auth (`/signin`), and Data Library table/evidence usage align with backend.

---

## 1. ESG Report routes — Back button / hub

| Item | Backend spec | Lovable code | Status |
|------|--------------|--------------|--------|
| Hub route | `/esg` | Router: `/esg` → `<Reports />` | ✅ Aligned |
| Corporate report | `/esg/corporate` | Router: `/esg/corporate` → `<ESGReportPage />` | ✅ Aligned |
| SECR report | `/esg/secr` | Router: `/esg/secr` → `<SECRReportPage />` | ✅ Aligned |
| Reporting Advisor | `/esg/advisor` | Router: `/esg/advisor` → `<ReportingAdvisor />` | ✅ Aligned |
| **Back button** | Should go to **`/reports`** (Reports hub — ESG/SECR are part of Reports) | Was `navigate("/reports")` in code; if hub was at `/esg` only, ensure hub is at `/reports` and Back → `/reports` | Apply via Lovable: use prompt in [lovable-prompts/LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md](lovable-prompts/LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md). Do **not** push local Cursor edits. |

---

## 2. Data Library routes

Data Library routes in Lovable match the backend spec:

- `/data-library`, `/data-library/energy`, `/data-library/water`, `/data-library/waste`, `/data-library/certificates`, `/data-library/esg`, `/data-library/scope-data`, `/data-library/governance`, `/data-library/targets`, `/data-library/indirect-activities`, `/data-library/occupant-feedback`, etc.

No changes required.

---

## 3. Data Library access IDs (verify)

Backend spec ([data-library-specifications.md](specs/data-library-specifications.md) § Access control) and [data-library-implementation-context.md](data-library-implementation-context.md) say:

- **Governance & Accountability** → access ID `governance`
- **Targets & Commitments** → access ID `targets`
- **ESG Disclosures** → access ID `esg`

Lovable currently uses:

- `GovernanceDataPage`: `getCategoryAccessById("esg_governance")`
- `TargetsDataPage`: `getCategoryAccessById("esg_governance")`
- `ESGDataPage`: `getCategoryAccessById("esg_governance")`

**Action:** Confirm whether the app intentionally groups these under `esg_governance` or should use `governance`, `targets`, and `esg` per tile for Taxonomy v3 alignment. If the backend/access model expects separate IDs, update Lovable to pass `governance`, `targets`, and `esg` respectively.

---

## 4. DC dashboards

- DC ESG & Reporting dashboard: Lovable has `href: \`/dashboards/data-centre/${propertyId}/esg\`` in DCPropertyDashboard.tsx — matches backend spec.
- DCLanding.tsx uses `path: "/esg"` for the DC landing link (context: DC dashboard section) — ensure this does not conflict with the main app route `/esg` (it is under the DC dashboard flow, so likely a relative path in that context).

---

## 5. Reporting Copilot / AI Agents

- Spec: Reporting Copilot is invoked from **AI Agents** dashboard (`/ai-agents`), not from the report page; generated report is shown there.
- Lovable: Confirm that `useSustainabilityReportingAgent` or equivalent calls POST `/api/reporting-copilot` and that `dataReadinessOutput` and `boundaryOutput` are passed when available (see [AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md)).

---

## 6. Summary of fix (apply via Lovable, not by pushing from Cursor)

The Lovable repo is **not** edited from Cursor; it is updated only through Lovable.ai. To get the Back button fix into the app:

1. **Do not push** any local changes made to the Lovable folder in Cursor (revert/discard them if present).
2. Paste the prompt from [lovable-prompts/LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md](lovable-prompts/LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md) into Lovable and let Lovable apply the change.
3. Sync your Lovable repo from Lovable.ai as usual.

| File (Lovable) | Change to apply via Lovable |
|----------------|-----------------------------|
| Router | Ensure reports hub is at `/reports` (if only at `/esg`, add `/reports` or redirect). |
| `src/pages/reports/ESGReport.tsx` | Back button: `navigate("/reports")` (keep or set to `/reports`) |
| `src/pages/reports/SECRReport.tsx` | Back button: `navigate("/reports")` (keep or set to `/reports`) |

---

## 7. Reports hub URL

**Canonical:** The Reports section (ESG, SECR, Reporting Advisor) hub should be at **`/reports`** so that the Back button and nav match the "Reports" label. If the app currently uses `/esg` as the hub, add route `/reports` for the hub (or redirect `/esg` → `/reports`) and have Back go to `/reports`. See [lovable-prompts/LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md](lovable-prompts/LOVABLE-PROMPT-ESG-SECR-BACK-TO-ESG-HUB.md).

Otherwise the above back-button fix is sufficient.

---

*Backend repo: Secure-SoR-backend. Lovable: separate workspace folder (add to workspace so it can be referenced for alignment).*

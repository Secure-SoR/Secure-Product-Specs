# Lovable prompt: ESG & SECR report Back button and Reports hub URL

**Do not** push local edits to the Lovable repo; apply any changes via Lovable.ai using the prompts below.

---

## Current state (checked in Lovable repo)

| Where | What the app has |
|-------|------------------|
| **App.tsx (router)** | Hub only at **`/esg`** → `<Reports />`. No `/reports` route. Sub-routes: `/esg/corporate`, `/esg/secr`, `/esg/advisor`. |
| **Sidebar.tsx** | Nav item title **"Reports"**, but **href: `/esg`** — so clicking "Reports" goes to `/esg`. |
| **ESGReport.tsx** | Back button: **`navigate("/esg")`** |
| **SECRReport.tsx** | Back button: **`navigate("/esg")`** |
| **ReportingAdvisor.tsx** | Back and in-text links: **`navigate("/esg")`** |

So today: the Reports hub lives at **`/esg`**, and all Back buttons correctly go to **`/esg`**. Navigation is consistent; the only mismatch is that the section is labeled "Reports" in the UI but the URL is `/esg`.

---

## Design choice: keep `/esg` or use `/reports`?

- **If you keep the app as-is:** No change needed. Back already goes to the hub at `/esg`.
- **If you want the URL to match the "Reports" label:** Use the prompt below so the hub is at **`/reports`** and Back goes to **`/reports`**. That requires adding a `/reports` route (or redirect) and updating the sidebar and Back buttons.

---

## Prompt to paste into Lovable (only if you want hub at `/reports`)

```
The sidebar label for this section is "Reports" and the hub URL is currently "/esg". We want the Reports hub to live at "/reports" so the URL matches the label. Make these changes:

1. Router (App.tsx): Add a route path="/reports" that renders the same Reports hub component (the catalogue that lists ESG Report, SECR, Reporting Advisor). Keep the existing /esg route as a redirect to /reports so old links still work: <Route path="/esg" element={<Navigate to="/reports" replace />} /> and add <Route path="/reports" element={<ProtectedRoute><Reports /></ProtectedRoute>} /> (order matters: put /reports first, then /esg redirect). Sub-routes can stay as /esg/corporate, /esg/secr, /esg/advisor.

2. Sidebar (components/dashboard/Sidebar.tsx): Change the Reports nav item href from "/esg" to "/reports".

3. Back buttons: In src/pages/reports/ESGReport.tsx, src/pages/reports/SECRReport.tsx, and src/pages/reports/ReportingAdvisor.tsx, change any navigate("/esg") to navigate("/reports") for the Back button and any in-page links that go to the Reports hub.
```

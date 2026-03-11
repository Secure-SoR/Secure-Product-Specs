# Lovable prompt: Fix Data Centre dashboards UI to match spec

**Use this when:** The Data Centre dashboards exist but the UI/content does not match the spec (wrong KPIs, missing sections, or wrong layout). Use the per-dashboard spec so Lovable can correct each screen.

**Where the specs live:** [DC-DASHBOARD-SPECS-FOR-LOVABLE.md](DC-DASHBOARD-SPECS-FOR-LOVABLE.md) — aligned with the canonical [specs/dc-dashboard-specifications.md](specs/dc-dashboard-specifications.md). One section per dashboard with route, purpose, KPI/widget tables, and data sources. Paste that doc (or the relevant section) into Lovable **after** the prompt below so the model has the full spec.

---

## How to paste into Lovable

1. **First:** Paste the **“Prompt to paste into Lovable”** block below into Lovable.
2. **Then:** Paste the contents of [DC-DASHBOARD-SPECS-FOR-LOVABLE.md](DC-DASHBOARD-SPECS-FOR-LOVABLE.md) (or the “Spec per dashboard” section for the dashboards you want to fix). That gives Lovable the exact spec for each dashboard.

If you only want to fix one or two dashboards, paste the prompt below and then only the **relevant dashboard block(s)** from the spec doc (e.g. “### 1. Portfolio overview” and “### 2. Single DC property overview”).

---

## Prompt to paste into Lovable

```
The Data Centre dashboards UI does not correctly match the product spec. I am pasting the spec for each dashboard below (or in the next message). Please fix the dashboards so that each route has the exact UI and content described in the spec.

- Do not change routes or add new ones; only align the existing DC dashboard pages with the spec.
- Each dashboard must show all items listed in its spec (KPIs, charts, tables, links, back navigation). Use placeholders where data is not yet in the schema and add a code comment: // MISSING_SCHEMA: <description>.
- Data sources: dc_metadata, data_library_records, properties. For SitDeck dashboards (geopolitical, climate-hazard, cyber-infrastructure): embed SitDeck widget when configured, or show the placeholder message from the spec when not connected.
- From every DC dashboard except the portfolio landing, provide a one-click way back to the Data Centre dashboards landing (/dashboards/data-centre), e.g. breadcrumb or "Back to Data Centre dashboards" link.
- Match the existing dashboard component structure and design language; read-only. No new UI patterns.
```

---

## After applying

- Each of the nine DC dashboards (portfolio + single property + PUE, Capacity, Cooling, ESG + three SitDeck) has the UI and content from the spec.
- Back navigation from any child page to the Data Centre dashboards landing works.
- [DC-DASHBOARD-SPECS-FOR-LOVABLE.md](DC-DASHBOARD-SPECS-FOR-LOVABLE.md) stays the single source of truth for what each dashboard must show; update that doc if the product spec changes.

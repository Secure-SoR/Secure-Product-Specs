# Lovable prompt: Remove mock/hardcoded data — Home page and Office dashboards

**Use this when:** The home page and office-type dashboards still show mock or hardcoded data. You want every tile and chart to use real Supabase data or a proper empty state.

**Backend schema:** [database/schema.md](database/schema.md) — column names in the DATA SOURCES section below match the schema (e.g. `value_numeric`, `reporting_period_start`, `nla`, `asset_type = 'Office'`).

---

## Prompt to paste into Lovable

```
Remove all mock/hardcoded data from the home page and all office-type dashboards. Replace every instance of mock data with real data fetched from Supabase, or with a proper empty state if no real data exists.

SCOPE
Apply to:
- Home page (/)
- All office asset type dashboards (any dashboard rendering for properties where asset_type = 'Office' or the generic/default dashboard view)

Do NOT touch:
- Data centre dashboards (separate build phase)
- Any seed/test data in the database — only remove hardcoded values from the frontend code

WHAT TO FIND AND REMOVE
Search the codebase for:
- Hardcoded arrays of fake properties, buildings, or assets (e.g. const mockProperties = [...])
- Hardcoded KPI numbers (e.g. totalEnergy: 1240, pue: 1.45, occupancy: 87)
- Placeholder chart data (e.g. data={[{ month: 'Jan', value: 400 }, ...]} inline or in a mock file)
- Any import from files named mock*, seed*, placeholder*, fixture*, or fakeData*
- Any ternary or conditional that returns mock data when real data is absent (e.g. data ?? mockData)
- Any TODO or FIXME referencing mock or placeholder data

Replace each with a real Supabase query or a proper empty state (see below).

DATA SOURCES — HOME PAGE (use these exact table/column names)
- Property count: from `properties` WHERE account_id = [current account] AND asset_type = 'Office' (count rows)
- Total NLA (sqm): from `properties` — column is `nla` (text); if your app stores numeric NLA here, sum it (cast to numeric where valid); otherwise use a dedicated NLA field if one exists
- Energy YTD: from `data_library_records` — sum(value_numeric) WHERE subject_category = 'energy' AND account_id = [current account] AND reporting_period_start >= start of current year (schema uses reporting_period_start, not period_start)
- Carbon YTD: from Emissions Engine output or data_library_records WHERE subject_category relates to emissions/carbon
- Coverage score: from CoverageEngine — count Complete / Partial / Unknown across properties (or placeholder if not wired)
- Recent activity: from `audit_events` WHERE account_id = [current account] ORDER BY created_at DESC LIMIT 5

DATA SOURCES — OFFICE DASHBOARDS
- Energy tiles: `data_library_records` (subject_category = 'energy'), use value_numeric for totals
- Carbon tiles: Emissions Engine / data_library_records (subject_category for emissions)
- Occupancy: data_library_records (subject_category = 'occupancy') or derived from `spaces` table
- Coverage: CoverageEngine per property
- Chart time series: data_library_records grouped by reporting_period_start (or reporting_period_end), ordered ascending
- Property list/table: `properties` filtered by asset_type = 'Office' and account_id

Note: Schema has asset_type default 'Office' (capital O). data_library_records has value_numeric (not value) and reporting_period_start / reporting_period_end (not period_start).

LOADING STATES
Every tile and chart that fetches from Supabase must show a skeleton loader while loading. Use existing Secure SoR skeleton component if one exists, otherwise grey animated pulse placeholder at the same size as the content.

EMPTY STATES — REQUIRED
When a query returns no data (empty array or null), do NOT fall back to mock data. Show:
- KPI tiles: display "—" with sub-label "No data yet"
- Charts: empty chart frame with message "No data available for this period" centred
- Tables/lists: "No properties found" or "No records found" with CTA where appropriate (e.g. "Add a property")
- Do not hide tiles or charts — preserve layout

ERROR STATES
If a Supabase query fails, show inline error in the relevant tile/chart: small warning icon + "Unable to load data. Try refreshing." Do not surface raw error messages.

ACCOUNT SCOPING
Every query must be scoped to the current user's account_id. RLS policies enforce this; ensure queries use the Supabase client with the authenticated user so RLS applies. Do not return data from another account.

CLEANUP
After replacing all mock data:
- Delete any mock data files that are no longer imported
- Remove unused mock data utility functions
- Remove feature flags or env checks that toggled mock vs real data (e.g. USE_MOCK_DATA)

ACCEPTANCE CRITERIA
- Home page loads with real data from Supabase for the current account
- All office dashboard tiles show real data or proper empty state — no hardcoded numbers
- No import of mock, seed, fixture, or placeholder data files in home page or office dashboard components
- Skeleton loaders on first load before data resolves
- If account has zero properties, home page shows meaningful empty state
- No console errors from undefined mock data references
```

---

## Schema reference (backend)

| Table / concept | Column / note |
|-----------------|----------------|
| properties | nla (text), asset_type (text, e.g. 'Office', 'data_centre') |
| data_library_records | value_numeric (not value), reporting_period_start, reporting_period_end, subject_category |
| audit_events | account_id, created_at; order by created_at DESC for recent activity |

[database/schema.md](database/schema.md) §3.4 properties, §3.9 data_library_records, §3.14 audit_events.

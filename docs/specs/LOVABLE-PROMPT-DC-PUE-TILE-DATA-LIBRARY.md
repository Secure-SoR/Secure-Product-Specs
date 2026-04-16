# Lovable prompt — Live PUE KPI tile (Data Centre main property page)

**Same content as** [../lovable-prompts/LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md](../lovable-prompts/LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md) — lives here **next to** [implementation-guide-phase-3-dc.md](./implementation-guide-phase-3-dc.md) for reliable `./` links in Cursor. Keep both in sync.

**Use when:** Step 3.7 — PUE tile from `data_library_records` on main DC property overview.  
**Schema:** [schema.md](../database/schema.md) §3.9 · **Spec:** [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) (PUE from Data Library in Phase 3).  
**Optional UX:** [LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md](./LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md) — Site PUE record type in Energy & Utilities.

---

## Prompt (copy everything inside the fence)

```
Data Centre — Live PUE KPI tile on the main property page

## Goal

On the **main Data Centre property overview** (e.g. `/dashboards/data-centre/:propertyId`), add a prominent **PUE** KPI tile. The value must come from **`data_library_records`** for this `property_id` (and current account via RLS). Phase 3: no SitDeck DCIM; manual/file/connector rows only.

## Data model (Supabase)

Table `data_library_records` (see schema): among others `property_id`, `subject_category`, `name`, `data_type`, `value_numeric`, `unit`, `reporting_period_end`, `reporting_period_start`, `updated_at`, `created_at`.

Optional: read `dc_metadata.target_pue` for the same property to show “vs target” or a small delta if you already load `dc_metadata` on this page.

## How to derive “live” PUE (in order of preference)

1. **Explicit PUE record**  
   Query rows where `property_id` = current property and the row clearly represents PUE, e.g. any of:
   - `data_type` case-insensitive contains `pue`, OR
   - `name` case-insensitive contains `PUE`, OR
   - `unit` case-insensitive is `PUE` or contains `PUE`  
   Use `value_numeric` as PUE.  
   **Recency:** pick the single **most recent** row by `reporting_period_end` DESC nulls last, then `updated_at` DESC, then `created_at` DESC.

2. **Computed from facility power and IT load**  
   If no explicit PUE row exists, try to compute **total facility power ÷ IT load** (standard PUE definition):
   - Find the latest **total facility power** (or “site” / “building” total power) record and the latest **IT load** (or “IT” / “UPS output” / “white space” IT power — use sensible name/`data_type` matching your existing Data Library energy records).
   - Both must be same property, positive numeric values, compatible units (prefer both kW or both W; convert if your app already stores a convention — document in code comment if you assume kW).
   - `PUE = total_facility_power / it_load`. If IT load is zero or missing, do not divide — treat as no data.

3. **No data**  
   If neither (1) nor (2) yields a valid number, show **“No PUE data”** or an empty state — or hide the tile if that matches existing KPI patterns on the page.

## UI

- **Tile:** Label e.g. “PUE” or “Live PUE”; show value to **2 decimal places** (or 2–3 consistent with other KPIs). No fake placeholder numbers.
- **Subtitle (optional):** reporting period end or a short “as of” date from the winning record(s).
- **Optional:** if `dc_metadata.target_pue` exists, show “Target 1.xx” or an inline comparison (below or beside) without cluttering the tile.
- **Link (optional):** “View in Data Library” or existing deep link to PUE / energy records for this property, if such a route exists.
- Match **layout, typography, and card style** of other KPI tiles on the same DC overview.

## Implementation notes

- Use the Supabase client with the authenticated user; filter `data_library_records` with `.eq('property_id', propertyId)` (and rely on RLS / account scope as elsewhere).
- Prefer **one or two efficient queries** (e.g. fetch candidate energy rows for the property with `subject_category` = `energy` if you use that, then reduce in code; or narrow with `.or()` filters for PUE / power labels — avoid N+1).
- Handle loading and error states like neighbouring tiles.

## Done when

- On the main DC property page, a PUE tile appears and shows a numeric PUE from `data_library_records` when an explicit PUE row or computable power/IT pair exists.
- When no data, the tile shows a clear empty state or is hidden per your pattern.
- Phase 3 acceptance: value is **not** sourced from SitDeck DCIM.
```

---

## After Lovable implements

- Seed or enter a test `data_library_records` row (PUE `value_numeric`, property scoped) and confirm the tile updates.
- If your app uses fixed `data_type` values for energy lines, tighten the prompt’s matching to those enums in a follow-up paste so computation is reliable.

**Recorded implementation:** `useLivePUE` + Live PUE KPI tile on DC overview (explicit PUE row or facility ÷ IT load; source label, date, optional `dc_metadata.target_pue`). Keep this section accurate if the hook or UI changes.

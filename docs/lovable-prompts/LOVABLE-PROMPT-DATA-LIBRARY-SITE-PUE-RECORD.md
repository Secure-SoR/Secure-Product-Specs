# Lovable prompt — Site PUE record type (Data Library → Energy & Utilities)

**Use when:** You want a **first-class, audit-friendly** way to enter **site PUE** (Power Usage Effectiveness) in **Data Library → Energy & Utilities** (nav label; route may remain `/data-library/energy`). Feeds the **Live PUE** tile via `data_library_records` (`useLivePUE` matches `data_type` / name / unit containing `PUE`).

**Related:** [LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md](LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md) · [implementation-guide-phase-3-dc.md](../specs/implementation-guide-phase-3-dc.md) Step 3.7.

**Duplicate for IDE links:** [../specs/LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md](../specs/LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md) — keep both in sync.

---

## Prompt (copy everything inside the fence)

```
Data Library — Add “Site PUE” as a manual record type under Energy & Utilities

## Context

The DC dashboard **Live PUE** tile reads `data_library_records` for this property. Users should not mislabel PUE as tenant electricity or generic landlord kWh. Add an explicit **Site PUE** line item in the same flow as other energy manual entries (Add Energy Record dialog on the Energy & Utilities page).

## Requirements

1. **New energy data type** `site_pue` with label **“Site PUE (DC)”** or **“Site PUE”** in the Component Type dropdown.
   - Extend `ENERGY_DATA_TYPES` in `useEnergyRecords.ts` (or equivalent single source of truth).
   - Map `site_pue` → `subject_category` via `resolveEnergySubjectCategory`: use **`energy`** (or add `"Energy - DC site metrics"` and include it in `ENERGY_SUBJECT_CATEGORIES` so existing energy queries still return these rows — choose one approach and be consistent).

2. **`AddEnergyRecordDialog` behaviour when `site_pue` is selected:**
   - Default **unit** to **`PUE`** (user can override rarely).
   - **Value** field: numeric, sensible step (e.g. 0.01), placeholder e.g. `1.45`. PUE is a **dimensionless ratio**, not kWh.
   - Short helper text under the value or in a tooltip: e.g. “Total facility power ÷ IT load for the same period; typically ≥ 1.”
   - **Period start / end:** required or strongly encouraged (month or reporting window for this PUE).
   - **Confidence:** keep existing control (measured / allocated / estimated / cost_only — hide **cost_only** for PUE if it is misleading, or map to estimated).
   - **Landlord-specific UI** (total cost emphasis, N/A unit defaults): **do not** use the landlord layout for `site_pue`; treat it like a normal measured KPI (value + PUE unit + period).
   - **Name (optional):** placeholder e.g. `January 2026 — site PUE` — still optional; if empty, persisted `name` may be null (acceptable).

3. **Insert payload** (unchanged table): `data_library_records` with `source_type: "manual"`, `data_type: "site_pue"`, `value_numeric`, `unit`, `property_id` from existing Data Library property selector, `account_id`, `subject_category` from resolver, reporting period fields, confidence.

4. **Evidence:** If the Energy & Utilities page already supports attaching evidence to a record after create, keep the same pattern for Site PUE rows (no new bucket required).

5. **Nav copy:** If the sidebar says **Energy & Utilities**, the new type appears in the **same** “Add record” dialog users already use on that page — no new top-level nav item required.

6. **Query invalidation:** After create, invalidate the same React Query keys as other manual energy rows so lists and **Live PUE** refresh.

## Done when

- User can open Data Library → Energy & Utilities, select the DC property, **Add** → choose **Site PUE**, enter value + period, save.
- Row appears in `data_library_records` with `data_type = 'site_pue'` and `property_id` set.
- Live PUE tile on the DC property overview shows the value (existing `useLivePUE` logic should match `data_type` containing PUE semantics — adjust hook only if your matching is stricter than substring on `site_pue`).
```

---

## After Lovable implements

- Add one test row for a data centre property and confirm **Live PUE** and Energy & Utilities list both update.
- Optional backend doc tweak: mention `site_pue` in [LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md](LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md) under “Recorded implementation”.

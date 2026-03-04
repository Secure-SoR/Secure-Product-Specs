# Lovable prompt: Data Centre Details step in property creation

**Use this when:** You need the property creation flow to show a second step **"Data Centre Details"** when the user selects asset type **Data centre**. All fields are optional; the user can skip.

**Spec:** [docs/specs/secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md) §2.3.

---

## Prompt to paste into Lovable

```
In the property creation flow:

1. Step 1 stays as is: core property form (name, address, asset_type, country, year_built, operational_status, etc.). Ensure "Data centre" is one of the asset type options (value saved as `data_centre`).

2. When the user selects asset type "Data centre" and completes Step 1 (e.g. clicks Next/Continue), show a second step titled "Data Centre Details" with the following fields. All fields are optional; the user must be able to skip this step (e.g. "Skip" or "Continue without details" button).

   **Data Centre Details form fields:**
   - **Tier Level** — Select: Tier I / Tier II / Tier III / Tier IV
   - **Design Capacity (MW)** — Number input
   - **Total White Floor (sqm)** — Number input
   - **Cooling Type** — Multi-select: Air | Liquid | Hybrid | Free Cooling
   - **Power Redundancy** — Select: N / N+1 / 2N / 2N+1
   - **Target PUE** — Number input (e.g. 1.3)
   - **Renewable Energy %** — Slider or number 0–100%
   - **WUE Target** — Number input (L/kWh)
   - **Certifications** — Multi-select or checkboxes: ISO 50001, ISO 14001, LEED, BREEAM, EU CoC
   - **SitDeck Site ID** — Text input (optional, for integration)

3. On submit of Step 2 (or when user clicks Skip), insert a row into the Supabase table `dc_metadata`. Map the form fields to these exact column names:

   **Form field → Supabase column (dc_metadata):**
   - Tier Level → `tier_level` (text, e.g. 'I', 'II', 'III', 'IV')
   - Design Capacity (MW) → `design_capacity_mw` (number)
   - Total White Floor (sqm) → `total_white_floor_sqm` (number)
   - Cooling Type → `cooling_type` (array of text, e.g. ['air_cooled', 'liquid_cooled'] — store selected values in lowercase with underscore)
   - Power Redundancy → `power_supply_redundancy` (text, e.g. 'N', 'N+1', '2N', '2N+1')
   - Target PUE → `target_pue` (number)
   - Renewable Energy % → `renewable_energy_pct` (number 0–100)
   - WUE Target → `water_usage_effectiveness_target` (number)
   - Certifications → `certifications` (array of text, e.g. ['ISO 50001', 'LEED'])
   - SitDeck Site ID → `sitdeck_site_id` (text)

   Also include: `account_id` (current account id), `property_id` (the new property id from Step 1). Do not send `current_it_load_mw` unless you have a form field for it (otherwise omit or null). For any empty or skipped field, omit the key or set value to null.

   **Example insert:**
   ```js
   await supabase.from('dc_metadata').insert({
     account_id: currentAccountId,
     property_id: newPropertyId,
     tier_level: form.tierLevel || null,
     design_capacity_mw: form.designCapacityMw ?? null,
     total_white_floor_sqm: form.totalWhiteFloorSqm ?? null,
     cooling_type: form.coolingType?.length ? form.coolingType : null,
     power_supply_redundancy: form.powerRedundancy || null,
     target_pue: form.targetPue ?? null,
     renewable_energy_pct: form.renewableEnergyPct ?? null,
     water_usage_effectiveness_target: form.wueTarget ?? null,
     certifications: form.certifications?.length ? form.certifications : null,
     sitdeck_site_id: form.sitdeckSiteId || null
   });
   ```
   (Adjust form property names to match your actual state/variable names; the important part is the Supabase column names on the left.)

   Then continue to the next part of the flow (e.g. spaces or dashboard).

4. Do not show the Data Centre Details step when asset type is not "Data centre" — only when asset_type === 'data_centre'.
```

---

## Short prompt (save/skip only)

If the Data Centre Details step and form already exist and you only need the insert behaviour:

```
When the user saves or skips the Data Centre Details step, insert a row into dc_metadata using the Supabase client: account_id (current account), property_id (the new property id from Step 1), and the form values mapped to the column names (tier_level, design_capacity_mw, total_white_floor_sqm, cooling_type, power_supply_redundancy, target_pue, renewable_energy_pct, water_usage_effectiveness_target, certifications, sitdeck_site_id). Use null or omit for empty/skipped fields. Example: supabase.from('dc_metadata').insert({ account_id, property_id, tier_level, design_capacity_mw, ... }).
```

---

## Backend requirements

- Table **dc_metadata** must exist (you have already run [add-dc-metadata.sql](database/migrations/add-dc-metadata.sql)). The mapping above is the single source of truth for form field → Supabase column names.

---

## After implementation

- Creating a property with asset type "Data centre" shows Step 2 "Data Centre Details"; user can fill it or skip.
- A row exists in `dc_metadata` for the new property (with the submitted values or nulls).

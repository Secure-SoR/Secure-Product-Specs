# How to implement Phase 1 — Data Centre schema & template

This guide explains **what each step means** and **how to do it** in plain language. Use it when briefing an engineer or when using Cursor to generate prompts for Lovable/backend.

**Link from main spec:** [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) → Section 8.1 Phase 1

---

## Step 1.1 — Add "Data centre" as an asset type

**What it means:** When a user creates or edits a property, they choose an asset type (e.g. Office, Retail). We need "Data centre" to appear as an option so they can mark a property as a data centre.

**How to do it:**

- **Database:** No change needed. The `properties` table already has a column `asset_type` as free text (no fixed list in the DB), so any value is allowed.
- **App (Lovable):** Find the **property form** (the screen where you add or edit a property). There is a field for **Asset type** (dropdown, select, or list). Add **"Data centre"** as a new option. The value saved to the database should be `data_centre` (lowercase, with underscore) so the rest of the logic can rely on it.
- **If you use Cursor to write prompts for Lovable:**  
  *"In the property create/edit form, add 'Data centre' to the Asset type field options. Store the value as `data_centre` in the database."*

**Done when:** A user can select "Data centre" when creating a property and it saves correctly.

---

## Step 1.2 — Create the dc_metadata table (migration)

**What it means:** Data centres have extra fields (tier, capacity, PUE, etc.) that don’t belong on the main property record. We store them in a separate table `dc_metadata`, one row per data centre property.

**How to do it:**

- **Where:** Backend repo, in the folder where migrations live (e.g. `docs/database/migrations/`).
- **Create a new file:** `add-dc-metadata.sql`.
- **Contents:** Define the table with columns as in the main spec §2.2: id, account_id, property_id (unique), tier_level, design_capacity_mw, current_it_load_mw, total_white_floor_sqm, cooling_type (array), power_supply_redundancy, target_pue, renewable_energy_pct, water_usage_effectiveness_target, certifications (array), sitdeck_site_id, created_at, updated_at. Add RLS policies so only users in the same account can read/insert/update. Add an index on property_id.
- **If you use Cursor:**  
  *"Create a migration file add-dc-metadata.sql that creates the dc_metadata table as described in docs/specs/secure-dc-spec-v2.md Section 2.2, with RLS by account_id."*

**Done when:** The migration runs on Supabase without errors and the table exists with the right columns and RLS.

---

## Step 1.3 — Add latitude and longitude to properties (migration)

**What it means:** Later we will show maps and SitDeck widgets based on the property’s location. For that we need latitude and longitude on each property.

**How to do it:**

- **Where:** Backend repo, same migrations folder.
- **Create a new file:** e.g. `add-properties-lat-lng.sql`.
- **Contents:** Add two columns to `properties`: `latitude` and `longitude` (numeric, nullable). No need to backfill existing rows.
- **If you use Cursor:**  
  *"Create a migration that adds nullable numeric columns latitude and longitude to the properties table."*

**Done when:** The migration runs and the `properties` table has `latitude` and `longitude`.

---

## Step 1.4 — Run migrations and update schema docs

**What it means:** Apply the new migrations to your Supabase database, then update any schema documentation (e.g. schema.md, supabase-schema.sql) so the backend docs match the real database.

**How to do it:**

- Run the migrations (e.g. via Supabase dashboard SQL editor, or CLI: `supabase db push` or running the .sql files in order).
- Open the backend schema doc (e.g. `docs/database/schema.md`) and add:
  - The `dc_metadata` table and its columns.
  - The new `latitude` and `longitude` columns on `properties`.

**Done when:** Database is up to date and docs describe dc_metadata and properties.lat/lng.

---

## Step 1.5 — Show "Data Centre Details" as Step 2 when asset type is Data centre

**What it means:** When the user has chosen "Data centre" as the asset type and completes the first property form, they should see a second step: "Data Centre Details", with fields like Tier, Capacity, PUE, etc. This step can be skipped (all fields optional).

**How to do it:**

- **Where:** Lovable app — property creation flow.
- **Logic:** After Step 1 (basic property info), if `asset_type === 'data_centre'`, show Step 2 "Data Centre Details" with the fields listed in the spec §2.3: Tier Level, Design Capacity (MW), Total White Floor (sqm), Cooling Type, Power Redundancy, Target PUE, Renewable Energy %, WUE Target, Certifications, SitDeck Site ID (optional). Provide a "Skip" or "Continue" so they can leave them blank.
- **If you use Cursor:**  
  *"In the property creation flow, when the user selects asset type 'Data centre', show a second step 'Data Centre Details' with the DC fields from secure-dc-spec-v2.md §2.3. All fields optional; user can skip."*

**Done when:** Creating a data centre property shows the extra DC Details step; user can fill it or skip.

---

## Step 1.6 — Save Data Centre Details into dc_metadata

**What it means:** When the user submits the Data Centre Details form (or skips it), we must create a row in `dc_metadata` linked to the new property (with account_id and property_id). If they skip, we can still insert a row with nulls.

**How to do it:**

- **Where:** Lovable app — same flow as 1.5. On submit of Step 2 (or on "Skip"), call Supabase: insert into `dc_metadata` with account_id (current account), property_id (the property just created in Step 1), and the form values (or nulls if skipped).
- **If you use Cursor:**  
  *"When the user saves or skips the Data Centre Details step, insert a row into dc_metadata with account_id, property_id (the new property id), and the form values. Use the Supabase client."*

**Done when:** After creating a data centre property, a corresponding row exists in dc_metadata.

---

## Step 1.7 — Show "Use Data Centre Template" on the spaces screen for data centres

**What it means:** For a data centre property, the spaces screen should show a button like "Use Data Centre Template" that, when clicked, creates a standard set of spaces (halls, suites, plant rooms, NOC, etc.) so the user doesn’t have to add them one by one.

**How to do it:**

- **Where:** Lovable app — spaces page for a property. The button should only appear when the current property has `asset_type === 'data_centre'`.
- **If you use Cursor:**  
  *"On the spaces screen for a property, when the property's asset_type is 'data_centre', show a button 'Use Data Centre Template'. On click it should call the logic that creates the default DC spaces (Step 1.8)."*

**Done when:** For a data centre property, the spaces view shows the template button.

---

## Step 1.8 — Implement the Data Centre space template (default spaces)

**What it means:** When the user clicks "Use Data Centre Template", the app creates a predefined set of spaces in the database: e.g. Hall A, Hall B, Suite 1, Suite 2, Mechanical Plant Room, Electrical Plant Room, Cooling Plant, Network Operations Centre, with the correct space_class, control, and space_type for each (as in spec §3.2).

**How to do it:**

- **Where:** Lovable app (and possibly a small backend function or direct Supabase inserts). Create spaces under the current property with parent_space_id if you use a hierarchy. Use the types from the spec: data_hall, data_suite, plant_room, cooling_plant, office (for NOC), etc.
- **If you use Cursor:**  
  *"Implement the Data Centre template: when the user clicks 'Use Data Centre Template', create spaces as in secure-dc-spec-v2.md §3.2 (Hall A, Hall B, Suite 1, Suite 2, Mechanical Plant Room, Electrical Plant Room, Cooling Plant, NOC) with the correct space_class, control, and space_type for each."*

**Done when:** Clicking the button creates all the default DC spaces; the user can then edit names and areas.

---

## Step 1.9 — Document new space_type values for data centres

**What it means:** Data centres use space types like data_hall, data_suite, data_pod, plant_room, cooling_plant, etc. These need to be available in the app (e.g. in a dropdown when creating/editing a space) and documented so everyone uses the same values.

**How to do it:**

- **Where:** Backend or shared docs: add the list from spec §3.3 (data_hall, data_suite, data_pod, data_row, plant_room, cooling_plant, ups_room, generator_room, hv_room, lv_room, loading_bay, security_gatehouse, noc, meet_me_room) to your space_type options in the UI and/or to a taxonomy/constants file. If space_type is free text in the DB, no migration — just UI and docs.
- **If you use Cursor:**  
  *"Add the data centre space_type values from secure-dc-spec-v2.md §3.3 to the space type dropdown (or allowed values) and to the building/space taxonomy doc."*

**Done when:** Users can assign these space types to spaces, and they are documented.

---

## Step 1.10 — Update building systems taxonomy with DC system types

**What it means:** The list of building systems (for the systems register) should include data centre–specific types: e.g. HV_Intake, UPS_System, CRAC_Unit, Chiller_Plant, DCIM_Platform, PUE_Meter, etc., as in spec §4.1.

**How to do it:**

- **Where:** Backend docs (e.g. building systems taxonomy doc or a config file that drives system type dropdowns). Add the new types under the categories in §4.1 (Power, HVAC/Cooling, Monitoring, Water). If the app has a dropdown for system type, ensure these options appear when the property is a data centre (or globally if that’s simpler).
- **If you use Cursor:**  
  *"Update the building systems taxonomy with the data centre system types from secure-dc-spec-v2.md §4.1. Ensure they are available in the systems UI for data centre properties."*

**Done when:** The systems taxonomy doc and UI include the DC system types; users can select them when adding systems to a data centre.

---

## Phase 1 complete

You’re done with Phase 1 when:

- A user can create a property and choose "Data centre".
- They see the "Data Centre Details" step and can fill it or skip it; data is saved to dc_metadata.
- On the spaces screen for that property, they see "Use Data Centre Template" and can apply it to get the default DC spaces.
- New space types and system types for data centres are available and documented.

Next: [Phase 2 — DC dashboards](./implementation-guide-phase-2-dc.md).

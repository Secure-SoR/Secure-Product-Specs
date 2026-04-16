# Lovable prompt: Fix Data Centre space template — whole/partial sync and spaces visibility

**Use this when:** (1) No way to save whole vs partial building; (2) template runs regardless of whole/partial; (3) spaces count shows (e.g. "12 spaces") but the actual list of spaces does not render; (4) user cannot delete spaces because they are not visible.

**Backend:** `properties.occupancy_scope` = `whole_building` | `partial_building`. Spaces: `space_class` = `tenant` | `base_building`; `in_scope` = boolean.

**If there are two whole/partial selectors:** Use [LOVABLE-PROMPT-FIX-SINGLE-WHOLE-PARTIAL-SELECTOR.md](LOVABLE-PROMPT-FIX-SINGLE-WHOLE-PARTIAL-SELECTOR.md) to consolidate to one.

---

## Prompt to paste into Lovable

```
Fix the spaces screen for data centre properties so the following work correctly.

---

1. **Add a visible way to save Whole building vs Partial building**

   - At the top of the spaces area, show: "Tenant footprint" with two options: "Whole building" and "Partial building" (radio buttons or a select). Load the current value from the property (property.occupancy_scope: 'whole_building' or 'partial_building').
   - Add a **"Save"** or **"Update"** button next to it. When the user clicks Save, call: supabase.from('properties').update({ occupancy_scope: selectedValue }).eq('id', propertyId). Use the selected value: 'whole_building' or 'partial_building'. After a successful update, refetch the property so the UI shows the saved value.
   - Do not allow the selection to be used until it is saved. The "Use Data Centre Template" (or "Generate spaces" / "Populate with spaces") button must only be enabled when the property already has occupancy_scope set (i.e. after the user has saved Whole or Partial at least once). If occupancy_scope is null or not set, disable the template button and show: "Select Whole building or Partial building above and click Save before generating spaces."

---

2. **Only create 8 Data Centre template spaces; respect whole vs partial for in_scope**

   - The Data Centre template must create exactly 8 spaces: Hall A, Hall B, Suite 1, Suite 2 (space_class: tenant, control: tenant_controlled), and Mechanical Plant Room, Electrical Plant Room, Cooling Plant, Network Operations Centre (space_class: base_building, control: landlord_controlled). Use the space_type values from the spec (data_hall, data_suite, plant_room, cooling_plant, office).
   - When inserting, set in_scope from the property's occupancy_scope: if occupancy_scope is 'whole_building', set in_scope: true for all 8. If occupancy_scope is 'partial_building', set in_scope: true for the 4 tenant spaces and in_scope: false for the 4 base_building spaces. Read the current property.occupancy_scope from state or refetch before inserting.

---

3. **Render every space in the list — do not only show a count**

   - The spaces screen must display each space so the user can see and delete it. Do not only show text like "12 spaces" without rendering the actual list.
   - Use one source of truth: fetch spaces with supabase.from('spaces').select('*').eq('property_id', propertyId). Store the result in state (e.g. spaces or setSpaces). Then:
     - Tenant section: filter spaces where space_class === 'tenant'. Map over this array and render each space as a row or card (show at least name, and a Delete button).
     - Landlord / base building section: filter spaces where space_class === 'base_building'. Map over this array and render each space as a row or card (show at least name, and a Delete button).
   - After the user clicks "Use Data Centre Template" and the insert succeeds, refetch spaces (same query) and update the same state (setSpaces or whatever the list uses). The list must re-render and show all spaces, including the 8 just created. The count (e.g. "8 spaces" or "12 spaces") must match the number of rows/cards actually rendered.

---

4. **Ensure Delete works for each space**

   - Each space row/card must have a Delete (or trash) button. On click: call supabase.from('spaces').delete().eq('id', space.id). After a successful delete, refetch the spaces list for this property and update state so the list re-renders without the deleted space. If the user cannot see the spaces (because only the count is shown), fix step 3 first so every space is rendered; then delete will work because the button is visible on each row.
```

---

## If you already have 12 spaces and can't see or delete them

Run this as a **follow-up** prompt after the one above:

```
On the spaces screen: ensure we render every space from the API. Get spaces with .eq('property_id', propertyId). Split into tenant (space_class === 'tenant') and base_building (space_class === 'base_building'). For each group, map over the array and render a row or card for every space, with the space name and a Delete button that calls supabase.from('spaces').delete().eq('id', space.id) then refetches spaces and updates state. Do not show only a count; the user must see each space and be able to delete it.
```

---

## Backend reference

- **properties.occupancy_scope** — text, `whole_building` | `partial_building`. Set from the spaces subpage.
- **spaces.in_scope** — boolean. Per-space inclusion in tenant footprint; can be driven by whole vs partial at property level when applying the template.
- **spaces.space_class** — `tenant` | `base_building`. Drives which section (tenant vs landlord) the space appears in.

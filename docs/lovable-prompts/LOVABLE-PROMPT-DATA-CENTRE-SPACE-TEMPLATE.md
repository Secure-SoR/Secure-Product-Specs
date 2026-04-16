# Lovable prompt: Data Centre space template (Steps 1.7 + 1.8)

**Use this when:** You need the spaces screen to show a **"Use Data Centre Template"** button for data centre properties and, on click, create the default DC spaces.

**Spec:** [docs/specs/secure-dc-spec-v2.md](specs/secure-dc-spec-v2.md) §3.2.

---

## Prompt to paste into Lovable

```
On the spaces screen for a property:

1. When the current property's asset_type is 'data_centre', show a button labelled "Use Data Centre Template" (or "Apply Data Centre Template"). Do not show this button when asset_type is anything else (e.g. Office, Retail).

2. On click of "Use Data Centre Template", create the following spaces for the current property using the Supabase client (supabase.from('spaces').insert(...)). Use the current property_id for all rows. Each space must have: name, space_class, control, space_type, in_scope (true). Omit parent_space_id (top-level spaces) and set area/floor_reference to null if not needed.

   **Default template spaces to insert:**

   | name                     | space_class   | control              | space_type   |
   |--------------------------|---------------|----------------------|--------------|
   | Hall A                   | tenant        | tenant_controlled    | data_hall    |
   | Hall B                   | tenant        | tenant_controlled    | data_hall    |
   | Suite 1                  | tenant        | tenant_controlled    | data_suite   |
   | Suite 2                  | tenant        | tenant_controlled    | data_suite   |
   | Mechanical Plant Room    | base_building  | landlord_controlled  | plant_room   |
   | Electrical Plant Room    | base_building  | landlord_controlled  | plant_room   |
   | Cooling Plant            | base_building  | landlord_controlled  | cooling_plant|
   | Network Operations Centre| base_building  | landlord_controlled  | office       |

   Example: insert each as { property_id: currentPropertyId, name, space_class, control, space_type, in_scope: true }. You can do one insert with an array of 8 objects: supabase.from('spaces').insert([...]) so all are created in one call. After a successful insert, refresh the spaces list (or refetch) so the user sees the new spaces and can edit names/areas as needed.

3. If the user has already added spaces, either append these template spaces to the existing list or show a short confirmation ("This will add 8 default spaces. Continue?") before inserting. Do not delete existing spaces when applying the template.
```

---

## Backend

- Table **spaces** and RLS are unchanged. Same columns: property_id, name, space_class, control, space_type, in_scope (default true), area, floor_reference, etc. No migration needed for the template.

---

## Done when

- For a data_centre property, the spaces screen shows "Use Data Centre Template".
- Clicking it creates the 8 default spaces with the correct space_class, control, and space_type.
- The user can then edit names and areas.

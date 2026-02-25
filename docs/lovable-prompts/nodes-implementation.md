# Lovable prompts — End-use nodes implementation

Paste the prompts below into Lovable to implement the Nodes UI. Use **Prompt 1** first for the full nodes CRUD; use **Prompt 2** for "Seed from template"; use **Prompt 3** for "Upload nodes" from CSV/Excel.

---

## Prompt 1: End-use nodes (full) — list, create, edit, delete

Copy everything inside the block below into Lovable.

```
Implement End-Use Nodes on the Physical and Technical page (or a dedicated "Nodes" section for the current property).

1. **List nodes:** Fetch nodes for the current property: supabase.from('end_use_nodes').select('*, systems(name)').eq('property_id', propertyId).eq('account_id', currentAccountId). Order by utility_type then node_id. Show a table or list with: Node ID, Category, Utility type, Linked system name, Control override, Allocation weight, Applies to (space names or count). Optionally let the user filter by system (dropdown of systems for this property) or by utility type (electricity, heating, cooling, water, waste, occupancy, access).

2. **Create node:** Add an "Add node" or "Create node" button. Open a form with:
   - **System** (required): dropdown of systems for this property (from supabase.from('systems').select('id, name').eq('property_id', propertyId)). Store as system_id (UUID).
   - **Node ID** (required): text, business key e.g. E_TENANT_PLUG, E_TENANT_LIGHT. Must be unique per property.
   - **Node category** (required): dropdown or text. Values from taxonomy: tenant_plug_load, tenant_lighting, hvac_serving_tenant, base_building_lighting, lifts_and_plant, tenant_zone_conditioning, base_building_conditioning, shared_conditioning, pantry_water, toilets_water, shared_water, office_waste, recycling_streams, people_counting, access_control.
   - **Utility type** (required): dropdown. Values: electricity, heating, cooling, water, waste, occupancy, access.
   - **Applies to spaces** (required, at least one): multi-select of spaces for this property (from supabase.from('spaces').select('id, name').eq('property_id', propertyId)). Store as applies_to_space_ids (array of space UUIDs).
   - **Control override** (optional): dropdown TENANT | LANDLORD | SHARED (store as-is; DB uses uppercase).
   - **Allocation weight** (optional): number 0 to 1 (e.g. 0.45). Used to split system-level consumption when bills are invoices only.
   - **Notes** (optional): text.
   On submit: supabase.from('end_use_nodes').insert({ account_id: currentAccountId, property_id: propertyId, system_id, node_id, node_category, utility_type, applies_to_space_ids, control_override: control_override || null, allocation_weight: allocation_weight ?? null, notes: notes || null }).select().single(). Then refetch the nodes list. Validate: node_id unique for property; at least one space selected; allocation_weight in 0..1 if provided. Show errors (e.g. duplicate node_id) in the UI.

3. **Edit node:** Clicking a node opens an edit form (same fields as create). supabase.from('end_use_nodes').update({ system_id, node_id, node_category, utility_type, applies_to_space_ids, control_override, allocation_weight, notes, updated_at: new Date().toISOString() }).eq('id', nodeId). Refetch list after success.

4. **Delete node:** Delete button with confirm. supabase.from('end_use_nodes').delete().eq('id', nodeId). Refetch list.

5. **Where to put it:** Add a "Nodes" sub-section or tab on the Physical and Technical page (below or alongside Building Systems). Use the current property context (propertyId, currentAccountId) for all queries and inserts. Ensure RLS allows insert/update/delete for end_use_nodes where account_id is in the user's memberships (standard policy: account_id IN (SELECT account_id FROM account_memberships WHERE user_id = auth.uid())).
```

---

## Prompt 2: Add default nodes (optional) — seed from 140A register

Use this after Prompt 1 if you want a "Seed nodes from template" or "Add default nodes" action.

```
Add an "Add default nodes" or "Seed nodes from template" button on the Nodes section. When clicked:

1. Fetch systems for this property (by property_id) and spaces for this property. We need to map system names to system IDs and resolve "tenant demise" / "base building" / "whole building" to actual space IDs (e.g. tenant spaces = spaces where space_class = 'tenant' or control = 'tenant_controlled'; base building = landlord_controlled or space_class = 'base_building'; whole building = all spaces). Or let the user choose which spaces count as "tenant demise", "base building", "whole building" once, then use that mapping.

2. Insert a fixed set of nodes from the 140 Aldersgate register. Use the template [docs/templates/seed-nodes-140-aldersgate.json](../templates/seed-nodes-140-aldersgate.json) (or the table in docs/sources/140-aldersgate/building-systems-register.md Section B). Each row has node_id, node_category, utility_type, linkedSystemName, spacePlaceholder, control_override, allocation_weight, notes. Map linkedSystemName to system id by matching system name for this property. Resolve spacePlaceholder to applies_to_space_ids from step 1. If a system is not found, skip that node or show a warning.

3. After insert, refetch the nodes list. Optionally set auto_generated = true on these rows if the table has that column.
```

---

## Upload nodes (CSV/Excel) — steps and Prompt 3

**Yes, you should also be able to upload nodes.** Same idea as "Upload register" for systems: user picks a CSV or Excel file, you parse it, resolve system names and space placeholders, preview, then insert. Below are the full steps and a Lovable prompt.

### Steps for upload nodes

1. **Button:** On the Nodes section, add an "Upload nodes" or "Import from file" button. On click, open a file input that accepts `.csv` and `.xlsx`.
2. **Parse:** In the browser, parse the file (e.g. Papa Parse for CSV, SheetJS for Excel). First row = headers; rows below = node rows. Result: array of objects keyed by column name.
3. **Column mapping:** Map spreadsheet columns (case-insensitive) to: node_id, node_category, utility_type, linked_system_name (or Linked System Name), space_placeholder (or Space Placeholder / Applies to spaces), control_override, allocation_weight, notes. Template: [docs/templates/nodes-upload-template.csv](../templates/nodes-upload-template.csv).
4. **Resolve system:** For each row, find the system for this property whose `name` matches `linked_system_name` (trim, case-insensitive or exact). If not found, skip that row and record a warning (e.g. "Node E_TENANT_PLUG skipped: system 'Tenant Electricity Submeters (6 total)' not found"). Store system_id (UUID).
5. **Resolve spaces:** For each row, map `space_placeholder` to an array of space UUIDs for this property: SPACE_TENANT_DEMISE → spaces where space_class = 'tenant' (or control = 'tenant_controlled'); SPACE_BASE_BUILDING → spaces where space_class = 'base_building' or landlord_controlled; SPACE_WHOLE_BUILDING → all spaces. If the file has space names or IDs instead of placeholders, resolve similarly. Store applies_to_space_ids (uuid[]). If no spaces found for a placeholder, skip that row and warn.
6. **Normalize:** control_override must be TENANT | LANDLORD | SHARED (uppercase); if empty or invalid, use null. allocation_weight: parse as number; if present must be 0..1; if invalid or empty, use null.
7. **Validate:** Skip or warn for rows with duplicate node_id (for this property), missing node_id/node_category/utility_type, or missing system_id/applies_to_space_ids after resolve. Show count of valid vs skipped.
8. **Preview:** Show a table (e.g. first 20 rows) with Node ID, Category, Utility type, Linked system, Spaces, Control, Weight. Buttons: "Import" and "Cancel".
9. **Insert:** On Import, for each valid row call supabase.from('end_use_nodes').insert({ account_id: currentAccountId, property_id: propertyId, system_id, node_id, node_category, utility_type, applies_to_space_ids, control_override: control_override || null, allocation_weight: allocation_weight ?? null, notes: notes || null }). If a row fails (e.g. duplicate node_id), show which row and the error; continue or stop. Refetch nodes list and show "N nodes added, M skipped."
10. **Optional:** Upload the file to Storage (e.g. account/{accountId}/property/{propertyId}/node-imports/{date}-{filename}) for audit.

### Lovable prompt: Upload nodes (Prompt 3)

```
On the Nodes section (same place as "Seed from template"), add an "Upload nodes" or "Import nodes from file" button. When clicked, the user selects a CSV or Excel file (.csv, .xlsx).

1. Parse the file in the browser (e.g. Papa Parse for CSV, xlsx/sheetjs for Excel). First row = headers. Map columns case-insensitively: node_id, node_category, utility_type, linked_system_name (or "Linked System Name"), space_placeholder (or "Space Placeholder"), control_override, allocation_weight, notes. Template format: docs/templates/nodes-upload-template.csv.

2. For each row: (a) Resolve linked_system_name to system_id by finding the system for this property (supabase.from('systems').select('id, name').eq('property_id', propertyId)) whose name matches (trim, case-insensitive). If no match, skip row and add to warnings. (b) Resolve space_placeholder to applies_to_space_ids: fetch spaces for this property; SPACE_TENANT_DEMISE = spaces where space_class = 'tenant', SPACE_BASE_BUILDING = spaces where space_class = 'base_building', SPACE_WHOLE_BUILDING = all spaces. If placeholder yields no spaces, skip row and warn.

3. Normalize: control_override must be TENANT, LANDLORD, or SHARED (uppercase); else null. allocation_weight: number 0..1 or null. Validate: node_id unique per property; at least one space; skip duplicates.

4. Show preview table (e.g. first 20 rows) with Node ID, Category, Utility type, Linked system, Control, Weight. Show "X rows to import, Y skipped" and any warning messages. Buttons: "Import" and "Cancel".

5. On Import: for each valid row, supabase.from('end_use_nodes').insert({ account_id: currentAccountId, property_id: propertyId, system_id, node_id, node_category, utility_type, applies_to_space_ids, control_override, allocation_weight, notes }). On duplicate node_id error, show which node and continue. Then refetch the nodes list and show "N nodes added" and any skip/error summary.
```

---

## Reference

- **Seed nodes template (JSON):** [docs/templates/seed-nodes-140-aldersgate.json](../templates/seed-nodes-140-aldersgate.json) — use for "Seed from template".
- **Upload nodes template (CSV):** [docs/templates/nodes-upload-template.csv](../templates/nodes-upload-template.csv) — use for "Upload nodes" (CSV/Excel import).
- **Spec:** [docs/data-model/end-use-nodes-spec.md](../data-model/end-use-nodes-spec.md)
- **Node definitions (140A, table):** [docs/sources/140-aldersgate/building-systems-register.md](../sources/140-aldersgate/building-systems-register.md) Section B
- **Taxonomy (categories, utility types):** [docs/data-model/building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) §2

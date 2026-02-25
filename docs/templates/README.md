# Templates for Secure SoR

## building-systems-register-template.csv

Use this as the expected format when implementing **Upload register** on the Physical and Technical page. The first row must be headers; column names are matched case-insensitively and with common variants (see implementation plan).

- **Required for insert:** System Name, systemCategory, Controlled By, Metering Status, Allocation Method.
- **Normalization:** Values are normalized to DB enums (e.g. Tenant → tenant, Submetered → partial). See [implementation-plan-lovable-supabase-agent.md](../implementation-plan-lovable-supabase-agent.md) § Upload building systems register.

## seed-nodes-140-aldersgate.json

Template for **seed default nodes** (e.g. "Add default nodes" on the Nodes section). Contains the 140 Aldersgate node set: node_id, node_category, utility_type, linkedSystemName, spacePlaceholder, control_override, allocation_weight, notes.

- **Resolve at seed time:** Map `linkedSystemName` to `systems.id` by matching system name for the property. Map `spacePlaceholder` to space UUIDs: SPACE_TENANT_DEMISE → tenant spaces, SPACE_BASE_BUILDING → base building spaces, SPACE_WHOLE_BUILDING → all spaces (from `spaces` for the property).
- **Insert into:** `end_use_nodes` with account_id, property_id, system_id (resolved), node_id, node_category, utility_type, applies_to_space_ids (resolved), control_override, allocation_weight, notes.
- **Source:** Same data as [building-systems-register.md §B](../sources/140-aldersgate/building-systems-register.md).

## nodes-upload-template.csv

Use this format when implementing **Upload nodes** (CSV/Excel) on the Nodes section. Headers (case-insensitive): node_id, node_category, utility_type, linked_system_name (or Linked System Name), space_placeholder (or Space Placeholder / applies_to_space_ids), control_override, allocation_weight, notes.

- **Required:** node_id (unique per property), node_category, utility_type, linked_system_name, space_placeholder (or space names/IDs — see upload steps).
- **Resolve:** linked_system_name → systems.id by matching system name for the property. space_placeholder → applies_to_space_ids: SPACE_TENANT_DEMISE = tenant spaces, SPACE_BASE_BUILDING = base building, SPACE_WHOLE_BUILDING = all spaces.
- **Normalize:** control_override = TENANT | LANDLORD | SHARED (uppercase); allocation_weight 0..1 or empty.

# Nodes: Attribution, Inference, and Consumption — Control from Spaces

This document summarises how **end-use nodes** are attributed, how they link to consumption, and how **system control** relates to **spaces**. It is derived from the Building Systems Taxonomy, the 140 Aldersgate register, and the canonical schema.

---

## 1. Node attribution

**Attribution** = which spaces and what share of consumption each end-use node represents.

| Concept | Where it lives | Description |
|--------|----------------|-------------|
| **Applies to which spaces** | `end_use_nodes.applies_to_space_ids` | Array of space UUIDs the node applies to (e.g. tenant demise, base building, whole building). |
| **Share of consumption** | `end_use_nodes.allocation_weight` | Numeric 0..1. For a given scope (e.g. tenant electricity), weights should sum to ~1. Example: tenant_plug_load 0.45, tenant_lighting 0.15, hvac_serving_tenant 0.30, etc. |

**Source:** [building-systems-taxonomy.md §2](building-systems-taxonomy.md) (node model, allocationWeight), [building-systems-register.md §B](../sources/140-aldersgate/building-systems-register.md) (appliesToSpaceIds, allocationWeight, notes).

---

## 2. “Inference” and link to consumption

Nodes are **defined** in the register (or in the platform) rather than algorithmically inferred. The “inference” is the **rule set** that links nodes to systems and to consumption:

1. **Node → system:** Each node is linked to exactly one system via `end_use_nodes.system_id` (or `linkedSystemId` / `linkedSystemName` in the register). That system holds metering and allocation at the **system** level.
2. **Consumption flow:** Meter/data → **system** (`metering_status`, `allocation_method`) → **nodes** (`allocation_weight`, `applies_to_space_ids`) for splitting to end-uses and spaces.
3. **Rationale:** The register’s **notes** column documents the real-world basis (e.g. “Tenant plug loads captured in floor submeters”, “HVAC electricity typically in landlord plant / service charge”, “Toilets are landlord space; tenant cannot retrofit fixtures”). So “inference” is: use system + space applicability + weight + notes to attribute consumption to spaces and control.

There is no separate “inference engine” in the current docs — the link to consumption is **system + node allocation_weight + applies_to_space_ids**, with notes for auditability.

---

## 3. Control: spaces as source; system defaulted with override

**Current state:** Both **spaces** and **systems** carry control:

- **Spaces:** `control` = `tenant_controlled` | `landlord_controlled` | `shared`
- **Systems:** `controlled_by` = `tenant` | `landlord` | `shared`, and `serves_space_ids` links a system to the space(s) it serves

**Recommendation:** Treat **space control as the primary source** and **system control as defaulted from the space(s) the system serves, with optional override**.

- **Link:** Systems are already linked to spaces via `systems.serves_space_ids`. So “the space(s) within which the system is placed” is represented by that array.
- **Defaulting rule:** When creating or editing a system, **default** `controlled_by` from the control of the selected space(s), e.g.:
  - All served spaces same control → use that (e.g. all tenant_controlled → `controlled_by` = tenant).
  - Mixed controls → default to `shared`.
- **Override:** Keep `controlled_by` on the system as an **explicit, overridable** field so edge cases can be recorded (e.g. “Toilets are landlord space; tenant cannot retrofit” even if the same system also serves tenant demise for another end-use).

So: **spaces are linked to systems via `serves_space_ids`; control is inherited by default from those spaces, with system-level override when needed.** No schema change required — only UI/UX: when the user selects “Serves spaces”, pre-fill or suggest `controlled_by` from the chosen spaces’ `control`, and allow override.

---

## 4. Multiple nodes per system — and bills as invoices only

**Multiple nodes per system is normal.** One system (e.g. “Tenant Electricity Submeters” or “IT & Small Power”) can have several nodes: e.g. plug loads, process loads, lighting — each with its own `node_id`, `node_category`, and `allocation_weight`. Each node links to the **same** `system_id`. The weights for nodes under that system should sum to ~1.0 for the utility/scope they share (e.g. tenant electricity end-uses).

**When utility bills are invoices only** (no breakdown by end-use — just total kWh or £ per meter/supply), you **infer** where consumption goes using the nodes:

1. **Bill / meter** gives a total (e.g. “Tenant electricity 1,000 kWh” for a system or meter).
2. **Nodes** linked to that system have `allocation_weight` (e.g. plugs 0.45, lighting 0.15, HVAC 0.30, …).
3. **Split the total** by weight: e.g. 450 kWh to tenant_plug_load, 150 kWh to tenant_lighting, 300 kWh to hvac_serving_tenant. That gives you an **inferred end-use breakdown** for reporting, Scope 2, or the agent.

So: **nodes are exactly what you use to go from “one number on the invoice” to “consumption by end-use”** when the bill doesn’t provide that split. The register’s notes (and allocation_weight) document the basis for the inference.

---

## 5. References

- Node model and enums: [building-systems-taxonomy.md §2](building-systems-taxonomy.md)
- Register example (systems + nodes): [building-systems-register.md](../sources/140-aldersgate/building-systems-register.md)
- Schema: [schema.md](../database/schema.md) (§3.6 systems, §3.8 end_use_nodes)
- Implementation plan (systems, nodes, context): [implementation-plan-lovable-supabase-agent.md](../implementation-plan-lovable-supabase-agent.md)
- End-use nodes spec (v1 + engineer rules): [end-use-nodes-spec.md](end-use-nodes-spec.md)

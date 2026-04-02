# Lovable prompt — Data Centre fields in agent context (paste into Lovable)

**Use when:** Data Readiness, Boundary, Sustainability Reporting, or any other agent is called with a **context JSON** from the Secure app.  
**Backend contract:** [agent-context-data-centre.md](../architecture/agent-context-data-centre.md)  
**Full checklist:** [implementation-guide-agent-context-data-centre.md](../specs/implementation-guide-agent-context-data-centre.md)

---

## Prompt (copy everything inside the fence)

```
Extend the Secure Lovable app so that every POST body sent to AI agents (Data Readiness, Boundary, Sustainability Reporting / Reporting Copilot, and any other agent that receives the same "AgentContext" object) includes Data Centre–specific fields when the selected property is a data centre.

Rules:
1. Read properties.asset_type for the current property. When it equals exactly "data_centre", attach:
   - propertyAssetType: "data_centre" (string, redundant but explicit for agents)
   - dcMetadata: the result of supabase.from('dc_metadata').select('*').eq('property_id', propertyId).maybeSingle() — use .data if present, otherwise null (no row yet is valid)

2. For ALL property types (including data_centre), keep existing context fields unchanged: propertyId, propertyName, reportingYear, spaces, systems, end_use_nodes (or nodes), dataLibraryRecords, evidence, reportingBoundary, etc.

3. Spaces array: each space object MUST include at least: id, name, space_type, space_class, control (and any fields you already send). Do not strip space_type — DC agents need data_hall, plant_room, etc.

4. Systems array: each system MUST include at least: id, name, system_category, system_type (and existing fields). DC properties may use DC system_type values (UPS_System, CRAC_Unit, etc.) per backend docs.

5. If the app inserts agent_runs with context_snapshot, merge propertyAssetType and dcMetadata into that snapshot the same way as the POST body so audit matches what was sent.

6. Non–data-centre properties: set propertyAssetType from properties.asset_type (e.g. "Office") and dcMetadata: null. Do not query dc_metadata unless you want to optimize with a conditional fetch.

7. Find every code path that builds the agent payload (search for agent API URLs, "data-readiness", "boundary", context_snapshot, agent_runs insert). Apply one shared helper e.g. buildAgentContext(property, ...) to avoid drift.

8. After change, test: (a) office property — payload unchanged aside from propertyAssetType if newly added; (b) data_centre property with dc_metadata row — dcMetadata populated; (c) data_centre property without dc_metadata row — dcMetadata null.

Reference: Secure backend docs/architecture/agent-context-data-centre.md for the expected JSON shape.
```

---

## After Lovable implements

- Confirm in browser Network tab: POST body includes `dcMetadata` and `propertyAssetType` for a DC property.
- Optional: update AI agent server prompts to mention PUE/tier when `dcMetadata` is present (separate repo).

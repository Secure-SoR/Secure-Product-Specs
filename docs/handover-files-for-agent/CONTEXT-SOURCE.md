# Context source — where the agent gets its input

The agent **does not read the database**. It receives a **single context JSON** in the request body. That JSON is built by **Lovable** (or your orchestration) by fetching from **Supabase** and mapping to the shape below.

---

## Where context comes from

- **Lovable** (or your service) fetches for the selected property and account:
  - `properties` (one row by id)
  - `spaces` (by property_id)
  - `systems` (by property_id)
  - `end_use_nodes` (by property_id), if present
  - `data_library_records` (by property_id or account)
  - `evidence_attachments` + `documents` for those records (to build the evidence list)
- It builds one **context object** that matches the “Agent context shape” and **POSTs** it to your agent (e.g. `/api/data-readiness` or `/api/boundary`).

So: **context = one JSON payload per request; data originally comes from Supabase.**

---

## Backend repo: path and files to read

**Backend repo (source of truth for context shape and DB):**  
**Secure-SoR-backend**

**Default path (adjust if your clone is elsewhere):**
```
/Users/anamariaspulber/Documents/Secure-SoR-backend
```

If the agent repo sits next to it:
```
../Secure-SoR-backend
```

**Read these files in the backend repo, in this order:**

| Priority | Path (relative to backend repo root) | Purpose |
|----------|--------------------------------------|--------|
| 1 | `docs/for-agent/README.md` | Sync notes: property/spaces/systems/Data Library columns, context source, Phase 5 pointer. |
| 2 | `docs/for-agent/AGENT-TASKS.md` | Concrete to-do: context input (floorsInScope, optional fields), API contract, data library (subject_category, no emissions as records). |
| 3 | `docs/implementation-plan-lovable-supabase-agent.md` | **Phase 5** section: exact “Agent context shape” (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence), ID format, how Lovable builds context. |
| 4 | `docs/database/schema.md` | Table definitions (properties, spaces, systems, data_library_records, documents, evidence_attachments) when you need column-level detail. |
| 5 | `Secure_Canonical_v5.md` (if present in repo root or docs) | Product/domain and reporting boundary; principles. |

**Optional (Data Library / coverage):**  
`docs/data-library-what-to-do-next.md`; `docs/sources/Secure_Data_Library_Taxonomy_v3_Activity_Emissions_Model.md`; `docs/sources/Secure_KPI_Coverage_Logic_Spec_v1.md` if the agent later receives coverage.

---

## Agent context shape (summary)

Your **input schema** must match the backend’s Phase 5 “Agent context shape”. Minimal expectation:

- `propertyId`, `propertyName`, `reportingYear`
- `reportingBoundary` (optional): e.g. `{ boundaryApproach, includedPropertyIds, methodologyFramework }`
- `floorsInScope` (optional): array of floor identifiers the tenant occupies (from `properties.floors_in_scope`)
- `spaces`: array of `{ id, name, spaceClass, control, inScope, area, floorReference, spaceType, parentSpaceId }`; optional `children` when sent as tree
- `systems`: array of `{ id, category, controlledBy, meteringStatus, allocationMethod, servesSpaces }` (backend DB has `system_category` → map to `category`)
- `nodes` (optional): array of `{ id, systemId, type, controlOverride, allocationWeight, spaceIds }`
- `dataLibraryRecords`: array of `{ id, category, reportingYear, propertyId, confidenceLevel }` (and optionally more); use **subject_category** (energy, water, waste, etc.); **emissions are not stored as records**
- `evidence`: array of `{ id, recordId, recordType, recordName, fileName }`

**IDs:** Supabase UUIDs for property/spaces/systems are fine; document whether you expect UUIDs or string ids and keep consistent with what Lovable sends.

For the **exact** shape and field names, always refer to the backend: **Phase 5** of `docs/implementation-plan-lovable-supabase-agent.md` in the Secure-SoR-backend repo.

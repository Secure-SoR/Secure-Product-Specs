# Full implementation guide — Data Centre agent context

This is the **single checklist** for shipping DC-aware agent payloads (Data Readiness, Boundary, Reporting Copilot, etc.): **Supabase migrations**, **docs/taxonomies**, **Lovable prompts**, and **AI Agents** notes.

**All-in-one copy-paste (full SQL + full Lovable prompts in one page):** [data-centre-agent-context-COPY-PASTE.md](./data-centre-agent-context-COPY-PASTE.md)

**SQL file next to the copy-paste doc (easy to open with Cmd+P):** [RUN-IN-SUPABASE-data-centre-prerequisites.sql](./RUN-IN-SUPABASE-data-centre-prerequisites.sql)

**Same script under migrations:** [run-data-centre-agent-context-prerequisites.sql](../database/migrations/run-data-centre-agent-context-prerequisites.sql)

**Contract (field names & JSON shape):** [agent-context-data-centre.md](../architecture/agent-context-data-centre.md)  
**DC product spec:** [secure-dc-spec-v2.md](./secure-dc-spec-v2.md)  
**Phase 2 reference:** [implementation-guide-phase-2-dc.md](./implementation-guide-phase-2-dc.md) Step 2.5

---

## 1. Database migrations (Supabase SQL Editor)

**Fast path:** run the combined script [run-data-centre-agent-context-prerequisites.sql](../database/migrations/run-data-centre-agent-context-prerequisites.sql) once (includes lat/lng, tenancy_type, `dc_metadata`).

**Or** run individual files in order on **staging first**, then production:

| Order | File | Purpose |
|-------|------|---------|
| 1 | [add-dc-metadata.sql](../database/migrations/add-dc-metadata.sql) | **`dc_metadata`** table + RLS. **Required** so Lovable can load `dcMetadata` for agent context. |
| 2 | [add-properties-lat-lng.sql](../database/migrations/add-properties-lat-lng.sql) | **`properties.latitude` / `longitude`**. Recommended for DC (SitDeck maps, risk dashboards per [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) §6). |
| 3 | [add-tenancy-type-property-and-spaces.sql](../database/migrations/add-tenancy-type-property-and-spaces.sql) | **`tenancy_type`** on properties/spaces. Use if your DC spaces UI uses whole/partial tenancy ([implementation-guide-phase-1-dc.md](./implementation-guide-phase-1-dc.md)). |

**No migration** adds agent context columns: context is a **JSON payload** built in the app. `agent_runs.context_snapshot` is existing `jsonb` ([schema.md](../database/schema.md) §3.12).

**Greenfield:** If you use the full [supabase-schema.sql](../database/supabase-schema.sql) on a new project, `dc_metadata` and often lat/lng are already included — run individual migrations only on **existing** DBs that predate those changes.

**Verify after SQL:**

```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'dc_metadata';
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'properties'
  AND column_name IN ('latitude', 'longitude', 'asset_type');
```

---

## 2. Schema & taxonomy docs (reference only — no SQL)

| Doc | Use |
|-----|-----|
| [schema.md](../database/schema.md) §3.4a | `dc_metadata` columns |
| [schema.md](../database/schema.md) §3.5 | `spaces` including `space_type` |
| [schema.md](../database/schema.md) §3.6 | `systems` including `system_category`, `system_type` |
| [space-types-taxonomy.md](../data-model/space-types-taxonomy.md) §2 | DC `space_type` enum values for UI + consistent saves |
| [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) §4 | DC `system_type` values under Power / HVAC / Monitoring / Water |

---

## 3. Lovable — prompt order and paste files

Use **`data_centre`** (underscore) as the stored `properties.asset_type` value everywhere.

### 3.1 Prerequisites (data in Supabase)

Apply **§1 migrations** so `dc_metadata` exists. Ensure property create/edit saves `asset_type = 'data_centre'` where relevant.

### 3.2 Recommended Lovable prompt order (DC foundation)

| Step | Prompt file | Purpose |
|------|-------------|---------|
| A | [LOVABLE-PROMPT-DATA-CENTRE-DETAILS-STEP.md](../lovable-prompts/LOVABLE-PROMPT-DATA-CENTRE-DETAILS-STEP.md) | DC metadata step → `dc_metadata` CRUD |
| B | [LOVABLE-PROMPT-SPACE-TYPE-DROPDOWN-DC.md](../lovable-prompts/LOVABLE-PROMPT-SPACE-TYPE-DROPDOWN-DC.md) | DC space types on space form |
| C | [LOVABLE-PROMPT-DATA-CENTRE-SPACE-TEMPLATE.md](../lovable-prompts/LOVABLE-PROMPT-DATA-CENTRE-SPACE-TEMPLATE.md) | Template seed spaces with correct `space_type` |
| D | [LOVABLE-PROMPT-TENANCY-TYPE-SELECTOR-AND-SPACE-SCOPE.md](../lovable-prompts/LOVABLE-PROMPT-TENANCY-TYPE-SELECTOR-AND-SPACE-SCOPE.md) | Whole/partial if needed |
| E | *(manual / Cursor)* | Systems register: offer DC `system_type` options when `asset_type` is data centre ([building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) §4) |

### 3.3 Agent context (required for Step 2.5)

| Step | Prompt file | Purpose |
|------|-------------|---------|
| F | [LOVABLE-PROMPT-AGENT-CONTEXT-DATA-CENTRE.md](../lovable-prompts/LOVABLE-PROMPT-AGENT-CONTEXT-DATA-CENTRE.md) | **`dcMetadata` + `propertyAssetType`** on every agent POST; align `spaces` / `systems` arrays |

Paste **F** after agent calls exist; re-paste if Lovable regresses context shape.

### 3.4 Agent / HTTP integration (existing docs)

| Doc | Purpose |
|-----|---------|
| [lovable-prompts-for-agents.md](../lovable-prompts/lovable-prompts-for-agents.md) | Endpoints and agent context pattern (this repo) |
| [LOVABLE-BACKEND-ALIGNMENT.md](../LOVABLE-BACKEND-ALIGNMENT.md) | Lovable ↔ backend / agent URL alignment |
| [architecture/architecture.md](../architecture/architecture.md) | Agent endpoint references |

**AI Agents repo (optional):** extended agent code and copies of prompts may also live under your **AI Agents** workspace; align payloads with [agent-context-data-centre.md](../architecture/agent-context-data-centre.md).

---

## 4. AI Agents service (optional but recommended)

| Action | Detail |
|--------|--------|
| Read optional fields | Accept `dcMetadata` and `propertyAssetType` on the same JSON body as today; **ignore** if missing (non-DC properties). |
| Prompts | When `propertyAssetType === 'data_centre'` and `dcMetadata` is non-null, inject tier, design capacity, target PUE, cooling_type into the system or user prompt for Data Readiness / Boundary. |
| Spec | [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) §7 |

No separate migration in the agents repo for this — **contract is JSON-only**.

---

## 5. Done checklist

- [ ] Migrations applied: at minimum **`add-dc-metadata.sql`**.
- [ ] `properties.asset_type` can be **`data_centre`**; DC metadata row optional but loadable.
- [ ] Lovable prompts **A–D** applied as needed for your DC UI scope.
- [ ] Lovable prompt **F** applied: agent requests include **`dcMetadata`** and **`propertyAssetType`** when property is a data centre.
- [ ] `spaces` in context include **`space_type`**; `systems` include **`system_category`** and **`system_type`**.
- [ ] (Optional) AI Agents updated to use `dcMetadata` in prompts.
- [ ] [agent-context-data-centre.md](../architecture/agent-context-data-centre.md) remains the canonical field list.

---

## 6. Related files index

| Item | Link |
|------|------|
| Contract | [agent-context-data-centre.md](../architecture/agent-context-data-centre.md) |
| DC Lovable prompts index | [lovable-prompts/README.md](../lovable-prompts/README.md) → Data Centre |
| DC → Lovable mapping | [data-centre-to-lovable-mapping.md](../data-centre-to-lovable-mapping.md) |
| Phase 1 DC | [implementation-guide-phase-1-dc.md](./implementation-guide-phase-1-dc.md) |

# Data Centre + agent context — SQL and Lovable prompts (copy-paste)

**One page:** everything to paste into **Supabase SQL Editor** and **Lovable**.  
**Contract:** [agent-context-data-centre.md](../architecture/agent-context-data-centre.md)  
**Checklist:** [implementation-guide-agent-context-data-centre.md](./implementation-guide-agent-context-data-centre.md)

---

## Part 1 — SQL (Supabase SQL Editor)

Markdown links to `.sql` files often **do not open** in the editor. Use one of these:

### Open the SQL file in Cursor (easiest)

1. Press **Cmd+P** (Mac) or **Ctrl+P** (Windows / Linux).
2. Type **`RUN-IN-SUPABASE-data-centre`** (or `data-centre-prerequisites`).
3. Open **[RUN-IN-SUPABASE-data-centre-prerequisites.sql](RUN-IN-SUPABASE-data-centre-prerequisites.sql)** — it lives in the **same folder** as this markdown (`docs/specs/`).
4. **Select all** → **Copy** → paste into **Supabase → SQL Editor** → **Run**.

Same script (migrations folder): [run-data-centre-agent-context-prerequisites.sql](../database/migrations/run-data-centre-agent-context-prerequisites.sql)

### Or copy from the block below

Click inside the grey box, select from `CREATE EXTENSION` through the final `USING` line, copy, paste into Supabase → Run:

```sql
-- Data Centre — prerequisites for agent context + DC UI (one paste for Supabase)
-- Run after accounts, properties, spaces, account_memberships exist.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS latitude numeric,
  ADD COLUMN IF NOT EXISTS longitude numeric;

COMMENT ON COLUMN public.properties.latitude IS 'Property latitude for maps and SitDeck widgets';
COMMENT ON COLUMN public.properties.longitude IS 'Property longitude for maps and SitDeck widgets';

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS tenancy_type text CHECK (tenancy_type IN ('whole', 'partial'));

COMMENT ON COLUMN public.properties.tenancy_type IS 'Tenancy type for space population: whole (Whole Building) or partial (Partial Building). Used by DC/spaces page; selector persists here; spaces are scoped by this.';

ALTER TABLE public.spaces
  ADD COLUMN IF NOT EXISTS tenancy_type text CHECK (tenancy_type IN ('whole', 'partial'));

COMMENT ON COLUMN public.spaces.tenancy_type IS 'Tenancy type at creation: whole or partial. Spaces are mutually exclusive by type; queries and writes must scope by property.tenancy_type.';

CREATE INDEX IF NOT EXISTS idx_spaces_property_id_tenancy_type
  ON public.spaces(property_id, tenancy_type);

CREATE TABLE IF NOT EXISTS public.dc_metadata (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  tier_level text,
  design_capacity_mw numeric,
  current_it_load_mw numeric,
  total_white_floor_sqm numeric,
  cooling_type text[],
  power_supply_redundancy text,
  target_pue numeric,
  renewable_energy_pct numeric,
  water_usage_effectiveness_target numeric,
  certifications text[],
  sitdeck_site_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(property_id)
);

CREATE INDEX IF NOT EXISTS idx_dc_metadata_account_id ON public.dc_metadata(account_id);
CREATE INDEX IF NOT EXISTS idx_dc_metadata_property_id ON public.dc_metadata(property_id);

COMMENT ON TABLE public.dc_metadata IS 'Data centre–specific metadata; one row per property with asset_type = data_centre';

ALTER TABLE public.dc_metadata ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can insert dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can update dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can delete dc_metadata in their accounts" ON public.dc_metadata;

CREATE POLICY "Members can read dc_metadata in their accounts"
  ON public.dc_metadata FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert dc_metadata in their accounts"
  ON public.dc_metadata FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update dc_metadata in their accounts"
  ON public.dc_metadata FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete dc_metadata in their accounts"
  ON public.dc_metadata FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
```

---

## Part 2 — Lovable Prompt A: Agent context (`dcMetadata`)

Paste into Lovable:

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

## Part 3 — Lovable Prompt B: Data Centre Details step + `dc_metadata` insert

Paste into Lovable:

```
In the property creation flow:

1. Step 1 stays as is: core property form (name, address, asset_type, country, year_built, operational_status, etc.). Ensure "Data centre" is one of the asset type options (value saved as data_centre).

2. When the user selects asset type "Data centre" and completes Step 1 (e.g. clicks Next/Continue), show a second step titled "Data Centre Details" with the following fields. All fields are optional; the user must be able to skip this step (e.g. "Skip" or "Continue without details" button).

   Data Centre Details form fields:
   - Tier Level — Select: Tier I / Tier II / Tier III / Tier IV
   - Design Capacity (MW) — Number input
   - Total White Floor (sqm) — Number input
   - Cooling Type — Multi-select: Air | Liquid | Hybrid | Free Cooling
   - Power Redundancy — Select: N / N+1 / 2N / 2N+1
   - Target PUE — Number input (e.g. 1.3)
   - Renewable Energy % — Slider or number 0–100%
   - WUE Target — Number input (L/kWh)
   - Certifications — Multi-select or checkboxes: ISO 50001, ISO 14001, LEED, BREEAM, EU CoC
   - SitDeck Site ID — Text input (optional, for integration)

3. On submit of Step 2 (or when user clicks Skip), insert a row into Supabase table dc_metadata. Map form fields to columns:
   - Tier Level → tier_level (text, e.g. I, II, III, IV)
   - Design Capacity (MW) → design_capacity_mw
   - Total White Floor (sqm) → total_white_floor_sqm
   - Cooling Type → cooling_type (text array, values like air_cooled, liquid_cooled in lowercase with underscore)
   - Power Redundancy → power_supply_redundancy (N, N+1, 2N, 2N+1)
   - Target PUE → target_pue
   - Renewable Energy % → renewable_energy_pct
   - WUE Target → water_usage_effectiveness_target
   - Certifications → certifications (text array)
   - SitDeck Site ID → sitdeck_site_id

   Always set account_id (current account) and property_id (new property from Step 1). Use null or omit for empty fields. Use supabase.from('dc_metadata').insert({ ... }).

4. Do not show the Data Centre Details step when asset type is not data_centre.
```

---

## Part 4 — Lovable Prompt C: DC space types in dropdown

Paste into Lovable:

```
The space type dropdown (or allowed values for space_type when creating/editing a space) must include the data centre space types when the current property's asset_type is 'data_centre'.

Add these options when property.asset_type === 'data_centre' (in addition to any existing options like common_area, shared_space, meeting_room, office):

- data_hall — Primary raised-floor data hall / white floor
- data_suite — Sub-division of a hall (caged or open)
- data_pod — Pre-fabricated or modular POD
- data_row — Row within a hall or suite
- plant_room — Mechanical or electrical plant room
- cooling_plant — Cooling tower yard, CRAC/CRAH room
- ups_room — UPS / battery room
- generator_room — Diesel or gas generator room
- hv_room — High voltage switchroom
- lv_room — Low voltage switchroom
- loading_bay — Loading / receiving area
- security_gatehouse — Security post
- noc — Network Operations Centre
- meet_me_room — Cross-connect / colocation meet-me room

Store the value in spaces.space_type exactly as above (e.g. data_hall, plant_room). Show human-readable labels in the UI while saving the snake_case value. When the property is not a data centre, keep the existing space type options.
```

---

## Part 5 — More Lovable prompts (full text — paste each block separately)

Canonical copies also live under `docs/lovable-prompts/` (same wording). **For Data Centre agent context:** after any agent prompt below, still apply **Part 2** of this file so `dcMetadata` and `propertyAssetType` are on the POST body when `asset_type === 'data_centre'`.

---

### Part 5a — DC space template (“Use Data Centre Template”)

```
On the spaces screen for a property:

1. When the current property's asset_type is 'data_centre', show a button labelled "Use Data Centre Template" (or "Apply Data Centre Template"). Do not show this button when asset_type is anything else (e.g. Office, Retail).

2. On click of "Use Data Centre Template", create the following spaces for the current property using the Supabase client (supabase.from('spaces').insert(...)). Use the current property_id for all rows. Each space must have: name, space_class, control, space_type, in_scope (true). Omit parent_space_id (top-level spaces) and set area/floor_reference to null if not needed.

   Default template spaces to insert:

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

### Part 5b — Tenancy type selector (Whole / Partial) + space scope

```
Data Centre property space page: make the tenancy type selector (Whole Building vs Partial Building) functional. Do not change any UI.

1) Persist: On selection, save immediately to properties.tenancy_type ('whole' or 'partial'). On load, read property.tenancy_type and pre-select the option. Migration: docs/database/migrations/add-tenancy-type-property-and-spaces.sql (run in Supabase if needed).

2) Spaces: When creating a space, set spaces.tenancy_type = current property.tenancy_type. All space lists, counts, and summaries on this page must filter by the current tenancy_type (WHERE tenancy_type = current). Spaces under whole must not appear when viewing partial, and vice versa. Switching type only changes the view and new additions; do not delete existing spaces.

3) Enforcement: Before any space save/update/delete, verify the space's tenancy_type matches the current selection; reject or warn if mismatch.

4) If property.tenancy_type is null, block space creation until the user selects Whole or Partial and it is saved. Extend existing space creation logic; do not replace it. Reuse existing Supabase usage; no new routes.
```

---

### Part 5c — DC dashboards: navigation + full route set (spec §5–§6)

```
Data Centre dashboards — fix two issues. Do not change Office or other asset-type dashboards.

**1) Navigation**
- The Data Centre dashboards landing page lists all DC properties (portfolio overview). When the user clicks a property or a dashboard card, they go to a property-level page but have no way to get back.
- Fix: On every Data Centre dashboard page except the landing page, add a clear way back to the Data Centre dashboards landing: either a breadcrumb whose first segment is "Data Centre dashboards" linking to the landing route (e.g. /dashboards/data-centre), or a "Back to Data Centre dashboards" link/button that goes to that route. One click from any DC dashboard (property overview, PUE, Capacity, Cooling, ESG) must return the user to the landing.

**2) Full dashboard set per spec**
- The backend spec (secure-dc-spec-v2.md §5 and §6) requires nine Data Centre dashboard views. Implement any that are missing and align content with the spec.
- Operational (§5): Landing /dashboards/data-centre (portfolio overview: PUE avg/range, IT load, energy YTD, renewable %, etc.; property table). Single property /dashboards/data-centre/:propertyId (six KPI tiles + links to sub-dashboards). Then: /pue (time series, waterfall, Tier benchmark), /capacity (capacity gauge, power chain, hall-level, redundancy), /cooling (cooling breakdown, WUE trend, free cooling, water), /esg (GRESB, EED Article 12, renewable, Scope 2, data quality).
- Risk Intelligence (§6 — SitDeck): /dashboards/data-centre/:propertyId/geopolitical (Geopolitical & Conflict Risk), /climate-hazard (Climate & Natural Hazard Risk), /cyber-infrastructure (Cyber & Critical Infrastructure Risk). Embed SitDeck widgets (iframe or JS SDK per https://sitdeck.com); centre on property latitude/longitude. Group these under a "Risk Intelligence" tab or section. If SitDeck is not connected yet, show a placeholder panel: "Connect SitDeck in Data Library → Connectors to see risk intelligence" and still provide the route and nav.
- Data from dc_metadata, data_library_records, properties for §5. Use placeholder + // MISSING_SCHEMA where a field is not in schema. Match existing dashboard component structure and design; read-only.
```

---

### Part 5d — Agent wiring (1) Property dropdown + build context for Data Readiness / Boundary

```
Requirement: When the user runs the Data Readiness or Boundary agent from the AI agents UI, the app must use only the property that is currently selected in the property dropdown. The agent must receive context for that one property and its associated data — not another property and not all properties.

Implementation:

1. Source of truth for "current property"
   When the user is on the AI agents screen (or any screen where they can run an agent), the property that counts is the one chosen in the property dropdown. Store this in state (e.g. selectedPropertyId).

2. When "Run Data Readiness" or "Run Boundary" is clicked
   - Read the currently selected property ID from the dropdown state.
   - Do not use a hardcoded property id, the first property in the list, or the last-viewed property.
   - Use this and only this id for the next steps.

3. Fetch from Supabase for that property only
   Using the selected property id (e.g. selectedPropertyId):
   - properties: one row where id = selectedPropertyId (include asset_type).
   - spaces: all rows where property_id = selectedPropertyId.
   - systems: all rows where property_id = selectedPropertyId.
   - end_use_nodes: all rows where property_id = selectedPropertyId (if the table exists).
   - data_library_records: rows where property_id = selectedPropertyId.
   - evidence: for those data library records, fetch evidence_attachments and documents and build the evidence list with recordId = data_library_record_id for each item.
   - If asset_type === 'data_centre': also fetch dc_metadata where property_id = selectedPropertyId (maybeSingle) and add dcMetadata and propertyAssetType to the context (see Secure backend docs/architecture/agent-context-data-centre.md).

4. Build the agent context
   Build a single context object that matches the agent's expected shape: include propertyId, propertyName, reportingYear, spaces, systems, nodes, dataLibraryRecords, evidence; map DB column names (e.g. system_category → category, space_class → spaceClass, controlled_by → controlledBy with values "Tenant"/"Landlord"/"Shared", serves_space_ids → servesSpaces).

5. Call the agent
   - Data Readiness: POST to agent base URL + /api/data-readiness with the context JSON.
   - Boundary: POST to agent base URL + /api/boundary with the same context JSON.

Summary: The dropdown selection is the single source of truth. Fetch and build context only for that property, then POST to the agent.
```

---

### Part 5e — Agent wiring (2) Configurable agent API base URL

```
Make the agent API URL configurable

- Add an environment variable VITE_AGENT_API_URL. In development it can default to http://localhost:3333; in production or Lovable cloud preview, set it to the deployed agent base URL (e.g. https://your-agent.onrender.com — no trailing slash).
- In the code that calls the agent (e.g. useDataReadinessAgent or equivalent), use: base URL = import.meta.env.VITE_AGENT_API_URL ?? 'http://localhost:3333'; POST to ${baseUrl}/api/data-readiness, ${baseUrl}/api/boundary, ${baseUrl}/api/action-prioritisation, ${baseUrl}/api/reporting-copilot as appropriate.
- In Lovable: if there is an env/config section, add VITE_AGENT_API_URL = your deployed agent base URL.
```

---

### Part 5f — More agent prompts (full text; mirrors AI Agents doc)

Canonical source: **`AI Agents/agent/docs/LOVABLE-PROMPTS-FOR-AGENTS.md`**. Backend pointer: [lovable-prompts-for-agents.md](../lovable-prompts/lovable-prompts-for-agents.md). For **Data Centre**, still merge **Part 2** of this file (`dcMetadata` / `propertyAssetType`) into the same context you POST.

**Suggested order:** Part 5e → Part 5d → **Part 2** (`dcMetadata`) → **5f-1b** → **5f-4** (if dropdown/results broken) → **5f-2** / **5f-3** → **5f-6** (PDF + evidence on tile 4).

---

#### Part 5f-1b — Evidence for ALL records (including energy / Scope 2)

```
Use when the agent reports "Scope 2 (energy) records exist but no evidence in context" even though energy records have evidence in the DB. The app must send evidence for all data library record types (energy, water, waste, commuting, business travel, indirect_activities), not only waste.

Requirement: When building the context for the Data Readiness (and Boundary) agent, the evidence array must include evidence for all data library records for the selected property — energy (Scope 2), water, waste, commuting, business travel, indirect_activities. Do not filter evidence by subject_category or record type.

Current bug (if present): Evidence is fetched or built only for certain record types (e.g. waste, indirect_activities), so Scope 2 (energy) records have no evidence in the context and the agent shows "Scope 2 records exist but no evidence in context for them".

Fix:

1. After fetching data_library_records for the selected property (property_id = selectedPropertyId), take the full list of record IDs: dataLibraryRecords.map(r => r.id) — all records (energy, water, waste, commuting, business_travel, indirect_activities, etc.).
2. Fetch evidence_attachments where data_library_record_id is in that full list. Do not filter by subject_category or record type. Join documents to get the file name.
3. Build the evidence array: one object per attachment with recordId = data_library_record_id, plus id, recordType, fileName, recordName as needed. Include all of these in the evidence array so the agent receives evidence for energy (Scope 2) as well as waste, commuting, travel, and indirect.
4. Send this full evidence array in the context when calling the agent. The agent uses it to set payload.contextReceived.scope2RecordsWithEvidence, wasteRecordsWithEvidence, and evidence-linked labels for commuting/business travel/indirect.

Check: After the change, run Data Readiness and look at the agent response payload.contextReceived.scope2RecordsWithEvidence. It should be ≥ 1 when the property has energy records with evidence in the DB.

Note: If the app already fetches evidence for all record IDs (no category filter) and the DB only has evidence_attachments for waste (none for energy), then "Scope 2 records exist but no evidence in context" is correct — there is no evidence in the DB for those records. The fix is then to add/link evidence in the DB for energy records (or seed sample data), not to change the context builder.

Debug when Data Readiness says no Scope 2 evidence but Boundary shows energy evidence: Check the agent response payload.contextReceived.allRecordCategories (categories the app sent) and scope2RecordCategories (categories we classified as Scope 2). If energy records use a category not in the second list, either use a recognised value (e.g. energy, electricity, scope_2, heat, service_charge) in the app/DB for subject_category, or add that category to the agent's Scope 2 map in scope-mapping.rules.ts.
```

---

#### Part 5f-2 — Action Prioritisation tile (3rd tile)

```
Goal: The 3rd tile on the AI agents page is for Action Prioritisation (Projects). It must:

1. Use the property currently selected in the property dropdown (same as tiles 1 and 2).
2. When the user runs the Action Prioritisation agent (e.g. "Generate Project Shortlist" or "Run" on that tile), the app must:
   - Fetch from Supabase for the selected property only: property row, spaces, systems, end_use_nodes (if present), data_library_records (for that property), evidence_attachments + documents for those records.
   - Build the same context JSON shape as for Data Readiness and Boundary (propertyId, propertyName, reportingYear, spaces, systems, nodes, dataLibraryRecords, evidence). For impact ranges, include on energy records when available: valueNumeric, unit, reportingPeriodStart/End, cost (from data_library_records). For nodes, include utilityType when present.
   - POST that context to: POST {AGENT_API_BASE_URL}/api/action-prioritisation (same base URL as other agents, e.g. VITE_AGENT_API_URL; no trailing slash).
3. Display the agent response: Summary (agent's summary array); Top 3 initiatives from payload.top3 or payload.rankedProjects with the fields below; CTA "View Full Ranking" for full payload.rankedProjects. If the agent returns an error or "No projects generated", show a friendly message and suggest adding systems and energy data for the selected property.
4. For each project card/row, show: title, systemName, resolvedControl, feasibility, confidence (e.g. "Medium" or "Low"); and next to or under the confidence label, show what that value means using payload.projectConfidenceMeaning — e.g. when a project has confidence: "Medium", display the text from payload.projectConfidenceMeaning.Medium (e.g. as a small note, tooltip, or expandable line under "Confidence: Medium"). Same for "Low" and "High". This is the note that explains what "Medium" means for project confidence. Also show when present: savingsKWhRange, savingsRange, paybackYearsRange, capexRange (min–likely–max). Use payload.rangesExplanation to label ranges.
5. Confidence & Data Gaps section: Show "Confidence: Allocated" (or "Missing") and under or next to it, show what that means using payload.overallConfidenceMeaning: when confidenceLevel is "Allocated", display payload.overallConfidenceMeaning.Allocated; when "Missing", display payload.overallConfidenceMeaning.Missing. This explains "Confidence: Allocated" in the UI. Also show dataGaps. Optionally show confidenceNote and payload.projectConfidenceMeaning (what Medium/Low mean for each project).
6. Decision: The agent's decision text now includes a sentence explaining project confidence (Medium = kWh data in context; Low = no kWh or allocation-only). If your UI shows the decision, that note will appear there too.
```

---

#### Part 5f-3 — Sustainability Reporting tile (4th tile)

```
Goal: The 4th tile on the AI agents page is for Sustainability Reporting Agent. It must:

1. Use the property currently selected in the property dropdown (same as tiles 1–3).
2. When the user runs the Sustainability Reporting Agent (e.g. "Generate Report" or "Generate Report (PDF)"):
   - Fetch from Supabase for the selected property only: property, spaces, systems, end_use_nodes, data_library_records, evidence_attachments + documents (same context shape as other agents).
   - Optionally run or reuse Agent 3 (Action Prioritisation) for the same property and pass its output as actionPrioritisationOutput in the request body.
   - Build the request body: same AgentContext (propertyId, propertyName, reportingYear, spaces, systems, nodes, dataLibraryRecords, evidence, etc.) plus optional propertyAddress, reportType, actionPrioritisationOutput (Agent 3 result), dataReadinessOutput (Agent 1 result), and boundaryOutput (Agent 2 result). When the user has already run Data Readiness and/or Boundary, pass those agent outputs so the report links evidence and scope to the same data (payload.report.previous_agents_summary and evidenceLinks will align).
   - POST to: POST {AGENT_API_BASE_URL}/api/reporting-copilot (same base URL; no trailing slash).
3. Display the agent response: Summary; Report structure from payload.report and payload.reportMarkdown; evidenceLinks (same shape as Data Readiness/Boundary — label, recordId, scope, category) so the report view shows evidence linked to data library records; Primary CTA "Generate Report (PDF)" — use payload to produce a PDF, upload to Storage, create documents + evidence_attachments; Secondary CTA "View Evidence Index". When Data Readiness and/or Boundary were run first, show payload.report.previous_agents_summary if present (linked agents). Use agent_type sustainability_reporting and display name Sustainability Reporting Agent in the UI and Action Queue.
```

---

#### Part 5f-4 — Full fix: property switch + context (control + systems) + display

```
Use when: (1) Changing the property dropdown doesn't change the agent result; (2) generated text doesn't reflect the selected property or DB (control, systems); (3) prioritised projects don't show which systems they're based on.

Problems to fix

1. The dropdown is not dynamic. When the user changes the property dropdown, the screen still shows the previous property's agent result. Clear the result when the dropdown changes (e.g. set result to null) so the user must click Run again for the new property.
2. The context sent to the agents doesn't fully reflect the DB: system control (controlledBy) and which systems serve which spaces (servesSpaces) are missing or wrong.
3. Prioritised projects don't show system names and control from the DB; the UI doesn't show payload.rankedProjects with title, systemName, resolvedControl.

Implementation

- State: Store the currently selected property (e.g. selectedPropertyId). When the user changes the dropdown, set it to the new property id and clear all stored agent results.
- When Run is clicked: Use only selectedPropertyId to fetch and build context. Fetch: properties (one row), spaces, systems, end_use_nodes, data_library_records (filtered by property_id = selectedPropertyId), evidence_attachments + documents for those records. Map DB to context: systems.controlled_by → controlledBy ("Tenant" | "Landlord" | "Shared"); systems.serves_space_ids → servesSpaces (array of space UUIDs); evidence_attachments → evidence array with recordId = data_library_record_id (see STEP-BY-STEP-EVIDENCE-IN-CONTEXT.md).
- Display: Every tile should show which property the result is for. For Action Prioritisation, show payload.rankedProjects / top3 with title, system name (systemName), and control (resolvedControl).
```

---

#### Part 5f-6 — Report PDF format + evidence links (4th tile)

```
Use when the Sustainability Reporting (4th) tile has: (1) PDF showing raw *** or ## instead of bold and headings; (2) evidence links not displayed the same way as on the Data Readiness and Boundary tiles.

Why the PDF shows asterisks: The app is using reportMarkdown (plain text with markdown) for PDF. That is not rendered, so asterisks appear literally. You must use payload.reportHtml for PDF.

1. PDF — switch to reportHtml (required)

- Find the code that runs when the user clicks "Generate Report (PDF)" (or similar). It currently uses payload.reportMarkdown or the markdown string. Change it to use payload.reportHtml (or response.payload.reportHtml).
- Do not pass markdown to the PDF generator. Pass the HTML string from payload.reportHtml.
- Simple way (iframe + print): Create a hidden iframe, set iframe.srcdoc = response.payload.reportHtml, on load call iframe.contentWindow.print(). User can choose "Save as PDF" in the print dialog. Example:

const html = response.payload?.reportHtml ?? "";
const iframe = document.createElement("iframe");
iframe.style.cssText = "position:absolute;width:0;height:0;border:none;";
document.body.appendChild(iframe);
iframe.srcdoc = html;
iframe.onload = () => { iframe.contentWindow?.print(); document.body.removeChild(iframe); };

- If you use a PDF library: Give it the HTML from payload.reportHtml and use a path that renders HTML (e.g. html2canvas + jsPDF, or a method that accepts HTML). Do not use the markdown string — that causes literal asterisks.

2. Evidence links (same as tiles 1–3)

- The report response includes evidenceLinks (same shape as Data Readiness/Boundary: label, recordId, scope, category). On the 4th tile, display them with the same component as tiles 1–3 (same list/chips with label, scope, category).
```

### Part 5g — Supplementary agent material (duplicated from AI Agents)

Canonical sources (keep in sync when editing): [LOVABLE-PROMPTS-FOR-AGENTS.md](../../../AI%20Agents/agent/docs/LOVABLE-PROMPTS-FOR-AGENTS.md), [REPORT-SUMMARY-PAGE-SANITY-CHECK.md](../../../AI%20Agents/agent/docs/REPORT-SUMMARY-PAGE-SANITY-CHECK.md), [BACKEND-DATA-LIBRARY-SUBJECT-CATEGORY.md](../../../AI%20Agents/agent/docs/BACKEND-DATA-LIBRARY-SUBJECT-CATEGORY.md). **Switching modes / handover** text remains only in `LOVABLE-PROMPTS-FOR-AGENTS.md` (not copied below).

---

#### Part 5g-1 — Order to apply (suggested)

1. **[Cursor — Backend]** Ensure DB has schema and (if needed) seed data; docs describe the contract. Do **not** use Lovable to migrate or seed the DB.
2. **[Cursor — Agent]** Ensure agent API accepts the context shape and returns the response shape. Do **not** use Lovable to change the agent.
3. **[Lovable — paste prompt]** **Agent API URL** (Prompt 5 / Part 5e here) — so the app can reach the agent.
4. **[Lovable — paste prompt]** **Property dropdown + context** (Prompt 1 / Part 5d) or **Full fix** (Prompt 4 / Part 5f-4) — so the agent gets one property’s data and correct control/systems.
5. **[Lovable — paste prompt]** **Evidence in context** — follow `AI Agents/agent/docs/STEP-BY-STEP-EVIDENCE-IN-CONTEXT.md` Part 2 and its Lovable prompt. If the agent says "Scope 2 records exist but no evidence in context", use **Part 5f-1b** so evidence is sent for **all** record types (including energy).
6. **[Lovable — paste prompt]** **Action Prioritisation** (Part 5f-2) and **Sustainability Reporting** (Part 5f-3) — when you wire tiles 3 and 4.

Context shape is defined by the agent; see `AI Agents/agent/src/types.ts` (AgentContext) and the backend repo’s `handover-files-for-agent/CONTEXT-SOURCE.md` for the contract.

---

#### Part 5g-2 — Testing the full flow (app → backend → agent)

1. **Lovable app:** Select a property that has data library records (including at least one energy/Scope 2 record with evidence in the DB). Click **Run Data Readiness**.
2. **Browser Network tab:** Confirm there is a **POST** (not only OPTIONS) to the agent URL (`/api/data-readiness`). Open that request and check:
   - **Payload:** Contains `propertyId`, `dataLibraryRecords`, `evidence`; each evidence item has `recordId` = a `data_library_record.id` (including for energy records if they have evidence).
   - **Response:** Status 200, JSON with `summary`, `decision`, `payload.contextReceived` including `scope2RecordsWithEvidence`, `wasteRecordsWithEvidence`.
3. **Agent response:** If you have energy records with evidence in the DB and sent them in `evidence`, `payload.contextReceived.scope2RecordsWithEvidence` should be ≥ 1. If it stays 0, the app is still not including evidence for energy records — apply **Part 5f-1b**.

---

#### Part 5g-3 — Scope 3 (Commuting): workforce dataset (optional)

If the agent reports **"Workforce dataset (headcount/FTE for allocation) not in context"**: the app can optionally include **workforceDatasets** in the context for the selected property and reporting year. Each item: `{ id, year, propertyId, headcount, confidence }`. This is used for allocation of commuting/business travel. If you do not allocate by headcount, you can ignore this gap or add a small dataset in the app.

---

#### Part 5g-4 — Report / summary page sanity check (wrong or uncorrelated data)

When the **summary page** (or report view) shows data that doesn’t match the other agents or evidence, use this checklist.

**1. Why the summary page can show wrong or uncorrelated data**

| Cause | What happens | Fix |
|-------|----------------|-----|
| **Property mismatch** | Report was generated for property A but the user switched to property B; the summary still shows A’s data (coverage, evidence, systems). | When the user changes the **property dropdown**, clear the stored report (and all agent results). Require “Generate Report” again for the new property. |
| **Previous agents not passed** | Reporting Copilot was called **without** `dataReadinessOutput` and `boundaryOutput`. Then `payload.report.previous_agents_summary` is `undefined`, and the summary can’t show “linked” Data Readiness/Boundary text. Evidence counts and scope may still be from the same context, but the UI has nothing to show for “linked agents”. | When the user has already run **Data Readiness** and/or **Boundary** for the **same property**, pass those agent **outputs** in the request body to `POST /api/reporting-copilot`: `dataReadinessOutput`, `boundaryOutput`. Use the **same** property and **same** run (no mixing runs from different properties). |
| **Stale / cached report** | The summary page displays an **old** report (e.g. from a previous run or property) instead of the latest response from the Reporting Copilot. | Store the latest report by **property id** (or clear when property changes). Never show a report for property B when the selected property is A. |
| **Evidence from different run** | Evidence list or counts on the summary page come from a **different** agent run (e.g. Data Readiness from run 1, report from run 2 with different context). | Build the summary page from **one** Reporting Copilot response: use `payload.report` and top-level `evidenceLinks` from that response. If you show “linked Data Readiness”, use **only** the `dataReadinessOutput` and `boundaryOutput` that were **passed in** to that same report request. |

**2. What the app must do so the report matches other agents and evidence**

1. **Single source of truth for property** — The property shown in the dropdown is the one used for **all** agent calls (Data Readiness, Boundary, Action Prioritisation, Reporting Copilot). Use the **same** `selectedPropertyId` to fetch context and to call each agent.
2. **Same context for report as for other agents** — When calling `POST /api/reporting-copilot`, send the **same** AgentContext (same property, spaces, systems, nodes, dataLibraryRecords, evidence) that you would use for Data Readiness and Boundary. Build it from the **selected property** only.
3. **Pass previous agent outputs when available** — If the user has run Data Readiness and/or Boundary for the **current** property, include their **outputs** in the report request body: `dataReadinessOutput` (full JSON from `POST /api/data-readiness`), `boundaryOutput` (full JSON from `POST /api/boundary`). Then the report will populate `payload.report.previous_agents_summary` and the executive summary will say “Data Readiness and Boundary outputs are linked below”.
4. **Clear report when property changes** — When the user changes the property dropdown, clear the stored report (and ideally all agent results) so the summary page doesn’t show the previous property’s data.
5. **Display only from the current report response** — Summary page should render from the **latest** report response for the **current** property: use `payload.report` (cover, executive_summary, data_coverage_summary, evidence_index, previous_agents_summary) and top-level `evidenceLinks`. Do not mix in evidence or summaries from other runs or other agents’ stored results unless they were the ones passed into this report.

**3. How to verify using the agent response**

- `payload.report.cover.property_id` / `property_name` — property for which the report was generated.
- `payload.report.report_sanity` (optional): `contextPropertyId`, `contextPropertyName`, `contextEvidenceCount`, `contextRecordsCount`, `previousAgentsIncluded: { dataReadiness, boundary }`.

**Checks:** (1) Compare `report_sanity.contextPropertyId` (or `cover.property_id`) with the **currently selected property id**; if they differ, don’t show as current report. (2) If `previousAgentsIncluded` flags are true, show linked summary from `payload.report.previous_agents_summary`. (3) Use top-level `evidenceLinks` from the **same** report response for the evidence list; count should align with `contextEvidenceCount`.

**4. Lovable prompt (summary page fix) — paste block**

```
Requirement: Report summary page must show data that matches the selected property and the other agents (Data Readiness, Boundary) and evidence.

1. Property match
When displaying the report (or summary page), read payload.report.cover.property_id (or payload.report.report_sanity.contextPropertyId). Only show this report as the "current" report if that id equals the currently selected property id in the dropdown. If the user has changed the property and the stored report is for a different property, clear or hide that report and show a message like "Run report for the selected property" or "Report is for [property name]; select that property to view it."

2. Pass Data Readiness and Boundary into the report
When the user clicks "Generate Report" (or equivalent), if you have already run Data Readiness and/or Boundary for the same selected property in this session, pass their full response objects in the request body to the Reporting Copilot: dataReadinessOutput and boundaryOutput. That way the report's previous_agents_summary and executive summary reflect the same run and evidence.

3. Clear report when property changes
When the user changes the property dropdown, clear the stored report result (and ideally other agent results) so the summary page never shows a report for a different property.

4. Single source for summary content
Build the summary page from the one report response: use payload.report (executive_summary, data_coverage_summary, evidence_index, previous_agents_summary) and the top-level evidenceLinks. Do not mix in data from other agent runs or other properties. If payload.report.report_sanity.previousAgentsIncluded.dataReadiness is false, do not show a "Data Readiness summary" block from another run; show the report's own executive summary bullet that explains Data Readiness/Boundary were not passed.
```

**5. Agent-side behaviour (already in place)** — Report cover includes `property_id` / `property_name`; `report_sanity` supports UI checks; executive summary includes a bullet for linked vs not-linked agents; `evidenceLinks` align with the same context as Data Readiness/Boundary when the app sends the same context.

---

#### Part 5g-5 — Backend: `subject_category` for Data Coverage table (report)

**Purpose:** So the **Sustainability Report** Data Coverage Summary shows the right row (Electricity, Heating, Service charge, Water, etc.) per record, each **data_library_record** must have **subject_category** set to a value the agent can map to that row. **Table:** `data_library_records`. **Column:** `subject_category` (or send as `subjectCategory` in JSON; agent accepts both.)

**Values that map to each Data Coverage row**

| Data Coverage row | subject_category values that map to this row |
|-------------------|------------------------------------------------|
| **Electricity** | `Energy - Tenant electricity`, `energy_tenant_electricity`, `electricity` |
| **Heating** | `Energy - Heating`, `energy_heating`, `heating`, `district_heat`, `steam` |
| **Heat** (e.g. gas) | `Energy - Gas`, `energy_gas`, `heat`, `gas` |
| **Service charge** | `Energy - Service charge`, `energy_service_charge`, `service_charge`, `recharge`, `landlord_recharge` |
| **Water** | `Energy - Water`, `energy_water`, `water` |
| **Energy** (generic) | `energy`, `Energy` |
| **Waste** | `waste` |
| **Indirect activities** | `indirect_activities`, `commuting`, `business_travel`, etc. |
| **Commuting / Employee commuting** | `employee_commuting`, `commuting` |
| **Business travel** | `business_travel` |
| **Certificates** | `certificates`, `certificate` |
| **Governance** | `governance`, `policy`, `general` |
| **Targets** | `targets`, `target` |
| **ESG** | `esg` |

**Recommended values per record type (energy sub-types)**

| Record type (your UI / logic) | Set subject_category to |
|-------------------------------|-------------------------|
| Tenant electricity | `Energy - Tenant electricity` or `energy_tenant_electricity` |
| Heating | `Energy - Heating` or `energy_heating` |
| Gas | `Energy - Gas` or `energy_gas` |
| Service charge (energy) | `Energy - Service charge` or `energy_service_charge` |
| Water | `Energy - Water` or `energy_water` |
| Waste | `waste` |
| Indirect activities | `indirect_activities` |

**Step 1 — Ensure column exists (Supabase SQL Editor)**

```sql
ALTER TABLE data_library_records
ADD COLUMN IF NOT EXISTS subject_category text;
```

**Step 2 — Lovable prompt (set subject_category on insert)**

```
When we create or insert a row into data_library_records (form, upload, or API):

1. If the user selects a "Record type" or "Data type" (e.g. dropdown): set subject_category from that choice using this mapping:
   - Tenant electricity → Energy - Tenant electricity
   - Heating → Energy - Heating
   - Gas → Energy - Gas
   - Service charge → Energy - Service charge
   - Water → Energy - Water
   - Waste → waste
   - Indirect activities → indirect_activities
   If the dropdown uses different labels, map them to these exact values. Include subject_category in the Supabase .insert() (or equivalent) for data_library_records.

2. If we create a record from an uploaded file (e.g. CSV) and the file name indicates the type (e.g. contains "tenant", "electricity", "heating", "gas", "service charge", "water", "waste"): infer subject_category from the file name when creating the record (e.g. "tenant" + "electricity" → Energy - Tenant electricity, "heating" → Energy - Heating, "gas" → Energy - Gas, "service" + "charge" → Energy - Service charge, "water" → Energy - Water, "waste" → waste), and set it on the new row. Otherwise use energy as fallback.

Ensure every insert into data_library_records sets subject_category (or the column we use for this) so the sustainability report Data Coverage table can show Electricity, Heating, Service charge, Water rows correctly.
```

**Step 3 — Include `subject_category` when building context** — When you fetch `data_library_records` for the selected property, **select** `subject_category` and pass it through in `dataLibraryRecords` (as `subject_category` or `subjectCategory` per record).

**Step 4 — Fix existing rows** — One-off `UPDATE` patterns (by `name` / `subject_category = 'energy'`) and Option A/B JS examples for insert + infer-from-filename: see [BACKEND-DATA-LIBRARY-SUBJECT-CATEGORY.md](../../../AI%20Agents/agent/docs/BACKEND-DATA-LIBRARY-SUBJECT-CATEGORY.md) §3–4 (full snippets).

**Troubleshooting:** If Data Coverage still shows only "Energy": (1) Redeploy agent if using name/file inference fallback; (2) Ensure context `.select()` includes `subject_category`; (3) In Supabase, verify rows use specific values above, or backfill via SQL / re-save from app.

---

## Part 6 — DC system types (systems register)

No extra SQL. In Lovable, when `asset_type === 'data_centre'`, extend the system type dropdown using [building-systems-taxonomy.md](../data-model/building-systems-taxonomy.md) section 4 (Data centre system types).

Paste hint for Lovable:

```
When the property asset_type is data_centre, add to the Building Systems Register system_type dropdown all rows from the backend taxonomy "section 4 Data centre system types": HV_Intake, UPS_System, PDU_Unit, Generator_Set, StaticTransfer_Switch, BusBars, REC_Meter under Power; CRAC_Unit, CRAH_Unit, Chiller_Plant, CoolingTower, AdiabatiCooler, LiquidCooling_Rack, ImmersionCooling, HotAisleColdAisle, FreeAirCooling, CRAC_EC_Fan under HVAC; DCIM_Platform, PUE_Meter, TemperatureHumidity_Sensor, Power_Chain_Monitor, WaterMeter_DC, RackPowerMeter under Monitoring; MakeupWater_Meter, TotalWater_Meter under Water. Map each to the correct system_category in the form.
```

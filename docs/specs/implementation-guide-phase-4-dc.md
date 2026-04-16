# How to implement Phase 4 — Risk Diagnosis, context & PUE agent

This guide explains **what each step means** and **how to do it** in plain language.

**Link from main spec:** [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) → Section 8.1 Phase 4

---

## Step 4.1 — Risk Diagnosis schema and physical_risk_flags

**What it means:** We need a place to store "risk diagnosis" results per property, including physical risk flags that come from SitDeck (e.g. flood, wildfire). So we define a table (e.g. `risk_diagnosis` or similar) and a way to store flags with a source (e.g. `source = 'sitdeck'`).

**How to do it:**

- **Where:** Backend repo — migration [add-risk-diagnosis.sql](../database/migrations/add-risk-diagnosis.sql). Canonical SQL: [supabase-schema.sql](../database/supabase-schema.sql); logical doc: [schema.md](../database/schema.md) §3.4c–3.4d.
- **Create:** Table `**risk_diagnosis`** (one row per property, `UNIQUE(property_id)`): summary, `overall_risk_level`, `diagnosis_json`, `assessed_at`, `sitdeck_last_synced_at`, RLS on `account_id`. Table `**physical_risk_flags`**: `risk_diagnosis_id`, `flag_type`, `**source**` (`sitdeck`  `manual`  `agent`), severity, title, detail, `payload`, `external_ref`, RLS via parent diagnosis. Spec: SitDeck feeds Phase 3 widgets / webhooks; sync jobs or UI write flags with `source = 'sitdeck'`.
- **Run:** Supabase Dashboard → SQL Editor → paste and run `add-risk-diagnosis.sql` (idempotent policy drops).
- **If you use Cursor:**  
*"Create migration(s) for Risk Diagnosis: a table to hold risk assessment per property and physical_risk_flags (with source e.g. 'sitdeck'). RLS by account. See secure-dc-spec-v2.md §6 and §10."*

**Done when:** Tables exist; we can store risk diagnosis and physical_risk_flags linked to properties.

---

## Step 4.2 — Risk Diagnosis UI

**What it means:** Users need a screen (or section) that shows the "Risk Diagnosis" for a property: the risk record and the physical_risk_flags (e.g. from SitDeck). So they see a single place for risk and how SitDeck feeds into it.

**How to do it:**

- **Where:** Lovable app — e.g. property view → Risk tab or Risk Diagnosis page (see prompt for DC routes).
- **UI:** Display the risk diagnosis record for the property and list (or visualise) physical_risk_flags. When flags come from SitDeck (source = 'sitdeck'), show that. Data from Phase 3 widgets and sitdeck_risk_config can feed what gets written into these flags (manual sync or when refresh runs).
- **Lovable (paste-ready):** [LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md](./LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md) · [lovable-prompts copy](../lovable-prompts/LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md)
- **If you use Cursor:**  
*"Add Risk Diagnosis UI: show risk record and physical_risk_flags for the property. Indicate when flags are from SitDeck. Use the Risk Diagnosis schema from Phase 4."*

**Done when:** User can open Risk Diagnosis and see risk + physical flags, including from SitDeck.

---

## Step 4.3 — Extend Data Readiness and Boundary context for DC

**What it means:** The "context" we send to agents (and use for reporting) must include everything relevant for a data centre: not only basic property and spaces, but dc_metadata, DC space types, and DC systems. Phase 2 started this; now we ensure it’s complete and documented.

**How to do it:**

- **Where:** Backend or app — the code that builds the context payload for the PUE agent and any reporting.
- **Content:** For a data centre property, include: property fields, dc_metadata row, spaces (with space_type), systems (with DC system types), and any data_library_records you already include. Document the shape so the agent team can rely on it.
- **If you use Cursor:**  
*"Ensure Data Readiness and Boundary context for data centre properties includes dc_metadata, full space list with space_type, and systems. Document the context shape for the PUE agent."*

**Done when:** DC context is complete and documented; agent receives full DC data.

---

## Step 4.4 — PUE & Efficiency Advisor agent

**What it means:** Define and implement an agent that takes DC context (property, dc_metadata, data_library_records, spaces, systems) and returns structured output: e.g. PUE insight, comparison to target, recommendations. Agent logic lives in the AI agents repo; schema and DB design stay in the backend repo.

**How to do it:**

- **Where:** AI agents repo — new or extended agent. Backend repo — any new types/tables and docs.
- **Input:** The context built in 4.3 (property, dc_metadata, spaces, systems, data_library_records).
- **Output:** Structured response (e.g. current PUE vs target, trend, suggested actions). Document the expected JSON shape. If you persist runs, use existing agent_runs and agent_findings; store the structured result in payload.
- **If you use Cursor:**  
*"Implement PUE & Efficiency Advisor agent: input = DC context (property, dc_metadata, spaces, systems, data_library_records). Output = structured PUE insight and recommendations. Document input/output shape. Persist to agent_runs/agent_findings if applicable."*

**Done when:** Agent exists, accepts DC context, and returns structured PUE/recommendations.

---

## Step 4.5 — Wire agent from DC dashboard

**What it means:** From the DC dashboard (property-level), the user can trigger "Run PUE Advisor" (or similar). The app builds the context, calls the agent, shows the result, and optionally saves the run and findings to the database.

**How to do it:**

- **Where:** Lovable app — DC dashboard; use the same pattern as existing agent integration (build context, POST to agent, show result, optionally save to agent_runs and agent_findings).
- **Flow:** User clicks "Run PUE Advisor" → app fetches property, dc_metadata, spaces, systems, data_library_records → builds context JSON → POST to agent URL → display response → optionally insert agent_runs row and agent_findings row(s).
- **If you use Cursor:**  
*"On the DC property dashboard, add 'Run PUE Advisor'. Build context from property, dc_metadata, spaces, systems, data_library_records; POST to PUE agent; show result; optionally save to agent_runs and agent_findings."*

**Done when:** User can run the PUE advisor from the DC dashboard and see structured output (and optionally history in DB).

---

## Phase 4 complete

You’re done with Phase 4 when:

- Risk Diagnosis schema exists; physical_risk_flags stored and shown in UI.
- DC context is full and documented; PUE agent receives it and returns structured output.
- User can run the PUE Advisor from the DC dashboard and see results.

End of Data Centre implementation guides.
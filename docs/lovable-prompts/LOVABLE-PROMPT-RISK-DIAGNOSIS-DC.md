# Lovable prompt — Risk Diagnosis UI (Data Centre property)

**Use when:** [implementation-guide-phase-4-dc.md](../specs/implementation-guide-phase-4-dc.md) Step 4.2 — show **`risk_diagnosis`** and **`physical_risk_flags`** for a property; clearly label flags from SitDeck (`source = 'sitdeck'`).

**Prerequisites:** Migration [add-risk-diagnosis.sql](../database/migrations/add-risk-diagnosis.sql) applied. Schema: [schema.md](../database/schema.md) §3.4c–3.4d.

**Duplicate for IDE links:** [../specs/LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md](../specs/LOVABLE-PROMPT-RISK-DIAGNOSIS-DC.md) — keep both in sync.

**Spec:** [secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §6, §10 (Risk Diagnosis, physical risk flags).

---

## Prompt (copy everything inside the fence)

```
Risk Diagnosis UI — property-scoped (Data Centre context)

## Where to show it

Add a **Risk Diagnosis** surface for a **data centre property** (primary). Prefer one of:
- A **Risk** or **Risk Diagnosis** tab/section on the single DC property view (e.g. `/dashboards/data-centre/:propertyId`), or
- A dedicated route e.g. `/dashboards/data-centre/:propertyId/risk-diagnosis` linked from the DC property nav.

Reuse existing DC dashboard layout, typography, and card patterns so it matches the rest of Secure.

## Database (do not create tables from Lovable)

Tables already exist (Phase 4 migration):

**risk_diagnosis** — one row per property (`UNIQUE(property_id)`):
- id, account_id, property_id, summary, overall_risk_level, diagnosis_json, assessed_at, sitdeck_last_synced_at, created_at, updated_at
- `overall_risk_level`: nullable; values include `unknown`, `low`, `moderate`, `high`, `critical`

**physical_risk_flags** — many rows per diagnosis:
- id, risk_diagnosis_id, flag_type, source, severity, title, detail, payload, external_ref, created_at, updated_at
- `source`: **`sitdeck`** | `manual` | `agent` (required)
- `severity`: same enum style as overall_risk_level or null

RLS applies; use the authenticated Supabase client with the user’s session.

## Data loading

1. For the current `propertyId`, load diagnosis:
   - `supabase.from('risk_diagnosis').select('*').eq('property_id', propertyId).maybeSingle()`
2. If a row exists, load flags:
   - `supabase.from('physical_risk_flags').select('*').eq('risk_diagnosis_id', diagnosis.id).order('created_at', { ascending: false })`
3. If no `risk_diagnosis` row: show an empty state (e.g. “No risk diagnosis for this property yet”) — no error. Optionally mention that data may appear after SitDeck sync or assessment (no fake data).

## UI — risk record

When `risk_diagnosis` exists, show a **summary card** with:
- **Summary** (text) if `summary` is set
- **Overall risk level** as a clear badge/chip (map `unknown` / `low` / `moderate` / `high` / `critical` to accessible colours; handle null)
- **Assessed at** (`assessed_at`) and **SitDeck last synced** (`sitdeck_last_synced_at`) when present — human-readable dates
- **`diagnosis_json`**: if non-null, show in a collapsible “Structured details” section as pretty-printed JSON (read-only) or omit if empty

## UI — physical risk flags

List flags in a second section (“Physical risk flags” or similar). For each flag show at minimum:
- **Title** (fallback to formatted `flag_type` if title empty)
- **Flag type** (`flag_type`)
- **Severity** badge when set
- **Detail** (body text) when set
- **Source** — must be visually obvious:
  - When `source === 'sitdeck'`: label e.g. **“SitDeck”** or “From SitDeck” (badge/pill distinct from manual/agent)
  - When `source === 'manual'`: “Manual”
  - When `source === 'agent'`: “Agent”
- Optionally show `external_ref` in muted text for traceability

Do not merge or hide `source`; users must see which flags come from SitDeck vs manual vs agent.

## Scope and quality

- Read-only for this prompt (no create/edit forms unless product already wants them — focus on display).
- Loading and error states; responsive layout.
- Only show this block for **data_centre** properties (or hide for other asset types if the route is shared).

## Done when

- User can open Risk Diagnosis for a DC property and see the `risk_diagnosis` record when present.
- `physical_risk_flags` list renders with **SitDeck-sourced** flags clearly indicated.
- Empty diagnosis shows a sensible empty state without breaking the page.
```

---

## After Lovable implements

- Run [add-risk-diagnosis.sql](../database/migrations/add-risk-diagnosis.sql) if not already applied.
- Seed or sync a test row + flags (e.g. `source = 'sitdeck'`) to verify badges and RLS.

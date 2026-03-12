# Prompt to paste into Claude — Explain the spec comparison and recommend next steps

Copy everything below the line into Claude. You can attach or paste the full comparison doc (CLAUDE-SPECS-VS-BACKEND-SPECS-COMPARISON.md) if you want Claude to have the full detail.

---

I have two sets of specifications for the same product (Secure Building Data Platform):

**1. Specs you (Claude) created** — in Word format:
- **Data Library**: secure-data-library-spec-v3.docx — describes a full REST API (/api/v1), human validation workflow (record_validations table, validation_status lifecycle), coverage_assessments table, bulk CSV import API, evidence_role enum, rate limits, etc.
- **ESG Report**: secure-esg-report-spec-v2.docx — describes a 3-step wizard, report_instances / report_sections / report_evidence_links tables, server-side report generation engine, publish/archive workflow, and export API.

**2. Backend repo specs** (used by the team today) — in Markdown in docs/specs/:
- **Data Library**: data-library-specifications.md — Supabase-only (no REST API), no record_validations or coverage_assessments, no validation_status on records; "human validation of proofs" is noted as *planned (future)*. Evidence bucket is secure-documents; record schema uses value_numeric/value_text, reporting_period_start/end, source_type, confidence.
- **ESG Report**: esg-report-specifications.md — Hub + tabs UI (/esg or /reports, then /esg/corporate, /esg/secr, /esg/advisor); no report tables in the database; report state is in localStorage; client-side PDF export; Reporting Copilot is a separate AI agent flow from the AI Agents dashboard.

A comparison was done and the conclusion is: **the two are not the same**. Your (Claude) specs describe a REST API–based, server-side product with validation lifecycle, coverage engine persistence, and full report persistence. The backend specs describe the current implementation: Supabase-only, no validation/coverage/report tables, localStorage for report state, client-side export.

**I need you to:**

1. **Explain in plain language** what this gap means: what did you (Claude) assume vs what the team is actually building? Who is "right" or are both valid for different phases?

2. **Recommend what I should do next.** For example:
   - Should we treat your specs as the *target* and plan migrations (e.g. add record_validations, coverage_assessments, report_instances) and eventually a REST API or Edge Functions that mirror that surface?
   - Or keep the current Supabase-only approach and only pull in selected pieces from your specs (e.g. validation_status, evidence_role) without the full REST API?
   - What would you prioritise first: human validation, coverage persistence, report persistence, or something else?
   - Any risks or pitfalls if we stay with the current approach and never adopt the REST API / server-side report generation?

3. **Give a short, actionable list** (3–5 items) of "next steps" I can take this week or this quarter, depending on whether the goal is to align with your specs over time or to keep the current architecture and only adopt specific features.

Please write for a product/engineering lead who needs to decide how to reconcile the two spec sources and what to build next.

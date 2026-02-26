# Agent instructions — copy this folder into your AI agent project

This folder is a **self-contained copy** of everything the Secure SoR backend expects from the **AI agent** (Data Readiness / Boundary). Use it as the single instruction set when building or updating the agent.

**Read in this order:**

1. **INSTRUCTIONS.md** — What the agent should do, how it receives context, and a quick checklist.
2. **CONTEXT-SOURCE.md** — Where context comes from (Supabase) and the exact Agent context shape (Phase 5).
3. **AGENT-TASKS.md** — Concrete to-do: context input, API contract, data library, coverage and applicability.
4. **BACKEND-SYNC-NOTES.md** — Backend/Lovable sync notes: properties, spaces, systems, data library, utility applicability and service charge includes.
5. **COVERAGE-AND-APPLICABILITY-FOR-AGENT.md** — How to use property_utility_applicability and property_service_charge_includes for water/heating completeness and KPI coverage.

**Backend repo (source of truth):** Secure-SoR-backend. When the backend adds or changes context shape, DB columns, or coverage rules, update this folder (or re-copy from docs/for-agent/ and docs/architecture/coverage-and-applicability-for-agent.md) so the agent stays in sync.

**Rule:** For every change that affects the agent (data shape, API, coverage), the backend updates docs/for-agent/ and this handover folder; you apply the same in the agent project.

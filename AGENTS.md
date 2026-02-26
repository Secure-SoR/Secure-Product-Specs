# Agent context: Secure SoR backend (from Lovable UI)

This repository is the **backend** for the Secure app — the app you **build from the [Lovable.ai](https://lovable.ai) UI**. It is **not** the AI Agent (Boundary, Data Readiness, etc.). The AI Agent is a separate project and runs as its own service; it is applied on top of this backend.

## For AI agents working in this repo

1. **Read the canonical spec first:** `Secure_Canonical_v5.md` defines the product, domain model (Account, Property, Space, System, Data Library, Reporting Boundary), and rules. All new code should align with it.

2. **Apply project rules:** [CURSOR_CONTEXT.md](CURSOR_CONTEXT.md) — Data Library philosophy, engines (Coverage/Emissions/Controllability), control logic, coverage vs controllability, required entities, and "never do" guardrails.

3. **Use the docs:**  
   - `docs/data-model/` — account, data-library, systems  
   - `docs/architecture/` — system overview, boundary logic, data confidence, migration (Supabase → Azure)  
   - `docs/database/` — Supabase schema (tables, columns, RLS) and runnable SQL  
   - `docs/modules/` — reports and other modules  

4. **Lovable:** The frontend is built in Lovable and calls this backend. You are building the backend that the UI needs. The Boundary / Data Readiness agent lives elsewhere (e.g. in an "AI Agents" project) and is connected to the Lovable app separately.

5. **Agent context and for-agent:** The agent receives a single context JSON (built by Lovable from Supabase). This repo defines that shape and keeps the agent in sync:
   - **Exact shape:** Phase 5 “Agent context shape” in `docs/implementation-plan-lovable-supabase-agent.md`.
   - **For-agent notes:** `docs/for-agent/README.md`, `docs/for-agent/AGENT-TASKS.md`, `docs/for-agent/HANDOFF-FOR-AGENT.md`. A copy-into-agent folder is `docs/handover-files-for-agent/` (the AI agent project has its own copy at `agent/handover-files-for-agent/`). When you change properties, spaces, systems, data library, or context fields, update `docs/for-agent/` so the agent project can stay in sync.

6. **GitHub:** [Apex-TIGRE/Secure-SoR-backend](https://github.com/Apex-TIGRE/Secure-SoR-backend) — push and open PRs from here.

When in doubt, prefer the definitions and types in `Secure_Canonical_v5.md` and the docs.

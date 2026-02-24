# Agent context: Secure SoR backend (from Lovable UI)

This repository is the **backend** for the Secure app — the app you **build from the [Lovable.ai](https://lovable.ai) UI**. It is **not** the AI Agent (Boundary, Data Readiness, etc.). The AI Agent is a separate project and runs as its own service; it is applied on top of this backend.

## For AI agents working in this repo

1. **Read the canonical spec first:** `Secure_Canonical_v5.md` defines the product, domain model (Account, Property, Space, System, Data Library, Reporting Boundary), and rules. All new code should align with it.

2. **Use the docs:**  
   - `docs/data-model/` — account, data-library, systems  
   - `docs/architecture/` — system overview, boundary logic, data confidence, migration (Supabase → Azure)  
   - `docs/database/` — Supabase schema (tables, columns, RLS) and runnable SQL  
   - `docs/modules/` — reports and other modules  

3. **Lovable:** The frontend is built in Lovable and calls this backend. You are building the backend that the UI needs. The Boundary / Data Readiness agent lives elsewhere (e.g. in an "AI Agents" project) and is connected to the Lovable app separately.

4. **GitHub:** [Apex-TIGRE/Secure-SoR-backend](https://github.com/Apex-TIGRE/Secure-SoR-backend) — push and open PRs from here.

When in doubt, prefer the definitions and types in `Secure_Canonical_v5.md` and the docs.

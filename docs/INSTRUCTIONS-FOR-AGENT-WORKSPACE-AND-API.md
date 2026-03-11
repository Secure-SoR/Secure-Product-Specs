# Instructions for the AI agent workspace + reconnecting the API

Use this when (1) you need to **pass instructions to the other workspace** (the AI agent project), or (2) the **API connection has been lost** in the Lovable app (Supabase or Agent).

---

## Workspace roots (multi-root Cursor setup)

This backend repo is often used in a Cursor workspace with two other roots:

| Root | Path | Role |
|------|------|------|
| **Secure-SoR-backend** | `.../Documents/Secure-SoR-backend` | Docs, schema, migrations, handover for agent + Lovable |
| **AI Agents** | `/Users/anamariaspulber/Documents/AI Agents` | Data Readiness / Boundary agent |
| **Lovable** | `/Users/anamariaspulber/Documents/[Apex TIGRE]/1_Secure/Repositories/Lovable` | Frontend app (Supabase + agent UI) |

When pointing the agent at this repo, use the path to **Secure-SoR-backend**; agent folder: `Secure-SoR-backend/docs/for-agent/`.

---

## Part 1: What to give to the AI agent workspace

The AI agent (Data Readiness / Boundary) lives in a **separate project** (e.g. `Documents/AI Agents/agent`). The backend repo (Secure-SoR-backend) is the **source of truth** for context shape, DB columns, and how Lovable builds context from Supabase.

### Option A — Copy the handover folder into the agent repo

1. Copy the entire folder **`docs/for-agent/`** from this repo into the agent project (e.g. `agent/backend-instructions/` or `docs/backend-instructions/`).
2. In the agent project, tell your AI or team: **"Use the files in `backend-instructions/` (or the path you chose). Read in this order: README.md → INSTRUCTIONS.md → CONTEXT-SOURCE.md → AGENT-TASKS.md → BACKEND-SYNC-NOTES.md → COVERAGE-AND-APPLICABILITY-FOR-AGENT.md."**

### Option B — Point the agent at this repo (no copy)

In the agent project, add a short README or `CONTEXT-SOURCE.md` that says:

- **Context shape and API contract:** Read from the **backend repo** at  
  `[path]/Secure-SoR-backend/docs/for-agent/`  
  Start with **README.md** and **INSTRUCTIONS.md**; then **CONTEXT-SOURCE.md**, **AGENT-TASKS.md**, **BACKEND-SYNC-NOTES.md**, **COVERAGE-AND-APPLICABILITY-FOR-AGENT.md**.

Replace `[path]` with the actual path (e.g. `../Secure-SoR-backend` if the agent repo is next to it).

### What to paste into the agent (or into Cursor in the agent repo)

When you open the **agent workspace**, give it this instruction (adjust the path if you use Option B):

```
Use the backend repo for context shape and API contract. Read these files in order:

1. [backend-path]/docs/for-agent/README.md
2. [backend-path]/docs/for-agent/INSTRUCTIONS.md
3. [backend-path]/docs/for-agent/CONTEXT-SOURCE.md
4. [backend-path]/docs/for-agent/AGENT-TASKS.md
5. [backend-path]/docs/for-agent/BACKEND-SYNC-NOTES.md
6. [backend-path]/docs/for-agent/COVERAGE-AND-APPLICABILITY-FOR-AGENT.md

Apply the agent to whatever property context is sent; context is built by Lovable from Supabase (properties, spaces, systems, data_library_records, evidence). Input schema must match Phase 5 "Agent context shape" (propertyId, propertyName, spaces, systems, nodes, dataLibraryRecords, evidence; optional floorsInScope, reportingBoundary, propertyUtilityApplicability, propertyServiceChargeIncludes). Document the API endpoint and request/response so Lovable can call the agent. When reasoning about water/heating completeness, use property_utility_applicability and property_service_charge_includes per COVERAGE-AND-APPLICABILITY-FOR-AGENT.md.
```

### Agent checklist (from handover)

- [ ] Input schema matches Phase 5 "Agent context shape" (see CONTEXT-SOURCE.md).
- [ ] Agent accepts context for **any** property id (UUID from Supabase), not only a hardcoded demo.
- [ ] **floorsInScope** (from `properties.floors_in_scope`) is accepted and used for reporting boundary.
- [ ] **dataLibraryRecords** use **subject_category** (energy, water, waste, etc.); emissions are not stored as records.
- [ ] **Coverage:** When reasoning about water/heating completeness, use **property_utility_applicability** and **property_service_charge_includes** (see COVERAGE-AND-APPLICABILITY-FOR-AGENT.md).
- [ ] **API contract** (endpoint, request body, response format) is documented so Lovable can call the agent.
- [ ] After backend or Lovable changes, re-read the handover folder and update the agent if context shape or fields change.

---

## Part 2: Reconnecting the API (Lovable)

If the **API connection has been lost**, the app typically needs one or both of:

- **Supabase** (database + auth)
- **AI agent** (Run agent / Data Readiness / Boundary)

### 1. Supabase connection (Lovable)

The Lovable app talks to **Supabase** directly (client-side). If data no longer loads or auth fails:

1. **Environment variables in Lovable:**  
   In your Lovable project settings (or `.env`), set:
   - `VITE_SUPABASE_URL` = your Supabase project URL (e.g. `https://xxxxx.supabase.co`)
   - `VITE_SUPABASE_ANON_KEY` = your Supabase anon (public) key

2. **Where to get them:**  
   Supabase Dashboard → Project Settings → API → Project URL and anon public key.

3. **Create Supabase client:**  
   The app should create the client with `createClient(VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY)`. If the client was created with placeholders or a different env name, update the code to use the same variable names as in your env.

4. **RLS and tables:**  
   Ensure you’ve run the migrations in this repo (`docs/database/`) so the tables and RLS policies exist. If the project was recreated, re-run the schema and migrations.

### 2. AI agent connection (Lovable → Agent)

The **“Run agent”** flow in Lovable **POSTs** the context JSON to the agent’s API. If that call fails or the button does nothing:

1. **Agent URL in Lovable:**  
   The app needs the agent’s base URL (e.g. `https://your-agent.onrender.com`). Set it in env, for example:
   - `VITE_AGENT_API_URL` = `https://your-agent.onrender.com`  
   (or whatever name the Lovable app uses for the agent base URL)

2. **Use it in the Run agent flow:**  
   When the user runs the agent, the app should:
   - Build the context JSON (property, spaces, systems, dataLibraryRecords, evidence, optional floorsInScope, etc.) as in Phase 5 of `docs/implementation-plan-lovable-supabase-agent.md`.
   - `POST` to the agent endpoint, e.g. `${VITE_AGENT_API_URL}/api/data-readiness` or `/api/boundary` (depending on how the agent is hosted), with `body: contextJSON`.

3. **If the agent runs locally:**  
   Use a tunnel (e.g. ngrok) and set `VITE_AGENT_API_URL` to the tunnel URL, or deploy the agent (e.g. Render) and set `VITE_AGENT_API_URL` to the deployed URL.

4. **CORS:**  
   If the agent runs on another origin, the agent server must allow the Lovable app’s origin in CORS so the browser allows the POST.

### 3. Quick checklist (Lovable)

- [ ] `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are set and used by `createClient`.
- [ ] Supabase tables and RLS are in place (run migrations from this repo if needed).
- [ ] `VITE_AGENT_API_URL` (or equivalent) is set and used in the “Run agent” POST.
- [ ] Agent endpoint and request/response format match what the agent expects (see handover CONTEXT-SOURCE.md and agent repo API docs).

---

## File locations in this repo

| What | Where |
|------|--------|
| Agent folder (copy to agent project) | `docs/for-agent/` |
| Agent context shape (Phase 5) | `docs/implementation-plan-lovable-supabase-agent.md` (§ Phase 5) |
| DB schema and migrations | `docs/database/schema.md`, `docs/database/migrations/` |

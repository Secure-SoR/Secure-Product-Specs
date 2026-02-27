# Fix: Data Readiness must send POST to the agent (not only OPTIONS)

**UI types (both documented in backend):**
- **Platform UI** — the independent platform (your main product UI).
- **Agent AI app (Lovable)** — the app that talks to the agent (e.g. securetigre). Lovable UI changes are also specified here in the backend repo so one place has the full flow (backend + Platform + Lovable).

**Issue:** When the user clicks “Run Data Readiness” on the app (e.g. https://www.securetigre.co.uk), the browser only sends an **OPTIONS** request (CORS preflight) to the agent API; **no POST** is sent. So the agent never receives context and no result is returned.

**Cause:** The app’s “Run Data Readiness” handler must explicitly send a **POST** request with the context JSON. If the handler is missing, or only triggers a preflight, or the fetch is misconfigured, the POST never happens.

**Fix:** Implement (or fix) the handler so it builds the context, then sends **POST** to the agent URL with that context as the body. Paste the prompt below into **Lovable’s AI chat**.

---

## Lovable prompt — copy-paste into Lovable’s chat

**Copy from here ▼**

**Bug:** When the user clicks “Run Data Readiness”, the app does not send a POST request to the agent API. In the browser Network tab we only see OPTIONS to the agent URL; there is no POST with the context body. The agent never runs and no result is shown.

**Fix:**

1. **When “Run Data Readiness” is clicked**, the handler must:
   - Read the **currently selected property** (e.g. `selectedPropertyId` from the property dropdown).
   - Fetch from Supabase for that property only: property row, spaces, systems, end_use_nodes (if used), **data_library_records** (where `property_id = selectedPropertyId`), and **evidence_attachments** + **documents** for those records.
   - Build a **context** object with: `propertyId`, `propertyName`, `reportingYear`, `spaces`, `systems`, `nodes`, `dataLibraryRecords`, `evidence`. For evidence, each item must have **recordId** (or **record_id**) = the **data_library_record.id** that the file is attached to. Map DB columns to the agent’s names (e.g. `system_category` → `category`, `controlled_by` → `controlledBy` with values "Tenant"/"Landlord"/"Shared"). See the backend doc `docs/step-by-step-evidence-in-context.md` for the evidence array shape.
   - Send a **POST** request to the agent API URL (e.g. `import.meta.env.VITE_AGENT_API_URL` or `https://ai-agents-sor-boundary-agent-1-1.onrender.com`) + `/api/data-readiness`:
     - **Method:** POST
     - **Headers:** `Content-Type: application/json`
     - **Body:** `JSON.stringify(context)`
   - Example: `fetch(\`${agentBaseUrl}/api/data-readiness\`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(context) })`. Use the agent base URL from env (e.g. VITE_AGENT_API_URL); no trailing slash on the base URL.
   - On success, read the response (e.g. `response.json()`) and use it to display the agent result (summary, decision, payload) in the UI. On error, show a user-friendly message and optionally log the error.

2. **Do not rely on OPTIONS alone.** The browser will send OPTIONS first (preflight); your code must then send the actual **POST** with the body. Ensure the click handler calls `fetch` with `method: 'POST'` and `body: JSON.stringify(context)`.

3. **Check:** After deploying, in the browser Network tab when clicking “Run Data Readiness” there should be **two** requests to the agent URL: one **OPTIONS** and one **POST**. The POST should have a request payload (the context JSON) and a response body (the agent output with summary, decision, payload).

**Copy to here ▲**

---

## When to switch to backend mode

**Backend repo** holds: backend/agent instructions and **Lovable UI** prompts (this doc). Platform UI changes are also specified here when they affect the agent flow.

If the fix involves **backend / agent code** (e.g. changing how the agent builds context, or how the API receives/validates the body), **switch to backend mode** and use the instructions below.

**How to switch:** Open the **backend** project (e.g. `Secure-SoR-backend` or the SoR Boundary Agent repo) in Cursor and start a new chat there, or use Cursor’s “backend” / project context so the AI has access to the backend codebase.

**Instructions to paste in backend mode:**

```
I'm working on the Data Readiness flow. The frontend will POST context to /api/data-readiness. I need you to:

1. Ensure the backend accepts POST with a JSON body containing: propertyId, propertyName, reportingYear, spaces, systems, nodes, dataLibraryRecords, evidence.
2. Ensure the agent builds its internal context from all of these, and that the evidence array is used to link evidence to records by recordId (data_library_record_id). Evidence must be considered for ALL record types: energy (Scope 2), water, waste, commuting, business travel, indirect_activities.
3. If there's a "buildContext" or similar function that builds evidence only for some record types, change it so evidence is built for ALL records (including energy). Reference: docs/step-by-step-evidence-in-context.md and docs/lovable-evidence-for-all-records-including-energy.md.
4. Return a JSON response with at least: summary, decision, payload (and payload.contextReceived with e.g. scope2RecordsWithEvidence when applicable).
```

---

## When you return here (after backend changes are done)

When you come back to **this** chat (or the AI Agents / main project) after finishing the backend work, paste the following so we can pick up and decide next steps (e.g. Lovable UI, testing, or Platform UI).

**Copy from here ▼**

```
Backend changes for Data Readiness are done:
- [ ] Backend accepts POST to /api/data-readiness with the full context (propertyId, propertyName, reportingYear, spaces, systems, nodes, dataLibraryRecords, evidence).
- [ ] Agent uses evidence for ALL record types (including energy / Scope 2); scope2RecordsWithEvidence etc. are populated when applicable.
- [ ] Response shape: summary, decision, payload (with contextReceived).

Next: I need instructions for (1) Lovable UI — ensure the app builds context with evidence for all records and sends POST; (2) any Platform UI changes if needed; (3) how to test the full flow (app → backend → agent).
```

**Copy to here ▲**

---

## Reference

- Context shape and evidence: [step-by-step-evidence-in-context.md](step-by-step-evidence-in-context.md)
- Phase 5 context shape: [implementation-plan-lovable-supabase-agent.md](implementation-plan-lovable-supabase-agent.md) (§ Phase 5)
- Agent base URL: set `VITE_AGENT_API_URL` in the app to e.g. `https://ai-agents-sor-boundary-agent-1-1.onrender.com` (no trailing slash).

# Fix: Data Readiness must send POST to the agent (not only OPTIONS)

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

## Reference

- Context shape and evidence: [step-by-step-evidence-in-context.md](step-by-step-evidence-in-context.md)
- Phase 5 context shape: [implementation-plan-lovable-supabase-agent.md](implementation-plan-lovable-supabase-agent.md) (§ Phase 5)
- Agent base URL: set `VITE_AGENT_API_URL` in the app to e.g. `https://ai-agents-sor-boundary-agent-1-1.onrender.com` (no trailing slash).

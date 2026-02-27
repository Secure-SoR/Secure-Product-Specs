# Step-by-step: Get evidence into the agent (DB → Lovable)

This doc is the **backend-repo** version of the implementation guide. Part 1 is done in **Supabase**; Part 2 is implemented in **Lovable** (context builder). The agent only sees what you send in the request body.

Full detail and SQL for Part 1 also lives in the AI Agents repo: `agent/docs/CHECK-WASTE-RECORDS-AND-EVIDENCE.md` and `agent/docs/STEP-BY-STEP-EVIDENCE-IN-CONTEXT.md`.

---

## Part 1: Database (Supabase)

**Goal:** Ensure waste (and other) records exist and evidence (files) is linked via `evidence_attachments` and `documents`.

1. **Waste records:** Query `data_library_records` where `subject_category = 'waste'`. Note record `id` values (UUIDs).
2. **Evidence linked:** Query `evidence_attachments` joined to `documents` and `data_library_records` where `subject_category = 'waste'`. You should see rows (one per record–document link). If not, fix the upload flow so the app inserts into `documents` and `evidence_attachments` when a file is linked to a record.
3. **Per-record count (optional):** For each waste record, count rows in `evidence_attachments` where `data_library_record_id = record.id`. `evidence_count ≥ 1` means that record has evidence in the DB.

**Done when:** Waste records exist and at least some have matching rows in `evidence_attachments` (and `documents`). Then implement Part 2 in Lovable.

---

## Part 2: Lovable (context builder) — implement in code

**Goal:** When the user runs Data Readiness (or any agent) for the **selected property**, the app must send that property’s **data library records** and their **evidence** in the request body.

### Step 2.1 — Use the selected property everywhere

- Store the **currently selected property** in one place (e.g. `selectedPropertyId` from the property dropdown).
- When building context for any agent, use **only** `selectedPropertyId`. Do not use a hardcoded id or the first property in the list.
- When the user **changes** the dropdown, clear stored agent results so the UI does not show the previous property’s result.

### Step 2.2 — Fetch data library records for the selected property only

- The **data library** table holds records for **all properties** (account-wide). Each row has a `property_id`.
- When building context, query **data_library_records** filtered by the selected property:
  - Supabase: `supabase.from('data_library_records').select('*').eq('property_id', selectedPropertyId)`
  - Or equivalent: only rows where `property_id = selectedPropertyId`.
- Put the result in the context object as **dataLibraryRecords**. Each item must include at least: `id`, `subject_category` (or map to `category`), and any other fields the agent expects (see Phase 5 context shape in `implementation-plan-lovable-supabase-agent.md` and `handover-files-for-agent/CONTEXT-SOURCE.md`).

### Step 2.3 — Fetch evidence for those records

- From Step 2.2 you have a list of record IDs (e.g. `dataLibraryRecords.map(r => r.id)`). This includes **all** records for the property (energy/Scope 2, water, waste, commuting, business travel, indirect_activities). Evidence must be fetched for **all** of them, not only waste or Scope 3.
- Query **evidence_attachments** where `data_library_record_id` is in that list, and join **documents** to get the file name:
  - Option A: For each record id in the list, query `evidence_attachments` with `.in('data_library_record_id', recordIds)`, then for each attachment fetch the related `documents` row (by `document_id`) for `file_name`.
  - Option B: One query that returns attachment id, `data_library_record_id`, `document_id`, and `documents.file_name` (e.g. via a join or RPC).
- You need one row per attachment: **data_library_record_id** and **file_name** (from `documents`).

### Step 2.4 — Build the `evidence` array for the request body

- From Step 2.3, build an array of objects. Each object must have:
  - **recordId** = `data_library_record_id` (the UUID of the record). **Critical:** the agent matches evidence to records by this.
  - **id** = e.g. evidence_attachment id or document id.
  - **recordType** = e.g. `"data_library_record"`.
  - **fileName** = from `documents.file_name` (optional but useful).
  - **recordName** = optional (e.g. from the data library record name).
- Add this array to the context object as **evidence** (same key as in Phase 5 / CONTEXT-SOURCE.md).

### Step 2.5 — Send context to the agent

- When the user clicks “Run Data Readiness” (or similar), the request body must include:
  - **propertyId** = `selectedPropertyId`
  - **propertyName** = selected property name (if needed)
  - **dataLibraryRecords** = array from Step 2.2 (only that property’s records)
  - **evidence** = array from Step 2.4 (only evidence for those records)
- POST this context to the agent endpoint (e.g. `${VITE_AGENT_API_URL}/api/data-readiness`). The agent will set **wasteRecordsWithEvidence** in the response based on how many waste record IDs appear in the evidence array.

### Step 2.6 — Verify

- After running Data Readiness, check the agent response payload: **contextReceived.wasteRecordsInContext** and **contextReceived.wasteRecordsWithEvidence**. If the DB has evidence for that property and you implemented Steps 2.2–2.5, **wasteRecordsWithEvidence** should be ≥ 1.

---

## Summary

| Where     | What to do |
|----------|------------|
| **DB**   | Ensure waste records exist and are linked to documents via `evidence_attachments` (and `documents`). |
| **Lovable** | For the selected property: (1) fetch its data_library_records, (2) fetch evidence_attachments + documents for those records, (3) build an `evidence` array with `recordId` = data_library_record id, (4) send it in the agent request. |

Schema reference: `docs/database/schema.md` (§ data_library_records, evidence_attachments, documents). Context shape: `handover-files-for-agent/CONTEXT-SOURCE.md` and Phase 5 in `implementation-plan-lovable-supabase-agent.md`.

---

## Lovable prompt (copy-paste into Lovable’s chat)

Paste the block below into **Lovable’s AI chat** so it implements Part 2 (evidence in context).

**Copy from here ▼**

When the user runs Data Readiness (or any agent), build the context in the app as follows:

1. **Selected property only:** Use only the currently selected property from the dropdown (e.g. `selectedPropertyId`) for all fetches. When the user changes the property dropdown, clear any stored agent results so the previous property’s result is not shown.

2. **Data library records:** Fetch `data_library_records` filtered by `property_id = selectedPropertyId` (the data library is account-wide; only send this property’s records). Send them in the request body as `dataLibraryRecords` with at least `id`, `subject_category` (or `category`), and other fields the agent expects.

3. **Evidence:** After loading data_library_records for the selected property, fetch evidence for those records: query `evidence_attachments` where `data_library_record_id` is in the list of those record IDs, and join `documents` to get the file name. Build an array of objects: `{ id, recordId: data_library_record_id, recordType: "data_library_record", recordName?, fileName }`. **recordId must be the data_library_record UUID** so the agent can match evidence to records. Send this array in the request body as `evidence`.

4. **Request body:** When calling the agent API, include in the context: `propertyId`, `propertyName`, `dataLibraryRecords` (from step 2), and `evidence` (from step 3). The agent uses this to set wasteRecordsWithEvidence and other evidence-based fields.

**Copy to here ▲**

---

## Other Lovable prompts (agent module integration)

The prompt above is for **evidence in context** only. Other prompts (property dropdown, tiles, API URL, full fix) are **agent module integration** — they live in the **AI Agents** repo, not in the backend, because the platform is independent and the agents are a module on top.

- **Where to find them:** AI Agents repo → **`agent/docs/LOVABLE-PROMPTS-FOR-AGENTS.md`** (and root `lovable.md`, `LOVABLE-FIX-PROPERTY-SWITCH-AND-CONTEXT.md`).
- **This backend doc** keeps the platform-side piece: how evidence is stored (Part 1) and how to build the evidence array from platform data when the agent module is used (Part 2 + prompt above). That’s the contract; the rest of the wiring is in the agent repo.

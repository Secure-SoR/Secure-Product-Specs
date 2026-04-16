# Fix: Evidence array must include all records (energy, waste, commuting, etc.)

**Issue:** The agent shows "Scope 2 records exist but evidence not linked" even when energy (Scope 2) records have evidence in the DB. The app’s `buildContext` (or equivalent) may be building the **evidence** array only for some categories (e.g. waste, indirect) and omitting evidence for **energy** (Scope 2) records.

**Fix:** When building the context for the agent, the **evidence** array must include evidence for **all** data library records for the selected property — energy, water, waste, commuting, business travel, indirect_activities, etc. Use the **same** list of record IDs as `dataLibraryRecords`; fetch evidence_attachments for **all** those IDs; build one evidence entry per attachment with **recordId** = `data_library_record_id`.

Paste the prompt below into **Lovable’s AI chat**.

---

## Lovable prompt — copy-paste into Lovable’s chat

**Copy from here ▼**

**Requirement:** When building the context for the Data Readiness agent, the **evidence** array must include evidence for **all** data library records for the selected property, not only some categories.

**Current behaviour (if wrong):** Evidence might be fetched or built only for certain record types (e.g. waste, indirect_activities), so Scope 2 (energy) records have no evidence in the context and the agent shows "Scope 2 records exist but evidence not linked".

**Fix:**

1. After fetching **data_library_records** for the selected property (`property_id = selectedPropertyId`), take the **full list** of record IDs (all records — energy, water, waste, commuting, business_travel, indirect_activities, etc.).
2. Fetch **evidence_attachments** where `data_library_record_id` is in **that full list** (no filter by category). Join **documents** to get the file name.
3. Build the **evidence** array: one object per attachment with **recordId** = `data_library_record_id`, plus `id`, `recordType`, `fileName`, `recordName` as needed. Append **all** of these to the evidence array so the agent receives evidence for energy (Scope 2) as well as waste, commuting, travel, and indirect.
4. Send this full evidence array in the context when calling the agent. The agent uses it to set `scope2RecordsWithEvidence`, `wasteRecordsWithEvidence`, and evidence-linked labels for commuting/business travel/indirect.

**Check:** After the change, run Data Readiness and look at the agent response `payload.contextReceived.scope2RecordsWithEvidence`. It should be ≥ 1 when the property has energy records with evidence in the DB.

**Copy to here ▲**

---

## Reference

- [step-by-step-evidence-in-context.md](step-by-step-evidence-in-context.md) — Step 2.3: fetch evidence for **all** records (including energy).

# Backend optimisations and UI implications

This document lists **recommended optimisations** for the Secure SoR platform (Supabase backend) and the **implications for the Lovable UI**. For a concise **UI checklist** (what Lovable must do for each optimisation), see **§4 UI implications for backend optimisations (Lovable checklist)**.

---

## 1. Database (schema & indexes)

### 1.1 Data Library records — composite indexes

**Current:** Only `account_id` and `property_id` are indexed on `data_library_records`.

**Recommendation:** Add indexes for the most common filter combinations used by the UI and by the agent context builder:

- **By property + category (e.g. Energy / Waste tabs):**  
  `(property_id, subject_category)`
- **By account + category (e.g. “all energy records for account”):**  
  `(account_id, subject_category)`
- **By property + reporting period (date range filter):**  
  `(property_id, reporting_period_start, reporting_period_end)`  
  or at least `(property_id, reporting_period_start)` if the UI filters by “period start”.

**Effect:** Faster list and filter on Data Library pages; faster context query when building the payload for the Data Readiness agent.

**Migration (run in Supabase SQL Editor):**

```sql
-- Data Library: property + category (tabs, filters)
CREATE INDEX IF NOT EXISTS idx_data_library_records_property_subject
  ON public.data_library_records(property_id, subject_category);

-- Data Library: account + category (cross-property views if needed)
CREATE INDEX IF NOT EXISTS idx_data_library_records_account_subject
  ON public.data_library_records(account_id, subject_category);

-- Data Library: property + period (date range filter)
CREATE INDEX IF NOT EXISTS idx_data_library_records_property_period
  ON public.data_library_records(property_id, reporting_period_start, reporting_period_end);
```

---

### 1.2 Agent runs — property and time

**Current:** Only `idx_agent_runs_account_id` exists.

**Recommendation:** Add:

- `(property_id)` — for “runs for this property” (e.g. property-scoped agent history).
- `(account_id, created_at DESC)` — for “recent runs” list (optional; can be covered by account_id + sort in app if row count is low).

**Effect:** Faster loading of agent run history when filtered by property or when showing recent runs.

**Migration:**

```sql
CREATE INDEX IF NOT EXISTS idx_agent_runs_property_id ON public.agent_runs(property_id);
CREATE INDEX IF NOT EXISTS idx_agent_runs_account_created ON public.agent_runs(account_id, created_at DESC);
```

---

### 1.3 Documents / evidence — storage path lookups

**Current:** Only `account_id` is indexed on `documents`. Lookups by `storage_path` or by “documents for these record IDs” go through `evidence_attachments` (which has indexes on `data_library_record_id` and `document_id`).

**Recommendation:** No extra index required for typical “evidence for records” flow (evidence_attachments is already well indexed). If you later add “find document by path” or “list documents for property,” consider:

- `(account_id, storage_path)` if you query by path.

Defer until such a query exists.

---

## 2. Query shape and RPCs

### 2.1 Pagination for large lists

**Current:** Docs show e.g.  
`supabase.from('data_library_records').select('*').eq('property_id', selectedPropertyId)`  
with no `.range()`.

**Recommendation:** Use Supabase `.range(from, to)` (or cursor-based pagination via `created_at` + limit) for:

- **data_library_records** (list by property or account).
- **audit_events** (audit log).
- **agent_runs** (run history).

Example:

```ts
const PAGE_SIZE = 50;
const { data, error } = await supabase
  .from('data_library_records')
  .select('id, name, subject_category, reporting_period_start, reporting_period_end, confidence, ...')
  .eq('property_id', propertyId)
  .order('reporting_period_start', { ascending: false })
  .range((page - 1) * PAGE_SIZE, page * PAGE_SIZE - 1);
```

**UI implications:**

- Data Library list, Audit log, and Agent run history should be **paginated** (e.g. “Load more” or page numbers).
- Show a **loading state** for the next page; keep first page size small (e.g. 25–50) so the first paint is fast.
- If you add “date range” or “category” filters, apply them in the query (`.eq('subject_category', category)`, `.gte('reporting_period_start', start).lte('reporting_period_end', end)`) so the backend returns only the needed rows.

---

### 2.2 Records + evidence in one round-trip (agent context)

**Current:** Step-by-step evidence doc describes: (1) fetch `data_library_records` for property, (2) fetch `evidence_attachments` + `documents` for those record IDs — i.e. at least two round-trips (or N+1 if done per record).

**Recommendation:** Add a **Supabase RPC** (or a **view** + select) that returns, for a given `property_id`:

- Data library records for that property (with only the columns needed for context), and
- For each record, either:
  - evidence count, or
  - list of evidence rows (e.g. `recordId`, `documentId`, `file_name`).

Example signature:

```sql
-- Returns: records (id, name, subject_category, ...) and evidence (record_id, document_id, file_name)
get_property_records_with_evidence(p_property_id uuid)
```

The Lovable context builder would call this **once** before calling the agent, and build the request body from the result.

**UI implications:**

- **No change** to what the user sees; only fewer network calls and faster “Run Data Readiness” (or similar).
- If you later add a “Preview context” or “Validate before run” feature, the same RPC can power that without extra round-trips.

---

### 2.3 Select only needed columns

**Current:** Several docs use `.select('*')`.

**Recommendation:** For list views and for agent context, **select only required columns** (e.g. id, name, subject_category, reporting_period_start/end, confidence, property_id). Avoid selecting large jsonb or text columns when not needed.

**UI implications:**

- None for behaviour; slightly smaller payloads and faster responses. No UI change required beyond ensuring list/table components only depend on the fields you actually fetch.

---

## 3. RLS and policy performance

**Current:** All account-scoped tables use policies like  
`account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())`.  
There are indexes on `account_memberships(user_id)` and `account_memberships(account_id)`.

**Recommendation:** Keep as is for now. If you ever see slow plans on very large tables, Postgres can use a **stable function** (e.g. `current_user_account_ids()`) that caches the set of account IDs for the request; that would be a later, measured optimisation. No UI impact.

---

## 4. UI implications for backend optimisations (Lovable checklist)

When you implement the backend optimisations above, the **UI (Lovable)** should do the following. This is the single place to look for “what does the frontend need to change?”

| Backend optimisation | What the UI must do (Lovable) |
|----------------------|------------------------------|
| **Composite indexes (Data Library, agent_runs)** | **No UI code change.** Queries stay the same; lists and filters just get faster. Optionally: add **filters** (e.g. by `subject_category`, date range) so the new indexes are used: `.eq('subject_category', category)`, `.gte('reporting_period_start', start).lte('reporting_period_end', end)`. |
| **Pagination (records, audit, agent runs)** | **Add pagination and loading states.** (1) Use `.range(from, to)` (or cursor) in Supabase calls for Data Library list, Audit log, and Agent run history. (2) In the UI: show “Load more” or page numbers; show a **loading** state when fetching the next page. (3) Use a small first page size (e.g. 25–50) so first paint is fast. (4) If you add filters (category, date range), send them in the query so the backend returns only the needed rows. |
| **RPC “records with evidence”** | **Switch context builder to use the RPC.** When the RPC exists: call it once (e.g. `supabase.rpc('get_property_records_with_evidence', { p_property_id: selectedPropertyId })`) and build the agent context from the result instead of separate fetches for records and evidence. No change to what the user sees; only fewer requests and faster “Run Data Readiness” etc. Optional: use the same RPC for a “Preview context” or “Validate before run” feature. |
| **Select only needed columns** | **No new screens.** When you change queries from `.select('*')` to explicit columns, ensure list/table components only use the fields you now fetch (e.g. id, name, subject_category, reporting_period_start/end, confidence). If a component expects a column you dropped, add it back to the select or remove that dependency. |
| **RLS / policy performance** | **No UI change.** Any future optimisation (e.g. stable function for account IDs) is server-side only. |

**Summary:** The only backend optimisations that **require** UI work are **pagination** (add controls + loading) and **RPC for context** (call the RPC instead of multiple fetches). Indexes and tighter selects need no or minimal UI changes.

---

## 5. Summary table

| Optimisation | Backend change | UI implication |
|-------------|----------------|-----------------|
| Composite indexes on `data_library_records` | Add 3 indexes (property+subject, account+subject, property+period) | Faster lists and filters; no UI change. |
| Indexes on `agent_runs` (property_id, account+created_at) | Add 2 indexes | Faster agent run history; no UI change. |
| Pagination for records, audit, agent runs | Use `.range()` or cursor in queries | Add **pagination** (Load more / pages) and **loading states** for lists. |
| RPC “records with evidence” for context | New RPC (or view) | Fewer round-trips; optional “Preview context” later. No visible change for current flows. |
| Select only needed columns | Replace `select('*')` with explicit columns where appropriate | No UI change; ensure components use only requested fields. |

---

## 6. Suggested order of work

1. **Add the indexes** (Section 1) — low risk, immediate benefit for Data Library and agent runs.
2. **Introduce pagination** in the UI and in the corresponding Supabase queries (Section 2.1) — prevents slow loads as data grows.
3. **Add the “records with evidence” RPC** (Section 2.2) — then switch the agent context builder to use it.
4. **Tighten selects** (Section 2.3) — as you touch each list or context builder.

Schema reference: `docs/database/schema.md`.  
Context builder reference: `docs/step-by-step-evidence-in-context.md`, `docs/implementation-plan-lovable-supabase-agent.md`.

---

## 7. Agent-side optimisations (separate doc)

Optimisations for the **AI agents** (Data Readiness, Boundary, Action Prioritisation, Sustainability Reporting) — payload size, timeouts, context trimming, caching, validation, rate limiting — and their implications for the UI are documented in the **AI Agents** repo:

- **Path:** `[AI-Agents-repo]/agent/docs/OPTIMISATIONS-AND-UI-IMPLICATIONS.md`

That doc covers: 1MB body limit and 413 handling; request timeouts and 504; which context fields each agent actually uses (so Lovable can send a minimal payload); optional Run-all endpoint and client/server caching; validation and 400 responses; rate limiting and 429. The platform (backend) optimisations above (indexes, pagination, RPC for records+evidence) reduce the cost and time of **building** context in Lovable; the agent doc reduces the cost and improves robustness of **sending** context and **receiving** responses.

# Data Library: seed evidence — do it from backend mode

**Rule:** DB changes (migrations, seed data, `evidence_attachments`, `documents`) are done from **backend mode** — Supabase SQL Editor or scripts in this repo. **Lovable** is for the app UI (screens, context builder, upload flow). Do not use Lovable prompts to “seed the DB”; use backend/Supabase so the change is versioned and repeatable.

**Workflow:** In steps and todos, label the mode. Seed evidence = **[Cursor — Backend]**. See agent repo `agent/docs/MODE-AND-WORKFLOW.md` for the full rule.

---

## What was done (reflected here)

For testing Data Readiness with Scope 2 evidence, seed data was added:

- **7 evidence documents + attachments** for energy records: tenant electricity ×2, heating, gas, service charge ×2, water.
- **Result:** Context now includes 9 evidence items (7 energy + 2 waste), and `scope2RecordsWithEvidence` can be ≥ 1 when running Data Readiness.

The **context builder** (Lovable) was already correct — it fetches evidence for all record IDs. The DB simply had no `evidence_attachments` rows for energy records before seeding.

---

## How to seed evidence from backend mode

1. **Supabase SQL Editor** (or a migration/script in this repo):
   - Insert rows into `documents` (e.g. placeholder or real file metadata: `account_id`, `file_name`, `storage_path`, etc.).
   - Insert rows into `evidence_attachments` with `data_library_record_id` = the energy record UUID and `document_id` = the new document UUID.
2. **Repeat** for each energy record you want to have evidence (tenant electricity, heating, gas, service charge, water, etc.).
3. Optionally add a **seed script** (e.g. `docs/database/seeds/seed-energy-evidence.sql`) that inserts documents + evidence_attachments for known test property/record IDs, so others can run it from backend mode.

---

## Why not Lovable for seeding?

- Lovable is for **building the app** (UI, API calls, context). Asking Lovable to “seed the DB” can lead to one-off or UI-driven changes that aren’t documented or repeatable in the backend.
- **Backend mode** keeps DB changes in migrations/seeds and docs (like this file), so the team can run the same steps and the backend repo stays the source of truth.

If you need to add more test evidence later, do it from backend mode (Supabase or a script in this repo) and update this doc or add a seed script.

# Cursor memory & workflow (Secure SoR)

**Canonical rule:** The rule Cursor actually uses is **`.cursor/rules/workflow-and-memory.mdc`** (always applied in this workspace). This doc is a readable copy; the .mdc file is the source of truth for backend vs agent mode, folder scope, and implementation workflow.

---

## Backend mode vs Agent mode — which folders to use

- **Backend mode (this repo: Secure-SoR-backend):**
  - **Use / keep up to date:** Everything in this repo. Specs go in `docs/specs/`. Implementation guides in `docs/specs/` (e.g. `implementation-guide-phase-*.md`). Lovable prompts in `docs/` (e.g. `LOVABLE-PROMPT-*.md`). Migrations in `docs/database/migrations/`. Schema docs: `docs/database/schema.md`, `docs/database/supabase-schema.sql`. Data model / taxonomy: `docs/data-model/`.
  - **Do not create or edit:** Agent code (that lives in the separate AI Agents / agent repo). In backend mode we only produce specs, guides, migrations, and Lovable prompts; we do not write agent application code here.

- **Agent mode (AI Agents / agent repo):**
  - **Use / keep up to date:** The agent repo folders (e.g. agent code, agent docs). Schema and API contracts stay defined in the **backend** repo; the agent repo implements the API and reads context from the backend docs.
  - **Do not create or edit:** Backend migrations, Supabase schema, or Lovable prompts in the agent repo. Those live in Secure-SoR-backend only.

**Summary:** Backend repo = specs, guides, migrations, schema docs, Lovable prompts. Agent repo = agent app code and agent-specific docs. After each implementation step, keep all files in the relevant folder up to date (e.g. if we add a table, update schema.md and any guide that references it).

---

## How every implementation is done (product-led, via Cursor)

1. **I (product) paste the specification** into Cursor (backend repo).
2. **Cursor produces:**
   - An **md file** that captures the spec (e.g. in `docs/specs/`).
   - A **guide** (e.g. implementation guide with “what it means” and “how to do it”).
   - **Concrete implementation steps** derived from the guide:
     - **Lovable prompts** — ready-to-paste instructions for the UI (save as `docs/LOVABLE-PROMPT-*.md`).
     - **Migrations** — SQL files (e.g. `docs/database/migrations/add-*.sql`) with exact tables/columns and how to run them (e.g. Supabase SQL Editor).
     - **Schema docs** — updates to `docs/database/schema.md` and `docs/database/supabase-schema.sql` so the backend docs match the real database.
3. **I do everything:** I run migrations in Supabase, paste Lovable prompts into Lovable, and follow the guide. I am not an engineer; I need **clear, step-by-step instructions** (which SQL to run and how, which prompt to paste where, what to check after).

**Rule:** Every new functionality goes through Cursor in this way. No implementation is done without a spec → md file → guide → steps (Lovable prompts, migrations, schema updates). Keep all of these in sync after each implementation.

---

## What I need in every implementation

- **Migrations:** Which SQL file(s) to run, in which order. Exact table and column names. How to run them (e.g. “Supabase Dashboard → SQL Editor → paste and Run”). Idempotent where possible (e.g. DROP POLICY IF EXISTS before CREATE POLICY) so re-running doesn’t fail.
- **Lovable prompts:** One prompt per UI change (or one doc with several prompts). Paste-ready text that tells Lovable exactly what to build (fields, validation, save behaviour, mapping to Supabase columns). If there’s a mapping (e.g. form field → DB column), include it in the prompt.
- **Schema docs:** After any migration, update `schema.md` and, if applicable, `supabase-schema.sql` so the docs match the database. List new tables/columns and point to the migration file.
- **Guides:** Plain-language explanation of each step (“what it means”, “how to do it”) so I can follow or hand off without guessing.

---

## Folder checklist (keep up to date after each implementation)

| What changed        | Files/folders to update |
|---------------------|-------------------------|
| New table / columns | `docs/database/migrations/` (new .sql), `docs/database/schema.md`, `docs/database/supabase-schema.sql` |
| New UI flow         | `docs/LOVABLE-PROMPT-*.md` (new or updated), implementation guide in `docs/specs/` |
| New spec / feature  | `docs/specs/*.md` (spec + implementation guide), step-by-step in guide, then prompts + migrations from it |
| Taxonomy / enums    | `docs/data-model/*.md` (e.g. space-types-taxonomy, building-systems-taxonomy), schema.md if needed |

All of the above live in **Secure-SoR-backend**. Agent repo stays in sync by reading backend docs (e.g. context shape, API contract); backend repo is the source of truth for schema and product behaviour.

**Audit (routes, components, automation gaps):** [docs/AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md) — lists route alignment (backend vs agent), component inconsistencies (spaces tiles, upload flows, tenant/landlord sections), and automation gaps (broken first, then missing, then cosmetic). §5 maps each gap to backend action and existing Lovable prompt where applicable.

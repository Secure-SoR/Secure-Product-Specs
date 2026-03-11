# Cursor memory & workflow (Secure SoR)

**Canonical rule:** The rule Cursor actually uses is **`.cursor/rules/workflow-and-memory.mdc`** (always applied in this workspace). This doc is a readable copy; the .mdc file is the source of truth for backend vs agent mode, folder scope, and implementation workflow.

---

## How to work with Cursor (practical guide)

**1. Declare mode when it matters**  
- **“We’re on backend”** or **“Backend mode”** → I only create/edit in **Secure-SoR-backend** (specs, prompts, migrations, schema). Default if you don’t say otherwise.  
- **“Check Lovable”** / **“Align Lovable with the spec”** → I read the Lovable repo and compare to backend specs; I don’t add new prompts unless you ask.  
- **“We’re on AI Agents”** / **“Agent mode”** → I work in the **AI Agents** root only.

**2. Giving specifications for a functionality**  
- **Any format is fine.** You can paste a short description, a bullet list, or a long spec.  
- **What helps most:** (a) What the user should see or do, (b) what should be stored (e.g. “we need to track X per property”), (c) any constraints (“don’t change existing Office dashboards”).  
- I’ll turn it into: a spec in `docs/specs/`, schema/migrations if needed, and **Lovable prompts** in `docs/lovable-prompts/` that you can paste into Lovable.  
- If something already exists (e.g. a spec file or a table), mention it or say “align with the Data Library spec” so I reuse it.

**3. No fixed prompt format**  
- You don’t need a special template. Just describe what you want; I’ll structure the Lovable prompt (and any backend steps) and save it in the backend repo.

**4. Branches**  
- **Use a branch** when you want to try a feature (e.g. “create a branch for DC dashboards work”) so main stays stable. Tell me the branch name if you want docs/commits to reference it.  
- **I don’t create or switch branches** unless you ask (e.g. “create branch feature/meters-ui”). For day-to-day spec and prompt work, working on main is fine unless you prefer a branch.

**5. After I produce something**  
- **Backend:** I create/update files in Secure-SoR-backend. You run migrations in Supabase, paste Lovable prompts into Lovable, and sync the Lovable repo as usual.  
- **Lovable repo:** I don’t edit it unless you ask (e.g. “check Lovable and fix the Back button”). All normal UI changes go through prompts you paste into Lovable.

**6. One place to look**  
- **Specs:** `docs/specs/*.md`. Feature-level specs must include the 10 sections in [docs/specs/SPEC-TEMPLATE.md](specs/SPEC-TEMPLATE.md); see Cursor rule `spec-structure.mdc`.  
- **Prompts for Lovable:** `docs/lovable-prompts/` (see [lovable-prompts/README.md](lovable-prompts/README.md) for index)  
- **Schema / DB:** `docs/database/schema.md`, `docs/database/migrations/`  
- **Route map:** `docs/APP-ROUTE-MAP.md`  
- **Alignment (Lovable vs backend):** `docs/LOVABLE-BACKEND-ALIGNMENT.md`, `docs/BACKEND-VS-LOVABLE-UI-ALIGNMENT.md`

---

## Difference between `docs/sources` and `docs/specs`

| | **`docs/sources`** | **`docs/specs`** |
|---|-------------------|------------------|
| **Purpose** | **Reference / input** material. External or legacy specs, handoffs, sample data, strategy/positioning docs, and context that the backend team uses but does not “own” as the single source of truth. | **Canonical specs** the backend owns. Define what to build, routes, data model, and behaviour. Drive migrations, Lovable prompts, and schema docs. |
| **Content** | **Strategy/positioning** (e.g. `Secure_platform-strategy-building-data-infrastructure.md`). Lovable-origin docs, versioned handoffs (e.g. `Secure_KPI_Coverage_Logic_Spec_v1.md`, `Secure_Emissions_Engine_*`), taxonomy/architecture drafts, and **sample data** (e.g. `140-aldersgate/building-systems-register.md`). See [docs/sources/README.md](sources/README.md). | Product specs (e.g. `secure-dc-spec-v2.md`, `data-library-specifications.md`, `esg-report-specifications.md`, `dc-dashboard-specifications.md`) and **implementation guides** (e.g. `implementation-guide-phase-*-dc.md`). |
| **Who updates** | Updated when new reference material arrives (e.g. new handoff, new Lovable export). Not the place for “how we implement” — that lives in specs. | Updated as part of implementation: new features get a spec (or section) in `specs/`; implementation guides and Lovable prompts reference these. |
| **Referenced by** | Specs and implementation guides may *reference* sources (e.g. “see sources/Secure_Data_Library_Taxonomy_v3…” or “seed data from sources/140-aldersgate/…”). Migrations and prompts point at **specs**, not sources. | Schema, migrations, `lovable-prompts/*.md`, and other docs point at **specs** as the authority (e.g. “per docs/specs/secure-dc-spec-v2.md”). |

**Rule of thumb:** **Specs** = what we’re building and how (canonical). **Sources** = where it came from or what we’re building from (reference only).

---

## Backend mode vs Agent mode — which folders to use

- **Backend mode (this repo: Secure-SoR-backend):**
  - **Use / keep up to date:** Everything in this repo. Specs go in `docs/specs/`. Implementation guides in `docs/specs/` (e.g. `implementation-guide-phase-*.md`). Lovable prompts in `docs/lovable-prompts/` (see [lovable-prompts/README.md](lovable-prompts/README.md)). Migrations in `docs/database/migrations/`. Schema docs: `docs/database/schema.md`, `docs/database/supabase-schema.sql`. Data model / taxonomy: `docs/data-model/`.
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
     - **Lovable prompts** — ready-to-paste instructions for the UI (save as `docs/lovable-prompts/LOVABLE-PROMPT-<name>.md`).
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
| New UI flow         | `docs/lovable-prompts/*.md` (new or updated), implementation guide in `docs/specs/` |
| New spec / feature  | `docs/specs/*.md` (spec + implementation guide), step-by-step in guide, then prompts + migrations from it |
| Taxonomy / enums    | `docs/data-model/*.md` (e.g. space-types-taxonomy, building-systems-taxonomy), schema.md if needed |

All of the above live in **Secure-SoR-backend**. Agent repo stays in sync by reading backend docs (e.g. context shape, API contract); backend repo is the source of truth for schema and product behaviour.

**Audit (routes, components, automation gaps):** [docs/AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md) — lists route alignment (backend vs agent), component inconsistencies (spaces tiles, upload flows, tenant/landlord sections), and automation gaps (broken first, then missing, then cosmetic). §5 maps each gap to backend action and existing Lovable prompt where applicable.

---

## Four workspace roots — declare mode so files stay aligned

The workspace has **four roots**. All instructions (including Lovable prompts for the Secure app) are given from here. To keep files aligned and avoid editing the wrong folder, **declare which mode you’re in** when it matters.

| Root | Purpose | When I work here |
|------|--------|-------------------|
| **Secure-SoR-backend** | Backend logic for Secure: schema, migrations, specs, **Lovable prompts**. Source of truth for app behaviour and prompts. | Default for specs, migrations, schema docs, and **all Lovable prompts** (created and updated here). |
| **Lovable** | The Lovable (frontend) repo for Secure; kept up to date by applying the prompts created in the backend. | When you ask to align or compare Lovable code with backend specs, or to fix frontend code to match a spec. |
| **AI Agents** | AI agents that run on the platform; they use data from the platform DB and power the AI agents module. | When you ask for agent logic, agent docs, or context/API alignment with the backend. |
| **Newsletter** | Newsletter project; used rarely. | Only when you explicitly ask for something in the Newsletter root. |

**How to declare mode**

- At the start of a task, say e.g. **“We’re on backend”** or **“Backend mode”** → I only create/edit files in **Secure-SoR-backend** (specs, prompts, migrations, schema). I do not touch Lovable, AI Agents, or Newsletter.
- Say **“We’re on Lovable”** or **“Check Lovable against the spec”** → I work in the **Lovable** root (and may read backend specs for alignment). I don’t add new prompts to the backend unless you ask.
- Say **“We’re on AI Agents”** or **“Agent mode”** → I work in the **AI Agents** root; schema/API context is read from the backend. I don’t edit backend migrations or Lovable prompts.
- If you don’t specify, I assume **backend mode** (specs and Lovable prompts in Secure-SoR-backend). For tasks that span two roots (e.g. “sync Lovable with the ESG spec”), I’ll work in both as needed and say which roots I’m touching.

**Do I work on all 4 at once?**

No. I only work in the root(s) that match your instruction and the mode you set. Typical pattern: **one primary root per task** (usually backend); second root only when you ask for alignment or cross-repo changes (e.g. backend + Lovable).

**Keeping things aligned**

- **Lovable prompts** are always created and stored in **backend** (`docs/lovable-prompts/`, `docs/specs/`). You paste them into Lovable (the product) to update the Lovable repo.
- **Lovable repo** (the folder) should reflect what those prompts and backend specs describe; when you add it to the workspace, we can compare and fix mismatches (e.g. [LOVABLE-BACKEND-ALIGNMENT.md](LOVABLE-BACKEND-ALIGNMENT.md)).
- **AI Agents** code and docs should reference backend schema and API; backend remains source of truth for data shape and behaviour.

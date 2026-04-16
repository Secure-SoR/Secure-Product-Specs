# Docs structure — Secure-SoR-backend

This file describes how the `docs/` folder is organized so you can find things quickly and know where to add new content.

---

## At a glance

| Folder / area | Purpose |
|---------------|---------|
| **specs/** | Canonical feature specs and implementation guides (what we build; source of truth). |
| **lovable-prompts/** | Ready-to-paste prompts and fix instructions for the Lovable (frontend) app. |
| **sources/** | Reference material: strategy, handoffs, sample data (input to specs; not the authority). |
| **database/** | Schema documentation and SQL migrations for Supabase. |
| **data-model/** | Domain taxonomies and data-model docs (spaces, systems, nodes, accounts). |
| **architecture/** | System architecture, boundary logic, coverage, risk (platform layer). |
| **modules/** | Per-module documentation: the application layer on top of the foundation (Data Library, Property section, Account settings / user profile, Evidence Store, Boundary Engine). Strategy: [sources/](sources/). |
| **for-agent/** | Context and tasks for the AI Agents module; copy this folder into the agent project. |
| **templates/** | Reusable templates (e.g. seed data JSON). |
| **releases/** | Release notes and version history. |
| **Top-level .md files** | Cross-cutting docs: route map, audit/gaps, workflow, alignment, one-off guides. |

---

## 1. specs/ — What we build (canonical)

**Use for:** Feature-level specifications and implementation guides. These are the **source of truth** for behaviour, routes, and data.

- **SPEC-TEMPLATE.md** — Template every feature spec must follow (10 sections).
- **secure-dc-spec-v2.md** — Data Centre asset type (property, spaces, dashboards, SitDeck).
- **dc-dashboard-specifications.md** — DC dashboard KPIs, routes, content per dashboard.
- **data-library-specifications.md** — Data Library: layers, routes, record model, evidence, access.
- **esg-report-specifications.md** — ESG Report / Sustainability Reporting: routes, screens, data sources, export.
- **implementation-guide-phase-*-dc.md** — Step-by-step DC implementation guides (phase 1–4).

When you add a **new feature**, add a spec here (and follow SPEC-TEMPLATE). Migrations and Lovable prompts reference these files.

---

## 2. lovable-prompts/ — Instructions for Lovable (frontend)

**Use for:** Every prompt or fix instruction you **paste into Lovable** to implement or fix UI.

- **README.md** — Index of all prompts by feature (Data Centre, Spaces, ESG, Data Library, etc.).
- **LOVABLE-PROMPT-*.md** — One file per prompt (e.g. DC spaces sync, dashboards filter, tenancy selector, ESG back button).
- **lovable-fix-*.md**, **lovable-evidence-*.md** — Fix and evidence-related instructions.
- **nodes-implementation.md** — End-use nodes implementation prompts.

**Not here:** LOVABLE-BACKEND-ALIGNMENT.md and LOVABLE-PUBLIC-PAGE-COPY stay in `docs/` (alignment/copy reference).

---

## 3. sources/ — Reference and input material

**Use for:** Strategy, positioning, handoffs, Lovable-origin specs, and sample data. These inform specs but are **not** the implementation authority.

- **README.md** — Explains what belongs in sources.
- **Secure_platform-strategy-building-data-infrastructure.md** — Platform strategy (primitives, modules, horizons, GTM).
- **Secure_*_v1.md**, **lovable-data-library-spec.md**, **lovable-data-library-context.md** — Versioned handoffs and Lovable-derived context.
- **140-aldersgate/** — Sample data (building-systems-register, bills-register) for testing/seeding.

See CURSOR-MEMORY-AND-WORKFLOW.md § Difference between docs/sources and docs/specs.

---

## 4. database/ — Schema and migrations

**Use for:** Everything about the Supabase/Postgres schema.

- **schema.md** — Human-readable schema (tables, columns, relationships, RLS).
- **supabase-schema.sql** — Runnable SQL for a fresh install.
- **migrations/** — One-off migration scripts (e.g. add-dc-metadata.sql, add-tenancy-type, add-insert-system-from-register-rpc.sql). Run in Supabase SQL Editor when needed.

When you add a **new table or column**, add a migration, then update schema.md and (if applicable) supabase-schema.sql.

---

## 5. data-model/ — Domain and taxonomies

**Use for:** Domain concepts, enums, and taxonomies that span features.

- **building-systems-taxonomy.md** — System categories and types (Power, HVAC, Lighting, etc.).
- **space-types-taxonomy.md** — Space types and classes.
- **end-use-nodes-spec.md** — End-use nodes (node categories, utility types).
- **nodes-attribution-and-control.md**, **account.md** — Attribution and account model.

---

## 6. architecture/ — System design (platform layer)

**Use for:** High-level architecture and cross-cutting design. Describes the **platform layer**: primitives, boundary logic, coverage, risk. The strategy (see [sources/](sources/)) defines the **module layer** as applications that consume these primitives.

- **architecture.md** — Current stack, domain entities, gap matrix, migration path.
- **landlord-tenant-boundary-logic.md** — Boundary and stakeholder logic.
- **coverage-and-applicability-for-agent.md**, **data-confidence-and-risk-matrix.md** — Coverage and risk concepts.
- **system-overview.md** — System overview.

---

## 7. modules/ — Application layer (modules on top of the foundation)

**Use for:** Per-module documentation. Per the [platform strategy](sources/Secure_platform-strategy-building-data-infrastructure.md), the **foundation** is **Data Library**, **Property section**, **Account settings / user profile**, **Evidence Store**, and **Boundary Engine** (primitives in architecture/); **modules** are built on top. **Canonical list:** [modules/MODULE-LIST.md](modules/MODULE-LIST.md) — all platform modules with **Built** / **Partial** / **Pending** status.

**Consumption logic:** Modules feed from the foundation; they can also consume other modules (e.g. Reports ← AI Agents). **Module vs feature** is to be clarified for **Stakeholders Management** and **Dashboards** (see [modules/README.md](modules/README.md) § Module vs feature).

**Platform modules:** Reports (partial — ESG only), Projects, Net Zero, Stakeholders Management, Asset Tracking, Digital Twin, Automation, AI Agents (built), Diagnosis, Risk & Finance, Valuation Impact. Each module consumes primitives and must follow the five module rules (consume don’t duplicate, write back, respect boundary, audit trail, strengthen a primitive).

- **README.md** — Purpose of this folder; full module list with status; pointers to specs.
- **MODULE-LIST.md** — Canonical table: module name, strategy alignment, status, primitives, spec (referenced by AUDIT §7.4 and §7.5).
- **reports.md** — Reports module (Sustainability Reporting); partial build; spec: [specs/esg-report-specifications.md](specs/esg-report-specifications.md).

Detailed feature specs live in **specs/** (DC, ESG, Data Library). This folder holds module-level overviews and the single source of truth for which modules are built vs pending.

---

## 8. for-agent/

**Use for:** Context and task handoffs for the **AI Agents** module (external agent API that consumes platform data). **Single folder:** copy **`docs/for-agent/`** into the agent project so the agent has one instruction set.

- **README.md** — How to use this folder; Phase 2/3/5 sync notes (properties, spaces, data library, context).
- **INSTRUCTIONS.md**, **CONTEXT-SOURCE.md**, **AGENT-TASKS.md**, **BACKEND-SYNC-NOTES.md**, **COVERAGE-AND-APPLICABILITY-FOR-AGENT.md** — What the agent should do, context shape, to-do, sync notes, coverage logic.
- **HANDOFF-FOR-AGENT.md** — How to point the agent at this backend.

---

## 9. templates/ and releases/

- **templates/** — Reusable artefacts (e.g. seed JSON for nodes). See templates/README.md.
- **releases/** — Release notes (e.g. v5.1.0). Version history.

---

## 10. Top-level docs (in docs/)

| File | Purpose |
|------|---------|
| **CURSOR-MEMORY-AND-WORKFLOW.md** | How to work with Cursor: backend vs agent mode, sources vs specs, where prompts live, declare mode. |
| **APP-ROUTE-MAP.md** | Single source of truth for app routes (entry, auth, data library, reports, dashboards). |
| **AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md** | Route alignment, component gaps, automation gaps, **strategy alignment** (§7), **combined to-do** (§7.5). Main place for "what's broken, what's missing, what to build." |
| **BACKEND-VS-LOVABLE-UI-ALIGNMENT.md** | Backend vs Lovable UI: what's aligned, what's not built yet. |
| **LOVABLE-BACKEND-ALIGNMENT.md** | Code-level alignment (routes, back button, access IDs, DC dashboards). |
| **DATA-LIBRARY-RECORDS-VS-PROOFS-AND-DC-DASHBOARDS.md** | Records vs proofs, shared upload, data flow to DC dashboards. |
| **data-library-implementation-context.md** | Data Library implementation context for Lovable. |
| **data-library-routes-and-responsibilities.md** | Per-route responsibilities and engine relationships. |
| **METERS-INFRASTRUCTURE.md** | Meters table, relationship to systems, what's built in UI. |
| **DC-DASHBOARD-SPECS-FOR-LOVABLE.md** | DC dashboard specs formatted for Lovable. |
| **DOCS-STRUCTURE.md** | This file. |

---

## 11. Where to put something new

| If you're adding… | Put it in… |
|--------------------|------------|
| A new **feature spec** | specs/ (use SPEC-TEMPLATE; 10 sections). |
| A **Lovable prompt** | lovable-prompts/ (add to README index). |
| **Strategy** or **handoff** from elsewhere | sources/ (see sources/README.md). |
| A **migration** (new table/column/RPC) | database/migrations/; then update database/schema.md. |
| **Taxonomy** or domain enum | data-model/ or the relevant spec. |
| **Architecture** or system design | architecture/. |
| **Module-level** overview (platform vs module boundary) | modules/. |
| **Agent** context or tasks | for-agent/. |
| **Release notes** | releases/. |
| **Cross-cutting** doc (routes, audit, workflow) | Top-level docs/. |

---

## 12. Quick links

- **Route map:** APP-ROUTE-MAP.md
- **Gaps and to-do:** AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md §7.5
- **Workflow and where things live:** CURSOR-MEMORY-AND-WORKFLOW.md
- **All Lovable prompts (index):** lovable-prompts/README.md
- **Schema:** database/schema.md
- **Spec template (10 sections):** specs/SPEC-TEMPLATE.md

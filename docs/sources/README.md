# docs/sources — reference and input material

This folder holds **reference material** the backend team uses but does not maintain as the single source of truth for implementation. See [CURSOR-MEMORY-AND-WORKFLOW.md](../CURSOR-MEMORY-AND-WORKFLOW.md) § Difference between docs/sources and docs/specs.

**What belongs here:**

- **Strategy and positioning** — e.g. [Secure_platform-strategy-building-data-infrastructure.md](Secure_platform-strategy-building-data-infrastructure.md). Used to align specs and roadmap; implementation is driven by `docs/specs/` and the audit/gaps doc.
- **Lovable-origin specs** — Detailed UI/screen specs exported from or produced with Lovable (e.g. lovable-data-library-spec.md). Canonical feature behaviour is in `docs/specs/`.
- **Versioned handoffs** — External or legacy specs (e.g. Secure_KPI_Coverage_Logic_Spec_v1.md, Secure_Emissions_Engine_*). Referenced by specs; migrations and schema live in `docs/database/`.
- **Sample / seed data** — e.g. 140-aldersgate building-systems-register, bills-register. Used for testing or seeding; not the canonical schema.

**What does not belong here:** Canonical feature specs, implementation guides, or schema definitions — those live in `docs/specs/` and `docs/database/`.

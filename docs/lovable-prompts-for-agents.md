# Lovable prompts for the AI agents module (pointer)

The **platform** (this backend repo) is **independent** and can be sold without AI agents. The **AI agents** are a **module on top** of the platform.

**Lovable prompts** that wire the platform to the agent module (property dropdown, tiles, API URL, full fix) live in the **AI Agents** repo, not here. They are part of the **agent module integration**, not the platform itself.

- **Where to find them:** In the AI Agents repo: **`agent/docs/LOVABLE-PROMPTS-FOR-AGENTS.md`** (and `lovable.md`, `LOVABLE-FIX-PROPERTY-SWITCH-AND-CONTEXT.md` at the repo root).
- **What stays in this repo:** Platform schema, data model, implementation plans, and **evidence in the platform** (e.g. [step-by-step-evidence-in-context.md](step-by-step-evidence-in-context.md) for Part 1 DB + Part 2 how to build the evidence array from platform data when the agent module is used — that’s the **contract** between platform and agent; the prompts that tell Lovable to implement it are in the AI Agents repo).

**Summary:** Backend folder = platform only, kept up to date for “platform without agents.” AI Agents folder = agent logic + integration (context shape, Lovable prompts to add the module on top).

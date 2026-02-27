# Backend (platform) vs AI Agents module

**Correct split:**

| | **Backend folder (this repo)** | **AI Agents folder** |
|---|-------------------------------|----------------------|
| **What it is** | The **platform** — app built with Lovable and Cursor. Independent; can be sold **without** AI agents. | The **AI agents module** — sits **on top** of the platform. Described to work with the platform’s structure. |
| **Owns** | Schema, data model, Supabase, implementation plans, app flows (data library, properties, spaces, systems, evidence in DB). Platform behaviour. | Agent logic, agent API, agent types. **Integration:** context shape the agent expects, and Lovable prompts to wire the platform to call the agent. |
| **When something is wrong** | Change is to the **platform** (app behaviour, schema, data, flows) → update **backend** folder. Keep it up to date so “platform only” is complete. | Change is to **agent behaviour** (agent doesn’t do something well) → update **AI Agents** folder. |
| **Lovable prompts** | Only the **platform/contract** side: e.g. how to build the evidence array from platform data (step-by-step-evidence-in-context.md). The platform must support the **contract** (context shape) when the agent module is used. | **All wiring prompts:** property dropdown, tiles, API URL, full fix. See `agent/docs/LOVABLE-PROMPTS-FOR-AGENTS.md` and `lovable.md`. |

**Summary:** Backend = platform only, independent. AI Agents = agent module + “how to add this module to the platform” (prompts to paste into Lovable). So the backend folder is always up to date for someone who says “I want to buy just the platform without AI agents.”

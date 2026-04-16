# Lovable prompt: Restore Construction & Envelope tile

**Use this when:** The Physical and Technical area (property or onboarding) shows only "Building systems" and the **Construction & Envelope** tile has disappeared. We need **two** tiles: (1) Construction & Envelope, (2) Building systems.

**Canonical requirement:** [implementation-plan-lovable-supabase-agent.md](implementation-plan-lovable-supabase-agent.md) — "Physical and Technical — Two tiles: Construction & Envelope + Building systems".

---

## Prompt to paste into Lovable

```
The Physical and Technical area (e.g. under a property, or in the onboarding/setup flow) must show TWO tiles or sections:

1. **Construction & Envelope** — For building fabric, envelope, and EPC-related data (e.g. construction type, façade, insulation, EPC certificate). This is separate from building systems.

2. **Building systems** — For the systems taxonomy (Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Lifts, Monitoring) and the building systems register.

Currently only "Building systems" appears; the **Construction & Envelope** tile is missing. Please restore it so that both tiles are visible in the same place where Building systems is shown (e.g. two cards, two sections, or two nav items). Users should be able to open Construction & Envelope and Building systems separately. The Construction & Envelope tile can link to a page or section that holds building fabric / envelope / EPC data (if that page was removed, restore it; if it never had a dedicated backend, a placeholder or simple form is fine for now). The important thing is that both tiles exist again and are visible next to each other.
```

---

## Why it likely disappeared

- A refactor (e.g. when adding the public landing page or fixing routing) may have simplified the Physical and Technical area to a single "Building systems" block.
- The backend spec had only documented Building systems in detail; Construction & Envelope was part of the intended UI but not called out in the implementation plan until now. Restoring both tiles aligns the app with the intended structure (construction/envelope vs systems).

---

## If the app crashes after applying this prompt

Lovable sometimes generates invalid code (e.g. escaped newlines `\\n` or broken JSX in `ConstructionEnvelopeSection.tsx`), which can make the app fail to load any page. **Recovery prompt:** [LOVABLE-PROMPT-FIX-CRASH-AFTER-CONSTRUCTION-ENVELOPE.md](LOVABLE-PROMPT-FIX-CRASH-AFTER-CONSTRUCTION-ENVELOPE.md) — use it to revert the Construction & Envelope changes and restore a working app, then re-add the tile later with a minimal implementation.

---

## After Lovable restores it

- Confirm both tiles are visible and that Construction & Envelope opens a distinct view (or placeholder) from Building systems.
- If Construction & Envelope needs its own route (e.g. `/property/:id/construction-envelope`), add it to the app route map or data-library-style docs if relevant.

# Lovable prompt — SitDeck OSINT embeds on Data Centre property view

**Filename:** Canonical copy lives in [docs/lovable-prompts/LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md](../lovable-prompts/LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md). **Keep this file in sync** with that copy.

**Use when:** [implementation-guide-phase-3-dc.md](./implementation-guide-phase-3-dc.md) Step 3.4.

---

## Prompt (copy everything inside the fence)

```
Data Centre — SitDeck OSINT on the single-property overview

Target page: the main Data Centre property dashboard / overview (e.g. `/dashboards/data-centre/:propertyId`) — the first screen after choosing a DC property from the Data Centre dashboards landing, not only the separate Risk Intelligence sub-routes.

## Behaviour

1. Add a clearly labelled section on that overview (e.g. "Risk intelligence" or "SitDeck OSINT") with three areas:
   - Geopolitical & conflict risk
   - Climate & natural hazard risk
   - Cyber & critical infrastructure risk

2. Implement each area using **SitDeck’s official embed method** only (as documented by SitDeck: iframe embed URL, JS SDK, or React component — use whatever they publish). Do not invent embed URLs.
   - Obtain the exact embed pattern (base URL, path, query parameter names for map centre, widget type, theme, tokens) from SitDeck’s developer documentation, embed/share UI inside SitDeck, or SitDeck support.
   - Pass the current property’s **latitude** and **longitude** from `properties.latitude` and `properties.longitude` into the embed exactly as SitDeck requires (e.g. `lat`/`lng`, `center`, postMessage init — follow their docs).
   - If SitDeck requires an embed token or signed URL, obtain it via the same secure path used for the SitDeck connector (e.g. Edge Function that reads the stored credential and returns a short-lived embed token or full embed URL). Never expose the raw API token in the client or in git.

3. **Visibility gate — show the entire SitDeck section only when ALL are true:**
   - SitDeck is **connected** for this account (same boolean / API you already use after Connect in Data Library → Connectors; e.g. Edge Function `sitdeck-status` or equivalent).
   - `properties.latitude` is a valid finite number (not null/undefined/empty).
   - `properties.longitude` is a valid finite number (not null/undefined/empty).

   If SitDeck is not connected OR lat/lng are missing or invalid:
   - Do **not** render empty iframes or broken embeds.
   - Optionally show one short inline message (e.g. "Connect SitDeck in Data Library → Connectors and set latitude/longitude for this property to see risk intelligence") — keep it subtle so the overview stays usable.

4. **Optional refinement:** If `sitdeck_risk_config` has a row for this `property_id` and `active_widget_types` is a non-empty array, you may hide a widget whose type is not listed — only if SitDeck’s type strings are known and mapped. If unsure, show all three widgets whenever the gate in (3) passes.

5. **Deep-link routes:** If the app already has `/dashboards/data-centre/:propertyId/geopolitical`, `/climate-hazard`, `/cyber-infrastructure`, reuse the same embed URL/builder logic in a shared helper so behaviour stays consistent; the **overview** must still contain the three embeds per this prompt.

6. Accessibility and layout: responsive height for iframes (min-height + aspect or fixed sensible height), `title` on iframes, loading state while embed token/URL is fetched.

## Done when

- On `/dashboards/data-centre/:propertyId` (DC property overview), the three SitDeck OSINT widgets appear when SitDeck is connected and lat/lng are set; they are centred on that property’s coordinates per SitDeck’s embed API.
- When not connected or coordinates missing, no SitDeck embeds are mounted.
```

---

## Related docs

- [implementation-guide-phase-3-dc.md](./implementation-guide-phase-3-dc.md)
- [LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md](./LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md)
- [LOVABLE-PROMPT-PROPERTY-LAT-LNG.md](./LOVABLE-PROMPT-PROPERTY-LAT-LNG.md)

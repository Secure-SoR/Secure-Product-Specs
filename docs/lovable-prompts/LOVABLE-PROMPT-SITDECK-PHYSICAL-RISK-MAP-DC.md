# Lovable prompt — SitDeck physical risk map (DC property / risk view)

**Use when:** [implementation-guide-phase-3-dc.md](../specs/implementation-guide-phase-3-dc.md) Step 3.5 — embed SitDeck’s **physical risk map** (flood, wildfire, extreme weather, etc.) on the data centre **property or risk** view; drive visibility from `sitdeck_risk_config.active_widget_types`.

**Prerequisites:** [LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md](LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md) (connector, Refresh → `sitdeck_risk_config`), [LOVABLE-PROMPT-PROPERTY-LAT-LNG.md](LOVABLE-PROMPT-PROPERTY-LAT-LNG.md), [LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md](LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md) (same embed-security patterns).

**Duplicate for IDE links:** [../specs/LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md](../specs/LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md) — keep both in sync.

**Spec:** [secure-dc-spec-v2.md](../specs/secure-dc-spec-v2.md) §10 (physical risk / `sitdeck_risk_config`); Phase 4 will consume this for Risk Diagnosis — see [implementation-guide-phase-4-dc.md](../specs/implementation-guide-phase-4-dc.md) when available.

---

## Prompt (copy everything inside the fence)

```
Data Centre — SitDeck physical risk map (config-driven)

## Where to show it

On the **data centre property risk surface**: either a dedicated **Risk** tab/section on the single DC property view (e.g. under `/dashboards/data-centre/:propertyId`), or your existing **Risk** route for that property — choose the place product already uses for DC risk. Label the panel clearly (e.g. "Physical risk map" / "Hazards near this asset").

## Data — sitdeck_risk_config

Load one row for the current property:

- `supabase.from('sitdeck_risk_config').select('active_widget_types, last_synced_at').eq('property_id', propertyId).maybeSingle()`

Table already exists (migration); do not create it from Lovable.

**Canonical type string for this widget:** treat the physical risk map as active when `active_widget_types` is a **non-null array** that includes **`physical_risk_map`** (or an equivalent string returned by your SitDeck Refresh mapping — keep a single constant e.g. `PHYSICAL_RISK_MAP = 'physical_risk_map'` and map SitDeck API labels to it in the Refresh Edge Function). If SitDeck returns only their own slugs, store those in `active_widget_types` and check for the slug you mapped for the physical map widget.

**When NOT to render the embed:**

- No row for this `property_id`, OR
- `active_widget_types` is null or empty, OR
- The array does not include the physical risk map type (after mapping), OR
- SitDeck is not **connected** for the account (same signal as other SitDeck embeds), OR
- `properties.latitude` / `properties.longitude` are missing or not finite numbers.

In those cases, do not mount an iframe/SDK. Optional short hint: "Connect SitDeck in Data Library → Connectors, run Refresh, and set property coordinates" where it fits your UX.

## Embed implementation

- Use **SitDeck’s official embed method** for the physical risk / hazards map widget (iframe, SDK, or signed URL — per SitDeck docs only). Do not guess embed URLs.
- Centre the map on `properties.latitude` and `properties.longitude` using SitDeck’s documented parameters.
- If an embed token or signed URL is required, fetch it via the same secure server path as other SitDeck embeds (Edge Function + stored credential); never ship raw API tokens to the client.

## Phase 4 — Risk Diagnosis (forward-compatible)

- Keep the embed logic in a **small dedicated component** (e.g. `SitDeckPhysicalRiskMap`) so Phase 4 can reuse the same property + config reads for **Risk Diagnosis** (e.g. linking `physical_risk_flags` / diagnosis UI to the same SitDeck surface). Add a brief code comment: `// Phase 4: Risk Diagnosis may consume sitdeck_risk_config + this widget context`.
- Do not build Risk Diagnosis schema/UI in this task — only embed the map when config says so.

## Done when

- On the DC property/risk view, the physical risk map appears **only when** SitDeck is connected, lat/lng are set, and `sitdeck_risk_config.active_widget_types` includes the physical map type.
- Refresh from Connectors updates `active_widget_types` and the panel shows/hides accordingly.
```

---

## After Lovable implements

- Ensure the SitDeck **Refresh** path writes `physical_risk_map` (or your chosen slug) into `active_widget_types` when that widget is enabled in SitDeck.
- Test: array without physical type → no embed; with it → embed loads centred on property.

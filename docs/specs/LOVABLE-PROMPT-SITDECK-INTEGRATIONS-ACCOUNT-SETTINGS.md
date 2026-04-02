# Lovable prompt — SitDeck connector (Data Library → Connectors)

**Filename note:** `LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md` is kept for stable links; **entry point is Data Library → Connectors**, not Account Settings → Integrations.

**Same content as** [../lovable-prompts/LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md](../lovable-prompts/LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md) — this copy lives **next to** [implementation-guide-phase-3-dc.md](./implementation-guide-phase-3-dc.md) so Step 3.2 can link with `./` (reliable in Cursor). Keep both files in sync when editing.

**Use when:** Step 3.2 — one SitDeck (OSINT) connector in Data Library → Connectors; token stored securely; widget config per property in `sitdeck_risk_config`.  
**Schema:** [schema.md](../database/schema.md) §3.4b · **Migration:** [add-sitdeck-risk-config.sql](../database/migrations/add-sitdeck-risk-config.sql)

---

## Prompt (copy everything inside the fence)

```
In Data Library → Connectors, add SitDeck as one connector in the connectors list: Connect (store token in secrets via Vault / Edge Function), Disconnect, optional Refresh to update active widget types. Use sitdeck_risk_config table.

Do not use Account Settings → Integrations as the primary place for SitDeck unless product explicitly wants a duplicate entry — canonical UX is Data Library → Connectors alongside other data connectors.

Expand as follows. This is the single SitDeck (OSINT) integration for Phase 3 — do not add a separate “DCIM” connector.

## Database (public, RLS)

Table `sitdeck_risk_config` (already created by backend migration — do not create tables from Lovable):
- id (uuid), account_id (uuid), property_id (uuid), UNIQUE(property_id)
- active_widget_types (text[] | null) — identifiers for enabled widget types (e.g. geopolitical, climate_hazard, cyber_infrastructure, physical_risk_map — align names with SitDeck embed docs when you integrate)
- last_synced_at (timestamptz | null)
- created_at, updated_at

RLS: rows are visible only to users who are members of the row’s account_id. Use the current user’s account_id from your existing app context (same pattern as properties, dc_metadata).

## Token storage (must NOT go in sitdeck_risk_config)

- Never store the SitDeck API token or OAuth refresh token in a public table or in client-side code.
- Preferred: Supabase **Vault** or a **Supabase Edge Function** that (1) accepts the token once over HTTPS from an authenticated user, (2) stores it server-side (Vault secret or encrypted), (3) exposes only “connected / not connected” to the client. If Vault/Edge Function is not built yet, implement the UI and `sitdeck_risk_config` reads/writes, and call a placeholder `invoke('sitdeck-save-token')` / `invoke('sitdeck-disconnect')` that you will wire later — but document that production requires the secret path.
- The connector row may show “Connected” based on a small account-level flag you derive from Edge Function or a `vault`-backed check — avoid storing booleans with the raw token in plain columns.

## UI — SitDeck row in Connectors

1. Place SitDeck in the **Data Library → Connectors** screen (same pattern as other connector rows: name, status, actions).
2. Title: e.g. “SitDeck” with short subtitle: OSINT / risk intelligence for data centre properties.
3. **Connect:** Opens a modal; user pastes API token (or OAuth button if SitDeck provides it). On submit, call your secure path (Edge Function) to persist the token. Then show Connected state on the connector row.
4. **Disconnect:** Clears the stored credential via Edge Function (or Vault delete); show Disconnected state. Do not delete `sitdeck_risk_config` rows unless product wants a full reset — optional: clear active_widget_types / last_synced_at on disconnect.
5. **Refresh (optional):** Button “Refresh widget list”. Server-side (Edge Function recommended): read token from Vault, call SitDeck’s API per their documentation to discover active widget types, then for each property that should use SitDeck (e.g. properties where asset_type = 'data_centre', or all properties you support — match product choice), upsert into `sitdeck_risk_config`:
   - Match on property_id; set account_id from that property’s row in `properties`.
   - Set active_widget_types to the array returned (or mapped) from SitDeck.
   - Set last_synced_at = now().
   Use supabase.from('sitdeck_risk_config').upsert(..., { onConflict: 'property_id' }) or insert where missing and update where exists — PostgreSQL UNIQUE is on property_id only; ensure one row per property.

If the SitDeck API does not return per-property widget lists, use one account-level API response and write the same active_widget_types to each target property’s row (still one row per property).

## Client reads

- Where the app needs to know which widgets to embed (Phase 3.4–3.5), load `sitdeck_risk_config` for the current property_id (maybeSingle). If no row, treat as no config yet (show placeholder or hide widgets per existing DC dashboard prompts).

## Done when

- User can Connect / Disconnect SitDeck from Data Library → Connectors without putting secrets in `sitdeck_risk_config` or localStorage.
- Refresh (when implemented end-to-end) updates `active_widget_types` and `last_synced_at` for the chosen properties.
- All Supabase calls respect RLS (use authenticated supabase client).
```

---

## After Lovable implements

- Run migration [add-sitdeck-risk-config.sql](../database/migrations/add-sitdeck-risk-config.sql) in Supabase if not already applied.
- Implement or stub Edge Functions for token save/disconnect/refresh before production.
- Test: member of account A cannot read account B’s `sitdeck_risk_config` rows.

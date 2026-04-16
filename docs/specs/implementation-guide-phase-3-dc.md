# How to implement Phase 3 — SitDeck OSINT integration

This guide explains **what each step means** and **how to do it** in plain language. SitDeck in this phase is **OSINT only** (intelligence dashboard / risk widgets), not DCIM sync.

**Link from main spec:** [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) → Section 8.1 Phase 3

---

## Step 3.1 — Create sitdeck_risk_config table (migration)

**What it means:** We need a table to store, per property, which SitDeck risk widgets are active and when we last synced. The integration token is stored in Supabase secrets / Vault / Edge Function, not in this table.

**How to do it:**

- **Where:** Backend repo — migration file [add-sitdeck-risk-config.sql](../database/migrations/add-sitdeck-risk-config.sql). Logical schema: [schema.md](../database/schema.md) §3.4b.
- **Run:** Supabase Dashboard → SQL Editor → paste and run that file (idempotent policies). Greenfield installs that use the full [supabase-schema.sql](../database/supabase-schema.sql) already include this table.
- **If you use Cursor (already done in repo):** Migration defines `sitdeck_risk_config` with `account_id`, `property_id` **UNIQUE**, `active_widget_types text[]`, `last_synced_at`, timestamps, indexes, RLS by `account_id`.

**Done when:** Migration runs and the table exists.

---

## Step 3.2 — SitDeck connector in Data Library → Connectors

**What it means:** SitDeck is configured from **Data Library → Connectors** (alongside other data connectors), not from Account Settings → Integrations. Add **one** SitDeck connector row/card there. The user can connect (token/credentials — stored in Supabase secrets / Vault / Edge Function), disconnect, and optionally refresh to update which widget types are active. This is the single SitDeck (OSINT) connector for Phase 3, not a second DCIM integration.

**How to do it:**

- **Where:** Lovable app — **Data Library → Connectors** (or equivalent nav: Data Library, then a Connectors sub-section/tab).
- **UI:** One SitDeck connector in the connectors list with Connect / Disconnect (and optional Refresh). On Connect, prompt for token (or OAuth if SitDeck provides it); save via a **server-side** path (Edge Function + Vault recommended — never store the token in `sitdeck_risk_config` or client storage). On Refresh, call SitDeck (per their API) to get active widget types and upsert `sitdeck_risk_config` for the relevant property/properties (`active_widget_types`, `last_synced_at`).
- **Lovable (paste-ready):** [LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md](./LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md) *(filename is legacy; content describes Data Library → Connectors)*. Canonical copy also in [docs/lovable-prompts/](../lovable-prompts/LOVABLE-PROMPT-SITDECK-INTEGRATIONS-ACCOUNT-SETTINGS.md); **keep both in sync** if you edit.
- **If you use Cursor:**  
  *"In Data Library → Connectors, add SitDeck: Connect (store token in secrets), Disconnect, optional Refresh to update active widget types. Use sitdeck_risk_config table. Do not use Account Settings → Integrations as the primary place for SitDeck."*

**Done when:** User can connect and disconnect SitDeck from Data Library → Connectors; token is stored securely; refresh updates config.

**Where the SitDeck token comes from:** Secure does not create it. Obtain whatever credential SitDeck’s product expects (API key, embed token, client id/secret, or OAuth) from **your SitDeck account** and their official documentation or support — for example [sitdeck.com](https://sitdeck.com) and any developer or embed guides they provide. Paste or complete OAuth only through the Connectors Connect flow once implemented; never commit tokens to the repo or store them in `sitdeck_risk_config`.

---

## Step 3.3 — Edit latitude/longitude on Integrations & Evidence (or property settings)

**What it means:** SitDeck widgets need the property’s location (lat/lng). We added the columns in Phase 1; now we need a place in the app where the user can enter or edit latitude and longitude for a property (e.g. on "Integrations & Evidence" or property settings).

**How to do it:**

- **Where:** Lovable app — the page you use for "Integrations & Evidence" or the property settings/edit screen.
- **UI:** Two fields: Latitude, Longitude (numeric). Load/save from `properties.latitude` and `properties.longitude`. Optional for non-DC properties; especially important for data centre properties that use SitDeck.
- **DB:** Columns are `numeric` nullable — see [add-properties-lat-lng.sql](../database/migrations/add-properties-lat-lng.sql) if your Supabase project predates them.
- **Lovable (paste-ready):** [LOVABLE-PROMPT-PROPERTY-LAT-LNG.md](./LOVABLE-PROMPT-PROPERTY-LAT-LNG.md) · [lovable-prompts copy](../lovable-prompts/LOVABLE-PROMPT-PROPERTY-LAT-LNG.md)
- **If you use Cursor:**  
  *"On the Integrations & Evidence page (or property settings), add Latitude and Longitude fields, saved to properties.latitude and properties.longitude."*

**Done when:** User can set and save property lat/lng so widgets can use it.

---

## Step 3.4 — Embed SitDeck OSINT widgets on DC property view

**What it means:** On the data centre property view, embed SitDeck’s OSINT widgets (geopolitical, climate, cyber dashboards) so the user sees how global events relate to the asset. Widgets should be anchored to the property’s lat/lng (from Step 3.3). Use iframe or JS SDK as per SitDeck’s documentation.

**How to do it:**

- **Where:** Lovable app — single DC property overview (`/dashboards/data-centre/:propertyId`); add a clear "Risk intelligence" / SitDeck section with three embeds (not only the separate `/geopolitical`, `/climate-hazard`, `/cyber-infrastructure` routes).
- **Implementation:** Follow SitDeck’s embed docs (iframe or JS SDK). Pass the property’s latitude and longitude so the widget shows the right location. Show the embed section **only when** SitDeck is connected **and** `properties.latitude` / `properties.longitude` are set and valid; otherwise do not mount iframes (optional short CTA to connect + set coordinates).
- **Lovable (paste-ready):** [LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md](./LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md) · [lovable-prompts copy](../lovable-prompts/LOVABLE-PROMPT-SITDECK-EMBED-DC-PROPERTY-VIEW.md)
- **If you use Cursor:**  
  *"On the data centre property view, embed SitDeck OSINT widgets (geopolitical, climate, cyber) using their embed method. Use the property’s latitude and longitude. Only show when SitDeck is connected and lat/lng are set."*

**Done when:** DC property view shows SitDeck OSINT widgets tied to the property location.

---

## Step 3.5 — Physical risk map widget and link to Risk Diagnosis

**What it means:** Embed SitDeck’s physical risk map widget (flood, wildfire, extreme weather, etc.) on the property or risk view. The widget types that are active can be driven by `sitdeck_risk_config`. When Risk Diagnosis exists (Phase 4), this feeds into it; for now you can just show the widget.

**How to do it:**

- **Where:** Lovable app — DC property **Risk** tab/section or risk route for that property. Use `sitdeck_risk_config.active_widget_types` (e.g. includes `physical_risk_map` after Refresh maps SitDeck’s labels) plus SitDeck connected + property lat/lng before mounting the embed.
- **Lovable (paste-ready):** [LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md](./LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md) · [lovable-prompts copy](../lovable-prompts/LOVABLE-PROMPT-SITDECK-PHYSICAL-RISK-MAP-DC.md)
- **If you use Cursor:**  
  *"Embed SitDeck physical risk map widget on the DC property/risk view. Use sitdeck_risk_config to know which widget types are active. When Risk Diagnosis is built (Phase 4), this will feed into it."*

**Done when:** Physical risk map widget appears and is driven by config; ready to plug into Risk Diagnosis later.

---

## Step 3.6 — Optional: webhook for SitDeck alerts → agent_findings

**What it means:** If SitDeck can send webhooks when an alert fires (e.g. threshold breached), we can receive that and write a row to `agent_findings` so we have an audit trail. `agent_run_id` is nullable for these rows; `source = 'sitdeck'` distinguishes them from agent-run findings. **`account_id`** is required on every row so RLS can scope reads without a run.

**How to do it:**

### 3.6a — Database migration

- **Where:** Backend repo — [add-agent-findings-sitdeck-webhook.sql](../database/migrations/add-agent-findings-sitdeck-webhook.sql).
- **Run:** Supabase Dashboard → SQL Editor → paste and run (idempotent `DROP POLICY IF EXISTS` / `IF NOT EXISTS` where applicable).
- **What it does:** Backfills `account_id` from `agent_runs`, sets `NOT NULL` on `account_id`, adds `source` and `property_id`, makes `agent_run_id` nullable with a CHECK constraint, adds trigger `agent_findings_set_account_id` so existing clients that only send `agent_run_id` still get `account_id`, replaces RLS so members **read** all findings in their account (including SitDeck rows) and **insert** only via agent runs (webhook uses service role).
- **Greenfield:** Full [supabase-schema.sql](../database/supabase-schema.sql) already matches this shape.
- **Docs:** [schema.md](../database/schema.md) §3.13.

### 3.6b — Edge Function `sitdeck-webhook`

- **Where:** Supabase → Edge Functions → deploy function **`sitdeck-webhook`** (Deno via Editor, CLI, or AI Assistant). Canonical source in this repo: [supabase/functions/sitdeck-webhook/index.ts](../../supabase/functions/sitdeck-webhook/index.ts) (sync with Dashboard if you edit locally).
- **JWT verification must be OFF** for this function. SitDeck sends a **shared secret** in `Authorization: Bearer …`, not a Supabase user JWT. If JWT verification stays on, the gateway returns `401` with `Invalid Token or Protected Header formatting` before your code runs. In the Dashboard: open **`sitdeck-webhook`** → disable **Verify JWT** / **Enforce JWT verification** (wording varies), or redeploy with CLI `supabase functions deploy sitdeck-webhook --no-verify-jwt`.
- **Secrets (Dashboard → Project Settings → Edge Functions → Secrets):**
  - `SUPABASE_SERVICE_ROLE_KEY` — usually available by default in Edge Functions; if not, add it.
  - `SITDECK_WEBHOOK_SECRET` — long random string; you configure the same value in SitDeck’s webhook settings (or as a Bearer token SitDeck sends).
- **Register in SitDeck:** Webhook URL `https://<project-ref>.supabase.co/functions/v1/sitdeck-webhook` (or your custom domain). Method **POST** only (opening the URL in a browser sends GET → `405` `Method not allowed` from the handler). Align headers with the verification below.

**Request contract (adjust field names when SitDeck’s payload is known):**

- Verify caller: e.g. header `Authorization: Bearer <secret>` must equal `SITDECK_WEBHOOK_SECRET`, or verify `X-SitDeck-Signature` per SitDeck docs if they document HMAC.
- Body JSON must allow resolving **account_id**, e.g. **`property_id`** (UUID of a row in `properties`). The function loads `properties.account_id` for that id; reject if missing or not found.
- **`finding_type`:** use SitDeck’s event type field if present, else default `'sitdeck_alert'`.
- **`payload`:** store the full parsed JSON body (or a normalised object) in `agent_findings.payload`.

**Insert (service role client):**

```ts
await supabase.from("agent_findings").insert({
  agent_run_id: null,
  account_id: property.account_id,
  property_id: propertyId,
  source: "sitdeck",
  finding_type: findingType,
  payload: bodyAsJsonb,
});
```

**Starter template (paste into `supabase/functions/sitdeck-webhook/index.ts` and adapt to SitDeck’s real payload and signature):**

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const secret = Deno.env.get("SITDECK_WEBHOOK_SECRET");
  const auth = req.headers.get("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!secret || bearer !== secret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const propertyId = body.property_id as string | undefined;
  if (!propertyId) {
    return new Response(JSON.stringify({ error: "property_id required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data: property, error: propErr } = await supabase
    .from("properties")
    .select("account_id")
    .eq("id", propertyId)
    .maybeSingle();

  if (propErr || !property) {
    return new Response(JSON.stringify({ error: "Property not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const findingType =
    (typeof body.finding_type === "string" && body.finding_type) ||
    (typeof body.type === "string" && body.type) ||
    "sitdeck_alert";

  const { error: insErr } = await supabase.from("agent_findings").insert({
    agent_run_id: null,
    account_id: property.account_id,
    property_id: propertyId,
    source: "sitdeck",
    finding_type: findingType,
    payload: body,
  });

  if (insErr) {
    console.error(insErr);
    return new Response(JSON.stringify({ error: "Insert failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
```

**Product note:** If SitDeck cannot send your internal `property_id`, map their site/asset id in the Edge Function (e.g. join `dc_metadata.sitdeck_site_id`) or use a signed per-property token in the webhook path.

**Smoke test (curl):** Use **POST** with a real `properties.id` as `property_id`. If the gateway still rejects `Authorization`, add header `apikey: <Supabase anon public key>` (Project Settings → API). Example:

```bash
curl -sS -w "\nHTTP_STATUS:%{http_code}\n" -X POST \
  "https://<project-ref>.supabase.co/functions/v1/sitdeck-webhook" \
  -H "apikey: <SUPABASE_ANON_KEY>" \
  -H "Authorization: Bearer <SITDECK_WEBHOOK_SECRET>" \
  -H "Content-Type: application/json" \
  -d '{"property_id":"<uuid-from-properties>","finding_type":"curl_smoke_test"}'
```

Expect `{"ok":true}` and HTTP `200`; confirm a row in `agent_findings` with `source = 'sitdeck'`.

**If you use Cursor:**  
*"Add a webhook endpoint for SitDeck alerts. On receive, insert into agent_findings with finding_type and source 'sitdeck'. Extend agent_findings schema if needed (e.g. source, nullable agent_run_id)."*  
→ Schema: run **3.6a** migration. Handler: **3.6b** / [sitdeck-webhook/index.ts](../../supabase/functions/sitdeck-webhook/index.ts); turn **off** JWT verification for this function.

**Done when:** Migration applied; Edge Function deployed; a test POST creates a row with `source = 'sitdeck'` and members of that account can SELECT it.

---

## Step 3.7 — Live PUE tile on main property page

**What it means:** On the main overview of a data centre property, show a "live" or "current" PUE tile. In this phase the value comes from `data_library_records` (manual or file upload), not from SitDeck DCIM.

**How to do it:**

- **Where:** Lovable app — main property page or dashboard for a data centre property (e.g. `/dashboards/data-centre/:propertyId` overview).
- **Data:** Derive latest PUE (or latest power/IT load and compute PUE) from `data_library_records` for this property. Display in a prominent tile. If no data, show "No data" or hide the tile.
- **Lovable (paste-ready):** [LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md](./LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md) · [lovable-prompts copy](../lovable-prompts/LOVABLE-PROMPT-DC-PUE-TILE-DATA-LIBRARY.md). Optional: first-class **Site PUE** entry in Data Library → Energy & Utilities — [LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md](./LOVABLE-PROMPT-DATA-LIBRARY-SITE-PUE-RECORD.md).
- **If you use Cursor:**  
  *"On the main property page for a data centre, add a PUE KPI tile. Source the value from data_library_records (latest PUE or computed from power/IT load)."*

**Done when:** The main DC property view shows a PUE tile sourced from data library.

**Implementation reference (Lovable):** `useLivePUE` queries `data_library_records` for an explicit PUE row (`name` / `data_type` / `unit` containing `PUE`) or computes **facility power ÷ IT load**; DC property overview tile shows value (e.g. 2 decimals), source label, as-of date, and optional **target** from `dc_metadata.target_pue`.

---

## Phase 3 complete

You’re done with Phase 3 when:

- SitDeck can be connected from **Data Library → Connectors**; token stored; config in sitdeck_risk_config.
- Property lat/lng can be edited (Integrations & Evidence or settings).
- DC property view shows SitDeck OSINT widgets and physical risk map.
- Optional: webhook writes SitDeck alerts to agent_findings.
- PUE tile on main property page uses data_library_records.

Next: [Phase 4 — Risk Diagnosis & PUE agent](./implementation-guide-phase-4-dc.md).

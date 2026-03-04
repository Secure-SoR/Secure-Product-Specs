# How to implement Phase 3 — SitDeck OSINT integration

This guide explains **what each step means** and **how to do it** in plain language. SitDeck in this phase is **OSINT only** (intelligence dashboard / risk widgets), not DCIM sync.

**Link from main spec:** [secure-dc-spec-v2.md](./secure-dc-spec-v2.md) → Section 8.1 Phase 3

---

## Step 3.1 — Create sitdeck_risk_config table (migration)

**What it means:** We need a table to store, per property, which SitDeck risk widgets are active and when we last synced. The integration token is stored in Supabase secrets, not in this table.

**How to do it:**

- **Where:** Backend repo, migrations folder.
- **Create:** `add-sitdeck-risk-config.sql`. Table: `sitdeck_risk_config` with columns: id, account_id, property_id (UNIQUE), active_widget_types (text array), last_synced_at (timestamptz). Add RLS so only users in the same account can read/update. Add index on property_id.
- **If you use Cursor:**  
  *"Create migration add-sitdeck-risk-config.sql for table sitdeck_risk_config (account_id, property_id UNIQUE, active_widget_types text[], last_synced_at), with RLS by account_id."*

**Done when:** Migration runs and the table exists.

---

## Step 3.2 — SitDeck connection in Account Settings → Integrations

**What it means:** In Account Settings (or Integrations), add **one** "SitDeck" card. The user can connect (enter token/credentials — stored in Supabase secrets), disconnect, and optionally refresh to update which widget types are active. This is the single SitDeck (OSINT) integration, not a second DCIM integration.

**How to do it:**

- **Where:** Lovable app — Account Settings → Integrations (or equivalent).
- **UI:** One card labelled e.g. "SitDeck" with Connect / Disconnect. On Connect, prompt for token (or OAuth if SitDeck provides it); save to Supabase secrets or a secure server-side store. On Refresh, call SitDeck (per their API) to get active widget types and update `sitdeck_risk_config` for the relevant property/properties.
- **If you use Cursor:**  
  *"In Account Settings → Integrations, add one SitDeck card: Connect (store token in secrets), Disconnect, optional Refresh to update active widget types. Use sitdeck_risk_config table."*

**Done when:** User can connect and disconnect SitDeck; token is stored securely; refresh updates config.

---

## Step 3.3 — Edit latitude/longitude on Integrations & Evidence (or property settings)

**What it means:** SitDeck widgets need the property’s location (lat/lng). We added the columns in Phase 1; now we need a place in the app where the user can enter or edit latitude and longitude for a property (e.g. on "Integrations & Evidence" or property settings).

**How to do it:**

- **Where:** Lovable app — the page you use for "Integrations & Evidence" or the property settings/edit screen.
- **UI:** Two fields: Latitude, Longitude (numeric). Load/save from `properties.latitude` and `properties.longitude`. Optional for non-DC properties; especially important for data centre properties that use SitDeck.
- **If you use Cursor:**  
  *"On the Integrations & Evidence page (or property settings), add Latitude and Longitude fields, saved to properties.latitude and properties.longitude."*

**Done when:** User can set and save property lat/lng so widgets can use it.

---

## Step 3.4 — Embed SitDeck OSINT widgets on DC property view

**What it means:** On the data centre property view, embed SitDeck’s OSINT widgets (geopolitical, climate, cyber dashboards) so the user sees how global events relate to the asset. Widgets should be anchored to the property’s lat/lng (from Step 3.3). Use iframe or JS SDK as per SitDeck’s documentation.

**How to do it:**

- **Where:** Lovable app — DC property dashboard or a dedicated "Intelligence" tab.
- **Implementation:** Follow SitDeck’s embed docs (iframe or JS SDK). Pass the property’s latitude and longitude so the widget shows the right location. Show only when SitDeck is connected and property has coordinates.
- **If you use Cursor:**  
  *"On the data centre property view, embed SitDeck OSINT widgets (geopolitical, climate, cyber) using their embed method. Use the property’s latitude and longitude. Only show when SitDeck is connected and lat/lng are set."*

**Done when:** DC property view shows SitDeck OSINT widgets tied to the property location.

---

## Step 3.5 — Physical risk map widget and link to Risk Diagnosis

**What it means:** Embed SitDeck’s physical risk map widget (flood, wildfire, extreme weather, etc.) on the property or risk view. The widget types that are active can be driven by `sitdeck_risk_config`. When Risk Diagnosis exists (Phase 4), this feeds into it; for now you can just show the widget.

**How to do it:**

- **Where:** Lovable app — DC property view or risk section. Use `sitdeck_risk_config.active_widget_types` to know which widgets to show.
- **If you use Cursor:**  
  *"Embed SitDeck physical risk map widget on the DC property/risk view. Use sitdeck_risk_config to know which widget types are active. When Risk Diagnosis is built (Phase 4), this will feed into it."*

**Done when:** Physical risk map widget appears and is driven by config; ready to plug into Risk Diagnosis later.

---

## Step 3.6 — Optional: webhook for SitDeck alerts → agent_findings

**What it means:** If SitDeck can send webhooks when an alert fires (e.g. threshold breached), we can receive that and write a row to `agent_findings` so we have an audit trail. That may require making `agent_run_id` nullable and adding a `source` column (e.g. `'sitdeck'`) so these findings don’t require an agent run.

**How to do it:**

- **Where:** Backend — Edge Function or API route that receives the webhook; plus a small migration if you extend `agent_findings` (e.g. source text, agent_run_id nullable).
- **Flow:** Webhook receives payload → validate → insert into agent_findings (finding_type from event, source 'sitdeck', payload as JSON). If you need schema changes, add a migration and document in backend schema.
- **If you use Cursor:**  
  *"Optional: add a webhook endpoint for SitDeck alerts. On receive, insert into agent_findings with finding_type and source 'sitdeck'. Extend agent_findings schema if needed (e.g. source, nullable agent_run_id)."*

**Done when:** (Optional) Alerts from SitDeck create agent_findings rows; schema is documented.

---

## Step 3.7 — Live PUE tile on main property page

**What it means:** On the main overview of a data centre property, show a "live" or "current" PUE tile. In this phase the value comes from `data_library_records` (manual or file upload), not from SitDeck DCIM.

**How to do it:**

- **Where:** Lovable app — main property page or dashboard for a data centre property.
- **Data:** Derive latest PUE (or latest power/IT load and compute PUE) from `data_library_records` for this property. Display in a prominent tile. If no data, show "No data" or hide the tile.
- **If you use Cursor:**  
  *"On the main property page for a data centre, add a PUE KPI tile. Source the value from data_library_records (latest PUE or computed from power/IT load)."*

**Done when:** The main DC property view shows a PUE tile sourced from data library.

---

## Phase 3 complete

You’re done with Phase 3 when:

- SitDeck can be connected in Account Settings; token stored; config in sitdeck_risk_config.
- Property lat/lng can be edited (Integrations & Evidence or settings).
- DC property view shows SitDeck OSINT widgets and physical risk map.
- Optional: webhook writes SitDeck alerts to agent_findings.
- PUE tile on main property page uses data_library_records.

Next: [Phase 4 — Risk Diagnosis & PUE agent](./implementation-guide-phase-4-dc.md).

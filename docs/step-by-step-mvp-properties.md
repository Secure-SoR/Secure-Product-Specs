# Step-by-step: MVP — Save properties in Supabase (non-developer guide)

This guide gets you from “login works, data is in the browser only” to “I can create and save properties in the database” so you can later add the AI agent.

---

## Where does the “backend” code live?

- **Database and auth:** They live in **Supabase** (in the cloud). You already created the Supabase project and have login working.
- **Backend “code” for properties:** There is **no separate backend server** for this MVP. The database schema (table definitions and security rules) is defined in **this repo** in `docs/database/supabase-schema.sql`. You (or someone) already ran that SQL in Supabase, so the `properties` table exists.
- **The app that talks to the database:** That’s the **Lovable app**. So the “code” that creates and lists properties is **inside the Lovable project** — the same place as your UI. Lovable uses the Supabase client to send data to Supabase.

So: **Supabase = database (already set up). Lovable = UI + the code that reads/writes properties.** There is no other backend to install or run for properties.

---

## What you need before starting

1. **Supabase project** — You have this (you have login).
2. **Schema run in Supabase** — The `properties` table (and `accounts`, `account_memberships`, etc.) must exist. If you’re not sure, in Supabase go to **Table Editor** and check for tables: `accounts`, `account_memberships`, `properties`. If they’re missing, run the SQL from `docs/database/supabase-schema.sql` in the **SQL Editor**.
3. **Lovable app connected to Supabase** — The app already uses Supabase for auth and account creation. It just needs to be updated to use Supabase for **properties** instead of localStorage.

You don’t need to install anything else. All changes are: (a) in Lovable (UI + Supabase calls), and (b) already documented in this repo.

---

## Step 1: Confirm Supabase has the `properties` table

1. Open your **Supabase** project dashboard.
2. Go to **Table Editor**.
3. Check that you see a table named **`properties`** (and that **`accounts`** and **`account_memberships`** exist).
4. If **`properties`** is missing: open **SQL Editor**, paste the contents of `docs/database/supabase-schema.sql` from this repo, and run it. (If you already ran it when setting up login, skip this.)

---

## Step 2: Get the “Lovable prompt” for properties

In this repo we’ve added a **Lovable prompt** that tells Lovable exactly how to save and load properties from Supabase. You’ll paste that into Lovable in the next step.

- The prompt is in **`docs/implementation-plan-lovable-supabase-agent.md`**, under the section **“Lovable prompt for Phase 2 (properties)”**.
- Or use the short version below in Step 3.

---

## Step 3: Paste the prompt into Lovable and apply

1. Open your **Lovable** project (the Secure SoR app).
2. Use the **prompt / chat** where you give instructions to Lovable (e.g. “Implement …” or “Change …”).
3. Paste the **Lovable prompt for Phase 2 (properties)** (see the implementation plan, or the box below).
4. Let Lovable implement the changes. It should:
   - When the user **adds a property**: insert a row into Supabase `properties` with `account_id`, `name`, and optionally `address`, `country`, `floors`, `total_area`.
   - When the app **loads the property list**: read from Supabase with `account_id` = current user’s account (the same `currentAccountId` you use after login/onboarding).
   - **Update** and **delete** property should use Supabase `.update()` and `.delete()` with the property’s `id`.

**Short prompt you can paste into Lovable (properties only):**

```
Use Supabase for properties instead of localStorage.

1. When the user creates a property, insert into the Supabase table "properties" with: account_id = currentAccountId (from AccountContext), name (required), and optionally address, city, region, postcode, country, nla, asset_type (e.g. 'Office'), year_built (integer), last_renovation (integer), operational_status (text), floors (JSON array), total_area. Keep city, region, postcode, nla as separate columns. Use .select('id').single() or .select().single() to get the new row and use its id as the property id in the app.

2. When loading the list of properties, use: supabase.from('properties').select('*').eq('account_id', currentAccountId). Use the returned rows as the source of truth (do not read from localStorage for the list).

3. When the user updates a property, use supabase.from('properties').update({ name, address, city, region, postcode, country, nla, asset_type, year_built, last_renovation, operational_status, floors, total_area }).eq('id', propertyId). When they delete, use supabase.from('properties').delete().eq('id', propertyId).

4. Ensure currentAccountId is set (from account_memberships after login) before any property query. Use the same Supabase client and auth session you already use for account creation and login.
```

---

## Step 4: Test in the app

1. In Lovable, run or preview the app.
2. **Sign in** with a user that already has an account (so `currentAccountId` is set).
3. Go to the **property** section and **add a new property** (name and any optional fields).
4. Save.
5. **Refresh the page** (or open the app in a new tab). The property should still be there (it’s now in Supabase, not only in the browser).
6. In **Supabase → Table Editor → `properties`**, you should see one row with that property’s name and your account’s `account_id`.

If step 5 or 6 fails, check: (a) Supabase project URL and anon key are set in the Lovable app (e.g. env vars), (b) the user is logged in and has an account (one row in `account_memberships`), (c) Lovable is using `currentAccountId` in every property query.

---

## Step 5: After properties work — spaces and systems (optional for MVP)

Once properties are saving to Supabase, you can do the same for **spaces** and **systems** (add/edit/delete in the UI, read/write from Supabase). The exact Supabase calls are in the implementation plan under **Phase 2**. You can do spaces/systems in a follow-up prompt to Lovable.

---

## AI agent folder (keeping the agent in sync)

The **AI agent** (Data Readiness / Boundary) is a **separate project** (e.g. in an “AI Agents” or “agent” folder). It is not inside this backend repo.

- **This repo** has a small **“For the AI agent”** section and a doc that describe what the agent should expect once properties (and later spaces, systems, data library) are in Supabase. When you work in the agent project, use that to keep the agent’s expectations in sync.
- **For properties only:** No change is required in the agent code. The agent receives a **context JSON** (property, spaces, systems, etc.) that Lovable will build from Supabase. The **shape** of that context does not change when you move from localStorage to Supabase; only the **source** of the data (Supabase) changes. So for “properties in Supabase” you don’t need to change the agent yet — you’ll need to when Lovable builds that context and calls the agent (Phase 5).

The file **`docs/for-agent/README.md`** in this repo summarises what to update in the agent project after each phase.

---

## Summary

| Step | What you do |
|------|----------------|
| 1 | Confirm `properties` (and accounts) exist in Supabase Table Editor. |
| 2 | Get the Lovable prompt from the implementation plan (or use the short version above). |
| 3 | Paste the prompt into Lovable and let it implement property create/list/update/delete with Supabase. |
| 4 | Test: add a property, refresh, check it appears in Supabase. |
| 5 | Optionally add spaces/systems to Supabase next; then data library; then wire the agent. |

Data is stored in **Supabase** (the database). The only “backend” code for this MVP is the schema in this repo (already run in Supabase) and the Supabase calls inside the **Lovable** app.

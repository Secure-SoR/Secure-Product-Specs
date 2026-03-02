# App route map (Lovable — www.securetigre.co.uk)

**Single source of truth** for the app’s entry, auth, and post-login flow. All changes to routing (landing, login, signup, dashboard) are decided here and in [LOVABLE-PROMPT-FIX-PUBLIC-PAGE-ROUTING.md](LOVABLE-PROMPT-FIX-PUBLIC-PAGE-ROUTING.md); Lovable implements from prompts. When Lovable confirms the actual paths it uses, update the table below.

---

## Entry and auth flow (canonical)

| Route | Who | Behaviour |
|-------|-----|-----------|
| **`/`** (or `/home`) | Not logged in | Show **public Landing Page** (marketing: hero, Building Data Platform, modules, CTA). |
| **`/`** (or `/home`) | Logged in | **Redirect → Dashboard** (platform home). |
| **`/login`** | Not logged in | Show login form. |
| **`/login`** | Logged in | **Redirect → Dashboard**. |
| **`/signup`** (if separate) | Not logged in | Show signup form. |
| **`/signup`** | Logged in | **Redirect → Dashboard**. |
| After successful sign-in | — | **Redirect → Dashboard**. |
| **Dashboard** (e.g. `/dashboard` or `/app`) | Logged in | Show platform home (property list / overview). |
| **Dashboard** (and all app routes below) | Not logged in | **Redirect → Login** (or Landing). |

**Flow:** Landing Page → Sign in button → Login/Signup → after auth → Dashboard. Authenticated users visiting `/` go to Dashboard.

---

## App routes (behind auth)

All of the following require authentication. If the user is not logged in, redirect to login (or landing). These sit under or alongside the Dashboard.

- Account Settings, Property & Onboarding, Spaces & Systems  
- **Data Library** (see [sources/lovable-data-library-spec.md](sources/lovable-data-library-spec.md) §2.3 for full map): `/data-library`, `/data-library/energy`, `/data-library/water`, `/data-library/waste`, etc.  
- Reports, Dashboards (Energy, Carbon, Risk, etc.), Landlord Portal  
- IoT / Device pages, Governance & Targets, Surveys & Feedback  

~67 routes total (62 pages + 5 redirects); structure in [architecture/architecture.md](architecture/architecture.md) §1.2.

---

## Where this is referenced

- **Backend:** [architecture/architecture.md](architecture/architecture.md) §1.2 Routes — entry/auth flow and link here.  
- **Backend:** [LOVABLE-PROMPT-FIX-PUBLIC-PAGE-ROUTING.md](LOVABLE-PROMPT-FIX-PUBLIC-PAGE-ROUTING.md) — prompt to fix routing; after Lovable applies it, update this file with confirmed paths.  
- **Backend:** [LOVABLE-PUBLIC-PAGE-COPY-SECURETIGRE.md](LOVABLE-PUBLIC-PAGE-COPY-SECURETIGRE.md) — public page lives at `/` when not logged in.  
- **AI Agents:** `agent/docs/MODE-AND-WORKFLOW.md` — points to this file for the Lovable app route map (landing, login, dashboard).

---

## Changelog

| Date | Change |
|------|--------|
| (Initial) | Canonical entry/auth flow added: Landing at `/`, Sign in → Login/Signup → Dashboard; auth redirects. |
| (When Lovable confirms) | Update with actual paths (e.g. `/dashboard` vs `/app`) and any path renames. |

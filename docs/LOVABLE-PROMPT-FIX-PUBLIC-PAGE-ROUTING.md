# Lovable prompt: Fix routing after adding public landing page

**Copy the prompt below into Lovable’s chat** so the routing is corrected. The goal: Landing Page first → Sign in → Login/Signup → after auth → Dashboard (platform home).

---

## Prompt to paste into Lovable

```
We added a public landing page but the routing is now wrong. Please fix it so the flow is exactly this:

**Intended flow**

1. **Unauthenticated users**
   - Default route (e.g. `/` or `/home`) shows the **public Landing Page** (marketing content: hero, value prop, modules, etc.).
   - The Landing Page has a **Sign in** (or **Log in**) button/link that navigates to the **login/signup pages** (e.g. `/login`, `/signup`, or your existing auth routes).
   - No authenticated content or dashboard is visible until the user signs in.

2. **Login / Sign up**
   - From the Landing Page, "Sign in" goes to the login (and optionally signup) page(s).
   - User enters credentials and submits. After **successful sign-in**, redirect the user to the **Dashboard** (the home page inside the platform), e.g. `/dashboard` or `/app` or whatever is the main app home.
   - If the user is already authenticated and visits `/login` or `/signup`, redirect them to the Dashboard instead of showing auth forms.

3. **Authenticated users**
   - When a user is **already signed in** and visits the root URL (e.g. `/` or `/home`), **redirect them to the Dashboard** (platform home) instead of showing the public landing page. They are already in the platform; they don’t need to see the marketing page again.
   - All existing app routes (dashboard, properties, data library, reports, etc.) stay behind auth: only authenticated users can access them. Unauthenticated users who hit those routes directly should be redirected to login (or to the landing page with a sign-in CTA).

**Summary**
- `/` (or `/home`) = Public Landing Page **only when not logged in**. When logged in → redirect to Dashboard.
- Landing Page has a "Sign in" button → goes to login/signup.
- After successful login/signup → redirect to Dashboard (platform home).
- Dashboard and all app routes = require auth; otherwise redirect to login or landing.

Please fix the router and any redirect/guard logic so this flow works. Tell me which routes you used (e.g. `/` for landing, `/login`, `/signup`, `/dashboard`) so we can keep the docs in sync.
```

---

## Route map to aim for (reference)

| Route        | Who can see it     | Action / redirect |
|-------------|--------------------|-------------------|
| `/` or `/home` | Not logged in      | Show Landing Page |
| `/` or `/home` | Logged in          | Redirect → Dashboard |
| `/login` (and `/signup` if separate) | Not logged in | Show login/signup form |
| `/login` (and `/signup`) | Logged in   | Redirect → Dashboard |
| After successful sign-in | —            | Redirect → Dashboard |
| `/dashboard` (or `/app`) | Logged in  | Show Dashboard (platform home) |
| `/dashboard` (or other app routes) | Not logged in | Redirect → Login (or Landing) |

---

## If Lovable asks for more detail

- **Landing page** = the public marketing page (hero, “Building Data Platform”, modules, CTA).
- **Dashboard** = the main app home after login (e.g. property list, overview, or whatever the first screen inside the app is).
- **Auth** = same as you already have (e.g. Supabase Auth, AuthContext). Only the **routes and redirects** need to change so that (1) root shows landing when logged out and dashboard when logged in, (2) “Sign in” from landing goes to login/signup, (3) after login we go to dashboard.

---

**After Lovable applies the fix:**
1. Update [docs/APP-ROUTE-MAP.md](APP-ROUTE-MAP.md) with the **actual** paths Lovable used (e.g. `/`, `/login`, `/signup`, `/dashboard` or `/app`). That file is the single source of truth for entry/auth/dashboard routes.
2. If the AI Agents workspace has a copy at `Secure-SoR-backend/docs/APP-ROUTE-MAP.md`, update the table and Changelog there too so both folders stay in sync.
3. Docs that reference the route map: architecture §1.2, this file, LOVABLE-PUBLIC-PAGE-COPY-SECURETIGRE.md, AI Agents MODE-AND-WORKFLOW.md, LOVABLE-PROMPTS-FOR-AGENTS.md — no further change needed once APP-ROUTE-MAP is updated.

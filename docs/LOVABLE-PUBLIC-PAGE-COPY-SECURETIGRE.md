# Public page copy for securetigre.co.uk — Building Data Platform positioning

Use this text when building the public/marketing page in Lovable. **Aligned to:** *Secure — Platform Strategy: Building Data Infrastructure* (vision: building data infrastructure platform; modules sit on top; Option 4: "the first Building Data Platform").

---

## Context and recommendation

**Backend/app already lives on www.securetigre.co.uk.** The public marketing page uses the **same domain** and the **same Lovable project**: one site at www.securetigre.co.uk — public landing at `/` (when not logged in), app (Dashboard and rest) after login. **Canonical route map:** [APP-ROUTE-MAP.md](APP-ROUTE-MAP.md). Do **not** create a new Lovable project; add the public page to the existing project.

---

## Recommended steps to add the public page

1. **Lovable** — Open the **existing** project that deploys to www.securetigre.co.uk. Add the public landing at `/` (when not logged in); Sign in → login/signup → after auth → Dashboard. See [APP-ROUTE-MAP.md](APP-ROUTE-MAP.md) for the full entry/auth flow.
2. **Copy** — Paste sections from this file into the new page components. Start with Hero (headline, subhead, CTA), then add sections in order. Use the SEO/meta block in your page settings or head.
3. **Design** — Reuse layout/visual style from [secure.live](https://www.secure.live/) if you want consistency (nav, footer, cards, CTA). Keep "Secure Tigre" branding and Building Data Platform messaging from the copy below.
4. **Deploy** — Deploy the existing project as usual. The same www.securetigre.co.uk deployment will now include the public page.
5. **Test** — Visit www.securetigre.co.uk and confirm the public content and app (and navigation between them) work as intended.

---

## Hero / Above the fold

**Headline**  
The building data platform for commercial real estate

**Subhead**  
One structured data layer. Every decision about your building — compliance, risk, reporting, retrofit — runs on the same data.

**CTA**  
Request a demo

**Short line (optional)**  
Secure Tigre — the first Building Data Platform.

---

## Value proposition (one short paragraph)

Secure is building data infrastructure for commercial real estate: the structured, normalised data layer that connects physical building reality to every decision — compliance, risk, reporting, ROI, and decarbonisation. You don't buy another tool; you get one platform. Modules (compliance, risk, sustainability reporting, stakeholder data exchange, AI agents) sit on top of the same data. The platform is the value.

---

## Section: What is a Building Data Platform?

**Title**  
One platform, one source of truth

**Body**  
Buildings generate data everywhere: meters, BMS, bills, certificates, leases. Today it's spread across spreadsheets, emails, and different systems. A Building Data Platform is the single layer where that data is structured, normalised, and connected to the physical building — so compliance, risk, reporting, and ESG all use the same facts. No duplicate entry, no conflicting numbers. One place for building data; every application runs on it.

---

## Section: What we offer (modules on the platform)

**Title**  
Modules that run on your building data

**Intro line**  
All of these use the same platform data: Property Graph, Evidence Store, Activity Data, Boundary Engine (and Coverage Engine, Emissions Engine where relevant).

- **Compliance Tracker** — MEES, EPC, SECR, ISSB readiness, regulatory calendar. Per property.
- **Risk Diagnosis** — Six-domain risk: regulatory, boundary, data confidence, physical, transition, operational.
- **Sustainability Reporting** — SECR, sustainability report, GRESB data export. Structured SoR data only.
- **Stakeholder Data Exchange** — Landlord ↔ tenant ↔ FM data requests, structured forms, shared building profile with role-gated access.
- **AI Agents** — Data readiness, boundary analysis, compliance gaps, action prioritisation. Cross-cutting; all fed by the same platform data.

---

## Section: Why the platform matters

**Title**  
Data infrastructure, not another dashboard

**Points (short bullets or cards)**  
- **One data layer** — Property Graph, Stakeholder Registry, Evidence Store, Activity Data, Boundary Engine (and Coverage Engine, Emissions Engine, Audit Trail) in one place.  
- **Modules consume it** — Compliance Tracker, Risk Diagnosis, Sustainability Reporting read from and write back to the platform; no silos (Rule 1: consume, don't duplicate; Rule 2: write back, don't hoard).  
- **Audit and traceability** — Every calculation and export traceable through the platform's Audit Trail.  
- **Built for multi-stakeholder** — Same building, different roles: occupier, landlord, FM, managing agent (Rule 3: respect the boundary).

---

## Section: Who it's for

**Title**  
For everyone who decides about the building

- **Real estate services** — Agencies, brokers, realtors, RE professionals  
- **Investment management** — Owners, portfolio managers, asset managers, property managers, facility managers  
- **Capital markets & mortgage** — Lenders, financial professionals (due diligence, lending, valuations)  
- **Real estate professionals** — Property management companies, RE operations, developers and contractors  
- **Occupiers and tenants** — Compliance, data exchange with landlords

---

## Section: Differentiator (optional)

**Title**  
Building-level data, not just portfolio-level

**Body**  
Other tools aggregate at portfolio or asset level (portfolio → asset → meter/bill). Secure models the building: Property Graph (spaces, systems, meters, end-use nodes), Evidence Store, Activity Data, and who is responsible for what (Boundary Engine). Building-level confidence: you see which records are measured vs allocated and why. Compliance and reporting are grounded in the actual building — and the same data drives risk, retrofit, and stakeholder exchange.

---

## Footer / Trust

- **Tagline:** Secure Tigre — Building Data Platform for commercial real estate.  
- **Legal:** © [Year] [Entity]. All rights reserved. | Privacy | Contact  
- **Optional:** "Used by occupiers, landlords, and advisors across UK commercial real estate."

---

## SEO / meta (for Lovable or your host)

- **Title:** Secure Tigre | Building Data Platform for Commercial Real Estate  
- **Description:** Secure Tigre is the building data platform — the structured data layer for commercial real estate. One platform for compliance, risk, sustainability reporting, and stakeholder data exchange.  
- **Keywords (optional):** building data platform, commercial real estate data, ESG data, SECR, MEES, building compliance, sustainability reporting, property data

---

## CTA and tone

- **Primary CTA:** Request a demo  
- **Secondary:** Contact sales | Learn more  
- **Tone:** Confident, infrastructure/platform (not "just another ESG app"). Short sentences. Avoid jargon where possible; when you use "platform," "data layer," "property graph," keep one brief explainer nearby.

---

*Copy aligned to **Secure — Platform Strategy: Building Data Infrastructure** (full strategy doc: primitives §1.1, first-party modules §1.2, Five Rules §1.3, Option 4 positioning §5, who it's for / stakeholder groups, Horizon 1–3 modules). This file lives in Secure-SoR-backend/docs/. Adjust brand name (e.g. "Secure" vs "Secure Tigre") to match how you want to show on securetigre.co.uk.*

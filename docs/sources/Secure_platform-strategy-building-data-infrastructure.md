# Secure — Platform Strategy: Building Data Infrastructure

**Vision:** Secure is a building data infrastructure platform — the structured, normalised data layer for commercial real estate that connects physical building reality to every decision made about that building.

Modules (compliance, risk, reporting, ROI scenarios, asset tracking) sit on top. The platform is the value.

---

## 1. The Platform Model

### 1.1 Core Data Matrix (the primitives)

Like AWS has S3, EC2, IAM — Secure has:

| Primitive | What It Holds | Equivalent |
|-----------|--------------|------------|
| **Property Graph** | Spaces, systems, meters, end-use nodes, IoT. The physical building as a structured, queryable model. | "S3 for building topology" |
| **Stakeholder Registry** | Accounts, roles, boundary relationships. Who controls what, who pays for what, who reports on what — for the same building. | "IAM for buildings" |
| **Evidence Store** | Documents with provenance, confidence, audit trail. Bills, certificates, FM confirmations, contracts. | "S3 + CloudTrail for evidence" |
| **Activity Data** | Utility readings, consumption, waste volumes. Structured by billing source, confidence level, reporting period. | "Kinesis for building operations" |
| **Boundary Engine** | Attribution logic: control hierarchy, billing source classification, metering status → who owns what data. | "Policy engine" |
| **Coverage Engine** | Completeness assessment: what data exists, what's missing, what's estimated. Per property, per period. | "Health check service" |
| **Emissions Engine** | Scope 1/2/3 calculation from activity inputs. Deterministic, traceable, never manually overridden. | "Compute for carbon" |
| **Audit Trail** | Append-only log of every data mutation. Actor, timestamp, before/after. | "CloudTrail" |

**Foundation (product surface).** In the product, the **foundation** is the platform surface that all modules consume. It comprises: **Data Library** (Activity Data + evidence in the app), **Property section** (Property Graph: properties, spaces, systems, meters), **Account settings / user profile** (Stakeholder Registry: accounts, roles, access), **Evidence Store**, and **Boundary Engine**. Modules feed from this foundation and may also consume other modules (e.g. Reports consuming AI Agents output). The distinction between *module* and *feature* is to be clarified for some areas (e.g. Stakeholders Management, Dashboards). See [docs/modules/README.md](../modules/README.md) in the backend repo for the canonical foundation list and module list.

### 1.2 Modules (applications that consume the primitives)

Modules can be built by Secure (first-party) or by third parties via API.

**First-party modules (your entry point):**

| Module | What It Does | Market Entry |
|--------|-------------|--------------|
| **Compliance Tracker** | MEES/EPC status, SECR, ISSB readiness, regulatory calendar. Per property. | UK occupiers + landlords |
| **Risk Diagnosis** | Six-domain risk assessment (regulatory, boundary, data confidence, physical, transition, operational). | Occupiers, lenders, acquirers |
| **Sustainability Reporting** | SECR, sustainability report, GRESB data export. Consuming structured SoR data only. | Occupiers for SECR; landlords for GRESB |
| **Stakeholder Data Exchange** | Landlord ↔ tenant ↔ FM data requests, structured forms, shared building profile with role-gated access. | Managing agents, occupiers |
| **AI Agents** | Data readiness, boundary analysis, compliance gaps, action prioritisation. | Cross-cutting |

**Future / third-party module opportunities:**

| Module | Builder | Value |
|--------|---------|-------|
| **ROI / Retrofit Scenarios** | Secure or partner | "If we replace system X, what's the payback, scope reduction, EPC impact?" Consumes Property Graph + Activity Data. |
| **Asset Valuation Impact** | Valuation firms | "What's the sustainability risk discount on this building?" Consumes Risk Diagnosis + Compliance Tracker. |
| **Insurance Underwriting** | Insurers / insurtechs | Physical risk + building systems data → premium adjustment. Consumes Property Graph + physical risk data. |
| **Green Lease Compliance** | Legal tech / proptech | Track green lease obligations vs actual performance. Consumes Stakeholder Registry + Activity Data. |
| **Fit-Out Assessment** | Occupier advisors | "What sustainability data exists for this building before we sign the lease?" Consumes Property Graph + Coverage Engine. |
| **Benchmarking** | Industry bodies / data partners | Building-level performance vs cohort. Consumes Activity Data (anonymised). |
| **FM Performance Monitoring** | FM providers | Demonstrate SLA compliance on metering, data quality, system maintenance. Consumes Property Graph + Audit Trail. |
| **Portfolio ESG Feed** | Deepki / Envizi / Measurabl | Export structured, confidence-rated, boundary-clear data into portfolio ESG platforms. Secure becomes the data preparation layer. |

### 1.3 Module Alignment Framework

Every module — first-party or third-party — must pass this fitness test before being built or accepted onto the platform.

**The Five Rules:**

**Rule 1: Consume, don't duplicate.** The module must read from existing primitives (Property Graph, Stakeholder Registry, Activity Data, etc.) via the platform API. It must NEVER create its own parallel data store for information the platform already holds. If a module needs building topology, it reads Property Graph. It does not build its own buildings table.

**Rule 2: Write back, don't hoard.** If the module generates data that enriches the platform, it must write it back to the appropriate primitive. An ROI scenario module that calculates retrofit impacts writes the results to Activity Data (projected) and Property Graph (proposed system changes). A risk diagnosis module writes risk scores to a standardised risk primitive. This ensures every module makes the platform smarter for every other module.

**Rule 3: Respect the boundary.** Every module must be stakeholder-aware. It must read the Stakeholder Registry to determine what data the current user can see and what actions they can take. A landlord using the Risk Diagnosis module sees whole-building risk. A tenant sees only their demise. No module bypasses boundary logic.

**Rule 4: Leave an audit trail.** Every action a module takes — every calculation, every recommendation, every export — must be traceable through the platform's Audit Trail. If a Sustainability Reporting module generates a SECR figure, the audit trail shows: which Activity Data records were consumed, which Emissions Engine version was used, which boundary assumptions applied. No black boxes.

**Rule 5: Strengthen a platform primitive.** The module must deepen at least one primitive. This is the strategic test.

| Module | Primary Primitive Strengthened |
|--------|-------------------------------|
| Compliance Tracker | Coverage Engine (forces data completeness per regulation) |
| Risk Diagnosis | Property Graph (requires systems and physical data to be modelled) |
| Sustainability Reporting | Emissions Engine + Evidence Store (forces calculation traceability) |
| Stakeholder Data Exchange | Stakeholder Registry + Boundary Engine (forces multi-party data) |
| ROI / Retrofit Scenarios | Property Graph (forces system-level modelling of interventions) |
| Asset Tracking | Property Graph (forces comprehensive systems register) |
| FM Performance Monitoring | Audit Trail + Activity Data (forces operational data cadence) |
| Green Lease Compliance | Stakeholder Registry + Activity Data (forces lease obligation tracking) |

**Anti-pattern: A module that only reads data and exports a PDF without writing anything back to the platform.** This is a reporting feature, not a platform module. It's acceptable as a lightweight add-on but should not be treated as a core module.

### 1.4 Revenue Model Options

| Model | How It Works | When |
|-------|-------------|------|
| **Per-building subscription** | Pay per property on the platform. Includes core data matrix. | From day 1 |
| **Module fees** | Each module is an add-on. Compliance Tracker = £X/building/year. | From day 1 |
| **API access** | Third parties pay per call or per-building to read/write via API. | When third-party modules exist |
| **Data exchange fees** | Stakeholders pay to participate in the building data exchange. Or: building owner pays, stakeholders access free. | When multi-stakeholder is live |
| **Marketplace commission** | Take % of third-party module revenue. | Later stage |
| **Data licensing** | Anonymised, aggregated building performance data (like Deepki's ESG Index, but building-level). | When data volume justifies it |

---

## 2. Why This Is Defensible

### 2.1 What Deepki/Envizi CANNOT copy easily

| Your Advantage | Why Incumbents Can't Just Add This |
|---------------|-----------------------------------|
| **Physical building model** | Their data model is portfolio → asset → meter/bill. Adding systems, spaces, end-use nodes, control attribution to 400,000 assets retroactively is a multi-year re-architecture. |
| **Multi-stakeholder per building** | Their architecture is single-customer (the investor/owner). Adding role-gated access for tenant, FM, managing agent on the same building requires a fundamentally different permission and data-sharing model. |
| **Boundary engine** | They calculate emissions. They don't model WHO is responsible for WHAT utility based on system control, metering status, and billing source. This is domain logic, not just data. |
| **Building-level confidence** | They report confidence at portfolio level ("85% measured data"). You report it at the record level ("this HVAC consumption is allocated because system X has no tenant meter and FM confirmed allocation method Y on date Z"). |
| **Schema as product** | Their schema is internal. Yours is the product. If you publish and govern it well, it becomes a standard — and they'd need to adopt it or compete against it. |

### 2.2 The moat deepens with data

Every building modelled in Secure adds:
- More systems taxonomy coverage (new system types, new building configurations)
- More boundary patterns (different landlord-tenant arrangements)
- More evidence patterns (what "complete" looks like for different property types)
- More benchmark data (building-level, not portfolio-level)

This is a data network effect. The more buildings, the smarter the Coverage Engine, the Emissions Engine, and the AI agents become.

---

## 3. Go-to-Market: Platform Entry via Application

**Critical principle: Nobody buys a platform. They buy a solution. The platform reveals itself.**

### Phase 1: Application Entry (now → 6 months)

Sell Secure as an **occupier compliance workbench** for UK commercial RE.

- "Track your MEES/EPC status, generate SECR-ready data, prepare for ISSB — across your leased portfolio."
- Target: Sustainability / RE managers at corporates with 5-50 UK buildings.
- Price: Per-building subscription, includes Compliance Tracker + Data Exchange + AI agents.
- Deploy on 5-10 buildings with 2-3 customers.

**What's really happening:** You're populating the data matrix. Every building gets a Property Graph, Stakeholder Registry, Evidence Store, and Activity Data structure.

### Phase 2: Multi-Stakeholder Activation (6-12 months)

Once occupiers are on the platform, enable data exchange:

- Occupier invites landlord to confirm metering status, upload service charge breakdown.
- Landlord sees value: structured tenant data they can use for GRESB.
- FM provider gets structured reporting requirements instead of ad-hoc emails.
- Managing agent sees multiple buildings with both landlord and tenant data.

**What's really happening:** The platform has multiple stakeholders per building. The network effect begins.

### Phase 3: Module Expansion (12-18 months)

Add first-party modules that demonstrate platform capability:

- Risk Diagnosis (consumes all primitives)
- ROI / Retrofit Scenarios (consumes Property Graph + Activity Data + Emissions Engine)
- Sustainability Reporting export (SECR report generation, GRESB data feed)

**What's really happening:** Proving that the data matrix serves multiple use cases. Each module is evidence that the platform works.

### Phase 4: API & Third-Party Modules (18-24 months)

Open the API:

- Let consultancies build assessment tools on your data.
- Let valuation firms pull risk profiles.
- Let Deepki/Envizi/Measurabl pull structured, confidence-rated building data via API (you become their data quality layer).
- Publish the building data schema as an open standard (or keep it proprietary — strategic choice).

**What's really happening:** You're becoming infrastructure. Revenue shifts from module subscriptions to API + marketplace.

---

## 4. Schema as Product: The Real Differentiator

### 4.1 What makes this an infrastructure play, not just a SaaS app

The canonical spec you've already written (Secure_Canonical_v5.md) + the building systems taxonomy + the end-use nodes spec + the boundary logic + the coverage logic + the confidence model = **a schema for building data that doesn't exist elsewhere.**

This schema IS the product. Everything else is implementation.

If you can get adoption of this schema — even just in UK commercial RE — you have:
- A standard that others build against
- Lock-in at the data model level (hardest to switch)
- A competitive advantage that grows with every building modelled
- Potential for industry body endorsement (RICS, BBP, BRE, UKGBC)

### 4.2 Open vs Proprietary

| Approach | Pros | Cons |
|----------|------|------|
| **Proprietary schema, proprietary platform** | Full control, maximum lock-in, simpler governance | Slower adoption, "walled garden" risk, harder to get industry buy-in |
| **Open schema, proprietary platform** | Faster adoption, industry credibility, others build tooling around your schema | Competitors can implement the same schema, need to win on execution |
| **Open schema, open-source core, commercial modules** | Maximum adoption, community contributions, RedHat/Elastic model | Hardest to monetise, risk of cloud providers offering managed versions |

**Recommendation:** Open schema, proprietary platform. Publish the building data schema as a specification that anyone can read. But Secure is the best (only?) implementation, and the API/modules are commercial.

---

## 5. Naming and Positioning

### Current: "Secure SoR"
Problem: "System of Record" means nothing to buyers. "Secure" sounds like a security product.

### Options for platform positioning:

**Option 1: Keep "Secure" but reframe**
"Secure — Building Data Infrastructure for Commercial Real Estate"
*"Secure the data. Secure the building. Secure the decision."*

**Option 2: "Secure" as acronym or expanded**
"SECURE: Structured Evidence-backed Commercial Utility & Real Estate"
(Bit forced, but gives it meaning)

**Option 3: Rebrand entirely for platform positioning**
Something that signals "data infrastructure" rather than "ESG tool":
- "BuildingCore" — the core data layer for buildings
- "PropertyGraph" — the structured graph of building data (echoes tech platform language)
- "Baseplan" — the foundational plan for building intelligence
- "GridLayer" — the data grid layer for real estate

**Option 4: Keep "Secure" but own the category name**
"Secure — the first Building Data Platform"
Create the category: "Building Data Platform" (like "Customer Data Platform" in martech).

### Recommended: Option 4
"Building Data Platform" is a category that doesn't exist yet. You define it. You own it.
Like Segment created "Customer Data Platform" — Secure creates "Building Data Platform."

---

## 6. What This Means for the Repo (Cursor Instructions)

If you choose this direction, the repo changes from the previous repositioning brief shift slightly:

1. **Canonical spec** frames the data matrix primitives explicitly (Property Graph, Stakeholder Registry, Evidence Store, Activity Data, Engines)
2. **Architecture docs** describe the platform layer vs module layer separation
3. **API design** becomes a priority — modules must consume primitives via clean interfaces, not direct DB access
4. **Schema documentation** becomes a publishable artefact — it's not just internal docs, it's the product
5. **Module boundaries** are defined: what's a primitive (platform) vs what's a module (application)

I can write specific Cursor instructions for this once you confirm the direction.

---

## 7. Honest Risks

| Risk | Mitigation |
|------|-----------|
| **"Too early for a platform"** — you don't have enough users/data to justify infrastructure positioning | Enter as application (Phase 1), reveal platform later. Don't talk about "infrastructure" to early customers. Sell compliance, deliver platform. |
| **Schema adoption requires credibility** | Partner with a respected industry body (BBP, UKGBC, RICS) to validate the building data schema. Or pilot with a known property (140 Aldersgate) and publish the case study. |
| **Third-party modules need developers** | Don't wait for third parties. Build 3-5 first-party modules that prove the platform works. Third parties follow traction, not potential. |
| **Revenue is small while building infrastructure** | Charge per-building from day 1. Platform economics improve over time as modules multiply. Early revenue is from compliance module, not API calls. |
| **Incumbents add building-level features** | Their architecture can't support it without fundamental re-design. Deepki is optimised for portfolio aggregation across 400K assets, not for modelling 500 systems inside one building. Different problems, different architectures. |

---

## 8. Long-Term Vision: The Building Data Platform (3-5 Years)

### 8.1 North Star

**By 2030, every significant decision made about a commercial building — lease, acquisition, retrofit, insurance, valuation, compliance filing — consumes structured data from Secure's Building Data Platform.**

Secure is not a sustainability tool. It's not a compliance tool. It's not a risk tool. It's the **canonical data layer** that all of those tools read from and write to. The same way Stripe became the payment layer (not a shop), Twilio became the communications layer (not a call centre), and Segment became the customer data layer (not a CRM) — Secure becomes the building data layer.

### 8.2 Three Horizons

**Horizon 1 — Application (now → 12 months): "We solve compliance"**

What customers see: A compliance and data management tool for UK commercial RE occupiers.
What we're actually building: The data matrix primitives, populated building by building.

| Milestone | Platform Primitive Developed |
|-----------|------------------------------|
| First 10 buildings modelled | Property Graph schema validated across different building types |
| First SECR report generated from SoR | Emissions Engine + Evidence Store proven end-to-end |
| First landlord-tenant data exchange | Stakeholder Registry + Boundary Engine proven multi-party |
| First risk assessment delivered | Coverage Engine + all primitives consumed together |

Modules live: Compliance Tracker, Stakeholder Data Exchange, AI Agents (data readiness).

Revenue: Per-building subscription. £500-2,000/building/year depending on modules.

**Horizon 2 — Multi-Module Platform (12-30 months): "We make building data usable"**

What customers see: A platform with multiple modules they can add to their buildings.
What we're actually building: Proof that the same data matrix serves fundamentally different use cases.

| Milestone | Platform Capability Proven |
|-----------|--------------------------|
| 3+ modules consuming same Property Graph | Schema is genuinely reusable, not compliance-specific |
| Third-party consultant using API to build assessment | API is good enough for external developers |
| Landlord AND tenant on same building, both paying | Multi-stakeholder revenue model works |
| 100+ buildings on platform | Data network effects beginning (benchmarking, pattern recognition) |
| Industry body (BBP/UKGBC/RICS) endorses or references schema | Schema has credibility beyond Secure |

New modules: Risk Diagnosis, ROI / Retrofit Scenarios, Sustainability Reporting, FM Performance Monitoring.

Revenue: Per-building + per-module + early API access fees. £2,000-5,000/building/year.

**Horizon 3 — Infrastructure (30-60 months): "Everything reads from Secure"**

What customers see: Their entire building data stack connected through Secure.
What we're actually building: The default data layer for commercial RE decisions.

| Milestone | Platform Maturity Indicator |
|-----------|---------------------------|
| Third-party modules in marketplace | Developers are building on Secure, not just using it |
| Deepki/Envizi consuming Secure API as data source | Incumbents treat you as infrastructure, not competitor |
| Lenders requiring Secure building profile for loan decisions | Platform is embedded in transaction workflows |
| Valuers referencing Secure risk profiles in RICS Red Book valuations | Platform data influences asset values |
| Insurance underwriters pricing from Secure physical data | Platform serves non-sustainability use cases |
| 1,000+ buildings, multiple countries | Schema works beyond UK, beyond offices |

New modules: Insurance Underwriting feed, Valuation Impact, Green Lease Compliance, Benchmarking, Portfolio ESG Feed. Mostly third-party.

Revenue: Per-building + modules + API + marketplace commission + data licensing. Platform economics.

### 8.3 Module Roadmap — Aligned to Platform Maturity

Every module is mapped to: (a) which platform primitives it requires, (b) which primitives it strengthens, and (c) what horizon it belongs to. This prevents building modules that the platform can't yet support, or modules that don't contribute back.

**Horizon 1 Modules (primitives being established)**

| Module | Requires | Strengthens | Entry Trigger |
|--------|----------|-------------|---------------|
| Compliance Tracker | Property Graph, Activity Data, Coverage Engine | Coverage Engine (forces completeness) | MEES/SECR obligation |
| Stakeholder Data Exchange | Stakeholder Registry, Boundary Engine | Stakeholder Registry, Evidence Store | Occupier needs landlord data |
| AI Agents: Data Readiness | All primitives (read-only) | Coverage Engine (identifies gaps) | Onboarding every building |
| SECR Report Generator | Emissions Engine, Activity Data, Evidence Store, Boundary Engine | Emissions Engine (proves calculation chain), Audit Trail | Annual reporting cycle |

**Horizon 2 Modules (primitives proven, expanding use cases)**

| Module | Requires | Strengthens | Entry Trigger |
|--------|----------|-------------|---------------|
| Risk Diagnosis | All primitives | Property Graph (forces physical completeness for risk assessment) | Acquisition, refinancing, lease renewal |
| ROI / Retrofit Scenarios | Property Graph (system-level), Emissions Engine, Activity Data | Property Graph (models interventions as proposed system changes) | CapEx planning cycle |
| FM Performance Monitoring | Property Graph, Activity Data, Audit Trail | Audit Trail (forces operational data cadence), Activity Data (regular readings) | FM contract renewal / SLA review |
| Asset Tracking (Systems Register) | Property Graph | Property Graph (comprehensive systems register with lifecycle data) | Planned maintenance, compliance |
| Benchmarking (internal) | Activity Data, Coverage Engine, Property Graph | Activity Data (data quality incentive — only good data benchmarks well) | Portfolio with 20+ buildings |

**Horizon 3 Modules (platform is infrastructure, third parties build)**

| Module | Requires | Strengthens | Likely Builder |
|--------|----------|-------------|----------------|
| Portfolio ESG Feed | All primitives (export) | Evidence Store (auditors demand provenance) | Secure API → Deepki/Envizi/Measurabl |
| Insurance Underwriting | Property Graph (physical systems), Activity Data, Risk Diagnosis output | Property Graph (forces physical risk data) | Insurtechs via API |
| Valuation Impact | Risk Diagnosis output, Compliance Tracker, Activity Data | All (valuers need complete picture) | Valuation firms via API |
| Green Lease Compliance | Stakeholder Registry, Activity Data, Boundary Engine | Stakeholder Registry (maps lease obligations to data) | Legal tech / proptech |
| Fit-Out Assessment | Property Graph, Coverage Engine, Compliance Tracker | Coverage Engine (shows what's known vs unknown pre-lease) | Occupier advisory firms |
| Benchmarking (external / anonymised) | Activity Data (aggregated), Property Graph (building type/age) | Data volume (incentivises participation) | Industry bodies, data partners |

### 8.4 Decision Framework: "Should We Build This Module Next?"

When evaluating any proposed module, score it against:

| Criterion | Weight | Question |
|-----------|--------|----------|
| **Primitive strengthening** | 30% | Does it force data into a primitive that's currently weak? (If it only reads and exports, it scores 0.) |
| **Market entry trigger** | 25% | Is there an external event (regulation, deadline, transaction) that forces someone to buy this? |
| **Stakeholder expansion** | 20% | Does it bring a new stakeholder type onto the platform? (Landlord, FM, insurer, valuer) |
| **Revenue per building** | 15% | Does it increase per-building ARPU or unlock a new revenue stream? |
| **Data network effect** | 10% | Does having more buildings make this module better? (Benchmarking does. SECR report generation doesn't.) |

**Minimum threshold:** A module must score above 0 on "Primitive strengthening" to be built. A module that only exports data is a feature, not a module — it can exist as a reporting function within the platform but should not be marketed as a standalone module.

### 8.5 What We DON'T Build (Platform Boundaries)

The platform is the building data layer. These are outside scope:

| Out of Scope | Why | Relationship |
|-------------|-----|--------------|
| **BMS / building controls** | We model systems, we don't operate them. Honeywell, Schneider, Siemens do this. | Data source → Secure ingests readings from BMS via IoT |
| **Utility procurement** | We track consumption, we don't negotiate contracts. | Adjacent — utility data flows into Activity Data |
| **Architectural design / BIM** | We model operational buildings, not design-phase buildings. | Data source → BIM model could seed Property Graph at handover |
| **Tenant experience / workplace** | We model who occupies what, we don't manage bookings or amenities. | Adjacent — workplace platforms could read Stakeholder Registry |
| **Portfolio financial management** | We don't track rents, yields, or deal pipelines. | Adjacent — financial platforms could consume risk/compliance data |
| **Carbon offsetting / credits** | We calculate emissions, we don't trade credits. | Adjacent — offset platforms could read Emissions Engine output |

These boundaries keep the platform focused. If a module proposal falls into this list, it's a third-party opportunity, not a Secure module.

# Lovable Data Library — Cursor context (from Lovable)

Below is the **Cursor-ready description** from Lovable for the **Data Library** end-to-end: tiles, routes, pages, components, and the key engines (Coverage/Emissions/Controllability) that interact with it. Use this to align backend schema, Storage, and upload flows.

---

## Purpose

**Data Library** is Secure's **System of Record (SoR)** for sustainability evidence and activity data. It is organized by **data subject** (what the data is) rather than ingestion method (how it arrived). All records support evidence attachments and audit trail. **Emissions are never stored as primary data**; they are calculated from activity inputs.

---

## IA Overview

### Route: `/data-library`

**Tabs**

1. **My Data** — category tiles (subject-first)
2. **Shared Data** — shared records table (owner/role/source/status)
3. **Connectors** — connector cards (e.g., Power BI, Google Sheets; future: SAP, Salesforce Net Zero, Envizi)

**Global UI Elements**

* Header: title + subtitle (SoR positioning)
* Context badges: Portfolio / Property / Organisation
* Actions:
  * `Manage Access` (admin only)
  * `Add Data` dropdown: Connect Platform / Upload Documents / Manual Entry / Rule Chain

**Access Control**

* Per-category `View only` / `Can edit` badge driven by access map hook (`useDataLibraryAccess` or equivalent). Admin overrides to edit.

---

## My Data Tiles (Subjects) and Routes

### 1) Emissions (Calculated)

* **Purpose:** Derived view of Scope 1/2/3 totals by period, by component, with confidence breakdown.
* **Important:** Not a storage surface. Pulls from Emissions Engine outputs.

> If UI currently uses "Scope 1/2/3 Data" tile: treat it as **derived/calculated** (or refactor into Emissions Calculated). Avoid duplicating activity inputs here.

---

### 2) Energy & Utilities

* **Route:** `/data-library/energy`
* **Purpose:** Activity evidence + component coverage for: electricity, landlord recharges, heating, water, and direct emissions (Scope 1) where applicable.
* **Key design:** Component-based sections, not billing-source-only.

**Components expected on page**

* Tenant Electricity (Direct – submetered)
* Landlord Utilities Recharge (service charge / allocated / cost-only)
* Heating (optional; may be bundled or metered)
* Water (optional; may be bundled or metered)
* Direct Emissions (Scope 1) subcomponents (optional/universal):
  * stationary_combustion (gas/oil/LPG/diesel)
  * onsite_generation (diesel generator)
  * mobile_combustion (fleet)
  * fugitive_emissions (refrigerants)
  * process_emissions (optional)

**Per-component fields**

* Control badge: TENANT / LANDLORD / SHARED
* Confidence: Measured / Allocated / Cost Only / Estimated
* Coverage status: Complete / Partial / Unknown (precomputed)
* KPIs: Records, Coverage (months), Latest
* CTA: View invoices / View recharges / Connect meter / Upload invoice / Manual entry
* Evidence: file attachments + tags
* Audit log: append-only

**Engine interactions**

* CoverageEngine: computes coverage completeness per component & reason codes.
* EmissionsEngine: converts activity quantities into tCO₂e outputs (scope-mapped).
* ControllabilityEngine (recommended): computes tenant vs landlord actionability share via end-use nodes.

---

### 3) Waste & Recycling

* **Route:** `/data-library/waste`
* **Purpose:** Waste activity evidence (contractor invoices, weight reports, diversion certificates).
* **Support:** Single invoice per month/period; optional stream breakdown.
* **Expected streams (140 Aldersgate example):** household waste, mixed glass, food tins & drink cans, plastics, mixed paper & card
* **Scope mapping:** Scope 3 (Category 5) at reporting layer.

---

### 4) Certificates

* **Route:** `/data-library/certificates`
* **Purpose:** Asset certificates (EPC, BREEAM, LEED, ISO, WELL/Fitwel).
* Records track evidence state: Confirmed (FM) vs Verified (Document) once uploaded.

---

### 5) ESG Documents

* **Route:** `/data-library/esg`
* **Purpose:** Policies, disclosures, submissions (e.g., Environmental Policy, Net Zero, GRESB submission, CDP, TCFD, supplier code, anti-corruption).

---

### 6) Governance & Accountability

* **Route:** `/data-library/governance`
* **Purpose:** Structured governance register: Oversight, Policy, Commitment, Engagement, Risk Management.
* Status values: In Place / In Progress / Planned
* Admin/edit features: add/delete items

---

### 7) Targets & Commitments

* **Route:** `/data-library/targets`
* **Purpose:** Target register: Carbon / Energy / Waste / Water.
* Fields: baseline (value+year), target (value+year), status (On Track / At Risk / Behind)
* Bug watch: ensure access map uses correct category ID (`targets`), not `esg_governance`.

---

### 8) Occupant Feedback

* **Route:** `/data-library/occupant-feedback`
* **Purpose:** Survey management (requests, submissions, insights), public form possible.

---

## Shared Subpage Component Pattern (Standard Pages)

Many subpages use a shared component (example: `DataLibrarySubPage`) which provides:

* **Records table** with columns:
  * Record Name
  * Ingestion Method (Upload / Manual / Connector / Rule Chain)
  * Confidence
  * Linked Report
  * Last Updated
  * Actions (View)
* **Row click** opens a right-side drawer/sheet with:
  * metadata badges
  * **Evidence panel** (upload/manage files if edit)
  * **Audit history panel** (append-only)

---

## Canonical Data Model Concepts (for backend alignment)

### Record (Data Library item)

Core metadata:

* subject/category (energy, waste, certificates…)
* ingestion method (upload / manual / connector / rule chain)
* confidence (measured / allocated / cost-only / estimated)
* period (month/quarter/year)
* links: propertyId, optional spaceIds (if demised), optional systemId(s)
* evidence files (PDF, CSV, XLSX, images)
* audit trail events

### Systems Register & Nodes (for controllability)

* Systems have: utilityType, control, appliesToSpaceIds
* End-use nodes link to exactly one system and refine end-use (e.g., toilets_water, pantry_water)
* Nodes carry optional controlOverride + optional allocationWeight + appliesToSpaceIds
* Used by ControllabilityEngine to gate project recommendations.

---

## Engines and Expected Outputs

* **CoverageEngine:** coverageStatus (COMPLETE | PARTIAL | UNKNOWN), reasonCodes, componentState.
* **EmissionsEngine:** calculated tCO₂e per record/component, scope mapping, confidence rollups.
* **ControllabilityEngine:** tenantShare / landlordShare / sharedShare, recommendation gating flags.

(These consume Data Library records; they do not replace storage. Data Library stores activity/evidence; engines compute derived outputs.)

---

## 140 Aldersgate Reference Context

* Tenant demised spaces: Ground, 4th, 5th
* Tenant electricity: Trio submeters (measured)
* Landlord utilities: service charge (allocated/cost-only; breakdown may be missing)
* Water: service charge (allocated; tenant controls pantry end-use but toilets are landlord-controlled)
* Waste: third-party contractor Recorra (measured by weight; invoice may be single line with optional stream breakdown)

---

## Non-goals / Guardrails

* Do not store emissions as editable primary records in Data Library.
* Avoid duplicating "Scope 1/2/3 Data" as both activity and calculated.
* Do not mix Waste as a "billing source card" inside Energy page; Waste is its own subject page.
* All recommendations must respect controllability (tenant vs landlord).

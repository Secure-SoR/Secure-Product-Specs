# Engineering Handoff — Emissions (Calculated) Page  
## React Component Hierarchy + State Logic (v1)

**Date:** 2026-02-19  
**Route:** `/data-library/scope-data` (renamed UI: **"Emissions (Calculated)"**)  
**Goal:** Read-only derived emissions UI reflecting Activity → Scope → Factors → Confidence mapping.

---

## 1) Scope & Non-Goals

### In scope

- Read-only Emissions page UI
- Scope 1/2/3 cards, metadata strip, collapsible breakdown tables
- Row click opens traceability drawer (read-only)
- Percent confidence mix per scope

### Out of scope (for this ticket)

- Building full Emissions Engine backend
- Persisting recalculation logs
- Admin configuration of factor sets
- Editing emissions directly

---

## 2) Data Contracts (Frontend-facing)

### 2.1 Emissions Summary Model (derived)

```ts
type ConfidenceLevel = "measured" | "allocated" | "estimated" | "unknown";

type ScopeId = 1 | 2 | 3;

type ScopeSummary = {
  scope: ScopeId;
  total_tco2e: number;
  percent_of_total: number;   // 0-100
  source_count: number;       // # of activity rows contributing
  confidence_mix: Record<Exclude<ConfidenceLevel, "unknown">, number>; // each 0-1 sum<=1
};
```

### 2.2 Calculation Metadata

```ts
type CalculationMeta = {
  calculationVersion: string;     // e.g. "v1.0"
  factorDatasetName: string;      // e.g. "UK DEFRA"
  factorYear: number;              // e.g. 2023
  scope2Method: "location" | "market" | "hybrid";
  lastCalculatedAtISO: string;     // ISO timestamp
  measuredShare: number;           // 0-1 overall
  allocatedShare: number;         // 0-1 overall
  estimatedShare: number;          // 0-1 overall
};
```

### 2.3 Emissions Line Items (table rows)

```ts
type ActivityDatasetId =
  | "energy_utilities"
  | "waste"
  | "indirect_activities";

type Scope3Category =
  | "cat1_purchased_goods"
  | "cat2_capital_goods"
  | "cat3_fuel_energy_related"
  | "cat6_business_travel"
  | "cat7_employee_commuting"
  | "cat5_waste"
  | "other";

type EmissionsLineItem = {
  id: string;
  scope: ScopeId;
  activityLabel: string;          // e.g. "Tenant Electricity (Trio)"
  datasetId: ActivityDatasetId;
  billingSource?: "tenant_direct" | "landlord_recharge" | "third_party" | "unknown";
  control?: "tenant" | "landlord" | "shared" | "unknown";
  ghgCategory?: Scope3Category;   // scope 3 only
  quantity: number;
  unit: "kWh" | "m3" | "kg" | "km" | "GBP" | "unknown";
  emissionFactor: {
    value: number;                // kgCO2e per unit (or per £)
    unit: string;                 // e.g. "kgCO2e/kWh"
    source: string;               // "DEFRA"
    year: number;
    version: string;              // dataset version tag
  };
  emissions_tco2e: number;
  confidence: ConfidenceLevel;
  period: { startISO: string; endISO: string };
  propertyId?: string;
  organisationId?: string;

  // Traceability pointers (read-only)
  sourceRecordIds?: string[];     // IDs in Data Library
  evidenceFileIds?: string[];     // evidence attachments
};
```

### 2.4 Page View Model

```ts
type EmissionsPageVM = {
  meta: CalculationMeta;
  totals: {
    grandTotal_tco2e: number;
    scopeSummaries: ScopeSummary[];  // 3 entries
  };
  lineItems: EmissionsLineItem[];   // all scopes
};
```

**Note:** In MVP, VM can be mocked/static; later it comes from Emissions Engine API. Engine classification and calculation rules: [Secure_Emissions_Engine_Mapping_v1.md](Secure_Emissions_Engine_Mapping_v1.md).

---

## 3) Component Hierarchy

```
EmissionsCalculatedPage (route component)
├─ PageHeader
│   ├─ Title + Subtitle
│   └─ ContextBadges (Portfolio / Property / Organisation)
│
├─ ScopeSummaryRow
│   ├─ ScopeSummaryCard (Scope 1)
│   │   └─ ConfidenceMixBar
│   ├─ ScopeSummaryCard (Scope 2)
│   │   └─ ConfidenceMixBar
│   └─ ScopeSummaryCard (Scope 3)
│       └─ ConfidenceMixBar
│
├─ CalculationMetaStrip
│
├─ ScopeBreakdownAccordion
│   ├─ ScopeSection (Scope 1)
│   │   └─ EmissionsLineItemsTable
│   ├─ ScopeSection (Scope 2)
│   │   └─ EmissionsLineItemsTable
│   └─ ScopeSection (Scope 3)
│       ├─ Scope3CategoryGroupTabs (optional)
│       └─ EmissionsLineItemsTable
│
└─ TraceabilityDrawer (Sheet)
    ├─ RowSummary
    ├─ FactorDetails
    ├─ FormulaBlock
    ├─ SourceLinks (dataset + record ids)
    └─ EvidenceList (view-only)
```

---

## 4) State & Logic

### 4.1 State Variables (page level)

```ts
const [vm, setVm] = useState<EmissionsPageVM | null>(null);
const [loading, setLoading] = useState(true);
const [error, setError] = useState<string | null>(null);

// UI state
const [openScopes, setOpenScopes] = useState<Record<ScopeId, boolean>>({ 1: false, 2: true, 3: false });
const [activeScope3Category, setActiveScope3Category] = useState<Scope3Category | "all">("all");
const [selectedLineItem, setSelectedLineItem] = useState<EmissionsLineItem | null>(null);
```

### 4.2 Data Loading Strategy (MVP)

- Use existing data-library stores (energy, waste, indirect) only if already available.
- Otherwise load a single consolidated endpoint:  
  `GET /api/emissions/summary?propertyId=...&period=...`
- For Lovable staging, use `mockEmissionsVM_140Aldersgate()`.

**Pseudocode:**

```ts
useEffect(() => {
  setLoading(true);
  fetchOrMockVM()
    .then(setVm)
    .catch(e => setError(String(e)))
    .finally(() => setLoading(false));
}, [propertyId, period]);
```

### 4.3 Derived Selectors

```ts
const scope1Items = vm?.lineItems.filter(x => x.scope === 1) ?? [];
const scope2Items = vm?.lineItems.filter(x => x.scope === 2) ?? [];
const scope3Items = vm?.lineItems.filter(x => x.scope === 3) ?? [];

const scope3ItemsFiltered = activeScope3Category === "all"
  ? scope3Items
  : scope3Items.filter(x => x.ghgCategory === activeScope3Category);
```

### 4.4 Row Click → Drawer

- On table row click: `setSelectedLineItem(item)`
- Drawer open state derived from `selectedLineItem !== null`
- Close: `setSelectedLineItem(null)`

---

## 5) UI Behaviors & Rules

### 5.1 Read-only enforcement

- No "Add Data" button on this page.
- No edit/delete actions in tables.
- Evidence list is view-only (no upload/remove).

### 5.2 Empty states

If a scope has 0 items, show:

- **Scope 1:** "No direct combustion data recorded."
- **Scope 2:** "No purchased energy activity data available."
- **Scope 3:** "No indirect activity data available."

### 5.3 Number formatting

- **tCO2e:** 3 decimals (or 2) consistent across UI
- **Percent:** 0–1 decimals
- **Units** displayed in row: quantity + unit

---

## 6) Styling & Reuse

- Reuse existing Data Library tokens/components:
  - Badges (control, confidence)
  - Context badge component
  - Sheet / Drawer pattern used in DataLibrarySubPage
- Keep scope colors consistent with platform:
  - **Scope 1** = amber
  - **Scope 2** = green
  - **Scope 3** = blue

---

## 7) Integration Points (Later)

When Emissions Engine exists, page will:

- Request VM from backend (single endpoint).
- VM will include:
  - factor dataset tags
  - calc version
  - traceability pointers to source record IDs
  - recalculation timestamps

---

## 8) Acceptance Criteria (Engineering)

- Page title: "Emissions (Calculated)"
- 3 scope cards show totals + confidence mix bar
- Metadata strip visible with factor set & timestamp
- Accordion sections show tables by scope
- Clicking a row opens traceability drawer with factor + formula + evidence links
- No editing actions exist anywhere on the page

---

## 9) Test Checklist

- Snapshot test: cards render with correct totals
- Selector test: scope filters return correct items
- Drawer test: row click opens/closes
- Empty state test per scope
- Read-only test: no add/edit buttons

---

## 10) UI layout and mapping matrix alignment

The page layout should **reflect the Emissions Engine mapping** so users see scope and confidence as outcomes of activity, not manual entries. Reference: [Secure_Emissions_Engine_Mapping_v1.md](Secure_Emissions_Engine_Mapping_v1.md).

| UI element | Mapping matrix reflection |
|------------|----------------------------|
| **Page title** | “Emissions (Calculated)” — reinforces derived layer; no “Scope 1/2/3 Data” (storage) wording. |
| **Scope 1 / 2 / 3 cards** | One card per scope; totals come from **Scope aggregation logic** (sum of all activity emissions in that scope). Card order: 1 → 2 → 3. |
| **Confidence mix bar (per scope)** | **Confidence scoring logic**: Measured → High, Allocated → Medium, Estimated → Low. Display % High / % Medium / % Low from line items in that scope. |
| **Calculation metadata strip** | **Factor versioning**: show factor dataset name, factor year, calculation version, `lastCalculatedAtISO`. Ties to engine’s “recalculate when factor version changes” rule. |
| **Accordion: Scope 1 section** | Table rows = **Activity → Scope** mapping **A (Energy)** rows with Scope 1: Gas (Tenant Direct / Landlord Recharge). Empty state: “No direct combustion data recorded.” |
| **Accordion: Scope 2 section** | Rows = Electricity, District Heat (Energy mapping **A**). Empty state: “No purchased energy activity data available.” |
| **Accordion: Scope 3 section** | Rows = Water (Energy **A**), Waste (**B**), Indirect Activities (**C**). Optional **Scope3CategoryGroupTabs** map to **C** (e.g. Cat 5 waste, Cat 6 travel, Cat 7 commuting). Empty state: “No indirect activity data available.” |
| **Table columns (line items)** | `activityLabel` → human-readable from activity type + billing source; `scope` → from matrix; `quantity` + `unit` → activity input; `emissionFactor` (value, unit, source, year) → factor resolution table; `emissions_tco2e` → **Calculation formula** (quantity × factor ÷ 1000); `confidence` → inherited from activity. |
| **Traceability drawer** | **Formula block**: “Emissions (tCO₂e) = Activity quantity × Emission factor ÷ 1000”. **Source links**: `sourceRecordIds` → Data Library records; **Evidence list**: `evidenceFileIds` (view-only). Reinforces “emissions derived from activity + factor”. |
| **Scope colors** | Scope 1 = amber, Scope 2 = green, Scope 3 = blue — consistent so scope is immediately recognisable. |

**Rule:** Every visible total, percentage, and row must be explainable by the mapping matrix (activity type → scope, factor application, aggregation). No manual scope override in UI.

---

*End of Handoff*

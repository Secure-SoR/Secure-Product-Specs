# Secure — Project Rules (Cursor Context)

Use this when working in the Secure SoR backend. Align with [Secure_Canonical_v5.md](Secure_Canonical_v5.md) and the docs in `docs/`.

---

## 1. Data Library Philosophy

- Data Library is the **System of Record (SoR)**.
- Organised by **subject** (Energy, Waste, Certificates, etc.).
- **Ingestion method** is metadata, not structure.
- **Emissions are NEVER stored manually** — always calculated.

---

## 2. Engines

- **CoverageEngine** → completeness (Complete / Partial / Unknown).
- **EmissionsEngine** → Scope 1/2/3 calculation from activity inputs; never stores emissions as primary data; deterministic scope via [Secure_Emissions_Engine_Mapping_v1.md](docs/sources/Secure_Emissions_Engine_Mapping_v1.md).
- **ControllabilityEngine** → tenant vs landlord actionability shares.

---

## 3. Core Principles

- Activity data lives in subject pages.
- Emissions are derived.
- Waste is separate from Energy.
- Scope classification is deterministic.
- Confidence inherits from activity type.

---

## 4. Control Logic

**Control resolution:**

`node.controlOverride ?? system.control ?? dominantSpace.control`

**Recommendations must:**

- Only suggest tenant actions if `tenantShare > 0`.
- Suggest landlord engagement when `landlordShare > 0`.
- Suppress projects when `coverage == UNKNOWN`.

---

## 5. Coverage vs Controllability

- **Coverage** = data completeness.
- **Controllability** = actionability share.
- They are independent but **both gate recommendations**.

---

## 6. Required Entities

- **systems** — utilityType, control, appliesToSpaces
- **spaces** — control
- **end_use_nodes** — systemId, utilityType, controlOverride?, allocationWeight?, appliesToSpaceIds
- **data_library_records** — subject, period, confidence, evidence

---

## 7. Never Do

- Do not duplicate Scope pages for storage.
- Do not mix Waste under Energy.
- Do not allow manual override of Scope totals.
- Do not recommend landlord-controlled retrofits to tenant users.

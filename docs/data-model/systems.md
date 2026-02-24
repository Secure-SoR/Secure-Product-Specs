# Systems — Canonical Data Model

This document defines how building systems are represented within Secure’s System of Record (SoR).

Systems are first-class entities and drive utility attribution, reporting boundaries, and AI boundary analysis.

**Taxonomy:** System categories, system types, and end-use node taxonomy are defined in [Building Systems Taxonomy (v1.0)](building-systems-taxonomy.md). Use that document for enums and validation rules.

---

## 1. System Entity Definition

```ts
System {
  id: string
  propertyId: string
  name: string
  systemCategory: "Power" | "HVAC" | "Lighting" | "PlugLoads" | "Water" | "Waste" | "BMS" | "Lifts" | "Monitoring" | "Other"
  systemType: string   // enum per taxonomy, e.g. Boilers, TenantLighting, PassengerLift
  spaceClass: "tenant" | "base_building"
  controlledBy: "tenant" | "landlord" | "shared"
  maintainedBy: string
  meteringStatus: "none" | "partial" | "full"
  allocationMethod: "measured" | "area" | "estimated"
  allocationNotes: string
  servesSpaces: string[]
  linkedMeterIds: string[]
  linkedDataLibraryRecordIds: string[]
  createdAt: string
  updatedAt: string
}
```

*Legacy: `category` is superseded by `systemCategory` + `systemType`; retain for compatibility if needed.*

# Systems — Canonical Data Model

This document defines how building systems are represented within Secure’s System of Record (SoR).

Systems are first-class entities and drive utility attribution, reporting boundaries, and AI boundary analysis.

---

## 1. System Entity Definition

```ts
System {
  id: string
  propertyId: string
  name: string
  category: "HVAC" | "Lighting" | "Plug Loads" | "Water" | "Waste" | "Lifts" | "Power" | "BMS" | "Other"
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

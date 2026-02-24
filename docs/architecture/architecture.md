# Secure SoR — Architecture

## 0. Purpose

This document defines:

1. The **current implementation state (Lovable SPA prototype)**
2. The **canonical Secure SoR baseline architecture**
3. A **Gap Matrix** between intent and implementation
4. The **temporary persistence strategy (Supabase)**
5. The **target enterprise architecture (Azure Fastify + Postgres + Blob)**
6. A structured **migration path**

This file is the authoritative architectural reference for Secure SoR.

---

# 1. Current Architecture (As-Is: Lovable SPA)

## 1.1 Runtime & Application Structure

* Framework: **Vite + React + TypeScript**
* Styling: Tailwind CSS
* Routing: `react-router-dom`
* Route definitions: `src/App.tsx`
* State management:

  * React context (e.g., AuthContext, AccountContext)
  * Feature-level hooks
* Persistence: **localStorage only**

  * Wrapper: `src/lib/storage.ts`
  * Key registry: `src/lib/storageKeys.ts`
* Seed logic: `PROPERTIES_SEED_VERSION`

There is **no backend owned by this project**.
The only network calls are to external AI agent endpoints.

---

## 1.2 Routes (UI Surface Map)

* ~67 routes total (62 pages + 5 redirects)
* Major sections:

  * Auth (SignIn, SignUp)
  * Account Settings
  * Property & Onboarding
  * Spaces & Systems
  * Data Library (subject-based)
  * Reports
  * Dashboards (Energy, Carbon, Risk, etc.)
  * Landlord Portal
  * IoT / Device pages
  * Governance & Targets
  * Surveys & Feedback

These routes imply a full SoR system, but persistence does not match that ambition.

---

## 1.3 Domain Entities Implied by the UI

### Core Access & Org

* User
* Account
* Membership (role-based)
* Team / Teamspace

### Asset Hierarchy

* Property
* Space (BuildingSpace)
* SystemInstance
* EndUseNode

### Stakeholders

* Stakeholder
* LandlordDataRequest

### Data Library

* DataLibraryRecord
* Evidence (metadata only)
* AuditEntry (local only)

### Governance

* Targets
* Governance policies

### Reports

* ReportInstance
* Audit log entries

### Agents

* Data Readiness Agent (POST)
* Boundary Agent (POST)
* Agent results (display only)

### Gaps in Domain Implementation

* Meter is not a first-class entity
* IoT devices/sensors not persisted
* Automation rules not persisted
* Risk register entries not persisted
* Carbon credits not persisted
* Retrofit projects not persisted

---

## 1.4 Persistence Model (Current)

All state is stored in localStorage.

### Storage Scopes

| Scope    | Description                                                                               |
| -------- | ----------------------------------------------------------------------------------------- |
| GLOBAL   | users, accounts, memberships, properties, governance, targets, evidence metadata, reports |
| USER     | current user, current account id, signup draft                                            |
| ACCOUNT  | selectedPropertyId, property draft                                                        |
| PROPERTY | spaces, onboarding state                                                                  |

### Critical Observations

* No server validation
* No multi-tenant enforcement
* No audit integrity
* Editable via browser dev tools
* Not suitable for audit-ready reporting

---

## 1.5 External Integrations

Only two outbound API calls exist:

* `POST /api/data-readiness`
* `POST /api/boundary`

Base host:

```
https://ai-agents-sor-boundary-agent-1-1.onrender.com
```

Issues:

* No Authorization header
* Inconsistent base URL configuration
* No persistence of agent run metadata
* No audit of agent outputs

---

## 1.6 Upload Handling

Multiple upload UI components exist:

* Workforce upload
* Certificate upload
* Evidence upload
* Bill upload
* Landlord evidence
* Policy upload
* IoT upload

All are:

* Pure UI
* No file storage
* No binary handling
* No upload progress
* No storage backend

There is currently **zero real document storage**.

---

# 2. Canonical Secure SoR Baseline (Intended Architecture)

Secure SoR must implement the following principles:

---

## 2.1 System-of-Record Principles

1. Authoritative persistence (DB-backed)
2. Multi-tenant enforcement
3. Immutable-ish audit trail
4. Evidence-backed reporting
5. Agent outputs traceable and reviewable
6. Deterministic onboarding state

---

## 2.2 Canonical Onboarding Flow

1. User
2. Account
3. Property
4. Spaces & Systems
5. Metering & Attribution
6. Data Ingestion
7. Dashboards & Reports

Onboarding must behave as a **state machine**, not just screens.

---

## 2.3 Core SoR Entities

### Access Control

* users
* accounts
* account_memberships

### Asset Model

* properties
* spaces
* systems
* meters (first-class entity)
* allocation_method
* metering_status

### Data Library

* data_library_records
* documents
* evidence_attachments
* provenance metadata
* confidence_level

### Agents

* agent_runs
* agent_findings
* validation_status
* approval workflow

### Reporting

* report_instances
* report_versions
* linked_evidence

### Audit

* audit_events
* before/after state
* actor identity
* timestamp

---

# 3. Gap Matrix

| Capability         | Baseline Requirement           | Current Lovable Status | Gap                 |
| ------------------ | ------------------------------ | ---------------------- | ------------------- |
| Auth enforcement   | Secure auth + tenant isolation | LocalStorage only      | Not secure          |
| SoR persistence    | DB-backed                      | LocalStorage           | Not authoritative   |
| Documents stored   | Blob + metadata                | No storage             | Missing             |
| Evidence linking   | record ↔ document              | metadata only          | Not audit-ready     |
| Meter entity       | First-class CRUD               | Not standalone         | Structural gap      |
| Agent runs         | Persisted with audit           | Display only           | Not traceable       |
| Audit trail        | Immutable-ish                  | Local JSON             | Not trustworthy     |
| Upload pipeline    | Signed upload flow             | Mock UI only           | Missing             |
| Landlord workflows | Persisted + secure             | Local only             | Not production-safe |

---

# 4. Temporary Architecture (Phase 1 — Supabase)

Purpose: introduce real persistence with minimal infrastructure overhead.

---

## 4.1 Supabase Components

* Auth (email/password or magic link)
* Postgres database
* Storage bucket: `secure-documents`
* Row Level Security (RLS) enforcing account isolation

---

## 4.2 Entities to Move to Supabase

Immediate priority:

* users (via Supabase Auth)
* profiles
* accounts
* account_memberships
* properties
* spaces
* systems
* meters (new entity)
* data_library_records
* documents
* evidence_attachments
* agent_runs
* agent_findings
* audit_events

**Schema and SQL:** Table definitions and runnable Supabase SQL are in [docs/database/schema.md](../database/schema.md) and [docs/database/supabase-schema.sql](../database/supabase-schema.sql). Use those to create the DB (see schema doc §1 “How to create the DB”).

---

## 4.3 Upload Flow (Supabase Phase)

1. UI selects file
2. Upload to Supabase Storage bucket
3. Insert row in `documents`
4. Insert row in `evidence_attachments`
5. Agent reads via signed URL
6. Agent writes extraction results to `agent_findings`

---

## 4.4 What Stays in LocalStorage (Temporary)

* UI preferences
* Selected property ID
* Non-critical display state

All SoR data moves to database.

---

# 5. Target Architecture (Phase 2 — Azure Enterprise)

---

## 5.1 Components

* Fastify API (Node/TypeScript)
* Azure Database for PostgreSQL
* Azure Blob Storage (`secure-documents`)
* JWT or Entra ID authentication
* Azure Container Apps (deployment)
* Azure Key Vault (secrets)

---

## 5.2 Upload Pattern (Enterprise)

1. Client requests upload-intent
2. Backend creates document row
3. Backend returns SAS URL
4. Client uploads directly to Blob
5. Backend finalize call links record ↔ document
6. Agent writes results via authenticated API

---

## 5.3 Security Model

* Backend enforces account_id on every query
* No client-trusted account identifiers
* Role-based access (admin/member/viewer)
* Immutable audit_events table

---

# 6. Migration Plan

---

## 6.1 LocalStorage → Supabase

1. Extract data via migration script
2. Insert into Supabase tables
3. Disable seed logic
4. Switch UI data source to Supabase

---

## 6.2 Supabase → Azure

1. `pg_dump` Supabase DB
2. Restore to Azure Postgres
3. Copy storage bucket to Azure Blob
4. Replace Supabase client calls with Fastify API calls
5. Enable backend-enforced auth

---

# 7. Architectural Invariants (Must Never Change)

These rules must remain stable across migrations:

* Every row includes `account_id`
* Documents never stored in DB as binary
* Evidence always linked via join table
* Agent outputs never overwrite source values without validation
* Audit events always record actor + timestamp
* Storage key format remains deterministic:

  ```
  account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}
  ```

---

# 8. Next Implementation Priority (Ordered)

1. Implement real authentication
2. Implement real document storage
3. Make Meter a first-class entity
4. Persist agent_runs and agent_findings
5. Add audit_events
6. Remove localStorage as SoR

---

# 9. Conclusion

Current Lovable implementation is a strong UI prototype but not yet a System of Record.

The Supabase phase introduces real persistence and multi-tenant control.

The Azure phase introduces enterprise-grade enforcement and infrastructure alignment.

This document is the architectural baseline for all future implementation decisions.

---

If you would like, next I can generate:

* The exact Supabase SQL schema aligned to this document
* Or the Meter entity + metering model extension
* Or a visual architecture diagram (logical layer view)

# Secure SoR

Secure is a real estate sustainability System of Record (SoR) for corporate occupiers.

This repository contains:
- Canonical architecture documentation
- Data model specifications
- **Database schema** (Supabase Phase 1): `docs/database/schema.md` and `docs/database/supabase-schema.sql`
- AI Agent contracts
- Reporting integration rules

**Phase 1 persistence (Supabase)** is implemented for auth, accounts, memberships, properties, spaces, systems, data library records, and document storage (Storage bucket `secure-documents` + `documents` and `evidence_attachments` tables).

See `Secure_Canonical_v5.md` for product and domain model; `docs/architecture/architecture.md` for implementation state and migration; `docs/database/schema.md` for DB table definitions and how to create the Supabase project. **App route map** (Landing → Sign in → Login/Signup → Dashboard): `docs/APP-ROUTE-MAP.md`.

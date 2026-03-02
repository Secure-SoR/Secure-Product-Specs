# Changelog

All notable changes to Secure will be documented in this file.

This project follows Semantic Versioning (SemVer).

---

## [5.2.0] - 2026-02-27
### Added
- Phase 1 Supabase persistence: accounts and account_memberships creation and read from Supabase.
- Real document storage: uploads to Supabase Storage bucket `secure-documents`, with rows in `documents` and `evidence_attachments` linking files to data library records.
- Architecture and Gap Matrix updated to reflect Supabase account/membership wiring and document/evidence upload pipeline as complete.
- **docs/APP-ROUTE-MAP.md** — canonical app route map (Landing at `/` → Sign in → Login/Signup → Dashboard; all app routes behind auth). Referenced from architecture §1.2, LOVABLE-PROMPT-FIX-PUBLIC-PAGE-ROUTING.md, LOVABLE-PUBLIC-PAGE-COPY-SECURETIGRE.md, and AI Agents MODE-AND-WORKFLOW.md + LOVABLE-PROMPTS-FOR-AGENTS.md.

### Changed
- Lovable app now uses Supabase for auth, accounts, memberships, properties, spaces, systems, data library records, and document uploads; only UI preferences and non-critical display state remain in localStorage.
- Persistence model (§1.4) and Upload handling (§1.6) documentation updated for current Supabase-backed implementation.

---

## [5.1.0] - 2026-02-18
### Added
- Billing-source-based utility model
- AI Workspace SoR enforcement
- Waste page KPI summary block

### Changed
- Landlord Utilities routing logic
- Reporting modules now consume structured SoR datasets only

### Removed
- Separate Water (Landlord) tile
- Mixed tenant/landlord utility grouping
- Standalone synthetic heat category


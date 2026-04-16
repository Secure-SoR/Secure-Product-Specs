-- Asset Tracking v2.0 — DALI light fixture system_type value
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.13
--
-- The canonical docs/database/supabase-schema.sql does NOT define a CHECK constraint on
-- public.systems.system_type (it is free-form text). Use system_type = 'DALILight' with
-- system_category = 'Lighting' in the app / register for DALI fixtures.
--
-- If your database has a custom CHECK on system_type, extend that constraint here to include
-- 'DALILight' without removing existing allowed values. Example pattern:
--
-- ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_system_type_check;
-- ALTER TABLE public.systems ADD CONSTRAINT systems_system_type_check
--   CHECK (system_type IS NULL OR system_type IN (..., 'DALILight'));

-- Intentionally no-op for standard Secure SoR schema.
SELECT 1 AS extend_systems_type_dalilight_noop;

-- Add name and extend source_type / confidence for Data Library (Lovable alignment)
-- Run once on existing DB. Safe for new installs if applied after supabase-schema.sql.

-- 1. Add optional display name for "Record Name" in UI
ALTER TABLE public.data_library_records
  ADD COLUMN IF NOT EXISTS name text;

COMMENT ON COLUMN public.data_library_records.name IS 'Display name for the record (e.g. "Electricity Jan 2026", "Sustainability policy")';

-- 2. Extend source_type to allow rule_chain (Lovable "Rule Chain" in Add Data)
ALTER TABLE public.data_library_records DROP CONSTRAINT IF EXISTS data_library_records_source_type_check;
ALTER TABLE public.data_library_records
  ADD CONSTRAINT data_library_records_source_type_check
  CHECK (source_type IN ('connector', 'upload', 'manual', 'rule_chain'));

-- 3. Extend confidence to allow cost_only (Energy: landlord recharge cost-only)
ALTER TABLE public.data_library_records DROP CONSTRAINT IF EXISTS data_library_records_confidence_check;
ALTER TABLE public.data_library_records
  ADD CONSTRAINT data_library_records_confidence_check
  CHECK (confidence IN ('measured', 'allocated', 'estimated', 'cost_only'));

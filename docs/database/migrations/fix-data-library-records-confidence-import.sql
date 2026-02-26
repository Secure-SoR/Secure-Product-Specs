-- Fix: "new row for relation data_library_records violates check constraint data_library_records_confidence_check"
-- The UI often sends "Measured", "Cost Only", "Estimated" (title case) or "cost only" (with space).
-- The DB only accepts: measured, allocated, estimated, cost_only (lowercase, underscore).
-- This trigger normalizes before insert/update. Run in Supabase → SQL Editor.

CREATE OR REPLACE FUNCTION public.normalize_data_library_records_confidence()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v text;
BEGIN
  v := lower(trim(COALESCE(NEW.confidence, '')));
  -- Replace space with underscore for "cost only" → cost_only
  v := replace(v, ' ', '_');

  -- Already valid
  IF v IN ('measured', 'allocated', 'estimated', 'cost_only') THEN
    NEW.confidence := v;
    RETURN NEW;
  END IF;

  -- Common display variants
  IF v IN ('measured', 'measure') THEN
    NEW.confidence := 'measured';
    RETURN NEW;
  END IF;
  IF v IN ('allocated', 'allocation') THEN
    NEW.confidence := 'allocated';
    RETURN NEW;
  END IF;
  IF v IN ('estimated', 'estimate') THEN
    NEW.confidence := 'estimated';
    RETURN NEW;
  END IF;
  IF v IN ('cost_only', 'costonly') THEN
    NEW.confidence := 'cost_only';
    RETURN NEW;
  END IF;

  -- Default so insert does not fail
  NEW.confidence := 'estimated';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS normalize_data_library_records_confidence_trigger ON public.data_library_records;
CREATE TRIGGER normalize_data_library_records_confidence_trigger
  BEFORE INSERT OR UPDATE OF confidence ON public.data_library_records
  FOR EACH ROW
  EXECUTE FUNCTION public.normalize_data_library_records_confidence();

COMMENT ON FUNCTION public.normalize_data_library_records_confidence() IS
  'Normalizes confidence to measured|allocated|estimated|cost_only for Data Library manual entry and import.';

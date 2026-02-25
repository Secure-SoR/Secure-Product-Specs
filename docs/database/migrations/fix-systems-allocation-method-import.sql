-- Fix: "new row for relation systems violates check constraint systems_allocation_method_check"
-- When importing from CSV/Excel, the "Allocation Method" column often has values like
-- "Service charge allocation", "Direct measured", "Embedded in service charge" — the DB only
-- accepts: measured, area, estimated, mixed. This trigger normalizes before insert/update.
-- Run this in Supabase → SQL Editor.

-- 1. Ensure 'mixed' is allowed (if your DB had the old 3-value constraint)
ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_allocation_method_check;
ALTER TABLE public.systems ADD CONSTRAINT systems_allocation_method_check
  CHECK (allocation_method IN ('measured', 'area', 'estimated', 'mixed'));

-- 2. Normalize any raw value (e.g. from CSV) to one of the four
CREATE OR REPLACE FUNCTION public.normalize_systems_allocation_method()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v text;
BEGIN
  v := lower(trim(COALESCE(NEW.allocation_method, '')));
  -- Already valid
  IF v IN ('measured', 'area', 'estimated', 'mixed') THEN
    RETURN NEW;
  END IF;
  -- Map common spreadsheet phrases to DB values
  IF v LIKE '%direct%measured%' OR v LIKE '%direct%billed%' OR v = 'measured' THEN
    NEW.allocation_method := 'measured';
    RETURN NEW;
  END IF;
  IF v LIKE '%service%charge%' OR v LIKE '%area%allocation%' OR v LIKE '%embedded%'
     OR v LIKE '%whole building%' OR v LIKE '%submeter%split%' OR v = 'area' THEN
    NEW.allocation_method := 'area';
    RETURN NEW;
  END IF;
  IF v LIKE '%mixed%' OR v LIKE '%part%measured%' OR v LIKE '%electricity%service%charge%' THEN
    NEW.allocation_method := 'mixed';
    RETURN NEW;
  END IF;
  IF v LIKE '%estimated%' OR v = 'estimated' THEN
    NEW.allocation_method := 'estimated';
    RETURN NEW;
  END IF;
  -- N/A, empty, or unknown → default to estimated
  NEW.allocation_method := 'estimated';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS normalize_systems_allocation_method_trigger ON public.systems;
CREATE TRIGGER normalize_systems_allocation_method_trigger
  BEFORE INSERT OR UPDATE OF allocation_method ON public.systems
  FOR EACH ROW EXECUTE FUNCTION public.normalize_systems_allocation_method();

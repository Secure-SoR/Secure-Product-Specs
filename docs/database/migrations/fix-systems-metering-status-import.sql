-- Fix: "new row for relation systems violates check constraint systems_metering_status_check"
-- CSV/Excel "Metering Status" has values like "Submetered", "Fiscal only", "Not tenant-metered" —
-- the DB only accepts: none, partial, full. This trigger normalizes before insert/update.
-- Run this in Supabase → SQL Editor.

CREATE OR REPLACE FUNCTION public.normalize_systems_metering_status()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v text;
BEGIN
  v := lower(trim(COALESCE(NEW.metering_status, '')));
  -- Already valid
  IF v IN ('none', 'partial', 'full') THEN
    RETURN NEW;
  END IF;
  -- No / not metered → none
  IF v LIKE '%not%metered%' OR v LIKE '%not tenant%metered%' OR v LIKE '%not separately metered%'
     OR v LIKE '%fiscal only%' OR v = 'n/a' OR v LIKE '%n/a%' OR v LIKE '%data-only%' OR v LIKE '%data only%'
     OR v LIKE '%included in electricity%' OR v LIKE '%not metered%' OR v = 'none' THEN
    NEW.metering_status := 'none';
    RETURN NEW;
  END IF;
  -- Submetered, direct measured, measured by weight, single fiscal meter → partial (or full for tenant)
  IF v LIKE '%submetered%' OR v LIKE '%direct measured%' OR v LIKE '%measured by weight%'
     OR v LIKE '%single fiscal%' OR v LIKE '%fiscal meter%' OR v = 'partial' OR v = 'full' THEN
    NEW.metering_status := 'partial';
    RETURN NEW;
  END IF;
  -- Default
  NEW.metering_status := 'partial';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS normalize_systems_metering_status_trigger ON public.systems;
CREATE TRIGGER normalize_systems_metering_status_trigger
  BEFORE INSERT OR UPDATE OF metering_status ON public.systems
  FOR EACH ROW EXECUTE FUNCTION public.normalize_systems_metering_status();

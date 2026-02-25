-- Fix: "new row for relation systems violates check constraint systems_controlled_by_check"
-- Run this in Supabase → SQL Editor. It allows the app to send "tenant_controlled" / "landlord_controlled"
-- (from spaces) and normalizes them to tenant / landlord before storing.

-- 1. Allow tenant_controlled and landlord_controlled in the constraint
ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_controlled_by_check;
ALTER TABLE public.systems ADD CONSTRAINT systems_controlled_by_check
  CHECK (controlled_by IN ('tenant', 'landlord', 'shared', 'tenant_controlled', 'landlord_controlled'));

-- 2. Normalize to tenant | landlord | shared on insert/update
CREATE OR REPLACE FUNCTION public.normalize_systems_controlled_by()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.controlled_by := CASE NEW.controlled_by
    WHEN 'tenant_controlled' THEN 'tenant'
    WHEN 'landlord_controlled' THEN 'landlord'
    ELSE NEW.controlled_by
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS normalize_systems_controlled_by_trigger ON public.systems;
CREATE TRIGGER normalize_systems_controlled_by_trigger
  BEFORE INSERT OR UPDATE OF controlled_by ON public.systems
  FOR EACH ROW EXECUTE FUNCTION public.normalize_systems_controlled_by();

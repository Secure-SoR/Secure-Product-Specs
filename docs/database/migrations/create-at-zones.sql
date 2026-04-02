-- Asset Tracking v2.0 — at_zones
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.3
-- Depends: at_floors, properties, spaces (optional FK), account_memberships.

CREATE TABLE IF NOT EXISTS public.at_zones (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  floor_id uuid NOT NULL REFERENCES public.at_floors(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  zone_type text NOT NULL CHECK (zone_type IN ('public', 'restricted', 'staff_entry')),
  polygon jsonb NOT NULL,
  space_id uuid REFERENCES public.spaces(id) ON DELETE SET NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_at_zones_floor_id ON public.at_zones(floor_id);
CREATE INDEX IF NOT EXISTS idx_at_zones_property_zone_type ON public.at_zones(property_id, zone_type);
CREATE INDEX IF NOT EXISTS idx_at_zones_account_id ON public.at_zones(account_id);

ALTER TABLE public.at_zones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_zones in their accounts" ON public.at_zones;
DROP POLICY IF EXISTS "Members can insert at_zones in their accounts" ON public.at_zones;
DROP POLICY IF EXISTS "Members can update at_zones in their accounts" ON public.at_zones;
DROP POLICY IF EXISTS "Members can delete at_zones in their accounts" ON public.at_zones;

CREATE POLICY "Members can read at_zones in their accounts"
  ON public.at_zones FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_zones in their accounts"
  ON public.at_zones FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_zones in their accounts"
  ON public.at_zones FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_zones in their accounts"
  ON public.at_zones FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_zones IS 'Asset Tracking: zone polygons on a floor plan; optional link to spaces.id (space_id).';
COMMENT ON COLUMN public.at_zones.space_id IS 'Optional cross-reference to Secure spaces; AT does not modify spaces.';

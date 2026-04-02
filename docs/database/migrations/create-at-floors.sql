-- Asset Tracking v2.0 — at_floors
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.2
-- Depends: accounts, properties, account_memberships (RLS pattern).

CREATE TABLE IF NOT EXISTS public.at_floors (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  level_index integer,
  floor_plan_image_url text,
  floor_plan_width_px integer,
  floor_plan_height_px integer,
  coord_system text NOT NULL CHECK (coord_system IN ('pixel', 'local_metres', 'gps')),
  gps_calibration jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_at_floors_account_id ON public.at_floors(account_id);
CREATE INDEX IF NOT EXISTS idx_at_floors_property_id ON public.at_floors(property_id);

ALTER TABLE public.at_floors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_floors in their accounts" ON public.at_floors;
DROP POLICY IF EXISTS "Members can insert at_floors in their accounts" ON public.at_floors;
DROP POLICY IF EXISTS "Members can update at_floors in their accounts" ON public.at_floors;
DROP POLICY IF EXISTS "Members can delete at_floors in their accounts" ON public.at_floors;

CREATE POLICY "Members can read at_floors in their accounts"
  ON public.at_floors FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_floors in their accounts"
  ON public.at_floors FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_floors in their accounts"
  ON public.at_floors FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_floors in their accounts"
  ON public.at_floors FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_floors IS 'Asset Tracking: one row per floor / level; floor plan metadata; references properties only (not spaces).';

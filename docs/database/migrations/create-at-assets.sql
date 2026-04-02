-- Asset Tracking v2.0 — at_assets
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.5
-- tag_id FK is added in add-at-assets-tag-id-fk.sql after at_asset_tags exists.

CREATE TABLE IF NOT EXISTS public.at_assets (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  asset_type_id uuid REFERENCES public.at_asset_types(id) ON DELETE SET NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  default_zone_id uuid REFERENCES public.at_zones(id) ON DELETE SET NULL,
  tag_id uuid,
  status text NOT NULL CHECK (status IN ('active', 'inactive', 'in_maintenance')),
  serial_number text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_at_assets_account_id ON public.at_assets(account_id);
CREATE INDEX IF NOT EXISTS idx_at_assets_property_id ON public.at_assets(property_id);
CREATE INDEX IF NOT EXISTS idx_at_assets_asset_type_id ON public.at_assets(asset_type_id);
CREATE INDEX IF NOT EXISTS idx_at_assets_tag_id ON public.at_assets(tag_id);

ALTER TABLE public.at_assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_assets in their accounts" ON public.at_assets;
DROP POLICY IF EXISTS "Members can insert at_assets in their accounts" ON public.at_assets;
DROP POLICY IF EXISTS "Members can update at_assets in their accounts" ON public.at_assets;
DROP POLICY IF EXISTS "Members can delete at_assets in their accounts" ON public.at_assets;

CREATE POLICY "Members can read at_assets in their accounts"
  ON public.at_assets FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_assets in their accounts"
  ON public.at_assets FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_assets in their accounts"
  ON public.at_assets FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_assets in their accounts"
  ON public.at_assets FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_assets IS 'Asset Tracking: trackable instances (people/equipment) per property.';
COMMENT ON COLUMN public.at_assets.tag_id IS 'FK to at_asset_tags added by migration add-at-assets-tag-id-fk.sql.';

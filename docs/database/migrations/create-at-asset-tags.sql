-- Asset Tracking v2.0 — at_asset_tags (Wirepas tags; never in systems)
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.6
-- Depends: at_assets (for assigned_asset_id FK).

CREATE TABLE IF NOT EXISTS public.at_asset_tags (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  wirepas_node_id text NOT NULL,
  mac_address text,
  tag_model text,
  has_panic_button boolean NOT NULL DEFAULT false,
  panic_button_action text CHECK (panic_button_action IS NULL OR panic_button_action IN ('panic', 'movement_detection', 'custom_scene')),
  battery_level_pct numeric,
  firmware_version text,
  status text NOT NULL CHECK (status IN ('active', 'inactive', 'unassigned')),
  assigned_asset_id uuid REFERENCES public.at_assets(id) ON DELETE SET NULL,
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id, wirepas_node_id)
);

CREATE INDEX IF NOT EXISTS idx_at_asset_tags_account_id ON public.at_asset_tags(account_id);
CREATE INDEX IF NOT EXISTS idx_at_asset_tags_property_id ON public.at_asset_tags(property_id);
CREATE INDEX IF NOT EXISTS idx_at_asset_tags_assigned_asset_id ON public.at_asset_tags(assigned_asset_id);

-- One tag row per assigned asset at a time (column is scalar; index prevents duplicate assignment rows)
CREATE UNIQUE INDEX IF NOT EXISTS at_asset_tags_one_row_per_assigned_asset
  ON public.at_asset_tags (assigned_asset_id)
  WHERE assigned_asset_id IS NOT NULL;

ALTER TABLE public.at_asset_tags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_asset_tags in their accounts" ON public.at_asset_tags;
DROP POLICY IF EXISTS "Members can insert at_asset_tags in their accounts" ON public.at_asset_tags;
DROP POLICY IF EXISTS "Members can update at_asset_tags in their accounts" ON public.at_asset_tags;
DROP POLICY IF EXISTS "Members can delete at_asset_tags in their accounts" ON public.at_asset_tags;

CREATE POLICY "Members can read at_asset_tags in their accounts"
  ON public.at_asset_tags FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_asset_tags in their accounts"
  ON public.at_asset_tags FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_asset_tags in their accounts"
  ON public.at_asset_tags FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_asset_tags in their accounts"
  ON public.at_asset_tags FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_asset_tags IS 'Asset Tracking: Wirepas RTLS tags; mutually exclusive with systems register per spec §2.';

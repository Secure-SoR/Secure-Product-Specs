-- Asset Tracking v2.0 — at_asset_types
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.3–6.4
-- Account-level: property_id IS NULL. Property extension: property_id set.
-- Uniqueness: partial unique indexes (PostgreSQL treats NULLs as distinct in plain UNIQUE).

CREATE TABLE IF NOT EXISTS public.at_asset_types (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  category text NOT NULL CHECK (category IN ('workers', 'drilling_equipments', 'loading_equipments', 'medical_kit')),
  icon_key text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_at_asset_types_account_id ON public.at_asset_types(account_id);
CREATE INDEX IF NOT EXISTS idx_at_asset_types_property_id ON public.at_asset_types(property_id);

CREATE UNIQUE INDEX IF NOT EXISTS at_asset_types_account_name_account_level
  ON public.at_asset_types (account_id, name)
  WHERE property_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS at_asset_types_account_property_name
  ON public.at_asset_types (account_id, property_id, name)
  WHERE property_id IS NOT NULL;

ALTER TABLE public.at_asset_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_asset_types in their accounts" ON public.at_asset_types;
DROP POLICY IF EXISTS "Members can insert at_asset_types in their accounts" ON public.at_asset_types;
DROP POLICY IF EXISTS "Members can update at_asset_types in their accounts" ON public.at_asset_types;
DROP POLICY IF EXISTS "Members can delete at_asset_types in their accounts" ON public.at_asset_types;

CREATE POLICY "Members can read at_asset_types in their accounts"
  ON public.at_asset_types FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_asset_types in their accounts"
  ON public.at_asset_types FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_asset_types in their accounts"
  ON public.at_asset_types FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_asset_types in their accounts"
  ON public.at_asset_types FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_asset_types IS 'Asset Tracking: master asset taxonomy; account-level (property_id null) or per-property extension.';
COMMENT ON COLUMN public.at_asset_types.icon_key IS 'Immutable after creation per product rules; enforce in app.';

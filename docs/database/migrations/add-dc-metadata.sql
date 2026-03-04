-- Data Centre metadata table (one row per data centre property)
-- Spec: docs/specs/secure-dc-spec-v2.md Section 2.2
-- Run after supabase-schema.sql (depends on accounts, properties, account_memberships).

CREATE TABLE IF NOT EXISTS public.dc_metadata (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  tier_level text,
  design_capacity_mw numeric,
  current_it_load_mw numeric,
  total_white_floor_sqm numeric,
  cooling_type text[],
  power_supply_redundancy text,
  target_pue numeric,
  renewable_energy_pct numeric,
  water_usage_effectiveness_target numeric,
  certifications text[],
  sitdeck_site_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(property_id)
);

CREATE INDEX IF NOT EXISTS idx_dc_metadata_account_id ON public.dc_metadata(account_id);
CREATE INDEX IF NOT EXISTS idx_dc_metadata_property_id ON public.dc_metadata(property_id);

COMMENT ON TABLE public.dc_metadata IS 'Data centre–specific metadata; one row per property with asset_type = data_centre';

-- RLS: account-scoped (same pattern as other tables)
ALTER TABLE public.dc_metadata ENABLE ROW LEVEL SECURITY;

-- Drop policies if they exist so this migration can be re-run safely
DROP POLICY IF EXISTS "Members can read dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can insert dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can update dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can delete dc_metadata in their accounts" ON public.dc_metadata;

CREATE POLICY "Members can read dc_metadata in their accounts"
  ON public.dc_metadata FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert dc_metadata in their accounts"
  ON public.dc_metadata FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update dc_metadata in their accounts"
  ON public.dc_metadata FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete dc_metadata in their accounts"
  ON public.dc_metadata FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

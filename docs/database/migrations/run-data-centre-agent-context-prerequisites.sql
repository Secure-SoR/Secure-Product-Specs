-- =============================================================================
-- Data Centre — prerequisites for agent context + DC UI (one paste for Supabase)
-- =============================================================================
-- Run in Supabase → SQL Editor after core tables exist (accounts, properties,
-- spaces, account_memberships).
--
-- Combines:
--   add-properties-lat-lng.sql
--   add-tenancy-type-property-and-spaces.sql
--   add-dc-metadata.sql
--
-- Spec: docs/specs/secure-dc-spec-v2.md
-- Guide: docs/specs/implementation-guide-agent-context-data-centre.md
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1) properties.latitude / longitude (SitDeck, maps)
-- -----------------------------------------------------------------------------
ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS latitude numeric,
  ADD COLUMN IF NOT EXISTS longitude numeric;

COMMENT ON COLUMN public.properties.latitude IS 'Property latitude for maps and SitDeck widgets';
COMMENT ON COLUMN public.properties.longitude IS 'Property longitude for maps and SitDeck widgets';

-- -----------------------------------------------------------------------------
-- 2) tenancy_type on properties + spaces (DC / spaces UI)
-- -----------------------------------------------------------------------------
ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS tenancy_type text CHECK (tenancy_type IN ('whole', 'partial'));

COMMENT ON COLUMN public.properties.tenancy_type IS 'Tenancy type for space population: whole (Whole Building) or partial (Partial Building). Used by DC/spaces page; selector persists here; spaces are scoped by this.';

ALTER TABLE public.spaces
  ADD COLUMN IF NOT EXISTS tenancy_type text CHECK (tenancy_type IN ('whole', 'partial'));

COMMENT ON COLUMN public.spaces.tenancy_type IS 'Tenancy type at creation: whole or partial. Spaces are mutually exclusive by type; queries and writes must scope by property.tenancy_type.';

CREATE INDEX IF NOT EXISTS idx_spaces_property_id_tenancy_type
  ON public.spaces(property_id, tenancy_type);

-- -----------------------------------------------------------------------------
-- 3) dc_metadata (required for Lovable dcMetadata in agent POST body)
-- -----------------------------------------------------------------------------
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

ALTER TABLE public.dc_metadata ENABLE ROW LEVEL SECURITY;

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

-- =============================================================================
-- End. Verify: SELECT * FROM dc_metadata LIMIT 1; SELECT latitude FROM properties LIMIT 1;
-- =============================================================================

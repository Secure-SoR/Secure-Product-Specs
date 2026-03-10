-- Tenancy type: Whole Building vs Partial Building (Data Centre / spaces page).
-- Persists the selector on the property; spaces are tagged so they are mutually exclusive by type.
-- Run after supabase-schema.sql. Idempotent.

-- Property: current tenancy type selection for the space population UI
ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS tenancy_type text CHECK (tenancy_type IN ('whole', 'partial'));

COMMENT ON COLUMN public.properties.tenancy_type IS 'Tenancy type for space population: whole (Whole Building) or partial (Partial Building). Used by DC/spaces page; selector persists here; spaces are scoped by this.';

-- Space: which tenancy type this space belongs to (mutually exclusive: a space is either whole or partial)
ALTER TABLE public.spaces
  ADD COLUMN IF NOT EXISTS tenancy_type text CHECK (tenancy_type IN ('whole', 'partial'));

COMMENT ON COLUMN public.spaces.tenancy_type IS 'Tenancy type at creation: whole or partial. Spaces are mutually exclusive by type; queries and writes must scope by property.tenancy_type.';

CREATE INDEX IF NOT EXISTS idx_spaces_property_id_tenancy_type
  ON public.spaces(property_id, tenancy_type);

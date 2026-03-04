-- Add latitude and longitude to properties (for SitDeck widgets and location-based features)
-- Spec: secure-dc-spec-v2.md clarification summary; surface on Integrations & Evidence.

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS latitude numeric,
  ADD COLUMN IF NOT EXISTS longitude numeric;

COMMENT ON COLUMN public.properties.latitude IS 'Property latitude for maps and SitDeck widgets';
COMMENT ON COLUMN public.properties.longitude IS 'Property longitude for maps and SitDeck widgets';

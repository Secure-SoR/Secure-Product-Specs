-- Asset Tracking v2.0 — enable flag per property
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.13
-- Run in Supabase SQL Editor after core schema exists.

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS at_enabled boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.properties.at_enabled IS 'When true, Asset Tracking module is active for this facility; shows property tab and AT routes.';

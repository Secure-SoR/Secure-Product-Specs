-- Asset Tracking v2.0 — complete at_assets.tag_id → at_asset_tags circular FK
-- Run after: create-at-assets.sql, create-at-asset-tags.sql

ALTER TABLE public.at_assets
  DROP CONSTRAINT IF EXISTS at_assets_tag_id_fkey;

ALTER TABLE public.at_assets
  ADD CONSTRAINT at_assets_tag_id_fkey
  FOREIGN KEY (tag_id) REFERENCES public.at_asset_tags(id) ON DELETE SET NULL;

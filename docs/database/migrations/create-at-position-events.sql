-- Asset Tracking v2.0 — at_position_events (append-only; high volume)
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.8
-- Retention / archive: Phase 4 (at_position_archive job).

CREATE TABLE IF NOT EXISTS public.at_position_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  asset_id uuid NOT NULL REFERENCES public.at_assets(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES public.at_asset_tags(id) ON DELETE SET NULL,
  floor_id uuid REFERENCES public.at_floors(id) ON DELETE SET NULL,
  zone_id uuid REFERENCES public.at_zones(id) ON DELETE SET NULL,
  x_pos numeric,
  y_pos numeric,
  accuracy_m numeric,
  source text NOT NULL CHECK (source IN ('wirepas', 'manual', 'simulated')),
  recorded_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_at_position_events_asset_recorded_desc
  ON public.at_position_events (asset_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_at_position_events_property_floor_recorded_desc
  ON public.at_position_events (property_id, floor_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_at_position_events_asset_recorded_asc
  ON public.at_position_events (asset_id, recorded_at);

CREATE INDEX IF NOT EXISTS idx_at_position_events_property_zone_recorded
  ON public.at_position_events (property_id, zone_id, recorded_at);

CREATE INDEX IF NOT EXISTS idx_at_position_events_account_id ON public.at_position_events(account_id);

ALTER TABLE public.at_position_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_position_events in their accounts" ON public.at_position_events;
DROP POLICY IF EXISTS "Members can insert at_position_events in their accounts" ON public.at_position_events;

CREATE POLICY "Members can read at_position_events in their accounts"
  ON public.at_position_events FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_position_events in their accounts"
  ON public.at_position_events FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- No UPDATE/DELETE policies for authenticated clients (append-only); service role bypasses RLS for maintenance jobs.

COMMENT ON TABLE public.at_position_events IS 'Asset Tracking: raw position fixes; append-only for 90-day window per spec.';

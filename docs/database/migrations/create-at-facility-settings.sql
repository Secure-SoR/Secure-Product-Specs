-- Asset Tracking v2.0 — at_facility_settings (one row per AT-enabled property)
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.12

CREATE TABLE IF NOT EXISTS public.at_facility_settings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  position_update_interval_sec integer NOT NULL DEFAULT 15 CHECK (position_update_interval_sec >= 5 AND position_update_interval_sec <= 60),
  prolonged_idle_threshold_min integer NOT NULL DEFAULT 60,
  panic_button_default_action text NOT NULL CHECK (panic_button_default_action IN ('panic', 'movement_detection', 'custom_scene')),
  out_of_zone_enabled boolean NOT NULL DEFAULT true,
  restricted_entry_enabled boolean NOT NULL DEFAULT true,
  dali_motion_timeout_sec integer,
  dali_dh_setpoint_als integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id)
);

CREATE INDEX IF NOT EXISTS idx_at_facility_settings_account_id ON public.at_facility_settings(account_id);

ALTER TABLE public.at_facility_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_facility_settings in their accounts" ON public.at_facility_settings;
DROP POLICY IF EXISTS "Members can insert at_facility_settings in their accounts" ON public.at_facility_settings;
DROP POLICY IF EXISTS "Members can update at_facility_settings in their accounts" ON public.at_facility_settings;
DROP POLICY IF EXISTS "Members can delete at_facility_settings in their accounts" ON public.at_facility_settings;

CREATE POLICY "Members can read at_facility_settings in their accounts"
  ON public.at_facility_settings FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_facility_settings in their accounts"
  ON public.at_facility_settings FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_facility_settings in their accounts"
  ON public.at_facility_settings FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_facility_settings in their accounts"
  ON public.at_facility_settings FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_facility_settings IS 'Asset Tracking: per-facility thresholds and toggles; not user prefs.';

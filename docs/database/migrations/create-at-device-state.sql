-- Asset Tracking v2.0 — at_device_state (DALI live cache; FK to systems only)
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.10

CREATE TABLE IF NOT EXISTS public.at_device_state (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  system_id uuid NOT NULL REFERENCES public.systems(id) ON DELETE CASCADE,
  online boolean NOT NULL DEFAULT false,
  light_on boolean,
  dim_level_pct numeric,
  als_value numeric,
  daylight_harvesting_active boolean,
  daylight_harvesting_pct numeric,
  behaviour_mode_index integer,
  power_watts numeric,
  last_updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (system_id)
);

CREATE INDEX IF NOT EXISTS idx_at_device_state_account_id ON public.at_device_state(account_id);

ALTER TABLE public.at_device_state ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_device_state in their accounts" ON public.at_device_state;
DROP POLICY IF EXISTS "Members can insert at_device_state in their accounts" ON public.at_device_state;
DROP POLICY IF EXISTS "Members can update at_device_state in their accounts" ON public.at_device_state;
DROP POLICY IF EXISTS "Members can delete at_device_state in their accounts" ON public.at_device_state;

CREATE POLICY "Members can read at_device_state in their accounts"
  ON public.at_device_state FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_device_state in their accounts"
  ON public.at_device_state FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_device_state in their accounts"
  ON public.at_device_state FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_device_state in their accounts"
  ON public.at_device_state FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_device_state IS 'Asset Tracking: DALI telemetry cache; join to systems for fixture definition; AT does not update systems rows.';

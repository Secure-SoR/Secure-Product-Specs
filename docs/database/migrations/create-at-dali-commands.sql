-- Asset Tracking v2.0 — at_dali_commands
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.11

CREATE TABLE IF NOT EXISTS public.at_dali_commands (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  system_id uuid NOT NULL REFERENCES public.systems(id) ON DELETE CASCADE,
  command_type text NOT NULL CHECK (command_type IN ('set_on_off', 'set_dim_level', 'set_scene', 'set_dh_enabled')),
  payload jsonb NOT NULL,
  status text NOT NULL CHECK (status IN ('queued', 'sent', 'acknowledged', 'failed')),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz,
  acknowledged_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_at_dali_commands_account_id ON public.at_dali_commands(account_id);
CREATE INDEX IF NOT EXISTS idx_at_dali_commands_system_status ON public.at_dali_commands(system_id, status);

ALTER TABLE public.at_dali_commands ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_dali_commands in their accounts" ON public.at_dali_commands;
DROP POLICY IF EXISTS "Members can insert at_dali_commands in their accounts" ON public.at_dali_commands;
DROP POLICY IF EXISTS "Members can update at_dali_commands in their accounts" ON public.at_dali_commands;
DROP POLICY IF EXISTS "Members can delete at_dali_commands in their accounts" ON public.at_dali_commands;

CREATE POLICY "Members can read at_dali_commands in their accounts"
  ON public.at_dali_commands FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_dali_commands in their accounts"
  ON public.at_dali_commands FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_dali_commands in their accounts"
  ON public.at_dali_commands FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_dali_commands in their accounts"
  ON public.at_dali_commands FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_dali_commands IS 'Asset Tracking: queued DALI control commands; processed by ingest / edge worker.';

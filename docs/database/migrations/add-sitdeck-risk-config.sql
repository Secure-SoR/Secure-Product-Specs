-- SitDeck risk dashboard widget configuration per property (Data Centre Risk Intelligence).
-- Run after supabase-schema.sql or add-dc-metadata.sql (depends on accounts, properties, account_memberships).

CREATE TABLE IF NOT EXISTS public.sitdeck_risk_config (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  active_widget_types text[],
  last_synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(property_id)
);

CREATE INDEX IF NOT EXISTS idx_sitdeck_risk_config_account_id ON public.sitdeck_risk_config(account_id);
CREATE INDEX IF NOT EXISTS idx_sitdeck_risk_config_property_id ON public.sitdeck_risk_config(property_id);

COMMENT ON TABLE public.sitdeck_risk_config IS 'Which SitDeck risk widgets are enabled per property; one row per property';

-- RLS: account-scoped (same pattern as dc_metadata)
ALTER TABLE public.sitdeck_risk_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;
DROP POLICY IF EXISTS "Members can insert sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;
DROP POLICY IF EXISTS "Members can update sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;
DROP POLICY IF EXISTS "Members can delete sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;

CREATE POLICY "Members can read sitdeck_risk_config in their accounts"
  ON public.sitdeck_risk_config FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert sitdeck_risk_config in their accounts"
  ON public.sitdeck_risk_config FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update sitdeck_risk_config in their accounts"
  ON public.sitdeck_risk_config FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete sitdeck_risk_config in their accounts"
  ON public.sitdeck_risk_config FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

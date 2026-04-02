-- Asset Tracking v2.0 — at_gateways (Wirepas border routers; not in systems)
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.7

CREATE TABLE IF NOT EXISTS public.at_gateways (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  floor_id uuid REFERENCES public.at_floors(id) ON DELETE SET NULL,
  name text NOT NULL,
  wirepas_gateway_id text NOT NULL,
  mac_address text,
  firmware_version text,
  ip_address text,
  online boolean NOT NULL DEFAULT false,
  connected_node_count integer,
  last_heartbeat_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id, wirepas_gateway_id)
);

CREATE INDEX IF NOT EXISTS idx_at_gateways_account_id ON public.at_gateways(account_id);
CREATE INDEX IF NOT EXISTS idx_at_gateways_property_id ON public.at_gateways(property_id);
CREATE INDEX IF NOT EXISTS idx_at_gateways_floor_id ON public.at_gateways(floor_id);

ALTER TABLE public.at_gateways ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_gateways in their accounts" ON public.at_gateways;
DROP POLICY IF EXISTS "Members can insert at_gateways in their accounts" ON public.at_gateways;
DROP POLICY IF EXISTS "Members can update at_gateways in their accounts" ON public.at_gateways;
DROP POLICY IF EXISTS "Members can delete at_gateways in their accounts" ON public.at_gateways;

CREATE POLICY "Members can read at_gateways in their accounts"
  ON public.at_gateways FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_gateways in their accounts"
  ON public.at_gateways FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_gateways in their accounts"
  ON public.at_gateways FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete at_gateways in their accounts"
  ON public.at_gateways FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

COMMENT ON TABLE public.at_gateways IS 'Asset Tracking: Wirepas mesh gateways; not stored in systems.';

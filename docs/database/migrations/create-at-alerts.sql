-- Asset Tracking v2.0 — at_alerts + audit_events trigger
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.9

CREATE TABLE IF NOT EXISTS public.at_alerts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  asset_id uuid NOT NULL REFERENCES public.at_assets(id) ON DELETE CASCADE,
  alert_type text NOT NULL CHECK (alert_type IN ('restricted_entry', 'out_of_zone', 'prolonged_idle', 'panic', 'custom')),
  zone_id uuid REFERENCES public.at_zones(id) ON DELETE SET NULL,
  floor_id uuid REFERENCES public.at_floors(id) ON DELETE SET NULL,
  message text NOT NULL,
  idle_minutes integer,
  status text NOT NULL CHECK (status IN ('unread', 'acknowledged', 'dismissed')),
  acknowledged_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  acknowledged_at timestamptz,
  triggered_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_at_alerts_property_status ON public.at_alerts(property_id, status);
CREATE INDEX IF NOT EXISTS idx_at_alerts_asset_triggered_desc ON public.at_alerts(asset_id, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_at_alerts_account_type_status ON public.at_alerts(account_id, alert_type, status);
CREATE INDEX IF NOT EXISTS idx_at_alerts_account_id ON public.at_alerts(account_id);

ALTER TABLE public.at_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read at_alerts in their accounts" ON public.at_alerts;
DROP POLICY IF EXISTS "Members can insert at_alerts in their accounts" ON public.at_alerts;
DROP POLICY IF EXISTS "Members can update at_alerts in their accounts" ON public.at_alerts;

CREATE POLICY "Members can read at_alerts in their accounts"
  ON public.at_alerts FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert at_alerts in their accounts"
  ON public.at_alerts FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update at_alerts in their accounts"
  ON public.at_alerts FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- Audit: every insert and status-related update → audit_events (SECURITY DEFINER; table owner bypasses RLS)

CREATE OR REPLACE FUNCTION public.at_alerts_audit_to_audit_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.audit_events (account_id, entity_type, entity_id, action, actor_id, before_state, after_state)
    VALUES (NEW.account_id, 'at_alerts', NEW.id, 'create', auth.uid(), NULL, to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status IS DISTINCT FROM NEW.status
       OR OLD.acknowledged_by IS DISTINCT FROM NEW.acknowledged_by
       OR OLD.acknowledged_at IS DISTINCT FROM NEW.acknowledged_at
    THEN
      INSERT INTO public.audit_events (account_id, entity_type, entity_id, action, actor_id, before_state, after_state)
      VALUES (
        NEW.account_id,
        'at_alerts',
        NEW.id,
        'update',
        auth.uid(),
        jsonb_build_object(
          'status', OLD.status,
          'acknowledged_by', OLD.acknowledged_by,
          'acknowledged_at', OLD.acknowledged_at
        ),
        jsonb_build_object(
          'status', NEW.status,
          'acknowledged_by', NEW.acknowledged_by,
          'acknowledged_at', NEW.acknowledged_at
        )
      );
    END IF;
    RETURN NEW;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS at_alerts_audit_trigger ON public.at_alerts;
CREATE TRIGGER at_alerts_audit_trigger
  AFTER INSERT OR UPDATE ON public.at_alerts
  FOR EACH ROW
  EXECUTE FUNCTION public.at_alerts_audit_to_audit_events();

COMMENT ON TABLE public.at_alerts IS 'Asset Tracking: alert records; status transitions only; never deleted per spec.';

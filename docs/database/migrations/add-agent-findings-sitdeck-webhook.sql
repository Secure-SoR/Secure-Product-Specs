-- agent_findings: support SitDeck webhook rows (no agent_run) + denormalized account_id for RLS.
-- Run in Supabase SQL Editor after prior agent_findings / agent_runs migrations.
-- Guide: docs/specs/implementation-guide-phase-3-dc.md Step 3.6

-- 1) Denormalized account scope (required for RLS when agent_run_id is null)
ALTER TABLE public.agent_findings
  ADD COLUMN IF NOT EXISTS account_id uuid REFERENCES public.accounts(id) ON DELETE CASCADE;

UPDATE public.agent_findings AS f
SET account_id = r.account_id
FROM public.agent_runs AS r
WHERE f.agent_run_id = r.id AND f.account_id IS NULL;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.agent_findings WHERE account_id IS NULL) THEN
    RAISE EXCEPTION 'agent_findings: cannot set NOT NULL on account_id — rows missing account_id after backfill';
  END IF;
END $$;

ALTER TABLE public.agent_findings ALTER COLUMN account_id SET NOT NULL;

-- 2) External source + optional property scope
ALTER TABLE public.agent_findings
  ADD COLUMN IF NOT EXISTS source text,
  ADD COLUMN IF NOT EXISTS property_id uuid REFERENCES public.properties(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.agent_findings.account_id IS 'Tenant scope; copied from agent_runs or set for webhook-sourced findings';
COMMENT ON COLUMN public.agent_findings.source IS 'sitdeck for SitDeck webhook alerts; NULL when tied to an agent run';
COMMENT ON COLUMN public.agent_findings.property_id IS 'Optional property scope (e.g. SitDeck alert for a specific property)';

-- 3) SitDeck rows do not reference agent_runs
ALTER TABLE public.agent_findings ALTER COLUMN agent_run_id DROP NOT NULL;

ALTER TABLE public.agent_findings DROP CONSTRAINT IF EXISTS agent_findings_source_run_check;
ALTER TABLE public.agent_findings ADD CONSTRAINT agent_findings_source_run_check CHECK (
  (agent_run_id IS NOT NULL AND (source IS NULL OR source <> 'sitdeck'))
  OR
  (agent_run_id IS NULL AND source = 'sitdeck' AND account_id IS NOT NULL)
);

-- 4) Keep account_id in sync when inserting/updating via agent_run_id (client code may omit account_id)
CREATE OR REPLACE FUNCTION public.agent_findings_set_account_id()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.agent_run_id IS NOT NULL THEN
    SELECT r.account_id INTO NEW.account_id
    FROM public.agent_runs AS r
    WHERE r.id = NEW.agent_run_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS agent_findings_set_account_id_trigger ON public.agent_findings;
CREATE TRIGGER agent_findings_set_account_id_trigger
  BEFORE INSERT OR UPDATE OF agent_run_id ON public.agent_findings
  FOR EACH ROW
  EXECUTE FUNCTION public.agent_findings_set_account_id();

CREATE INDEX IF NOT EXISTS idx_agent_findings_account_id ON public.agent_findings(account_id);
CREATE INDEX IF NOT EXISTS idx_agent_findings_property_id ON public.agent_findings(property_id)
  WHERE property_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agent_findings_account_sitdeck ON public.agent_findings(account_id, created_at DESC)
  WHERE source = 'sitdeck';

-- 5) RLS: scope by account_id; members insert only via agent runs (webhook uses service role)
DROP POLICY IF EXISTS "Members can read agent_findings for runs in their accounts" ON public.agent_findings;
DROP POLICY IF EXISTS "Members can read agent_findings in their accounts" ON public.agent_findings;
DROP POLICY IF EXISTS "Members can insert agent_findings for runs in their accounts" ON public.agent_findings;

CREATE POLICY "Members can read agent_findings in their accounts"
  ON public.agent_findings FOR SELECT
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Members can insert agent_findings for runs in their accounts"
  ON public.agent_findings FOR INSERT
  WITH CHECK (
    agent_run_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.agent_runs AS r
      WHERE r.id = agent_run_id
        AND r.account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
    AND account_id = (SELECT r2.account_id FROM public.agent_runs AS r2 WHERE r2.id = agent_run_id)
  );

-- End. Webhook inserts use Supabase service role (bypass RLS). See implementation-guide-phase-3-dc.md Step 3.6.

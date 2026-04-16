-- Risk Diagnosis + physical risk flags per property (Data Centre).
-- Spec: docs/specs/secure-dc-spec-v2.md §6, §10; guide: docs/specs/implementation-guide-phase-4-dc.md Step 4.1
-- Depends on: accounts, properties, account_memberships (RLS).

-- 1) One current risk assessment record per property (upsert on property_id).
CREATE TABLE IF NOT EXISTS public.risk_diagnosis (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  summary text,
  overall_risk_level text CHECK (
    overall_risk_level IS NULL
    OR overall_risk_level IN ('unknown', 'low', 'moderate', 'high', 'critical')
  ),
  diagnosis_json jsonb,
  assessed_at timestamptz,
  sitdeck_last_synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id)
);

CREATE INDEX IF NOT EXISTS idx_risk_diagnosis_account_id ON public.risk_diagnosis(account_id);
CREATE INDEX IF NOT EXISTS idx_risk_diagnosis_property_id ON public.risk_diagnosis(property_id);

COMMENT ON TABLE public.risk_diagnosis IS 'Per-property risk assessment snapshot for DC / Risk Diagnosis UI; feeds from SitDeck and other sources';
COMMENT ON COLUMN public.risk_diagnosis.sitdeck_last_synced_at IS 'When physical risk flags (or SitDeck-driven data) were last merged into this diagnosis';

-- 2) Individual physical risk flags (e.g. flood, wildfire) with provenance.
CREATE TABLE IF NOT EXISTS public.physical_risk_flags (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  risk_diagnosis_id uuid NOT NULL REFERENCES public.risk_diagnosis(id) ON DELETE CASCADE,
  flag_type text NOT NULL,
  source text NOT NULL CHECK (source IN ('sitdeck', 'manual', 'agent')),
  severity text CHECK (
    severity IS NULL
    OR severity IN ('unknown', 'low', 'moderate', 'high', 'critical')
  ),
  title text,
  detail text,
  payload jsonb,
  external_ref text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_physical_risk_flags_diagnosis_id ON public.physical_risk_flags(risk_diagnosis_id);
CREATE INDEX IF NOT EXISTS idx_physical_risk_flags_source ON public.physical_risk_flags(risk_diagnosis_id, source);

COMMENT ON TABLE public.physical_risk_flags IS 'Physical / location risk flags linked to a risk_diagnosis row; source distinguishes SitDeck vs manual vs agent';
COMMENT ON COLUMN public.physical_risk_flags.flag_type IS 'e.g. flood, wildfire, extreme_weather, earthquake — app/SitDeck taxonomy';
COMMENT ON COLUMN public.physical_risk_flags.payload IS 'Optional raw or normalised JSON from SitDeck or agent';

ALTER TABLE public.risk_diagnosis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.physical_risk_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read risk_diagnosis in their accounts" ON public.risk_diagnosis;
DROP POLICY IF EXISTS "Members can insert risk_diagnosis in their accounts" ON public.risk_diagnosis;
DROP POLICY IF EXISTS "Members can update risk_diagnosis in their accounts" ON public.risk_diagnosis;
DROP POLICY IF EXISTS "Members can delete risk_diagnosis in their accounts" ON public.risk_diagnosis;

CREATE POLICY "Members can read risk_diagnosis in their accounts"
  ON public.risk_diagnosis FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can insert risk_diagnosis in their accounts"
  ON public.risk_diagnosis FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can update risk_diagnosis in their accounts"
  ON public.risk_diagnosis FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can delete risk_diagnosis in their accounts"
  ON public.risk_diagnosis FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Members can read physical_risk_flags for their diagnoses" ON public.physical_risk_flags;
DROP POLICY IF EXISTS "Members can insert physical_risk_flags for their diagnoses" ON public.physical_risk_flags;
DROP POLICY IF EXISTS "Members can update physical_risk_flags for their diagnoses" ON public.physical_risk_flags;
DROP POLICY IF EXISTS "Members can delete physical_risk_flags for their diagnoses" ON public.physical_risk_flags;

CREATE POLICY "Members can read physical_risk_flags for their diagnoses"
  ON public.physical_risk_flags FOR SELECT
  USING (
    risk_diagnosis_id IN (
      SELECT id FROM public.risk_diagnosis
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can insert physical_risk_flags for their diagnoses"
  ON public.physical_risk_flags FOR INSERT
  WITH CHECK (
    risk_diagnosis_id IN (
      SELECT id FROM public.risk_diagnosis
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can update physical_risk_flags for their diagnoses"
  ON public.physical_risk_flags FOR UPDATE
  USING (
    risk_diagnosis_id IN (
      SELECT id FROM public.risk_diagnosis
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can delete physical_risk_flags for their diagnoses"
  ON public.physical_risk_flags FOR DELETE
  USING (
    risk_diagnosis_id IN (
      SELECT id FROM public.risk_diagnosis
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

-- End. Edge Functions / service role may also insert/update when syncing SitDeck (bypass RLS).

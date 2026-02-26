-- Property utility applicability and service charge inclusion
-- For CoverageEngine and agent: know if components (heating, water, etc.) are
-- separate bills, included in service charge only, or both. Service charge
-- "includes" flags indicate what the landlord recharge contains (energy, water, heating).
-- See docs/architecture/coverage-and-applicability-for-agent.md and
-- docs/sources/Secure_KPI_Coverage_Logic_Spec_v1.md.

-- Applicability per property per component
-- Agent and CoverageEngine read this to infer: no separate bill expected vs both expected.
CREATE TABLE IF NOT EXISTS public.property_utility_applicability (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  component text NOT NULL CHECK (component IN (
    'tenant_electricity',
    'landlord_recharge',
    'heating',
    'water',
    'waste'
  )),
  applicability text NOT NULL CHECK (applicability IN (
    'separate_bill',           -- only separate bills (e.g. tenant electricity)
    'included_in_service_charge', -- no separate bill; data comes from service charge only
    'both',                   -- both separate bill AND service charge (e.g. water: direct + in SC)
    'not_applicable'          -- component not relevant for this property
  )),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(property_id, component)
);

CREATE INDEX IF NOT EXISTS idx_property_utility_applicability_property_id
  ON public.property_utility_applicability(property_id);
CREATE INDEX IF NOT EXISTS idx_property_utility_applicability_account_id
  ON public.property_utility_applicability(account_id);

COMMENT ON TABLE public.property_utility_applicability IS
  'Per-property: how each utility component is supplied (separate bill, in service charge only, or both). Used by CoverageEngine and agent to infer Complete/Partial and whether to expect separate heating/water bills.';

-- What the service charge includes (one row per property)
-- When service charge exists, these flags say whether it contains energy, water, heating.
CREATE TABLE IF NOT EXISTS public.property_service_charge_includes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE UNIQUE,
  includes_energy boolean NOT NULL DEFAULT false,
  includes_water boolean NOT NULL DEFAULT false,
  includes_heating boolean NOT NULL DEFAULT false,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_service_charge_includes_property_id
  ON public.property_service_charge_includes(property_id);
CREATE INDEX IF NOT EXISTS idx_property_service_charge_includes_account_id
  ON public.property_service_charge_includes(account_id);

COMMENT ON TABLE public.property_service_charge_includes IS
  'Per-property: whether the service charge (landlord recharge) is known to include energy, water, heating. Used with property_utility_applicability and data_library_records to determine KPI coverage (e.g. water complete when SC includes water and heating/water marked included_in_service_charge).';

-- RLS: account-scoped
ALTER TABLE public.property_utility_applicability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_service_charge_includes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read property_utility_applicability in their accounts"
  ON public.property_utility_applicability;
DROP POLICY IF EXISTS "Members can insert property_utility_applicability in their accounts"
  ON public.property_utility_applicability;
DROP POLICY IF EXISTS "Members can update property_utility_applicability in their accounts"
  ON public.property_utility_applicability;
DROP POLICY IF EXISTS "Members can delete property_utility_applicability in their accounts"
  ON public.property_utility_applicability;

CREATE POLICY "Members can read property_utility_applicability in their accounts"
  ON public.property_utility_applicability FOR SELECT
  USING (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );
CREATE POLICY "Members can insert property_utility_applicability in their accounts"
  ON public.property_utility_applicability FOR INSERT
  WITH CHECK (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );
CREATE POLICY "Members can update property_utility_applicability in their accounts"
  ON public.property_utility_applicability FOR UPDATE
  USING (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );
CREATE POLICY "Members can delete property_utility_applicability in their accounts"
  ON public.property_utility_applicability FOR DELETE
  USING (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Members can read property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes;
DROP POLICY IF EXISTS "Members can insert property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes;
DROP POLICY IF EXISTS "Members can update property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes;
DROP POLICY IF EXISTS "Members can delete property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes;

CREATE POLICY "Members can read property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes FOR SELECT
  USING (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );
CREATE POLICY "Members can insert property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes FOR INSERT
  WITH CHECK (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );
CREATE POLICY "Members can update property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes FOR UPDATE
  USING (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );
CREATE POLICY "Members can delete property_service_charge_includes in their accounts"
  ON public.property_service_charge_includes FOR DELETE
  USING (
    account_id IN (
      SELECT am.account_id FROM public.account_memberships am
      WHERE am.user_id = auth.uid()
    )
  );

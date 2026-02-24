-- Secure SoR — Supabase schema (Phase 1)
-- Run this in Supabase SQL Editor to create all tables.
-- Schema source: docs/database/schema.md

-- Enable UUID extension if not already
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------
-- 1. profiles (extends auth.users)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- 2. accounts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.accounts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  account_type text NOT NULL CHECK (account_type IN ('corporate_occupier', 'asset_manager')),
  enabled_modules text[],
  reporting_boundary jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read their accounts"
  ON public.accounts FOR SELECT
  USING (
    id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins can update their accounts"
  ON public.accounts FOR UPDATE
  USING (
    id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ---------------------------------------------------------------------------
-- 3. account_memberships (must exist for account RLS)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.account_memberships (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'member', 'viewer')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(account_id, user_id)
);

CREATE INDEX idx_account_memberships_user_id ON public.account_memberships(user_id);
CREATE INDEX idx_account_memberships_account_id ON public.account_memberships(account_id);

ALTER TABLE public.account_memberships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own memberships"
  ON public.account_memberships FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can add themselves as member"
  ON public.account_memberships FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update/delete memberships in their account"
  ON public.account_memberships FOR UPDATE
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can delete memberships in their account"
  ON public.account_memberships FOR DELETE
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ---------------------------------------------------------------------------
-- 4. properties
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.properties (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text,
  country text,
  floors jsonb,
  total_area numeric,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_properties_account_id ON public.properties(account_id);

ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read properties in their accounts"
  ON public.properties FOR SELECT
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Members can insert properties in their accounts"
  ON public.properties FOR INSERT
  WITH CHECK (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Members can update/delete properties in their accounts"
  ON public.properties FOR UPDATE
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 5. spaces
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.spaces (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  space_class text NOT NULL CHECK (space_class IN ('tenant', 'base_building')),
  control text NOT NULL CHECK (control IN ('landlord_controlled', 'tenant_controlled', 'shared')),
  space_type text,
  area numeric,
  floor_reference text,
  in_scope boolean NOT NULL DEFAULT true,
  net_zero_included boolean,
  gresb_reporting boolean,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_spaces_property_id ON public.spaces(property_id);

ALTER TABLE public.spaces ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can manage spaces in their account properties"
  ON public.spaces FOR ALL
  USING (
    property_id IN (
      SELECT p.id FROM public.properties p
      JOIN public.account_memberships m ON m.account_id = p.account_id
      WHERE m.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 6. systems
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.systems (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  system_category text NOT NULL,
  system_type text,
  space_class text CHECK (space_class IN ('tenant', 'base_building')),
  controlled_by text NOT NULL CHECK (controlled_by IN ('tenant', 'landlord', 'shared')),
  maintained_by text,
  metering_status text NOT NULL CHECK (metering_status IN ('none', 'partial', 'full')),
  allocation_method text NOT NULL CHECK (allocation_method IN ('measured', 'area', 'estimated')),
  allocation_notes text,
  serves_space_ids uuid[],
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_systems_account_id ON public.systems(account_id);
CREATE INDEX idx_systems_property_id ON public.systems(property_id);

ALTER TABLE public.systems ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read systems in their accounts"
  ON public.systems FOR SELECT
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Members can insert/update/delete systems in their accounts"
  ON public.systems FOR ALL
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 7. meters
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.meters (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  system_id uuid REFERENCES public.systems(id) ON DELETE SET NULL,
  name text NOT NULL,
  meter_type text,
  unit text,
  external_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_meters_account_id ON public.meters(account_id);
CREATE INDEX idx_meters_property_id ON public.meters(property_id);
CREATE INDEX idx_meters_system_id ON public.meters(system_id);

ALTER TABLE public.meters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can manage meters in their accounts"
  ON public.meters FOR ALL
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 8. end_use_nodes
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.end_use_nodes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  system_id uuid NOT NULL REFERENCES public.systems(id) ON DELETE CASCADE,
  node_id text NOT NULL,
  node_category text NOT NULL,
  utility_type text NOT NULL,
  control_override text CHECK (control_override IN ('TENANT', 'LANDLORD', 'SHARED')),
  allocation_weight numeric CHECK (allocation_weight IS NULL OR (allocation_weight >= 0 AND allocation_weight <= 1)),
  applies_to_space_ids uuid[],
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(property_id, node_id)
);

CREATE INDEX idx_end_use_nodes_account_id ON public.end_use_nodes(account_id);
CREATE INDEX idx_end_use_nodes_system_id ON public.end_use_nodes(system_id);

ALTER TABLE public.end_use_nodes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can manage end_use_nodes in their accounts"
  ON public.end_use_nodes FOR ALL
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 9. data_library_records
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.data_library_records (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid REFERENCES public.properties(id) ON DELETE SET NULL,
  subject_category text NOT NULL,
  data_type text,
  value_numeric numeric,
  value_text text,
  unit text,
  reporting_period_start date,
  reporting_period_end date,
  source_type text NOT NULL CHECK (source_type IN ('connector', 'upload', 'manual')),
  confidence text CHECK (confidence IN ('measured', 'allocated', 'estimated')),
  allocation_method text,
  allocation_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_data_library_records_account_id ON public.data_library_records(account_id);
CREATE INDEX idx_data_library_records_property_id ON public.data_library_records(property_id);

ALTER TABLE public.data_library_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can manage data_library_records in their accounts"
  ON public.data_library_records FOR ALL
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 10. documents
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.documents (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  storage_path text NOT NULL,
  file_name text NOT NULL,
  mime_type text,
  file_size_bytes bigint,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_documents_account_id ON public.documents(account_id);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can manage documents in their accounts"
  ON public.documents FOR ALL
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 11. evidence_attachments
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.evidence_attachments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  data_library_record_id uuid NOT NULL REFERENCES public.data_library_records(id) ON DELETE CASCADE,
  document_id uuid NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(data_library_record_id, document_id)
);

CREATE INDEX idx_evidence_attachments_record_id ON public.evidence_attachments(data_library_record_id);
CREATE INDEX idx_evidence_attachments_document_id ON public.evidence_attachments(document_id);

ALTER TABLE public.evidence_attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can manage evidence_attachments for records in their accounts"
  ON public.evidence_attachments FOR ALL
  USING (
    data_library_record_id IN (
      SELECT id FROM public.data_library_records
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- 12. agent_runs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agent_runs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid REFERENCES public.properties(id) ON DELETE SET NULL,
  agent_type text NOT NULL CHECK (agent_type IN ('data_readiness', 'boundary')),
  status text NOT NULL CHECK (status IN ('pending', 'completed', 'failed')),
  context_snapshot jsonb,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_agent_runs_account_id ON public.agent_runs(account_id);

ALTER TABLE public.agent_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read agent_runs in their accounts"
  ON public.agent_runs FOR SELECT
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Members can insert agent_runs in their accounts"
  ON public.agent_runs FOR INSERT
  WITH CHECK (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Members can update agent_runs in their accounts"
  ON public.agent_runs FOR UPDATE
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 13. agent_findings
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.agent_findings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_run_id uuid NOT NULL REFERENCES public.agent_runs(id) ON DELETE CASCADE,
  finding_type text,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_agent_findings_agent_run_id ON public.agent_findings(agent_run_id);

ALTER TABLE public.agent_findings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read agent_findings for runs in their accounts"
  ON public.agent_findings FOR SELECT
  USING (
    agent_run_id IN (
      SELECT id FROM public.agent_runs
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can insert agent_findings for runs in their accounts"
  ON public.agent_findings FOR INSERT
  WITH CHECK (
    agent_run_id IN (
      SELECT id FROM public.agent_runs
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- 14. audit_events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  action text NOT NULL CHECK (action IN ('create', 'update', 'delete')),
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  before_state jsonb,
  after_state jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_events_account_id ON public.audit_events(account_id);
CREATE INDEX idx_audit_events_entity ON public.audit_events(entity_type, entity_id);
CREATE INDEX idx_audit_events_created_at ON public.audit_events(created_at);

ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read audit_events in their accounts"
  ON public.audit_events FOR SELECT
  USING (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

CREATE POLICY "Members can insert audit_events (no update/delete)"
  ON public.audit_events FOR INSERT
  WITH CHECK (
    account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- Trigger: create profile on signup (Supabase pattern)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, updated_at)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email), now())
  ON CONFLICT (id) DO UPDATE SET updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Optional: updated_at triggers (uncomment if you want auto updated_at)
-- ---------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION public.set_updated_at()
-- RETURNS trigger AS $$
-- BEGIN
--   NEW.updated_at = now();
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
-- (Apply to each table with updated_at as needed)

-- Secure SoR — Supabase schema (Phase 1)
-- Run this in Supabase SQL Editor to create all tables.
-- Schema source: docs/database/schema.md
-- Order: tables + indexes first, then RLS + policies (so account_memberships exists when accounts policies run).

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PART 1: CREATE ALL TABLES AND INDEXES (no RLS policies yet)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.accounts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  account_type text NOT NULL CHECK (account_type IN ('corporate_occupier', 'asset_manager')),
  enabled_modules text[],
  reporting_boundary jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.account_memberships (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'member', 'viewer')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(account_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_account_memberships_user_id ON public.account_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_account_memberships_account_id ON public.account_memberships(account_id);

CREATE TABLE IF NOT EXISTS public.properties (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  name text NOT NULL,
  address text,
  city text,
  region text,
  postcode text,
  country text,
  nla text,
  asset_type text DEFAULT 'Office',
  year_built integer,
  last_renovation integer,
  operational_status text,
  occupancy_scope text,
  floors jsonb,
  floors_in_scope jsonb,
  total_area numeric,
  latitude numeric,
  longitude numeric,
  at_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_properties_account_id ON public.properties(account_id);

CREATE TABLE IF NOT EXISTS public.dc_metadata (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  tier_level text,
  design_capacity_mw numeric,
  current_it_load_mw numeric,
  total_white_floor_sqm numeric,
  cooling_type text[],
  power_supply_redundancy text,
  target_pue numeric,
  renewable_energy_pct numeric,
  water_usage_effectiveness_target numeric,
  certifications text[],
  sitdeck_site_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(property_id)
);
CREATE INDEX IF NOT EXISTS idx_dc_metadata_account_id ON public.dc_metadata(account_id);
CREATE INDEX IF NOT EXISTS idx_dc_metadata_property_id ON public.dc_metadata(property_id);

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

COMMENT ON TABLE public.risk_diagnosis IS 'Per-property risk assessment snapshot; DC Risk Diagnosis UI';
COMMENT ON TABLE public.physical_risk_flags IS 'Physical risk flags; source = sitdeck | manual | agent';

CREATE TABLE IF NOT EXISTS public.spaces (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  parent_space_id uuid REFERENCES public.spaces(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_spaces_property_id ON public.spaces(property_id);
CREATE INDEX IF NOT EXISTS idx_spaces_parent_space_id ON public.spaces(parent_space_id);

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
  allocation_method text NOT NULL CHECK (allocation_method IN ('measured', 'area', 'estimated', 'mixed')),
  allocation_notes text,
  key_specs text,
  spec_status text,
  serves_space_ids uuid[],
  serves_spaces_description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_systems_account_id ON public.systems(account_id);
CREATE INDEX IF NOT EXISTS idx_systems_property_id ON public.systems(property_id);

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
CREATE INDEX IF NOT EXISTS idx_meters_account_id ON public.meters(account_id);
CREATE INDEX IF NOT EXISTS idx_meters_property_id ON public.meters(property_id);
CREATE INDEX IF NOT EXISTS idx_meters_system_id ON public.meters(system_id);

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
  auto_generated boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(property_id, node_id)
);
CREATE INDEX IF NOT EXISTS idx_end_use_nodes_account_id ON public.end_use_nodes(account_id);
CREATE INDEX IF NOT EXISTS idx_end_use_nodes_system_id ON public.end_use_nodes(system_id);

CREATE TABLE IF NOT EXISTS public.data_library_records (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid REFERENCES public.properties(id) ON DELETE SET NULL,
  subject_category text NOT NULL,
  name text,
  data_type text,
  value_numeric numeric,
  value_text text,
  unit text,
  reporting_period_start date,
  reporting_period_end date,
  source_type text NOT NULL CHECK (source_type IN ('connector', 'upload', 'manual', 'rule_chain')),
  confidence text CHECK (confidence IN ('measured', 'allocated', 'estimated', 'cost_only')),
  allocation_method text,
  allocation_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_data_library_records_account_id ON public.data_library_records(account_id);
CREATE INDEX IF NOT EXISTS idx_data_library_records_property_id ON public.data_library_records(property_id);

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
CREATE INDEX IF NOT EXISTS idx_documents_account_id ON public.documents(account_id);

CREATE TABLE IF NOT EXISTS public.evidence_attachments (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  data_library_record_id uuid NOT NULL REFERENCES public.data_library_records(id) ON DELETE CASCADE,
  document_id uuid NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(data_library_record_id, document_id)
);
CREATE INDEX IF NOT EXISTS idx_evidence_attachments_record_id ON public.evidence_attachments(data_library_record_id);
CREATE INDEX IF NOT EXISTS idx_evidence_attachments_document_id ON public.evidence_attachments(document_id);

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
CREATE INDEX IF NOT EXISTS idx_agent_runs_account_id ON public.agent_runs(account_id);

CREATE TABLE IF NOT EXISTS public.agent_findings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_run_id uuid REFERENCES public.agent_runs(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid REFERENCES public.properties(id) ON DELETE SET NULL,
  source text,
  finding_type text,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT agent_findings_source_run_check CHECK (
    (agent_run_id IS NOT NULL AND (source IS NULL OR source <> 'sitdeck'))
    OR
    (agent_run_id IS NULL AND source = 'sitdeck' AND account_id IS NOT NULL)
  )
);
CREATE INDEX IF NOT EXISTS idx_agent_findings_agent_run_id ON public.agent_findings(agent_run_id);
CREATE INDEX IF NOT EXISTS idx_agent_findings_account_id ON public.agent_findings(account_id);
CREATE INDEX IF NOT EXISTS idx_agent_findings_property_id ON public.agent_findings(property_id)
  WHERE property_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agent_findings_account_sitdeck ON public.agent_findings(account_id, created_at DESC)
  WHERE source = 'sitdeck';

COMMENT ON COLUMN public.agent_findings.account_id IS 'Tenant scope; set from agent_runs or for webhook-sourced findings';
COMMENT ON COLUMN public.agent_findings.source IS 'sitdeck for SitDeck webhook alerts; NULL when tied to an agent run';
COMMENT ON COLUMN public.agent_findings.property_id IS 'Optional property scope (e.g. SitDeck alert for a specific property)';

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
CREATE INDEX IF NOT EXISTS idx_audit_events_account_id ON public.audit_events(account_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_entity ON public.audit_events(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_created_at ON public.audit_events(created_at);

-- Asset Tracking (v2.0) — spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6
CREATE TABLE IF NOT EXISTS public.at_floors (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  level_index integer,
  floor_plan_image_url text,
  floor_plan_width_px integer,
  floor_plan_height_px integer,
  coord_system text NOT NULL CHECK (coord_system IN ('pixel', 'local_metres', 'gps')),
  gps_calibration jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_at_floors_account_id ON public.at_floors(account_id);
CREATE INDEX IF NOT EXISTS idx_at_floors_property_id ON public.at_floors(property_id);

CREATE TABLE IF NOT EXISTS public.at_zones (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  floor_id uuid NOT NULL REFERENCES public.at_floors(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  zone_type text NOT NULL CHECK (zone_type IN ('public', 'restricted', 'staff_entry')),
  polygon jsonb NOT NULL,
  space_id uuid REFERENCES public.spaces(id) ON DELETE SET NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_at_zones_floor_id ON public.at_zones(floor_id);
CREATE INDEX IF NOT EXISTS idx_at_zones_property_zone_type ON public.at_zones(property_id, zone_type);
CREATE INDEX IF NOT EXISTS idx_at_zones_account_id ON public.at_zones(account_id);

CREATE TABLE IF NOT EXISTS public.at_asset_types (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  category text NOT NULL CHECK (category IN ('workers', 'drilling_equipments', 'loading_equipments', 'medical_kit')),
  icon_key text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_at_asset_types_account_id ON public.at_asset_types(account_id);
CREATE INDEX IF NOT EXISTS idx_at_asset_types_property_id ON public.at_asset_types(property_id);
CREATE UNIQUE INDEX IF NOT EXISTS at_asset_types_account_name_account_level
  ON public.at_asset_types (account_id, name) WHERE property_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS at_asset_types_account_property_name
  ON public.at_asset_types (account_id, property_id, name) WHERE property_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.at_assets (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  asset_type_id uuid REFERENCES public.at_asset_types(id) ON DELETE SET NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  default_zone_id uuid REFERENCES public.at_zones(id) ON DELETE SET NULL,
  tag_id uuid,
  status text NOT NULL CHECK (status IN ('active', 'inactive', 'in_maintenance')),
  serial_number text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_at_assets_account_id ON public.at_assets(account_id);
CREATE INDEX IF NOT EXISTS idx_at_assets_property_id ON public.at_assets(property_id);
CREATE INDEX IF NOT EXISTS idx_at_assets_asset_type_id ON public.at_assets(asset_type_id);
CREATE INDEX IF NOT EXISTS idx_at_assets_tag_id ON public.at_assets(tag_id);

CREATE TABLE IF NOT EXISTS public.at_asset_tags (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  wirepas_node_id text NOT NULL,
  mac_address text,
  tag_model text,
  has_panic_button boolean NOT NULL DEFAULT false,
  panic_button_action text CHECK (panic_button_action IS NULL OR panic_button_action IN ('panic', 'movement_detection', 'custom_scene')),
  battery_level_pct numeric,
  firmware_version text,
  status text NOT NULL CHECK (status IN ('active', 'inactive', 'unassigned')),
  assigned_asset_id uuid REFERENCES public.at_assets(id) ON DELETE SET NULL,
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (property_id, wirepas_node_id)
);
CREATE INDEX IF NOT EXISTS idx_at_asset_tags_account_id ON public.at_asset_tags(account_id);
CREATE INDEX IF NOT EXISTS idx_at_asset_tags_property_id ON public.at_asset_tags(property_id);
CREATE INDEX IF NOT EXISTS idx_at_asset_tags_assigned_asset_id ON public.at_asset_tags(assigned_asset_id);
CREATE UNIQUE INDEX IF NOT EXISTS at_asset_tags_one_row_per_assigned_asset
  ON public.at_asset_tags (assigned_asset_id) WHERE assigned_asset_id IS NOT NULL;

ALTER TABLE public.at_assets DROP CONSTRAINT IF EXISTS at_assets_tag_id_fkey;
ALTER TABLE public.at_assets
  ADD CONSTRAINT at_assets_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.at_asset_tags(id) ON DELETE SET NULL;

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

CREATE TABLE IF NOT EXISTS public.at_position_events (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  asset_id uuid NOT NULL REFERENCES public.at_assets(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES public.at_asset_tags(id) ON DELETE SET NULL,
  floor_id uuid REFERENCES public.at_floors(id) ON DELETE SET NULL,
  zone_id uuid REFERENCES public.at_zones(id) ON DELETE SET NULL,
  x_pos numeric,
  y_pos numeric,
  accuracy_m numeric,
  source text NOT NULL CHECK (source IN ('wirepas', 'manual', 'simulated')),
  recorded_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_at_position_events_asset_recorded_desc ON public.at_position_events (asset_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_at_position_events_property_floor_recorded_desc ON public.at_position_events (property_id, floor_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_at_position_events_asset_recorded_asc ON public.at_position_events (asset_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_at_position_events_property_zone_recorded ON public.at_position_events (property_id, zone_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_at_position_events_account_id ON public.at_position_events(account_id);

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

-- ============================================================================
-- PART 2: ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dc_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sitdeck_risk_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.risk_diagnosis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.physical_risk_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.end_use_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_library_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_floors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_asset_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_asset_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_gateways ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_position_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_device_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_dali_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.at_facility_settings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 3: CREATE POLICIES (account_memberships now exists)
-- ============================================================================
-- Drop existing policies so this script can be re-run (PostgreSQL has no CREATE POLICY IF NOT EXISTS).
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Members can read their accounts" ON public.accounts;
DROP POLICY IF EXISTS "Admins can update their accounts" ON public.accounts;
DROP POLICY IF EXISTS "Users can read own memberships" ON public.account_memberships;
DROP POLICY IF EXISTS "Admins can update memberships in their account" ON public.account_memberships;
DROP POLICY IF EXISTS "Admins can delete memberships in their account" ON public.account_memberships;
DROP POLICY IF EXISTS "Members can read properties in their accounts" ON public.properties;
DROP POLICY IF EXISTS "Members can insert properties in their accounts" ON public.properties;
DROP POLICY IF EXISTS "Members can update properties in their accounts" ON public.properties;
DROP POLICY IF EXISTS "Members can delete properties in their accounts" ON public.properties;
DROP POLICY IF EXISTS "Members can read dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can insert dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can update dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can delete dc_metadata in their accounts" ON public.dc_metadata;
DROP POLICY IF EXISTS "Members can read sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;
DROP POLICY IF EXISTS "Members can insert sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;
DROP POLICY IF EXISTS "Members can update sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;
DROP POLICY IF EXISTS "Members can delete sitdeck_risk_config in their accounts" ON public.sitdeck_risk_config;
DROP POLICY IF EXISTS "Members can read risk_diagnosis in their accounts" ON public.risk_diagnosis;
DROP POLICY IF EXISTS "Members can insert risk_diagnosis in their accounts" ON public.risk_diagnosis;
DROP POLICY IF EXISTS "Members can update risk_diagnosis in their accounts" ON public.risk_diagnosis;
DROP POLICY IF EXISTS "Members can delete risk_diagnosis in their accounts" ON public.risk_diagnosis;
DROP POLICY IF EXISTS "Members can read physical_risk_flags for their diagnoses" ON public.physical_risk_flags;
DROP POLICY IF EXISTS "Members can insert physical_risk_flags for their diagnoses" ON public.physical_risk_flags;
DROP POLICY IF EXISTS "Members can update physical_risk_flags for their diagnoses" ON public.physical_risk_flags;
DROP POLICY IF EXISTS "Members can delete physical_risk_flags for their diagnoses" ON public.physical_risk_flags;
DROP POLICY IF EXISTS "Members can manage spaces in their account properties" ON public.spaces;
DROP POLICY IF EXISTS "Members can read systems in their accounts" ON public.systems;
DROP POLICY IF EXISTS "Members can insert systems in their accounts" ON public.systems;
DROP POLICY IF EXISTS "Members can update systems in their accounts" ON public.systems;
DROP POLICY IF EXISTS "Members can delete systems in their accounts" ON public.systems;
DROP POLICY IF EXISTS "Members can manage meters in their accounts" ON public.meters;
DROP POLICY IF EXISTS "Members can manage end_use_nodes in their accounts" ON public.end_use_nodes;
DROP POLICY IF EXISTS "Members can manage data_library_records in their accounts" ON public.data_library_records;
DROP POLICY IF EXISTS "Members can manage documents in their accounts" ON public.documents;
DROP POLICY IF EXISTS "Members can manage evidence_attachments for records in their accounts" ON public.evidence_attachments;
DROP POLICY IF EXISTS "Members can read agent_runs in their accounts" ON public.agent_runs;
DROP POLICY IF EXISTS "Members can insert agent_runs in their accounts" ON public.agent_runs;
DROP POLICY IF EXISTS "Members can update agent_runs in their accounts" ON public.agent_runs;
DROP POLICY IF EXISTS "Members can read agent_findings for runs in their accounts" ON public.agent_findings;
DROP POLICY IF EXISTS "Members can read agent_findings in their accounts" ON public.agent_findings;
DROP POLICY IF EXISTS "Members can insert agent_findings for runs in their accounts" ON public.agent_findings;
DROP POLICY IF EXISTS "Members can read audit_events in their accounts" ON public.audit_events;
DROP POLICY IF EXISTS "Members can insert audit_events" ON public.audit_events;
DROP POLICY IF EXISTS "Members can manage at_floors in their accounts" ON public.at_floors;
DROP POLICY IF EXISTS "Members can manage at_zones in their accounts" ON public.at_zones;
DROP POLICY IF EXISTS "Members can manage at_asset_types in their accounts" ON public.at_asset_types;
DROP POLICY IF EXISTS "Members can manage at_assets in their accounts" ON public.at_assets;
DROP POLICY IF EXISTS "Members can manage at_asset_tags in their accounts" ON public.at_asset_tags;
DROP POLICY IF EXISTS "Members can manage at_gateways in their accounts" ON public.at_gateways;
DROP POLICY IF EXISTS "Members can read at_position_events in their accounts" ON public.at_position_events;
DROP POLICY IF EXISTS "Members can insert at_position_events in their accounts" ON public.at_position_events;
DROP POLICY IF EXISTS "Members can read at_alerts in their accounts" ON public.at_alerts;
DROP POLICY IF EXISTS "Members can insert at_alerts in their accounts" ON public.at_alerts;
DROP POLICY IF EXISTS "Members can update at_alerts in their accounts" ON public.at_alerts;
DROP POLICY IF EXISTS "Members can manage at_device_state in their accounts" ON public.at_device_state;
DROP POLICY IF EXISTS "Members can manage at_dali_commands in their accounts" ON public.at_dali_commands;
DROP POLICY IF EXISTS "Members can manage at_facility_settings in their accounts" ON public.at_facility_settings;

-- profiles
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- accounts (no client INSERT — creation is via create-account Edge Function with service role only)
CREATE POLICY "Members can read their accounts"
  ON public.accounts FOR SELECT
  USING (id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Admins can update their accounts"
  ON public.accounts FOR UPDATE
  USING (id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid() AND role = 'admin'));

-- account_memberships (no client INSERT — creation is via create-account Edge Function with service role only)
CREATE POLICY "Users can read own memberships"
  ON public.account_memberships FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can update memberships in their account"
  ON public.account_memberships FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can delete memberships in their account"
  ON public.account_memberships FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid() AND role = 'admin'));

-- properties
CREATE POLICY "Members can read properties in their accounts"
  ON public.properties FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can insert properties in their accounts"
  ON public.properties FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can update properties in their accounts"
  ON public.properties FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can delete properties in their accounts"
  ON public.properties FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- dc_metadata
CREATE POLICY "Members can read dc_metadata in their accounts"
  ON public.dc_metadata FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can insert dc_metadata in their accounts"
  ON public.dc_metadata FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can update dc_metadata in their accounts"
  ON public.dc_metadata FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can delete dc_metadata in their accounts"
  ON public.dc_metadata FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- sitdeck_risk_config
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

-- risk_diagnosis
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

-- physical_risk_flags (via risk_diagnosis.account_id)
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

-- spaces
CREATE POLICY "Members can manage spaces in their account properties"
  ON public.spaces FOR ALL
  USING (
    property_id IN (
      SELECT p.id FROM public.properties p
      JOIN public.account_memberships m ON m.account_id = p.account_id
      WHERE m.user_id = auth.uid()
    )
  );

-- systems
CREATE POLICY "Members can read systems in their accounts"
  ON public.systems FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can insert systems in their accounts"
  ON public.systems FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can update systems in their accounts"
  ON public.systems FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can delete systems in their accounts"
  ON public.systems FOR DELETE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- meters
CREATE POLICY "Members can manage meters in their accounts"
  ON public.meters FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- end_use_nodes
CREATE POLICY "Members can manage end_use_nodes in their accounts"
  ON public.end_use_nodes FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- data_library_records
CREATE POLICY "Members can manage data_library_records in their accounts"
  ON public.data_library_records FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- documents
CREATE POLICY "Members can manage documents in their accounts"
  ON public.documents FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- evidence_attachments
CREATE POLICY "Members can manage evidence_attachments for records in their accounts"
  ON public.evidence_attachments FOR ALL
  USING (
    data_library_record_id IN (
      SELECT id FROM public.data_library_records
      WHERE account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid())
    )
  );

-- agent_runs
CREATE POLICY "Members can read agent_runs in their accounts"
  ON public.agent_runs FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can insert agent_runs in their accounts"
  ON public.agent_runs FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can update agent_runs in their accounts"
  ON public.agent_runs FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- agent_findings (account_id scope; SitDeck webhook inserts use service role)
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

-- audit_events
CREATE POLICY "Members can read audit_events in their accounts"
  ON public.audit_events FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can insert audit_events"
  ON public.audit_events FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- Asset Tracking — account-scoped policies (same membership pattern)
CREATE POLICY "Members can manage at_floors in their accounts"
  ON public.at_floors FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_zones in their accounts"
  ON public.at_zones FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_asset_types in their accounts"
  ON public.at_asset_types FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_assets in their accounts"
  ON public.at_assets FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_asset_tags in their accounts"
  ON public.at_asset_tags FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_gateways in their accounts"
  ON public.at_gateways FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can read at_position_events in their accounts"
  ON public.at_position_events FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can insert at_position_events in their accounts"
  ON public.at_position_events FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can read at_alerts in their accounts"
  ON public.at_alerts FOR SELECT
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can insert at_alerts in their accounts"
  ON public.at_alerts FOR INSERT
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));
CREATE POLICY "Members can update at_alerts in their accounts"
  ON public.at_alerts FOR UPDATE
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_device_state in their accounts"
  ON public.at_device_state FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_dali_commands in their accounts"
  ON public.at_dali_commands FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

CREATE POLICY "Members can manage at_facility_settings in their accounts"
  ON public.at_facility_settings FOR ALL
  USING (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()))
  WITH CHECK (account_id IN (SELECT account_id FROM public.account_memberships WHERE user_id = auth.uid()));

-- agent_findings: set account_id from agent_run when clients omit it
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

-- ============================================================================
-- PART 4: Trigger — create profile on signup
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, updated_at)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email), now())
  ON CONFLICT (id) DO UPDATE SET updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- PART 5: RPC — account name check (used by Lovable onboarding)
-- ============================================================================
-- Bypasses RLS so unauthenticated or new users can check if an org name is taken.

CREATE OR REPLACE FUNCTION public.check_account_name_exists(account_name text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.accounts WHERE lower(name) = lower(account_name)
  );
$$;

-- ============================================================================
-- MIGRATIONS (run only if you already have the table with the old constraint)
-- ============================================================================
-- Allow allocation_method 'mixed' (part measured, part allocated) on systems:
-- ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_allocation_method_check;
-- ALTER TABLE public.systems ADD CONSTRAINT systems_allocation_method_check
--   CHECK (allocation_method IN ('measured', 'area', 'estimated', 'mixed'));

-- Fix "systems_controlled_by_check" when app sends tenant_controlled / landlord_controlled:
-- 1) Allow those values in the CHECK.
-- 2) Normalize to tenant | landlord | shared on insert/update so stored data stays consistent.
-- Run the following in Supabase SQL Editor:

-- DROP CONSTRAINT (name may be systems_controlled_by_check):
-- ALTER TABLE public.systems DROP CONSTRAINT IF EXISTS systems_controlled_by_check;
-- ALTER TABLE public.systems ADD CONSTRAINT systems_controlled_by_check
--   CHECK (controlled_by IN ('tenant', 'landlord', 'shared', 'tenant_controlled', 'landlord_controlled'));

-- Trigger to normalize controlled_by before insert/update:
-- CREATE OR REPLACE FUNCTION public.normalize_systems_controlled_by()
-- RETURNS TRIGGER LANGUAGE plpgsql AS $$
-- BEGIN
--   NEW.controlled_by := CASE NEW.controlled_by
--     WHEN 'tenant_controlled' THEN 'tenant'
--     WHEN 'landlord_controlled' THEN 'landlord'
--     ELSE NEW.controlled_by
--   END;
--   RETURN NEW;
-- END;
-- $$;
-- DROP TRIGGER IF EXISTS normalize_systems_controlled_by_trigger ON public.systems;
-- CREATE TRIGGER normalize_systems_controlled_by_trigger
--   BEFORE INSERT OR UPDATE OF controlled_by ON public.systems
--   FOR EACH ROW EXECUTE FUNCTION public.normalize_systems_controlled_by();

-- Optional: add auto_generated to end_use_nodes (for portfolio default nodes):
-- ALTER TABLE public.end_use_nodes ADD COLUMN IF NOT EXISTS auto_generated boolean DEFAULT false;

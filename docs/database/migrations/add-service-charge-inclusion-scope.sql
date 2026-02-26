-- Service charge inclusion scope: base building only vs complete tenant consumption
-- When a utility is "included in service charge", this indicates whether the SC covers
-- base building spaces only, or the tenant's full consumption (base building shared + tenant space).
-- See docs/architecture/coverage-and-applicability-for-agent.md §2.2 and §5 (double counting).

ALTER TABLE public.property_service_charge_includes
  ADD COLUMN IF NOT EXISTS water_inclusion_scope text
    CHECK (water_inclusion_scope IS NULL OR water_inclusion_scope IN ('base_building_only', 'tenant_consumption_included')),
  ADD COLUMN IF NOT EXISTS heating_inclusion_scope text
    CHECK (heating_inclusion_scope IS NULL OR heating_inclusion_scope IN ('base_building_only', 'tenant_consumption_included')),
  ADD COLUMN IF NOT EXISTS energy_inclusion_scope text
    CHECK (energy_inclusion_scope IS NULL OR energy_inclusion_scope IN ('base_building_only', 'tenant_consumption_included'));

COMMENT ON COLUMN public.property_service_charge_includes.water_inclusion_scope IS
  'When includes_water is true: base_building_only = SC covers only base building/common areas; tenant_consumption_included = SC includes tenant full share (base building shared + measured/allocated tenant spaces). Affects double-counting: only tenant_consumption_included means do not add separate water records.';
COMMENT ON COLUMN public.property_service_charge_includes.heating_inclusion_scope IS
  'When includes_heating is true: base_building_only = SC covers only base building; tenant_consumption_included = SC includes tenant full share.';
COMMENT ON COLUMN public.property_service_charge_includes.energy_inclusion_scope IS
  'When includes_energy is true: base_building_only = SC covers only base building electricity; tenant_consumption_included = SC includes tenant full share (e.g. allocated base building + tenant).';

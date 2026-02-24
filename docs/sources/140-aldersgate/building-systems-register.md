# 140 Aldersgate — Building Systems Register (Secure SoR) + Nodes

**Site:** 140 Aldersgate, London  
**Version:** v2.4 (as provided)  
**Taxonomy alignment:** Updated taxonomy covers all systems below (incl. Monitoring + GasSupply + Lighting overlay sensors/gateways)

---

## A) Building Systems Register (authoritative list)

| systemId | systemCategory | System Name | systemType | Controlled By | Maintained By | Serves Spaces | Metering Status | Allocation Method | Key Specs | Spec Status |
|---|---|---|---|---|---|---|---|---|---|---|
| power_main_elec | Power | Main Incoming Electricity Supply | GridLVSupply | Landlord | Landlord | Whole Property | Fiscal meter (LV switch room) | Whole building → submeter split | Supply No. 1200051331498 | REAL |
| power_tenant_submeters | Power | Tenant Electricity Submeters (6 total) | ElectricitySubmeters | Tenant | Landlord (meter infra) | Ground, 4th, 5th | Submetered | Direct measured | Meter IDs confirmed (6) | REAL |
| power_main_gas_meter | Power | Main Gas Meter | GasSupply | Landlord | Landlord | Whole Property | Fiscal only | Service charge allocation | Gas intake room | REAL |
| hvac_base_building_plant | HVAC | Base Building HVAC Plant | CentralPlant_Unknown | Landlord | Landlord | Whole Building | Not tenant-metered | Embedded in service charge | Plant specs unknown | REAL (Context confirmed) |
| hvac_local_controls | HVAC | Local HVAC Controls | ZoneControls | Shared | Tenant (local) / Landlord (plant) | Ground, 4th, 5th | Not separately metered | Electricity + service charge | Shared operational boundary | REAL |
| lighting_legacy_control | Lighting | Simmtronic SPECS | LegacyLightingControl | Landlord | Landlord | Whole Building | Included in electricity | Service charge embedded | ~20 yrs old; LCM ceiling units; 15V E-BUS; on/off only | REAL |
| lighting_enocean_motion | Lighting | EnOcean Motion Sensors | OccupancySensors | Tenant | Tenant | Ground, 4th, 5th | Data-only | Included in tenant electricity | 89 installed | REAL |
| lighting_danlers_climate | Lighting | Danlers Climate Sensors | EnvironmentalSensors | Tenant | Tenant | Ground, 4th, 5th | Data-only | Included in tenant electricity | 12 installed | REAL |
| lighting_gateways | Lighting | Lighting Gateways | GatewayDevices | Tenant | Tenant | Ground, 4th, 5th | Data-only | Included in tenant electricity | 2 installed | REAL |
| plugloads_it_small_power | PlugLoads | IT & Small Power | TenantPlugLoads | Tenant | Tenant | Ground, 4th, 5th | Included in tenant electricity | Direct measured | Embedded in floor submeters | REAL |
| water_fiscal_meter | Water | Fiscal Water Meter | MainsSupply | Landlord | Landlord | Whole Property | Single fiscal meter | Area allocation | Boiler room | REAL |
| water_tenant_allocation | Water | Tenant Water Allocation | AllocatedConsumption | Landlord (billing) | Landlord | Ground, 4th, 5th | Not submetered | Service charge | Toilets in landlord space; tenant cannot retrofit fixtures | REAL |
| waste_contractor_recorra | Waste | Waste Contractor – Recorra | WasteCollection | Shared | Landlord contract | Ground, 4th, 5th | Measured by weight | Direct billed by stream | Confirmed streams; Office Guide | REAL |
| waste_recycling_stations | Waste | Recycling Stations | SegregatedWasteInfrastructure | Shared | Landlord | Ground, 4th, 5th | Not metered | Included in contract | Streams: household, glass, tins/cans, plastics, mixed paper & card | REAL |
| bms_trend_iqvision | BMS | Trend IQ Vision | CentralBMS | Landlord | Landlord | Whole Building | N/A (control system) | N/A | Head-end in site office | REAL |
| iot_haltian_people_counting | Monitoring | Haltian People Counting Sensors | PeopleCountingSensors | Tenant | Tenant | Ground, 4th, 5th | Data-only | N/A | 38 sensors | REAL |
| iot_paxton_net2 | Monitoring | Paxton Net2 | AccessControl | Tenant | Tenant | Ground, 4th, 5th | Data-only | N/A | Tenant-managed access | REAL |
| lifts_passenger | Lifts | Passenger Lifts | PassengerLift | Landlord | Landlord | Whole Building | Not tenant-metered | Service charge allocation | 3 × 16-person lifts | REAL |

---

## B) Nodes (end-use) linked to systems

> **Rule:** each node links to exactly one system (by `linkedSystemName` below; Lovable implementation can map to `systemId`).

| nodeId | nodeCategory | utilityType | linkedSystemName | appliesToSpaceIds | controlOverride | allocationWeight | notes |
|---|---|---|---|---|---|---:|---|
| E_TENANT_PLUG | tenant_plug_load | electricity | Tenant Electricity Submeters (6 total) | [SPACE_TENANT_DEMISE] | TENANT | 0.45 | Tenant plug loads captured in floor submeters |
| E_TENANT_LIGHT | tenant_lighting | electricity | Tenant Electricity Submeters (6 total) | [SPACE_TENANT_DEMISE] | TENANT | 0.15 | Tenant demise lighting on submeters |
| E_HVAC_SERVE_TENANT | hvac_serving_tenant | electricity | Base Building HVAC Plant | [SPACE_TENANT_DEMISE] | LANDLORD | 0.30 | HVAC electricity typically in landlord plant / service charge |
| E_BASE_LIGHT | base_building_lighting | electricity | Main Incoming Electricity Supply | [SPACE_BASE_BUILDING] | LANDLORD | 0.05 | Common areas / cores |
| E_LIFTS_PLANT | lifts_and_plant | electricity | Passenger Lifts | [SPACE_WHOLE_BUILDING] | LANDLORD | 0.05 | Lift electricity; no tenant control |
| H_TENANT_ZONE | tenant_zone_conditioning | heating | Local HVAC Controls | [SPACE_TENANT_DEMISE] | SHARED | 0.70 | Tenant can adjust local zones; landlord controls plant |
| H_BASE_BUILDING | base_building_conditioning | heating | Base Building HVAC Plant | [SPACE_BASE_BUILDING] | LANDLORD | 0.20 | Cores/common areas |
| H_SHARED | shared_conditioning | heating | Base Building HVAC Plant | [SPACE_WHOLE_BUILDING] | SHARED | 0.10 | Shared boundary / mixed benefit |
| W_PANTRY | pantry_water | water | Tenant Water Allocation | [SPACE_TENANT_DEMISE] | TENANT | 0.20 | Pantry sinks within tenant demise (no submeter) |
| W_TOILETS | toilets_water | water | Tenant Water Allocation | [SPACE_BASE_BUILDING] | LANDLORD | 0.70 | Toilets are landlord space; tenant cannot retrofit fixtures |
| W_SHARED | shared_water | water | Fiscal Water Meter | [SPACE_WHOLE_BUILDING] | SHARED | 0.10 | Shared taps/cleaning/etc. |
| WA_OFFICE | office_waste | waste | Waste Contractor – Recorra | [SPACE_TENANT_DEMISE] | SHARED | 1.00 | Landlord contract; tenant controls segregation behaviour |
| WA_RECYCLING_INFRA | recycling_streams | waste | Recycling Stations | [SPACE_TENANT_DEMISE] | SHARED | — | Streams: household, glass, tins/cans, plastics, mixed paper & card |
| O_PEOPLE_COUNT | people_counting | occupancy | Haltian People Counting Sensors | [SPACE_TENANT_DEMISE] | TENANT | — | 38 sensors |
| A_ACCESS | access_control | access | Paxton Net2 | [SPACE_TENANT_DEMISE] | TENANT | — | Tenant-managed access |

---

## C) Notes for platform implementation

1. **Taxonomy update required (not data change):**
   - Add `Monitoring` category
   - Add `GasSupply` under `Power`
   - Add `OccupancySensors`, `EnvironmentalSensors`, `GatewayDevices` under `Lighting` (to match register classification)

2. **Nodes are already consistent** with the systems list; no node renames required.

3. Dashboard boundary enforcement:
   - Electricity nodes: measured (tenant submeters) + building incoming supply
   - Heating / water: allocated / service charge (until landlord breakdown exists)
   - Occupancy/access: datasets only (never roll into energy/carbon totals)

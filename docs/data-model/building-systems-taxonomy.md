# Building Systems Taxonomy (Secure SoR)

**Version:** v1.0 (140 Aldersgate coverage + "complete building" placeholders)

This taxonomy standardises:

- Building Systems Register classification
- Node-to-System linking (end-use / virtual meters)
- Landlord–Tenant boundary logic (control + billing + metering)

Aligned with: Lovable.ai UI, Agent rules (Boundary / Data Readiness).

---

## 1) System Categories → System Types (enum)

> **Rule:** every `buildingSystem` has exactly one `systemCategory` and one `systemType`.

| systemCategory (enum) | Description | systemType examples (enum) |
|---|---|---|
| Power | Incoming supplies, distribution, metering, on-site generation | GridLVSupply, ElectricitySubmeters, **GasSupply**, UPS, Generator, PVInverter |
| HVAC | Heating/cooling/ventilation plant + terminal units + controls | CentralPlant_Unknown, Boilers, Chillers, HeatPumps, AHU, VRF, FCU, **ZoneControls**, Thermostats, HeatNetworkHIU |
| Lighting | Lighting infra + lighting control + lighting IoT overlay | TenantLighting, EmergencyLighting, **LegacyLightingControl**, **OccupancySensors**, **EnvironmentalSensors**, **GatewayDevices**, DALI, KNXLighting |
| PlugLoads | Tenant plug loads and small power | TenantPlugLoads, ServerRoomLoads, KitchenEquipment, EVCharging |
| Water | Water supply + metering/submetering + allocation | MainsSupply, **AllocatedConsumption**, SubmeteredWater, DHW, Irrigation, LeakDetection |
| Waste | Waste collection contracts + segregation infrastructure | WasteCollection, **SegregatedWasteInfrastructure**, FoodWasteSystem, BalerCompactor |
| BMS | Building management/control head-end and integrations | **CentralBMS**, TrendIQVision, SiemensDesigo, Honeywell |
| Lifts | Vertical transport | **PassengerLift**, GoodsLift |
| **Monitoring** | Occupancy/access/experience monitoring (not plant control) | **PeopleCountingSensors**, **AccessControl**, IAQPlatform, DeskBooking, ComplaintsSystem |

---

## 2) End-use Nodes taxonomy

### 2.1 Node model (minimum fields)

- nodeId (string)
- nodeCategory (enum)
- utilityType (enum)
- linkedSystemId (string) OR linkedSystemName (string)
- appliesToSpaceIds[] (array)

Optional:

- controlOverride (TENANT | LANDLORD | SHARED)
- allocationWeight (0..1)
- notes

### 2.2 utilityType (enum)

- electricity
- heating
- cooling
- water
- waste
- occupancy
- access
- air_quality (reserved)

### 2.3 nodeCategory (examples)

**Electricity:**

- tenant_plug_load
- tenant_lighting
- hvac_serving_tenant
- base_building_lighting
- lifts_and_plant

**Heating/Cooling:**

- tenant_zone_conditioning
- base_building_conditioning
- shared_conditioning

**Water:**

- pantry_water
- toilets_water
- shared_water

**Waste:**

- office_waste
- recycling_streams

**Occupancy / Access:**

- people_counting
- access_control

---

## 3) "Complete building" placeholders (recommended to exist even if unused at 140A)

| Future category | Example system types |
|---|---|
| LifeSafety | FireAlarm, SmokeControl, Sprinklers, FireDampers |
| Security | CCTV, IntruderAlarm, Turnstiles, Intercom |
| ICT | LAN, WiFi, ServerRoom, TelecomsRiser, BMSNetwork |
| Envelope | Facade, Roof, Glazing, Insulation |
| PlumbingDrainage | Drainage, SumpPumps, Greywater, WaterTreatment |
| Amenities | Showers, Gym, Canteen, BikeStorage |

---

## 4) Validation rules (recommended)

1. When used, allocationWeight should sum to ~1 for a given scope (e.g., tenant demise electricity end-uses).
2. If meteringStatus = not tenant-metered, dashboards must show Included in Service Charge / Allocated / Partial.
3. occupancy/access nodes are non-utility datasets and must never roll into energy/carbon totals.

# Templates for Secure SoR

## building-systems-register-template.csv

Use this as the expected format when implementing **Upload register** on the Physical and Technical page. The first row must be headers; column names are matched case-insensitively and with common variants (see implementation plan).

- **Required for insert:** System Name, systemCategory, Controlled By, Metering Status, Allocation Method.
- **Normalization:** Values are normalized to DB enums (e.g. Tenant → tenant, Submetered → partial). See [implementation-plan-lovable-supabase-agent.md](../implementation-plan-lovable-supabase-agent.md) § Upload building systems register.
- **Do not map to UUID:** Map **"Serves Spaces"** only to **serves_spaces_description** (text). Do **not** map any column to **serves_space_ids** (that column is uuid[] and must be real space UUIDs from the DB; numbers like "1" or "89" from the file will cause "invalid input syntax for type uuid").

**If import fails with "invalid input syntax for type uuid: '1'":** Run the migration [add-insert-system-from-register-rpc.sql](../database/migrations/add-insert-system-from-register-rpc.sql) in Supabase, then in Lovable use `supabase.rpc('insert_system_from_register', { payload })` instead of `.from('systems').insert()`. See implementation plan § "Permanent fix (use safe RPC)".

## sample-waste-invoice-jan2026-recorra-140-aldersgate.csv

**Sample waste invoice (CSV)** — Jan 2026 Recorra Waste for 140 Aldersgate, with **all streams included**. One row; columns: Name, Reporting period start/end, Contractor, Total kg, Total cost GBP, Confidence, Invoice ref, Property, Serves spaces, Notes, **Streams_breakdown** (JSON array: Household waste 420 kg, Mixed paper & card 285 kg, Plastics 120 kg, Mixed glass 95 kg, Food tins & drink cans 48 kg). The app must store **Streams_breakdown** in `value_text` so the Waste page **Streams breakdown** tile can display it. Use on Data Library Waste: Add Data → Upload (same Upload that accepts CSV and documents). See [data-library-waste-bill-sample-payload.md](../data-library-waste-bill-sample-payload.md). Manual Entry / Delete / streams tile prompt: data-library-what-to-do-next.md § "Waste — Manual Entry, Delete, CSV extraction, and streams tile".

## sample-waste-invoice-feb2026-recorra-140-aldersgate.csv

**February 2026** — Same format as the January invoice: one row, columns Name, Reporting period start/end, Contractor, Total kg (932), Total cost GBP (321.84), Confidence, Streams_breakdown (Household 405, Paper 272, Plastics 118, Glass 91, Tins 46 kg). Use with Add Data → Upload on the Waste page. Upload both Jan and Feb to test the Segregation tile "By month" vs "All" view.

## sample-waste-invoice-jan2026-recorra-lumen-technology-hq.csv / sample-waste-invoice-feb2026-recorra-lumen-technology-hq.csv

**Lumen Technology HQ** (5 floors, 2500 sqm) — Same invoice format as 140 Aldersgate. Jan: 1280 kg, £440.32, streams Household 550, Paper 370, Plastics 155, Glass 130, Tins 75. Feb: 1230 kg, £423.50. Property "Lumen Technology HQ", Serves spaces "1st 2nd 3rd 4th 5th". Invoice refs REC-0126-LTHQ, REC-0226-LTHQ.

## sample-waste-invoice-jan2026-recorra-moleculeq-technology-uk.csv / sample-waste-invoice-feb2026-recorra-moleculeq-technology-uk.csv

**MoleculeQ Technology UK** (1 floor, 1000 sqm) — Same invoice format. Jan: 387 kg, £133.25, streams Household 167, Paper 112, Plastics 47, Glass 39, Tins 22. Feb: 372 kg, £128.00. Property "MoleculeQ Technology UK", Serves spaces "1st floor". Invoice refs REC-0126-MOLQ, REC-0226-MOLQ.

## sample-waste-streams-140-aldersgate.csv

**Streams-only format** — 5 rows (one per stream): Stream, kg, Method, plus invoice name/period/contractor. **Do not use for upload** — the Waste page expects the invoice CSV format. This file is reference only. Same 140 Aldersgate data: Household waste 420, Mixed paper & card 285, Plastics 120, Mixed glass 95, Food tins & drink cans 48 kg.

## sample-energy-tenant-electricity-jan2026-mapp-140-aldersgate.csv / sample-energy-tenant-electricity-feb2026-mapp-140-aldersgate.csv

**Energy — Tenant Electricity, 140 Aldersgate London** — Supplier MAPP. One row per bill. Jan 2026: 25,883 kWh, £8,536.00 (invoice ref MAPP-0126-140ALD). Feb 2026: 24,820 kWh, £8,180.00 (MAPP-0226-140ALD). Columns: Name, Reporting period start/end, Supplier, Total kWh, Total cost GBP, Unit (kWh), Confidence, Invoice ref, Property, data_type (tenant_electricity), Notes. Use for Data Library Energy → Tenant Electricity: Manual Entry (or CSV import if the app supports it). Map to `data_library_records`: subject_category **energy**, value_numeric = Total kWh, unit = kWh, value_text = Supplier + invoice + cost notes. See [data-library-energy-bill-sample-payload.md](../data-library-energy-bill-sample-payload.md) for record shape.

## sample-energy-tenant-electricity-jan2026-mapp-lumen-technology-hq.csv / sample-energy-tenant-electricity-feb2026-mapp-lumen-technology-hq.csv

**Energy — Tenant Electricity, Lumen Technology HQ** (5 floors, 2500 sqm). Consumption scaled by size vs 140 Aldersgate. Jan 2026: 43,200 kWh, £14,240 (MAPP-0126-LTHQ). Feb 2026: 41,400 kWh, £13,650 (MAPP-0226-LTHQ). Same column layout; Property "Lumen Technology HQ".

## sample-energy-tenant-electricity-jan2026-mapp-moleculeq-technology-uk.csv / sample-energy-tenant-electricity-feb2026-mapp-moleculeq-technology-uk.csv

**Energy — Tenant Electricity, MoleculeQ Technology UK** (1 floor, 1000 sqm). Consumption scaled by size. Jan 2026: 17,250 kWh, £5,690 (MAPP-0126-MOLQ). Feb 2026: 16,550 kWh, £5,460 (MAPP-0226-MOLQ). Same column layout; Property "MoleculeQ Technology UK".

## sample-service-charge-jan2026-140-aldersgate.csv / sample-service-charge-feb2026-140-aldersgate.csv

**Energy — Service Charge / Landlord Utilities, 140 Aldersgate** — Allocated (not measured). One row per period. Jan 2026: £3,068.05 (SC-0126-140ALD). Feb 2026: £2,980.00 (SC-0226-140ALD). Includes heat pump, electricity base building, water; full breakout pending. Unit N/A (bundled utilities). Columns: Name, Reporting period start/end, Total cost GBP, Unit (N/A), Confidence (allocated), Invoice ref, Property, data_type (landlord_recharge), Notes. Use for Data Library Energy → Landlord Utilities (Service Charge): Upload CSV or Manual Entry. Map to `data_library_records`: subject_category **energy**, data_type **landlord_recharge**, value_numeric = Total cost GBP, unit = "N/A", confidence = **allocated**, value_text = Notes. See data-library-what-to-do-next.md § "Service Charge (Landlord Utilities)".

## sample-heating-jan2026-140-aldersgate.csv / sample-heating-feb2026-140-aldersgate.csv

**Energy — Heating, 140 Aldersgate** — One row per period. Jan 2026: 5,200 kWh, £780 (HET-0126-140ALD). Feb 2026: 4,900 kWh, £735 (HET-0226-140ALD). Heat pump / heat network, base building. Columns: Name, Reporting period start/end, Supplier, Total kWh, Total cost GBP, Unit (kWh), Confidence (measured), Invoice ref, Property, data_type (heating), Notes. Map to `data_library_records`: subject_category **energy**, data_type **heating**, value_numeric = Total kWh, unit = kWh, value_text = TotalCostGBP + Notes. See data-library-what-to-do-next.md § "Heating — same components".

## sample-water-jan2026-140-aldersgate.csv / sample-water-feb2026-140-aldersgate.csv

**Energy — Water, 140 Aldersgate** — One row per period. Jan 2026: 85 m³, £420 (WAT-0126-140ALD). Feb 2026: 82 m³, £405 (WAT-0226-140ALD). Fiscal water meter, base building allocation. Columns: Name, Reporting period start/end, Supplier, Total m3, Total cost GBP, Unit (m³), Confidence (measured), Invoice ref, Property, data_type (water), Notes. Map to `data_library_records`: subject_category **energy**, data_type **water**, value_numeric = Total m3, unit = m³, value_text = TotalCostGBP + Notes. See data-library-what-to-do-next.md § "Water — same components".

## sample-scope1-stationary-jan2026-140-aldersgate.csv / sample-scope1-stationary-feb2026-140-aldersgate.csv

**Energy — Scope 1 (Direct Emissions), stationary combustion, 140 Aldersgate** — One row per period. Jan 2026: 1,200 kWh gas, £360 (S1G-0126-140ALD). Feb 2026: 1,150 kWh, £345 (S1G-0226-140ALD). Natural gas, main gas meter, base building. Columns: Name, Reporting period start/end, Fuel type, Quantity, Unit, Total cost GBP, Confidence, Invoice ref, Property, data_type (scope1_stationary), Notes. Map to `data_library_records`: subject_category **energy**, data_type **scope1_stationary**, value_numeric = Quantity, unit = Unit, value_text = TotalCostGBP + Fuel type + Notes. Scope 1 has **three** add options: Upload, Manual Entry, **Calculator** (fuel/refrigerant type + quantity; app stores activity). See data-library-what-to-do-next.md § "Scope 1 (Direct Emissions)".

## Scope 3 — Indirect Activities (140 Aldersgate)

**Commuting (500 employees, 50% desk-based, min 3 days/week office, mostly public transport):**  
- **sample-scope3-commuting-jan2026-140-aldersgate.csv** — 3 rows (Train 255,000 km, Bus 91,000 km, Car 18,000 km). Columns: Name, Reporting period start/end, Mode, Quantity km, Unit, Confidence, Property, data_type (employee_commuting_train | employee_commuting_bus | employee_commuting_car), Notes.  
- **sample-scope3-commuting-feb2026-140-aldersgate.csv** — 3 rows (Train 250,000, Bus 89,000, Car 17,500 km). Same format. Use on Data Library → Indirect Activities → Employee Commuting: Upload or Manual Entry. subject_category **indirect_activities**, value_numeric = Quantity km, unit = km.

**Business travel (fictive names, all employees):** One row per trip; one CSV per mode.  
- **sample-scope3-business-travel-flights-jan2026-140-aldersgate.csv** — 8 trips (e.g. Sarah Chen LHR–Edinburgh, James Wright LHR–Dublin, Priya Sharma LGW–Glasgow). data_type **business_travel_flights**.  
- **sample-scope3-business-travel-rail-jan2026-140-aldersgate.csv** — 8 trips (e.g. Emma Foster King's Cross–Manchester, David Okonkwo Paddington–Bristol). data_type **business_travel_rail**.  
- **sample-scope3-business-travel-car-jan2026-140-aldersgate.csv** — 5 trips (e.g. Michael Torres London–Birmingham, Anna Kowalski London–Slough). data_type **business_travel_car**.  
- **sample-scope3-business-travel-bus-jan2026-140-aldersgate.csv** — 4 coach trips (e.g. Helen Brooks Victoria–Oxford, Raj Patel Stratford–Brighton). data_type **business_travel_bus**.  

Columns (business travel): Name, Reporting period start/end, Employee, Trip description, Origin, Destination, Quantity km, Unit, Confidence, Property, data_type, Notes. Map to `data_library_records`: subject_category **indirect_activities**, value_numeric = Quantity km, unit = km, value_text = Employee + Trip + Origin + Destination + Notes. See data-library-what-to-do-next.md § "Scope 3 — Indirect Activities".

## building-systems-register-140-aldersgate.csv

**Full 140 Aldersgate building systems** — all 18 systems from the [building-systems-register.md](../sources/140-aldersgate/building-systems-register.md) (Power, HVAC, Lighting, PlugLoads, Water, Waste, BMS, Monitoring, Lifts). Same column layout as the generic template above. Use this file to import the complete Aldersgate register in one go, or as a reference when filling your own spreadsheet. Normalization and UUID rules apply the same way.

## seed-nodes-140-aldersgate.json

Template for **seed default nodes** (e.g. "Add default nodes" on the Nodes section). Contains the 140 Aldersgate node set: node_id, node_category, utility_type, linkedSystemName, spacePlaceholder, control_override, allocation_weight, notes.

- **Resolve at seed time:** Map `linkedSystemName` to `systems.id` by matching system name for the property. Map `spacePlaceholder` to space UUIDs: SPACE_TENANT_DEMISE → tenant spaces, SPACE_BASE_BUILDING → base building spaces, SPACE_WHOLE_BUILDING → all spaces (from `spaces` for the property).
- **Insert into:** `end_use_nodes` with account_id, property_id, system_id (resolved), node_id, node_category, utility_type, applies_to_space_ids (resolved), control_override, allocation_weight, notes.
- **Source:** Same data as [building-systems-register.md §B](../sources/140-aldersgate/building-systems-register.md).

## nodes-upload-template.csv

Use this format when implementing **Upload nodes** (CSV/Excel) on the Nodes section. Headers (case-insensitive): node_id, node_category, utility_type, linked_system_name (or Linked System Name), space_placeholder (or Space Placeholder / applies_to_space_ids), control_override, allocation_weight, notes.

- **Required:** node_id (unique per property), node_category, utility_type, linked_system_name, space_placeholder (or space names/IDs — see upload steps).
- **Resolve:** linked_system_name → systems.id by matching system name for the property. space_placeholder → applies_to_space_ids: SPACE_TENANT_DEMISE = tenant spaces, SPACE_BASE_BUILDING = base building, SPACE_WHOLE_BUILDING = all spaces.
- **Normalize:** control_override = TENANT | LANDLORD | SHARED (uppercase); allocation_weight 0..1 or empty.

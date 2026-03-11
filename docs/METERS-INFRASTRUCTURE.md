# Meters infrastructure (backend and UI)

**Purpose:** Single reference for the **meters** layer in Secure: what exists in the backend, how it relates to systems and data library, and what is (not) built in the UI.

---

## 1. Backend — what exists

### Table: `meters`

First-class meter entity; can be linked to a system. Defined in [database/schema.md](database/schema.md) §3.7 and [database/supabase-schema.sql](database/supabase-schema.sql).

| Column       | Type      | Nullable | Description |
|-------------|-----------|----------|-------------|
| id          | uuid      | NO       | PK |
| account_id  | uuid      | NO       | FK → accounts.id |
| property_id | uuid      | NO       | FK → properties.id |
| system_id   | uuid      | YES      | FK → systems.id (optional) |
| name        | text      | NO       | |
| meter_type  | text      | YES      | e.g. electricity, gas, water |
| unit        | text      | YES      | e.g. kWh, m³ |
| external_id | text      | YES      | Supplier / meter ID |
| created_at  | timestamptz | NO    | |
| updated_at  | timestamptz | NO    | |

- **Indexes:** account_id, property_id, system_id.
- **RLS:** “Members can manage meters in their accounts” (FOR ALL with account check).

### Relationship to systems

- **systems** table has:
  - **metering_status** — `none` | `partial` | `full` (normalized on import; see [fix-systems-metering-status-import.sql](database/migrations/fix-systems-metering-status-import.sql)).
  - **key_specs** — free text, often used for “meter IDs” or plant specs from the building systems register.
- A **meter** row can reference a **system** via `system_id` (nullable). So: property → systems; property → meters; optionally meter → system.
- Consumption data (readings) lives in **data_library_records** (and optionally in future meter_readings or similar), not in `meters`; `meters` is the **asset** (the meter device or logical meter), not the time-series.

### Data flow (intended)

- **Property** has many **systems** (Building Systems tab) and many **meters**.
- **Meters** can be linked to a system (e.g. “Submeter 6th floor” → system “Tenant Electricity”).
- **Metering status** on the system describes whether that system is none/partial/full metered; **key_specs** can hold meter IDs.
- **Readings** (kWh, m³, etc.) are stored as **data_library_records** (subject_category energy/water, etc.); linking a record to a specific meter (e.g. `meter_id` on data_library_records) is optional and not in the current schema — today records are property/category scoped.

---

## 2. Lovable UI — what is built

- **Property Detail → Physical & Technical → “Meters” tab:**  
  Only a **placeholder**: “Metering data is displayed within Building Systems above. Select the Building Systems tab to view metering infrastructure.”  
  There is **no** list of meters, no CRUD, and no Supabase read/write to the `meters` table from this tab.

- **Building Systems tab:**  
  Shows **systems** (with metering_status, allocation, etc.). No UI that lists or edits **meters** or links a meter to a system.

- **Elsewhere:**  
  “Meters” and “submeters” appear in copy (Landing, Data Library sample row, Digital Twin, Diagnosis, DC PUE placeholder). None of these use the `meters` table.

So: **the meters table is unused in the app.** The backend is ready; the UI does not yet expose it.

---

## 3. What is not built (meters)

| Item | Status |
|------|--------|
| **Meters tab content** | Replace placeholder with a list of meters for the property (from `meters` table), with add/edit/delete if required. |
| **Link meter ↔ system** | UI to attach a meter to a system (or show “meters for this system”) using `meters.system_id`. |
| **Optional: meter_id on data_library_records** | If readings should be tied to a specific meter, schema would need a `meter_id` (or similar) on data_library_records; not in current schema. |
| **Register / import** | If meters are imported from a register (e.g. CSV), define whether that goes through a new RPC/migration or through systems + key_specs only. |

---

## 4. References

- [database/schema.md](database/schema.md) §3.7 meters, §3.5 systems (metering_status, key_specs).
- [database/supabase-schema.sql](database/supabase-schema.sql) — `CREATE TABLE meters`, indexes, RLS.
- [data-model/building-systems-taxonomy.md](data-model/building-systems-taxonomy.md) — metering and system types (e.g. ElectricitySubmeters, SubmeteredWater).
- [AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md](AUDIT-ROUTES-COMPONENTS-AUTOMATION-GAPS.md) — backend data surface (meters = CRUD).
- [BACKEND-VS-LOVABLE-UI-ALIGNMENT.md](BACKEND-VS-LOVABLE-UI-ALIGNMENT.md) § Meters infrastructure.

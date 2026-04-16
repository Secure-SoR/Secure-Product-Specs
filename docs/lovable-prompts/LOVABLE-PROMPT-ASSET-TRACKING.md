# Lovable prompts — Asset Tracking (Secure SoR)

**Source of truth:** [secure-asset-tracking-spec-v2.0.md](../specs/secure-asset-tracking-spec-v2.0.md)  
**Schema / columns:** [schema.md](../database/schema.md) §3.15, migrations in [docs/database/migrations/](../database/migrations/)  
**Run migrations on staging before wiring Supabase** (see [implementation-guide-asset-tracking-phase-1.md](../specs/implementation-guide-asset-tracking-phase-1.md)).

**Hard rules (do not violate):**

- **Sensor split:** Fixed building sensors stay under **Property › Physical & Technical › Sensors** (`systems`, etc.). **Asset Tracking › Tracking Sensors** uses **`at_asset_tags`** only — do not merge lists or share one component.
- **Do not** add AT columns to `spaces` or reuse DC / Data Library routes for AT data.
- **Optional zone → space link** column is **`at_zones.space_id`** (FK → `spaces.id`), not `spaces_id`.

Paste each block below into Lovable in order (or split across sessions). Adjust paths if your app’s router differs slightly.

---

## Troubleshooting — “I don’t see Asset Tracking”

1. **Sidebar is hidden by design until AT is enabled**  
   Prompt A hides the nav item unless **at least one property** in the current account has `properties.at_enabled = true`.  
   **Fix:** In Supabase SQL Editor run:  
   `UPDATE public.properties SET at_enabled = true WHERE id = '<your-property-uuid>';`  
   Reload the app. If RLS blocks the update, use an admin account or run as appropriate for your environment.

2. **Wrong route prefix (very common)**  
   Every page must live under the **`/asset-tracking`** prefix.  
   **Wrong:** `/alerts`, `/devices`, `/admin/floors` at the app root.  
   **Right:** `/asset-tracking/alerts`, `/asset-tracking/devices`, `/asset-tracking/admin/floors`.  
   If nested routes were declared as children without a parent path, React Router (and similar) may mount them at the root — fix the parent route to `path="asset-tracking"` (or `path="/asset-tracking/*"`) and nest children as `alerts`, `live`, etc., so the full URL is `/asset-tracking/alerts`, etc.

3. **Query for “any AT property” fails or returns empty**  
   Confirm the client selects `at_enabled` from `properties` with `.eq('account_id', currentAccountId)` (or equivalent). Typos (`atEnabled` vs `at_enabled`), missing column (migration not run), or wrong account scope will keep the sidebar hidden.

4. **Quick visibility for development**  
   Optionally show the sidebar link **always** (or when `import.meta.env.DEV`) and only gate *content* on `at_enabled`, so you can debug routing without toggling DB every time. Remove or tighten before production.

---

## Prompt A-fix — Correct AT routes and sidebar (paste if module missing or 404s)

```
Fix Asset Tracking routing and navigation.

1. ALL user-facing URLs MUST use the prefix /asset-tracking/ — not /alerts, /devices, /admin at root.
   Required paths:
   /asset-tracking
   /asset-tracking/live
   /asset-tracking/alerts
   /asset-tracking/devices
   /asset-tracking/analytics
   /asset-tracking/analytics/playback
   /asset-tracking/admin
   /asset-tracking/admin/floors
   /asset-tracking/admin/assets
   /asset-tracking/admin/configuration
   /asset-tracking/admin/settings

2. In the router (React Router v6 or whatever the app uses), define a parent route at "asset-tracking" with nested child routes so Link components use relative paths but resolved URLs include /asset-tracking/... . Audit every <Link to="..."> and navigate() call.

3. Sidebar: ensure one entry "Asset Tracking" points to /asset-tracking. If the entry is hidden because no property has at_enabled, either:
   (a) document that users must set at_enabled in Supabase, OR
   (b) for dev, show the link when NODE_ENV/ import.meta.env.DEV is true.

4. Add a temporary small label under the nav item showing (enabledPropertiesCount) to verify the Supabase query used for visibility.

Output a short checklist in comments: route path → file component.
```

---

## Prompt A — Module shell, routes, sidebar, facility context

```
Add the Asset Tracking module to the Secure Lovable app.

CRITICAL — URL prefix: Every route below MUST be registered under the path prefix /asset-tracking (full paths like /asset-tracking/alerts, not /alerts). Nested routers must use a parent route "asset-tracking" so child paths do not mount at site root.

1. Routes (match product spec §7.1):
   - /asset-tracking — landing: if the account has multiple properties with properties.at_enabled = true, show a facility selector; otherwise default to the single enabled property and redirect or show content for that property_id.
   - /asset-tracking/live
   - /asset-tracking/alerts
   - /asset-tracking/devices
   - /asset-tracking/analytics
   - /asset-tracking/analytics/playback
   - /asset-tracking/admin (index or redirect to a sensible default e.g. admin/floors)
   - /asset-tracking/admin/floors
   - /asset-tracking/admin/assets
   - /asset-tracking/admin/configuration
   - /asset-tracking/admin/settings

2. Sidebar: add "Asset Tracking" entry linking to /asset-tracking (only show if the current account has at least one property with at_enabled = true, or always show but gate content — prefer conditional visibility). Document in a code comment that the sidebar is HIDDEN until at_enabled is true on at least one property.

3. Use existing Secure layout (header, sidebar, cards, typography). Read property_id and account_id from app context / route params consistently across all AT pages.

4. Guard: if the selected property has at_enabled = false, show a short message that Asset Tracking is not enabled for this facility and link back to properties.

5. Do not modify Data Library, Data Centre dashboards, or Physical & Technical routes.
```

---

## Prompt B — Property detail: "Asset Tracking" summary tab only

```
On the existing Property detail page (/properties/:id), add a main tab "Asset Tracking" that is visible only when properties.at_enabled === true for that property.

This tab is a SUMMARY entry point only (spec §7.2–7.3). Do NOT embed the full live map, full admin, or duplicate Physical & Technical Sensors here.

Content for the tab:
1. Short description: "Open the Asset Tracking module for live views, devices, and administration."
2. Primary CTA buttons linking to:
   - /asset-tracking/live?propertyId=<id> (or your chosen query param / context pattern)
   - /asset-tracking/admin/floors?propertyId=<id>
   - /asset-tracking/devices?propertyId=<id>
3. "AT Readiness" summary tiles (computed from Supabase):
   - Active assets: count at_assets where property_id = id and status = 'active'
   - Tracked now: count distinct asset_id from at_position_events where property_id = id and recorded_at > now() - interval '5 minutes'
   - Online gateways: count at_gateways where property_id = id and online = true
   - Unread alerts: count at_alerts where property_id = id and status = 'unread'
   - Missing tag: count at_assets where property_id = id and status = 'active' and tag_id is null
4. Optional: simple "readiness %" from floors with images + zones count + tags assigned (define a clear formula in code comments).

Use Supabase client with RLS. Do not change behaviour of other property tabs.
```

**Tab not visible?** You do **not** need a new property. Either run SQL (see [add-at-enabled-to-properties.sql](../database/migrations/add-at-enabled-to-properties.sql)) or add **Prompt B-add-on** below so admins can turn AT on from the UI.

---

## Prompt B-add-on — “Enable Asset Tracking” toggle (property page; paste this)

```
On the Property detail page (/properties/:id), add a way to turn Asset Tracking on or off without using SQL.

Placement (important — avoid chicken-and-egg):
- Put the control on the main property view that is ALWAYS visible (e.g. Overview / Settings card or “Facility options” section), NOT inside the “Asset Tracking” tab (that tab is hidden while at_enabled is false).

Behaviour:
1. Label: “Asset Tracking for this facility” with short help text: “When enabled, the Asset Tracking tab and module navigation appear for this property.”
2. Use a Switch/Toggle bound to properties.at_enabled for the current property id from the route.
3. On change: supabase.from('properties').update({ at_enabled: checked, updated_at: new Date().toISOString() }).eq('id', propertyId).select().single()
4. On success: invalidate/refetch property query so the “Asset Tracking” tab visibility updates immediately.
5. Permissions: only account admins may toggle (reuse the same role check you use for other property-level admin actions, e.g. account_memberships.role === 'admin'). Viewers/members: show the toggle disabled or hide it with a tooltip “Only account admins can enable Asset Tracking.”
6. If turning OFF: optional confirm dialog — “Hide Asset Tracking tab and sidebar entry for this facility?” (sidebar hides when no property in the account has at_enabled true.)

Ensure the property fetch includes the at_enabled column (add it to the select list if missing).

Do not add new database columns; use existing properties.at_enabled.
```

---

## Prompt C — Admin: floors, floor plans, zones, GPS calibration

```
Build /asset-tracking/admin/floors for the current property (from context or ?propertyId=).

Data: at_floors, at_zones, storage bucket at-floor-plans, spaces (optional dropdown for at_zones.space_id).

1. Floor list: all at_floors for this property_id. Columns: name, level_index, has floor plan (boolean from floor_plan_image_url), zone count (aggregate). "Add floor" → modal: name, level_index, coord_system (pixel | local_metres | gps).

2. Floor detail (click row): three tabs:
   a) Floor plan: upload PNG/SVG to bucket path account/{accountId}/property/{propertyId}/floors/{floorId}/{filename} (match storage RLS path pattern). Save path in at_floors.floor_plan_image_url; set floor_plan_width_px and floor_plan_height_px from the image after load; display image preview.
   b) Zones: list at_zones for this floor_id — name, zone_type badge (public=green, restricted=red, staff_entry=amber), vertex count from polygon JSON, optional linked space name (join spaces on at_zones.space_id). Actions: edit, delete. "Draw zone": polygon tool over the floor plan image; on save, store polygon as jsonb array [{x,y}, ...]. Zone form: name, zone_type select, optional space_id (searchable dropdown of spaces for this property only). DB column is space_id (FK → spaces.id).
   c) GPS calibration: table of pixel_x, pixel_y, lat, lng; add/remove rows; save to at_floors.gps_calibration as jsonb array. Show this tab only when coord_system = 'gps'.

3. All CRUD via Supabase .from('at_floors'|'at_zones') with RLS; uploads via storage API.

4. Do not change the existing Property "Floors & Spaces" page — this is AT-only.
```

---

## Prompt D — Admin: configuration (categories + types) and asset registry

```
Build two routes:

1) /asset-tracking/admin/configuration
Tabs: "Asset categories" | "Asset types"

Asset categories tab:
- List distinct category values present in at_asset_types for this account (workers, drilling_equipments, loading_equipments, medical_kit per spec). Allow adding a "new category" only if implemented as inserting a placeholder type or document that categories are enum-driven — prefer read-only list from spec enums plus short descriptions from spec copy.
- If you keep dynamic categories, store them only via at_asset_types.category text (no separate table).

Asset types tab:
- Table: icon (from icon_key), name, category, scope ("Account-wide" if property_id IS NULL, "This facility" if property_id = current property), actions.
- Query: WHERE account_id = current AND (property_id IS NULL OR property_id = current property), order account-wide first then facility-specific.
- Add type modal: name, category (select), scope radio (Account-wide vs This facility only), icon picker mapping to icon_key string. On save: set property_id NULL or current property id. Show warning: icon_key cannot be changed after save (disable icon field on edit).
- Delete: if any at_assets references asset_type_id, block with toast error.

2) /asset-tracking/admin/assets
- Table: icon from type, name, type name, default zone name, status badge, tag (wirepas_node_id or "Unassigned"), actions (edit, delete).
- Search filters name and serial_number.
- Add/Edit asset modal: name (required); asset type (dropdown from query above); default zone (at_zones for property); serial_number; optional user link (profiles/users in account — store user_id on at_assets); assign tag from at_asset_tags where property_id matches and assigned_asset_id IS NULL. When changing tag on an asset that already has tag_id, confirm unassign; then clear at_assets.tag_id and previous tag's assigned_asset_id and set new assignment in one logical flow (transaction if available).
- Enforce: updating tag assignment keeps at_asset_tags.assigned_asset_id and at_assets.tag_id consistent.

Use Supabase only; scope by account_id and property_id.
```

---

## Prompt E — Devices: Lights, Gateways, Tracking Sensors

```
Build /asset-tracking/devices with three tabs (spec §8.3).

PROPERTY SELECTION (required — do not assume silent global context):
- At the top of the page, show a "Facility" Select/dropdown listing all properties for the current account where at_enabled = true (query properties with account_id + at_enabled).
- Resolve selected propertyId in this order: (1) URL search param ?propertyId=<uuid> if valid and AT-enabled, (2) else if exactly one AT-enabled property exists, auto-select it and replaceState/setSearchParams to add ?propertyId= so the URL is shareable, (3) else require the user to pick from the dropdown; on change, update ?propertyId= and refetch all tabs.
- Until propertyId is resolved, show a short message + the facility dropdown only — do NOT run Lights/Gateways/Sensors queries with an empty id (avoids empty/wrong data).

1) Lights — data from at_device_state joined to systems (read-only join) for fixture name, serves_spaces_description, serves_space_ids. Filter by property_id = selectedPropertyId. Do NOT write to systems. Cards/rows: device identifier (from systems.key_specs or name), room/space label, online, on/off, dim % (disable slider when at_device_state.daylight_harvesting_active is true), power_watts, als_value (label as not calibrated to lux), DH badges, behaviour_mode_index as chips (Motion / Daylight / Eco / Scene per product copy). Toggle on/off and dim changes insert rows into at_dali_commands with status queued and appropriate payload (command_type set_on_off, set_dim_level, etc.).

2) Gateways — at_gateways for selected property_id. Table: name, floor, online, connected_node_count, last_heartbeat_at. Empty state: "No gateways configured". Add gateway form → insert at_gateways (wirepas_gateway_id unique per property).

3) Tracking Sensors — NOT the same as Physical & Technical Sensors. Section A: recent positions from at_position_events for selected property. Section B: at_asset_tags left join at_assets for selected property; Active if last_seen_at > now() - 5 minutes else Inactive.

RLS on all tables.
```

---

## Prompt E-fix — Devices page: add facility selector (paste if you cannot pick property)

```
Fix /asset-tracking/devices so the user can always choose the facility.

Problem: Opening /asset-tracking/devices from the sidebar has no ?propertyId=, and there is no React Context property — so queries use undefined property_id and nothing useful loads.

Implement:
1) Fetch list: supabase.from('properties').select('id,name,at_enabled').eq('account_id', currentAccountId).eq('at_enabled', true)
2) Top of page: <Select> "Facility" with options = that list. Show property name; value = id.
3) Selected id = read from useSearchParams().get('propertyId') if it matches one of the options; otherwise if options.length === 1 auto-pick and navigate.replace({ search: `propertyId=${id}` }); else selected = null until user chooses.
4) When user changes Select, navigate to same path with ?propertyId=newId (useNavigate + setSearchParams).
5) Gate all three tabs' useQuery/useEffect on Boolean(selectedPropertyId) — enabled: !!selectedPropertyId
6) Apply the same pattern to /asset-tracking/live, /asset-tracking/alerts, /asset-tracking/admin/* if they have the same bug.

Optional: extract shared hook useAtSelectedPropertyId() used by all AT routes.
```

---

## Prompt F — AT facility settings

```
Build /asset-tracking/admin/settings for the current property.

Load or create a single at_facility_settings row per property_id (unique). Form fields (spec §8.7):
- position_update_interval_sec: select 5, 10, 15, 30, 60 (enforce DB check 5–60)
- prolonged_idle_threshold_min
- panic_button_default_action: panic | movement_detection | custom_scene
- out_of_zone_enabled, restricted_entry_enabled toggles
- dali_motion_timeout_sec, dali_dh_setpoint_als (optional numbers)

On first visit, if no row exists, insert defaults from spec defaults with account_id and property_id from context.

Save updates updated_at.
```

---

## Prompt G — Live tracking

```
Build /asset-tracking/live (spec §8.1).

Data: latest position per asset (query at_position_events distinct on asset_id ordered by recorded_at desc, or equivalent), at_assets + at_asset_types, at_floors, at_zones for overlays, at_alerts unread count, at_facility_settings for poll interval.

Layout:
- Top summary tiles: Active assets; In maintenance; Lost/Missing (active assets with no position in last 30 min — make interval configurable via constant matching spec); Most active floor; Total tracked.
- Filters: floor dropdown, asset type, status (map spec filters to at_assets.status; if "Available/Reserved" is not in schema, map to closest or hide until spec adds fields).
- Left panel: list of assets on selected floor with icon, name, type, zone, status; click highlights marker.
- Right panel: floor plan image; plot markers at x_pos/y_pos scaled to image dimensions; tooltip on marker.
- Buttons: Live indicator; Historical View opens modal or navigates to /asset-tracking/analytics/playback with query params; Alerts opens slide-over panel listing at_alerts status=unread with acknowledge/dismiss (UPDATE at_alerts; rely on DB trigger for audit_events — do not duplicate audit insert from client if trigger exists).

Realtime: subscribe to postgres_changes on at_position_events filtered by property_id if publication enabled; else poll using position_update_interval_sec from settings.

Do not import or wrap Data Library, DC, or Physical & Technical components.
```

---

## Prompt H — Alert management page

```
Build /asset-tracking/alerts (spec §8.2).

- Summary tiles: total alerts, counts by alert_type for selected time range.
- Table: type badge, message, asset name, floor, zone, triggered_at, status, actions (acknowledge, dismiss for unread).
- Filters: time range (15m, 1h, 24h, 7d, all), alert_type, status.
- Reference panel (static copy) describing alert types from spec — not loaded from DB.

Mutations: only status transitions on at_alerts. Acknowledge → status acknowledged + acknowledged_by + acknowledged_at. Dismiss → dismissed. Assume server trigger writes audit_events on update.
```

---

## Prompt I — Analytics landing and historical playback

```
1) /asset-tracking/analytics — landing page with cards/links to reports described in spec §10 (dwell time, zone occupancy, T&A, alert summary). For first iteration, implement placeholder sections with "Coming soon" OR basic charts fed by SQL queries over at_position_events and at_alerts if time permits. Match Secure dashboard card styling.

2) /asset-tracking/analytics/playback — historical playback (spec §8.6): select asset, datetime range, play/pause/step, speed 1x/2x/5x/10x, scrubber; load at_position_events for asset ordered by recorded_at; animate marker on floor plan; empty state message exactly as spec when no rows.

Reuse floor plan + marker rendering from live page where possible.
```

---

## Prompt J — Hooks / data layer

```
Create src/hooks/asset-tracking/ (or project-equivalent) with typed hooks:

- useAtPropertyGate(propertyId) — fetches properties.at_enabled
- useAtFloors(propertyId), useAtZones(floorId), useAtAssetTypes(accountId, propertyId), useAtAssets(propertyId), useAtAssetTags(propertyId)
- useLatestPositions(propertyId, floorId?), useAtAlerts(propertyId, filters), useAtFacilitySettings(propertyId)
- useAtDeviceStateForProperty(propertyId) — join systems + at_device_state for Lighting/DALILight rows only

Centralise Supabase client usage; handle loading/error states; never query Physical & Technical sensors tables for Tracking Sensors UI.

Add TODO comments only for Edge Function ingest (at-position-ingest) — not implemented in Lovable.
```

---

## Not for Lovable (backend / Supabase)

- **Phase 0 validation** and **Edge Functions** (`at-position-ingest`, `at-dali-ingest`): implement in Supabase, not Lovable. Spec Appendix B Prompts 1, 5, 6 describe these.
- **`at_alerts` → `audit_events`**: if you applied migrations from this repo, the DB trigger `at_alerts_audit_trigger` already writes audit rows on insert/update — the Lovable app should not double-insert.

---

## Order suggestion

A → B → C → D → E → F → G → H → I → J

After J, refine UX and Realtime publication in Supabase dashboard as needed.

# Lovable prompt — Property latitude & longitude

**Same content as** [../lovable-prompts/LOVABLE-PROMPT-PROPERTY-LAT-LNG.md](../lovable-prompts/LOVABLE-PROMPT-PROPERTY-LAT-LNG.md) — lives here **next to** [implementation-guide-phase-3-dc.md](./implementation-guide-phase-3-dc.md) for reliable `./` links in Cursor. Keep both in sync.

**Use when:** Step 3.3 — property coordinates for SitDeck / maps / DC dashboards.  
**Schema:** [schema.md](../database/schema.md) · **Migration:** [add-properties-lat-lng.sql](../database/migrations/add-properties-lat-lng.sql)

---

## Prompt (copy everything inside the fence)

```
On the Integrations & Evidence page (or property settings / property edit), add Latitude and Longitude fields, saved to properties.latitude and properties.longitude.

## Requirements

1. **Placement:** Add a small section (e.g. "Property location" or under an existing location block) on whichever screen already scopes to a single selected property — prefer Integrations & Evidence if that page is property-scoped; otherwise use the main property settings or edit form. The user must be able to see which property they are editing.

2. **Fields:**
   - **Latitude** — number input (decimal degrees). Nullable / clearable.
   - **Longitude** — number input (decimal degrees). Nullable / clearable.
   - Optional short hint: "Used for maps and SitDeck risk dashboards (data centre properties)."

3. **Load:** When the page loads for the current property, fetch `latitude` and `longitude` with the rest of the property row from `properties` (e.g. `.select('..., latitude, longitude')`) and populate the fields.

4. **Save:** On explicit Save (or on blur if that matches the rest of the page), update only the current property:
   - `supabase.from('properties').update({ latitude, longitude }).eq('id', currentPropertyId)`
   - Send `null` for cleared fields (not empty string), so the DB stays `numeric` nullable.
   - Respect existing RLS (authenticated client).

5. **Validation (client):**
   - If latitude is filled: must be between -90 and 90.
   - If longitude is filled: must be between -180 and 180.
   - Show inline errors; do not save until valid or both empty.

6. **Optional:** If `asset_type === 'data_centre'`, show a non-blocking note that lat/lng are recommended for SitDeck widgets — do not block save if empty.

7. **Do not** create migrations or alter schema from Lovable. If columns are missing, product runs add-properties-lat-lng.sql in Supabase SQL Editor first (see backend docs/database/migrations/add-properties-lat-lng.sql).

## Done when

- User can enter, clear, and persist latitude/longitude for a property; values appear after refresh.
- DC dashboards / SitDeck embeds can read `properties.latitude` and `properties.longitude` for the same property.
```

---

## After Lovable implements

- Confirm columns exist: run [add-properties-lat-lng.sql](../database/migrations/add-properties-lat-lng.sql) if the app errors on unknown column.
- Test with a data_centre property: set coordinates, open a Risk Intelligence route, confirm embed or map uses the values.

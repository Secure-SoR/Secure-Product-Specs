-- Safe insert for building systems register import (avoids "invalid input syntax for type uuid: '1'").
-- The app may send serves_space_ids from a spreadsheet column with numbers (1, 2, 89); this RPC
-- never writes those to the DB — only valid UUIDs or NULL. Also validates account_id and property_id.
-- Run in Supabase → SQL Editor. Then in Lovable, use supabase.rpc('insert_system_from_register', { payload: {...} }) for each row instead of .from('systems').insert(...).

CREATE OR REPLACE FUNCTION public.insert_system_from_register(payload jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  new_id uuid;
  space_ids uuid[] := '{}';
  arr jsonb;
  i int;
  elem text;
  uuid_pattern text := '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
BEGIN
  -- Reject invalid account_id or property_id (e.g. "1" from wrong mapping)
  IF payload->>'account_id' IS NULL OR payload->>'account_id' !~ uuid_pattern THEN
    RAISE EXCEPTION 'insert_system_from_register: account_id must be a valid UUID, got "%"', payload->>'account_id';
  END IF;
  IF payload->>'property_id' IS NULL OR payload->>'property_id' !~ uuid_pattern THEN
    RAISE EXCEPTION 'insert_system_from_register: property_id must be a valid UUID, got "%"', payload->>'property_id';
  END IF;

  -- Build serves_space_ids only from valid UUIDs; ignore any non-UUID (e.g. "1", "89" from spreadsheet)
  IF payload ? 'serves_space_ids' AND jsonb_typeof(payload->'serves_space_ids') = 'array' THEN
    arr := payload->'serves_space_ids';
    FOR i IN 0..jsonb_array_length(arr)-1 LOOP
      elem := (arr->i)#>>'{}';
      IF elem IS NOT NULL AND elem ~ uuid_pattern THEN
        space_ids := array_append(space_ids, elem::uuid);
      END IF;
    END LOOP;
  END IF;

  INSERT INTO public.systems (
    account_id,
    property_id,
    name,
    system_category,
    system_type,
    controlled_by,
    maintained_by,
    metering_status,
    allocation_method,
    allocation_notes,
    key_specs,
    spec_status,
    serves_space_ids,
    serves_spaces_description
  ) VALUES (
    (payload->>'account_id')::uuid,
    (payload->>'property_id')::uuid,
    COALESCE(nullif(trim(payload->>'name'), ''), 'Unnamed system'),
    COALESCE(nullif(trim(payload->>'system_category'), ''), 'Other'),
    nullif(trim(payload->>'system_type'), ''),
    COALESCE(lower(nullif(trim(payload->>'controlled_by'), '')), 'tenant'),
    nullif(trim(payload->>'maintained_by'), ''),
    COALESCE(lower(nullif(trim(payload->>'metering_status'), '')), 'none'),
    COALESCE(lower(nullif(trim(payload->>'allocation_method'), '')), 'estimated'),
    nullif(trim(payload->>'allocation_notes'), ''),
    nullif(trim(payload->>'key_specs'), ''),
    nullif(trim(payload->>'spec_status'), ''),
    CASE WHEN array_length(space_ids, 1) > 0 THEN space_ids ELSE NULL END,
    nullif(trim(payload->>'serves_spaces_description'), '')
  )
  RETURNING id INTO new_id;

  RETURN new_id;
END;
$$;

COMMENT ON FUNCTION public.insert_system_from_register(jsonb) IS
  'Safe insert for building systems register import. Sanitizes serves_space_ids (only valid UUIDs); validates account_id and property_id. Use from Lovable instead of .from(''systems'').insert() to avoid uuid parse errors.';

GRANT EXECUTE ON FUNCTION public.insert_system_from_register(jsonb) TO authenticated;

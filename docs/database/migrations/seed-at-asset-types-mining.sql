-- Seed account-level at_asset_types for mining POC (spec §3.2)
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §3.2
--
-- Edit v_account below to your pilot account UUID, then run once.

DO $$
DECLARE
  v_account uuid := NULL; -- e.g. 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid;
BEGIN
  IF v_account IS NULL THEN
    RAISE NOTICE 'seed-at-asset-types-mining: set v_account to your account id; no rows inserted.';
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.accounts WHERE id = v_account) THEN
    RAISE NOTICE 'seed-at-asset-types-mining: account % not found; no rows inserted.', v_account;
    RETURN;
  END IF;

  INSERT INTO public.at_asset_types (account_id, property_id, name, category, icon_key)
  SELECT v_account, NULL, v.name, v.category, v.icon_key
  FROM (VALUES
    ('Worker', 'workers', 'icon_worker'),
    ('Drilling Jumbos', 'drilling_equipments', 'icon_drilling_jumbo'),
    ('Jacklegs', 'drilling_equipments', 'icon_jackleg'),
    ('Rocker Shovel Loaders', 'loading_equipments', 'icon_rsl'),
    ('First Aid Box', 'medical_kit', 'icon_first_aid')
  ) AS v(name, category, icon_key)
  WHERE NOT EXISTS (
    SELECT 1 FROM public.at_asset_types t
    WHERE t.account_id = v_account AND t.property_id IS NULL AND t.name = v.name
  );
END $$;

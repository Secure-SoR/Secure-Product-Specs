-- Storage RLS for bucket at-floor-plans (Asset Tracking floor plan images)
-- Spec: docs/specs/secure-asset-tracking-spec-v2.0.md §6.1
-- 1) Create bucket "at-floor-plans" in Supabase Dashboard → Storage (private).
-- 2) Run this script in SQL Editor.
-- Suggested object path: account/{accountId}/property/{propertyId}/{filename}

DROP POLICY IF EXISTS "AT floor plans: upload" ON storage.objects;
DROP POLICY IF EXISTS "AT floor plans: read" ON storage.objects;
DROP POLICY IF EXISTS "AT floor plans: update" ON storage.objects;
DROP POLICY IF EXISTS "AT floor plans: delete" ON storage.objects;

CREATE POLICY "AT floor plans: upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'at-floor-plans'
    AND split_part(name, '/', 1) = 'account'
    AND split_part(name, '/', 2) IN (
      SELECT m.account_id::text FROM public.account_memberships m WHERE m.user_id = auth.uid()
    )
  );

CREATE POLICY "AT floor plans: read"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'at-floor-plans'
    AND split_part(name, '/', 1) = 'account'
    AND split_part(name, '/', 2) IN (
      SELECT m.account_id::text FROM public.account_memberships m WHERE m.user_id = auth.uid()
    )
  );

CREATE POLICY "AT floor plans: update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'at-floor-plans'
    AND split_part(name, '/', 1) = 'account'
    AND split_part(name, '/', 2) IN (
      SELECT m.account_id::text FROM public.account_memberships m WHERE m.user_id = auth.uid()
    )
  );

CREATE POLICY "AT floor plans: delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'at-floor-plans'
    AND split_part(name, '/', 1) = 'account'
    AND split_part(name, '/', 2) IN (
      SELECT m.account_id::text FROM public.account_memberships m WHERE m.user_id = auth.uid()
    )
  );

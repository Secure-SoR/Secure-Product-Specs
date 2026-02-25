-- Storage RLS policies for bucket secure-documents (Data Library evidence uploads)
-- Run in Supabase SQL Editor after creating the bucket "secure-documents" (private).
-- Path format from app: account/{accountId}/property/{propertyId}/{yyyy}/{mm}/{documentId}-{fileName}
-- or account/{accountId}/account-level/{yyyy}/{mm}/... when no property.
-- Safe to re-run: drops existing policies first.

DROP POLICY IF EXISTS "Users can upload to secure-documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can read secure-documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete from secure-documents" ON storage.objects;

-- Allow authenticated users to upload to secure-documents
CREATE POLICY "Users can upload to secure-documents"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'secure-documents');

-- Allow authenticated users to read from secure-documents
CREATE POLICY "Users can read secure-documents"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'secure-documents');

-- Allow authenticated users to delete from secure-documents (evidence cleanup when attachment is removed)
CREATE POLICY "Users can delete from secure-documents"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'secure-documents');

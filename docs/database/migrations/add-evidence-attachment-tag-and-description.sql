-- Optional: add tag and description to evidence_attachments (Lovable Evidence panel)
-- Run if the UI stores evidence tag (invoice, contract, methodology, certificate, report, other) and description per attachment.

ALTER TABLE public.evidence_attachments
  ADD COLUMN IF NOT EXISTS tag text,
  ADD COLUMN IF NOT EXISTS description text;

COMMENT ON COLUMN public.evidence_attachments.tag IS 'Evidence type: invoice, contract, methodology, certificate, report, other';
COMMENT ON COLUMN public.evidence_attachments.description IS 'Optional description for this attachment';

-- Optional: constrain tag to known values (uncomment if you want DB enforcement)
-- ALTER TABLE public.evidence_attachments DROP CONSTRAINT IF EXISTS evidence_attachments_tag_check;
-- ALTER TABLE public.evidence_attachments
--   ADD CONSTRAINT evidence_attachments_tag_check
--   CHECK (tag IS NULL OR tag IN ('invoice', 'contract', 'methodology', 'certificate', 'report', 'other'));

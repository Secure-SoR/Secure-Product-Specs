# Waste bill sample — upload and record shape

Sample: **Jan 2026 Recorra Waste for 140 Aldersgate** (aligned with [140 Aldersgate bills-register](../sources/140-aldersgate/bills-register.md) and [building-systems-register](../sources/140-aldersgate/building-systems-register.md)). Use this for testing the Data Library **Waste** page.

**Sample CSV to upload:** [sample-waste-invoice-jan2026-recorra-140-aldersgate.csv](../templates/sample-waste-invoice-jan2026-recorra-140-aldersgate.csv)  
**One row = one invoice = one record.** The CSV has one row with all 140 Aldersgate waste fields: Name, Reporting period start/end, Contractor, Total kg, Total cost GBP, Confidence, Invoice ref, Property, Serves spaces, Notes, **Streams_breakdown** (JSON array of stream, kg, method). The app must create **exactly one** data_library_record for that row: total kg and total cost on the record, and **Streams_breakdown stored in value_text** so the **Streams breakdown / Segregation** tile can read and display it. Do **not** create one record per stream — the streams are only for the tile to render from that single record's value_text. (The file [sample-waste-streams-140-aldersgate.csv](../templates/sample-waste-streams-140-aldersgate.csv) is a 5-row alternative format for reference only; if the app accepts it, it must merge those 5 rows into one record with summed total kg and streams in value_text, not create 5 records.)

**Manual Entry:** If the Waste page has no Manual Entry button, use the Lovable prompt in [data-library-what-to-do-next.md](data-library-what-to-do-next.md) § "Waste — Manual Entry, Delete, CSV extraction, and streams tile".

**If you have a different sample bill (e.g. PDF or image of the real Recorra invoice):** Paste the text or a description here (or in a new doc under `docs/sources/140-aldersgate/` or `docs/templates/`) and we can align the CSV columns and stream names to match it.

---

## 1. Sample invoice reference (140 Aldersgate)

| Section      | Field / content |
|-------------|------------------|
| Contractor  | Recorra |
| Invoice No  | REC-0126-140ALD |
| Period      | January 2026 (01 Jan – 31 Jan 2026) |
| Property    | 140 Aldersgate |
| Address     | 140 Aldersgate Street, London EC1A 4HY |
| Billed To   | Apex Group Services UK |
| Serves      | Ground, 4th, 5th |
| **Streams** | Household waste 420 kg; Mixed paper & card 285 kg; Plastics 120 kg; Mixed glass 95 kg; Food tins & drink cans 48 kg |
| **Total**   | 968 kg; Net £277.60; VAT £55.52; Total due £333.12 |
| Confidence  | Measured by weight |
| Method      | Direct billed by stream. Independent contractor; not in landlord service charge. |
| Scope       | 3 (Waste) |

---

## 2. What the upload should create

When the user uploads this file on the **Waste** page, the app should (same pattern as Energy):

1. Upload the file to Supabase Storage (`secure-documents`), path e.g. `account/{accountId}/property/{propertyId}/2026/01/{docId}-sample-waste-invoice-jan2026-recorra-140-aldersgate.txt`.
2. Insert a row into `documents` (account_id, storage_path, file_name, mime_type, file_size_bytes).
3. Insert a row into `data_library_records` with at least:
   - `account_id` = current account
   - `property_id` = current property (e.g. 140 Aldersgate’s UUID) or null
   - `subject_category` = **waste**
   - `source_type` = **upload**
   - `name` = e.g. **"Waste Jan 2026 – Recorra"** or from filename
   - Optionally: `reporting_period_start` = 2026-01-01, `reporting_period_end` = 2026-01-31; `value_numeric` = 968 (total kg) or 333.12 (total £); `unit` = "kg" or "GBP"; `confidence` = "measured"; `value_text` = "Contractor: Recorra; Invoice: REC-0126-140ALD"
4. Insert a row into `evidence_attachments` linking that record to that document (tag e.g. "invoice").

So **one uploaded file (one invoice row) → one waste record** + one document + one evidence_attachment. That single record holds the invoice total kg, total cost, and the streams breakdown in value_text; the Streams breakdown tile displays the streams from this record — do not create separate records per stream. No manual entry required for the record; the user can later edit the record to add period, kg, cost if the app supports it.

---

## 3. Target record shape (for one waste bill)

| Field                   | Example / notes |
|------------------------|-----------------|
| name                   | "Waste Jan 2026 – Recorra" |
| subject_category       | waste |
| source_type            | upload |
| reporting_period_start | 2026-01-01 |
| reporting_period_end    | 2026-01-31 |
| value_numeric          | 968 (total kg) or 333.12 (total £) |
| unit                   | kg or GBP |
| confidence             | measured |
| value_text             | Store the **Streams_breakdown** JSON from the CSV here (or append to Notes). Example: `[{"stream":"Household waste","kg":420,"method":"measured"},{"stream":"Mixed paper & card","kg":285,"method":"measured"},...]` so the Streams breakdown tile can parse and display Stream \| kg \| Method. |
| property_id            | 140 Aldersgate’s UUID (from app context) |

**Streams in the sample (140 Aldersgate):** Household waste 420 kg; Mixed paper & card 285 kg; Plastics 120 kg; Mixed glass 95 kg; Food tins & drink cans 48 kg. Total 968 kg. All method = measured.

---

## 4. If the Waste page has no Upload button

The Data Library **Waste** page should offer **Upload** (and optionally Manual Entry) like Energy. If it doesn’t, use the same pattern as the Energy upload prompt: add an “Upload” or “Upload waste invoice” action that opens a file picker, then for each file: upload to Storage → insert `documents` → insert `data_library_records` (subject_category **waste**, source_type **upload**, name from filename or "Waste Jan 2026 – Recorra") → insert `evidence_attachments`. See [data-library-what-to-do-next.md](data-library-what-to-do-next.md) “Restore Add/Upload buttons” and “Upload energy record = file upload” and apply the same logic for Waste with subject_category `"waste"`.

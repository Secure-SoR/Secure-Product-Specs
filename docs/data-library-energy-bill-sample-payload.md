# Energy bill sample — extraction target

This document defines the **target shape** for one electricity bill based on the **sample invoice** (UrbanGrid Energy Ltd, January 2026, Lumen Technology HQ). Use it for:

- **Manual entry:** which fields to fill after uploading the PDF.
- **Future PDF/OCR or AI extraction:** what to extract and where to put it in `data_library_records` and `documents`.

Schema reference: [database/schema.md](database/schema.md) (`data_library_records`, `documents`, `evidence_attachments`).

---

## 1. Sample bill reference

| Bill section | Field on document | Example value |
|--------------|-------------------|----------------|
| Header | Period | January 2026 |
| Invoice details | Supplier | UrbanGrid Energy Ltd |
| | Invoice No | UGE-0126-LTHQ |
| | Invoice Date | 31 January 2026 |
| | Billed To | Lumen Technology (UK) Limited |
| | Property | Lumen Technology HQ |
| | Address | 120 Montgomery Square, London EC1 5BN |
| | Leased Area | 1,500 sqm (3 floors) |
| **Consumption table** | Floor | Ground / 3rd / 4th |
| | Consumption (kWh) | 10,050 ; 10,420 ; 9,870 |
| | Rate (p/kWh) | 26.10 |
| | Net (£) | 2,623.05 ; 2,720.62 ; 2,575.07 |
| **Summary** | Total Consumption | 30,340 kWh |
| | Net Energy Cost | £7,918.74 |
| | Climate Levy | £152.00 |
| | VAT (20%) | £1,614.15 |
| | TOTAL DUE | £9,684.89 |

---

## 2. Field mapping: bill → database

### 2.1 One main record per bill (`data_library_records`)

Store **one** record per invoice for reporting and emissions. Primary metric = total consumption (kWh). Cost and other amounts can be stored in the same record as secondary info (see below).

| Bill field | Target column | Example / notes |
|------------|----------------|------------------|
| Period (January 2026) | `reporting_period_start`, `reporting_period_end` | 2026-01-01, 2026-01-31 |
| Total Consumption | `value_numeric` | 30340 |
| | `unit` | kWh |
| Display label | `name` | "Electricity Jan 2026" or "UrbanGrid – Jan 2026" |
| | `subject_category` | energy |
| | `source_type` | upload (or manual) |
| | `confidence` | measured |
| | `data_type` | tenant_electricity (or leave null) |
| Supplier + Invoice No | `value_text` | "Supplier: UrbanGrid Energy Ltd; Invoice: UGE-0126-LTHQ" (or split: supplier in value_text, invoice ref in documents) |
| Net Energy Cost / Total due | Optional: store in `value_text` as structured string, e.g. "NetEnergyCostGBP:7918.74;TotalDueGBP:9684.89;ClimateLevyGBP:152;VATGBP:1614.15" until a dedicated cost column exists | — |
| Property | `property_id` | Resolve "Lumen Technology HQ" / address to `properties.id` in app |

**Floor-level breakdown** (Ground 10,050 kWh, 3rd 10,420, 4th 9,870) can be stored in `value_text` or `allocation_notes` as JSON or readable text for now, e.g. `"Floor breakdown: Ground 10050 kWh, 3rd 10420 kWh, 4th 9870 kWh"`, or in a future `metadata` / `breakdown` column if added.

### 2.2 Document metadata (`documents`)

| Bill field | Use in app | Notes |
|------------|------------|--------|
| Invoice No | `file_name` or store in record | UGE-0126-LTHQ — good as reference in UI |
| Invoice Date | Can mirror `reporting_period_end` or store in record | 31 Jan 2026 |

The PDF itself is in Storage; `documents` has `storage_path`, `file_name`, `mime_type`, `file_size_bytes`. Optional: add a column like `external_id` (invoice number) later if needed.

### 2.3 Evidence

- Link the uploaded PDF to this record via `evidence_attachments` (tag e.g. `invoice`).
- No change to existing flow: upload → `documents` row → `evidence_attachments` (data_library_record_id, document_id, tag).

---

## 3. Example payload (one record, one bill)

Canonical shape for **one** `data_library_records` row created from the sample bill (e.g. after upload + manual entry or after extraction):

```json
{
  "name": "Electricity Jan 2026",
  "subject_category": "energy",
  "source_type": "upload",
  "data_type": "tenant_electricity",
  "reporting_period_start": "2026-01-01",
  "reporting_period_end": "2026-01-31",
  "value_numeric": 30340,
  "unit": "kWh",
  "confidence": "measured",
  "value_text": "Supplier: UrbanGrid Energy Ltd; Invoice: UGE-0126-LTHQ; NetEnergyCostGBP:7918.74; TotalDueGBP:9684.89",
  "property_id": "<resolved property uuid>",
  "account_id": "<account uuid>"
}
```

Optional: put floor breakdown in `allocation_notes` or `value_text`:

- `"allocation_notes": "Ground: 10050 kWh; 3rd: 10420 kWh; 4th: 9870 kWh"`
- or a small JSON in `value_text` if the app supports it.

---

## 4. Extraction hints (for OCR / parser / AI)

When implementing PDF or image extraction, look for:

| Target | Where on bill | Hints |
|--------|----------------|------|
| Period | Header "January 2026" or "SAMPLE INVOICE – Electricity - January 2026" | Parse month/year → set reporting_period_start = first day, reporting_period_end = last day of month |
| Total Consumption | Summary line "Total Consumption: 30,340 kWh" | Number before "kWh"; strip commas |
| Net Energy Cost | "Net Energy Cost: £7,918.74" | Number after "£"; strip commas |
| Total due | "TOTAL DUE: £9,684.89" | Same |
| Supplier | "UrbanGrid Energy Ltd" (under Invoice details) | Often near "Supplier" or top of details block |
| Invoice No | "UGE-0126-LTHQ" | Often labelled "Invoice No" or "Reference" |
| Invoice Date | "31 January 2026" | |
| Property / Billed To | "Lumen Technology HQ", "Lumen Technology (UK) Limited" | Use for display and to resolve property_id if address/name match |
| Floor table | Rows with Floor, Consumption (kWh), Net (£) | Optional: parse into breakdown for allocation_notes or future breakdown field |

---

## 5. Manual entry checklist (after upload)

When the user has uploaded this bill and wants to complete the record manually:

1. Open the record in the Data Library (Energy) → View / Edit.
2. Set **Reporting period:** 01 Jan 2026 – 31 Jan 2026.
3. Set **Consumption:** 30340, unit **kWh**.
4. Set **Name:** e.g. "Electricity Jan 2026".
5. Set **Confidence:** Measured.
6. Optionally set **value_text** (or equivalent UI): Supplier and invoice ref, and/or "Net cost £7,918.74; Total due £9,684.89".
7. Optionally add floor breakdown in notes if the UI has a notes field.
8. Ensure **property** is set (e.g. Lumen Technology HQ) so the record is scoped correctly.

This sample defines the target for one property; repeat the same shape for other bills and properties.

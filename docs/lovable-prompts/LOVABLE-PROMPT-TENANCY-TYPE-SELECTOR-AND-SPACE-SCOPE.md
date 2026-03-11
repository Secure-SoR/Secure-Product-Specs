# Lovable prompt: Tenancy type selector + mutually exclusive space scope (Data Centre)

**Use this when:** The Data Centre property space creation page already has (1) an upper tenancy type selector (Whole Building vs Partial Building) and (2) a lower space population form. You need to make the selector **functional**: persist to DB, and scope spaces so Whole and Partial are mutually exclusive. **Do not change any UI.**

**Backend:** Migration and schema are in place. See [add-tenancy-type-property-and-spaces.sql](database/migrations/add-tenancy-type-property-and-spaces.sql), [schema.md](database/schema.md) (§3.4 properties, §3.5 spaces).

---

## 1. Persist tenancy type selection to DB

- When the user selects **Whole Building** or **Partial Building**, save that selection **immediately** to the property record.
- **Field:** `properties.tenancy_type` — values `'whole'` (Whole Building) or `'partial'` (Partial Building). Map UI labels to these values.
- On page load, **read** `property.tenancy_type` from the DB and **pre-select** the correct option in the existing selector (no new UI).
- **Run the migration** in Supabase SQL Editor if not already run: [add-tenancy-type-property-and-spaces.sql](database/migrations/add-tenancy-type-property-and-spaces.sql).

---

## 2. Mutually exclusive space population

- Every space **created or populated** on this page must be tagged with the **active** `tenancy_type` at time of creation: set `spaces.tenancy_type = property.tenancy_type` when inserting.
- **View scope:** When showing spaces, only list spaces where `spaces.tenancy_type` equals the **currently selected** `property.tenancy_type`. Spaces under `whole` must not appear or count when viewing `partial`, and vice versa.
- When the user **switches** tenancy type, **do not delete** existing spaces — only change the **view** and any **new** additions to the newly selected type. Existing spaces keep their stored `tenancy_type`.
- A space belongs to **one** type only; the same space cannot belong to both `whole` and `partial`.

---

## 3. Scope enforcement

- **All** space-related **queries** (list, counts, summaries, tile counts) on this page must **filter** by the currently selected `tenancy_type`: `WHERE property_id = :id AND tenancy_type = :currentTenancyType`. Use `currentTenancyType` from the property record (or the selector state after it’s saved).
- On **save**, **update**, or **delete** of a space: **verify** that `space.tenancy_type` matches the current selection before executing. If there is a mismatch (e.g. stale UI or race), **reject or warn** and do not apply the change.

---

## 4. Constraints

- **Do not modify** any UI components, layout, or styling — only wire behaviour to the existing selector and form.
- **Use the existing** space creation logic; **extend** it (e.g. pass `tenancy_type` into create, filter in queries), do not replace it.
- If `tenancy_type` has **never been set** (null), treat the selector as unselected and **block space creation** until the user chooses Whole or Partial and it is saved.
- **Reuse** existing Supabase client usage and routes; no new backend routes required — only schema columns and client-side filtering/validation.

---

## Prompt to paste into Lovable

```
Data Centre property space page: make the tenancy type selector (Whole Building vs Partial Building) functional. Do not change any UI.

1) Persist: On selection, save immediately to properties.tenancy_type ('whole' or 'partial'). On load, read property.tenancy_type and pre-select the option. Migration: docs/database/migrations/add-tenancy-type-property-and-spaces.sql (run in Supabase if needed).

2) Spaces: When creating a space, set spaces.tenancy_type = current property.tenancy_type. All space lists, counts, and summaries on this page must filter by the current tenancy_type (WHERE tenancy_type = current). Spaces under whole must not appear when viewing partial, and vice versa. Switching type only changes the view and new additions; do not delete existing spaces.

3) Enforcement: Before any space save/update/delete, verify the space's tenancy_type matches the current selection; reject or warn if mismatch.

4) If property.tenancy_type is null, block space creation until the user selects Whole or Partial and it is saved. Extend existing space creation logic; do not replace it. Reuse existing Supabase usage; no new routes.
```

---

## Output checklist (after implementing)

- **Schema:** [add-tenancy-type-property-and-spaces.sql](database/migrations/add-tenancy-type-property-and-spaces.sql) adds `properties.tenancy_type` and `spaces.tenancy_type`; index `idx_spaces_property_id_tenancy_type` on `(property_id, tenancy_type)`.
- **Routes:** No new backend routes. Frontend continues to use existing Supabase tables (`properties`, `spaces`) with the new columns.
- **Extended:** Property update (PATCH) to set `tenancy_type` on selector change; space create with `tenancy_type`; all space queries/counts filtered by `tenancy_type`; space update/delete guarded by `tenancy_type` match.
- **Untouched:** UI layout and styling; existing space form fields and creation flow (only extended with `tenancy_type` and filters).

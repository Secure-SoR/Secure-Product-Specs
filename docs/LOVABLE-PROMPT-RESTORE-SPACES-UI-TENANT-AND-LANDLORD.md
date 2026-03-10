# Lovable prompt: Restore Spaces UI — My Tenant Spaces + My Landlord / Base Building Spaces

**Use this when:** After applying the Data Centre space template fix, the Spaces screen was changed and (1) the **"My Landlord / Base Building Spaces"** subpage or section next to **"My Tenant Spaces"** disappeared; (2) you want the previous UI back with both sections visible; (3) base building spaces may be missing on other (non–data centre) properties too.

**Goal:** Restore the previous structure: two distinct sections/tabs for spaces — **My Tenant Spaces** and **My Landlord / Base Building Spaces** — for **all properties** (not only data centre). Both sections must show their spaces and work as before.

---

## Prompt to paste into Lovable

```
Restore the Spaces screen to the previous structure. The spaces area must have TWO separate sections (or tabs, or subpages) as before:

1. **My Tenant Spaces** — Shows all spaces where space_class === 'tenant' for the current property. Each space should be visible (name, type, etc.) with the ability to edit or delete. This section must exist and be visible for every property (data centre and non–data centre).

2. **My Landlord / Base Building Spaces** — Shows all spaces where space_class === 'base_building' for the current property. Each space should be visible (name, type, etc.) with the ability to edit or delete. This section must exist and be visible for every property (data centre and non–data centre).

Do not show only one combined list. Do not remove the Landlord / Base Building section. Both "My Tenant Spaces" and "My Landlord / Base Building Spaces" must appear (e.g. as two tabs, two cards, or two subsections) so the user can switch between them or see both. The same behaviour must apply for all asset types (Office, Retail, Data centre, etc.): tenant spaces in one section, base building spaces in the other. If base building spaces were removed or hidden on other properties, restore them so that for any property, spaces with space_class === 'base_building' are listed under "My Landlord / Base Building Spaces".
```

---

## After applying

- Check a **data centre** property: you should see both "My Tenant Spaces" and "My Landlord / Base Building Spaces".
- Check an **Office or Retail** property: you should also see both sections; base building spaces (if any) must appear under "My Landlord / Base Building Spaces".
- If the app crashes or the UI is still wrong, try reverting the recent Lovable changes (e.g. undo or restore from git) and then paste this prompt again with the single goal: "Restore two sections for spaces: My Tenant Spaces and My Landlord / Base Building Spaces, for all properties."

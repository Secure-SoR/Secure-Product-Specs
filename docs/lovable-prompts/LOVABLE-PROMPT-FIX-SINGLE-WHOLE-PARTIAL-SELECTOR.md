# Lovable prompt: One place only for Whole vs Partial building (fix duplicate)

**Use this when:** The spaces screen shows **two sections** or two places where the user can choose "partial or whole building tenant", which is confusing. There should be **only one** tenant footprint selector (Whole building | Partial building), not two.

**Goal:** Remove the duplicate. Keep a single, clear place to choose and save Whole building vs Partial building. The spaces list (My Tenant Spaces + My Landlord / Base Building Spaces) stays as is; only the whole/partial control is simplified.

---

## Prompt to paste into Lovable

```
On the Spaces screen, there must be only ONE place to choose "Whole building" or "Partial building" (tenant footprint). Currently there are two sections or two controls for this, which is confusing.

- **Remove the duplicate:** Keep a single selector (e.g. "Tenant footprint: Whole building | Partial building" with one Save button) at the top of the spaces area. Delete or merge any second section that also asks for whole vs partial. The user should see this choice once, save it once, and then see "My Tenant Spaces" and "My Landlord / Base Building Spaces" below (or in tabs) without being asked again in another place.
- **Result:** One tenant-footprint choice (Whole | Partial) with one Save. Then the two space sections (My Tenant Spaces and My Landlord / Base Building Spaces) that list the actual spaces. Do not repeat the whole/partial question in a second section or under each tab.
```

---

## Backend reference

- **properties.occupancy_scope** — text, `whole_building` | `partial_building`. Stored once per property; the single selector saves to this field.

---

## After applying

- Spaces screen has **one** "Tenant footprint" (Whole building | Partial building) with one Save at the top.
- Below (or in tabs): **My Tenant Spaces** and **My Landlord / Base Building Spaces** only — no second whole/partial selector.
- If you later need to re-add the DC template behaviour (e.g. gate template on occupancy_scope), use [LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md](LOVABLE-PROMPT-FIX-DC-SPACE-TEMPLATE-SYNC.md) but keep the single whole/partial control from this prompt.

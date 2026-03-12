# Lovable prompt: Data Library access IDs — align with backend

**Backend reference:** [data-library-specifications.md](../specs/data-library-specifications.md), [data-library-implementation-context.md](../data-library-implementation-context.md), [LOVABLE-BACKEND-ALIGNMENT.md](../LOVABLE-BACKEND-ALIGNMENT.md) §3.

**Issue:** GovernanceDataPage, TargetsDataPage, and ESGDataPage all use `getCategoryAccessById("esg_governance")`. The backend Taxonomy v3 defines **three separate** access IDs for these sections: **governance**, **targets**, **esg**. Using one ID for all three means access control cannot be scoped per section (e.g. a user might get access to "Governance" only but not "Targets").

**Goal:** Use the correct access ID on each page so that future per-tile access control (if you add it) matches the backend. Data fetches should also filter by the correct `subject_category` for each page (`governance`, `targets`, `esg`).

---

## Prompt to paste into Lovable

```
Data Library access IDs — align with backend Taxonomy v3

Current state:
- GovernanceDataPage, TargetsDataPage, and ESGDataPage all call getCategoryAccessById("esg_governance").
- The backend spec defines three distinct access IDs for these sections: "governance", "targets", "esg".

Task:
1. Change GovernanceDataPage to use getCategoryAccessById("governance") (not "esg_governance").
2. Change TargetsDataPage to use getCategoryAccessById("targets") (not "esg_governance").
3. Change ESGDataPage to use getCategoryAccessById("esg") (not "esg_governance").

Ensure the hook useDataLibraryAccess (or equivalent) supports these three IDs: "governance", "targets", "esg". If the type or config map only has "esg_governance", add "governance", "targets", and "esg" so that each page can resolve access correctly.

When loading records for each page, filter by subject_category to match the page:
- Governance page: subject_category = 'governance'
- Targets page: subject_category = 'targets'
- ESG Disclosures page: subject_category = 'esg'

Do not change routes or page structure — only the access ID passed to getCategoryAccessById and the subject_category used for data queries.
```

---

## After applying

- Backend and Lovable will agree: Governance → `governance`, Targets → `targets`, ESG Disclosures → `esg`.
- If you later add role-based visibility (e.g. hide "Targets" for some users), you can key off these IDs.
- Update [LOVABLE-BACKEND-ALIGNMENT.md](../LOVABLE-BACKEND-ALIGNMENT.md) §3 to mark this as done.

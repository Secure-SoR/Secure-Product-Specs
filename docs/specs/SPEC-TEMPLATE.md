# Feature-level backend spec template

Every feature-level specification in `docs/specs/` must include the following 10 sections. Use **N/A** or **See §X** where a section does not apply. This template is the source of truth; the Cursor rule enforces it when creating or editing spec files.

**Platform context:** Features may consume the **foundation** (Data Library, Property section, Account settings / user profile, Evidence Store, Boundary Engine) and optionally other modules. See [docs/modules/README.md](../modules/README.md) for the foundation and module list.

---

1. **Feature Overview** — Purpose of the feature, who uses it, and what business problem it solves.

2. **Functional Requirements** — Step-by-step description of what the feature does, including all user actions and expected system responses.

3. **API Endpoints / Data Surface** — For Secure (Supabase-backed): tables, RPCs, Edge Functions, and Storage buckets used; any external REST endpoints (e.g. AI agents) with method, route, request payload, response structure, and status codes.

4. **Database Schema** — Tables/collections involved, fields with data types and constraints, indexes, and relationships to other entities. Link to `docs/database/schema.md` and migrations where applicable.

5. **Business Logic & Validation Rules** — All conditions, calculations, restrictions, and edge cases the backend must enforce.

6. **Authentication & Authorization** — Who can access this feature, role-based permissions, and any token or session requirements (RLS, module flags, account scoping).

7. **State & Workflow** — Status transitions, trigger events, and sequence of operations if the feature has multi-step or stateful behaviour.

8. **Error Handling** — All failure scenarios, error codes, error messages, and fallback behaviour.

9. **External Integrations & Events** — Third-party services, internal service dependencies, webhooks, queues, or background jobs involved in this feature.

10. **Non-Functional Requirements** — Performance expectations, rate limits, data retention rules, logging needs, and any security considerations specific to this feature.

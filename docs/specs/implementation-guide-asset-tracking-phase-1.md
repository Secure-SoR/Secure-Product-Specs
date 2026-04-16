# Asset Tracking — Phase 1 implementation guide

This guide turns [secure-asset-tracking-spec-v2.0.md](secure-asset-tracking-spec-v2.0.md) Phase 1 into concrete steps. Complete [Phase 0](secure-asset-tracking-spec-v2.0.md) (validation gate) on staging before applying migrations to production.

## What Phase 1 delivers

- `properties.at_enabled` flag.
- All Asset Tracking tables with RLS aligned to `account_memberships`.
- Partial unique indexes for `at_asset_types` (account vs property scope).
- `at_assets.tag_id` ↔ `at_asset_tags` FK (split migration to resolve circular dependency).
- `at_alerts` → `audit_events` trigger (`at_alerts_audit_to_audit_events`).
- Storage policies for bucket `at-floor-plans` (after you create the bucket).
- Optional seed for mining POC asset types.

Logical schema reference: [schema.md](../database/schema.md) §3.15. Runnable aggregate: [supabase-schema.sql](../database/supabase-schema.sql) (includes AT for greenfield installs).

## Run order (Supabase SQL Editor)

Run each file once, in order:

| # | File |
|---|------|
| 1 | [add-at-enabled-to-properties.sql](../database/migrations/add-at-enabled-to-properties.sql) |
| 2 | [create-at-floors.sql](../database/migrations/create-at-floors.sql) |
| 3 | [create-at-zones.sql](../database/migrations/create-at-zones.sql) |
| 4 | [create-at-asset-types.sql](../database/migrations/create-at-asset-types.sql) |
| 5 | [create-at-assets.sql](../database/migrations/create-at-assets.sql) |
| 6 | [create-at-asset-tags.sql](../database/migrations/create-at-asset-tags.sql) |
| 7 | [add-at-assets-tag-id-fk.sql](../database/migrations/add-at-assets-tag-id-fk.sql) |
| 8 | [create-at-gateways.sql](../database/migrations/create-at-gateways.sql) |
| 9 | [create-at-position-events.sql](../database/migrations/create-at-position-events.sql) |
| 10 | [create-at-alerts.sql](../database/migrations/create-at-alerts.sql) |
| 11 | [create-at-device-state.sql](../database/migrations/create-at-device-state.sql) |
| 12 | [create-at-dali-commands.sql](../database/migrations/create-at-dali-commands.sql) |
| 13 | [create-at-facility-settings.sql](../database/migrations/create-at-facility-settings.sql) |
| 14 | [extend-systems-type-dalilight.sql](../database/migrations/extend-systems-type-dalilight.sql) (no-op unless you maintain a `system_type` CHECK) |

**Storage**

1. Dashboard → Storage → New bucket → `at-floor-plans` (private).
2. Run [add-at-floor-plans-storage-policies.sql](../database/migrations/add-at-floor-plans-storage-policies.sql).

**Seed (optional)**

1. Edit `v_account` in [seed-at-asset-types-mining.sql](../database/migrations/seed-at-asset-types-mining.sql).
2. Run once per pilot account.

## After SQL

- **Realtime (optional for Phase 3 UI):** add `at_position_events` and `at_alerts` to the `supabase_realtime` publication if you want live subscriptions.
- **Lovable:** use routes in spec §7.1; prompts in [asset-tracker-to-secure-mapping.md](../asset-tracker-to-secure-mapping.md) and spec Appendix C.
- **`at_access` / AT roles (spec Q9):** not in Phase 1 migrations; decide before Account Settings work (Phase 2).

## Implementation note: `at_zones` and `spaces`

The v2.0 spec table labels the optional FK as `spaces_id`. Migrations and [schema.md](../database/schema.md) use **`space_id`** (FK → `spaces.id`).

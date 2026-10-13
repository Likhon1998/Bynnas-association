# Database Design

## Implemented

### `users`

| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| name | VARCHAR | |
| email | VARCHAR unique | Login identifier |
| role | VARCHAR(32) | `super_admin`, `admin`, `accountant`, `member` |
| member_id | VARCHAR(32) nullable unique | Required for members; null for pure staff accounts |
| is_active | BOOLEAN | Soft account disable |
| deactivated_at | TIMESTAMP nullable | |
| password | VARCHAR | Hashed |
| email_verified_at | TIMESTAMP nullable | |
| remember_token | VARCHAR nullable | Web sessions |
| timestamps | | |

### `personal_access_tokens` (Sanctum)

Stores hashed API tokens for mobile clients.

### `member_profiles`

| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | BIGINT unique FK → users | One profile per member user |
| phone | VARCHAR(32) nullable | Indexed for search |
| address | VARCHAR(500) nullable | |
| notes | TEXT nullable | Staff-only internal notes |
| joined_on | DATE nullable | |
| timestamps | | |

Members are `users` with `role = member` plus an optional `member_profiles` row. Deactivation sets `users.is_active = false` and never hard-deletes the user (financial history must remain).

### Financial tables

Money columns use `DECIMAL(15,2)`. Application math uses BCMath decimal strings. See [FINANCE.md](./FINANCE.md) for invariants.

| Table | Purpose |
|---|---|
| `contribution_plans` | Configurable plans with `default_amount` |
| `member_contribution_assignments` | Per-member amount overrides (effective dated) |
| `due_periods` | Calendar month buckets (`year` + `month`) |
| `member_dues` | Obligations (member + period + plan) |
| `payments` | Money received; unique `receipt_number` + `idempotency_key` |
| `payment_allocations` | Payment → due applications (`is_reversed` for reversals) |
| `financial_audit_logs` | Append-only audit trail (no `updated_at`) |

Hard deletes of financial rows are blocked in application models. Use void/reversal.

### Notices & notifications

| Table | Purpose |
|---|---|
| `notices` | Draft/published/archived announcements + audience |
| `notice_targets` | Selected member recipients |
| `user_notifications` | In-app inbox; unique (`user_id`, `dedupe_key`) |
| `device_tokens` | FCM tokens; soft-invalidated via `invalidated_at` |

Details: [NOTICES.md](./NOTICES.md).


### Laravel defaults

`sessions`, `password_reset_tokens`, `cache`, `jobs` tables from framework scaffolding.

## Indexing

- Unique: `users.member_id`, `users.email`, `contribution_plans.code`, `due_periods(year,month)`, `member_dues(user_id,due_period_id,contribution_plan_id)`, `payments.receipt_number`, `payments.idempotency_key`
- Index: `member_dues(user_id, status)`, `payments(user_id, received_at)`, `financial_audit_logs(entity_type, entity_id)`

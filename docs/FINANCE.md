# Contribution & Payment Rules

This document defines the financial schema and invariants for Bynnas Association.  
Admin Blade + Flutter member finance UI (Stage 8) reuse these services; **payment gateways remain out of scope.**

## Money representation

- Database money columns use `DECIMAL(15,2)`.
- Application math uses decimal strings with BCMath (`bcadd`, `bcsub`, `bccomp`).
- Floating-point types (`float`, `double`) are forbidden for money.
- API money fields are decimal strings (e.g. `"500.00"`).
- Single currency for now (`BDT`), stored explicitly for future multi-currency readiness.

## Core concepts

| Concept | Meaning |
|---|---|
| Contribution plan | Named configurable plan with a default monthly amount |
| Member assignment | Optional per-member amount override for a plan |
| Due period | Calendar month bucket (year + month) |
| Member due | Obligation for a member for one plan in one period |
| Payment | Money received from a member (separate from dues) |
| Allocation | Application of part/all of a payment to one or more dues |
| Receipt number | Unique human-readable identifier issued with each posted payment |
| Reversal | Audited void of a posted payment; restores due balances |
| Idempotency key | Client-supplied key preventing duplicate submissions |

## Schema

### `contribution_plans`
- `id`, `name`, `code` (unique), `description` nullable
- `default_amount` DECIMAL(15,2)
- `currency` CHAR(3) default `BDT`
- `is_active` boolean
- timestamps

### `member_contribution_assignments`
- `id`, `user_id` → member user
- `contribution_plan_id`
- `amount` DECIMAL(15,2) nullable — if null, plan default applies
- `effective_from` date, `effective_to` date nullable
- `is_active` boolean
- unique(`user_id`, `contribution_plan_id`, `effective_from`)

### `due_periods`
- `id`, `year`, `month` (1–12), `label` (e.g. `2026-03`)
- `starts_on`, `ends_on`
- unique(`year`, `month`)

### `member_dues`
- `id`, `user_id`, `due_period_id`, `contribution_plan_id`
- `amount_due` DECIMAL(15,2)
- `amount_allocated` DECIMAL(15,2) default `0.00` (maintained in transactions)
- `status`: `pending`, `partial`, `paid`, `voided`
- `currency` CHAR(3)
- `idempotency_key` nullable unique
- `voided_at`, `voided_by`, `void_reason` nullable
- timestamps
- unique active obligation: unique(`user_id`, `due_period_id`, `contribution_plan_id`)

### `payments`
- `id`, `user_id` (paying member)
- `amount` DECIMAL(15,2)
- `currency` CHAR(3)
- `method`: `cash`, `bank_transfer`, `cheque`, `other`
- `received_at` datetime
- `recorded_by` → staff user
- `status`: `posted`, `reversed`
- `receipt_number` unique
- `idempotency_key` unique
- `notes` nullable
- `reversed_at`, `reversed_by`, `reversal_reason` nullable
- timestamps

### `payment_allocations`
- `id`, `payment_id`, `member_due_id`
- `amount` DECIMAL(15,2)
- `is_reversed` boolean default false
- timestamps
- index(`payment_id`), index(`member_due_id`)

### `financial_audit_logs` (append-only)
- `id`, `actor_id` nullable
- `action` string
- `entity_type`, `entity_id`
- `before` JSON nullable, `after` JSON nullable
- `meta` JSON nullable
- `created_at` (no `updated_at`)

## Financial rules (invariants)

1. **Dues ≠ payments.** Obligations and receipts of money are separate tables.
2. **No hardcoded monthly amount.** Amounts come from plans/assignments at generation time and are stored on the due row.
3. **Partial payments allowed.** A payment may allocate less than a due’s remaining balance.
4. **Allocation ceiling.** For a payment, sum(allocations) ≤ payment.amount.
5. **Due ceiling.** For a due, amount_allocated ≤ amount_due (among non-reversed allocations).
6. **Outstanding balance** (due) = `amount_due - amount_allocated` (for non-voided dues).
7. **Member outstanding** = sum of outstanding across that member’s non-voided dues.
8. **No silent deletes.** Application code must not hard-delete dues, payments, allocations, or audit logs.
9. **No unauthorized edits.** Posted payment amounts/methods cannot be edited in place; use reversal.
10. **Reversal is audited.** Reversing a payment marks it `reversed`, marks allocations `is_reversed`, decreases due `amount_allocated`, updates due status, and writes audit log rows.
11. **Duplicate protection.** Creating a payment with an existing `idempotency_key` returns the original payment (no second charge/allocation). Due generation uses idempotency keys per member/period/plan.
12. **Transactions.** Payment posting, allocation, due generation, and reversal run inside DB transactions with row locks where needed.
13. **Receipt numbers** are unique, generated server-side (`RCPT-YYYYMMDD-XXXXXX`), never reused.
14. **Authorization**
    - Super Admin / Admin: manage plans, assignments, generate dues, record/reverse payments.
    - Accountant: generate dues, record/reverse payments, view all financial data; cannot manage plans unless also admin (Accountant may manage plans for ops speed — **allowed**: create/update plans + record payments).
    - Member: view own dues, payments, balances only.
15. **Deactivated members** keep financial history; new payments may be blocked for inactive members.

## Status transitions

### Member due
- `pending` → `partial` when 0 < allocated < due
- `pending`/`partial` → `paid` when allocated == due
- `*` → `voided` only via explicit void (rare; preferred path is payment reversal)

### Payment
- created as `posted`
- `posted` → `reversed` via audited reversal
- `reversed` cannot be reversed again

## Example

1. Plan “Standard Monthly” default `500.00`.
2. Member A assigned override `300.00`.
3. Generate March 2026 due for A → due `300.00`, status `pending`.
4. Post payment `200.00` with allocation `200.00` to that due → due outstanding `100.00`, status `partial`, receipt issued.
5. Post payment `100.00` allocated to same due → due paid.
6. Reverse second payment → due returns to outstanding `100.00`, status `partial`, audit logged.

## Out of scope

- Online payment gateways
- Multi-currency FX
- Interest/penalties
- Contribution plan / dues-generate admin Blade (API exists; optional later)
- Automated reminder campaigns beyond in-app notification hooks

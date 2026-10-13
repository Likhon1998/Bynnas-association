# Requirements

## Product goals

Build an Association Management Application that supports approximately 3,000 members with:

1. A Flutter Android/iOS member application.
2. A Laravel Blade + Tailwind web admin panel.
3. One shared Laravel REST API and MySQL/MariaDB database.

## Functional requirements

### Identity and membership

- Every member has a unique `member_id`.
- Users authenticate with email/password (mobile via Sanctum token; admin via session).
- Four roles: Super Admin, Admin, Accountant, Member.
- Members may access only their own private profile and financial records.
- Staff permissions are enforced on the backend (policies + middleware), never only in the client.

### Financial management

- Monthly dues (obligations) and payments (receipts of money) are modeled separately.
- System must support:
  - Partial payments
  - Payment allocations across one or more dues/charges
  - Receipts
  - Outstanding balances
- Contribution amounts are configurable and may differ by member/plan/period.
- Do **not** hardcode a single monthly amount for all members.
- Financial records must not be silently deleted (use soft-delete / voiding / reversal with audit).
- Every financial mutation produces an audit trail (who, what, when, before/after).

### Money handling

- Store monetary values as fixed-precision decimals (`DECIMAL(15,2)`) or integer minor units.
- Never use floating-point types for money in DB, API contracts, or business logic.
- Currency is assumed local/single-currency initially; schema should allow explicit currency code later if needed.

### Privacy and security

- Protect credentials with hashed passwords (bcrypt/argon via Laravel).
- Store mobile auth tokens in Flutter Secure Storage.
- Do not commit secrets, `.env` files, or production credentials.
- Personal information is role-scoped and logged only as necessary.
- API authorization is authoritative; mobile UI checks are UX only.

## Non-functional requirements

- Scale target: ~3,000 members with concurrent admin/member usage.
- API versioned under `/api/v1`.
- Feature tests for critical auth and (later) financial invariants.
- Git-based version control; no destructive production database operations during development.

## Out of scope (current phase)

- Blade/Flutter finance UI (plans/dues/payments screens)
- Bulk member import
- Production-verified FCM delivery (interfaces + token APIs ready; needs credentials + worker)
- Multi-currency FX
- Payment gateway integrations

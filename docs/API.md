# API Conventions

## Base URL

```text
/api/v1
```

All mobile endpoints are versioned. Breaking changes require `/api/v2`.

## Auth

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/health` | GET | Public | Service health check |
| `/api/v1/auth/login` | POST | Public | Issue Sanctum token (rate limited) |
| `/api/v1/auth/forgot-password` | POST | Public | Email password reset link |
| `/api/v1/auth/reset-password` | POST | Public | Reset password and revoke all tokens |
| `/api/v1/auth/me` | GET | Bearer + active | Current user profile |
| `/api/v1/auth/logout` | POST | Bearer + active | Revoke current token |
| `/api/v1/auth/logout-all` | POST | Bearer + active | Revoke all tokens for the user |
| `/api/v1/staff/ping` | GET | Bearer + active + staff role | Authorization probe |

### Login request

```json
{
  "email": "member@example.com",
  "password": "password",
  "device_name": "pixel-8"
}
```

### Login response

```json
{
  "token": "...",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "Example Member",
    "email": "member@example.com",
    "role": "member",
    "member_id": "BYN-2026-0001",
    "is_active": true,
    "email_verified_at": null,
    "created_at": "2026-10-13T00:00:00+00:00"
  }
}
```

Send authenticated requests with:

```http
Authorization: Bearer {token}
Accept: application/json
```

### Account status

- Inactive users cannot log in.
- If a user is deactivated while a token is still valid, authenticated API routes return `403` and revoke the current token.

### Web admin auth

- Session-based (Laravel Breeze).
- Only staff roles (`super_admin`, `admin`, `accountant`) may log in to the web panel.
- Members are directed to the mobile app.
- Public self-registration is disabled.

## Conventions

- Controllers live under `App\Http\Controllers\Api\V1`.
- Validate with Form Requests under `App\Http\Requests\Api\V1`.
- Transform with API Resources under `App\Http\Resources\Api\V1`.
- Money fields in JSON are decimal strings (e.g. `"500.00"`), never binary floats.
- Errors:
  - `401` unauthenticated
  - `403` forbidden / inactive / wrong role
  - `422` validation
  - `404` missing resource
- Collection/resource wrapping follows Laravel defaults (`data` for standalone resources).
- Role-restricted routes use middleware: `role:admin,super_admin` (example).
- Active-account enforcement uses middleware: `active`.

## Members

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/members` | GET | Staff | Search/paginate members (`search`, `status`, `per_page`) |
| `/api/v1/members` | POST | Admin / Super Admin | Create member + unique `member_id` |
| `/api/v1/members/me` | GET | Member | Own member profile |
| `/api/v1/members/{id}` | GET | Staff or self | Member detail |
| `/api/v1/members/{id}` | PUT/PATCH | Admin/Super Admin or self (limited) | Update member/profile |
| `/api/v1/members/{id}/deactivate` | POST | Admin / Super Admin | Soft-deactivate (tokens revoked, row kept) |
| `/api/v1/members/{id}/reactivate` | POST | Admin / Super Admin | Restore access |

Hard delete is intentionally unsupported.

## Finance

Money fields are decimal strings. Full rules: [FINANCE.md](./FINANCE.md). No payment gateways in this phase.

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/contribution-plans` | GET | Staff | List plans (`active`, `per_page`) |
| `/api/v1/contribution-plans` | POST | Staff | Create plan |
| `/api/v1/contribution-plans/{id}` | GET | Staff | Plan detail |
| `/api/v1/contribution-plans/{id}` | PUT/PATCH | Staff | Update plan (not code) |
| `/api/v1/contribution-assignments` | POST | Staff | Assign plan/amount override to member |
| `/api/v1/dues` | GET | Staff (all) / Member (own) | List dues |
| `/api/v1/dues/generate` | POST | Staff | Generate monthly dues (idempotent) |
| `/api/v1/dues/{id}/void` | POST | Admin / Super Admin | Void unpaid due |
| `/api/v1/balances/me` | GET | Member | Own outstanding balance |
| `/api/v1/balances/{member}` | GET | Staff or self | Member outstanding balance |
| `/api/v1/payments` | GET | Staff (all) / Member (own) | List payments |
| `/api/v1/payments` | POST | Staff | Record payment + allocations (`idempotency_key` required) |
| `/api/v1/payments/{id}` | GET | Staff or owning member | Payment detail |
| `/api/v1/payments/{id}/reverse` | POST | Staff | Audited reversal (`reason` required) |

Payment create is idempotent: replaying the same `idempotency_key` returns the original payment (`200`, `idempotent_replay: true`) without double allocation. Posted payments have no update endpoint — correct via reversal.

### Example: record partial payment

```json
{
  "user_id": 12,
  "amount": "200.00",
  "method": "cash",
  "idempotency_key": "client-uuid-or-hash",
  "allocations": [
    { "member_due_id": 55, "amount": "200.00" }
  ]
}
```

## Dashboard & reports

All financial totals are computed by authorized backend queries (`ReportService`). Clients must display returned totals and must not recompute money aggregates.

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/dashboard` | GET | Staff or Member | Role-specific summary (`from`, `to` date filters) |
| `/api/v1/reports/member-wise` | GET | Staff | Paginated member rows + **full-filter** `summary` |
| `/api/v1/reports/month-wise` | GET | Staff | Paginated month rows + **full-filter** `summary` |
| `/api/v1/reports/member-wise/pdf` | GET | Staff | PDF export |
| `/api/v1/reports/month-wise/pdf` | GET | Staff | PDF export |

Dashboard fields: `active_members`, `expected_dues`, `actual_collections`, `allocated_to_dues`, `outstanding`, `payment_status`.  
Members receive a self-scoped dashboard only. Staff web panel mirrors these reports at `/dashboard`, `/reports/member-wise`, `/reports/month-wise` (print via `?print=1`).

## Notices & notifications

See [NOTICES.md](./NOTICES.md).

| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `/api/v1/notices` | GET | Staff (all) / Member (intended) | List notices |
| `/api/v1/notices` | POST | Admin / Super Admin | Create draft |
| `/api/v1/notices/{id}` | GET | Staff or intended member | Notice detail |
| `/api/v1/notices/{id}` | PUT/PATCH | Admin / Super Admin | Update draft |
| `/api/v1/notices/{id}/preview` | POST | Admin / Super Admin | Recipient count preview |
| `/api/v1/notices/{id}/publish` | POST | Admin / Super Admin | Publish + queue chunked delivery |
| `/api/v1/notices/{id}/archive` | POST | Admin / Super Admin | Archive |
| `/api/v1/notifications` | GET | Auth | Inbox (paginated) |
| `/api/v1/notifications/unread-count` | GET | Auth | Unread badge count |
| `/api/v1/notifications/{id}/read` | POST | Owner | Mark one read |
| `/api/v1/notifications/read-all` | POST | Auth | Mark all read |
| `/api/v1/device-tokens` | POST | Auth | Register FCM token |
| `/api/v1/device-tokens` | DELETE | Auth | Invalidate token |

# Flutter ↔ Laravel integration tests

These tests call the **real HTTP API** (Sanctum login, token header, JSON envelopes). They use an isolated SQLite file database — never production.

## What is covered

1. Valid login + token storage  
2. Invalid credentials error message  
3. Logout clears token  
4. Member profile (`/members/me`)  
5. Notices list + detail  
6. Notifications list + unread/read  
7. Dues history + outstanding balance + payments  
8. Invalid token → 401  
9. Network failure mapping  
10. Deliberate 500 fault endpoint (when enabled)  
11. Member A cannot read member B profile/balance  

## Setup

```powershell
# From repo root
copy backend\.env.integration.example backend\.env.integration
# Optionally edit credentials in backend\.env.integration (gitignored)

.\scripts\run-mobile-integration.ps1
```

The script:

1. Writes an **absolute** `DB_DATABASE` into `.env.integration` (required because `artisan serve` resolves relative SQLite paths from `public/`)
2. Migrates/seeds `backend/database/integration.sqlite`
3. Serves Laravel on `127.0.0.1:8765` with `APP_ENV=integration` and `ENABLE_INTEGRATION_FAULTS=true`
4. Probes login against the live API before Flutter runs
5. Runs `flutter test test/integration` with `REQUIRE_INTEGRATION_API=true`

### API base URL (devices)

| Runtime | Default / recommendation |
|---|---|
| Flutter unit integration tests (host) | `--dart-define=API_BASE_URL=http://127.0.0.1:8765/api/v1` |
| Android emulator app | `http://10.0.2.2:8765/api/v1` (built into `AppConfig`) |
| iOS simulator | `http://127.0.0.1:8765/api/v1` |
| Physical device | Pass your machine LAN IP via `API_BASE_URL` — do not hardcode |

## Credentials

Defaults (safe for local/CI fixtures only):

- `integration.member@bynnas.test` / `password`
- `integration.other@bynnas.test` / `password`

Override via `backend/.env.integration` and matching `--dart-define` values. Do not commit secrets.

## Soft skip vs required

- Without the server: tests print `SKIP` and return (local convenience).
- With `REQUIRE_INTEGRATION_API=1` or dart-define `true`: suite **fails** if the API is down (CI/script mode).

# Required Packages

## Backend (Laravel)

| Package | Why needed |
|---|---|
| `laravel/framework` | Application foundation, ORM, validation, queues, mail |
| `laravel/sanctum` | Token authentication for Flutter mobile clients |
| `laravel/breeze` | Blade + Tailwind admin auth scaffolding (login/register/password reset) |
| `laravel/tinker` | Interactive debugging in local/dev |
| `phpunit/phpunit` | Feature/unit tests for API and domain rules |
| `barryvdh/laravel-dompdf` | Server-side PDF export for member/month reports |

### Why Sanctum (not Passport/JWT)

Sanctum is first-party, lightweight, and fits a single Laravel backend serving our own Flutter app. Passport/OAuth is heavier than needed for this use case.

### Why Breeze Blade

Admin panel requirement is Blade + Tailwind. Breeze provides secure session auth and Tailwind Vite setup without implementing auth from scratch.

## Mobile (Flutter)

| Package | Why needed |
|---|---|
| `flutter_riverpod` | Predictable state management across features |
| `dio` | HTTP client with interceptors (auth header, error mapping) |
| `flutter_secure_storage` | OS-backed storage for Sanctum tokens (not SharedPreferences) |
| `go_router` | Declarative navigation / deep-link ready routing |
| `intl` | Locale-aware date/number formatting for dues and receipts |
| `flutter_lints` | Consistent static analysis |
| `mockito` + `build_runner` | Unit/widget test doubles for API/storage layers |

## Intentionally deferred packages

| Package | When to add |
|---|---|
| Excel import/export | Bulk member/dues import |
| Firebase Flutter SDK | Wire real FCM after credentials + HTTP v1 sender are production-ready |
| Local DB/cache (e.g. Drift/Hive) | Offline member statements |

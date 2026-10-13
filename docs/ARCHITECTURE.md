# Architecture

## High-level design

```text
┌────────────────────┐      Sanctum token       ┌──────────────────────────┐
│  Flutter App       │ ───────────────────────► │   Laravel API            │
│  Members + Staff   │                          │   /api/v1/*              │
│  (Riverpod/Dio)    │                          │   Domain + policies      │
└────────────────────┘                          └────────────┬─────────────┘
                                                             │
                                                             ▼
                                                    MySQL / MariaDB
```

Product surface is **mobile-only**. Laravel owns:

- REST API (`routes/api.php` → `routes/api/v1.php`) used by the Flutter app
- Domain models, policies, services, and migrations
- Web routes only show a retired/mobile-only notice (no admin UI dependency)

## Backend structure

```text
backend/app/
├── Enums/                  # UserRole and future domain enums
├── Http/
│   ├── Controllers/Api/V1/ # Versioned API controllers
│   ├── Controllers/        # Web/admin controllers
│   ├── Middleware/         # role middleware, etc.
│   ├── Requests/Api/V1/    # Form requests
│   └── Resources/Api/V1/   # API transformers
├── Models/
├── Policies/               # Authorization
└── Services/               # Domain services (e.g. MemberIdGenerator)
```

### Key decisions

| Decision | Choice | Why |
|---|---|---|
| Auth for mobile | Laravel Sanctum personal access tokens | Simple, first-party mobile auth without OAuth complexity |
| Auth for admin | Laravel Breeze (session) | Secure cookie sessions for Blade admin |
| Roles | PHP backed enum on `users.role` | Clear four-role model; easy policy checks; can migrate to RBAC later if needed |
| API versioning | `/api/v1` route group | Safe evolution of contracts for mobile clients |
| Money | `DECIMAL(15,2)` planned | Fixed precision; human-readable; sufficient for association dues |
| Soft financial deletes | Void/reverse + audit (planned) | Prevent silent loss of financial history |
| Member ID | Service-generated unique code | Avoids collisions; format can evolve without client hardcoding |

## Flutter structure (feature-first)

```text
mobile/lib/
├── core/
│   ├── api/          # Dio client + interceptors
│   ├── config/       # Environment/base URL
│   ├── error/        # Typed exceptions
│   ├── routing/      # go_router
│   ├── storage/      # Flutter Secure Storage
│   └── theme/        # Shared theme
├── features/
│   ├── auth/
│   ├── home/
│   └── profile/
├── shared/
└── main.dart
```

Each feature may contain `data/`, `domain/`, and `presentation/` as it grows.

## Authorization model

- Backend policies are the source of truth.
- Middleware alias `role:` restricts staff-only route groups.
- Members are limited to self-scoped resources (`UserPolicy@view` etc.).
- Accountants get financial permissions; Super Admin retains role management.

## Security notes

- Never trust role claims from the mobile client.
- Tokens stored only in secure storage on device.
- Credentials and PII excluded from git via root and project `.gitignore`.
- Validation via Form Requests; responses via API Resources to avoid over-exposure.

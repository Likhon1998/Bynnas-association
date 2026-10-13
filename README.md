# Bynnas Association Management Application

Association management platform for ~3,000 members.

- **Mobile (Android/iOS):** Flutter + Riverpod + Dio + Secure Storage
- **Backend / Admin:** Laravel 12 REST API + Blade/Tailwind admin panel
- **Database:** MySQL/MariaDB (SQLite for automated tests)
- **Auth:** Laravel Sanctum (mobile API tokens) + session auth (web admin)

## Repository layout

```text
bynnas-association/
├── backend/          # Laravel API + Blade admin
├── mobile/           # Flutter member application
├── docs/             # Requirements, architecture, DB, API, packages
└── README.md
```

## Quick start

### Backend

```bash
cd backend
cp .env.example .env
php artisan key:generate
# Configure MySQL in .env, create database `bynnas_association`
php artisan migrate
php artisan serve
```

Admin panel (Breeze): `http://127.0.0.1:8000` (use another port if 8000 is already taken)  
API health: `http://127.0.0.1:8000/api/v1/health`

> On this machine, ports `8000`/`8010` may already be used by other local PHP apps. Prefer `php artisan serve --port=8765` when needed.

### Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Documentation

| Document | Purpose |
|---|---|
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Business and security requirements |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture decisions |
| [docs/DATABASE.md](docs/DATABASE.md) | Database design (planned + implemented) |
| [docs/API.md](docs/API.md) | Versioned API conventions |
| [docs/PACKAGES.md](docs/PACKAGES.md) | Required packages and rationale |

## Roles

| Role | Access |
|---|---|
| Super Admin | Full system control |
| Admin | Member and operational management |
| Accountant | Financial operations and reporting |
| Member | Own profile and own financial records only |

## Current initialization status

Scaffolding complete: project structure, Sanctum API v1 auth/health endpoints, role foundation, Flutter core layers, and documentation. Business modules (dues, payments, receipts, allocations) are intentionally not implemented yet.

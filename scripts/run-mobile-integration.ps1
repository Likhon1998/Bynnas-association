# Prepares an isolated Laravel SQLite DB, serves /api/v1, and runs Flutter
# integration tests against the live HTTP API.
#
# Usage (from repo root):
#   .\scripts\run-mobile-integration.ps1
#   .\scripts\run-mobile-integration.ps1 -Port 8765 -HostAddress 127.0.0.1

param(
    [string]$HostAddress = "127.0.0.1",
    [int]$Port = 8765
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $Root "backend"
$Mobile = Join-Path $Root "mobile"
$EnvExample = Join-Path $Backend ".env.integration.example"
$EnvFile = Join-Path $Backend ".env.integration"
$Sqlite = (Join-Path $Backend "database\integration.sqlite")
# Forward slashes avoid Windows path escaping issues in .env / PDO
$SqliteEnv = $Sqlite -replace '\\', '/'

if (-not (Test-Path $EnvFile)) {
    if (-not (Test-Path $EnvExample)) {
        throw "Missing $EnvExample"
    }
    Copy-Item $EnvExample $EnvFile
    Write-Host "Created $EnvFile from example. Review credentials before CI use."
}

# Ensure APP_KEY exists
$envContent = Get-Content $EnvFile -Raw
if ($envContent -notmatch "APP_KEY=base64:") {
    Push-Location $Backend
    try {
        $key = php -r "echo 'base64:'.base64_encode(random_bytes(32));"
        $envContent = $envContent -replace "APP_KEY=.*", "APP_KEY=$key"
        Set-Content -Path $EnvFile -Value $envContent -NoNewline
    } finally {
        Pop-Location
    }
}

# Force absolute SQLite path so `artisan serve` (CWD under public/) uses the seeded DB.
$envContent = Get-Content $EnvFile -Raw
if ($envContent -match "DB_DATABASE=") {
    $envContent = $envContent -replace "DB_DATABASE=.*", "DB_DATABASE=`"$SqliteEnv`""
} else {
    $envContent = $envContent.TrimEnd() + "`nDB_DATABASE=`"$SqliteEnv`"`n"
}
Set-Content -Path $EnvFile -Value $envContent -NoNewline

function Set-IntegrationProcessEnv {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        $parts = $_.Split('=', 2)
        if ($parts.Length -eq 2) {
            $name = $parts[0].Trim()
            $value = $parts[1].Trim().Trim('"')
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }

    $env:DB_CONNECTION = "sqlite"
    $env:DB_DATABASE = $SqliteEnv
    $env:ENABLE_INTEGRATION_FAULTS = "true"
    $env:QUEUE_CONNECTION = "sync"
    $env:CACHE_STORE = "array"
    $env:SESSION_DRIVER = "array"
    $env:MAIL_MAILER = "array"
    $env:APP_ENV = "integration"
}

Write-Host "==> Preparing integration database at $SqliteEnv"
Push-Location $Backend
try {
    Set-IntegrationProcessEnv
    php artisan mobile-integration:prepare --fresh --path=database/integration.sqlite
} finally {
    Pop-Location
}

$apiBase = "http://${HostAddress}:${Port}/api/v1"
Write-Host "==> Starting Laravel on $apiBase (env=integration, absolute sqlite)"

# Free the port if a previous run left a listener.
Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

Set-IntegrationProcessEnv

$serveOut = Join-Path $Backend "storage\logs\integration-serve.out.log"
$serveErr = Join-Path $Backend "storage\logs\integration-serve.err.log"
$serveArgs = @(
    "artisan", "serve",
    "--env=integration",
    "--host=$HostAddress",
    "--port=$Port"
)

# Same-shell background process inherits Process env (APP_ENV + absolute DB_DATABASE).
$serve = Start-Process -FilePath "php" -ArgumentList $serveArgs -WorkingDirectory $Backend `
    -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput $serveOut `
    -RedirectStandardError $serveErr

try {
    $healthy = $false
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "$apiBase/health" -UseBasicParsing -TimeoutSec 2 -Headers @{ Accept = "application/json" }
            if ($response.StatusCode -eq 200) {
                $healthy = $true
                break
            }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }

    if (-not $healthy) {
        Write-Host "--- serve stdout ---"
        if (Test-Path $serveOut) { Get-Content $serveOut }
        Write-Host "--- serve stderr ---"
        if (Test-Path $serveErr) { Get-Content $serveErr }
        throw "Laravel integration server did not become healthy at $apiBase/health"
    }

    # Confirm this listener is the integration app (not a leftover local serve).
    $info = Invoke-RestMethod -Uri "$apiBase/testing/integration-info" -Headers @{ Accept = "application/json" }
    Write-Host "==> integration-info app_env=$($info.app_env) users=$($info.users) db=$($info.db_database)"
    if ($info.app_env -ne "integration" -or -not $info.member_email_present -or [int]$info.users -lt 3) {
        throw "Server is not using the seeded integration database."
    }

    # Prove login against the seeded fixture before Flutter runs.
    $loginBody = '{"email":"integration.member@bynnas.test","password":"password","device_name":"integration-probe"}'
    try {
        $login = Invoke-WebRequest -Uri "$apiBase/auth/login" -Method POST -Body $loginBody `
            -ContentType "application/json" -Headers @{ Accept = "application/json" } -UseBasicParsing
        if ($login.StatusCode -ne 200) {
            throw "Probe login HTTP $($login.StatusCode)"
        }
        Write-Host "==> Probe login OK"
    } catch {
        Write-Host "Probe login failed: $_"
        throw "Integration API login probe failed; aborting Flutter suite."
    }

    Write-Host "==> Running Flutter integration tests (REQUIRE_INTEGRATION_API=1)"
    $env:REQUIRE_INTEGRATION_API = "1"

    Push-Location $Mobile
    try {
        flutter test test/integration `
            --dart-define=API_BASE_URL=$apiBase `
            --dart-define=REQUIRE_INTEGRATION_API=true `
            --dart-define=INTEGRATION_MEMBER_EMAIL=integration.member@bynnas.test `
            --dart-define=INTEGRATION_MEMBER_PASSWORD=password `
            --dart-define=INTEGRATION_OTHER_MEMBER_EMAIL=integration.other@bynnas.test `
            --dart-define=INTEGRATION_OTHER_MEMBER_PASSWORD=password
    } finally {
        Pop-Location
    }
} finally {
    # Do not leave integration env vars in the shell — they break `php artisan test`
    # (APP_ENV=integration / SESSION_DRIVER=array cause CSRF 419 and auth failures).
    @(
        'REQUIRE_INTEGRATION_API',
        'ENABLE_INTEGRATION_FAULTS',
        'APP_ENV',
        'DB_CONNECTION',
        'DB_DATABASE',
        'CACHE_STORE',
        'SESSION_DRIVER',
        'QUEUE_CONNECTION',
        'MAIL_MAILER',
        'APP_URL',
        'APP_KEY',
        'APP_NAME',
        'APP_DEBUG',
        'LOG_CHANNEL',
        'LOG_LEVEL',
        'SANCTUM_STATEFUL_DOMAINS',
        'INTEGRATION_MEMBER_EMAIL',
        'INTEGRATION_MEMBER_PASSWORD',
        'INTEGRATION_OTHER_MEMBER_EMAIL',
        'INTEGRATION_OTHER_MEMBER_PASSWORD',
        'INTEGRATION_ADMIN_EMAIL',
        'INTEGRATION_ADMIN_PASSWORD'
    ) | ForEach-Object { Remove-Item "Env:$_" -ErrorAction SilentlyContinue }

    if ($serve -and -not $serve.HasExited) {
        Stop-Process -Id $serve.Id -Force -ErrorAction SilentlyContinue
        # Also stop any orphaned php artisan serve children on this port.
        Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
            ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    }
}

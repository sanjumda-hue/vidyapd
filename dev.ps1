<#
  Bring the local stack up, down, or report on it.

      .\dev.ps1            # same as status
      .\dev.ps1 up
      .\dev.ps1 down
      .\dev.ps1 status
      .\dev.ps1 up -Watch  # API in nest watch mode instead of the built dist

  Why this exists: the app shows "Cannot reach the server. Is the API running
  on http://localhost:3000/api/v1?" whenever the API is down, and the API is
  down whenever PostgreSQL is -- which is after every single reboot, because
  the portable Postgres build has no Windows service to start it. That made
  three things to remember, in order, every morning. Now it is one.

  `up` is safe to re-run. Anything already listening is left alone.
#>
param(
  [ValidateSet('up', 'down', 'status')]
  [string]$Action = 'status',

  # Run the API through `nest start --watch` so edits to api/src reload.
  # Slower to boot and holds a console; the default runs the built dist.
  [switch]$Watch,

  # Skip the staleness check and use whatever is in api/dist already.
  [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$Root    = $PSScriptRoot
$ApiDir  = Join-Path $Root 'api'
$PgLocal = Join-Path $Root 'db\pg-local.ps1'
$ApiPort = 3000
$PgPort  = 5432

function Test-Port([int]$Port) {
  $null -ne (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Get-ApiProcesses {
  Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -and
      ($_.CommandLine -like '*dist/main.js*' -or $_.CommandLine -like '*dist\main.js*' -or
       $_.CommandLine -like '*nest*start*') }
}

# The API answers on this once it is ready. A 200 means Postgres is reachable
# too, because the handler reads six tables -- so it is the one honest check.
function Test-ApiReady {
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$ApiPort/api/v1/reference/bootstrap" `
      -UseBasicParsing -TimeoutSec 4
    return $r.StatusCode -eq 200
  } catch { return $false }
}

function Show-Status {
  $pg  = if (Test-Port $PgPort)  { 'UP' } else { 'DOWN' }
  $api = if (Test-Port $ApiPort) { 'UP' } else { 'DOWN' }
  $ready = if ((Test-Port $ApiPort) -and (Test-ApiReady)) { 'serving data' } else { 'not answering' }

  Write-Host ''
  Write-Host ("  PostgreSQL  {0,-5} (port {1})" -f $pg, $PgPort)
  Write-Host ("  API         {0,-5} (port {1}, {2})" -f $api, $ApiPort, $ready)
  Write-Host ''
  if ($pg -eq 'DOWN' -or $api -eq 'DOWN') {
    Write-Host '  Run  .\dev.ps1 up' -ForegroundColor Yellow
    Write-Host ''
  }
}

switch ($Action) {

  'status' { Show-Status }

  'down' {
    Get-ApiProcesses | ForEach-Object {
      Write-Host "  stopping API (pid $($_.ProcessId))"
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
    & $PgLocal stop
    Show-Status
  }

  'up' {
    # 1. PostgreSQL. Nothing else can work without it, so this is fatal.
    if (Test-Port $PgPort) {
      Write-Host '  PostgreSQL already up'
    } else {
      Write-Host '  starting PostgreSQL...'
      & $PgLocal start
      if (-not (Test-Port $PgPort)) {
        Write-Error "PostgreSQL did not come up. Check: .\db\pg-local.ps1 log"
        exit 1
      }
    }

    # 2. API.
    if (Test-Port $ApiPort) {
      Write-Host '  API already up'
    } else {
      $main = Join-Path $ApiDir 'dist\main.js'

      # Rebuild only when src is actually newer than the bundle, so the common
      # case -- nothing changed since yesterday -- costs nothing.
      $stale = $true
      if ((-not $NoBuild) -and (Test-Path $main)) {
        $built = (Get-Item $main).LastWriteTimeUtc
        $newest = Get-ChildItem (Join-Path $ApiDir 'src') -Recurse -File -Filter *.ts |
          Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        $stale = $newest -and $newest.LastWriteTimeUtc -gt $built
      }

      if ($Watch) {
        Write-Host '  starting API (watch mode)...'
        Start-Process -FilePath 'npm.cmd' -ArgumentList @('run', 'start:dev') `
          -WorkingDirectory $ApiDir -WindowStyle Minimized
      } else {
        if ($stale -and -not $NoBuild) {
          Write-Host '  api/src is newer than the build, rebuilding...'
          Push-Location $ApiDir
          try { & npm.cmd run build | Out-Null } finally { Pop-Location }
        }
        if (-not (Test-Path $main)) {
          Write-Error "No build at $main and none could be made."
          exit 1
        }
        Write-Host '  starting API...'
        # Detached, so closing this terminal does not take the API with it.
        Start-Process -FilePath 'node.exe' -ArgumentList @('dist/main.js') `
          -WorkingDirectory $ApiDir -WindowStyle Hidden
      }

      # Boot takes a few seconds; watch mode compiles first.
      $deadline = (Get-Date).AddSeconds($(if ($Watch) { 90 } else { 40 }))
      while ((Get-Date) -lt $deadline -and -not (Test-ApiReady)) {
        Start-Sleep -Milliseconds 700
      }
      if (-not (Test-ApiReady)) {
        Write-Error 'API did not start answering. Check api/.env DATABASE_URL, or run it in the foreground: cd api; node dist/main.js'
        exit 1
      }
    }

    Show-Status
    Write-Host '  App:  cd app; flutter run -d chrome' -ForegroundColor DarkGray
    Write-Host ''
  }
}

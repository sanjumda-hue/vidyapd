<#
  Start / stop / check the portable PostgreSQL used for local development.

  There is no Windows service (the portable build is unpacked into the user
  profile and installing a service needs admin), so the cluster has to be
  started by hand after every reboot.

  It also has to be started DETACHED. When postgres is a child of a shell that
  later exits, Windows can tear down the context its backends need, and the
  next connection dies with 0xC0000142 (DLL init failed) -- which takes the
  whole cluster down, not just that connection. Start-Process below avoids that.

      .\db\pg-local.ps1 start
      .\db\pg-local.ps1 status
      .\db\pg-local.ps1 stop
      .\db\pg-local.ps1 log
#>
param(
  [ValidateSet('start', 'stop', 'status', 'log', 'restart')]
  [string]$Action = 'status'
)

$PgCtl = Join-Path $env:USERPROFILE 'pgsql\17\bin\pg_ctl.exe'
$PgData = Join-Path $env:USERPROFILE 'pgsql\data'
$PgLog  = Join-Path $env:USERPROFILE 'pgsql\server.log'
$Port   = 5432

function Test-PgUp {
  $null -ne (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

<#
  Launch detached and poll the port.

  NOT Start-Process -Wait. pg_ctl spawns the postgres server and the wait
  covers the whole process tree, so it only returns when the database shuts
  down again -- the caller hangs forever while the cluster sits there running
  perfectly. Recovery after an unclean stop also takes a few seconds, so a
  fixed sleep either blocks longer than needed or reports failure too early.
#>
function Start-PgDetached([int]$TimeoutSeconds = 30) {
  Start-Process -FilePath $PgCtl `
    -ArgumentList @('-D', $PgData, '-l', $PgLog, '-o', "`"-p $Port`"", 'start') `
    -WindowStyle Hidden
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline -and -not (Test-PgUp)) {
    Start-Sleep -Milliseconds 500
  }
  return (Test-PgUp)
}

if (-not (Test-Path $PgCtl)) {
  Write-Error "pg_ctl not found at $PgCtl. See the PostgreSQL section of README.md."
  exit 1
}

switch ($Action) {
  'status' {
    if (Test-PgUp) { "PostgreSQL is UP on port $Port" } else { "PostgreSQL is DOWN" }
  }
  'start' {
    if (Test-PgUp) { "Already running on port $Port"; break }
    if (Start-PgDetached) { "PostgreSQL started on port $Port" }
    else { Write-Error "Failed to start. Last lines of ${PgLog}:"; Get-Content $PgLog -Tail 15 }
  }
  'stop' {
    & $PgCtl -D $PgData -m fast stop
  }
  'restart' {
    & $PgCtl -D $PgData -m fast stop 2>$null
    Start-Sleep -Seconds 2
    if (Start-PgDetached) { "PostgreSQL restarted on port $Port" }
    else { Write-Error "Restart failed." }
  }
  'log' {
    Get-Content $PgLog -Tail 40
  }
}


# run_concurrencia.ps1
# Issue #43 (A-37): demostracion reproducible del escenario de dos sesiones
# concurrentes que intentan vender la ultima botella (stock = 1), con y sin
# el mecanismo SELECT ... FOR UPDATE de RN-09.
#
# Dos bases temporales e independientes:
#   a37_ultima_botella_tmp          : esquema productivo (001-012) intacto.
#   a37_ultima_botella_noblock_tmp  : esquema productivo SIN el mecanismo de
#                                     bloqueo: la venta se simula con
#                                     UPDATE directos y, solo en esta base
#                                     temporal, se retira el CHECK de stock
#                                     no negativo para mostrar el defecto
#                                     completo (venta doble).
#
# Cada fase lanza DOS procesos psql independientes (sesion A y sesion B) que
# compiten por la misma ultima unidad. Un monitoreo por pg_stat_activity
# registra la espera de la sesion B. La base operativa bodegas_atuel no
# participa; ambas bases temporales se eliminan al finalizar.

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$dbUser = 'bodegas_app'
$baseLock = 'a37_ultima_botella_tmp'
$baseNoLock = 'a37_ultima_botella_noblock_tmp'
$migrationDir = Join-Path $PSScriptRoot '..\migrations'
$outdir = Join-Path $PSScriptRoot 'resultados'
$evidenceDir = 'D:\Bodegas-del-Atuel\docs\auditorias'

$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envFile = Join-Path $projectRoot '.env'
$pgPORT = $null
$pgPASSWORD = $null
foreach ($line in (Get-Content $envFile)) {
    if ($line -match '^POSTGRES_(PASSWORD|PORT)=(.*)$') {
        Set-Variable -Name ("pg" + $Matches[1]) -Value $Matches[2]
    }
}
if (-not $pgPORT) { $pgPORT = 5433 }
if ($pgPASSWORD) { $env:PGPASSWORD = $pgPASSWORD }

$psql = @(
    (Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    'C:\Program Files\PostgreSQL\18\bin\psql.exe'
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $psql) {
    throw 'No se encontro el cliente psql.'
}

$seedFile = Join-Path $PSScriptRoot 'a37_seed_ultima_botella.sql'
$sesionA = Join-Path $PSScriptRoot 'a37_sesion_a.sql'
$sesionB = Join-Path $PSScriptRoot 'a37_sesion_b.sql'
$sesionANoLock = Join-Path $PSScriptRoot 'a37_sesion_a_sin_bloqueo.sql'
$sesionBNoLock = Join-Path $PSScriptRoot 'a37_sesion_b_sin_bloqueo.sql'

$migrations = Get-ChildItem $migrationDir -Filter '0*.sql' |
    Where-Object { $_.Name -notlike '013*' -and $_.Extension -eq '.sql' } |
    Sort-Object Name

if ($baseLock -eq 'bodegas_atuel' -or $baseNoLock -eq 'bodegas_atuel') {
    throw 'Proteccion: se rechazo utilizar la base operativa.'
}

if (-not (Test-Path $outdir)) {
    New-Item -ItemType Directory -Path $outdir | Out-Null
}

# ---------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------

function Invoke-PsqlCmd {
    param([string]$Command, [string]$Database = 'postgres', [string]$File = '')

    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($File) {
            $output = @(& $psql -X -h localhost -p $pgPORT -U $dbUser `
                -d $Database -v ON_ERROR_STOP=1 -q -f $File 2>&1)
        }
        else {
            $output = @(& $psql -X -h localhost -p $pgPORT -U $dbUser `
                -d $Database -v ON_ERROR_STOP=1 -q -c $Command 2>&1)
        }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldEAP
    }

    if ($exitCode -ne 0) {
        throw "Fallo psql (${Database}): $($output -join "`n")"
    }

    return $output
}

function New-CleanupBase {
    param([string]$Base)
    Invoke-PsqlCmd "DROP DATABASE IF EXISTS ${Base};" -Database postgres | Out-Null
}

function New-SetupBase {
    param([string]$Base)

    New-CleanupBase $Base

    Invoke-PsqlCmd "CREATE DATABASE ${Base} OWNER $dbUser;" | Out-Null

    foreach ($migration in $migrations) {
        Invoke-PsqlCmd '' -Database $Base -File $migration.FullName | Out-Null
    }

    Invoke-PsqlCmd "SELECT 1 FROM pg_database WHERE datname='${Base}';" -Database postgres | Out-Null
    Invoke-PsqlCmd '' -Database $Base -File $seedFile | Out-Null
}

function Invoke-RunSession {
    param(
        [string]$Base,
        [string]$Script,
        [string]$OutFile,
        [string]$ErrFile
    )

    return Start-Process -FilePath $psql `
        -ArgumentList @(
            '-X', '-h', 'localhost', '-p', $pgPORT, '-U', $dbUser,
            '-d', $Base, '-v', 'ON_ERROR_STOP=1',
            '-f', $Script
        ) `
        -NoNewWindow `
        -RedirectStandardOutput $OutFile `
        -RedirectStandardError $ErrFile `
        -PassThru
}

function Invoke-Monitor {
    param([string]$Base, [int]$Seconds, [string]$MonitorFile)

    $log = @()
    $deadline = (Get-Date).AddSeconds($Seconds)

    while ((Get-Date) -lt $deadline) {
        $rows = Invoke-PsqlCmd "
            SELECT to_char(clock_timestamp(), 'HH24:MI:SS') || ' | ' ||
                   coalesce(wait_event_type, '-') || ' | ' ||
                   coalesce(wait_event, '-') || ' | ' ||
                   coalesce(usename, '-') || ' | ' ||
                   left(regexp_replace(query, E'[\\n\\r\\t ]+', ' ', 'g'), 90)
              FROM pg_stat_activity
             WHERE datname = '${Base}'
                AND pid <> pg_backend_pid();" -Database $Base

        $log += $rows
        Start-Sleep -Milliseconds 700
    }

    $log | Set-Content -Path $MonitorFile -Encoding UTF8
    return $log
}

function Invoke-Prend {
    param([string]$Text, [string]$Pattern)
    return ($Text -match $Pattern)
}

function Invoke-FinalCheck {
    # Verifica el estado final del stock y de los renglones de la venta en
    # la base indicada (escribe en un archivo temporal para conservar las
    # comillas dobles de los identificadores).
    param([string]$Base)

    $finalSql = Join-Path $env:TEMP 'a37_final_check.sql'
    Set-Content -Path $finalSql -Encoding UTF8 -Value @'
SELECT 'stock final = ' || (SELECT cantidad FROM "Stock_Sala" WHERE sala = 777701 AND vino = 'A37-V1') ||
       ', renglones de A37-V1 en el comprobante = ' ||
       (SELECT COUNT(*) FROM "Renglon_Comprobante" WHERE comprobante = 777701 AND vino = 'A37-V1') AS estado_final;
'@

    $result = Invoke-PsqlCmd '' -Database $Base -File $finalSql
    Remove-Item $finalSql -ErrorAction SilentlyContinue
    return $result
}

# La evidencia consolidada queda en este string y se escribe al final.
$evidence = @()

try {
    Write-Host "=== FASE 1: venta con SELECT ... FOR UPDATE (RN-09) ===" -ForegroundColor Cyan
    Write-Host "Base temporal: $baseLock" -ForegroundColor DarkGray

    New-SetupBase $baseLock

    $pA = Invoke-RunSession $baseLock $sesionA `
        (Join-Path $outdir 'a_sesionA_bloqueo.out') `
        (Join-Path $outdir 'a_sesionA_bloqueo.err')

    Start-Sleep -Seconds 2

    $pB = Invoke-RunSession $baseLock $sesionB `
        (Join-Path $outdir 'a_sesionB_bloqueo.out') `
        (Join-Path $outdir 'a_sesionB_bloqueo.err')

    Write-Host 'Sesiones A y B ejecutandose en paralelo (dos procesos psql)...' -ForegroundColor DarkGray

    $monFile = Join-Path $outdir 'a_monitor_pg_stat_activity.txt'
    $mon = Invoke-Monitor $baseLock 10 $monFile

    $pA.WaitForExit()
    $pB.WaitForExit()

    $outA = (Get-Content (Join-Path $outdir 'a_sesionA_bloqueo.out') -Raw) +
            (Get-Content (Join-Path $outdir 'a_sesionA_bloqueo.err') -Raw)
    $outB = (Get-Content (Join-Path $outdir 'a_sesionB_bloqueo.out') -Raw) +
            (Get-Content (Join-Path $outdir 'a_sesionB_bloqueo.err') -Raw)

    $finalLock = Invoke-FinalCheck $baseLock

    Write-Host "`n--- Salida sesion A ---" -ForegroundColor DarkGray
    Write-Host $outA
    Write-Host "`n--- Salida sesion B ---" -ForegroundColor DarkGray
    Write-Host $outB
    Write-Host "`n--- Esperas observadas (pg_stat_activity) ---" -ForegroundColor DarkGray
    $mon | ForEach-Object { Write-Host $_ }
    Write-Host "`n--- Estado final base con bloqueo ---" -ForegroundColor DarkGray
    $finalLock | ForEach-Object { Write-Host $_ }

    $evidence += 'FASE 1: CON SELECT ... FOR UPDATE (mecanismo RN-09, esquema productivo)'
    $evidence += $outA
    $evidence += $outB
    $evidence += 'Monitoreo pg_stat_activity (sesiones concurrentes):'
    $evidence += $mon
    $evidence += 'Estado final:'
    $evidence += $finalLock
    $evidence += ''

    Write-Host "`n=== FASE 2: comparacion SIN SELECT ... FOR UPDATE ===" -ForegroundColor Cyan
    Write-Host "Base temporal: $baseNoLock" -ForegroundColor DarkGray

    New-SetupBase $baseNoLock

    # Unicamente en la base temporal: se retira el CHECK de stock no negativo
    # (segunda linea de defensa), para mostrar el defecto completo de la
    # venta concurrente sin bloqueo. La base de produccion no se toca.
    Invoke-PsqlCmd '' -Database $baseNoLock `
        -File (Join-Path $PSScriptRoot 'a37_retirar_check.sql') | Out-Null

    $pA2 = Invoke-RunSession $baseNoLock $sesionANoLock `
        (Join-Path $outdir 'n_sesionA_nobloqueo.out') `
        (Join-Path $outdir 'n_sesionA_nobloqueo.err')

    Start-Sleep -Seconds 2

    $pB2 = Invoke-RunSession $baseNoLock $sesionBNoLock `
        (Join-Path $outdir 'n_sesionB_nobloqueo.out') `
        (Join-Path $outdir 'n_sesionB_nobloqueo.err')

    $mon2File = Join-Path $outdir 'n_monitor_pg_stat_activity.txt'
    $mon2 = Invoke-Monitor $baseNoLock 10 $mon2File

    $pA2.WaitForExit()
    $pB2.WaitForExit()

    $outA2 = (Get-Content (Join-Path $outdir 'n_sesionA_nobloqueo.out') -Raw) +
             (Get-Content (Join-Path $outdir 'n_sesionA_nobloqueo.err') -Raw)
    $outB2 = (Get-Content (Join-Path $outdir 'n_sesionB_nobloqueo.out') -Raw) +
             (Get-Content (Join-Path $outdir 'n_sesionB_nobloqueo.err') -Raw)

    $finalNoLock = Invoke-FinalCheck $baseNoLock

    Write-Host "`n--- Salida sesion A (sin bloqueo) ---" -ForegroundColor DarkGray
    Write-Host $outA2
    Write-Host "`n--- Salida sesion B (sin bloqueo) ---" -ForegroundColor DarkGray
    Write-Host $outB2
    Write-Host "`n--- Esperas observadas (pg_stat_activity) ---" -ForegroundColor DarkGray
    $mon2 | ForEach-Object { Write-Host $_ }
    Write-Host "`n--- Estado final base sin bloqueo ---" -ForegroundColor DarkGray
    $finalNoLock | ForEach-Object { Write-Host $_ }

    $evidence += 'FASE 2: SIN SELECT ... FOR UPDATE (UPDATE directos, CHECK retirado en la base temporal)'
    $evidence += $outA2
    $evidence += $outB2
    $evidence += 'Monitoreo pg_stat_activity (sesiones concurrentes):'
    $evidence += $mon2
    $evidence += 'Estado final:'
    $evidence += $finalNoLock

    $evidencePath = Join-Path $evidenceDir 'concurrencia_ultima_botella_raw.txt'
    $evidence | Set-Content -Path $evidencePath -Encoding UTF8
    Write-Host "`nEvidencia cruda guardada en $evidencePath" -ForegroundColor Green
}
finally {
    Write-Host "`nEliminando bases temporales..." -ForegroundColor Yellow
    foreach ($b in @($baseLock, $baseNoLock)) {
        try { New-CleanupBase $b } catch {
            Write-Host "ADVERTENCIA: no se pudo eliminar $b" -ForegroundColor Yellow
        }
    }
    Write-Host 'Finalizado.' -ForegroundColor Green
}

# 04_costo_escritura.ps1
# Issue #46 (A-39/A-40): mide el costo de escritura de la carga masiva con y
# sin los indices de la migracion 013.
#
# Usa dos bases temporales equivalentes:
#   idx_wcost_noidx_tmp : migraciones 001-012 + carga, sin indices 013.
#   idx_wcost_idx_tmp   : migraciones 001-012 + 013 + la misma carga.
#
# Mediciones registradas:
#   1. Duracion de la carga sin indices 013 (base noidx).
#   2. Duracion de crear los indices 013 sobre esas mismas tablas ya cargadas.
#   3. Duracion de la misma carga CON indices (base idx, 013 aplicado antes).
#
# No modifica la base operativa bodegas_atuel. Ambas bases temporales se
# eliminan al finalizar.

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$dbUser = 'bodegas_app'
$baseNoIdx = 'idx_wcost_noidx_tmp'
$baseIdx = 'idx_wcost_idx_tmp'
$migrationDir = Join-Path $PSScriptRoot '..\migrations'
$outdir = Join-Path $PSScriptRoot 'bench_resultados'
$evi = Join-Path $outdir 'costo_escritura.txt'

$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envFile = Join-Path $projectRoot '.env'

$pgPASSWORD = $null
$pgPORT = $null
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

if ($baseNoIdx -eq 'bodegas_atuel' -or $baseIdx -eq 'bodegas_atuel') {
    throw 'Proteccion: se rechazo utilizar la base operativa.'
}

$migrations = Get-ChildItem $migrationDir -Filter '0*.sql' |
    Where-Object { $_.Name -notlike '013*' -and $_.Extension -eq '.sql' } |
    Sort-Object Name

if ($migrations.Count -lt 5) {
    throw 'No se encontraron suficientes migraciones.'
}

$carga = Join-Path $PSScriptRoot '01_carga_sintetica.sql'
$migracion013 = Join-Path $migrationDir '013_indices.sql'

function Invoke-BaseSql {
    param([string]$Base, [string]$Command, [string]$File = '')

    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($File) {
            $output = @(& $psql -X -h localhost -p $pgPORT -U $dbUser `
                -d $Base -v ON_ERROR_STOP=1 -q -f $File 2>&1)
        }
        else {
            $output = @(& $psql -X -h localhost -p $pgPORT -U $dbUser `
                -d postgres -v ON_ERROR_STOP=1 -q -c $Command 2>&1)
        }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldEAP
    }

    if ($exitCode -ne 0) {
        throw "Fallo psql en ${Base}: $($output -join "`n")"
    }

    return $output
}

function New-Base {
    param([string]$Base)

    Invoke-BaseSql $Base "DROP DATABASE IF EXISTS $Base;" | Out-Null
    Invoke-BaseSql $Base "CREATE DATABASE $Base OWNER $dbUser;" | Out-Null

    foreach ($migration in $migrations) {
        Invoke-BaseSql $Base '' $migration.FullName | Out-Null
    }
}

function Remove-Base {
    param([string]$Base)
    Invoke-BaseSql $Base "DROP DATABASE IF EXISTS $Base;" | Out-Null
}

function Invoke-CargaMedida {
    param([string]$Base)

    (Measure-Command {
        Invoke-BaseSql $Base '' $carga | Out-Null
    }).TotalSeconds
}

try {
    Write-Host "Creando base temporal $baseNoIdx..." -ForegroundColor Cyan
    New-Base $baseNoIdx

    Write-Host "Cargando datos SIN indices de 013..." -ForegroundColor Cyan
    $dCargaNoIdx = Invoke-CargaMedida $baseNoIdx

    Write-Host "Creando indices 013 sobre las tablas cargadas..." -ForegroundColor Cyan
    $dIndices = (Measure-Command {
        Invoke-BaseSql $baseNoIdx '' $migracion013 | Out-Null
    }).TotalSeconds

    $verifSql = @'
SELECT
    (SELECT COUNT(*) FROM "Vino" WHERE codigo LIKE 'BENCH-%') AS vinos,
    (SELECT COUNT(*) FROM "Renglon_Comprobante") AS renglones,
    (SELECT COUNT(*) FROM "Stock_Sala") AS stock;
'@

    $verifPath = Join-Path $env:TEMP 'wcost_verif.sql'
    Set-Content -Path $verifPath -Value $verifSql -Encoding UTF8

    $verifNoIdx = Invoke-BaseSql $baseNoIdx '' $verifPath

    Write-Host "Creando base temporal $baseIdx..." -ForegroundColor Cyan
    New-Base $baseIdx

    Write-Host "Aplicando 013 (tablas vacias) en $baseIdx..." -ForegroundColor Cyan
    Invoke-BaseSql $baseIdx '' $migracion013 | Out-Null

    Write-Host "Cargando los mismos datos CON indices..." -ForegroundColor Cyan
    $dCargaIdx = Invoke-CargaMedida $baseIdx

    $verifIdx = Invoke-BaseSql $baseIdx '' $verifPath
    Remove-Item $verifPath -ErrorAction SilentlyContinue

    $report = @()
    $report += '# Medicion de costo de escritura (issue #46 / A-40)'
    $report += ("Fecha de ejecucion : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    $report += 'Entorno: PostgreSQL 16 en contenedor bodegas-atuel-db (local, localhost).'
    $report += 'Datos: 01_carga_sintetica.sql (mismos datos sinteticos en ambas bases).'
    $report += ''
    $report += 'Mediciones'
    $report += ("  Carga SIN indices 013            : {0:N2} s  (base {1})" -f $dCargaNoIdx, $baseNoIdx)
    $report += ("  Creacion de indices sobre datos  : {0:N2} s  (migracion 013 despues de la carga)" -f $dIndices)
    $report += ("  Carga CON indices 013            : {0:N2} s  (base {1}, 013 aplicado antes de cargar)" -f $dCargaIdx, $baseIdx)
    $report += ("  Delta de la carga (con - sin)    : {0:N2} s" -f ($dCargaIdx - $dCargaNoIdx))
    $report += ''
    $report += 'Verificacion de conteos identicos en ambas bases'
    $report += ($verifNoIdx -join "`n")
    $report += '  ---'
    $report += ($verifIdx -join "`n")
    $report += ''
    $report += 'Limitaciones'
    $report += '  - Unica repeticion por escenario; el tiempo de carga no se promedio.'
    $report += '  - Ambas cargas corren secuencialmente: la segunda puede encontrar'
    $report += '    mas registros cacheados en el servidor.'
    $report += '  - La carga usa INSERT (generados en SQL): no mide COPY u otras'
    $report += '    estrategias de carga masiva.'
    $report += '  - No mide UPDATE/DELETE: solo INSERT (carga ascendente e inicial).'

    $report | Set-Content -Path $evi -Encoding UTF8

    Write-Host "`nResultados:" -ForegroundColor Green
    $report | ForEach-Object { Write-Host $_ }
}
finally {
    Write-Host "`nEliminando bases temporales..." -ForegroundColor Yellow
    foreach ($b in @($baseNoIdx, $baseIdx)) {
        try { Remove-Base $b } catch {
            Write-Host "ADVERTENCIA: no se pudo eliminar $b" -ForegroundColor Yellow
        }
    }
}

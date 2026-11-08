
# run_bench.ps1
# Issues #44 / #46: compara consultas antes y despues de la migracion 013.
# Utiliza exclusivamente la base temporal rn_bench_tmp.
# No modifica la base operativa bodegas_atuel.

param([switch]$SoloLimpia)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$container = 'bodegas-atuel-db'
$dbUser = 'bodegas_app'
$base = 'rn_bench_tmp'
$migrationDir = Join-Path $PSScriptRoot '..\migrations'
$outdir = Join-Path $PSScriptRoot 'bench_resultados'

$antes = Join-Path $outdir 'bench_antes.txt'
$despues = Join-Path $outdir 'bench_despues.txt'


function Invoke-Docker {
    param([string[]]$Arguments)

    $output = @(& docker @Arguments)
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Fallo docker (codigo $exitCode): $($output -join "`n")"
    }

    return $output
}

function Invoke-PsqlFile {
    param(
        [string]$LocalPath,
        [string]$RemoteName
    )

    if (-not (Test-Path $LocalPath)) {
        throw "No existe el archivo SQL: $LocalPath"
    }

    $remotePath = "/tmp/$RemoteName"

    Invoke-Docker @(
        'cp',
        $LocalPath,
        "${container}:$remotePath"
    ) | Out-Null

    $output = Invoke-Docker @(
        'exec',
        $container,
        'psql',
        '-X',
        '-U', $dbUser,
        '-d', $base,
        '-v', 'ON_ERROR_STOP=1',
        '-q',
        '-f', $remotePath
    )

    return $output
}

function Invoke-Migration {
    param([string]$MigrationName)

    $path = Join-Path $migrationDir $MigrationName

    Write-Host "Aplicando $MigrationName..." -ForegroundColor Cyan

    Invoke-PsqlFile $path "bench_$MigrationName" | Out-Null
}

function Invoke-Consultas {
    param([string]$Destino)

    $q02 = Invoke-PsqlFile `
        (Join-Path $PSScriptRoot '02_consultas.sql') `
        'bench_q02.sql'

    $q03 = Invoke-PsqlFile `
        (Join-Path $PSScriptRoot '03_patrones_sintetica.sql') `
        'bench_q03.sql'

    @($q02) + @($q03) | Set-Content -Path $Destino -Encoding UTF8
}

if ($SoloLimpia) {
    $exists = Invoke-Docker @(
    'exec', $container,
    'psql', '-X', '-U', $dbUser,
    '-d', 'postgres', '-tAc',
    "SELECT 1 FROM pg_database WHERE datname = '$base';"
)

if (($exists -join '').Trim() -eq '1') {
    Invoke-Docker @(
        'exec', $container,
        'dropdb', '-U', $dbUser, $base
    ) | Out-Null
}

    Write-Host 'Base temporal eliminada, si existia.' -ForegroundColor Green
    exit 0
}

# Verificaciones previas.
$running = Invoke-Docker @(
    'inspect',
    '-f', '{{.State.Running}}',
    $container
)

if (($running -join '').Trim() -ne 'true') {
    throw "El contenedor $container no esta en ejecucion."
}

if ($base -eq 'bodegas_atuel') {
    throw 'Proteccion: se rechazo utilizar la base operativa.'
}

if (-not (Test-Path $outdir)) {
    New-Item -ItemType Directory -Path $outdir | Out-Null
}

$migrations = Get-ChildItem $migrationDir -Filter '0*.sql' |
    Where-Object {
        $_.Name -notlike '013*' -and
        $_.Extension -eq '.sql'
    } |
    Sort-Object Name

if ($migrations.Count -lt 5) {
    throw 'No se encontraron suficientes migraciones.'
}

# La base se elimina incluso si falla una etapa del benchmark.
try {
    Write-Host "`nCreando base temporal $base..." -ForegroundColor Cyan

    Invoke-Docker @(
        'exec', $container,
        'dropdb', '--if-exists',
        '-U', $dbUser, $base
    ) | Out-Null

    Invoke-Docker @(
        'exec', $container,
        'createdb',
        '-U', $dbUser,
        '-O', $dbUser,
        $base
    ) | Out-Null

    # 1. Migraciones sin indices.
    foreach ($migration in $migrations) {
        Invoke-Migration $migration.Name
    }

    # 2. Carga sintetica.
    Write-Host "`nCargando datos sinteticos..." -ForegroundColor Cyan

    Invoke-PsqlFile `
        (Join-Path $PSScriptRoot '01_carga_sintetica.sql') `
        'bench_carga.sql' | Out-Null

    # 3. Verificacion minima de la carga.
    $checkSql = @'
SELECT
    (SELECT COUNT(*) FROM "Vino" WHERE codigo LIKE 'BENCH-%') AS vinos,
    (SELECT COUNT(*) FROM "Comprobante" WHERE numero BETWEEN 50001 AND 55000) AS comprobantes,
    (SELECT COUNT(*) FROM "Ingreso" WHERE codigo LIKE 'ING-BENCH-%') AS ingresos,
    (SELECT COUNT(*) FROM "Transferencia" WHERE numero BETWEEN 1 AND 2000) AS transferencias,
    (SELECT COUNT(*) FROM "Auditoria_Precio" WHERE vino LIKE 'BENCH-%') AS auditorias;
'@

    $checkPath = Join-Path $env:TEMP 'bench_check.sql'
    Set-Content -Path $checkPath -Value $checkSql -Encoding UTF8

    $check = Invoke-PsqlFile $checkPath 'bench_check.sql'
    Remove-Item $checkPath -ErrorAction SilentlyContinue

    Write-Host "`nVerificacion de carga:" -ForegroundColor Cyan
    $check | ForEach-Object { Write-Host $_ }

        # 3.1 Actualizar estadisticas antes de la medicion sin indices.
    Write-Host "`nActualizando estadisticas antes de medir..." -ForegroundColor Cyan

    Invoke-Docker @(
        'exec', $container,
        'psql', '-X',
        '-U', $dbUser,
        '-d', $base,
        '-v', 'ON_ERROR_STOP=1',
        '-c', 'ANALYZE;'
    ) | Out-Null

    # 4. Consultas sin indices.
    Write-Host "`nEjecutando consultas SIN indices..." -ForegroundColor Cyan
    Invoke-Consultas $antes

        # 5. Aplicacion de indices y actualizacion de estadisticas.
    Write-Host "`nAplicando migracion 013..." -ForegroundColor Cyan
    Invoke-Migration '013_indices.sql'

    Write-Host "`nActualizando estadisticas despues de crear indices..." -ForegroundColor Cyan

    Invoke-Docker @(
        'exec', $container,
        'psql', '-X',
        '-U', $dbUser,
        '-d', $base,
        '-v', 'ON_ERROR_STOP=1',
        '-c', 'ANALYZE;'
    ) | Out-Null

    # 6. Consultas con indices, sobre exactamente los mismos datos.
    Write-Host "`nEjecutando consultas CON indices..." -ForegroundColor Cyan
    Invoke-Consultas $despues

    Write-Host "`nResultados guardados:" -ForegroundColor Green
    Write-Host "  $antes"
    Write-Host "  $despues"
}
finally {
    Write-Host "`nEliminando base temporal..." -ForegroundColor Yellow

    Invoke-Docker @(
        'exec', $container,
        'dropdb', '--if-exists',
        '-U', $dbUser, $base
    ) | Out-Null

    Write-Host 'Finalizado: la base temporal fue eliminada.' -ForegroundColor Green
}

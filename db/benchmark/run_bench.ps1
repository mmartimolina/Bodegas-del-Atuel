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

# Conexion por TCP al servidor PostgreSQL del contenedor (mapeado en localhost).
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envFile = Join-Path $projectRoot '.env'
$pgUser = $dbUser

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

function Invoke-Docker {
    param([string[]]$Arguments)

    # Comandos psql directos al servidor (la palabra clave -c o -f se conserva).
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $psql -X -h localhost -p $pgPORT @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldEAP
    }

    if ($exitCode -ne 0) {
        throw "Fallo psql (codigo $exitCode): $($output -join "`n")"
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

    $output = Invoke-Docker @(
        '-U', $dbUser,
        '-d', $base,
        '-v', 'ON_ERROR_STOP=1',
        '-q',
        '-f', $LocalPath
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
    '-U', $dbUser,
    '-d', 'postgres', '-tAc',
    "SELECT 1 FROM pg_database WHERE datname = '$base';"
)

if (($exists -join '').Trim() -eq '1') {
    Invoke-Docker @(
        '-U', $dbUser,
        '-c', "DROP DATABASE $base;"
    ) | Out-Null
}

    Write-Host 'Base temporal eliminada, si existia.' -ForegroundColor Green
    exit 0
}

# Verificaciones previas.
& $psql -X -h localhost -p $pgPORT -U $dbUser -d postgres -q -tAc 'SELECT 1;' | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw 'El servidor PostgreSQL no esta disponible.'
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

    & $psql -X -h localhost -p $pgPORT -U $dbUser -d postgres -q `
        -v ON_ERROR_STOP=1 `
        -c "DROP DATABASE IF EXISTS $base;" `
        -c "CREATE DATABASE $base OWNER $dbUser;" | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw 'No se pudo crear la base temporal.'
    }

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

    & $psql -X -h localhost -p $pgPORT -U $dbUser -d postgres -q `
        -v ON_ERROR_STOP=1 `
        -c "DROP DATABASE IF EXISTS $base;" | Out-Null

    Write-Host 'Finalizado: la base temporal fue eliminada.' -ForegroundColor Green
}

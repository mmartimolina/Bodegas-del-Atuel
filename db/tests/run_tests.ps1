# Ejecutor integral de pruebas de reglas de negocio.
# Bases de datos utilizadas exclusivamente para pruebas:
# rn_tests_tmp
#
# No modifica bodegas_atuel ni volúmenes Docker.

param(
    [string]$TestName = ''
)

$ErrorActionPreference = 'Stop'

$script:container = 'bodegas-atuel-db'
$script:pgUser = 'bodegas_app'
$script:testDb = 'rn_tests_tmp'

# Conexion por TCP al servidor PostgreSQL del contenedor (mapeado en localhost).
# Se leen POSTGRES_USER, POSTGRES_PASSWORD y POSTGRES_PORT del .env del repositorio.
$script:projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:envFile = Join-Path $script:projectRoot '.env'
if (-not (Test-Path $script:envFile)) {
    throw "Falta el archivo .env con las credenciales de PostgreSQL."
}

foreach ($line in (Get-Content $script:envFile)) {
    if ($line -match '^POSTGRES_(USER|PASSWORD|PORT)=(.*)$') {
        Set-Variable -Scope Script -Name ("pg" + $Matches[1]) -Value $Matches[2]
    }
}

$script:pgPortDefault = 5433
if (-not (Get-Variable -Scope Script -Name 'pgPORT' -ErrorAction SilentlyContinue)) {
    $script:pgPORT = $script:pgPortDefault
}

$script:psql = @(
    (Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    'C:\Program Files\PostgreSQL\18\bin\psql.exe'
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $script:psql) {
    throw "No se encontró el cliente psql."
}

if ($script:pgPASSWORD) {
    $env:PGPASSWORD = $script:pgPASSWORD
}

$script:projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:migrationRoot = Join-Path $script:projectRoot 'db\migrations'

$migrations = Get-ChildItem $script:migrationRoot -Filter '0*.sql' |
    Where-Object { $_.Name -notmatch '\.bak$|\.pre' } |
    Sort-Object Name |
    ForEach-Object { $_.Name }

$okFiles = Get-ChildItem $PSScriptRoot -Filter '*.ok.sql' |
    Sort-Object Name

$failFiles = Get-ChildItem $PSScriptRoot -Filter '*.fail.sql' |
    Sort-Object Name
    if (-not [string]::IsNullOrWhiteSpace($TestName)) {
    $selectedFiles = @(
        $okFiles + $failFiles |
            Where-Object { $_.Name -eq $TestName }
    )

    if ($selectedFiles.Count -ne 1) {
        throw "No se encontró exactamente una prueba llamada: $TestName"
    }

    $okFiles = @($okFiles | Where-Object { $_.Name -eq $TestName })
    $failFiles = @($failFiles | Where-Object { $_.Name -eq $TestName })
}
$expectedSqlStates = @{
    'rn05_delete_incompleto.fail.sql' = 'P0001'
    'rn05_suma_mayor.fail.sql'         = 'P0001'
    'rn05_suma_menor.fail.sql'         = 'P0001'
    'rn05_vino_sin_composicion.fail.sql' = 'P0001'
    'rn06_cliente_sin_subtipo.fail.sql' = '23514'
    'rn10_ingreso_en_confeccion.fail.sql' = '23514'
    'rn10_ingreso_vacio.fail.sql'      = '23514'
    'rn10_reproceso.fail.sql'          = '23514'
    'rn11_reproceso.fail.sql'          = '23514'
    'rn11_stock_insuficiente.fail.sql' = '23514'
}

function Invoke-PsqlFile {
    param(
        [string]$Database,
        [string]$LocalFile
    )

    $ErrorActionPreference = 'Continue'

    try {
        $output = & $script:psql `
            -X `
            -h localhost `
            -p $script:pgPORT `
            -U $script:pgUser `
            -d $Database `
            -v ON_ERROR_STOP=1 `
            -v VERBOSITY=verbose `
            -f $LocalFile 2>&1

        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output = ($output | Out-String)
    }
}

function Invoke-PsqlOk {
    param(
        [string]$Database,
        [string]$File
    )

    $result = Invoke-PsqlFile $Database $File

    if ($result.ExitCode -ne 0) {
        throw "La ejecución debía ser correcta y falló: $File`n$($result.Output)"
    }

    return $result.Output
}

function Invoke-PsqlExpectedFailure {
    param(
        [string]$Database,
        [string]$File
    )

    $result = Invoke-PsqlFile $Database $File

    if ($result.ExitCode -eq 0) {
        throw "La prueba negativa no produjo el rechazo esperado: $File"
    }

    $testName = [IO.Path]::GetFileName($File)

    if (-not $expectedSqlStates.ContainsKey($testName)) {
        throw "No hay SQLSTATE esperado definido para: $testName"
    }

    $sqlStateEsperado = $expectedSqlStates[$testName]

    if ($result.Output -notmatch '(?m)ERROR:\s+([A-Z0-9]{5}):') {
        throw "No se pudo identificar el SQLSTATE del error: $File`n$($result.Output)"
    }

    $sqlStateObtenido = $Matches[1]

    if ($sqlStateObtenido -ne $sqlStateEsperado) {
        throw "SQLSTATE incorrecto en $File. Esperado: $sqlStateEsperado. Obtenido: $sqlStateObtenido.`n$($result.Output)"
    }

    # También exige que el mensaje mencione la regla correspondiente.
    if ($testName -match '^rn(\d+_|\d+)') {
        $regla = $Matches[1].TrimEnd('_')

        if ($regla -match '^\d+$') {
            $reglaEsperada = 'RN-' + $regla.PadLeft(2, '0')
        } else {
            $reglaEsperada = 'RN-' + $regla
        }

        if ($result.Output -notmatch [regex]::Escape($reglaEsperada)) {
            throw "La prueba no falló por $reglaEsperada como se esperaba: $File`n$($result.Output)"
        }
    }

    return $result.Output
}

function New-TestDb {
    Write-Host "  Preparando base temporal..." -ForegroundColor DarkGray

    & $script:psql -X -h localhost -p $script:pgPORT -U $script:pgUser `
        -d postgres -q `
        -v ON_ERROR_STOP=1 `
        -c "DROP DATABASE IF EXISTS $script:testDb;"

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo eliminar la base temporal anterior."
    }

    & $script:psql -X -h localhost -p $script:pgPORT -U $script:pgUser `
        -d postgres -q `
        -v ON_ERROR_STOP=1 `
        -c "CREATE DATABASE $script:testDb OWNER $script:pgUser;"

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo crear la base temporal."
    }
}

function Remove-TestDb {
    & $script:psql -X -h localhost -p $script:pgPORT -U $script:pgUser `
        -d postgres -q `
        -v ON_ERROR_STOP=1 `
        -c "DROP DATABASE IF EXISTS $script:testDb;"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ADVERTENCIA: no se pudo eliminar rn_tests_tmp." -ForegroundColor Yellow
    }
}

# ============================================================
# VALIDACIONES PREVIAS
# ============================================================

if ($script:testDb -eq 'bodegas_atuel') {
    throw "Protección: no se permite utilizar la base de desarrollo."
}

if (($okFiles.Count + $failFiles.Count) -eq 0) {
    throw "No se encontraron pruebas para ejecutar."
}

# Conexion al servidor por TCP.
& $script:psql -X -h localhost -p $script:pgPORT -U $script:pgUser `
    -d postgres -q -tAc "SELECT 1;" | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "El servidor PostgreSQL no está disponible."
}

if ($migrations.Count -lt 5) {
    throw "No hay suficientes migraciones."
}

foreach ($migration in $migrations) {
    if (-not (Test-Path (Join-Path $script:migrationRoot $migration))) {
        throw "Falta la migración $migration."
    }
}

Write-Host "`n=== PRUEBAS DE REGLAS DE NEGOCIO ===" -ForegroundColor Cyan
Write-Host "Base exclusiva de pruebas: $script:testDb"
Write-Host "Base de desarrollo protegida: bodegas_atuel"

$total = 0
$aprobadas = 0
$fallidas = 0

$tests = @(
    foreach ($file in $okFiles) {
        [PSCustomObject]@{
            File = $file
            Negative = $false
        }
    }
    foreach ($file in $failFiles) {
        [PSCustomObject]@{
            File = $file
            Negative = $true
        }
    }
)

try {
    foreach ($test in $tests) {
        $file = $test.File
        $total++

        Write-Host "`n[$total/$($tests.Count)] $($file.Name)" -ForegroundColor Cyan

        try {
            New-TestDb

            foreach ($migration in $migrations) {
                $migrationPath = Join-Path $script:migrationRoot $migration

                Invoke-PsqlOk $script:testDb $migrationPath |
                    Out-Null
            }

            if ($test.Negative) {
                $output = Invoke-PsqlExpectedFailure `
                    $script:testDb `
                    $file.FullName

                Write-Host "[RECHAZO CORRECTO] $($file.Name)" -ForegroundColor Green
            }
            else {
                $output = Invoke-PsqlOk `
                    $script:testDb `
                    $file.FullName

                Write-Host "[ACEPTADA] $($file.Name)" -ForegroundColor Green
            }

            $notices = $output -split "`r?`n" |
                Select-String -Pattern 'OK RN|RN-05'

            foreach ($notice in $notices) {
                Write-Host "  $($notice.Line.Trim())" -ForegroundColor DarkGreen
            }

            $aprobadas++
        }
        catch {
            $fallidas++
            Write-Host "[FALLO] $($file.Name)" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
        finally {
            Remove-TestDb
        }
    }
}
finally {
    Remove-TestDb
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RESULTADO FINAL" -ForegroundColor Cyan
Write-Host "Casos ejecutados: $total"
Write-Host "Casos aprobados: $aprobadas" -ForegroundColor Green
Write-Host "Casos fallidos: $fallidas" -ForegroundColor $(if ($fallidas -eq 0) { 'Green' } else { 'Red' })
Write-Host "Base de desarrollo bodegas_atuel: intacta"
Write-Host "========================================" -ForegroundColor Cyan

if ($fallidas -gt 0) {
    exit 1
}

exit 0

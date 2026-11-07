# Ejecutor integral de pruebas de reglas de negocio.
# Bases de datos utilizadas exclusivamente para pruebas:
# rn_tests_tmp
#
# No modifica bodegas_atuel ni volúmenes Docker.

$ErrorActionPreference = 'Stop'

$script:container = 'bodegas-atuel-db'
$script:pgUser = 'bodegas_app'
$script:testDb = 'rn_tests_tmp'

$script:projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:migrationRoot = Join-Path $script:projectRoot 'db\migrations'

$migrations = @(
    '001_esquema.sql',
    '002_constraints.sql',
    '003_rn05_composicion_deferred.sql',
    '004_rn03_rn06.sql'
)

$okFiles = Get-ChildItem $PSScriptRoot -Filter '*.ok.sql' |
    Sort-Object Name

$failFiles = Get-ChildItem $PSScriptRoot -Filter '*.fail.sql' |
    Sort-Object Name

function Invoke-PsqlFile {
    param(
        [string]$Database,
        [string]$LocalFile
    )

    if (-not (Test-Path -LiteralPath $LocalFile)) {
        throw "No existe el archivo: $LocalFile"
    }

    $remoteFile = "/tmp/rn_test_$([IO.Path]::GetFileName($LocalFile))"

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        & docker cp $LocalFile "${script:container}:$remoteFile" 2>$null |
            Out-Null

        $copyExitCode = $LASTEXITCODE

        if ($copyExitCode -ne 0) {
            throw "No se pudo copiar $LocalFile al contenedor."
        }

        $output = & docker exec $script:container psql `
            -X `
            -U $script:pgUser `
            -d $Database `
            -v ON_ERROR_STOP=1 `
            -f $remoteFile 2>&1

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

    if ($testName -like 'rn05_*' -and $result.Output -notmatch 'RN-05') {
        throw "La prueba no fallo por RN-05 como se esperaba: $File`n$($result.Output)"
    }

    if ($testName -like 'rn06_*' -and $result.Output -notmatch 'RN-06') {
        throw "La prueba no fallo por RN-06 como se esperaba: $File`n$($result.Output)"
    }

    return $result.Output
}

function New-TestDb {
    Write-Host "  Preparando base temporal..." -ForegroundColor DarkGray

    & docker exec $script:container dropdb `
        --if-exists `
        -U $script:pgUser `
        $script:testDb

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo eliminar la base temporal anterior."
    }

    & docker exec $script:container createdb `
        -U $script:pgUser `
        -O $script:pgUser `
        $script:testDb

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo crear la base temporal."
    }
}

function Remove-TestDb {
    & docker exec $script:container dropdb `
        --if-exists `
        -U $script:pgUser `
        $script:testDb

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

$running = & docker inspect -f '{{.State.Running}}' $script:container

if ($LASTEXITCODE -ne 0 -or $running -ne 'true') {
    throw "El contenedor PostgreSQL no está disponible."
}

if ($okFiles.Count -eq 0) {
    throw "No se encontraron pruebas positivas."
}

if ($migrations.Count -ne 4) {
    throw "La lista de migraciones no es la esperada."
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

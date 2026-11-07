
# verify_a15.ps1
# A-15 (issue #18): mecanismo reproducible de verificacion del DDL base.
# Crea una base temporal vacia, aplica la migracion, ejecuta las verificaciones
# y elimina exclusivamente la base temporal creada por este script.
# No modifica la base de desarrollo.
# Uso: powershell -File db\verify\verify_a15.ps1
# Requiere: contenedor Docker bodegas-atuel-db en ejecucion.

$ErrorActionPreference = 'Stop'

$container = 'bodegas-atuel-db'
$user      = 'bodegas_app'
$db        = 'a15_verificacion_tmp'
$root      = Split-Path $PSScriptRoot -Parent

function Invoke-Psql([string]$dbn, [string]$sqlFile) {
    if (-not (Test-Path $sqlFile)) {
        throw "No existe el archivo SQL: $sqlFile"
    }

    $remote = '/tmp/_a15_' + [IO.Path]::GetFileName($sqlFile)

    docker cp $sqlFile "${container}:$remote"
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo copiar $sqlFile al contenedor"
    }

    docker exec -i $container psql -U $user -d $dbn -v ON_ERROR_STOP=1 -f $remote
    if ($LASTEXITCODE -ne 0) {
        throw "psql fallo con codigo $LASTEXITCODE"
    }
}

Write-Host "== 0. Comprobando base temporal ($db) =="

$existe = docker exec -i $container psql -U $user -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$db';"

if ($LASTEXITCODE -ne 0) {
    throw 'No se pudo comprobar la existencia de la base de pruebas'
}

if ($null -ne $existe -and $existe.Trim() -eq '1') {
    throw "La base $db ya existe. No se eliminara por seguridad."
}

docker exec -i $container psql -U $user -d postgres -c "CREATE DATABASE $db OWNER $user;"

if ($LASTEXITCODE -ne 0) {
    throw 'No se pudo crear la base de pruebas'
}

$baseCreada = $true

try {
    Write-Host "== 1. Aplicando migration 001_esquema.sql =="
    Invoke-Psql $db (Join-Path $root 'migrations\001_esquema.sql')

    Write-Host "== 2. Verificacion de catalogo (verify_a15.sql) =="
    Invoke-Psql $db (Join-Path $PSScriptRoot 'verify_a15.sql')

    Write-Host "== RESULTADO: verificacion completa OK =="
}
finally {
    if ($baseCreada) {
        Write-Host "== 3. Eliminando base temporal =="

        docker exec -i $container psql -U $user -d postgres -c "DROP DATABASE $db;"

        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo eliminar la base temporal $db. Revisar manualmente."
        }

        Write-Host "== Base temporal eliminada. Base de desarrollo intacta. =="
    }
}

# Respaldo y restauración de PostgreSQL

Guía para respaldar y comprobar una restauración de Bodegas del Atuel. No
modifica el esquema. Las pruebas de restauración deben ejecutarse en una
instancia de prueba o staging, nunca sobre la base de producción.

## Requisitos

- Cliente `pg_dump`, `pg_restore`, `createdb`, `dropdb` y `psql` compatible con
  PostgreSQL 16.
- Variables de conexión `PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE` y
  `PGPASSWORD` configuradas en el entorno. No poner contraseñas en comandos,
  archivos versionados ni registros de terminal.
- Espacio protegido para el archivo de respaldo: puede contener datos
  personales y comerciales.

## Crear y verificar un respaldo

En PowerShell, una vez configuradas las variables del entorno:

```powershell
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $PWD "bodegas-$stamp.dump"

pg_dump `
  --host="$env:PGHOST" `
  --port="$env:PGPORT" `
  --username="$env:PGUSER" `
  --dbname="$env:PGDATABASE" `
  --format=custom `
  --no-owner `
  --no-acl `
  --file="$backup"
if ($LASTEXITCODE -ne 0) { throw 'pg_dump fallo' }

pg_restore --list "$backup" | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'El archivo no se puede leer con pg_restore' }
Get-FileHash -Algorithm SHA256 "$backup"
```

El formato custom permite restaurar objetos selectivos y conserva la estructura
del archivo. Guardar el dump y su hash en almacenamiento cifrado con acceso
restringido y política de retención aprobada por el operador.

## Ensayo reproducible de restauración

Usar credenciales con permiso para crear una base en una instancia aislada.
Elegir un nombre de base nuevo y comprobar que no exista antes de crearla.

```powershell
$restoreDb = 'bodegas_restore_test'

createdb `
  --host="$env:PGHOST" `
  --port="$env:PGPORT" `
  --username="$env:PGUSER" `
  --maintenance-db=postgres `
  "$restoreDb"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la base de restauracion' }

pg_restore `
  --host="$env:PGHOST" `
  --port="$env:PGPORT" `
  --username="$env:PGUSER" `
  --dbname="$restoreDb" `
  --no-owner `
  --no-acl `
  --exit-on-error `
  '.\bodegas-backup.dump'
if ($LASTEXITCODE -ne 0) { throw 'La restauracion fallo; conservar la base para diagnostico' }

psql `
  --host="$env:PGHOST" `
  --port="$env:PGPORT" `
  --username="$env:PGUSER" `
  --dbname="$restoreDb" `
  --set=ON_ERROR_STOP=1 `
  --command='SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ''public'';'
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las verificaciones posteriores a restaurar' }
```

Comparar los conteos de tablas con el origen mediante
[`db/seed/validar_carga.sql`](../db/seed/validar_carga.sql) cuando el dump
corresponda al dataset completo. Confirmar además acceso a vistas, funciones,
procedimientos y roles con el administrador de la instancia.

Al finalizar y solo después de comprobar el nombre y la instancia:

```powershell
dropdb `
  --host="$env:PGHOST" `
  --port="$env:PGPORT" `
  --username="$env:PGUSER" `
  --maintenance-db=postgres `
  "$restoreDb"
```

No ejecutar `dropdb` si el nombre no identifica inequívocamente la base
temporal. Registrar fecha, versión de PostgreSQL, resultado, duración, hash y
responsable del ensayo en el registro de operación.

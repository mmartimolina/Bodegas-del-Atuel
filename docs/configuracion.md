# Variables de entorno

Copiar `.env.example` a `.env` en la raíz y reemplazar los valores de ejemplo
por valores locales. No versionar `.env` ni compartir contraseñas reales.

## PostgreSQL y Compose

| Variable | Uso | Valor de ejemplo |
|---|---|---|
| `POSTGRES_DB` | Base inicializada por el contenedor PostgreSQL. | `bodegas_atuel` |
| `POSTGRES_USER` | Usuario administrador inicial usado por Compose y migraciones. | `bodegas_app` |
| `POSTGRES_PASSWORD` | Contraseña local del usuario inicial. Debe reemplazarse. | `cambiar_esta_clave` |
| `POSTGRES_PORT` | Puerto publicado en el host; dentro de Compose PostgreSQL escucha en 5432. | `5433` |

El directorio `db/migrations` se monta como scripts de inicialización. PostgreSQL
los ejecuta únicamente cuando crea un directorio de datos vacío.

## API

| Variable | Uso | Valor de ejemplo |
|---|---|---|
| `DB_HOST` | Host PostgreSQL. Compose lo reemplaza por `postgres`; fuera de Compose usar `localhost`. | `localhost` |
| `DB_PORT` | Puerto de PostgreSQL. Compose lo reemplaza por `5432`; fuera de Compose usar `POSTGRES_PORT`. | `5433` |
| `DB_ROLE` | Rol de negocio seleccionado en cada conexión. La API solo permite `bodegas_api`. | `bodegas_api` |
| `API_HOST` | Dirección de escucha de Uvicorn. | `0.0.0.0` |
| `API_PORT` | Puerto de Uvicorn y puerto publicado en el host. | `8000` |
| `API_CORS_ORIGINS` | Orígenes web permitidos, separados por comas. | `http://localhost:8080` |

La API toma las credenciales de `POSTGRES_USER`, `POSTGRES_PASSWORD` y
`POSTGRES_DB`; no se configuran duplicados.

## Frontend

| Variable | Uso | Valor de ejemplo |
|---|---|---|
| `FRONTEND_PORT` | Puerto HTTP publicado por Nginx en el host. | `8080` |
| `FRONTEND_API_BASE_URL` | URL de API que usará el navegador. Debe ser accesible desde la computadora del usuario, no el nombre interno del servicio Compose. | `http://localhost:8000` |

## Carga de datos

`PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE` y `PGPASSWORD` son variables
estándar de libpq usadas por utilidades como `psql`, `pg_dump` y el generador de
datos. No son necesarias para iniciar Compose. El ejemplo las documenta para
una instancia local; ajustarlas antes de usar las utilidades y mantener la
contraseña fuera del repositorio.

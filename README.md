# Bodegas del Atuel

Trabajo Práctico Integrador de Bases de Datos.

Sistema de gestión de información para una bodega vitivinícola, desarrollado como parte del Trabajo Práctico Integrador de la asignatura.

## 1. Tecnologías

- **Base de datos:** PostgreSQL 16.
- **Contenedores:** Docker.
- **Orquestación local:** Docker Compose.
- **Cliente SQL:** pgAdmin 4 (u otro cliente compatible).
- **Control de versiones:** Git y GitHub.

## 2. Requisitos previos

Para trabajar con el proyecto se necesita:

- Docker Desktop instalado y en ejecución.
- Docker Compose.
- Git.
- Un cliente SQL, como pgAdmin 4 (opcional, pero recomendado).

## 3. Configuración del entorno local

Cada integrante debe configurar su propio entorno local.

### 3.1. Crear el archivo de variables de entorno

Desde la raíz del repositorio, copiar el archivo de ejemplo:

```powershell
Copy-Item .env.example .env
```

### 3.2. Configurar las variables

Abrir el archivo `.env` y establecer los valores correspondientes:

```env
POSTGRES_DB=bodegas_atuel
POSTGRES_USER=bodegas_app
POSTGRES_PASSWORD=tu_clave_local
POSTGRES_PORT=5433
```

La contraseña es elegida por cada integrante y debe mantenerse en su entorno local.

**Importante:**
- El archivo `.env` contiene información local y no debe subirse a GitHub.
- El archivo `.env.example` sirve como plantilla y sí debe compartirse en el repositorio.
- Cada integrante puede utilizar una contraseña diferente.
- El puerto local `5433` permite evitar conflictos con instalaciones de PostgreSQL que utilicen el puerto `5432`.

## 4. Iniciar los servicios

Desde la carpeta raíz del proyecto, ejecutar:

```powershell
docker compose up -d
```

Este comando crea e inicia PostgreSQL, la API y el frontend en segundo plano.
La API espera que PostgreSQL esté saludable y el frontend espera que la API
responda a su healthcheck.

En una base nueva, PostgreSQL aplica automáticamente las migraciones
`db/migrations/001..014` en orden. Los scripts de inicialización de la imagen
oficial solo se ejecutan cuando el directorio de datos está vacío. Si ya existe
un volumen de una instalación anterior, crear una copia de seguridad y aplicar
manualmente únicamente las migraciones pendientes antes de iniciar la API; no
borres el volumen para forzar una inicialización.

### 4.1. Verificar el estado

```powershell
docker compose ps
```

PostgreSQL y la API deben aparecer con estado `healthy`.

### 4.2. Consultar los registros

```powershell
docker compose logs -f postgres
```

Para salir de la visualización de registros, presionar `Ctrl + C`. Esto no detiene el contenedor.

Para consultar los registros de la API o el frontend, usar
`docker compose logs -f api` o `docker compose logs -f frontend`.

## 5. Conexión desde un cliente SQL

Para conectarse a la base de datos desde pgAdmin 4 u otro cliente SQL, utilizar los siguientes parámetros:

| Parámetro | Valor |
|---|---|
| Host | `localhost` |
| Puerto | `5433` |
| Base de datos | `bodegas_atuel` |
| Usuario | `bodegas_app` |
| Contraseña | La definida en `.env` |

El puerto configurado corresponde al acceso desde la computadora local. Dentro del contenedor, PostgreSQL utiliza el puerto `5432`.

## 6. Comandos habituales

Ejecutar los siguientes comandos desde la raíz del repositorio.

### Iniciar el servicio

```powershell
docker compose start
```

### Detener el servicio

```powershell
docker compose stop
```

### Reiniciar el servicio

```powershell
docker compose restart postgres
```

### Consultar el estado

```powershell
docker compose ps
```

### Consultar los registros

```powershell
docker compose logs -f postgres
```

### Acceder a PostgreSQL desde la terminal

```powershell
docker compose exec postgres psql -U bodegas_app -d bodegas_atuel
```

### Eliminar el contenedor y la red

```powershell
docker compose down
```

Este comando elimina los contenedores y la red del proyecto, pero conserva el volumen de datos.

**Advertencia:** no utilizar `docker compose down -v` salvo que se quiera eliminar también el volumen y perder los datos almacenados.

## 7. Persistencia de datos

PostgreSQL utiliza un volumen Docker denominado:

```text
bodegas_atuel_postgres_data
```

Este volumen permite conservar la información de la base de datos aunque el contenedor se detenga, reinicie o se vuelva a crear.

Los datos no se almacenan directamente en los archivos del repositorio.

## 8. Healthcheck

El servicio cuenta con un control de salud que utiliza `pg_isready` para verificar que PostgreSQL esté aceptando conexiones.

La configuración contempla:

- Intervalo de comprobación: 10 segundos.
- Tiempo máximo de espera: 5 segundos.
- Reintentos: 5.
- Tiempo inicial de espera: 10 segundos.

El estado puede consultarse mediante:

```powershell
docker compose ps
```

## 9. Aplicación web y API

Compose inicia PostgreSQL, la API FastAPI y el frontend estático. Cuando los
servicios estén saludables, abrí `http://localhost:8080`; la documentación
interactiva de la API está en `http://localhost:8000/docs`.

La API utiliza Python 3.12, FastAPI y psycopg 3. Las consultas SQL están
parametrizadas y organizadas en `api/app/repositories/`; no se usa ORM. En
Compose, la aplicación se conecta como `bodegas_app` y ejecuta las operaciones
con `SET ROLE bodegas_api`. Para correrla fuera de Docker, instalá las
dependencias y configurá `DB_HOST=localhost`, `DB_PORT` igual a `POSTGRES_PORT`
y las credenciales locales del archivo `.env`:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r api\requirements-dev.txt
$env:PYTHONPATH = "api"
python -m uvicorn app.main:app --reload
```

La base debe estar migrada y contener los datos de referencia antes de usar
formularios de vinos, ventas y movimientos. Las instrucciones para preparar la
carga de datos están en [db/seed/README.md](db/seed/README.md).
La descripción de cada variable de entorno está en
[docs/configuracion.md](docs/configuracion.md). Los bocetos y el mapeo de
pantallas a endpoints están en
[docs/frontend/wireframes.md](docs/frontend/wireframes.md).
El detalle de rutas, parámetros, ejemplos y errores está en
[docs/api.md](docs/api.md); la especificación ejecutable se publica en
`/openapi.json`.

### Pruebas y calidad

Desde la raíz, ejecutá:

```powershell
python -m pytest api\tests
python -m ruff check api
python -m ruff format --check api
node --check front\app.js
docker compose config --quiet
```

Las pruebas HTTP de la API no escriben en PostgreSQL. Las pruebas SQL se
ejecutan con `db\tests\run_tests.ps1` contra una base temporal y requieren
`psql`; nunca uses la base de desarrollo para esa suite.

## 10. Organización del proyecto

```text
Bodegas-del-Atuel/
│
├── db/
│   ├── migrations/
│   ├── seed/
│   └── tests/
├── api/
│   ├── app/
│   └── tests/
├── front/
├── consultas/
│
├── docs/
│   ├── consigna/
│   ├── auditorias/
│   └── modelo/
│
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md
```

La estructura puede ampliarse a medida que avance el desarrollo.

## 11. Trabajo colaborativo

Cada integrante trabaja con su propia instancia local de PostgreSQL.

El repositorio GitHub permite compartir los archivos del proyecto, las migraciones SQL, la documentación y los cambios realizados.

Las configuraciones locales y las contraseñas no se comparten mediante Git.

Para comenzar a trabajar en una computadora nueva:

1. Clonar el repositorio.
2. Crear el archivo `.env` a partir de `.env.example`.
3. Configurar las variables locales.
4. Ejecutar `docker compose up -d`.
5. Verificar que PostgreSQL esté saludable.

---

**Proyecto:** Bodegas del Atuel
**Trabajo:** Integrador de Bases de Datos
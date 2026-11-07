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

## 4. Iniciar PostgreSQL

Desde la carpeta raíz del proyecto, ejecutar:

```powershell
docker compose up -d
```

Este comando crea e inicia el contenedor de PostgreSQL en segundo plano.

### 4.1. Verificar el estado del servicio

```powershell
docker compose ps
```

El servicio debe aparecer con estado `healthy`.

### 4.2. Consultar los registros

```powershell
docker compose logs -f postgres
```

Para salir de la visualización de registros, presionar `Ctrl + C`. Esto no detiene el contenedor.

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

## 9. Organización del proyecto

```text
Bodegas-del-Atuel/
│
├── db/
│   └── migrations/
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

## 10. Trabajo colaborativo

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
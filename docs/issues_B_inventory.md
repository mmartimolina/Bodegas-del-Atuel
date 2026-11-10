# Inventario y trazabilidad de Issues tipo B

Fuente: Issues abiertas `#97`–`#126` del repositorio GitHub, identificadas por
los prefijos `B-39`–`B-68` de sus títulos. El filtro por etiqueta `B` no
devolvió Issues; los títulos son la fuente usada para identificar la categoría.
Se revisaron individualmente descripción, actividades, criterios de aceptación
y comentarios. Las Issues no tienen comentarios. No se modificarán ni cerrarán
automáticamente.

## Situación inicial

- Worktree rastreado limpio antes de los cambios.
- Stack actual: PostgreSQL 16, Docker Compose, SQL y utilidades Python.
- `api/` solo contiene configuración/entorno local ignorado; no contiene código
  versionado. No se debe leer ni alterar `api/.env`.
- No hay frontend ni manifiestos de dependencias de aplicación.
- Ya existen migraciones `db/migrations/001..013`, pruebas SQL en
  `db/tests/`, consultas individuales S1–S12 y D1–D6, documentación de
  trazabilidad RN-01..RN-15 e índices.
- Se revisó la consigna PDF, en particular las secciones 8.1–8.5.

## Inventario priorizado

| Issue | Requisitos y criterio de aceptación | Dependencias declaradas | Áreas probables | Estrategia y verificación |
|---|---|---|---|---|
| [#97 B-39 — Elegir tecnología y crear estructura de la API](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/97) | Elegir y justificar lenguaje/framework, estructura modular en `api/`, ejecución local documentada, driver nativo y SQL propio; sin ORM/query builder. Aceptación: API ejecutable con estructura clara y decisión documentada. | Esquema e interfaz DB. | `api/`, docs, README | Implementar API Python/FastAPI modular con psycopg; validar importación, arranque y OpenAPI. |
| [#98 B-40 — Implementar conexión PostgreSQL, pool y endpoint /salud](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/98) | Pool, configuración de entorno, rol API, `GET /salud` comprobando DB y `.env.example` sin secretos. Aceptación: rol correcto y disponibilidad real. | B-39, A-34 | `api/`, `.env.example`, Compose, README | Pool psycopg; usar rol `bodegas_api`; pruebas de DB disponible/indisponible. |
| [#99 B-41 — Crear capa propia de acceso a datos con SQL parametrizado](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/99) | Repositorios por recurso, función por consulta, parámetros separados, sin SQL en controladores ni concatenación de entrada. Aceptación: SQL visible y parametrizado. | B-40 | `api/app/repositories/`, tests | Queries SQL explícitas con parámetros; test de filtro malicioso y revisión de consultas. |
| [#100 B-42 — Implementar endpoints de vinos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/100) | Listado paginado/filtrado por tipo, cepa, bodega, añada; detalle con composición/maridajes; alta, edición y baja con RN-14/RN-13. Aceptación: rutas del PDF y errores de reglas. | B-41, A-21/A-33 | API vinos, tests | CRUD transaccional con reglas en DB; pruebas positivas, filtros, composición inválida, auditoría y FK. |
| [#101 B-43 — Implementar CRUD de clientes y sus subtipos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/101) | CRUD de `/clientes` para Socio, Distribuidor y Exportador; zona/habilitación, país/permisos, descuentos y restricciones. Aceptación: jerarquía/reglas coherentes. | A-06, B-41 | API clientes, tests | Transacciones para supertipo/subtipo; probar subtipos y restricciones. |
| [#102 B-44 — Implementar creación y consulta de comprobantes](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/102) | `POST /comprobantes`, `GET /comprobantes/{nro}`; cabecera y renglones en una transacción, rollback ante error, importes/descuento/stock desde DB. | A-24/A-25, B-41 | API ventas, repositorios, tests | Inserción atómica usando funciones/triggers DB; comprobar stock insuficiente y ausencia de venta parcial. |
| [#103 B-45 — Implementar endpoints de transferencias e ingresos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/103) | Ciclos de transferencia/ingreso, alta, renglones, terminar y procesar; procedures PostgreSQL, sin actualizar stock desde API. | A-26/A-27/A-28, B-41 | API movimientos, tests | Transacciones para cabeceras/renglones y llamadas `CALL`; probar estados inválidos y stock. |
| [#104 B-46 — Implementar endpoints de reportes](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/104) | Reportes top-vinos, ventas-por-sala, sin-stock, transportista-activo y trazabilidad por código; solo lectura. Aceptación: JSON acorde a consultas aprobadas. | Consultas B-27..B-38, vistas A-33 | API reportes, tests | Queries SQL parametrizadas alineadas a S1/S6/S7/S8/S9; probar argumentos y resultados. |
| [#105 B-47 — Traducir errores SQLSTATE a respuestas HTTP](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/105) | Mapear `23505`, `23503`, `23514`, `23502`, `P0001`, `22P02`, `40001`, `40P01`; ocultar detalles internos. | B-42..B-46 | API errores, tests | Handler central tipado; pruebas de cada clase de error y respuesta sin secretos. |
| [#106 B-48 — Completar pruebas automatizadas y demostración de inyección SQL fallida](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/106) | Ocho pruebas como mínimo, tres errores de regla con HTTP, stock, transición inválida, CHECK y texto malicioso parametrizado. | B-42..B-47 | `api/tests/`, docs | Pruebas unitarias/DB de integración; validar HTTP y estado final, documentar inyección no efectiva. |
| [#107 B-49 — Documentar la API con OpenAPI/Swagger o Postman](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/107) | Rutas, métodos, esquemas, parámetros, ejemplos válidos/ inválidos, paginación, errores SQLSTATE; coincide con API implementada. | B-42..B-48 | API OpenAPI, docs | OpenAPI generado desde FastAPI y comprobado contra rutas/tests. |
| [#108 B-50 — Diseñar bocetos de las cinco pantallas](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/108) | Bocetos de catálogo, alta/edición, venta, transferencias y tablero; identificar endpoints. Aceptación: cinco bocetos y flujo claro. | Definición endpoints API | `docs/frontend/` | Bocetos estáticos con llamadas a API indicadas; revisar cobertura de cinco flujos. |
| [#109 B-51 — Crear estructura del frontend y cliente HTTP de API](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/109) | App en `front/`, base URL configurable, cliente HTTP y errores centralizados; sin cálculos de stock/importes. | B-50 | `front/`, docs | Cliente nativo JS con configuración por entorno; validar solicitudes y errores. |
| [#110 B-52 — Implementar catálogo de vinos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/110) | Listado paginado, filtros tipo/cepa/bodega/añada, composición/maridajes y estados carga/vacío/error. Filtros en backend. | B-42, B-51 | `front/` catálogo | UI contra API real; pruebas de interacción/filtros y estados. |
| [#111 B-53 — Implementar alta y edición de vinos con composición](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/111) | Formulario, añadir/quitar cepas y porcentajes, enviar API, mostrar error de porcentaje no válido desde DB/API. | B-42, B-51 | `front/` vinos | Formularios con edición y mensajes de error del backend; probar composición inválida. |
| [#112 B-54 — Implementar pantalla de nueva venta](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/112) | Elegir cliente/sala, varios vinos/cantidades, enviar venta atómica, mostrar total backend y error de stock sin venta parcial. | B-44, B-51 | `front/` venta | UI consume ventas API; probar éxito y stock insuficiente. |
| [#113 B-55 — Implementar pantalla de transferencias](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/113) | Crear transferencia, renglones, estado y acciones según transición; errores de stock/estado. No gestionar stock en UI. | B-45, B-51 | `front/` transferencias | UI llama API y usa estado del servidor; probar transición válida/inválida. |
| [#114 B-56 — Implementar tablero de indicadores](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/114) | Top 10, ventas del último trimestre por sala y vinos sin stock para sala elegida; solo endpoints reportes. | B-46, B-51 | `front/` dashboard | Tres vistas con datos API reales; validar filtros y vacíos. |
| [#115 B-57 — Integrar frontend en Docker Compose](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/115) | Servicios DB/API/frontend, URL API de contenedores, comunicación y puertos documentados. Aceptación: `docker compose up` y cinco pantallas en API real. | B-52..B-56, configuración API | Compose, Dockerfiles, README | Validar Compose y healthchecks; smoke test de API y frontend local. |
| [#116 B-58 — Redacción del manual y guía de respaldo y restauración en la nube](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/116) | Comandos PostgreSQL exactos, protocolo reproducible de restauración y guía en docs; sin cambios de esquema. | Ninguna declarada | `docs/`, README | Instrucciones `pg_dump`/`pg_restore` con variables, prueba en DB separada. |
| [#117 B-59 — Estructuración de la tabla de trazabilidad de reglas de negocio](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/117) | Trazar RN-01..RN-15 a constraints/funciones/triggers/procedures y archivo de pruebas; integrar al informe. | Ninguna declarada | `docs/auditorias/`, informe | Revisar cada regla y enlazar mecanismo/pruebas existentes. |
| [#118 B-60 — Configuración de herramientas de análisis estático y estilo de código](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/118) | Configurar estilo/análisis estático y documentar comandos de verificación en README. | Ninguna declarada | configuración, README | Configurar Ruff para Python; ejecutar formatter/lint sobre API. |
| [#119 B-61 — Redacción de la estructura base e introducción del informe final en la carpeta](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/119) | Plantilla Markdown con introducción, alcance y roles; reservas para resultados/diagramas posteriores. | Ninguna declarada | `docs/informe_final.md` | Crear plantilla formal y verificar que incluya secciones pedidas sin afirmar resultados no medidos. |
| [#120 B-62 — Documentación de variables de entorno y parámetros de configuración](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/120) | `.env.example` completo para API/containers y manual por variable; sin credenciales reales. | Ninguna declarada | `.env.example`, README | Agregar placeholders no sensibles y contrastarlos con configuración Compose/API. |
| [#121 B-63 — Diseño y estructuración del plan de medición de rendimiento para índices](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/121) | Seleccionar consultas costosas sección 8; tabla de tiempos, escaneo y filas antes/después; documentar sin tocar diseño físico. | Ninguna declarada | `docs/modelo/15_rendimiento_indices.md` | Completar plan reproducible, usar EXPLAIN/ANALYZE y no inventar mediciones. |
| [#122 B-64 — Automatización del script de validación de conteos para la carga de datos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/122) | Conteos mínimos por tabla y detección automatizada de huérfanos/desfasajes. | Ninguna declarada | `db/seed/`, SQL de validación | Script de solo lectura y comprobaciones de conteos/FK; probar con dataset migrado. |
| [#123 B-65 — Documentación de las sentencias de inserción de datos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/123) | `consultas/insert.sql` con I1–I6, encabezados, enunciados, estrategias y datos coherentes. | Ninguna declarada | `consultas/insert.sql`, scripts I1–I6 | Implementar las dos consignas faltantes, integrar las existentes y validar SQL en transacciones aisladas. |
| [#124 B-66 — Documentación de las sentencias de modificación de datos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/124) | `consultas/update.sql` con U1–U6, datos concretos, comentarios, pruebas antes/después y `ROLLBACK`. | Ninguna declarada | `consultas/update.sql`, migración RN-06, tests | Alinear descuentos con reglas vigentes; cubrir exportadores con >3 permisos y ejecutar solo en DB temporal. |
| [#125 B-67 — Documentación de las sentencias de borrado de datos](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/125) | `consultas/delete.sql` con D1–D6, transacciones seguras, acciones referenciales y explicación técnica/impacto. | Ninguna declarada | `consultas/delete.sql`, seis scripts D | Integrar scripts existentes, revisar restricciones y hacer `ROLLBACK` por defecto. |
| [#126 B-68 — Redacción y organización de las consultas de selección y analíticas](https://github.com/mmartimolina/Bodegas-del-Atuel/issues/126) | `consultas/select.sql` con S1–S12, códigos/enunciados, explicación, CTE, ventanas, división relacional y preparación EXPLAIN. | Ninguna declarada | `consultas/select.sql`, doce scripts S | Integrar consultas existentes y revisar SQL, marcadores de parámetros y EXPLAIN. |

## Orden técnico de ejecución

1. Verificar los entregables SQL/documentales existentes y completar las
   consultas B-63..B-68 seguras para reproducción.
2. Construir API y acceso DB: B-39..B-41; luego recursos/errores B-42..B-47.
3. Cubrir API con pruebas y OpenAPI: B-48..B-49.
4. Completar bocetos y frontend B-50..B-56, una vez acordado el contrato HTTP.
5. Integrar servicios y configuración B-57..B-62.
6. Ejecutar validación integral y actualizar la trazabilidad con resultados
   observados. No se marcará como completada una Issue no verificada.

## Estado de ejecución

La implementación se incorporó en el worktree, pero ninguna Issue se cerró en
GitHub. “Pendiente” significa que falta ejecutar la verificación de aceptación
integral o que el entorno impidió realizarla; no implica que no haya cambios.

| Issue | Trabajo incorporado | Verificación ejecutada | Pendiente |
|---|---|---|---|
| #97 B-39 | API FastAPI modular, psycopg y SQL propio; `api/`, Dockerfile y documentación técnica en README. | API importada por pytest y sus rutas OpenAPI respondieron en ASGI. | Build de imagen y arranque local completo. |
| #98 B-40 | Pool PostgreSQL, configuración de entorno, rol `bodegas_api`, `/salud`, Compose y `.env.example`. | Test de `/salud` confirma la consulta `SELECT 1` mediante conexión sustituida; Compose valida. | Healthcheck conectado a PostgreSQL real. |
| #99 B-41 | Repositorios SQL por recurso, con valores parametrizados. | Test de búsqueda comprueba que la entrada de inyección permanece en parámetros, no en SQL. | Revisión/ejecución de todas las consultas contra PostgreSQL. |
| #100 B-42 | CRUD de vinos con filtros, paginación, composición, maridajes y baja sujeta a FK. | Tests HTTP de filtros, alta, límite y discrepancia de código al editar. | Reglas SQL, auditoría de precio y baja con dependencias en DB real. |
| #101 B-43 | CRUD de clientes y subtipos, con permisos de exportación. | Compilación/importación y ruta en OpenAPI. | Casos DB positivos/negativos por subtipo y permisos. |
| #102 B-44 | Alta/consulta transaccional de comprobantes; cálculo y stock permanecen en PostgreSQL. | Tests HTTP de duplicados y traducción de una violación de stock simulada. | Venta/rollback y concurrencia contra PostgreSQL. |
| #103 B-45 | Endpoints de ingresos y transferencias, renglones, estados y procedimientos SQL. | Ruta de transición incluida en OpenAPI; test de error de transición simulado. | Flujo completo, estados y stock contra PostgreSQL. |
| #104 B-46 | Cinco reportes en repositorio y endpoints JSON. | Test de presencia del endpoint de trazabilidad en OpenAPI. | Ejecutar consultas y validar resultados con datos. |
| #105 B-47 | Handler central SQLSTATE→HTTP sin exponer texto interno. | Tests ejecutados para `23505`, `23514`, `P0001` y `40001`. | Pruebas contra excepciones SQL reales y estado de conexión caído. |
| #106 B-48 | Suite de 13 pruebas HTTP/unitarias y demostración de parametrización contra inyección. | `pytest`: 13 aprobadas. | Integración con DB: stock sin venta parcial, transición, CHECK y restricciones reales. |
| #107 B-49 | OpenAPI de FastAPI, guía `docs/api.md`, ejemplos, paginación y catálogo SQLSTATE. | Test comprueba que OpenAPI publica rutas clave. | Smoke test del servidor publicado. |
| #108 B-50 | Cinco bocetos y relación pantalla-endpoint en `docs/frontend/wireframes.md`. | Revisión del documento. | Ninguna verificación automatizada requerida; validar con usuarios/equipo si corresponde. |
| #109 B-51 | Frontend estático, URL configurable, cliente HTTP y manejo central de errores. | `node --check front/app.js`. | Pruebas en navegador contra la API. |
| #110 B-52 | Catálogo filtrable/paginado, detalle y estados de carga/vacío/error. | `node --check front/app.js`. | Pruebas de interacción con datos reales. |
| #111 B-53 | Formularios de alta/edición, composición dinámica y maridajes. | `node --check front/app.js`. | Verificar validación de composición en DB y respuestas HTTP desde navegador. |
| #112 B-54 | Venta con búsqueda de clientes, varias etiquetas y total recibido del servidor. | `node --check front/app.js`; tests API unitarios parciales. | Venta y rollback de stock insuficiente end-to-end. |
| #113 B-55 | Flujo de transferencia guiado por estado del servidor. | `node --check front/app.js`; test de error HTTP simulado. | Flujo y errores con PostgreSQL real. |
| #114 B-56 | Tablero con top 10, ventas trimestrales y vinos sin stock por sala. | `node --check front/app.js`. | Validación visual y datos reales. |
| #115 B-57 | Compose con PostgreSQL, API y frontend, migraciones de inicio y healthchecks. | `docker compose config --quiet` pasó con `.env` temporal derivado del ejemplo. | Build/smoke test bloqueado porque Docker Hub no respondió; no se inició Compose ni se tocó el volumen persistente. |
| #116 B-58 | Guía reproducible de `pg_dump`/`pg_restore` en `docs/backup_restore.md`. | Revisión de comandos/documentación. | Ensayo real de restauración en una base aislada. |
| #117 B-59 | Matriz RN-01..RN-15 integrada al informe; RN-06 refleja migración U6 y test pendiente. | Revisión documental. | Volver a ejecutar la suite DB y renovar evidencia histórica. |
| #118 B-60 | `.editorconfig`, Ruff y pytest en `pyproject.toml`; comandos documentados. | Pylance no reportó errores en `api/`. | Ruff no pudo instalarse por timeout de PyPI; lint/formatter no ejecutados. |
| #119 B-61 | Plantilla del informe con introducción, alcance y roles. | Revisión documental. | Completar datos del equipo y resultados cuando existan. |
| #120 B-62 | `.env.example` y guía por variable en `docs/configuracion.md`. | Comparación con `config.py` y Compose; configuración Compose válida. | Sustituir placeholders localmente, sin versionar secretos. |
| #121 B-63 | Plan/informe de rendimiento existente con consultas, métricas y análisis antes/después. | Evidencia medida ya registrada en el documento; no se repitió en esta sesión. | Reproducir benchmark en DB temporal para renovar la evidencia. |
| #122 B-64 | `db/seed/validar_carga.sql`: conteos mínimos y búsqueda dinámica de FK huérfanas. | Revisión estática. | Ejecutar contra el dataset; instancia PostgreSQL temporal no disponible. |
| #123 B-65 | Agrupador `consultas/insert.sql` para I1–I6 y ajustes a scripts vinculados. | Revisión estática; no se ejecutó SQL. | Ejecutar cada consigna en DB temporal y validar datos. |
| #124 B-66 | Agrupador U1–U6, cálculo con descuentos históricos, migración U6 y test SQL. | 13 tests API no cubren la DB; scripts SQL no ejecutados. | Ejecutar el test de tres/cuatro permisos y las actualizaciones en DB temporal. |
| #125 B-67 | Agrupador D1–D6 con opt-in explícito `apply_deletes=true`. | Revisión estática; ningún borrado ejecutado. | Probar dependencias/impacto únicamente en DB desechable. |
| #126 B-68 | Agrupador `consultas/select.sql` para S1–S12. | Revisión estática; no se ejecutó SQL. | Ejecutar consultas y EXPLAIN con dataset temporal. |

### Resultado global de validación

- Issues identificadas: **30** (#97–#126).
- Issues completamente resueltas y verificadas contra todos sus criterios:
  **0**. No se declaran terminadas sin pruebas de aceptación completas.
- Issues con implementación o documentación incorporada: **30**.
- Issues pendientes de una o más verificaciones de aceptación: **30**.
- Issues bloqueadas por disponibilidad del entorno: pruebas de DB y build de
  contenedores, por falta de imagen PostgreSQL local y timeout al consultar
  Docker Hub; Ruff tampoco pudo descargarse desde PyPI.
- Validaciones observadas: **13 pruebas API aprobadas**, `node --check`,
  `docker compose config --quiet`, `git diff --check` y diagnósticos Pylance
  sin errores para `api/`.
- No se ejecutó la suite SQL, lint/formatter, build Docker ni prueba visual.
- No se modificaron/cerraron Issues, no se crearon commits, PRs ni merges, y no
  se inició ningún servicio sobre el volumen persistente del proyecto.

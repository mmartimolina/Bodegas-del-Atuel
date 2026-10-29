# Bodegas del Atuel — Análisis de requisitos

> Fuente: `docs/Consigna/TPI_Bodegas_del_Atuel.pdf` (29 páginas; la carpeta real es `Consigna` con mayúscula).
> Convención de marcado:
> - Texto normal = requisito **explícito** del PDF (con la sección de origen; véase nota sobre páginas).
> - `[Inferencia]` = interpretación nuestra, no textual del PDF.
> - `[Pregunta]` = tema a consultar al docente.
> - `[Docente]` = indicaciones de cátedra recibidas fuera del PDF (por ej. el equipo es de 2 integrantes).
>
> Nota sobre páginas: el orden de extracción del PDF no permite verificar números de página con
> certeza, por lo que se cita la **sección numerada** del documento como referencia principal.

---

## 1. Descripción del negocio y contexto

- **Trabajo:** Trabajo Práctico Integrador (TPI) de Bases de Datos, UTN Facultad Regional San Rafael, año 2026 (3.° año). Título: «Sistema de gestión y distribución de una empresa vitivinícola: "Bodegas del Atuel"» (carátula, p. 1).
- **Negocio:** empresa vitivinícola que integra la **producción de uva y de vino** con su **distribución y venta** a través de una **red de salas de venta** en distintas localidades (sección 3).
- **Enfoque del TPI:** la base de datos es el corazón del sistema; la capa de datos pesa el 70 % de la nota (sección 9). «La API y el front son el medio para demostrar que la base funciona» (sección 1.2).
- **Datos del encabezado (carátula):**
  - Ciclo lectivo: 2026. Fecha de lanzamiento: 13/10/2026. Fecha de entrega final / defensa: «A definir».
  - Motor: PostgreSQL 14 o superior. Acceso a datos: SQL directo con driver nativo; **prohibido ORM**.
  - Modalidad grupal con roles rotativos: [Pregunta] el PDF indica **grupos de 3 a 4 integrantes** (carátula y sección 2.1), pero el equipo real es de **2 estudiantes**.

## 2. Procesos principales

- **Cadena productiva:** cultivo en fincas divididas en parcelas; cosecha por campaña (año) que genera lotes de uva; análisis de calidad de cada lote; entregado a una bodega, elaborado como vino, distribuido a salas de venta y vendido a clientes socios/distribuidores/exportadores. (Secciones 3.2–3.4.)
- **Gestión de salas de venta:** cada localidad tiene un encargado regional único y una o más salas; los empleados pertenecen a una sola sala (sección 3.1).
- **Ventas en sala:** comprobante con cabecera y renglones (vino, cantidad, precio unitario al momento de la venta, descuento según tipo de cliente y subtotal del renglón); el stock de la sala se descuenta al vender y un trigger valida que no se venda sin stock suficiente. (Sección 3.4, RN-08 y RN-09.)
- **Aprovisionamiento:**
  - **Ingresos** a depósito central desde bodegas, con estado `en_confeccion → terminado → procesado`; solo un ingreso terminado afecta al stock; tras impactar pasa a `procesado` y **no retrocede**. (Sección 3.5, RN-10.)
  - **Transferencias** desde depósito central a salas que las solicitan, mismas modalidades de estado; al procesarse se descuenta del stock del depósito y suma al de la sala; no se puede procesar sin stock suficiente en depósito. (Sección 3.5, RN-11.)
- **Comercialización:** el precio de venta es el mismo para todas las salas; el descuento depende del tipo de cliente: socios del club 10 %, distribuidores 20 %, exportadores 30 %. (Sección 3.4, RN-01 y RN-06.)
- **Logística:** transportistas externos que cubren determinadas localidades. (Sección 3.5, entidad "Transportista cubre localidad".)

## 3. Requisitos funcionales y técnicos

Desde el encabezado técnico (secciones 1 y 6) y etapas del proyecto (sección 7):

- Motor de BD: **PostgreSQL ≥ 14**.
- Herramienta de modelado: draw.io / dbdiagram.io / pgModeler u similares; entregar imagen/PDF y fuente.
- Cliente SQL: psql, DBeaver o pgAdmin.
- Repositorio Git (GitHub o GitLab), **commits de todos los integrantes**, rama por etapa y revisión cruzada recomendadas.
- Docker + Docker Compose: **un solo comando debe levantar BD + API + front** en local.
- Carga masiva con Python (Faker, random) y catálogos reales desde CSV (o herramienta equivalente) con semilla fija para reproducibilidad.
- API REST con JSON, lenguaje a elección, documentada con OpenAPI/Swagger o colección Postman. **Prohibido ORM y query builders que oculten el SQL** (sección 6 y 1.2).
- Front libre (HTML/CSS/JS, React, Vue, etc.), que consume **únicamente la API**.
- Elemento central: la lógica de las reglas de negocio debe vivir **dentro de la base** (constraints, funciones, procedimientos, triggers, vistas, roles) y no en la API (secciones 1.2, 6 y regla de oro).
- **Transacciones/concurrencia:** el PDF exige en etapa 2 una demostración de concurrencia con dos sesiones psql (sección 7, etapa 2, paso 8), con `FOR UPDATE` y explicación del nivel de aislamiento. [Docente] La cátedra ya **no ha visto transacciones** en clase y esa demostración es **opcional** para el grupo. [Pregunta] Confirmar si queda exigida bajo esa condición.
- Criterios generales (sección 1.2): se evalúa la calidad del diseño, la corrección de las reglas implementadas, la evidencia de rendimiento, el dominio de SQL y la capacidad de **explicar y defender cada decisión**; no se exige diseño visual sofisticado ni autenticación compleja (puede sumarse como extra).

## 4. Reglas de negocio (sección 4)

| N.° | Regla | Mecanismo esperado (PDF) |
|----|-------|------------------------|
| **RN-01** | Precio de un vino único para toda la red y siempre mayor que cero. | Atributo en vino + CHECK |
| **RN-02** | Una sala pertenece a una sola localidad. Cada localidad tiene un único encargado regional. | FK + diseño normalizado (3FN) |
| **RN-03** | Cada empleado trabaja en una sola sala. | FK NOT NULL |
| **RN-04** | Una parcela tiene una sola cepa y se cosecha como máximo una vez por campaña. | FK + UNIQUE (parcela, campaña) |
| **RN-05** | Porcentajes de corte de un vino suman exactamente 100. | Constraint trigger diferido |
| **RN-06** | El descuento depende del tipo de cliente: socio 10 %, distribuidor 20 %, exportador 30 %. | Función de descuento + CHECK de rango |
| **RN-07** | Un exportador puede tener varios permisos; vencimiento posterior a emisión. | Tabla de permisos + CHECK entre columnas |
| **RN-08** | El total del comprobante es la suma de sus renglones con el descuento aplicado. No se carga a mano. | Función de cálculo + trigger |
| **RN-09** | No se puede vender más de lo que hay en stock de la sala. El stock nunca es negativo. | Trigger BEFORE INSERT + CHECK (cantidad >= 0) |
| **RN-10** | Solo un ingreso terminado impacta en el depósito, pasa a procesado y no retrocede. | Tipo ENUM + trigger de estados + procedimiento |
| **RN-11** | Igual que RN-10, para transferencias. La fecha de confección es la actual y no se puede modificar. | Trigger de estados y de fecha + procedimiento |
| **RN-12** | Un ingreso o transferencia que no está en confección no admite agregar, modificar ni quitar renglones. | Trigger sobre los renglones |
| **RN-13** | Todo cambio de precio de un vino queda auditado (fecha, usuario, precio anterior y nuevo). | Trigger AFTER UPDATE + tabla de auditoría |
| **RN-14** | No se puede borrar un transportista, bodega ni vino con movimientos asociados. | FK con ON DELETE RESTRICT |
| **RN-15** | Cantidades, superficies, kilos y precios son siempre positivos. Graduación entre 5 y 20. | CHECK |

Condiciones del PDF sobre reglas de negocio:

- Cada regla debe estar protegida por **al menos un mecanismo en la base** (constraint, función, procedimiento o trigger) y el grupo debe poder **señalar cuál es** (sección 4).
- En el archivo de pruebas de la etapa 2 debe existir **al menos un caso por regla** (mismo punto).
- Guía «¿dónde va cada regla?» (sección 7, etapa 2, guía del PDF): validación de fila con restricciones (NOT NULL/CHECK/DOMAIN), existencia con FK, unicidad con UNIQUE/PK, dependencia de otras filas o de la fecha actual con triggers, cálculo con funciones, operación todo-o-nada con procedimiento transaccional, y formato/UX/autorización con API y front.

## 5. Integridad y restricciones de datos

### 5.1 Entidades mínimas y atributos (sección 5)

| Entidad | Atributos principales | Observación |
|---------|----------------------|-------------|
| Localidad | Código postal, nombre, provincia, encargado regional | El encargado depende de la localidad |
| Sala de venta | ID, calle, número, día de cierre, localidad | |
| Empleado | CUIT, nombre, fecha de ingreso, salario, sala | |
| Finca | ID, nombre, superficie (ha), departamento, provincia | |
| Parcela | N° parcela, finca, superficie, año de plantación, cepa | **Entidad débil**: clave (finca, n° parcela) |
| Cepa | ID, nombre, tipo (tinta/blanca) | Catálogo real |
| Lote de uva | N° lote, parcela, campaña, fecha, kg, bodega destino | Una cosecha por parcela y campaña |
| Análisis de calidad | ID, lote, fecha, Brix, pH, acidez | Varios por lote |
| Bodega | CUIT, razón social, domicilio | |
| Vino | Código, nombre, tipo, añada, volumen (ml), graduación, precio, bodega | Un vino lo elabora una bodega |
| Composición (vino–cepa) | Vino, cepa, porcentaje | N:M con atributo; suma 100 por vino |
| Maridaje | ID, nombre, temperatura de servicio | Catálogo |
| Vino–maridaje | Vino, maridaje | N:M |
| Cliente | ID, nombre o razón social, tipo y n° doc, dirección, localidad, fecha de alta, descuento | **Supertipo de jerarquía con 3 subtipos** |
| Socio / Distribuidor / Exportador | Datos propios (cada uno) | Estrategia de mapeo a definir y justificar |
| Permiso de exportación | Código, exportador, fecha de emisión, fecha de vencimiento | Varios por exportador |
| Comprobante | Número, fecha, cliente, sala, subtotal, descuento, total | |
| Renglón de comprobante | Comprobante, vino, cantidad, precio unitario, descuento, subtotal | Clave (comprobante, vino) |
| Transportista | Código, razón social, CUIT, e-mail, teléfono, domicilio | |
| Transportista–cubre–localidad | Transportista, localidad | N:M |
| Ingreso / renglón de ingreso | Código, fecha, estado, transportista, bodega; vino y cantidad | Estado con ENUM |
| Transferencia / renglón | N°, sala, fecha de confección, estado; vino y cantidad | Estado con ENUM |
| Stock de sala | Sala, vino, cantidad | Clave (sala, vino); cantidad >= 0 |
| Stock de depósito | Vino, cantidad | Uno solo, cantidad >= 0 |
| Auditoría de precio | ID, vino, precio anterior, precio nuevo, fecha y hora, usuario | La completa un trigger |

### 5.2 Mínimos de restricciones (sección 7, etapa 2)

| Elemento | Mínimo exigido | Ejemplos del PDF |
|---|---|---|
| PRIMARY KEY | En todas las tablas | Claves compuestas en renglones y stock |
| FOREIGN KEY | Todas las relaciones, con `ON DELETE` / `ON UPDATE` elegidos y justificados | RESTRICT en vino, bodega, transportista; CASCADE en renglones |
| NOT NULL | En todo atributo obligatorio | Fecha, cantidad, precio, estado |
| UNIQUE | **4** adicionales a las PK | (nombre, añada, volumen) en vino; (parcela, campaña) en lote; CUIT de bodega |
| CHECK | **8** restricciones, al menos una **entre columnas** | cantidad > 0; precio > 0; graduación 5–20; vencimiento > emisión; stock >= 0 |
| DEFAULT | 3 valores por defecto | Estado inicial `en_confeccion`; fecha de alta actual |
| Tipos propios | 1 ENUM y 1 DOMAIN | `estado_documento`; DOMAIN CUIT de 11 dígitos |
| Funciones | 4 | fn_total_comprobante, fn_stock_sala, fn_descuento_cliente, fn_antiguedad_anios |
| Procedimientos | 2 (transaccionales) | sp_procesar_ingreso, sp_procesar_transferencia |
| Triggers | 6 con propósitos distintos: al menos 1 BEFORE, 1 AFTER y 1 constraint trigger diferido | Validar stock (RN-09), stock+totales (RN-08/09), estados (RN-10/11), bloqueo de renglones (RN-12), fecha de transferencia (RN-11), auditoría de precio (RN-13), suma de cortes (RN-05, deferred) |
| Vistas | 3 (una puede ser materializada) | Stock total por vino, ventas mensuales por sala, documentos pendientes |
| Roles | 3: propietario, lectura/escritura API, solo lectura reportes | REVOKE de public + GRANT mínimos |

- Los **atributos derivados** (subtotales, totales, descuento) deberán decidirse cuáles se guardan y cuáles se calculan, con justificación de consistencia (sección 5, «decisiones de diseño»).
- Ejemplo: vino con `UNIQUE (nombre, anada, volumen_ml)`; stock con `CHECK (cantidad >= 0)` (Anexo A.2).
- Tipos de datos recomendados: dinero con `NUMERIC(p,s)` (nunca `FLOAT`); fechas con `DATE` o `TIMESTAMP`; estados con tipos enumerados. **Ningún importe usa FLOAT; los estados no son texto libre** (criterio de aceptación etapa 1).
- Acciones referenciales a decidir y justificar (sección 5): qué `ON DELETE` / `ON UPDATE` por FK; `RESTRICT` en movimientos, `CASCADE` en renglones que no existen sin cabecera, es la sugerencia del PDF.
- Advertencia del PDF (etapa 2, «Atención»): **no usar `CURRENT_DATE` ni otras funciones no determinísticas dentro de un `CHECK`**: «el resultado cambia con el tiempo y se rompe al restaurar un backup. Las reglas que dependen de la fecha actual van en un trigger».
- Etapa 2, paso 2 (requisito del PDF): cada función se implementa en `003_funciones.sql` **con un comentario que indique su propósito, sus parámetros y si es `STABLE` o `IMMUTABLE`**.

> [Pregunta] La fila UNIQUE del PDF exige 4 restricciones adicionales a las PK, pero lista solo 3 ejemplos: (nombre, añada, volumen_ml) en vino; (parcela, campaña) en lote; y CUIT de bodega. ¿Cuál sería la cuarta, o los 3 son orientativos?

## 6. Carga y volumen de datos de prueba

- Requisitos mínimos (sección 7, etapa 3):
  - **Todas** las tablas con al menos 1 fila.
  - Al menos **3 tablas con más de 10.000 filas**.
  - Al menos **1 tabla con más de 100.000 filas**.
  - Recomendación del PDF: renglón de comprobante ≈ **500.000** filas.

- Volúmenes recomendados por tabla (ídem):
  - Localidad, cepa, maridaje, bodega, transportista, transportista-cubre-localidad: 10–60 (catálogos reales).
  - Sala de venta, finca, empleado: 15–150.
  - Parcela, vino, composición, vino–maridaje, stock de depósito: 300–1.000.
  - Ingreso, transferencia, stock de sala: 500–5.000.
  - Renglón de ingreso, renglón de transferencia, lote de uva, análisis de calidad: 3.000–15.000.
  - Cliente: **20.000**.
  - Comprobante: **150.000**.
  - Renglón de comprobante: **500.000 o más**.

- Procedimiento pedido (pasos de etapa 3):
  1. Cargar catálogos reales desde CSV (Anexo B: cepas, maridajes, departamentos de Mendoza, tipos de vino y volúmenes habituales).
  2. Orden de carga según dependencias FK; dibujarlo en el informe.
  3. Script de carga con Python + psycopg + Faker + random, con **semilla fija** (reproducible: dos ejecuciones → mismos datos).
  4. Datos coherentes: cosecha → elaboración → ingreso → venta (fechas lógicas); porcentajes que suman 100; descuentos según tipo cliente; stocks nunca negativos.
  5. Decidir cómo cargar el historial sin chocar con los triggers (p. ej. `ALTER TABLE ... DISABLE TRIGGER` y controlar resultado) y documentar la decisión y sus riesgos.
  6. Carga eficiente: lotes con `execute_values`/`executemany` o `COPY`; **comparar tiempos** fila-a-fila vs por lotes.
  7. Validar con **consultas de control**: conteos por tabla, filas huérfanas, stock negativo, comprobantes cuyo total no coincide con la sumatoria de renglones.
  8. Generar `dump_completo.sql.gz` (si pesa demasiado, incluir instrucciones para generarlo).
- Entregables de etapa 3: `db/seed/` con CSV + script de carga + README de ejecución; reporte con conteos, tiempos y resultados de las consultas de control; volcado.
- Criterios de aceptación (etapa 3): se cumplen los mínimos, la semilla es reproducible, no hay inconsistencias en las validaciones, se compara la carga fila-a-fila vs por lotes y está documentado el manejo de triggers.
- Catálogos sugeridos del Anexo B: 7 cepas tintas (Malbec, Cabernet Sauvignon, Merlot, Syrah, Bonarda, Tempranillo, Pinot Noir) + 5 blancas (Chardonnay, Sauvignon Blanc, Torrontés, Chenin Blanc, Semillón); 8 maridajes de ejemplo con temperaturas; 18 departamentos de Mendoza; volúmenes: 187 ml, 375 ml, 750 ml, 1500 ml, 3000 ml; campañas: los últimos 5 años, con cosecha entre febrero y abril. (Anexo B.)

## 7. Consultas SQL, índices y rendimiento

### 7.1 Índices y mediciones (sección 7, etapa 4)

- Requisitos mínimos (etapa 4):
  - Al menos **5 índices** creados en `db/migrations/008_indices.sql` que incluyan:
    1. uno compuesto,
    2. uno parcial (con `WHERE`),
    3. uno sobre una clave foránea (PostgreSQL no indexa las FK automáticamente),
    4. uno de otro tipo o variante (de expresión, BRIN, o con `INCLUDE`; ejemplos del Anexo A.3);
    5. cada uno con su justificación.
  - Al menos **3 consultas medidas** con `EXPLAIN (ANALYZE, BUFFERS)` **antes y después** de crear los índices.
- Pasos de etapa 4:
  1. Elegir ≥ 3 consultas de la sección 8 involucrando muchas filas (p. ej. S1, S4, S8, S10).
  2. Medir solo con los índices automáticos de PK y UNIQUE y guardar plan y tiempo.
  3. Diseñar índices a partir de los planes (Seq Scan sobre tablas grandes, ordenamientos costosos, joins sin índice).
  4. Implementar en `008_indices.sql`, correr `ANALYZE` y repetir métricas.
  5. Armar tabla comparativa: tiempo antes/después, tipo de recorrido (Seq Scan / Index Scan / Bitmap Scan) y filas leídas.
  6. Justificar el orden de columnas del índice compuesto y mostrar un índice evaluado y descartado con motivo.
  7. Medir el **costo de escritura**: tiempo de carga masiva con y sin índices.
  8. Mostrar un caso en el que el planificador **no** usa un índice existente, con causa (p. ej. baja selectividad o estadísticas desactualizadas).
- Criterios de aceptación: `008_indices.sql` + informe con planes completos en anexo, tabla comparativa con mejora medida en ≥3 consultas, explicar por qué se descartó un índice y el costo de escritura de los creados.

### 7.2 Consultas requeridas (sección 8)

> «Todas las consultas deben resolverse en SQL de PostgreSQL y estar comentadas. Los valores concretos (nombres de bodega, sala, localidad, vino) se eligen del dataset cargado. Cuando la consigna dice "la última semana" o "el último trimestre" debe calcularse a partir de la fecha actual (`CURRENT_DATE`), no con fechas fijas.» (sección 8).

**UPDATE (sección 8.1):**

| Código | Consigna |
|-------|---------|
| U1 | Recalcular el total de todos los comprobantes aplicando el descuento del tipo de cliente |
| U2 | Aumentar 20 % el salario de empleados con más de 5 años de antigüedad |
| U3 | Incrementar 13 % el precio de los vinos elaborados por una bodega determinada |
| U4 | En las salas con cierre lunes cambiarlo a miércoles y viceversa, en una sola sentencia |
| U5 | Aplicar 15 % de descuento a los 10 vinos menos vendidos de la red |
| U6 | A los exportadores con más de 3 permisos, subirles el descuento a 35 % |

> [Pregunta] RN-06 fija un descuento general del 30 % para todos los exportadores, mientras que U6 pide subirlo al 35 % solo para exportadores con más de tres permisos de exportación. La consigna no aclara expresamente cómo se relacionan ambos casos (¿ajuste puntual sobre el descuento base, o caso especial permanente?). Interpretación pendiente de consulta al docente.

**INSERT (sección 8.2):**

| Código | Consigna |
|-------|---------|
| I1 | Insertar en la relación transportista-cubre-localidad una nueva cobertura que vincule la localidad de General Alvear con el transportista que menos ingresos haya trasladado en el último trimestre |
| I2 | Si existe algún vino tinto con graduación ≥ 14°, crear el maridaje «cordero al disco» y asociarlo a todos los vinos que cumplan esa condición |
| I3 | Crear un comprobante con 3 renglones para un cliente dado, en la sala con ID 1, dentro de una transacción y usando las funciones de cálculo |
| I4 | Insertar una nueva bodega |
| I5 | Insertar una nueva sala de venta |
| I6 | Crear un ingreso en confección de 120 botellas de un vino determinado (p. ej. «Malbec Reserva» de 750 ml), elaborado por una bodega dada y trasladado por un transportista dado |

**DELETE (sección 8.3):**

| Código | Consigna |
|-------|---------|
| D1 | Borrar los comprobantes con más de 5 años de antigüedad asociados a clientes socios del club |
| D2 | Eliminar las cepas que no componen ningún vino ni están plantadas en ninguna parcela |
| D3 | La sala de una localidad determinada fue dada de baja: eliminar los empleados de esa sala que trabajaron menos de dos años |
| D4 | Borrar los clientes socios que nunca compraron y se dieron de alta hace más de 5 años |
| D5 | Eliminar los ingresos en estado «procesado» de hace más de 365 días |
| D6 | Borrar los clientes socios sin compras que viven en una localidad específica |

**SELECT (sección 8.4):**

| Código | Consigna |
|-------|---------|
| S1 | Ranking de los 10 vinos con mayor cantidad de botellas vendidas en toda la red de salas |
| S2 | Listar códigos y nombres de los vinos que se vendieron en **todas** las salas (división relacional) |
| S3 | Cantidad de clientes de cada tipo que compraron en una sala determinada en la última semana |
| S4 | Top 5 de las salas que solicitaron mayor cantidad de un vino determinado mediante transferencias en los últimos 15 días |
| S5 | Listado de las salas con menor cantidad de transferencias pendientes (no procesadas) |
| S6 | Para una sala determinada, los vinos sin stock en la sala pero con stock en el depósito central |
| S7 | ¿Cuál es la empresa de transporte con mayor actividad en el último mes? |
| S8 | Monto total de ventas por sala en el último trimestre, en orden descendente |

**Consultas avanzadas (sección 8.5):**

| Código | Consigna | Herramienta esperada |
|-------|---------|--------------------|
| S9 | Ficha de un vino: cepas con porcentajes, bodega, maridajes, stock total (depósito + salas) | Joins, agregación y vista |
| S10 | Rendimiento kg/ha por parcela y campaña e identificar las que rinden menos que el promedio de su finca | CTE y subconsulta correlacionada |
| S11 | Ranking de vinos dentro de cada sala por botellas vendidas y ventas acumuladas mensuales | `RANK() OVER (PARTITION BY ...)` y suma acumulada con ventana |
| S12 | Clientes que compraron todos los vinos de una bodega y clientes que nunca compraron ningún vino tinto | `NOT EXISTS` (división) y anti-join |

- Pasos de etapa 5: archivos `consultas/insert.sql`, `update.sql`, `delete.sql`, `select.sql`, cada consigna con código, enunciado, consulta y explicación de la estrategia (joins, subconsultas, CTE, ventanas); probar sentencias de modificación dentro de una transacción (`BEGIN`/`ROLLBACK`), documentando cuántas filas se afectaron; usar valores concretos del dataset; anotar interacción con triggers y constraints; correr `EXPLAIN (ANALYZE)` en las consultas a optimizar y en S9–S12.
- Criterios de aceptación (etapa 5): consignas resueltas con explicación, estado antes/después y prueba transaccional en las sentencias de modificación, uso efectivo de CTE, ventanas, subconsultas correlacionadas y `NOT EXISTS` conforme a cada consulta.

## 8. API, interfaz, despliegue y seguridad

### 8.1 API REST (sección 7, etapa 6)

Requisitos (etapa 6):

- Acceso a base con driver nativo y **consultas parametrizadas** (nunca concatenar texto del usuario en el SQL).
- **Capa de acceso a datos propia**: un módulo con una función por consulta (el SQL no desparramado en los controladores).
- **Pool de conexiones** y manejo explícito de transacciones (`BEGIN`/`COMMIT`/`ROLLBACK`) cuando una operación involucra más de una sentencia.
- Conexión con el rol de lectura/escritura (no propietario), credenciales en variables de entorno y `.env.example` **sin secretos**.
- **Paginación** en listados y filtros en el catálogo de vinos (tipo, cepa, bodega, añada).
- Traducción de errores a códigos HTTP según SQLSTATE.
- Documentación OpenAPI/Swagger o colección Postman.
- Al menos **8 pruebas automáticas**, con al menos 3 que provoquen violación de una regla de la base y validen el código de respuesta.
- Demostrar una **inyección SQL fallida** (enviar un valor malicioso a un endpoint filtrado) con captura en el informe.

Endpoints mínimos:

| Recurso | Rutas |
|---|---|
| Vinos | GET `/vinos` / GET `/vinos/{cod}` (con filtros y paginación) / POST / PUT / DELETE |
| Clientes | CRUD completo sobre `/clientes` |
| Comprobantes | POST `/comprobantes` (cabecera + renglones en una sola transacción), GET `/comprobantes/{nro}` |
| Transferencias | POST `/transferencias`, POST `/transferencias/{nro}/renglones`, POST `/transferencias/{nro}/terminar`, POST `/transferencias/{nro}/procesar` (invoca el procedimiento) |
| Ingresos | POST `/ingresos`, POST `/ingresos/{cod}/renglones`, POST `/ingresos/{cod}/procesar` |
| Reportes | GET `/reportes/top-vinos`, `/ventas-por-sala`, `/vinos-sin-stock`, `/transportista-activo`, `/trazabilidad/{cod}` |
| Salud | GET `/salud` |

Mapeo de errores (sección 7, etapa 6):

| Situación | SQLSTATE | HTTP sugerido |
|---|---|---|
| UNIQUE violado | 23505 | 409 Conflict |
| FOREIGN KEY violada | 23503 | 409 Conflict o 422 |
| CHECK violado | 23514 | 422 Unprocessable Entity |
| NOT NULL violado | 23502 | 422 Unprocessable Entity |
| Regla rechazada por trigger / `RAISE EXCEPTION` | P0001 | 409 Conflict con el mensaje de la regla |
| Formato inválido para el tipo | 22P02 | 400 Bad Request |
| Deadlock / serialización | 40001 / 40P01 | 503 Service Unavailable con reintento |

**Regla de oro:** la API **no recalcula** totales, descuentos ni stock: llama a funciones y procedimientos de la base y deja que los triggers protejan las reglas, «así las reglas siguen valiendo aunque alguien acceda a la base directamente» (sección 6, «Regla de oro»).

### 8.2 Front (sección 7, etapa 7)

- Pantallas mínimas:
  - Catálogo de vinos (paginado con filtros por tipo/cepa/bodega/añada + detalle).
  - Alta y edición de vino (formulario con composición; muestra el error si los porcentajes no suman 100).
  - Nueva venta (cliente + sala + vinos; total calculado por el **backend**; muestra error de stock insuficiente).
  - Transferencias (crear, cargar renglones, cambiar de estado con botones habilitados según estado).
  - Tablero (ranking top-10 de vinos más vendidos, ventas por sala en el último trimestre con gráfico, y vinos sin stock por sala elegida).
- Requisitos: dibujar boceto simple, capa que concentre las llamadas a la API con base configurable, mostrar los mensajes de error tal como los devuelve la API (sin ocultarlos ni reemplazarlos por mensajes genéricos); verificar que el front **no calcula** totales/descuentos/stock; agregar front al `docker-compose.yml`.
- **El foco no es el diseño visual.**
- Criterios de aceptación: las 5 pantallas funcionan contra la API real; venta sin stock muestra el mensaje de la regla y no deja datos a medias; el front no contiene lógica de cálculo de importes ni de stock.

### 8.3 Despliegue en la nube (sección 7, etapa 8)

- Base PostgreSQL en la nube (servicio gestionado o servidor virtual con contenedor) y API + front con **URL pública HTTPS**.
- Migraciones aplicadas en la nube en orden desde los SQL del repositorio.
- Conexión a la base **cifrada** (`sslmode=require` o equivalente) y **puerto de la base no expuesto** a todo internet (restringir por IP o red interna).
- Secretos en variables de entorno del proveedor, **nunca en el repositorio** (ni en su historial).
- La API usa el **rol de privilegios mínimos**, no el propietario.
- **Backup y restauración probados**: backup con `pg_dump`, restauración en base nueva con `pg_restore`/`psql` y verificación de conteos.
- Datos: si el plan en la nube limita almacenamiento, se acepta una carga reducida (**≥ 10.000 filas en una tabla**) con justificación, manteniendo el volumen completo en la versión local.
- Proveedores de ejemplo: Neon, Supabase, Render, Railway, Fly.io, Aiven, planes educativos/free-tier de AWS/Azure/GCP, o VPS propio con Docker. Hay que comparar ≥ 2 proveedores y registrar la decisión y límites del plan en el informe (los límites cambian; verificar en el sitio del proveedor).
- Pasos de etapa 8: crear DB + 3 roles, aplicar migraciones con rol propietario, cargar datos + consultas de control, desplegar API (verificar `/salud`), desplegar front con CORS correcto, restringir acceso a la base, probar backup/restauración, **repetir en la nube un caso que dispare un trigger** (p. ej. venta sin stock) con captura, completar README con URL y pasos de despliegue.
- Criterios de aceptación: URL pública funcionando, conexión cifrada y puerto restringido, sin secretos en el repo, backup restaurado en base nueva con conteos coincidentes, y una regla de la base probada en la nube.

## 9. Documentación, entregables y criterios de evaluación

### 9.1 Estructura del repositorio (sección 10)

```
/README.md
/docker-compose.yml
/.env.example
/db/
  migrations/
    001_esquema.sql
    002_constraints.sql
    003_funciones.sql
    004_procedimientos.sql
    005_triggers.sql
    006_vistas.sql
    007_roles.sql
    008_indices.sql
  seed/          (CSV de catálogo y script de carga)
  tests/         (db_tests.sql)
/consultas/      (insert.sql, update.sql, delete.sql, select.sql)
/api/
/front/
/docs/           (DER, esquema relacional, diccionario, informes)
```

### 9.2 Entregables por etapa / hitos (sección 2.2 y 7)

| Hito | Etapa | Entregable |
|------|-------|-----------|
| H1 | 1. Modelado | DER, esquema relacional, diccionario de datos y DDL base |
| H2 | 2. Integridad y lógica | Constraints, funciones, procs, triggers, vistas, roles y pruebas SQL |
| H3 | 3. Carga masiva | Scripts de carga reproducibles + reporte de conteos y tiempos |
| H4 | 4. Índices y rendimiento | Informe con planes de ejecución antes y después |
| H5 | 5. Consultas SQL | Archivos INSERT/UPDATE/DELETE/SELECT comentadas |
| H6 | 6. API | API REST funcionando en local con Docker Compose |
| H7 | 7. Front | Front conectado a la API |
| H8 | 8. Nube | Sistema desplegado con URL pública, backup y restauración probados |
| H9 | 9. Documentación y defensa | Informe final, README, demo en vivo y defensa oral |

- Los **entregables parciales por etapa** deben estar en el repo y el docente puede devolver correcciones entre etapas (sección 2.1).

### 9.3 Informe final (sección 10.2)

1. Introducción y alcance.
2. Modelo de datos: DER, esquema relacional, normalización, diccionario y decisiones.
3. Reglas de negocio: «dónde va cada regla» y demostración de concurrencia.
4. Carga masiva: catálogos, orden de carga, estrategia frente a triggers, tiempos y consultas de control.
5. Índices y rendimiento: tabla antes/después, planes y costo de escritura.
6. Consultas SQL: enlaces a archivos y comentarios sobre las más interesantes.
7. API y front: arquitectura, endpoints, traducción de errores, pruebas y demostración de inyección SQL fallida.
8. Despliegue en la nube: proveedor y por qué, seguridad, backup y restauración.
9. Conclusiones: dificultades, decisiones que cambiarían y aprendizajes.

Además, la entrega final debe cumplir la **lista de control de la sección 10.3** (aparte del informe): repo sin secretos con commits de todos, `docker compose up` en máquina limpia, migraciones en orden sobre base vacía, mínimos de restricciones/funciones/triggers/vistas/índices, > 100.000 filas en al menos una tabla + carga reproducible, consultas resueltas y comentadas, versión en nube con URL y HTTPS, backup restaurado en base nueva, informe y README completos, y defensa individual preparada.

### 9.4 Rúbrica (sección 9)

| Criterio | Puntos |
|---|---|
| Modelado (etapa 1) | 15 |
| Constraints (etapa 2) | 8 |
| Funciones, procedimientos, triggers y transacciones (etapa 2) | 17 |
| Carga masiva (etapa 3) | 8 |
| Índices y rendimiento (etapa 4) | 10 |
| Consultas SQL (etapa 5) | 12 |
| API (etapa 6) | 10 |
| Front (etapa 7) | 5 |
| Nube y seguridad (etapa 8) | 10 |
| Documentación, Git y demo (etapa 9) | 5 |
| **Total** | **100** |

- La **capa de datos** (modelado + constraints + lógica + índices + carga + consultas) **representa el 70 %** de la nota.
- Nota individual: la nota grupal se pondera con la **defensa oral** individual. El PDF deja **un placeholder sin completar**: «[Completar: coeficiente o mecanismo que defina la cátedra]»; un integrante que no pueda explicar el modelo ni las reglas puede ver reducida su nota. [Pregunta] Pedir el coeficiente exacto.
- Penalizaciones explícitas (sección 9): uso de ORM/herramientas generadoras; secretos en el repo (inclusive en historial); base no recreable desde cero con los entregables; API conectada con propietario o superusuario; totales/descuentos/stock calculados en API o front; historial de Git con un solo integrante.
- Integridad académica (sección 2.1): todo el trabajo debe ser del grupo; en la defensa debe poder explicarse y **modificarse en vivo** cualquier parte; la nota es individual en función de esa defensa.

## 10. Ambigüedades, contradicciones y preguntas pendientes

### 10.1 Contradicciones / puntos a resolver (el PDF no los cierra)

1. **Tamaño del equipo.** El PDF exige grupos de 3 a 4 integrantes (carátula y sección 2.1), y nuestro equipo es de **2 estudiantes**. La indicación de 2 integrantes es de la cátedra/docente, no del PDF. [Pregunta]
2. **Placeholder sin completar en el PDF.** En la sección «Nota individual» (sección 9, rúbrica) el texto queda abierto: «[Completar: coeficiente o mecanismo que defina la cátedra]». [Pregunta]
3. **Anexo C inexistente en el PDF.** El índice menciona «Anexos: … preguntas típicas de defensa» y la etapa 9 remite explícitamente al «anexo C», pero el PDF no desarrolla ese anexo (el documento llega hasta el Anexo B). No hay anexo C. [Pregunta]
4. **Paso faltante en Etapa 9.** La lista de pasos de la etapa 9 salta del «2.» al «4.» sin mostrar un ítem «3.» en el texto extraído del PDF. [Pregunta] ¿Es un número sin contenido real o un problema de lectura del PDF?
5. **RN-06 vs U6 (transversal).** Ver nota bajo la tabla de UPDATE en §7.2: descuento general 30 % (RN-06) frente a 35 % para exportadores con más de tres permisos (U6). La consigna no explicita la relación. [Pregunta]
6. **RN-15 vs valor por defecto del stock.** RN-15 dice «cantidades… siempre positivas», pero los ejemplos de stock usan `CHECK (cantidad >= 0)` con `DEFAULT 0`. [Pregunta] ¿«Positivo» excluye el cero, o para stock basta `>= 0`? [Inferencia] probablemente sea «≥ 0», a confirmar.
7. **Volúmenes: sección 3.3 vs Anexo B.** En la sección 3.3 se citan como presentaciones habituales 375, 750 y 1500 ml; en Anexo B.4 se agregan 187 y 3000 ml y en A.2 el ejemplo de CHECK admite (187, 375, 750, 1500, 3000). [Pregunta] ¿Es un catálogo abierto o fijo?

### 10.2 Preguntas para el docente (resumen operacional)

1. Con dos integrantes, ¿se ajusta la exigencia de roles sugeridos con esos 4 roles del PDF?
2. Con transacciones no vistas en clase y siendo opcionales, ¿queda excluida de la nota (la rúbrica asigna 17 pts a «transacciones»)? ¿Cómo se compensa el puntaje o qué alcanza con implementar sin la demostración?
3. ¿Cuál es el coeficiente exacto para la nota individual (el PDF lo deja sin completar)?
4. ¿Qué pasó con el Anexo C de «preguntas típicas de defensa»? ¿Se publica aparte o queda excluido?
5. ¿Es un error del PDF el paso «3.» faltante en la etapa 9?
6. ¿El mínimo de UNIQUE son 4 aunque el PDF ejemplifica solo 3?
7. ¿El «positivo» en RN-15 es `> 0` o basta con el `>= 0` ejemplificado para stock?
8. ¿La lista de presentaciones (187/375/750/1500/3000 ml) es cerrada u orientativa?
9. ¿Cómo se relacionan RN-06 (30 % general) y U6 (35 % para exportadores con más de 3 permisos)?
10. ¿Los índices automáticos de PK/UNIQUE cuentan como «índices existentes» para la medición inicial de la etapa 4, o solo los explicitados con `CREATE INDEX`?
11. ¿Hay fecha límite para la entrega final y la defensa? (El PDF dice «A definir».)

### 10.3 Semántica de mapeo de jerarquía de clientes [Inferencia]

El PDF deja explícitamente **tres formas posibles** de mapear la jerarquía (tabla única con columna de tipo, tabla por subtipo, supertipo + subtipos) y pide justificar la elegida, con ventajas/desventajas. No exige una forma específica; elegir y documentar. (Sección 5, «decisiones de diseño que deben tomar y justificar».)

### 10.4 Memoria de contexto (docente, fuera del PDF) [Docente]

- **Equipo de 2 integrantes** (el PDF dice 3–4).
- Algunos temas **no se vieron** en clase: **transacciones**, entre otros. La cátedra marcó que quedan **opcionales**; esta indicación **no aparece en el PDF**, que exige explícitamente «manejo de transacciones y concurrencia» como objetivo y línea de rúbrica (sección 1.1 y rúbrica). El grupo debe decidir con el docente la estrategia: implementar lo mínimo necesario y poder explicarlo igual en la defensa.
- [Pregunta] Confirmar si la demostración de concurrencia (sección 7, etapa 2, paso 8) es exigible o reemplazable.

---

### Notas de extracción [limitación]

- El PDF fue leído extrayendo el texto con un script Python (no había `pdftotext` ni lectores de PDF disponibles en el entorno). El texto íntegro se recuperó correctamente (29 páginas), con carencias mínimas de formateo.
- Los números de página no son verificables de manera confiable con este extractor; por eso el documento cita la **sección numerada** (1–10 y anexos A/B) como referencia principal. Solo la carátula (p. 1) y la extensión del archivo (29 páginas) se verificaron de forma directa.
- No hay contenido aparente perdido: el máximo índice de página en el cuerpo del PDF es 29 y la extracción llega hasta el Anexo B. El **Anexo C no aparece** en el extracto ni en la versión completa del archivo.
- El PDF dice explícitamente que los grupos son «3 a 4 integrantes», pero el equipo actual es de dos; además, el docente comunicó extra-PDF los temas no vistos en clase (transacciones). Ambos puntos quedan pendientes de consulta y **no se resuelven arbitrariamente** en este documento.

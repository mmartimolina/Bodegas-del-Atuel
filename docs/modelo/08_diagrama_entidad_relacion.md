# A-08 — Diagrama Entidad-Relación (DER)

> **Estado:** propuesta construida a partir de A-01…A-07. **No aprobada**: queda sujeta a revisión
> de Persona B y del docente. El DER es la fuente para la propuesta **preliminar** de A-09
> (`09_esquema_relacional.md`); ninguna decisión de A-09 es definitiva mientras A-08 no sea revisado.
>
> **Fuentes obligatorias usadas (contenido, no títulos):** `docs/Consigna/TPI_Bodegas_del_Atuel.pdf`
> por vía de la transcripción `docs/requisitos.md` (con la marcación explícito/[Inferencia]/[Pregunta]
> de su §10) y `docs/modelo/01…07_*.md` completos.
> **Limitación declarada:** la herramienta de este entorno no pudo abrir el PDF directamente
> ("Cannot read pdf"); toda cita de sección/página proviene de la transcripción comprometida y de la
> marcación de los A-01…A-07, que citan el PDF por sección. No se verificaron números de página más
> allá de lo ya marcado en A-03/A-04.

---

## 1. Objetivo y alcance

Construir el DER completo del modelo conceptual de «Bodegas del Atuel»:

- representar **todas las entidades** de A-01 (29 conceptos), con los **atributos de A-02** y las
  **claves candidatas de A-03** con su estado de respaldo;
- representar las **25 relaciones de A-04** con su notación de cardinalidad por extremo
  (`A x..y — z..w B`), manteniendo los marcadores `*` de extremos inferidos/condicionados;
- representar la entidad débil **Parcela** con su relación identificadora y clave propietaria + parcial;
- representar la **jerarquía total y disjunta de Cliente**, con la estrategia de mapeo de A-06
  (supertipo + 3 subtipos), según DEC-11, DEC-12 y DEC-13;
- representar las 7 asociaciones de A-05 (1 débil + 6 N:M, de las cuales 4 con atributos y 2 sin atributos).

**No se hace en este documento:** reabrir decisiones de diseño ya adoptadas ni definir su implementación
física definitiva. Permanecen pendientes las cuestiones no resueltas de D-2…D-10, Q-01…Q-13,
AMB-01…AMB-06, AMB-08…AMB-17, ComK-a, RI-a/RT-a, ParK-a, LK-a/LK-b, CompK-a, IK-a, TF-a,
VK/LoteK/PerK… (según el estado documentado en A-12).

---

## 2. Selección de herramienta y justificación

| Criterio | decisión | justificación |
|---|---|---|
| Herramienta elegida | **diagrams.net (draw.io)** — archivo editable `.drawio` multipágina (7 páginas) | Permite representar entidades con atributos (cajas con texto), bordes dobles/discontinuos (débiles), jerarquías con subtipos, aristas con etiquetas y varios niveles de cardinalidad; esencia para la defensa oral; multipágina permite dividir el modelo en 6 módulos sin "achicar" el modelo integral. |
| Por qué no SQL tampoco se genera aquí | — | La consigna evalúa etapa 1 (DER + esquema relacional documentado); A-09 se entrega como documento de diseño (sin SQL definitivo). |
| Por qué no otras herramientas | Mermaid/PlantUML: su notación de ER estándar no muestra claves candidatas alternativas con estado ni atributos derivados sin "inventar" sintaxis; ERwin/dbdiagram: menos control sobre la marcación textual exacta (K / I / P) que ya usamos en A-03. | draw.io permite texto libre dentro de la entidad, con lo que la marcación de candidatas no confirmadas es literal y defendible. |

**Notación del diagrama (consistente y definida):**

- **Entidades:** cajas-tabla con encabezado y lista de atributos. Color/borde:
  - azul = `entidad fuerte`; **verde con borde discontinuo doble = entidad débil** (Parcela);
  - naranja = entidad/relación **asociativa N:M** (las 6 de A-05); amarillo = **inventario** (stock de sala,
    stock de depósito, y auditoría técnica); violeta = **supertipo** (Cliente); violeta claro = **subtipo**.
- **Claves marcadas dentro de la caja** (nunca elegidas como "PK" cerrada):
  - `[K]` = candidata **respaldada** (A-03 categoría R);
  - `[K·inf]` = candidata **inferida** (A-03 categoría I);
  - `[K·pend]` = candidata **pendiente de validación** (A-03 categoría P);
  - `[AK·pend]` = candidata **alterna pendiente**;
  - `[K/FK]` = atributo que a la vez es componente de la clave compuesta y referencia a otra entidad;
  - `[K parcial]` = componente débil (n_parcela); `[FK propietaria]` = la clave propietaria de la débil.
- **Relaciones:** aristas etiquetadas con `REL-nn` + cardinalidad **por extremo** en el formato A-04:
  `A x..y — z..w B`, con `*` junto al extremo cuyo valor es inferido/condicionado (igual que en A-04:
  `1*..N`, `0*..N`, `2*..N`, `1..N*`, `1*..1`, `1*..1*`, `0*..1`). El mínimo **0** del extremo indica
  **participación parcial**; el mínimo ≥ 1 indica participación **total** (en la débil Parcela, total
  respecto de Finca).
- **Atributos derivados** marcados `*` y regla que los respalda (RN-08 para importes de comprobantes).
- **Referencias repetidas:** cuando una entidad aparece en dos páginas, la segunda copia se dibuja
  grisada y etiquetada "(referencia)", con su misma estructura; la definición completa está en la
  página indicada.

### 2.1 Provisión honesta de los archivos de A-08

| Archivo | Qué es | Cómo se produjo |
|---|---|---|
| `08_diagrama_entidad_relacion.drawio` | **Fuente editable**, 7 páginas (00_mapa + 6 módulos) | XML generado por script (`gen_der.py`, carpeta temporal del equipo) a partir del modelo documentado. Puede abrirse en diagrams.net para editar, ruteo fino y **exportar PDF/PNG** cuando la ronda de revisión entre pares lo pida. |
| `08_der_00_mapa.svg` | Mapa de módulos (visión integral) | generado por el mismo script desde el **mismo layout** del `.drawio`. |
| `08_der_01_produccion.svg` … `08_der_06_stock_auditoria.svg` | 6 páginas de módulos | idem. |

> **Declaración:** estos **SVG no son una exportación automática de draw.io**; son la renderización
> fiel del mismo layout, legibles para revisión impresa/comentada. La exportación oficial se hará
> desde draw.io cuando el documento sea aprobado (el `.drawio` es el editable normativo).
> No generamos PDF porque nuestro entorno no tiene la herramienta de exportación instalada; **no se
> declara ninguna exportación PDF como hecha**.

---

## 3. Estructura del diagrama (7 páginas)

| Página | Contenido | Relaciones A-04 representadas |
|---|---|---|
| `00_mapa` | visión integral del modelo, módulos y aristas intermódulos, jerarquía total y disjunta / estrategia A-06 | índice de REL-01…REL-25 |
| `01_produccion` | Finca, Parcela (débil), Cepa, Lote de uva, Análisis de calidad | REL-04, REL-05, REL-06, REL-08 (+ nota REL-07) |
| `02_elaboracion` | Bodega, Vino, Maridaje, Cepa (ref.), Composición, Vino–Maridaje | REL-09, REL-10, REL-11 (+ nota REL-07) |
| `03_comercial_jerarquia` | Localidad, Sala, Empleado, Cliente (supertipo), Socio/Distribuidor/Exportador (subtipos), Permiso | REL-01, REL-02, REL-03, REL-15, REL-16 |
| `04_ventas` | Cliente/Sala/Vino (ref.), Comprobante, Renglón de comprobante | REL-12, REL-13, REL-14 |
| `05_logistica` | Transportista, Bodega/Localidad/Vino (ref.), Ingreso, Transportista–Localidad, Renglón de ingreso | REL-17, REL-18, REL-19, REL-20 |
| `06_stock_auditoria` | Vino/Sala (ref.), Stock de depósito, Auditoría de precio, Stock de sala, Transferencia, Renglón de transferencia | REL-21, REL-22, REL-23, REL-24, REL-25 |

---

## 4. Entidades representadas (29 conceptos) e inventario de atributos y claves

Se listan exactamente las entidades de A-01 §2 (mismo orden), su módulo/página, los atributos de A-02
(incluyendo participantes que en A-02 ya estaban señalados como "serán relaciones en el DER"), y las
claves candidatas de A-03 **con su categoría** (R/I/P). **Estado de cierre:** las PK se adoptaron en A-12 (DEC-01…DEC-10) y se anotan en la tabla §4; las cajas del `.drawio`/SVG conservan aún la notación de candidatas abiertas (regeneración gráfica pendiente, como se indica por fila Q-02/LoteK-a en §9).

| # | Entidad | Pág. | Claves candidatas (estado A-03) | Observaciones de A-02/A-05 respetadas |
|---|---|---|---|---|
| 1 | Localidad | 03, 05 | **PK adoptada: `id_localidad` subrogada (DEC-01/DEC-10)**; codigo_postal y (nombre,provincia) descriptivas | encargado_regional = atributo de Localidad (D-4, RN-02, etapa 1 paso 4); no es entidad |
| 2 | Sala de venta | 03, 04, 06 | id_sala [R, `BIGINT IDENTITY` DEC-10] | dia_cierre Q-09 sin declarar dominio |
| 3 | Empleado | 03 | **PK adoptada: `id_empleado` subrogada (DEC-09/DEC-10)**; cuit fiscal sin UNIQUE | fecha_ingreso para U2/fn_antiguedad_anios; PK no elegida |
| 4 | Finca | 01 | id_finca [R, `BIGINT IDENTITY` DEC-10] | superficie total (dato propio, no suma de parcelas, R-7) |
| 5 | **Parcela (débil)** | 01 | **(finca, n_parcela) = ParK-1 [R: triple cita 3.2, 5, etapa 1-2]** | **entidad débil: borde discontinuo doble; identificación por clave propietaria + parcial; ParK-a (¿reutilización de n.º? sin efecto sobre clave)** |
| 6 | Cepa | 01, 02 | id [R, IDENTITY DEC-10] · nombre [P sin UNIQUE] | doble rol (parcelas y composición); catálogo Anexo B |
| 7 | Lote de uva | 01 | **(parcela, campania) = PK conceptual adoptada (DEC-02)** [R: RN-04 + regla de diseño]; PK relacional `(finca, n_parcela, campania)`; n_lote descriptivo | campaña = atributo (D-5); UNA sola cosecha por parcela y campaña (maximun un lote, p. ej.); ParK-a no cambia estructura |
| 8 | Análisis de calidad | 01 | id_analisis [R, identidad de fila dudosa] · (finca, n_parcela, campania, fecha) [P, AK-2 extendida a la PK de Lote (DEC-02)] | D-6/Q-06 abiertos (AMB-13) |
| 9 | Bodega | 02, 05 | cuit [R por UNIQUE etapa 2] · raz.social descartada por A-03 | PK = cuit [propuesta; subrogación NO adoptada]; raz.-social descartada por A-03 |
| 10 | Vino | 02, 04, 05, 06 | **PK adoptada: `codigo` (DEC-03)**; UNIQUE triada `(nombre, anada, volumen_ml)` [R] | precio único de red > 0 (RN-01) |
| 11 | Composición (vino–cepa) | 02 | (vino, cepa) = ComK-1 [I] | N:M con atributo porcentaje (RN-05 suma 100); ComK-a abierto |
| 12 | Maridaje | 02 | id [R, IDENTITY DEC-10] · nombre [P] | catálogo; I2 confirma existencia previa al vínculo |
| 13 | Vino–Maridaje | 02 | (vino, maridaje) = VMK-1 [I] | N:M sin atributos; nombre/temperatura pertenecen a Maridaje (A-05 §10.5) |
| 14 | Cliente (supertipo) | 03, 04 | id_cliente [R, IDENTITY DEC-10] · (tipo_doc, n_doc) [P sin UNIQUE] | descuento atributo con Q-01/P-9 abiertos; estrategia de mapeo = A-06, sujeta a Persona B |
| 15 | Socio (subtipo) | 03 | `id_cliente` heredada [PK/FK adoptada por DEC-13] | sin atributos propios (A-02 2.15) |
| 16 | Distribuidor (subtipo) | 03 | `id_cliente` heredada [PK/FK adoptada por DEC-13] · `n_habilitacion` [P] | zona = atributo del subtipo (≠ cobertura; AMB-15 resuelta) |
| 17 | Exportador (subtipo) | 03 | `id_cliente` heredada [PK/FK adoptada por DEC-13] | país de destino = atributo del subtipo |
| 18 | Permiso de exportación | 03 | **PK adoptada: `codigo` (DEC-04)** | RN-07 (CHECK vencimiento > emisión); Q-12 estado derivado |
| 19 | Comprobante | 04 | **PK adoptada: `numero` global BIGINT (DEC-05)** | imports subtotal/descuento/total marcados como derivados (RN-08) |
| 20 | Renglón de comprobante | 04 | **(comprobante, vino) = RK-1 [R textual sec. 5]** | precio_unitario = valor histórico (no derivado); Q-05 dominio del descuento |
| 21 | Transportista | 05 | **PK adoptada: `codigo` (DEC-08)**; cuit fiscal sin UNIQUE | S7 actividad; sin UNIQUE textual (UNIQUE de etapa 2 es solo bodega) |
| 22 | Transportista–Localidad | 05 | (transportista, localidad) [I] | N:M sin atributos; ≠ zona del distribuidor (AMB-15 resuelta) |
| 23 | Ingreso | 05 | **PK adoptada: `codigo` global (DEC-06)** | fecha con semántica Q-03; estado ENUM RN-10 |
| 24 | Renglón de ingreso | 05 | (ingreso, vino) = RI-1 [I analogía] | RI-a abierto (asimetría de consigna registrada en A-03) |
| 25 | Transferencia | 06 | **PK adoptada: `numero` global BIGINT (DEC-07)** | fecha_confeccion inmodificable (RN-11) |
| 26 | Renglón de transferencia | 06 | (transferencia, vino) = RT-1 [I analogía] | RT-a abierto |
| 27 | Stock de sala | 06 | **(sala, vino) = SS-1 [R textual sec. 5]** | cantidad >= 0 con P-6 (¿ >0 vs >=0) abierta; distinguir: "fila ausente ≠ cantidad 0" (AMB-11) |
| 28 | Stock de depósito | 06 | vino [I cond. a 1 fila por vino] | depende de D-3 (separación de stocks) y de "un solo depósito central" (sec. 5) |
| 29 | Auditoría de precio | 06 | id_auditoria [R] · (vino, fecha_hora) [P: hipótesis técnica AU-2] | RN-13; Q-07 usuario BD vs funcional; D-10 (pertenencia al DER) respetada incluyéndola |

---

## 5. Relaciones representadas (REL-01…REL-25, cardinalidades de A-04 sin cambios)

| REL | Participantes (A-04) | Cardinalidad A-04 | Cómo quedó en el DER |
|---|---|---|---|
| REL-01 | Localidad — Sala | `0*..N — 1..1` | arista pág. 03 y 05 (y su referencia), etiqueta con rango textual |
| REL-02 | Sala — Empleado | `2*..N — 1..1` (mín. 2 NO definitivo: AMB-02) | arista pág. 03 |
| REL-03 | Localidad — Cliente | `0*..N — 1*..1` | arista pág. 03 |
| REL-04 | Finca — Parcela | `1*..N — 1..1` | **relación identificadora** de la débil (pág. 01), participación total de Parcela |
| REL-05 | Parcela — Cepa | `1..1 — 0*..N*` | arista pág. 01; sin tabla intermedia (D-7) |
| REL-06 | Parcela — Lote | `0*..N — 1*..1` | arista pág. 01 (límite por campaña RN-04 visible) |
| REL-07 | Lote — Bodega | `1..1 — 0*..N` | arista + nota intermódulo: en pág. 01 sale hacia módulo 2 (pág. 02); rol "destino" ≠ elaboradora ≠ origen (AMB-06) |
| REL-08 | Lote — Análisis | `1..N* — 1*..1*` | arista pág. 01 |
| REL-09 | Bodega — Vino | `2*..N — 1..1` (mín. 2 NO definitivo: AMB-05) | arista pág. 02 |
| REL-10 | Vino — Cepa | `1..N — 0*..N` | **entidad asociativa "Composición"** con atributo porcentaje (pág. 02) |
| REL-11 | Vino — Maridaje | `1..N — 0*..N` | **entidad asociativa "Vino–Maridaje"** sin atributos (pág. 02) |
| REL-12 | Cliente — Comprobante | `0*..N* — 1..1` | arista pág. 04 |
| REL-13 | Sala — Comprobante | `0*..N — 1..1` | arista pág. 04 |
| REL-14 | Comprobante — Vino | `1*..N* — 0*..N` | **entidad asociativa "Renglón de comprobante"** con cantidad/precio hist./desc./subtotal (pág. 04) |
| REL-15 | Cliente — Socio/Distribuidor/Exportador | especialización total y disjunta: cada Cliente pertenece a exactamente un subtipo; cada registro de subtipo corresponde a un Cliente | supertipo violeta con 3 subtipos (pág. 03); totalidad y disyunción según DEC-11 y DEC-12 |
| REL-16 | Exportador — Permiso | `0..N — 1*..1` | arista pág. 03 |
| REL-17 | Transportista — Localidad | `0*..N — 0*..N` | **entidad asociativa "Transportista–Localidad"** sin atributos (pág. 05) |
| REL-18 | Bodega — Ingreso | `0*..N — 1..1` | arista pág. 05 |
| REL-19 | Transportista — Ingreso | `0*..N — 1..1` | arista pág. 05 |
| REL-20 | Ingreso — Vino | `1*..N* — 0*..N` | **entidad asociativa "Renglón de ingreso"** con cantidad (pág. 05) |
| REL-21 | Sala — Transferencia | `0*..N — 1..1` | arista pág. 06 |
| REL-22 | Transferencia — Vino | `1*..N* — 0*..N` | **entidad asociativa "Renglón de transferencia"** con cantidad (pág. 06) |
| REL-23 | Sala — Vino (stock) | `0*..N — 0*..N` | **entidad "Stock de sala"** (inventario) con clave (sala, vino) [R] (pág. 06) |
| REL-24 | Vino — Stock de depósito | `0*..1 — 1..1` | **entidad "Stock de depósito"** (inventario), 1 fila máx. por vino (pág. 06) |
| REL-25 | Vino — Auditoría de precio | `0*..N — 1..1` | **entidad "Auditoría de precio"** (pág. 06) |

**Discrepanciones/limitaciones chequeadas contra A-04 §7.1:** A-04 clasifica 24 relaciones como `P`
(parcial) y 1 como `J` (jerarquía). El DER **conserva** cada `*` y no "limpia" ningún rango. No existe
ninguna relación `C` (respaldo textual claro en ambos extremos) en A-04; el DER no inventa ninguna.

---

## 6. Casos especiales

### 6.1 Entidad débil Parcela (A-05 §4)

- Representada con **doble borde discontinuo** en la pág. 01 (caja verde).
- Atributos propios de A-02 (n_parcela, superficie, anio_plantacion) + `finca` como componente
  identificador (clave propietaria) mostrado como `[K/FK propietaria]` + `cepa [FK]` (REL-05).
- Relation identificador REL-04 etiquetada; **participación total** de Parcela (mínimo 1 en el extremo
  Parcela de la relación A-04 `1..1`).
- Clave (finca, n_parcela) = **ParK-1 respaldada (A-03, triple cita)**; ParK-a (reutilización del
  n.º) queda sin efecto sobre la clave.

### 6.2 Jerarquía de clientes (A-06; DEC-11, DEC-12 y DEC-13)

- Cliente = caja violeta con los atributos comunes de A-02/A-06 (id_cliente, nombre Q-04,
  tipo_doc + n_doc, direccion, localidad, fecha_alta, descuento Q-01/P-9).
- Socio / Distribuidor / Exportador = cajas violeta claro con clave heredada `id_cliente`,
  que funciona como PK y FK hacia `Cliente` según la estrategia adoptada en DEC-13.
  Cada subtipo contiene SOLO sus atributos propios (A-06 §2.2: zona+n_habilitacion;
  pais). Socio no tiene atributos propios.
- Especialización REL-15: **total y disjunta**, según DEC-11 y DEC-12.
  Todo `Cliente` debe pertenecer a exactamente uno de los tres subtipos:
  `Socio`, `Distribuidor` o `Exportador`.
- Representación gráfica: indicar totalidad mediante doble línea desde `Cliente`
  hacia la especialización y exclusividad mediante la marca de disyunción (`d`).
- **Alcance de la decisión:** la totalidad y la exclusividad están adoptadas como reglas
  de diseño. Las claves foráneas por sí solas no garantizan ambas reglas; los mecanismos
  adicionales para hacerlas cumplir en PostgreSQL permanecen pendientes de definición
  e implementación.
- Nota en la pág. 03: "Jerarquía total y disjunta adoptada por DEC-11 y DEC-12;
  estrategia de mapeo supertipo + subtipos adoptada por DEC-13. Mecanismos de integridad
  adicionales pendientes de implementación".

### 6.3 Entidades asociativas N:M (A-05)

| Asociación | Participantes | Atributos propios | Estado de notación |
|---|---|---|---|
| Composición | Vino–Cepa | porcentaje (RN-05) | caja naranja; D-9 abierto (asociativa vs. relación simple) |
| Renglón de comprobante | Comprobante–Vino | cantidad, precio_unitario (histórico), descuento (Q-05), subtotal (derivado) | caja naranja; clave (comprobante, vino) [R de sec. 5] |
| Renglón de ingreso | Ingreso–Vino | cantidad | caja naranja; clave [I]; RI-a abierto |
| Renglón de transferencia | Transferencia–Vino | cantidad | caja naranja; clave [I]; RT-a abierto |
| Vino–Maridaje | Vino–Maridaje | (ninguno) | caja naranja; D-9 abierto; no se duplican atributos de Maridaje |
| Transportista–Localidad | Transportista–Localidad | (ninguno) | caja naranja; D-9 abierto; AMB-15 resuelta (≠ zona del distribuidor) |

Las **stocks** (Stock de sala `(sala, vino)` y Stock de depósito `vino`) se dibujan como inventarios
amarillos: son entidades de estado persistente por par (A-01 §2.27/§2.28), aunque la consigna los
relaciona por N:M/1..N en A-04; su clave textual (SS-1) está respetada. La duda D-2 (débil vs. asociati-
va para renglones/stocks) sigue abierta y el diagrama no la resuelve: usa la marca de "inventario" para
los stocks y "asociativa" para los renglones (con lo que renglón podría ser reetiquetado si se
resuelve D-2 en la revisión).

---

## 7. Matriz de trazabilidad (relaciones A-04/A-05 ↔ elementos del DER)

| REL (A-04) | A-05 | Elemento en el DER | Página del `.drawio` | ¿Cardinalidad conservada sin cambio? |
|---|---|---|---|---|
| REL-01 | — | arista Localidad–Sala | 03 (y 05 ref.) | sí (`0*..N — 1..1`) |
| REL-02 | — | arista Sala–Empleado | 03 | sí (`2*..N — 1..1`, con nota AMB-02) |
| REL-03 | — | arista Localidad–Cliente | 03 | sí (`0*..N — 1*..1`) |
| REL-04 | §4 | relación identificadora Finca–Parcela | 01 | sí (`1*..N — 1..1`) |
| REL-05 | — | arista Parcela–Cepa | 01 | sí (`1..1 — 0*..N*`) |
| REL-06 | — | arista Parcela–Lote | 01 | sí (`0*..N — 1*..1`) |
| REL-07 | — | nota intermódulo (pág. 01→02) | 01, 02 | sí (`1..1 — 0*..N`; nota AMB-06) |
| REL-08 | — | arista Lote–Análisis | 01 | sí (`1..N* — 1*..1*`) |
| REL-09 | — | arista Bodega–Vino | 02 | sí (`2*..N — 1..1`, nota AMB-05) |
| REL-10 | §5 | entidad asociativa Composición | 02 | sí (`1..N — 0*..N`) |
| REL-11 | §10 | entidad asociativa Vino–Maridaje | 02 | sí (`1..N — 0*..N`) |
| REL-12 | — | arista Cliente–Comprobante | 04 | sí (`0*..N* — 1..1`) |
| REL-13 | — | arista Sala–Comprobante | 04 | sí (`0*..N — 1..1`) |
| REL-14 | §6 | entidad asociativa Renglón de comprobante | 04 | sí (`1*..N* — 0*..N`) |
| REL-15 | §6.2 | jerarquía total y disjunta supertipo/subtipos | 03 | sí; DEC-11, DEC-12 y DEC-13 adoptadas |
| REL-16 | — | arista Exportador–Permiso | 03 | sí (`0..N — 1*..1`) |
| REL-17 | §9 | entidad asociativa Transportista–Localidad | 05 | sí (`0*..N — 0*..N`) |
| REL-18 | — | arista Bodega–Ingreso | 05 | sí (`0*..N — 1..1`) |
| REL-19 | — | arista Transportista–Ingreso | 05 | sí (`0*..N — 1..1`) |
| REL-20 | §7 | entidad asociativa Renglón de ingreso | 05 | sí (`1*..N* — 0*..N`) |
| REL-21 | — | arista Sala–Transferencia | 06 | sí (`0*..N — 1..1`) |
| REL-22 | §8 | entidad asociativa Renglón de transferencia | 06 | sí (`1*..N* — 0*..N`) |
| REL-23 | — | entidad Stock de sala | 06 | sí (`0*..N — 0*..N`) |
| REL-24 | — | entidad Stock de depósito | 06 | sí (`0*..1 — 1..1`) |
| REL-25 | — | entidad Auditoría de precio | 06 | sí (`0*..N — 1..1`) |

Cobertura: **25/25 relaciones representadas**; **29/29 entidades (conceptos A-01) representadas**; los
**atributos de A-02** están en las cajas correspondientes (los participantes marcados por A-02 como
"futuras relaciones" no se duplican como atributos sin vínculo: aparecen como componente/FK dentro de
la caja y como arista/clave según el caso, p. ej. `Empleado.sala [FK]`, `Comprobante.cliente [FK]`,
`Ingreso.transportista [FK]`, `Auditoria.vino [FK]`).

---

## 8. Validaciones de A-08 (estado de cada criterio)

| Criterio de validación (consigna) | Resultado |
|---|---|
| Todas las entidades requeridas representadas (29 conceptos de A-01 §2/§3) | **OK** — matriz §4 de este documento |
| No faltan atributos aprobados (A-02 §2) | **OK** — inventario por caja; los dominios/derivados se marcan pero no se "cierran" |
| Relaciones coinciden con A-04 y A-05 | **OK** — matriz §7 (25/25) |
| Claves y cardinalidades correctamente identificadas con su estado | **OK** — marcas R/I/P y `*` preservadas; PK elegida mediante DEC-02 cuando el fundamento lo permite (`Lote`); el resto queda en alternativa abierta sin cierre |
| Parcela representada como débil | **OK** — doble borde discontinuo, clave propietaria + parcial, relación identificadora |
| Jerarquía Cliente representada según A-06 y DEC-11/12/13 | **Pendiente de actualización gráfica** — la documentación textual establece totalidad y disyunción; falta verificar la doble línea y la marca de disyunción en el `.drawio` y sus SVG |
| Asociaciones N:M y atributos incluidas | **OK** — 6 asociativas (§6.3) + stocks/inventario diferenciados |
| Archivo editable abre | **Validado parcialmente**: el XML del `.drawio` es parseable y sigue el formato estándar `mxfile/diagram/mxGraphModel`; falta la verificación visual final abriéndolo en diagrams.net por el equipo (no puedo ejecutar la GUI en este entorno) |
| Exportación legible | **SVG sí** (7 archivos, generados por script sobre el mismo layout); **PDF no generado** (herramienta no disponible en el entorno; se declarará como pendiente, sin afirmar que se exportó) |

---

## 9. Decisiones pendientes, ambigüedades y limitaciones (consecuencia en el DER)

| Referencia | Impacto en este DER |
|---|---|
| **Jerarquía Cliente (DEC-11/12/13)** | La totalidad, la disyunción y la estrategia supertipo + subtipos están adoptadas. No constituyen decisiones pendientes. Permanecen pendientes los mecanismos adicionales de integridad en PostgreSQL y la actualización/verificación de la representación gráfica. La revisión de Persona B sigue pendiente. |
| **D-2** (débil vs. asociativa para renglones/stocks) | Renglones naranjas; stocks amarillos. Notación de renglones podría pasar a "débil" sin cambiar la estructura. |
| **D-9** | Las 6 asociativas (REL-10, 11, 14, 17, 20, 22) están dibujadas como cajas para poder marcar atributos y claves; si se resuelve como relación simple, REL-11 y REL-17 quedarían como aristas puras (sin caja). No cambia la estructura relacional. |
| **D-3** (stock de depósito separado) | Se respeta la separación (stock de sala ≠ stock de depósito); si se unificaran, cambiaría la clave del stock de depósito. |
| **D-6 / Q-06 / AMB-13** | El Análisis se dibuja con id_analisis [R] y la AK extendida (finca, n_parcela, campania, fecha) [P]; si se confirman duplicados por fecha, habría que agregar n.º de análisis o revisar la clave. |
| **Q-02 / LoteK-a** (identidad del lote) | **RESUELTA (DEC-02):** PK conceptual `(parcela, campania)`; relacional `(finca, n_parcela, campania)`; `n_lote` descriptivo. La caja del diagrama (XML/SVG) conserva aún la notación de AMBAS candidatas; regeneración gráfica pendiente (no afecta la validez estructural ni el esquema). |
| **CompK-a / IK-a / TF-a** | Comprobante, Ingreso y Transferencia muestran ambas candidatas (global vs. por sala/bodega); ninguna elegida. |
| **LK-a/LK-b** | Localidad muestra ambas candidatas; ninguna elegida (encargado depende de la identidad de la localidad: si no se cierra, la clave de Localidad sigue abierta). |
| **ComK-a / RI-a / RT-a / RK (resuelta por A-05 §12)** | Composición/Renglón de ingreso/Renglón de transferencia marcan sus claves como inferidas; el renglón de comprobante es el único [R] (clave textual de la sección 5, A-05 §12). |
| **Q-01 / P-9** (descuento) | El atributo `descuento` queda en Cliente con la marca "(Q-01/P-9)"; no se decide atributo vs. función. |
| **P-6, P-8, Q-…** dominios/cantidad | Marcados como pendientes entre paréntesis en las cajas (no alteran entidades ni claves). |
| **AMB-01…AMB-17 (18 abiertas de A-04)** | Los extremos con `*` del diagrama corresponden exactamente a los marcados por A-04; no se eliminó ninguno. |

**Limitaciones declaradas:**
1. El PDF no se leyó directamente con esta herramienta; toda cita viene de `docs/requisitos.md` y
   A-01…A-07 (que ya anotaron ese mismo límite).
2. No me es posible abrir la GUI de diagrams.net en este entorno para "ver" el archivo renderizado;
   la validación hecha es estructural (XML válido y formato mxfile estándar) + SVG legibles por script.
3. **No hay exportación PDF** producida (herramienta no disponible); no se declara como hecha.
4. Las réplicas de entidades entre páginas son **referencias** (grisadas), no entidades nuevas.

---

### Registro de cambios de este documento
- Cierre (2): inventario §4 sincronizado con las PK ADOPTADAS de A-12 (DEC-01, 03, 04, 05, 06, 07, 08, 09, 10): cada fila indica la PK adoptada y las candidatas descartadas; nota §4 actualizada (la regeneración gráfica de cajas sigue pendiente, sin afectar la validez del documento textual).
- Cierre: actualizadas las claves de `Lote` (PK conceptual `(parcela, campania)` adoptada por DEC-02; `n_lote` descriptivo) y la candidata de `Analisis` (AK extendida con la PK compuesta); fila Q-02/LoteK-a marcada RESUELTA con nota de regeneración gráfica pendiente. El PDF oficial de draw.io sigue NO generado (la herramienta no existe en el entorno; no se simula su exportación). Ninguna aprobación humana declarada.

- Creación (A-08): documento + fuente editable multipágina (7 páginas) + 7 SVG (mapa + 6 módulos)
  generados por script a partir de A-01…A-07; matrices de entidades/relaciones/trazabilidad y lista de
  validaciones; sin resolución de ambigüedades ni elección de PK; estado: por revisar.

# A-13 — Tipos PostgreSQL, ENUM y DOMAIN

> **Estado: PRELIMINAR, sujeto a decisiones pendientes.** Define los **tipos de datos** (elegidos y
> justificados) para las 128 columnas del diccionario A-10 y desarrolla los **tipos propios**
> (1 ENUM + 1 DOMAIN mínimos exigidos en etapa 2). **No cierra decisiones pendientes:** todo lo
> dependiente del docente o de Persona B se mantiene marcado [P]/PENDIENTE. **No se generan DDL de
> tablas, scripts ni migraciones**; no se modifican A-01…A-12 ni `docs/requisitos.md`; sin commits.
>
> Documentos de entrada: `docs/requisitos.md` (transcripción de la consigna), A-08 (DER, sin
> aprobación), A-09 (esquema PRELIMINAR), A-10 (diccionario PRELIMINAR: 29 tablas / 128 columnas) y
> A-12 (matriz de decisiones pendientes, en especial DEC-25…DEC-33).
>
> **Marcado heredado:** [R] respaldado textualmente (con cita) · [I] propuesta inferida · [P]
> pendiente (docente / Persona B / DEC de A-12). Estados de decisión por fila de la matriz: **D**
> definida (respaldo completo), **prop** propuesta ([I], decidible por el equipo en etapa 2),
> **pend** pendiente de terceros.
>
> **Nota de nomenclatura:** la tarea fija el nombre del DOMAIN en **`cuit_dom`** (A-10 §7 lo llamaba
> `cuit`). Se adopta `cuit_dom`; es un renombre de identificador del tipo, no un cambio de diseño, y
> se registra sin editar A-10.

---

## 1. Alcance y método

1. Propuesta de ENUM para los estados de documentos (§2), DOMAIN de CUIT con análisis de formato vs.
   dígito verificador (§3), selección de tipos por categoría de atributo (§4), casos particulares (§5),
   orden de creación/eliminación de tipos y dependencias (§6), mapeo con A-12 (§7) y matriz de
   trazabilidad con cobertura completa del diccionario (§8), verificación final (§9).
2. Respaldo base de tipos (requisitos §5.2): dinero con `NUMERIC(p,s)` **nunca FLOAT**; fechas con
   `DATE`/`TIMESTAMP`; estados con tipos enumerados; 1 ENUM + 1 DOMAIN. Precisión/escala no
   respaldada ⇒ propuesta [I] justificada, revisable en etapa 2 (cf. DEC-31 de A-12).
3. No se agregan UNIQUE/NOT NULL sin respaldo (regla A-09 §1.8, vigente); no se inventan valores,
   rangos ni estados no listados en la consigna.
4. Advertencia transversal (requisitos §5.2): **no usar `CURRENT_DATE` ni funciones no determinísticas
   dentro de un CHECK**; las reglas dependientes de la fecha actual van en trigger.

---

## 2. ENUM `estado_documento`

### 2.1 Propuesta

| Aspecto | Propuesta | Respaldo | Estado |
|---|---|---|---|
| Nombre | `estado_documento` | consigna (etapa 2) + A-10 §7.1 [R] | prop |
| Tipo | ENUM de PostgreSQL; el orden de declaración de los valores determina su orden de comparación. | [I] (aporte técnico; el tipo enumerado es exigencia textual) | prop |
| Valores | `en_confeccion`, `terminado`, `procesado` (en este orden) | RN-10; sec. 3.5; etapa 2 (DEFAULT `en_confeccion`) [R] | prop [R en valores] |

Semántica de cada valor [R]: `en_confeccion` — estado inicial; admite agregar/quitar renglones
(RN-12); `terminado` — confección cerrada, aún sin impacto en stock («solo un ingreso terminado
impacta», RN-10); `procesado` — impactó stock (ingreso: suma al depósito; transferencia: descuenta
depósito y suma a la sala) y es terminal, **sin retroceso** (RN-10/RN-11).
El orden de declaración del ENUM no reemplaza la validación de transiciones. El futuro trigger deberá permitir explícitamente las transiciones en_confeccion → terminado y terminado → procesado, y rechazar las demás transiciones no autorizadas. No se debe utilizar únicamente el orden de comparación del ENUM para determinar si una transición está permitida.

### 2.2 Documentos que necesitan estado (análisis del diccionario)

| Tabla.Columna | ¿Lleva estado? | Base |
|---|---|---|
| `Ingreso.estado` | **Sí [R]** | RN-10: ciclo `en_confeccion → terminado → procesado`. |
| `Transferencia.estado` | **Sí [R]** | RN-11: «misma modalidad» que RN-10. |
| `Comprobante` | **No respaldado** | Ni RN-08 ni la sec. 5 asignan ciclo de vida a comprobantes (A-02 §2.19 no lo lista); rectamente no se inventa el atributo ni un tercer caso de uso del ENUM. |
| `Permiso_Exportacion` | **No respaldado como columna** | La vigencia («vigente/vencido», Q-12) es **derivada**: se calcula por `fecha_vencimiento` frente a la fecha actual en consulta/trigger, no como columna — y no admite CHECK por la advertencia de CURRENT_DATE. |

**Conclusión:** un único ENUM compartido por `Ingreso.estado` y `Transferencia.estado`; cubre el
mínimo de 1 ENUM [R]. Los dos ciclos y valores son textualmente idénticos (RN-11 «misma
modalidad»), por lo que un ENUM compartido también permite reutilizar el trigger de transición
planeado para RN-10/RN-11 en etapa 2.
Si el docente indicara estados distintos por documento, la alternativa es un ENUM por documento
(pendiente; no hay dato que la sustente hoy).

---

## 3. DOMAIN `cuit_dom`

### 3.1 Propuesta de formato

| Aspecto | Propuesta | Respaldo/estado |
|---|---|---|
| Nombre | `cuit_dom` | nombre fijado por la tarea (A-10 usaba `cuit`); prop |
| Tipo subyacente | `VARCHAR(11)` | [I]: permite almacenar el CUIT como cadena de hasta 11 caracteres, sin introducir el comportamiento de relleno con espacios de `CHAR(11)`. La longitud exacta y el contenido numérico se controlan mediante la validación del DOMAIN. |
| Validación de formato | exactamente 11 caracteres, todos numéricos, sin separadores (expresión regular o equivalente determinista e inmutable) | [R] etapa 2 («DOMAIN CUIT de 11 dígitos»); prop |

La validación de formato es **sintáctica, determinista e IMMUTABLE**: sin fecha actual ni datos
externos, por lo que es apta como CHECK de DOMAIN (no incurre en la advertencia de la consigna).

**Alcance propuesto (DEC-26 de A-12):**

| Columna | Fundamento | Estado |
|---|---|---|
| `Bodega.cuit` | [R]: UNIQUE textual de etapa 2 y alcance del DOMAIN respaldado; su elección como PK es una propuesta de diseño pendiente. | prop |
| `Transportista.cuit` | [I]: el DOMAIN valida **formato**, no unicidad; formato común coherente | prop |
| `Empleado.cuit` | [I]: idem; compatible incluso si su PK final fuera subrogada (DEC-09) | prop |

Recordatorio: usar el DOMAIN **no implica UNIQUE**. La unicidad sigue regida por A-09 §6.2: la
única UNIQUE textual de CUIT es la de `Bodega.cuit`; `Transportista.cuit` y `Empleado.cuit` siguen
sin UNIQUE declarada (DEC-08/DEC-09/DEC-33 de A-12).

### 3.2 Dígito verificador: análisis de validez (extensión no respaldada)

La consigna **no pide** validar el dígito verificador. Se diferencia:

- **Validación de formato (sintaxis):** «11 dígitos numéricos». Respaldo [R]; **propuesta adoptada**
  para el DOMAIN.
- **Validación de validez (dígito verificador):** algoritmo estándar de módulo 11 para CUIT:
  pesos `5,4,3,2,7,6,5,4,3,2` sobre los 10 primeros dígitos; dígito verificador esperado = 11 −
  (peso_digito_de_suma mod 11), con convenciones para 10 (→ 9) y 11 (→ 0). Es una función pura
  (determinista e inmutable sobre la cadena) y técnicamente cabe como CHECK del DOMAIN, creando
  antes una función auxiliar IMMUTABLE.

**Limitaciones y riesgos de incorporarlo (por qué queda PENDIENTE y no se decide aquí):**

1. **Falta de respaldo textual**: agregarlo infringe la regla «no se agregan restricciones sin
   respaldo»; el algoritmo no proviene de la consigna sino del estándar fiscal externo.
2. **Calidad de los datos de carga (etapa 3)**: si la generación con Faker/CSV no calcula el dígito
   correcto, el DOMAIN **rechazaría filas legítimas**; la semilla reproducible debería usar la misma
   función para fabricar CUITs válidos.
3. **Es validez formal, no validez fiscal**: ningún CHECK valida que el CUIT exista/esté activo ante
   el padrón (fuera de alcance del TPI) — la «validez real» queda como límite documentado.
4. **Orden de creación**: una función auxiliar debería crearse antes del DOMAIN (impacta §6).

**Estado:** formato — **prop [R]**; dígito verificador — **PENDIENTE** de docente/equipo (qué falta:
decidir si el DOMAIN incluye validación de dígito; por qué afecta: cambia el alcance del CHECK y la
carga de datos; alternativas: (a) solo formato hoy, (b) formato + verificador siempre, (c)
verificador opcional como CHECK aparte por tabla; actor: docente/equipo en DEC-26).

---

## 4. Selección de tipos PostgreSQL por categoría

> Principio global: `NUMERIC` es exacto (sin error de punto flotante en sumas de importes);
> `FLOAT`/`REAL`/`DOUBLE PRECISION` muestran error de representación al sumar dinero — **prohibido
> por la consigna** (§5.2) y descartado por criterio de aceptación de etapa 1. En PostgreSQL,
> `VARCHAR(n)` solo aporta un CHECK de longitud: sin límite textual conocido, `TEXT` es lo
> defendible.

### 4.1 Importes monetarios → `NUMERIC(12,2)`

- Aplica a: `Vino.precio` [R], `Empleado.salario` [I], `Comprobante.subtotal/total`,
  `Renglon_Comprobante.precio_unitario/subtotal`, `Auditoria_Precio.precio_anterior/precio_nuevo`
  (todos respaldados como dinero/magnitud monetaria [R] salvo salario [I]).
- Precisión `12,2` [I]: 10 enteros + 2 decimales, margen holgado para los volúmenes del trabajo
  (≤ 500.000 renglones; importes de venta de 3–5 dígitos) sin inventar límites de negocio. La
  consigna no fija p/s: la propuesta es revisable en etapa 2 (DEC-31).
- **`Comprobante.descuento` / `Renglon_Comprobante.descuento`:** el tipo depende del dominio
  **PENDIENTE Q-05** — porcentaje ⇒ `NUMERIC(5,2)` (0–100,00); importe monetario ⇒ `NUMERIC(12,2)`.
  No se fija en este documento (DEC-23 de A-12); alternativas registradas en §8. Fondo adicional
  (columna vs función Q-01; relación RN-06 vs U6 P-9): PENDIENTE.

### 4.2 Porcentajes y descuentos → `NUMERIC(5,2)`

- Aplica a: `Cliente.descuento` (RN-06 exige un CHECK de rango [R]; sus límites exactos siguen pendientes), `Composicion.porcentaje` [I], y  condicionalmente los `descuento` de §4.1 si Q-05 concluye «porcentaje».
- Precisión `5,2` [I]: cubre 0–100,00 (valores textuales 10/20/30 y el 35 % de U6). El CHECK
  individual de rango 0–100 es **PENDIENTE** (límites por atributo no declarados textualmente).
- RN-05 (porcentajes de un vino suman 100) es **restricción agregada**: constraint trigger diferido
  en etapa 2; no es CHECK de fila ni domina el tipo.

### 4.3 Fechas y timestamps

- **`DATE`** para todas las fechas con solo día [R: «fecha» consigna + guía `DATE/TIMESTAMP`]:
  `Empleado.fecha_ingreso`, `Lote.fecha_cosecha`, `Analisis.fecha`,
  `Permiso_Exportacion.fecha_emision/fecha_vencimiento`, `Comprobante.fecha`, `Cliente.fecha_alta`,
  `Ingreso.fecha` (semántica **PEND Q-03**: ¿confección o traslado? el tipo no cambia), `Transferencia.fecha_confeccion` (**inmodificable** [R RN-11]; modificado vía trigger, no CHECK).
- **`TIMESTAMP` (sin zona)** para `Auditoria_Precio.fecha_hora` [R: «fecha y hora», RN-13].
  `TIMESTAMPTZ` no se propone (sin respaldo de zonas horarias en la consigna) [I revisable].
- Defaults: `Cliente.fecha_alta DEFAULT CURRENT_DATE` [R etapa 2];
  `Transferencia.fecha_confeccion DEFAULT CURRENT_DATE` [I, RN-11]. Si el valor o la inmodificabilidad los fija un trigger BEFORE en
  vez del DEFAULT es decisión de etapa 2 (relevante para la carga masiva reproducible); **PENDIENTE**.

### 4.4 Cantidades y volúmenes

- **`INTEGER`** para cantidades de botellas:
  `Renglon_Comprobante/Renglon_Ingreso/Renglon_Transferencia/Stock_Sala/Stock_Deposito.cantidad` [I: unidad atómica entera; sin rango
  textual]. CHECK `> 0` (RN-15 [R]) para renglones; CHECK `>= 0` para stocks [R sec. 5/RN-09];
  la contradicción «positivo» RN-15 vs `>= 0` stock sigue **PENDIENTE P-6** (los stocks llevan
  texto `>= 0`; la pregunta es si «positivo» excluye el cero en general).
- `Stock_*.cantidad DEFAULT 0` [R etapa 2 como ejemplo]: admite el DEFAULT **PENDIENTE AMB-11/
  DEC-19** (fila ausente ≠ cantidad 0; DEFAULT 0 fuerza «matriz completa»). No se cierra aquí.
- **Años → `SMALLINT`** [I]: `Vino.anada`, `Lote.campania`, `Parcela.anio_plantacion` (rango
  plausible 1800–9999).
- **`volumen_ml → SMALLINT`** [I]: dominio propuesto de volúmenes 187–3000 ml (Anexo A.2/B.4); el CHECK
  de lista cerrada 187/375/750/1500/3000 sigue **PENDIENTE P-8/DEC-29** (¿catálogo cerrado u
  orientativo?).
- **Kilos y superficies → `NUMERIC`**: `Lote.kg NUMERIC(10,2)`; `Finca.superficie` y
  `Parcela.superficie NUMERIC(8,2)` [I: magnitudes continuas con decimales; sin escala textual].
  CHECK `> 0` [R RN-15] para ambos (P-6 no aplica a stocks: es solo texto stock). Checks exactos
  en etapa 2.

### 4.5 Graduación alcohólica → `NUMERIC(4,1)`

- **`Vino.graduacion`**: rango `BETWEEN 5 AND 20` [R RN-15]. Escala 1 decimal [I: práctica habitual
  en grados GL (12,5; 14,2)] — **revisable** (¿1 o 2 decimales?) en etapa 2; el rango es respaldo
  completo, la escala no.
- **`Maridaje.temperatura` → `NUMERIC(3,1)`** [I: °C de servicio, rango plausible sin dominio
  textual]. Fuente correcta: sec. 5/3.3 (la cita «RN-06» de A-09 §3.12 es errónea; ya registrada en
  A-10 §9.3 / DEC-16). CHECK de rango: **PENDIENTE** (sin dominio declarado).

### 4.6 Identificadores y códigos

- **Subrogados → `BIGINT GENERATED ALWAYS AS IDENTITY`**: `Localidad.id_localidad`,
  `Sala.id_sala`, `Empleado.id_empleado`, `Finca.id_finca`, `Cepa.id`, `Maridaje.id`,
  `Cliente.id_cliente`, `Analisis.id_analisis` y `Auditoria_Precio.id_auditoria`.
  La forma subrogada está declarada en A-09 §2/A-10 §3; la autogeneración está ADOPTADA
  (DEC-10). Para la carga masiva se utilizará `OVERRIDING SYSTEM VALUE` (etapa 3).
- **Columnas FK / componentes de PK compuesta:** tras el cierre, los tipos quedan fijados por las DEC adoptadas (§8): `localidad` → BIGINT (DEC-01); `vino` → TEXT (DEC-03); `comprobante` → BIGINT (DEC-05); `ingreso` → TEXT (DEC-06); `transferencia` → BIGINT (DEC-07); `transportista` → TEXT (DEC-08); `Analisis.(finca, n_parcela, campania)` → FK compuesta (DEC-02); subtipos/permiso (DEC-13, PK/FK heredada BIGINT).
- **Códigos de negocio → `TEXT`** [I, sin formato textual]: `Vino.codigo`,
  `Permiso_Exportacion.codigo`, `Ingreso.codigo`, `Transportista.codigo`,
    `Cliente.tipo_doc/n_doc`, `Distribuidor.n_habilitacion` y `Localidad.codigo_postal`
  (este último no es PK: DEC-01 adoptó `id_localidad`).
  `Comprobante.numero` y `Transferencia.numero`: **BIGINT**, conforme a las PK globales adoptadas
  (DEC-05/DEC-07).

- **CUIT**: DOMAIN `cuit_dom` (§3). Su aplicación a `Bodega.cuit` está respaldada [R].
  La elección de `Bodega.cuit` como PK sigue pendiente de confirmación en el modelo; su UNIQUE
  textual está respaldada. Si se mantiene como clave de referencia, las FK con rol a Bodega
  (`Vino.bodega`, `Lote.bodega_destino`, `Ingreso.bodega_origen`) deben utilizar el mismo tipo
  compatible con `cuit_dom`. La aplicación del DOMAIN a `Transportista.cuit` y `Empleado.cuit`
  depende de la alternativa A de DEC-26.

### 4.7 Textos y descripciones → `TEXT`

- `TEXT` para: todos los `nombre` (Localidad, Sala vía calle, Empleado, Finca, Parcela no tiene,
  Cepa, Vino, Maridaje, Cliente, Exportador.pais, Distribuidor.zona), `razon_social` (Bodega,
  Transportista), `domicilio` (Bodega, Transportista), `direccion` (Cliente), `calle`,
  `encargado_regional`, `departamento`, `provincia`, `telefono`, `email`, `usuario`
  (Auditoria_Precio). [I; sin longitud textual; NOT NULL sujeto a la política DEC-14 y a las decisiones de etapa 2.]
- `Cliente.tipo_doc`: TEXT [I]; dominio (lista de valores, p. ej. DNI/CUIT) **PENDIENTE** — no se
  inventa lista. `n_doc`: TEXT [I: pueden convivir DNI (8) y CUIT (11)].
- `Transportista.email`: TEXT; validación de formato de email **PENDIENTE** (sin respaldo; opción:
  DOMAIN ad-hoc o CHECK regex en etapa 2; la consigna no lo pide).

### 4.8 Dominios cerrados textuales (tipo de uva/vino; día de cierre)

- **`Cepa.tipo`** (tinta/blanca) y **`Vino.tipo`** (tinto/blanco/rosado/espumante): valores
  textuales [R 3.2/3.3]. **Materialización PENDIENTE (DEC-28)**:
  - Alternativa A (propuesta por defecto): `TEXT` + CHECK de lista cerrada (sin tipo nuevo; el mínimo 1 ENUM ya se cubre con `estado_documento`).
  - Alternativa B: DOMAINs `tipo_uva_dom`/`tipo_vino_dom` (tipos propios adicionales; sin exigencia
    textual, más formal pero doble costo de mantenimiento).
- **`Sala.dia_cierre` → DOMAIN `dia_semana`** [I]: lista de días lunes…domingo. **PENDIENTE Q-09**:
  ¿existe «sin cierre» como valor? (¿o la sala siempre cierra algún día?). Alternativas técnicas
  si hay «sin cierre»: (a) DOMAIN con séptimo valor, (b) columna nula, (c) CHECK aparte; decide el
  docente (Q-09/DEC-27). U4 (UPDATE masivo lunes↔miércoles) es indiferente a la elección.

---

## 5. Casos particulares (otras decisiones que afectan el tipo)

| Asunto | Análisis | Estado |
|---|---|---|
| Autogeneración de `id_*` | `BIGINT GENERATED ALWAYS AS IDENTITY`, conforme a DEC-10; carga reproducible mediante `OVERRIDING SYSTEM VALUE` (etapa 3) | **ADOPTADA** |
| `Ingreso.fecha` semántica | Q-03 (¿confección o traslado?); el tipo no cambia (DATE) | **PENDIENTE** |
| Vigencia de permisos | derivada por consulta/trigger con fecha actual (Q-12); sin columna; sin CHECK que use CURRENT_DATE | prop |
| `Stock_Deposito.vino` PK/FK 1:1 | «un solo depósito central»: referencia única cond. D-3/AMB-11 | prop / pend (DEC-19) |
| `Auditoria_Precio.fecha_hora` DEFAULT | lo completa el trigger RN-13 (instante del disparo); DEFAULT/estrategia en etapa 2 | pend |
| `Auditoria_Precio.usuario` | semántica Q-07 (CURRENT_USER de BD vs. usuario funcional) — el tipo no cambia (TEXT) | **PENDIENTE** |
| Default de `estado` | `en_confeccion` [R etapa 2] — cubre un DEFAULT del mínimo de 3 | prop |
| `Stock_*.cantidad DEFAULT 0` | AMB-11 (fila ausente ≠ 0) | **PENDIENTE** |

---

## 6. Orden de creación y dependencias de tipos (para implementar posteriormente)

### 6.1 Orden de creación de tipos (propuesto)

1. **`estado_documento`** (ENUM) — sin dependencias; alimentará `Ingreso.estado` y
   `Transferencia.estado`.
2. **`cuit_dom`** (DOMAIN) — CHECK autocontenido; alimenta `Bodega.cuit` y, si se adopta la
   alternativa A de DEC-26, también las columnas de CUIT de Transportista/Empleado. Si se adopta
   la validación del dígito verificador, **antes** de `cuit_dom` va la función IMMUTABLE del
   algoritmo (PENDIENTE).
3. *(Si DEC-28 elige B)*: `tipo_uva_dom` y `tipo_vino_dom` antes de `Cepa` y `Vino` (si elige A, no
   hay tipo nuevo: CHECK de tabla).
4. *(Si Q-09 se resuelve)*: `dia_semana` antes de `Sala`.
5. Tablas: en el orden de niveles de FK de A-10 §8 (cada nivel solo depende de los anteriores).
   PG de 14; `ALTER DOMAIN` permite ajustar CHECKs con `NOT VALID`/`VALIDATE` en etapa 2 si hiciera
   falta, aunque lo ideal es no cambiar el dominio en operación.

### 6.2 Eliminación

- En orden inverso: primero views/triggers/roles/funciones/procedimientos, luego **DROP TABLE** en
  reverso de niveles FK (niveles 9 → 1), y recién al final **DROP TYPE/DOMAIN** (una vez que ninguna
  tabla/columna los use). El `DROP ... CASCADE` de tipo es de emergencia (borra usos); se documenta,
  no se recomienda.
- En despliegue a nube (etapa 8) los SQL de migración deben reproducir el mismo orden de creación
  (los tipos primero); en el dump/restore Pg usa este mismo orden interno.

### 6.3 Dependencia entre tipos y tablas (síntesis)

| Tipo | Alimenta |
|---|---|
| `estado_documento` | `Ingreso.estado`, `Transferencia.estado` |
| `cuit_dom` | `Bodega.cuit`; si se adopta la alternativa A de DEC-26: `Transportista.cuit` y `Empleado.cuit`; las FKs con rol a Bodega heredan su tipo si `cuit` es la PK |
| `dia_semana` (cond.) | `Sala.dia_cierre` |
| `tipo_uva_dom`/`tipo_vino_dom` (cond.) | `Cepa.tipo`, `Vino.tipo` |
| ninguno (tipos base) | todas las demás columnas (BIGINT/INTEGER/SMALLINT/NUMERIC/DATE/TIMESTAMP/TEXT/CHAR) |

### 6.4 Consideraciones para la implementación posterior

- **PostgreSQL ≥ 14** (mínimo de la consigna; los tipos descritos son estándar del motor).
- **Migraciones** (requisitos §9.1): los tipos user-defined se crean al inicio de `001_esquema.sql`
  (o en un archivo previo si la cátedra avala separarlos); las tablas por niveles FK (A-10 §8).
- **Carga masiva (etapa 3):** si los DEFAULT/trigger fijan fecha actual (RN-11, RN-13), plan
  documentado para reproducir el sembrado (requisitos §6 paso 5); el tipo no lo resuelve.
- **No usar FLOAT/REAL** en ningún importe — ya cubierto (criterio de aceptación cumplido por
  diseño).

---

## 7. Relación con A-12 (DEC-25…DEC-33 y afines)

| DEC (A-12) | Tema | Estado tras A-13 |
|---|---|---|
| **DEC-25** | ENUM `estado_documento` | **Prop [R]** (valores y alcance definidos; formalización de creación en etapa 2 quede a equipo). Comprobante sin estado respaldado queda dicho. |
| **DEC-26** | DOMAIN CUIT y alcance | **Prop** formato (11 dígitos); alcance Bodega [R] + Transportista/Empleado [I]; **dígito verificador PENDIENTE** (docente/equipo). |
| **DEC-27** | dia_cierre (Q-09) | **PENDIENTE** — DOMAIN `dia_semana` propuesto como forma; conjunto de valores (¿«sin cierre»?) requiere docente. |
| **DEC-28** | tipo_uva/tipo_vino materialización | **PENDIENTE** — alternativas A (CHECK de lista) y B (DOMAIN con CHECK); propuesta por defecto A; sin decisión. |
| **DEC-29** | volúmenes (P-8) | Tipo `SMALLINT` **prop**; CHECK de lista cerrada vs orientativa **PENDIENTE**. |
| **DEC-30** | salario (Q-08) | Tipo NUMERIC(12,2) **prop**; CHECK `>0` **PENDIENTE**. |
| **DEC-31** | tipos físicos por columna | Desarrollado en §4/§8 con precisiones [I] justificadas; revizable etapa 2 (**prop**, no «definida»). |
| **DEC-32** | Q-01 descuento columna vs función | Tipo NUMERIC(5,2) **prop**; el fondo (columna vs función; P-9 30% vs 35%) **PENDIENTE** — no cerrado. |
| **DEC-33** | UNIQUEs sin respaldo | Fuera de alcance de tipos (afecta CONSTRAINT UNIQUE, no tipo) — no tocado. |
| **DEC-10** | forma de PK «ID» / autogeneración | **ADOPTADA**: `BIGINT GENERATED ALWAYS AS IDENTITY`; la carga masiva usará `OVERRIDING SYSTEM VALUE` (etapa 3). |
| **DEC-23** | Q-05 / R-5 importes | Tipos condicionales documentados (§4.1/§8: NUMERIC(5,2) si %, NUMERIC(12,2) si importe); guardar vs calcular **PENDIENTE**. |
| **DEC-14** | política NOT NULL | Se permiten NOT NULL en componentes de PK y en FKs con mínimo 1 respaldado textualmente, conforme a A-09 §6.3. No se derivan NOT NULL físicos para atributos descriptivos a partir de «Siempre» de A-02; quedan [P] para etapa 2. |

**Otros enlaces propuestos:** DEC-15/16/17: **RESUELTAS en cierre** (corregidas en A-09; A-13 ya
usaba las fuentes correctas). DEC-02: **RESUELTA** (PK de `Lote` compuesta; FK #8 sin ambigüedad).
DEC-01…09 y DEC-13: decisiones de PK adoptadas; los tipos de las FK dependientes
están especificados en §8 conforme a esas decisiones. La definición de la PK de
`Bodega` continúa pendiente de confirmación en el modelo. DEC-21 (cuarta UNIQUE)
y DEC-24 (acciones referenciales): fuera del alcance de tipos.

---

## 8. Matriz de trazabilidad: entidad — atributo — tipo — justificación — fuente — estado

Cobertura: **29 tablas / 128 columnas** (conteo de referencia: A-10 §9.2). Los tipos de las columnas FK están fijados por las DEC adoptadas (ver §7); las columnas con decisión aún abierta se marcan «pend» dentro de §8.

### 8.1 Localidad (5)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id_localidad | BIGINT `GENERATED ALWAYS AS IDENTITY` | PK subrogada ADOPTADA (DEC-01/DEC-10) | DEC-01; DEC-10 | D |
| codigo_postal | TEXT | Formato CP variable; sin UNIQUE; ya no candidata a PK (DEC-01) | sec. 5; DEC-01 | prop |
| nombre | TEXT | Sin límite textual | sec. 5 | prop |
| provincia | TEXT | Sin límite textual | sec. 5 | prop |
| encargado_regional | TEXT | Atributo lógico (dependencia funcional RN-02) | RN-02; D-4 | prop |

### 8.2 Sala (5)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id_sala | BIGINT `GENERATED ALWAYS AS IDENTITY` | Identificador subrogado autogenerado; forma adoptada (DEC-10) [R] | sec. 5; DEC-10 | D |
| calle | TEXT | Sin límite textual | sec. 5 | prop |
| numero | INTEGER | Altura de dirección (entero corto) | sec. 5 | prop |
| dia_cierre | DOMAIN `dia_semana` (prop.) | Dominio cerrado; conjunto pendiente | sec. 5; Q-09 | pend |
| localidad | BIGINT (→ `Localidad.id_localidad`) | NOT NULL; FK #1; tipo fijado por DEC-01 | A-09 §5; DEC-01 | prop |

### 8.3 Empleado (6)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id_empleado | BIGINT `GENERATED ALWAYS AS IDENTITY` | PK subrogada ADOPTADA (DEC-09/DEC-10) | DEC-09; DEC-10 | D |
| cuit | DOMAIN `cuit_dom` | Formato [R]; atributo fiscal sin UNIQUE (la PK no es cuit: DEC-09) | etapa 2; DEC-09 | prop |
| nombre | TEXT | Sin límite textual | sec. 5 | prop |
| fecha_ingreso | DATE | Fecha [R] | sec. 5 | D |
| salario | NUMERIC(12,2) | Dinero (nunca FLOAT); CHECK >0 PEND Q-08 | sec. 5 | prop / pend (CHECK) |
| sala | BIGINT (→ `Sala.id_sala`) | NOT NULL; FK #2; PK de Sala [R] (DEC-10) | RN-03; DEC-10 | prop |

### 8.4 Finca (5)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id_finca | BIGINT `GENERATED ALWAYS AS IDENTITY` | Identificador subrogado; forma adoptada (DEC-10) [R] | sec. 5; DEC-10 | D |
| nombre | TEXT | Sin límite textual | sec. 5 | prop |
| superficie | NUMERIC(8,2) | Magnitud continua; >0 [R] | RN-15 | prop |
| departamento | TEXT | Catálogo vs atributo: PEND Q-11 | sec. 5; Q-11 | prop / pend |
| provincia | TEXT | Sin límite textual | sec. 5 | prop |

### 8.5 Parcela (5, débil)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| finca | BIGINT | NOT NULL; FK propietaria, componente de PK [R] | 3.2 | D |
| n_parcela | INTEGER | NOT NULL; clave parcial y componente de PK [R] | sec. 5 | D |
| superficie | NUMERIC(8,2) | Magnitud continua; >0 [R] | RN-15 | prop |
| anio_plantacion | SMALLINT | Año [I] | sec. 5 | prop |
| cepa | BIGINT (→ `Cepa.id`) | NOT NULL; FK #5; tipo fijado por DEC-10 | RN-04; DEC-10 | prop |

### 8.6 Cepa (3)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id | BIGINT `GENERATED ALWAYS AS IDENTITY` | Identificador subrogado; forma adoptada (DEC-10) [R] | sec. 5; DEC-10 | D |
| nombre | TEXT | Candidata CeK-2 sin UNIQUE | Anexo B | prop |
| tipo | TEXT + CHECK ('tinta','blanca') | Dominio binario textual [R]; DOMAIN opcional PEND | 3.2 | prop / pend (material) |

### 8.7 Lote (7)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| n_lote | INTEGER | Descriptivo, sin UNIQUE (PK de `Lote` RESUELTA por DEC-02: compuesta) | sec. 5 | prop (DEC-02) |
| finca | BIGINT | NOT NULL; componente de PK compuesta (DEC-02) y de FK #6 → `Parcela` | REL-06; DEC-02 | prop |
| n_parcela | INTEGER | NOT NULL; componente de PK compuesta (DEC-02) y de FK #6 → `Parcela` | REL-06; DEC-02 | prop |
| campania | SMALLINT | NOT NULL; año de campaña [I; D-5]; tercera componente de la PK compuesta (DEC-02) | 3.2; DEC-02 | prop |
| fecha_cosecha | DATE | Fecha [R]; coherencia con campaña PENDIENTE | sec. 5 | prop / pend (CHECK) |
| kg | NUMERIC(10,2) | Magnitud continua; >0 [R] | RN-15 | prop |
| bodega_destino | `cuit` (DOMAIN `cuit_dom`) | NOT NULL; FK #7 con rol [R]; tipo = PK de Bodega [R] | sec. 5; AMB-06 | prop |

### 8.8 Analisis (8)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id_analisis | BIGINT GENERATED ALWAYS AS IDENTITY | Identificador subrogado autogenerado; DEC-10 adoptada [R] | DEC-10 | D |
| finca | BIGINT | Primera columna de la FK compuesta #8 hacia Lote | REL-08; DEC-02 | D |
| n_parcela | INTEGER | Segunda columna de la FK compuesta #8 hacia Lote | REL-08; DEC-02 | D |
| campania | SMALLINT | Tercera columna de la FK compuesta #8 hacia Lote; rango por justificar [I] | REL-08; DEC-02 | prop |
| fecha | DATE | Fecha [R]; AK extendida `(finca, n_parcela, campania, fecha)` sin garantía (AMB-13) | sec. 5 | prop / pend (AK) |
| brix | NUMERIC(5,2) | Precisión plausible [I]; dominio pendiente | sec. 5 | prop / pend (dominio) |
| ph | NUMERIC(3,2) | Precisión plausible [I]; dominio pendiente | sec. 5 | prop / pend (dominio) |
| acidez | NUMERIC(5,2) | Precisión plausible [I]; concentración en g/L; dominio pendiente | 3.2 | prop / pend (dominio) |

### 8.9 Bodega (3)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| cuit | DOMAIN `cuit_dom` | 11 dígitos [R]; UNIQUE textual [R]; elección como PK pendiente de confirmar en el modelo | etapa 2; A-09 | prop / pend (PK) |
| razon_social | TEXT | Sin UNIQUE (descartada) | sec. 5 | prop |
| domicilio | TEXT | Sin límite textual | sec. 5 | prop |

### 8.10 Vino (8)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| codigo | TEXT | NOT NULL; PK ADOPTADA (DEC-03); UNIQUE triada `(nombre, anada, volumen_ml)` [R] | API `GET /vinos/{cod}`; DEC-03 | prop (PK DEC-03) |
| nombre | TEXT | Parte de UNIQUE `(nombre, anada, volumen_ml)` [R] | etapa 2; 3.3 | prop |
| tipo | TEXT + CHECK ('tinto','blanco','rosado','espumante') | Dominio textual [R]; materialización PENDIENTE | 3.3 | prop / pend (material) |
| anada | SMALLINT | Año [I] | sec. 5; 3.3 | prop |
| volumen_ml | SMALLINT | 187–3000 ml [I]; CHECK de catálogo PENDIENTE (P-8) | Anexo A.2/B.4 | prop / pend (CHECK) |
| graduacion | NUMERIC(4,1) | Rango 5–20 [R]; escala [I] | RN-15 | prop |
| precio | NUMERIC(12,2) | Dinero exacto (nunca FLOAT) [R]; >0 [R] | RN-01; §5.2 | prop |
| bodega | `cuit` (DOMAIN `cuit_dom`) | NOT NULL; FK #9 [R: RN-14]; tipo = PK de Bodega [R] | REL-09 | prop |

### 8.11 Composicion (3)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; FK #10; componente de PK; tipo fijado por DEC-03 | A-05; DEC-03 | prop |
| cepa | BIGINT (→ `Cepa.id`) | NOT NULL; FK #11; componente de PK; tipo fijado por DEC-10 | A-05; DEC-10 | prop |
| porcentaje | NUMERIC(5,2) | 0–100 [I]; CHECK individual PENDIENTE; suma 100 = RN-05 (etapas 2) | RN-05 | prop / pend |

### 8.12 Maridaje (3)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id | BIGINT GENERATED ALWAYS AS IDENTITY | Identificador subrogado autogenerado; DEC-10 adoptada [R] | DEC-10 | D |
| nombre | TEXT | Candidata MK-2 sin UNIQUE; ej. «cordero al disco» (I2) | sec. 5; I2 | prop |
| temperatura | NUMERIC(3,1) | °C plausible [I]; dominio pendiente; fuente real 3.3/sec. 5 (la cita RN-06 de A-09 es errónea) | 3.3 | prop / pend (dominio) |

### 8.13 Vino_Maridaje (2)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; FK #12; componente de PK; tipo fijado por DEC-03 | A-05; DEC-03 | prop |
| maridaje | BIGINT (→ `Maridaje.id`) | NOT NULL; FK #13; componente de PK; tipo fijado por DEC-10 | A-05; DEC-10 | prop |

### 8.14 Cliente (8) — supertipo

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id_cliente | BIGINT `GENERATED ALWAYS AS IDENTITY` | Identificador subrogado; forma adoptada (DEC-10) [R] | sec. 5; DEC-10 | D |
| nombre | TEXT | Un campo o dos: PENDIENTE Q-04 | sec. 5 | prop / pend (Q-04) |
| tipo_doc | TEXT | Dominio (DNI/CUIT) sin lista textual | sec. 5 | prop |
| n_doc | TEXT | Documento; pueden coexistir DNI y CUIT. Candidata UNIQUE `(tipo_doc, n_doc)` pendiente de confirmación | sec. 5; A-10 §2.14 | prop / pend (UNIQUE) |
| direccion | TEXT | Campo único vs desglosado: PENDIENTE Q-10 | sec. 5 | prop / pend (Q-10) |
| localidad | BIGINT (→ `Localidad.id_localidad`) | FK #3; tipo fijado por DEC-01 | REL-03; DEC-01 | prop |
| fecha_alta | DATE | Fecha [R]; DEFAULT CURRENT_DATE [R] | etapa 2 | D |
| descuento | NUMERIC(5,2) | Porcentaje con CHECK de rango [R RN-06]; fondo Q-01/P-9 PENDIENTE | RN-06 | prop / pend |

### 8.15 Socio (1) / 8.16 Distribuidor (3) / 8.17 Exportador (2) — subtipos

| Tabla | Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|---|
| Socio | id_cliente | BIGINT | NOT NULL; PK/FK heredada del supertipo; AMB-07 ADOPTADA como diseño (DEC-11/12); mecanismo físico pendiente en etapa 2 | A-06; DEC-11/12 | prop / pend (mecanismo) |
| Distribuidor | id_cliente | BIGINT | NOT NULL; PK/FK heredada del supertipo; AMB-07 ADOPTADA como diseño (DEC-11/12); mecanismo físico pendiente en etapa 2 | A-06; DEC-11/12 | prop / pend (mecanismo) |
| Distribuidor | zona | TEXT | Descriptivo | sec. 5 | prop |
| Distribuidor | n_habilitacion | TEXT | Candidata DK-2 sin UNIQUE | sec. 5 | prop |
| Exportador | id_cliente | BIGINT | NOT NULL; PK/FK heredada del supertipo; AMB-07 ADOPTADA como diseño (DEC-11/12); mecanismo físico pendiente en etapa 2 | A-06; DEC-11/12 | prop / pend (mecanismo) |
| Exportador | pais | TEXT | Descriptivo | sec. 5; 3.4 | prop |

### 8.18 Permiso_Exportacion (4)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| codigo | TEXT | NOT NULL; PK ADOPTADA (DEC-04) | sec. 5; DEC-04 | prop (PK DEC-04) |
| exportador | BIGINT (→ `Exportador.id_cliente`) | FK #21; ON DELETE no decidido (DEC-24) | REL-16; DEC-13/10 | prop / pend (ON DELETE) |
| fecha_emision | DATE | Fecha [R]; candidata UNIQUE `(exportador, fecha_emision)` pendiente de confirmación | sec. 5; A-10 §2.18 | prop / pend (UNIQUE) |
| fecha_vencimiento | DATE | > emisión [R RN-07, CHECK entre columnas] | RN-07 | D |

### 8.19 Comprobante (7)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| numero | BIGINT | NOT NULL; PK GLOBAL ADOPTADA (DEC-05) | sec. 5; API; DEC-05 | D |
| fecha | DATE | Fecha [R] | sec. 5 | D |
| cliente | BIGINT | FK #14; NOT NULL | REL-12 | prop |
| sala | BIGINT | FK #15; NOT NULL | REL-13 | prop |
| subtotal | NUMERIC(12,2) | Dinero [R]; almacenar vs calcular PENDIENTE (R-5) | RN-08 | prop / pend (R-5) |
| descuento | NUMERIC(5,2) si % / NUMERIC(12,2) si importe | **PENDIENTE Q-05** | Q-05 | pend |
| total | NUMERIC(12,2) | Dinero [R]; idem R-5 | RN-08 | prop / pend (R-5) |

### 8.20 Renglon_Comprobante (6)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| comprobante | BIGINT (→ `Comprobante.numero`) | NOT NULL; FK #16; componente de PK; ON DELETE CASCADE preferente, sujeto a confirmación (DEC-24) | sec. 5; DEC-05/24 | prop / pend (ON DELETE) |
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; FK #17; componente de PK [R]; ON DELETE RESTRICT pendiente de confirmación | RN-14; DEC-03 | prop / pend (ON DELETE) |
| cantidad | INTEGER | CHECK > 0 [R]; control de stock (RN-09) en etapa 2 | RN-15 | prop |
| precio_unitario | NUMERIC(12,2) | Dinero [R]; valor histórico capturado | A-02 R-4 | prop |
| descuento | NUMERIC(5,2) si % / NUMERIC(12,2) si importe | **PENDIENTE Q-05** | Q-05 | pend |
| subtotal | NUMERIC(12,2) | Dinero [R]; derivado; R-5 PENDIENTE | RN-08 | prop / pend |

### 8.21 Transportista (6)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| codigo | TEXT | NOT NULL; **PK ADOPTADA (DEC-08)** | sec. 5; DEC-08 | D |
| razon_social | TEXT | Sin UNIQUE (descartada) | sec. 5 | prop |
| cuit | DOMAIN `cuit_dom` | Formato respaldado [R]; no es clave candidata de Transportista y no lleva UNIQUE [R] | DEC-08; etapa 2 | prop |
| email | TEXT | Validación de formato PENDIENTE (sin respaldo) | sec. 5 | prop / pend |
| telefono | TEXT | Sin formato textual | sec. 5 | prop |
| domicilio | TEXT | Sin límite textual | sec. 5 | prop |

### 8.22 Transportista_Localidad (2)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| transportista | TEXT (→ `Transportista.codigo`) | NOT NULL; FK #22; componente de PK; ON DELETE CASCADE pendiente de confirmación | REL-17; DEC-08/24 | prop / pend (ON DELETE) |
| localidad | BIGINT (→ `Localidad.id_localidad`) | NOT NULL; FK #23; componente de PK; ON DELETE RESTRICT [R: A-09] | REL-17; DEC-01; A-09 | D |

### 8.23 Ingreso (5)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| codigo | TEXT | NOT NULL; PK global adoptada (DEC-06) | sec. 5; API; DEC-06 | D |
| fecha | DATE | Fecha [R]; semántica PENDIENTE Q-03 | sec. 5; Q-03 | prop / pend (Q-03) |
| estado | ENUM `estado_documento` | DEFAULT `en_confeccion` [R]; transiciones controladas por trigger/procedimiento (RN-10) | RN-10; etapa 2 | prop |
| transportista | TEXT (→ `Transportista.codigo`) | NOT NULL; FK #24; ON DELETE RESTRICT [R: RN-14]; tipo fijado por DEC-08 | REL-19; DEC-08; RN-14 | D |
| bodega_origen | DOMAIN `cuit_dom` (→ `Bodega.cuit`) | FK #25; NOT NULL; ON DELETE RESTRICT [R: RN-14]; representa el rol de bodega de origen (AMB-06) | REL-18; AMB-06; RN-14 | prop |

### 8.24 Renglon_Ingreso (3)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| ingreso | TEXT (→ `Ingreso.codigo`) | NOT NULL; FK #26; componente de PK; ON DELETE CASCADE pendiente de confirmación (DEC-24; RI-a) | REL-20; DEC-06/24 | prop / pend (RI-a) |
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; FK #27; componente de PK; ON DELETE RESTRICT pendiente de confirmación | REL-20; DEC-03 | prop / pend (ON DELETE) |
| cantidad | INTEGER | CHECK > 0 [R: RN-15] | RN-15 | prop |

### 8.25 Transferencia (4)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| numero | BIGINT | NOT NULL; PK global adoptada (DEC-07) | sec. 5; API; DEC-07 | D |
| fecha_confeccion | DATE | Inmodificable mediante trigger (RN-11); DEFAULT `CURRENT_DATE` propuesto, pendiente de confirmación | RN-11 | prop / pend (DEFAULT) |
| estado | ENUM `estado_documento` | DEFAULT `en_confeccion`; transiciones controladas mediante trigger/procedimiento (RN-11) | RN-11; etapa 2 | prop |
| sala | BIGINT | FK #28; NOT NULL; ON DELETE RESTRICT pendiente de confirmación | REL-21 | prop / pend (ON DELETE) |

### 8.26 Renglon_Transferencia (3)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| transferencia | BIGINT (→ `Transferencia.numero`) | NOT NULL; FK #29; componente de PK; ON DELETE CASCADE preferente (DEC-24), pendiente RT-a | REL-22; DEC-07/24 | prop / pend (RT-a) |
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; FK #30; componente de PK; ON DELETE RESTRICT pendiente de confirmación | REL-22; DEC-03 | prop / pend (ON DELETE) |
| cantidad | INTEGER | CHECK > 0 [R: RN-15] | RN-15 | prop |

### 8.27 Stock_Sala (3)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| sala | BIGINT | NOT NULL; FK #31 hacia Sala con ON DELETE RESTRICT [R: A-09]; componente de PK [R] | sec. 5; A-09 | D |
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; FK #32; componente de PK [R] | sec. 5; DEC-03 | prop |
| cantidad | INTEGER | `>= 0` [R sec. 5/RN-09]; DEFAULT 0 PENDIENTE (AMB-11/DEC-19) | sec. 5 | prop / pend |

### 8.28 Stock_Deposito (2)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; PK/FK #33; ON DELETE RESTRICT pendiente; existencia de la fila condicionada por D-3/AMB-11 | sec. 5; DEC-03; D-3; AMB-11 | prop / pend |
| cantidad | INTEGER | CHECK >= 0 [R]; DEFAULT 0 pendiente (AMB-11) | sec. 5; AMB-11 | prop / pend |

### 8.29 Auditoria_Precio (6)

| Atributo | Tipo propuesto | Justificación | Fuente | Estado |
|---|---|---|---|---|
| id_auditoria | BIGINT `GENERATED ALWAYS AS IDENTITY` | PK autogenerada; forma adoptada (DEC-10) [R] | RN-13; DEC-10 | D |
| vino | TEXT (→ `Vino.codigo`) | NOT NULL; FK #34 ON DELETE RESTRICT [R: RN-13, trazabilidad] | RN-13; DEC-03 | D |
| precio_anterior | NUMERIC(12,2) | Dinero [R] | RN-13 | prop |
| precio_nuevo | NUMERIC(12,2) | Dinero [R] | RN-13 | prop |
| fecha_hora | TIMESTAMP | Fecha y hora [R]; candidata UNIQUE `(vino, fecha_hora)` pendiente (AU-2); DEFAULT a definir en etapa 2 | sec. 5; AU-2 | prop / pend (AK; DEFAULT) |
| usuario | TEXT | Semántica pendiente de Q-07 | sec. 5; Q-07 | prop / pend (Q-07) |

### 8.30 Verificación de cobertura

| Control | Resultado |
|---|---|
| Tablas de A-09 §2 documentadas en §8 | 29/29 |
| Columnas de A-10 §9.2 cubiertas | 128/128 (5+5+6+5+5+3+7+8+3+8+3+3+2+8+1+3+2+4+7+6+6+2+5+3+4+3+3+2+6 = 128; conteo actualizado en cierre: `id_localidad` (DEC-01), `id_empleado` (DEC-09), `Analisis` de 6 a 8 (DEC-02)) |
| Atributos sin tipo propuesto | ninguno (los que están «pend» dependen de una PK/DEC ajena, no de falta de análisis) |

---

## 9. Verificación final (checklist de la tarea)

1. **Existen al menos un ENUM y un DOMAIN propuestos:** sí — `estado_documento` (§2) y `cuit_dom`
   (§3); DOMAINs/estado condicionales (`dia_semana`, `tipo_uva/vino`) marcados PENDIENTES, no como
   aprobados.
2. **Los tipos responden al diccionario:** sí — §8 cubre 29 tablas / 128 columnas de A-10 con su
   justificación y fuente; ningún tipo modifica el esquema relacional de A-09.
3. **No se usan tipos aproximados para importes:** confirmado — todos los importes usan
   `NUMERIC(p,s)`; ninguna columna usa FLOAT/REAL/DOUBLE PRECISION (§4.1, §4.4 y §8). Solo queda
   condicional si `descuento` (cabecera/renglón) es porcentaje o importe (Q-05), también con
   alternativas exactas.
4. **Decisiones pendientes identificadas:** sí — §3.2 (dígito verificador), §4 (casos Q-03, Q-05,
   Q-07, Q-09, P-6, P-8, Q-10, Q-11), §5, §7 (mapeo DEC-25…DEC-33 más DEC-10/DEC-14/DEC-23/DEC-24)
   y filas `pend` de §8. Cada pendiente indica qué falta, por qué afecta al tipo, alternativas
   técnicas y actor responsable (docente / Persona B / equipo).
5. **Coherencia y ortografía:** revisada; sin lenguaje ofensivo ni texto fuera de registro, sin SQL, sin cambios a A-01…A-12 ni a
   `docs/requisitos.md`.
6. **Archivos creados/modificados:** creado `docs/modelo/13_tipos_postgresql_enum_domain.md`;
   no modificados ninguno de los demás documentos; sin commits ni push.

7. **Criterios de aceptación no plenamente alcanzados (condicionados):** el documento
   mantiene estado **PRELIMINAR** hasta completar: (a) revisión de A-08/A-09/A-06
   (Persona B/docente: jerarquía AMB-07 y decisiones de PK aún pendientes que afectan
   los tipos de las columnas FK); (b) respuestas del docente sobre Q-05, Q-08, Q-09,
   P-6, P-8 y el dígito verificador del CUIT; (c) decisiones de equipo pendientes,
   especialmente DEC-28 (CHECK vs. DOMAIN para tipos de uva/vino). DEC-10
   (autogeneración de `id_*`) está ADOPTADA y no constituye un pendiente.
   Las propuestas de tipos están documentadas y justificadas, pero las decisiones
   pendientes deben resolverse antes de considerar definitivo el diseño y ejecutar
   el DDL.

---

### Registro de cambios de este documento
- Cierre (2): sincronización DEC-01…DEC-10: id_localidad/id_empleado incorporados (§8.1/§8.3); conteo corregido 126/128; PK de Vino/Permiso/Comprobante/Ingreso/Transferencia/Transportista marcadas ADOPTADAS y tipos de FK fijados; DEC-10 detallada con IDENTITY; nota en §9.7.
- Cierre: sincronizado con DEC-02 (8.7/8.8/§7: PK de `Lote` compuesta, FK #8 compuesta, AK de `Analisis` extendida); backticks multi-línea de §4.3/§4.4 reparados; DEC-15/16/17 marcadas RESUELTAS.

- Creación (A-13, PRELIMINAR): propuesta ENUM `estado_documento` (valores [R], alcance
  Ingreso/Transferencia; se registra que Comprobante y Permiso no tienen estado respaldado), DOMAIN
  `cuit_dom` con validación de formato propuesta y análisis detallado del dígito verificador
  (pendiente), selección de tipos por categoría (NUMERIC(12,2) importes; NUMERIC(5,2) porcentajes;
  DATE/TIMESTAMP fechas; INTEGER/SMALLINT cantidades/años/volúmenes; NUMERIC(4,1)/(3,1) graduación/
  temperatura; BIGINT identificadores subrogados; TEXT códigos/textos; tipos de PK dependientes
  quedados [P]), orden de creación/eliminación de tipos con dependencias (§6), matriz de trazabilidad
  29 tablas / 128 columnas (§8) y mapeo con DEC-25…DEC-33 sin cerrar decisiones pendientes.
  Sin DDL, sin migraciones, sin Docker, sin commits.

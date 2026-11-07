# A-12 - Matriz consolidada de decisiones pendientes del modelo

> **Estado: documento de trabajo para el responsable del proyecto.** El estado de cada decisión se indica en su entrada individual. DEC-01…DEC-17 están resueltas o adoptadas; DEC-18…DEC-52 permanecen pendientes, según el resumen de §9.
>
> Este documento consolida decisiones y propuestas de diseño. Las recomendaciones técnicas no constituyen decisiones hasta que se adopten expresamente. Las decisiones adoptadas deben reflejarse en los documentos y artefactos correspondientes.
> **Fuentes releveadas:** `docs/requisitos.md` (§4 RN, §5 entidades/resto, §5.2 mínimos etapa 2,
> §10 ambigüedades/preguntas), A-01…A-07 (D-1…D-10, Q-01…Q-13, R-1…R-12), A-04 (REL-01…25,
> AMB-01…17), A-05 (casos especiales), A-06 (jerarquía, revisión Persona B pendiente), A-07 (DFs
> y 3FN), A-08 (DER), A-09 §2-§14 (esquema PRELIMINAR), A-10 §2-§9 (diccionario PRELIMINAR),
> A-11 (auditoría, OBS-01…OBS-14).
>
> **Nota de estado de aprobación:** A-08 pendiente de revisión; A-09 PRELIMINAR condicionado a
> A-08; A-10 PRELIMINAR; A-11 revisado técnicamente pero la revisión de Persona B sigue PENDIENTE.

---

## 0. Verificación previa: coherencia del desglose de A-11

**Comprobación solicitada (§3.D):** A-11 declara **14 observaciones** (OBS-01…OBS-14). Su desglose
final por gravedad (§4) registra: crítica 0, alta 4, media 5, baja 3, resuelta sin acción 1
(= 13 unidades clasificadas). **Resultado de la verificación:** la lista detallada sí contiene 14
observaciones; la discrepancia está en el resumen por gravedad, que **omite OBS-13**, clasificada
con gravedad **media** en su propia sección (DEC sobre Q-05 y guardar-vs-calcular, §2 de A-11).
Desglose real verificado: **alta 4 (OBS-04…07) · media 6 (OBS-01, 02, 03, 08, 09, 13) · baja 4
(OBS-10, 11, 12, 14) = 14**. La omisión fue explicada y **se corrigió en A-11 durante el cierre**
(su §4 ahora incluye OBS-13 en Media). El total declarado (14) es correcto.

---

## 1. Índice de decisiones

| Grupo | Decisiones |
|---|---|
| **A. Claves primarias y candidatas** | DEC-01 … DEC-10 |
| **B. Jerarquía de clientes** | DEC-11 … DEC-13 |
| **C. Inconsistencias detectadas en A-10** | DEC-14 … DEC-17 |
| **D. Observaciones de A-11** | DEC-18 … DEC-24 |
| **E. Tipos y restricciones** | DEC-25 … DEC-33 |
| **F. Otras decisiones pendientes** | DEC-34 … DEC-52 |

---

## 2. Grupo A - Claves primarias y candidatas (decisiones adoptadas)

Las alternativas de PK que estaban pendientes para Localidad, Lote, Vino,
Permiso_Exportacion, Comprobante, Ingreso, Transferencia, Transportista y
Empleado fueron resueltas mediante decisiones de diseño documentadas en
DEC-01 a DEC-09. La generación automática de los identificadores subrogados
también fue adoptada en DEC-10.

**Criterio general:** las claves se eligieron considerando la unicidad,
la estabilidad de los identificadores, la simplicidad de las FK y el respaldo
disponible en la consigna. Cuando la elección constituye un supuesto o una
decisión de diseño no exigida textualmente, se deja expresamente documentado.

### DEC-01 - PK de `Localidad`
- **Tema:** identificador de localidad.
- **Documentos afectados:** A-03 §2.1 (LK-1/LK-2), A-09 §2.1/§4, A-10 §2.1, A-11 OBS-05.
- **Decisión adoptada:** PK subrogada `id_localidad BIGINT GENERATED ALWAYS AS IDENTITY`.
- **Fundamento:** ni `codigo_postal` ni `(nombre, provincia)` tienen unicidad garantizada por la consigna. Un código postal puede abarcar varias localidades y pueden existir localidades homónimas. El identificador subrogado permite referencias simples y estables.
- **Atributos conservados:** `codigo_postal`, `nombre` y `provincia` permanecen como atributos descriptivos. No se impone UNIQUE sobre ellos sin respaldo suficiente.
- **Consecuencias:** las FK #1 (Sala), #3 (Cliente) y #23 (Transportista_Localidad) referencian `Localidad.id_localidad BIGINT`. La DF de A-07 debe conservarse sin asumir que el código postal identifica unívocamente una localidad.
- **Alternativas descartadas:** `codigo_postal` como PK y `(nombre, provincia)` como PK, por no contar con garantía de unicidad.
- **Naturaleza:** decisión de diseño adoptada; no es un identificador exigido textualmente por la consigna.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-02 - PK de `Lote`
- **Tema:** identificador de lote.
- **Documentos:** A-03 §2.7 (LoteK-1/2), A-09 §2.7/§4, A-10 §2.7.
- **Decisión adoptada:** PK compuesta `(finca, n_parcela, campania)`, extendiendo la
  identificación de `Parcela` con la campaña correspondiente.
- **Fundamento:** RN-04 establece que una parcela se cosecha como máximo una vez por
  campaña. Adoptamos como regla de negocio que cada combinación de parcela y campaña
  genera como máximo un lote. La combinación permite identificar el lote sin depender
  de que `n_lote` sea globalmente único.
- **Minimalidad:** asumimos que una parcela puede cosecharse en distintas campañas y que
  una campaña puede incluir distintas parcelas. Por lo tanto, ninguno de los componentes
  de la clave compuesta identifica por sí solo un lote.
- **`n_lote`:** se conserva como atributo descriptivo, sin imponer unicidad global.
- **Cosechas parciales:** adoptamos que las cosechas parciales de una misma parcela y
  campaña no generan lotes independientes.
- **Consecuencias:** la FK #8 (`Analisis.lote`) debe referenciar las tres columnas de la
  PK de `Lote`. La PK garantiza la unicidad de la combinación parcela-campaña.
- **Justificación de la alternativa descartada:** no elegimos `n_lote` como PK porque
  la consigna no establece expresamente su unicidad global. Tampoco incorporamos una
  clave subrogada porque la clave compuesta representa una regla de negocio suficiente.
- **¿Decidible con la información disponible?:** Sí, mediante las decisiones de diseño
  y las reglas de negocio adoptadas.
- **Estado:** RESUELTA.

### DEC-03 - PK de `Vino`

- **Tema:** identificador de vino.
- **Documentos:** A-03 §2.10, A-09 §2.10/§4, A-10 §2.10.
- **Decisión adoptada:** `codigo TEXT` como PK y UNIQUE sobre `(nombre, anada, volumen_ml)`.
- **Fundamento:** el código permite FKs simples y coincide con el identificador utilizado por la API `GET /vinos/{cod}`. La triada conserva la restricción UNIQUE respaldada textualmente.
- **Supuesto adoptado:** `codigo` identifica unívocamente cada vino. Es una decisión de diseño, no una unicidad declarada expresamente en la consigna.
- **Consecuencias:** todas las FK que referencian Vino utilizan `TEXT` y apuntan a `Vino.codigo`.
- **Alternativa descartada:** `(nombre, anada, volumen_ml)` como PK, porque generaría FKs compuestas innecesariamente extensas.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-04 - PK de `Permiso_Exportacion`

- **Tema:** identificador del permiso de exportación.
- **Decisión adoptada:** `codigo TEXT` como PK.
- **Fundamento:** evita depender de `(exportador, fecha_emision)`, combinación que no garantiza distinguir permisos emitidos el mismo día.
- **Naturaleza:** unicidad del código adoptada como decisión de diseño.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-05 - PK de `Comprobante`

- **Tema:** numeración global frente a numeración por sala.
- **Decisión adoptada:** `numero BIGINT` como PK global.
- **Fundamento:** la API `GET /comprobantes/{nro}` utiliza el número como identificador directo. No hay respaldo textual para numeración por sala.
- **Consecuencias:** `Renglon_Comprobante.comprobante` referencia `Comprobante.numero`.
- **Naturaleza:** alcance global adoptado como decisión de diseño.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-06 - PK de `Ingreso`

- **Tema:** identificador del ingreso.
- **Decisión adoptada:** `codigo TEXT` como PK global.
- **Fundamento:** la API `/ingresos/{codigo}` utiliza el código como identificador directo. Se mantiene un criterio uniforme con los demás documentos.
- **Consecuencias:** `Renglon_Ingreso.ingreso` referencia `Ingreso.codigo`.
- **Naturaleza:** unicidad global adoptada como decisión de diseño.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-07 - PK de `Transferencia`

- **Tema:** numeración global frente a numeración por sala.
- **Decisión adoptada:** `numero BIGINT` como PK global.
- **Fundamento:** la API `/transferencias/{nro}` utiliza el número como identificador directo. Se mantiene un criterio uniforme con Comprobante e Ingreso.
- **Consecuencias:** `Renglon_Transferencia.transferencia` referencia `Transferencia.numero`.
- **Naturaleza:** alcance global adoptado como decisión de diseño.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-08 - PK de `Transportista`

- **Tema:** identificador del transportista.
- **Decisión adoptada:** `codigo TEXT` como PK.
- **Fundamento:** el código es el identificador operacional previsto. El CUIT permanece como atributo fiscal, sin UNIQUE, porque la consigna no declara su unicidad para esta entidad.
- **Consecuencias:** las FK que referencian Transportista utilizan `TEXT` y apuntan a `Transportista.codigo`.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-09 - PK de `Empleado`

- **Tema:** identificador del empleado.
- **Decisión adoptada:** agregar `id_empleado BIGINT GENERATED ALWAYS AS IDENTITY` como PK.
- **Fundamento:** el CUIT permanece como atributo fiscal, sin presuponer unicidad no documentada. El identificador subrogado proporciona una clave estable.
- **Consecuencias:** `Empleado.sala` continúa siendo FK hacia Sala.
- **Naturaleza:** incorporación de identificador subrogado como decisión de diseño.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-10 - Autogeneración de identificadores `ID`

- **Tema:** generación de claves subrogadas respaldadas con identificadores «ID».
- **Decisión adoptada:** utilizar `BIGINT GENERATED ALWAYS AS IDENTITY` para `Sala.id_sala`, `Finca.id_finca`, `Cepa.id`, `Analisis.id_analisis`, `Maridaje.id`, `Cliente.id_cliente`, `Auditoria_Precio.id_auditoria`, y los nuevos `Localidad.id_localidad` y `Empleado.id_empleado`.
- **Fundamento:** los identificadores representan identidad de fila y no necesitan depender de valores asignados por el negocio. La generación automática facilita altas y evita colisiones accidentales.
- **Consecuencias:** las columnas serán autogeneradas por PostgreSQL. Las cargas iniciales deberán respetar la generación de identidad y la sincronización de secuencias cuando corresponda.
- **Alternativa descartada:** asignación manual de identificadores, por no existir una regla de negocio que la justifique.
- **Naturaleza:** decisión de implementación adoptada para las claves subrogadas.
- **Estado:** RESUELTA — DECISIÓN DE DISEÑO ADOPTADA.

### DEC-11 - AMB-07 (a): la jerarquía es total
- **Tema:** ¿todo `Cliente` tiene al menos un subtipo?
- **Documentos:** A-04 §4 (AMB-07), A-06 §6, A-09 §10, A-11 OBS-06.
- **Decisión adoptada:** jerarquía total. Todo registro de `Cliente` debe pertenecer a exactamente un subtipo: `Socio`, `Distribuidor` o `Exportador`.
- **Fundamento:** A-06 adopta esta alternativa como decisión de diseño, apoyada en las tres categorías de clientes identificadas en la consigna y en la necesidad de determinar el descuento por tipo (RN-06). La totalidad no se presenta como una exigencia textual de la consigna.
- **Consecuencias:** el DER representa totalidad; el esquema relacional requiere mecanismos adicionales para garantizar que todo cliente tenga un subtipo, porque las PK/FK heredadas por sí solas no lo imponen.
- **Estado:** DECISIÓN DE DISEÑO ADOPTADA EN A-06. Su implementación debe resolverse en la etapa correspondiente.

### DEC-12 - AMB-07 (b): la jerarquía es disjunta
- **Tema:** ¿un cliente puede pertenecer a más de un subtipo?
- **Documentos:** A-04 §4 (AMB-07), A-06 §6, A-09 §10, A-11 OBS-06.
- **Decisión adoptada:** jerarquía disjunta. Cada `Cliente` puede pertenecer a un único subtipo.
- **Fundamento:** A-06 adopta esta alternativa como decisión de diseño. El descuento único por cliente (RN-06) y la estrategia de mapeo mediante supertipo y subtipos respaldan esta elección.
- **Consecuencias:** la PK heredada de `Cliente` en cada subtipo impide que un mismo cliente tenga más de una fila dentro de una misma tabla de subtipo, pero la exclusividad entre tablas requiere mecanismos adicionales de integridad.
- **Estado:** DECISIÓN DE DISEÑO ADOPTADA EN A-06. Su implementación debe resolverse en la etapa correspondiente.

### DEC-13 - Confirmación de la estrategia de mapeo de A-06 (supertipo + tablas de subtipos)
- **Tema:** estrategia de representación relacional de la jerarquía de clientes.
- **Documentos:** A-06 §5/§7, A-09 §10, A-10 §2.14–2.17, A-11 OBS-06.
- **Decisión adoptada:** mantener un supertipo `Cliente` y tres tablas de subtipos: `Socio`, `Distribuidor` y `Exportador`.
- **Alternativas consideradas:** (a) supertipo + subtipos; (b) tabla única con discriminador; (c) una tabla por subtipo sin estructura común. La comparación y justificación están documentadas en A-06 §3/§4.
- **Fundamento:** pocos atributos específicos, volumen estimado de 20.000 clientes, consultas por tipo (S3/D1/D4/D6) e integridad referencial centralizada mediante `Cliente`.
- **Consecuencias:** determina la PK/FK heredada de los subtipos, la relación de permisos con `Exportador`, las relaciones de comprobantes con `Cliente` y las consultas que combinan información de distintos tipos.
- **Estado:** ESTRATEGIA DE MAPEO ADOPTADA EN A-06. Las observaciones posteriores del equipo pueden documentarse sin considerar esta decisión pendiente mientras no se acuerde modificarla.
---

## 4. Grupo C - Inconsistencias detectadas en A-10 (§9.3)

### DEC-14 - Criterio de obligatoriedad física NOT NULL

- **Tema:** política física de `NOT NULL`.
- **Documentos:** A-02 §2 («Siempre»), A-09 §6.3, A-10 §6.2, A-11 OBS-04 (alta).
- **Situación:** A-02 utiliza «Siempre» para numerosos atributos. A-09 establece un criterio conservador: `NOT NULL` únicamente para componentes de PK y FK cuya participación mínima 1 tenga respaldo textual. A-10 y el DDL incorporaron algunas obligatoriedades descriptivas inferidas que no siguen ese criterio.
- **Alternativa A — ADOPTADA:** aplicar el criterio de A-09 §6.3. Se implementa `NOT NULL` en todas las columnas PK y en las FK con mínimo 1 respaldado textualmente. No se impone `NOT NULL` físico a atributos descriptivos únicamente por inferencia de «Siempre».
- **Alternativa B — DESCARTADA:** derivar automáticamente `NOT NULL` de la obligatoriedad conceptual «Siempre» de A-02. Se descarta porque introduciría restricciones físicas sin respaldo textual suficiente y contradiría el criterio documentado en A-09.
- **Fundamento:** se prioriza la trazabilidad entre consigna, modelo lógico y restricciones físicas. La obligatoriedad conceptual de un atributo no se transforma automáticamente en una restricción física sin una decisión de dominio fundamentada.
- **Consecuencias:** revisar A-10 y `001_esquema.sql`; retirar los `NOT NULL` descriptivos que no estén respaldados por una decisión específica. Mantener los `NOT NULL` de PK y FK respaldadas. Los `CHECK`, DEFAULT y demás restricciones se evalúan independientemente.
- **Alcance:** esta decisión no elimina reglas de negocio ni impide que una obligatoriedad descriptiva se adopte posteriormente si se fundamenta y documenta expresamente.
- **Estado:** **ADOPTADA**.

### DEC-15 - Aritmética del encabezado de A-09 §2 (§9.3-2 / A-11 OBS-01)
- **Tema:** «17 de entidades fuertes + 1 débil…» (suma 30) vs tabla de 29 filas (16 fuertes reales).
- **Documentos:** A-09 §2, A-10 §9.3-2, A-11 OBS-01 (media).
- **Problema:** doble conteo de la primera categoría; la tabla es correcta.
- **Alternativa A:** corregir el texto a «16 fuertes (+1 débil)».
- **Alternativa B:** no corregir, dejar nota en A-11/A-12 (actual).
- **Consecuencias:** cosmética; ninguna estructural.
- **Recomendación:** A (errata evidente; aplicar tras revisión de Persona B, no antes).
- **¿Decidible?:** Sí (el equipo); es corrección tipográfica aprobable en la revisión.
- **Estado:** RESUELTA (cierre).
- **Elección (cierre):** Alternativa A aplicada en A-09; pendiente la validación de Persona B como parte de la revisión de dicho documento.

### DEC-16 - Cita «RN-06» en Maridaje, A-09 §3.12 (§9.3-3 / A-11 OBS-02)

- **Tema:** trazabilidad errónea del `temperatura` de Maridaje.
- **Documentos:** A-09 §3.12, A-10 §2.12 (nota), A-11 OBS-02 (media).
- **Problema:** RN-06 regula el descuento por tipo de cliente; no la temperatura del maridaje.
- **Alternativa A:** reemplazar por la fuente correcta (3.3 / sec. 5; Anexo B para temperaturas de carga).
- **Alternativa B:** dejar la cita (riesgo de inducir CHECK de temperatura con «respaldo» falso).
- **Consecuencias:** bajo, pero corrige una trazabilidad que en la defensa se preguntaría.
- **Recomendación:** A. No hay regla textual de dominio de temperatura → sin CHECK por ahora (A-13).
- **¿Decidible?:** Sí (equipo).
- **Estado:** RESUELTA (cierre).
- **Elección (cierre):** Alternativa A aplicada en A-09; pendiente la validación de Persona B como parte de la revisión de dicho documento.

### DEC-17 - Resumen P-9 en A-09 §12.7: «35% (distrib.?)» vs exportador (§9.3-4 / A-11 OBS-03)
- **Tema:** el ajuste U6 (35 %) aplica a **exportadores** con >3 permisos, no a distribuidores.
- **Documentos:** A-09 §12.7, requisitos §7.2 (U6) y §10.1.5 (P-9), A-11 OBS-03 (media).
- **Problema:** la Red del modelo podría malentender el lugar del descuento especial.
- **Alternativa A:** corregir el resumen («30 % exportador base (RN-06) vs 35 % exportadores con >3
  permisos (U6): relación pendiente»).
- **Alternativa B:** mantener el texto (peligro de decisión mal fundamentada de Q-01, ver DEC-32).
- **Consecuencias:** afecta el CHECK de rango del descuento y la función `fn_descuento_cliente`.
- **Recomendación:** A; además registrar P-9 como consulta al docente (ya está en §10.2.9).
- **¿Decidible?:** La corrección textual sí (equipo); el fondo (P-9) requiere docente.
- **Estado:** RESUELTA (cierre).

---

## 5. Grupo D - Observaciones de A-11 (relevo completo, OBS-01…OBS-14)

Las observaciones ya convertidas en decisiones se re-enlazan (sin cambiar clasificación):
OBS-01→DEC-15 · OBS-02→DEC-16 · OBS-03→DEC-17 · OBS-04→DEC-14 · OBS-05→DEC-01 · OBS-06→DEC-11/12/13 ·
OBS-07→DEC-02/03/05/06/07/08/09 · OBS-08→DEC-18 · OBS-09→DEC-19 · OBS-10→DEC-20 · OBS-11→DEC-21 ·
OBS-12→DEC-22 · OBS-13→DEC-23 · OBS-14→DEC-24.

### DEC-18 - RI-a / RT-a (OBS-08, media): PK de renglones por analogía
- **Tema:** `(ingreso, vino)` y `(transferencia, vino)` son inferidas; si el vino puede repetirse por
  documento, hace falta n.º de renglón.
- **Documentos:** A-03 §2.24/§2.26, A-05 §7.4/§8.4, A-09 §2 (nota)/§12.5, A-10 §2.24/§2.26, A-11 OBS-08.
- **Alternativa A:** par compuesto (diseño actual).
- **Alternativa B:** agregar `n_renglon` a ambas tablas y extender las PK. Ventajas de B: fotos con
  repetición posible. Desventajas de B: columna sin respaldo textual; el diseño estándar del par refleja
  la intendencia de la consigna con el renglón de comprobante.
- **Consecuencias:** FKs #26/#29 y el trigger RN-12 sobre renglones.
- **Recomendación:** A (mantener par), confirmar supuesto con docente.
- **¿Decidible?:** No - consulta docente (asimetría documentada de la consigna).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-19 - Stocks: fila presente vs ausente y DEFAULT 0 (OBS-09, media; P-6/AMB-11)
- **Tema:** ¿fila de stock para todo par sala–vino / todo vino?; ¿DEFAULT 0?
- **Documentos:** A-01 §2.27/§2.28, A-04 REL-23/REL-24 (AMB-11), requisitos §10.1.6 (P-6) y §5.2
  (DEFAULT 0 en ejemplos), A-09 §11, A-10 §2.27/§2.28, A-11 OBS-09.
- **Alternativa A:** fila para todo par (matriz completa) + DEFAULT 0. Ventajas: simplifica funciones
  stock y trigger RN-09. Desventajas: filas «0» de más (3.000–15.000 pares); sin regla textual.
- **Alternativa B:** solo filas con stock real (ausencia ≠ 0), sin DEFAULT.
  Ventajas: fiel al estado actual de ejemplos del `CHECK cantidad >= 0` con DEFAULT 0 en etapa 2. Desventajas:
  consultas deben tratar el caso no-fila (S6/S9).
- **Consecuencias:** trigger RN-09 (BEFORE INSERT), función `fn_stock_sala`, consultas S6/S9, carga.
- **Recomendación técnica:** B (respeta «un solo stock de depósito… fila por vino» con no-cobertura
  completa) + DEFAULT 0 solo donde haya fila; conviene docente !
- **¿Decidible?:** No - consulta docente (P-6/AMB-11).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-20 - Exportación oficial del DER desde draw.io (OBS-10, baja/procesal)
- **Tema:** tras aprobación de A-08, sustituir los SVG no oficiales por exportación oficial (PDF/PNG).
- **Documentos:** A-08 §2.1 (declaración), A-11 OBS-10.
- **Alternativa A:** exportar desde diagrams.net al aprobarse A-08.
- **Alternativa B:** conservar los SVG actuales (ya declarados como renderización fidelíntima).
- **Recomendación:** A tras aprobación; no bloquea nada.
- **¿Decidible?:** Sí (equipo, post-aprobación).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-21 - Cuarta UNIQUE del mínimo de etapa 2 (OBS-11)

- **Tema:** alcanzar el mínimo de cuatro restricciones UNIQUE adicionales a las PK.
- **Documentos:** consigna, `docs/requisitos.md`, A-09 §6.1, A-10 §5 y `002_constraints.sql`.
- **Situación:** la consigna exige cuatro UNIQUE adicionales. Se identificó que varias de las combinaciones mencionadas como ejemplos ya están cubiertas por claves primarias. Para alcanzar el mínimo se adoptaron restricciones adicionales fundamentadas en reglas del dominio.

- **Decisiones adoptadas:**
  1. `Vino(nombre, anada, volumen_ml)`: unicidad de la combinación que identifica una presentación de vino.
  2. `Cliente(tipo_doc, n_doc)`: una combinación de tipo y número documental identifica un único registro de cliente. Esto no impide que una persona tenga documentos de distinto tipo.
  3. `Transportista(cuit)`: un CUIT identifica un único registro de transportista.
  4. `Empleado(cuit)`: un CUIT identifica un único registro de empleado.

- **Alternativa descartada:** dejar el mínimo sin completar a la espera de una respuesta docente, dado que el equipo puede fundamentar restricciones adicionales de dominio.

- **Fundamento:** las restricciones evitan duplicaciones de identificadores documentales y fiscales dentro de cada entidad. Las tres restricciones adicionales son decisiones de diseño del equipo y no se presentan como ejemplos textuales de la consigna.

- **Implementación:** las cuatro restricciones están definidas en `002_constraints.sql`.

- **¿Decidible?:** Sí, por decisión de diseño del equipo.

- **Estado:** **ADOPTADA E IMPLEMENTADA**.

### DEC-22 - OBS-12 (baja, sin acción): verificar y registrar
- **Tema:** la observación OBS-12 se resolvió sin acción (la documentación de Transportista ya era
  consistente).
- **Documentos:** A-11 §2/OBS-12, A-10 §2.21.
- **Decisión requerida:** solo registrar; no hay inversión de diseño. Verificación complementaria ya
  computada: el desglose por gravedad de A-11 omite OBS-13 (ver §0 de esta matriz).
- **¿Decidible?:** Sí (equipo; nada que decidir).
- **Estado:** PENDIENTE DE DECISIÓN (de confirmación administrativa, no de diseño).

### DEC-23 - Q-05 y guardar vs calcular importes (OBS-13, media; R-5, RN-08)
- **Tema:** (a) dominio de `descuento` del renglón/cabecera (¿porcentaje o importe?); (b) ¿se
  almacenan subtotal/descuento/total o se calculan?
- **Documentos:** A-02 §2.19/§2.20/§3 (R-5), A-09 §3.19/§3.20/§12.15, A-10 §2.19/§2.20, A-11 OBS-13.
- **Evidencia:** sec. 5 («decisiones de diseño» exige justificar por escrito); RN-08 («No se carga a
  mano»); `fn_total_comprobante` (etapa 2).
- **Alternativa A:** importes almacenados, recalculados/validados por trigger. Ventajas: tracking
  histórico, auditable; RN-08 ya pedida como trigger. Desventajas: precisión/mantenimiento de
  igualdad (el negocio no lo carga a mano).
- **Alternativa B:** solo almacenar precio_unitario y cantidad; totales calculados en consulta/vista.
  Ventajas: sin riesgo de divergencia. Desventajas: «descuento» histórico por renglón y «total» por
  cabecera tienen que recompute-er; la sec. 5 lo admite pero exige defensa de consistencia.
- **Consecuencias:** DDL (columnas y tipos), triggers RN-08/09, consultas U1/S8.
- **Recomendación técnica:** A (histórico consistente con `precio_unitario` histórico ya almacenado),
  con trigger de cálculo; tomar (a) dominio: **porcentaje** para descuento del renglón (coherente con
  RN-06, «directamente relacionado al tipo de cliente»), enviado a revisión.
- **¿Decidible?:** No en su totalidad - la sec. 5 exige justificar por escrito al equipo, y Q-05
  conviene validar con docente.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-24 - Acciones referenciales ON DELETE y ON UPDATE (OBS-14)

- **Tema:** adopción de las acciones referenciales para las 34 FK del modelo.
- **Documentos:** A-09 §7.1 y §7.2, A-10 §4 y §9.3, `001_esquema.sql`.
- **Situación:** cinco acciones ON DELETE estaban pendientes de decisión: FK #4, #21, #22, #23 y #31. Se evaluaron sus consecuencias sobre la integridad estructural, las asociaciones y la conservación de datos históricos.

- **Decisiones adoptadas:**
  - FK #4 `Parcela.finca`: RESTRICT. Impide eliminar una finca mientras tenga parcelas asociadas y evita borrados en cascada sin una regla de negocio que los autorice.
  - FK #21 `Permiso_Exportacion.exportador`: RESTRICT. Preserva los permisos de exportación y evita eliminarlos automáticamente al borrar un exportador.
  - FK #22 `Transportista_Localidad.transportista`: CASCADE. Elimina las asociaciones de cobertura cuando se elimina un transportista.
  - FK #23 `Transportista_Localidad.localidad`: CASCADE. Elimina las asociaciones de cobertura cuando se elimina una localidad.
  - FK #31 `Stock_Sala.sala`: RESTRICT. Impide eliminar una sala mientras tenga existencias registradas.

- **ON UPDATE:** se conserva la política implementada, sin propagación automática mediante CASCADE. La distribución es 20 RESTRICT y 14 NO ACTION (comportamiento predeterminado de PostgreSQL cuando no se declara otra acción).

- **Fundamento:** se utiliza RESTRICT para proteger datos históricos, registros dependientes y existencias. CASCADE se reserva para las asociaciones de la tabla intermedia `Transportista_Localidad`, cuya información depende de sus entidades relacionadas.

- **Consecuencias:** las 34 FK quedan con acciones referenciales definidas. La distribución ON DELETE es 26 RESTRICT y 8 CASCADE. No se utilizan SET NULL ni SET DEFAULT.

- **¿Decidible?:** Sí, por decisión de diseño del equipo. No requiere una regla adicional de la cátedra para implementar las acciones elegidas.

- **Estado:** **ADOPTADA E IMPLEMENTADA**.
---

## 6. Grupo E - Tipos y restricciones

### DEC-25 - ENUM `estado_documento` (nombre final y valores)
- **Documentos:** RN-10/RN-11 («Tipo ENUM»), sec. 5 («Estado con ENUM»), etapa 2 (DEFAULT
  `en_confeccion`), A-10 §7.1, A-11 (sin bloqueo).
- **Situación:** valores propuestos `en_confeccion`/`terminado`/`procesado` [R]; es el 1 ENUM mínimo.
- **Alternativa A:** un ENUM compartido por Ingreso y Transferencia. Ventajas: 1 tipo, mínimo cumplido.
- **B:** dos ENUM por documento. Desventajas: duplicación sin necesidad textual.
- **Consecuencias:** CREATE TYPE en A-13; triggers de transición RN-10/11; carga masiva (etapa 3);
  API (mapeo SQLSTATE).
- **Recomendación:** A. **¿Decidible?:** Sí (equipo).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-26 - DOMAIN `cuit` y su alcance por tabla
- **Documentos:** etapa 2 («DOMAIN CUIT de 11 dígitos»), A-10 §7.2; UNIQUE de CUIT solo textual para
  Bodega (etapa 2) - A-03 §2.9/§2.21/§2.3, A-10 §7.2.
- **Situación:** DOMAIN respaldado; el texto no dice a qué columnas se aplica.
- **Alternativa A:** aplicar a `Bodega.cuit`, `Transportista.cuit`, `Empleado.cuit` (los tres CUITs del
  modelo). **B:** solo Bodega (único con UNIQUE textual).
- **Consecuencias:** validación de formato físico en Bodega/Transportista/Empleado; sin UNIQUE salvo
  Bodega (DEC-08/09).
- **Recomendación:** A (formato común es dominio, no unicidad); confirmar con docente si el DOMAIN
  es «1 mínimo» suficientemente reutilizable.
- **¿Decidible?:** Sí (equipo); unicidad queda regida por DEC-08/DEC-09.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-27 - Dominio de `Sala.dia_cierre` (Q-09) y DOMAIN/DOMAIN-DTED `dia_semana`
- **Documentos:** A-02 §2.2 (duda Q-09), U4 (lunes/miércoles), A-10 §7.3.
- **Alternativa A:** DOMAIN días lunes–domingo (ENUM/TEXT + CHECK). **B:** dominio con valor «sin
  cierre». La consigna no acota.
- **Consecuencias:** tipo propuesto en A-10; U4 (un solo UPDATE masivo mapear lunes↔miércoles).
- **Recomendación:** A sin «sin cierre», salvo que docente lo confirme; sin DOMAIN si se decide
  CHECK simple.
- **¿Decidible?:** En parte - la existencia de «sin cierre» requiere docente (Q-09).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-28 - Tipo propio de `Cepa.tipo` y `Vino.tipo`
- **Documentos:** A-10 §7.4 (extensiones [I]); 3.2/3.3 (dominios textuales tinta/blanca y
  tinto/blanco/rosado/espumante).
- **Alternativa A:** ENUM/DOMAIN por cada uno. **B:** TEXT + CHECK (dominio cerrado con CHECK).
- **Consecuencias:** A-13 (Cuento mínimos: 1 ENUM ya cumplido con DEC-25; esto es extra).
- **Recomendación:** B (CHECK), mantiene el mínimo sin tipos de más.
- **¿Decidible?:** Sí (equipo).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-29 - Catálogo de volúmenes de vino (P-8)
- **Documentos:** requisitos §10.1.7 (P-8) y §10.2.8; 3.3 vs Anexo B.4; A-10 §2.10 (`volumen_ml` CHECK [P]).
- **Alternativa A:** CHECK lista cerrada (187/375/750/1500/3000). **B:** CHECK rango abierto.
- **Consecuencias:** Anexo A.2 e incorporación de 187/3000 de DDL.
- **Recomendación:** A sobre la base de A.2 (admite los 5 volúmenes), pendiente confirmación.
- **¿Decidible?:** No - consulta docente (P-8).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-30 - Q-08: ¿el salario entra en la positividad de RN-15?
- **Documentos:** A-02 §2.3/§5 (Q-08), requisitos §10.2.7 [Pregunta], A-10 §2.3.
- **Alternativa A:** CHECK `salario > 0`. **B:** sin CHECK (RN-15 no menciona salario).
- **Recomendación:** A defensiblemente (salario es una suma de dinero; no hay contexto de 0 o negativo),
  pero el texto no lo lista.
- **¿Decidible?:** No - consulta docente.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-31 - Tipos físicos de columnas (monetarios, porcentajes, fechas, cantidades, graduación)
- **Documentos:** A-10 §2 (tipos propuestos [R]/[I]); requisitos §5.2 (NUMERIC para dinero, sin FLOAT;
  DATE/TIMESTAMP).
- **Situación:** las precisiones `(p,s)` no están textualmente respaldadas ([I]).
- **Alternativa A:** fijar `NUMERIC(12,2)` para importes, `NUMERIC(5,2)` porcentajes, `DATE` fechas de
  documento y `TIMESTAMP` para la auditoría («fecha y hora»), `INTEGER` cantidades, `NUMERIC` (precisión
  de dominio por cerrar) para superficie/kg/Brix/pH/acidez/graduación con precisión por columna en
  A-13.
- **Alternativa B:** `MONEY`/`FLOAT` - **descartada** por la consigna (nunca FLOAT; efectos de
  redondeo).
- **Consecuencias:** DDL de todas las columnas; índices (78 tabla? stage 4) y vistas.
- **Recomendación:** A. **¿Decidible?:** Sí (equipo; precisión exacta documentable).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-32 - Q-01: descuento de Cliente: atributo almacenado vs función
- **Documentos:** A-02 §2.14/§5 (Q-01), RN-06 (función + CHECK de rango), A-06 §2.1, A-10 §2.14,
  requisitos §10.1.5 (P-9, ver DEC-17).
- **Alternativa A:** columna `Cliente.descuento` + `fn_descuento_cliente` consistente (CHECK de rango).
  Ventajas: histórico por tipo siempre disponible; sección 5 lista el atributo. Desventajas: dos
  fuentes de verdad (mitigado con trigger/checks; R-10 de A-02).
- **Alternativa B:** solo función. Desventajas: contradice el listado de la sec. 5 (atributo).
- **Consecuencias:** jerarquía (DEC-11/12), U6 (P-9), triggers de venta.
- **Recomendación:** A (híbrido consistente: atributo como copia aplicada + función como regla).
- **¿Decidible?:** Sí como criterio (equipo); el valor concreto del caso U6 requiere docente (P-9).
- **Estado:** ADOPTADA (alternativa A; implementación verificada en la migración 004 y pruebas RN-06).

### DEC-33 - UNIQUE candidatas de A-09 §6.2 (¿declarar o dejar sin restricción?)
- **Documentos:** A-09 §6.2 (lista completa), A-10 §5, A-11 OBS-11.
- **Situación:** 13 candidatas sin UNIQUE textual (LP/nombre+prov, Cepa.nombre, Maridaje.nombre,
  Vino.codigo, Client (tipo_doc, n_doc), Distribuidor.n_habilitacion, Transportista.cuit,
  Comprobante numero/(sala, numero), Ingreso.codigo, Transferencia.numero, Auditoría (vino,
  fecha_hora), Empleado.cuit).
- **Alternativa A:** ninguna se declara hasta cierre de la DEC de PK correspondiente (DEC-01…09) y de
  DEC-21 (regla del docente). **B:** declarar por criterio dominial (peligro: viola «no agregar UNIQUE
  sin respaldo»).
- **Consecuencias:** mínimos de etapa 2; carga masiva (reproducción de semilla).
- **Recomendación:** A; casar cada una con la decisión de PK/DEC correspondiente.
- **¿Decidible?:** No (depende de DEC-01…09 y consulta docente).
- **Estado:** PENDIENTE DE DECISIÓN.

---

## 7. Grupo F - Otras decisiones pendientes

### DEC-34 - Q-03: semántica de `Ingreso.fecha`
- **Documentos:** A-02 §2.23, A-09 §3.23 (fecha sin resolver), A-10 §2.23.
- **Alternativa A:** fecha de confección del documento (análoga a RN-11 para la transferencia).
- **B:** fecha del traslado/entrada a depósito.
- **Consecuencias:** aquí no hay trigger RN-11 declarado para el ingreso; cambia semántica del
  documento y pruebas.
- **Recomendación:** A con prefijo «confección» si docente confirma.
- **¿Decidible?:** No - consulta docente (candidata [Pregunta]).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-35 - Q-07: usuario de la auditoría de precios
- **Documentos:** A-02 §2.29, A-10 §2.29; sec. 5eros 3 roles de BD (etapa 2).
- **Alternativa A:** usuario de BD (`CURRENT_USER` capturado por el trigger RN-13). **B:** usuario
  funcional (no hay modelo de usuarios de aplicación).
- **Recomendación:** A (única opción con elementos en el modelo).
- **¿Decidible?:** Sí (equipo) - técnica; sin cuestión docente si se argumenta con stages.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-36 - Q-04: `Cliente.nombre` en uno o dos campos
- **Documentos:** A-02 §2.14, A-03 CliK-a (depende de D-1).
- **Alternativa A:** campo único («apellido y nombre o razón social»). **B:** dos campos por subtipo.
- **Consecuencias:** conectado a DEC-11/12/13.
- **Recomendación:** A (campo único) como la sección 5 la lista. **¿Decidible?:** Sí con DEC-13.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-37 - Q-10: direcciones en un campo vs desglosadas
- **Documentos:** A-02 §2.14/§5; sec. 5 («calle, número» para sala).
- **Alternativa A:** campo único. **B:** desglosado.
- **Recomendación:** A; sin respaldo para desglosar.
- **¿Decidible?:** Sí (equipo).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-38 - Q-11: departamento/provincia como atributos vs catálogo
- **Documentos:** A-02 §2.4; Anexo B (departamentos de Mendoza); A-10 §2.4.
- **Alternativa A:** atributos sueltos. **B:** tabla catálogo (impacto: 1 tabla más en A-09 - eso
  implicaría modificar el esquema; no se hace sin aprobación).
- **Recomendación:** A por ahorro; cargar departamentos solo como datos de prueba.
- **¿Decidible?:** Sí (equipo); exige decidir antes del DDL.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-39 - Q-12: estado (vigente/vencido) de permisos
- **Documentos:** A-02 §2.18; A-10 §2.18 (sin atributo - la coherencia actual es "no guardar").
- **Recomendación:** derivado por consulta, no almacenado (alternativa ya seguida).
- **¿Decidible?:** Sí (equipo; [Inferencia] ya declarada).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-40 - Q-13: atributos extra en stocks (fecha de última actualización, etc.)
- **Documentos:** A-02 §2.27 (nota), A-10 §2.27/§2.28.
- **Recomendación:** solo cantidad (consigna); no agregar sin pedido.
- **¿Decidible?:** Sí (equipo).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-41 - AMB-02/AMB-05: mínimos «2» (empleados por sala, vinos por bodega)
- **Documentos:** A-04 REL-02/REL-09 (2*..N, no sustituibles sin decisión); etapa 2 (¿regla formal?).
- **Alternativa A:** mantener 2*..N como lectura literal («varios»). **B:** 1..N (varios = coloquial).
  No hay trigger/constraint hasta decidir.
- **Recomendación:** no imponer mínimo en la base hasta cierre.
- **¿Decidible?:** No - consulta docente.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-42 - AMB-01/03/04a/16/17: mínimos de existencia de participantes (0 vs 1)
- **Documentos:** A-04 §4 (AMB-01 localidad-sala, AMB-03 finca-parcela, AMB-04a localidad-cliente,
  AMB-16 maridaje-vino, AMB-17 bodega-lote); A-09 §6.3 (NOT NULL FKs solo si mínimo 1 textual).
- **Situación:** los NOT NULL de estas FKs no afectan (los mínimos del lado «uno» ya están con
  mínimo 1); el problema es el lado «muchos» (¿la finca debe tener parcela? etc.).
- **Alternativa A:** mínimos 0 (letras actuales). **B:** mínimos 1 con triggers/constraints etapa 2.
- **Recomendación:** A (mínimos 0) por falta de cuantificación textual; sin reglas físicas.
- **¿Decidible?:** No - consulta docente.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-43 - AMB-04b: ¿el cliente debe comprar en una sala de su localidad?
- **Documentos:** A-04 §4 (AMB-04b); no hay relación Cliente–Sala.
- **Recomendación:** no imponer (sin regla textual).
- **¿Decidible?:** Sí (equipo) - la consigna no lo exige; se registra como decisión de no-modelar.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-44 - AMB-06: ¿son la misma bodega destino del lote / elaboradora del vino / origen del ingreso?
- **Documentos:** A-04 §4 (AMB-06); A-09 §3.7/§3.10/§3.23 (roles distintos, nombres con rol).
- **Recomendación:** mantener tres vínculos separados (diseño actual) al no haber regla de igualdad.
- **¿Decidible?:** Sí (equipo; no-modelar es la lectura conservadora).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-45 - AMB-08: permisos (mínimo 0 [R] por «puede tener»; ¿compartidos?)
- **Documentos:** A-04 REL-16; FK #21 (1 permiso = 1 exportador, no compartido).
- **Recomendación:** mínimo 0, no compartidos (diseño actual coherente).
- **¿Decidible?:** Sí (equipo).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-46 - AMB-09: cobertura mínima de transportistas/localidades
- **Documentos:** A-04 REL-17; A-05 §9.4.
- **Recomendación:** mínimos 0 en ambos extremos (sin cuantificación textual).
- **¿Decidible?:** Sí (equipo).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-47 - AMB-10a/10b/14: documentos sin renglones y su estado
- **Documentos:** A-04 §4, A-05 §6.4/§7.4/§8.4; RN-12 (bloqueo fuera de `en_confeccion`).
- **Alternativa A:** permitir documento vacío en `en_confeccion` (coherente con el ciclo: se crea
  «en confección» y después se cargan renglones; API lo crea por POST y agrega renglones aparte).
- **B:** exigir ≥1 renglón siempre (choca con el ciclo del API: `POST /transferencias` crea la
  cabecera y `POST /transferencias/{nro}/renglones` agrega).
- **Consecuencias:** triggers RN-12, validación de total (un comprobante vacío: total 0).
- **Recomendación:** A (la mecánica del API lo presupone); confirmar.
- **¿Decidible?:** En parte (equipo por el API) + docente (AMB-14).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-48 - AMB-12/AMB-13: historia de plantación de parcela y análisis same-day
- **Documentos:** A-04 §4; D-7 (sin tabla intermedia); D-6/Q-06 y AKA-2 [pend. también en DEC-09? no:
  Analisis PK está respaldada (id [R]) y AK-2 es candidata alterna].
- **Alternativa A:** sin historia de plantación (una cepa plantada actual); sin exigencia de
  unicidad (finca, n_parcela, campania, fecha) - queda id_analisis.
- **B:** historia con tabla intermedia / UNIQUE (finca, n_parcela, campania, fecha). Sin respaldo.
- **Recomendación:** A. **¿Decidible?:** Sí (equipo) si nadie pide historia; AMB-13 queda condicionado
  a consulta del docente por si dos análisis same-day fueran legítimos (impacta AK-2 en A-10 §2.8).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-49 - ComK-a: ¿puede repetirse una cepa en la composición de un vino?
- **Documentos:** A-03 §2.11, A-05 §5.4, A-09 §9, A-10 §2.11.
- **Recomendación:** No (par como PK, diseño actual).
- **¿Decidible?:** Sí (equipo) - sin señal de la consigna que lo permita; dejar registro del supuesto.
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-50 - ParK-a: política de reutilización del n.° de parcela
- **Documentos:** A-03 §2.5 (duda sin efecto sobre la clave).
- **Recomendación:** asumir que el n.° es del objeto y no se reutiliza (no cambia estructura).
- **¿Decidible?:** Sí (equipo); solo política de borrado/replante (relacionada con DEC-24 FK #4).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-51 - D-2/D-9/D-10: notación documental en el DER (débil vs asociativa; entidades vs relaciones)
- **Documentos:** A-01 §6.1, A-05 §§6-10/§12, A-08 (notación actual: asociativas dibujadas como
  entidades N:M).
- **Situación:** decisión de notación (no cambia estructura relacional) - marcadas provisionales.
- **Alternativa A:** mantener la notación actual del A-08 (asociativas como cajas). **B:** modelos puros
  de relación CHEN (más pesoía dibujo, mismo resultado).
- **Recomendación:** A (ya dibujado y declarado; facilitar la defensa).
- **¿Decidible?:** Sí (equipo).
- **Estado:** PENDIENTE DE DECISIÓN.

### DEC-52 - D-4/D-5/D-7/D-8: decisiones de no-modelar (encargado, campaña, plantación, transportista-venta)
- **Documentos:** A-01 §2.1/§2.5/§2.21 y §5 (lista «no entidades»), A-04 §5.
- **Situación:** el modelo actual no modela: encargado como entidad (es atributo, D-4), campaña como
  catálogo (D-5), tabla intermedia parcela–cepa (D-7), transportista en comprobantes (D-8).
- **Alternativa A:** mantener los no-modelados (lecturas actuales con [Inferencia]/sec. 5).
- **B:** modelar alguna (exigiría agregar entidades - no respaldado).
- **Recomendación:** A.
- **¿Decidible?:** Sí (equipo); confirmar en la revisión de A-08 (Persona B) que nadie las pide.
- **Estado:** PENDIENTE DE DECISIÓN.

---

## 8. Priorización y dependencias

### 8.1 Clasificación por prioridad
> **Nota de estado (cierre):** las decisiones del Grupo A (DEC-01…DEC-10) y el Grupo B (DEC-11…DEC-13, adoptadas en A-06) ya están **RESUELTAS/ADOPTADAS** (ver cada entrada); DEC-15/16/17 también (validación de Persona B pendiente). Las filas siguientes reflejan su estado original de _pendientes_ y se mantienen como histórico de priorización; ya no bloquean A-08/A-09/A-10.

| Prioridad | Decisiones | Justificación |
|---|---|---|
| **1. Bloqueantes para aprobar A-08 y A-09** | DEC-11, DEC-12, DEC-13 (jerarquía), DEC-41, DEC-42, DEC-47, DEC-51, DEC-52 (decisiones que el DER refleja como abiertas) | A-08/A-09 no pueden declararse aprobados con la jerarquía sin decidir y las alternativas vivas influyendo en el dibujo y en las FKs |
| **2. Bloqueantes para completar A-10** | DEC-01…DEC-10 (PK y forma de ID), implementación de DEC-14 (matriz NOT NULL), DEC-23 (importes), DEC-24 (acciones referenciales), DEC-33 (UNIQUE) | El diccionario no puede dejar de estar marcado PRELIMINAR hasta completar la documentación de estos puntos. DEC-32 (Q-01) ya fue adoptada e implementada. |
| **3. Bloqueantes para la etapa 2 (DDL + Docker/PostgreSQL)** | DEC-01…DEC-10, implementación de DEC-14 en A-10 y DDL, DEC-23, DEC-24, DEC-25, DEC-26, DEC-31, DEC-33, DEC-38, DEC-39, DEC-40, DEC-43, DEC-44, DEC-45, DEC-46, DEC-49, DEC-50 | El DDL necesita PK, tipos y restricciones documentados y coherentes; la adopción de un criterio general no sustituye su implementación |
| **4. Bloqueantes para A-13 (ENUM/DOMAIN)** | DEC-25 (ENUM), DEC-26 (DOMAIN cuit), DEC-27, DEC-28, DEC-29, DEC-30, DEC-31, DEC-21 (4.ª UNIQUE), DEC-33 | Los tipos propios y dominios son el contenido de A-13 y dependen de estas decisiones |
| **5. Resolubles en etapas posteriores** | DEC-19 (puede cerrarse en etapa 2 con el trigger RN-09), DEC-34…DEC-37, DEC-41, DEC-42, DEC-47 (parte), DEC-20 (post-aprobación), DEC-22 (administrativa), DEC-51/52 (notaciones documentales) | No bloquen el DDL; algunas pertenecen a etapa 2/3 por su naturaleza (triggers, carga, exportación) |

### 8.2 Grafo de dependencias (no son decisiones independientes)

| Decisión | Depende de / afecta a |
|---|---|
| DEC-13 (mapeo jerarquía) | **precondición** de DEC-11, DEC-12 (AMB-07), DEC-36 (Q-04); afecta DEC-04 (target de FK #21 con PK heredada), DEC-14, DEC-32 |
| DEC-11/12 | afectan DEC-04 (PK/FK de Exportador), DEC-33 (`id_cliente` UNIQUE en subtipos), DEC-14 |
| DEC-01 (Localidad) | afecta DEC-03? no: afecta FKs #1/#3/#23 → influye en el tipo de las FKs y en DEC-33; independiente excepto porque define si hay PK subrogada → DEC-10 |
| DEC-03 (Vino `codigo`) | afecta DEC-33 (UNIQUE de `codigo`), las FKs #10, #12, #16, #17, #26, #27, #29, #30, #32, #33, #34 (Se pasaron a FK compuestas si se elige VK-2), la etapa 3 (volumen);
| DEC-05/06/07 (numeración global/por sala-bodega) | afectan FKs #16, #26, #29 y las decisiones de numeración física de etapa 2 (secuencias vs asignación por API) |
| DEC-08/09 | afectan FKs #22, #24 (transportista); DEC-26 (DOMAIN), DEC-33 (UNIQUE de cuit) |
| DEC-10 (forma ID) | afecta la etapa 3 (carga) y todas las FKs con targets subrogados |
| DEC-14 (NOT NULL) | Criterio conservador adoptado; afecta todo el diccionario y debe reflejarse en A-10 y `001_esquema.sql` |
| DEC-17 (P-9) | pendiente únicamente por la regla especial del 35 % para exportadores con más de 3 permisos; DEC-32 ya adoptó e implementó el descuento base y el CHECK de rango de `descuento` |
| DEC-23 (importes) | afecta DEC-31 (tipos monetarios) y triggers RN-08/RN-09 (etapa 2) |
| DEC-24 (ON DELETE) | interdependiente con DEC-41/DEC-42/DEC-47 (mínimos y ciclo de estados) |
| DEC-19 (stocks) | interdependiente con DEC-24 (FK #31) y con los triggers RN-09/RN-11 |
| DEC-18 (RI/RT) | interdependiente con DEC-06/DEC-07 (si cambia la PK del documento, cambia el tipo de FK del renglón) |
| DEC-21 (4.ª UNIQUE) | depende de la respuesta del docente y de DEC-33 |
| DEC-25/26/27/28 | son de A-13; DEC-28 depende de DEC-25 (que el mínimo ENUM ya esté cumplido) |

**Cadenas críticas (estado de cierre: las cadenas 1, 2, 3 y la porción de DEC-14→A-13 que corresponde a PKs ya están resueltas o desbloqueadas; las subcadenas que dependen de dominios/N-únicos siguen activas para etapa 2):**
1. **DEC-13 → DEC-11/12 → DEC-04** (jerarquía; desbloquea 4 FKs y afecta descuento).
2. **DEC-01 → (DEC-10) → FK #1/#3/#23** (localidad).
3. **DEC-03 → FKs de vino y DEC-33** (vino: la tabla con más FKs).
4. **DEC-05/06/07** (numeración de documentos: 3 PKs y 3 FKs de renglones).
5. **DEC-14 (adoptada) → A-10 → `001_esquema.sql`** (aplicación del criterio NOT NULL a cada columna).
6. **DEC-25/DEC-26** (los mínimos de tipos propios, luego el resto de dominios).

---

## 9. Resumen de la matriz

| Grupo | Decisiones | Intervalo |
|---|---:|---|
| A. PK y claves | 10 | DEC-01–DEC-10 |
| B. Jerarquía | 3 | DEC-11–DEC-13 |
| C. Inconsistencias detectadas en A-10 | 4 | DEC-14–DEC-17 |
| D. Observaciones A-11 | 7 | DEC-18–DEC-24 |
| E. Tipos y restricciones | 9 | DEC-25–DEC-33 |
| F. Otras decisiones pendientes | 19 | DEC-34–DEC-52 |
| **Total** | **52** | **RESUELTAS/ADOPTADAS: 18** — DEC-01…DEC-17 y DEC-32. **PENDIENTES: 34** — DEC-18…DEC-31 y DEC-33…DEC-52. |

---

### Registro de cambios de este documento
- DEC-32 (Q-01) adoptada: se eligió la alternativa A (columna `Cliente.descuento` sincronizada mediante `fn_descuento_cliente`); implementación en `004_rn03_rn06.sql` y pruebas RN-06 aprobadas (18/18 pruebas de la suite general). P-9 permanece pendiente exclusivamente por el caso especial del 35 %.
- Cierre: DEC-15/16/17 llevadas a RESUELTA (correcciones aplicadas en A-09, validación pendiente de Persona B); §0 actualizado (A-11 corregió la omisión de OBS-13); fila 1 de §8.1 depurada; título de fila 3 de §8.1 corregido a «etapa 2» y la nota «¿catalog extra tables?» reinterpretada sobre DEC-38.

- Creación (A-12-matriz): relevo de 52 decisiones pendientes (grupos A-F incluidos), con la verificación
  del desglose de gravedad de A-11 (omisión de OBS-13 documentada, sin modificar A-11),
  priorización en 5 niveles y grafo de dependencias. Ninguna decisión tomada; sin SQL, sin Docker,
  sin commits.
- Actualización: DEC-14 registrada como ADOPTADA; criterio conservador de NOT NULL. Se actualizaron encabezado, prioridades, dependencias y resumen de estados. Pendiente reflejar su implementación en A-10 y `001_esquema.sql`.

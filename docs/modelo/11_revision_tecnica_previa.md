# A-11 — Revisión técnica previa (auditoría interna de consistencia)

> **Estado: PRELIMINAR — la revisión de Persona B sigue explícitamente PENDIENTE.** Este documento
> es una revisión técnica independiente preparatoria; **no sustituye** la revisión de Persona B
> ni la del docente, y **no simula su aprobación**. Ninguna observación aquí proviene de Persona B.
>
> **Alcance:** consistencia entre A-01…A-07 (conceptual), A-08 (DER, pendiente de revisión), A-09
> (esquema relacional, PRELIMINAR) y A-10 (diccionario de datos, PRELIMINAR), contrastados con
> `docs/requisitos.md` (transcripción de la consigna con sus [Pregunta]/[Inferencia]).
> **Durante el cierre de issues (ciclo posterior a esta auditoría) sí se corrigieron en A-09 las
> erratas de OBS-01/02/03 y se propagó DEC-02 (PK de `Lote`)**; este documento conserva el registro
> histórico original (motivo documentado en A-12 §0). La revisión de Persona B sigue PENDIENTE.
>
> Convención: OBS-nn = observación; GRA: **crítica / alta / media / baja**.
> Categorías: [INC] inconsistencia comprobada · [MEJ] mejora recomendada · [DEC] decisión pendiente ·
> [OK] aspecto correcto y justificado.

---

## 1. Evaluación por criterio exigido

| # | Criterio | Evaluación | Observaciones asociadas |
|---|---|---|---|
| 1 | Cobertura de entidades mínimas | 29 conceptos de sec. 5 representados en A-01→A-08→A-09→A-10 (16 fuertes+débil+6 asoc.+2 stock+3 subtipos+1 auditoría; cifra corregida en A-09 conforme OBS-01); ninguna entidad de la tabla de la sección 5 falta. | OBS-01 (aritmética del encabezado), OK-01 |
| 2 | Cardinalidades y participación | A-04 define 25 relaciones con rangos por extremo con `*` para inferidos; A-08 y A-09 las conservan sin "limpiar". 18 ambigüedades abiertas (AMB-01…AMB-17, AMB-15 resuelta). | OK-02; DEC-01 |
| 3 | Claves candidatas | A-03 lista candidatas con categorías R/I/P; A-09 §4 conserva las alternativas de PK abiertas; A-10 no eligió ninguna arbitrariamente. | OK-03; DEC-02 |
| 4 | Relaciones N:M y tablas asociativas | 6 asociativas materializadas como tablas (Composicion, Vino_Maridaje, Renglon_Comprobante, Renglon_Ingreso, Renglon_Transferencia, Transportista_Localidad), con atributos propios correctos y minimalidades argumentadas (A-09 §4). Renglones de ingreso/transferencia por analogía (RI-a/RT-a pendientes). | OK-04; DEC-03 |
| 5 | Entidad débil Parcela | Correctamente traducida: PK compuesta `(finca, n_parcela)` [R triple cita], FK identificadora componente de PK, dependencia existencial via NOT NULL; una sola tabla que la referencia (Lote, FK compuesta). | OK-05; DEC-04 (ON DELETE) |
| 6 | Jerarquía de clientes | Estrategia supertipo+subtipos propuesta en A-06 con PK/FK heredada; AMB-07 (totalidad/exclusividad) abierta; revisión de Persona B pendiente. A-09/A-10 la marcan condicionada. | OK-06; DEC-05 |
| 7 | Dependencias funcionales y 3FN | A-07 documenta DFs por tabla, separa cabeceras/renglones (evita dependencias parciales) y evita transitivas (encargado regional en Localidad). Sin certificación definitiva de 3FN (claves pendientes) — declarado explícitamente. | OK-07; DEC-02 |
| 8 | Correspondencia DER ↔ esquema relacional | Matriz trazabilidad A-09 §13 mapea las 27 entidades/relaciones del DER a las 29 tablas; auditoría cruzada A-09 §14 sin elementos fuera del trazado. | OK-08 |
| 9 | Esquema relacional ↔ diccionario | A-10 cubre 29/29 tablas y 128/128 columnas (conteo actualizado en cierre: +`id_localidad` DEC-01, +`id_empleado` DEC-09, +2 en `Analisis` DEC-02) con nombres idénticos a A-09; tipos propuestos sin alterar A-09. | OK-09; INC-01 (citas) |
| 10 | Ambigüedades y decisiones pendientes | Inventariadas en A-09 §12 y A-10 §9.4, sin cerrarse. | DEC-06 |

---

## 2. Inobservaciones detalladas (OBS-01 … OBS-14)

### OBS-01 — [INC · gravedad: media]
- **Doc/sección:** A-09 §2 (encabezado del listado de 29 tablas).
- **Problema:** el texto indica «17 de entidades fuertes + 1 débil + 6 asociativas + 2 stock + 3 subtipos + 1 técnica» (suma 30), en contradicción con la numeración de la propia tabla (29 filas). La cuenta correcta es 16 fuertes + 1 débil.
- **Evidencia:** A-09 §2 primer párrafo; conteo de filas 1–29 de la tabla; clasificación del A-01 §3 (Localidad…Transferencia = 16 fuertes, sin contar Parcela).
- **Impacto:** bajo estructural (la tabla es correcta); riesgo de confusión al defender o exportar cifras.
- **Corrección sugerida (aplicada en el cierre):** reemplazada «17 de entidades fuertes» por «16 de entidades fuertes + 1 débil» en A-09.
- **Decisión:** corrección tipográfica evidente; puede aplicarse tras confirmación (revisión de Persona B puede aprobarla junto al documento).

### OBS-02 — [INC · media]
- **Doc/sección:** A-09 §3 punto 12 (Maridaje).
- **Problema:** cita «(RN-06)» como respaldo de la temperatura del maridaje; RN-06 regula el descuento por tipo de cliente.
- **Evidencia:** `docs/requisitos.md` §4 (RN-06) vs A-09 §3 ítem 12.
- **Impacto:** trazabilidad incorrecta de una restricción (puede inducir a documentar un CHECK vacuo).
- **Corrección sugerida [aplicada en el cierre]:** reemplazar la cita por «3.3/sec. 5»; ningún CHECK de temperatura tiene respaldo textual (dominio sin cerrar).

### OBS-03 — [INC · media]
- **Doc/sección:** A-09 §12 ítem 7 (Q-01/P-9).
- **Problema:** se resume «30% socio, 35% cliente (distrib.?)»; P-9/U6 se refiere a **exportadores** con más de 3 permisos (35 %), no a distribuidores.
- **Evidencia:** `requisitos.md` §7.2 U6 y §10.1.5; A-02 §3 (descuento por tipo).
- **Impacto:** riesgo de decidir mal dónde vive el descuento (Q-01) y cómo se aplica U6.
- **Corrección sugerida [aplicada en el cierre]:** reformular como «30 % exportador (RN-06) vs 35 % exportadores con >3 permisos (U6): relación pendiente (P-9)».
- **Decisión:** requiere decisión conjunta (P-9 está entre las [Pregunta] al docente, requisitos §10.2.9).

### OBS-04 — [INC · alta]
- **Doc/sección:** A-02 (obligatoriedad «Siempre») vs A-09 §6.3 (NOT NULL restringido) vs A-10 §6.2.
- **Problema:** inconsistencia de nivel lógico/físico: A-02 declara «Siempre» para casi todos los atributos; A-09 propone NOT NULL solo para componentes de PK y FKs con mínimo 1 textual. El diccionario sigue A-09 y deja `P` los descriptivos.
- **Evidencia:** A-02 §2; A-09 §6.3; A-10 §2/§6.2 (marcas y contradicción registrada §9.3-1).
- **Impacto:** el DDL de A-13 podría quedar más laxo que la semántica del negocio; decisión falta de cerrar hasta etapa 2 con dominios (la guía de la consigna: NOT NULL/CHECK/DOMAIN, etapa 2).
- **Corrección sugerida:** documentar en etapa 2 la política de NOT NULL por columna con justificación (no resolver aquí). Requiere decisión conjunta/docente.

### OBS-05 — [DEC · alta]
- **Docs:** A-03 (LK-a/LK-b), A-09 §4/§12, A-10 §9.4.
- **Problema:** PK de `Localidad` sin definir (`codigo_postal` vs `(nombre, provincia)`), bloquea formalizar 3 FK (Sala.localidad, Cliente.localidad, Transportista_Localidad.localidad) y la DF `identidad_localidad → encargado_regional` de A-07.
- **Evidencia:** A-03 §2.1 (ambas candidatas sin unicidad confirmada); A-07 §3.1.
- **Impacto:** bloquea DDL (A-12/13) y la carga de catálogos (etapa 3).
- **Corrección sugerida:** consulta al docente (sección 5 «decisiones de diseño»); mientras tanto se mantiene la alternativa doble. **PENDIENTE**.

### OBS-06 — [DEC · alta]
- **Docs:** A-04 AMB-07; A-06 §7; A-09 §10/§12.2; A-10 §9.4.
- **Problema:** totalidad y exclusividad de la jerarquía Cliente no determinadas; la estrategia de mapeo (supertipo+subtipos) está propuesta y **pendiente de revisión de Persona B** (A-06 §7).
- **Evidencia:** A-04 §4 (AMB-07); A-06 §5/§6/§7.
- **Impacto:** afecta PK/FK de Socio/Distribuidor/Exportador, FK #21 (permisos) y las reglas de borrado #18–20; bloquea cierre de DEC-05.
- **Corrección sugerida:** revisión de Persona B sobre A-06 y confirmación de AMB-07 antes de DDL. **PENDIENTE** (intervención de Persona B explícita).

### OBS-07 — [DEC · alta]
- **Docs:** A-03 (CompK-a/IK-a/TF-a), A-09 §4/§12.1, A-10 §3.
- **Problema:** numeración global vs por sala/bodega (`Comprobante`, `Ingreso`, `Transferencia`) y PK de `Vino` (`codigo` vs triada) y `Lote` (`n_lote` vs `(parcela, campania)`) quedan abiertas; las FK de renglones y stocks dependen de ellas.
- **Evidencia:** A-03 §2.19/2.23/2.25/2.10/2.7; A-09 §4 («PK pendiente»); API de la consigna sugiere unicidad global ([Inferencia] marcada).
- **Impacto:** bloqueo directo del DDL y de las consultas por identificador (API).
- **Corrección sugerida:** consulta docente batch (sección 5); documentar preferencia con base en el API como argumento, sin cerrar. **PENDIENTE**.

### OBS-08 — [DEC · media]
- **Docs:** A-03 (RI-a/RT-a), A-05 §7.4/§8.4, A-09 §2 nota/§12.5.
- **Problema:** PK compuesta de `Renglon_Ingreso` y `Renglon_Transferencia` es por analogía (no textual); si se permitiera repetir el vino por documento, haría falta n.º de renglón.
- **Evidencia:** A-03 §2.24/§2.26; asimetría con la clave textual de `Renglon_Comprobante` (sec. 5).
- **Impacto:** media — estructura mayor no cambia; sí la PK y un posible atributo (n_renglon).
- **Corrección sugerida:** confirmar con docente; mantener par como propuesta [I]. **PENDIENTE**.

### OBS-09 — [DEC · media]
- **Docs:** A-01 (D-3), A-04 (AMB-11), A-09 §11, A-10 §9.4; requisitos §10.1.6 (P-6).
- **Problema:** existencia de fila de stock (fila ausente ≠ cantidad 0) y DEFAULT 0 de stocks sin cerrar; afecta `Stock_Sala`/`Stock_Deposito` y el trigger RN-09.
- **Evidencia:** requisitos §5.1 (rows de stock) y §10.1.6; A-04 REL-23/REL-24.
- **Impacto:** afecta validación «no vender sin stock» y consultas S6/S9.
- **Corrección sugerida:** cerrar P-6/AMB-11 con docente; mientras tanto el diccionario conserva `>= 0` [R] y DEFAULT 0 como [P]. **PENDIENTE**.

### OBS-10 — [MEJ · baja]
- **Docs:** A-08 §2.1 declaración de SVG no oficiales; A-08 `.drawio` y 7 SVGs sin revisión por Persona B.
- **Problema:** los SVG no son exportación oficial de draw.io (declarado honestamente en A-08); tras aprobación conviene exportar PDF/PNG oficial y mantener el `.drawio` como fuente normativa.
- **Evidencia:** A-08 §2.1 tabla y declaración.
- **Corrección sugerida:** post-aprobación de A-08, exportar desde diagrams.net y reemplazar/registrar los SVG. No bloquea.

### OBS-11 — [MEJ · baja]
- **Docs:** A-09 §6.2; requisitos §5.2 (UNIQUE mínimas).
- **Problema:** la consigna pide 4 UNIQUE adicionales y ejemplifica 3; la cuarta no se propuso (correcto no inventar), pero conviene registrar expresamente en la lista de consultas al docente (ya está como [Pregunta] §10.2.6) y en A-13 decidir la cuarta con justificación si la cátedra confirma el mínimo.
- **Evidencia:** requisitos §5.2 y §10.2.6.
- **Corrección sugerida:** al resolver la [Pregunta], proponer la cuarta con respaldo o documentar que son orientativas. **PENDIENTE**.

### OBS-12 — [INC · baja]
- **Docs:** A-03 §3 tabla-resumen línea 25; A-10 §3 (Transportista).
- **Problema:** A-10 resume la candidata TK según alternativas (`codigo` [P] vs `cuit` [I]); en A-03 §3 TK-2 figura como «I», alcanzada en el texto del cuerpo como «inferencia condicionada» — coherente, pero el diccionario debe conservar la condición (persona jurídica con CUIT propio: supuesto TK-a sin cerrar). Verificado: consistente; se baja a nota de atención (sin acción).
- **Evidencia:** A-03 §2.21; A-10 §2.21.
- **Corrección sugerida:** ninguna (documentación ya consistente).

### OBS-13 — [DEC · media]
- **Docs:** A-02 (Q-05, R-5), A-09 §3.19/§3.20, A-10 §2.19/§2.20.
- **Problema:** dominio de `descuento` de renglón/cabecera (¿% o importe?) y la decisión «guardar vs calcular» subtotal/descuento/total no cerradas; el diccionario documenta columnas presentes (por A-02) con la decisión física PENDIENTE.
- **Evidencia:** requisitos §5.2 nota de decisiones de diseño; A-02 §3/§4.
- **Impacto:** alto para etapa 2 (triggers RN-08) y para el DDL.
- **Corrección sugerida:** decidir en etapa 2 con justificación escrita exigida. **PENDIENTE**.

### OBS-14 — [DEC · baja]
- **Docs:** A-09 §7.1 #4/#21/#22/#23/#31; A-10 §2.5/§2.18/§2.22/§2.27.
- **Problema:** cinco acciones ON DELETE quedan «no decididas» (RESTRICT vs CASCADE) sin regla textual; correcto no cerrarlas, pero deben resolverse antes del DDL.
- **Evidencia:** A-09 §7.1 y §12.16.
- **Corrección sugerida:** decidir en etapa 2/consulta docente con las consecuencias ya listadas. **PENDIENTE**.

---

## 3. Clasificación de resultados

### 3.1 Inconsistencias comprobadas [INC]
| ID | Resumen | Gravedad |
|---|---|---|
| OBS-01 | Aritmética de encabezado de A-09 §2 (30 vs 29; 16 fuertes reales) | media |
| OBS-02 | Cita RN-06 incorrecta para temperatura de Maridaje (A-09 §3.12) | media |
| OBS-03 | Resumen P-9 en A-09 §12.7 asigna 35 % a «distrib.?»; es exportador | media |
| OBS-04 | Tensión obligatoriedad conceptual (A-02) vs NOT NULL restringido (A-09 §6.3) | alta |
| OBS-12 | Nota de atención sobre condición de TK-2 (sin acción; consistente) | baja |

### 3.2 Mejoras recomendadas [MEJ]
| ID | Resumen | Gravedad |
|---|---|---|
| OBS-10 | Exportación oficial desde draw.io tras aprobación de A-08 | baja |
| OBS-11 | Registrar expresamente la 4.ª UNIQUE pendiente de [Pregunta] | baja |

### 3.3 Decisiones pendientes [DEC]
| ID | Resumen | Gravedad | Requiere Persona B / docente |
|---|---|---|---|
| OBS-05 | PK de Localidad | alta | docente |
| OBS-06 | AMB-07 + revisión de A-06 | alta | **Persona B** (que a su vez puede consultar al docente) |
| OBS-07 | PK de Vino/Comprobante/Ingreso/Transferencia/Transportista/Empleado | alta | docente | *(actualizado: la PK de `Lote` quedó RESUELTA por DEC-02 — la fila original incluía Lote)*
| OBS-08 | RI-a/RT-a | media | docente |
| OBS-09 | P-6/AMB-11 (stocks, DEFAULT 0) | media | docente |
| OBS-13 | Q-05 + guardar vs calcular (R-5) | media | docente |
| OBS-14 | ON DELETE #4/#21/#22/#23/#31 | baja | docente/equipo |

### 3.4 Aspectos correctos y justificados [OK]
| ID | Aspecto | Justificación |
|---|---|---|
| OK-01 | Cobertura completa de las 29 entidades mínimas (sec. 5) izquierda→derecha A-01→A-10 | trazabilidad por matriz A-09 §13 y checksum A-10 §9.1 |
| OK-02 | 25 relaciones con cardinalidades por extremo y `*` preservados; ninguna C inventada | A-04 §7.1; A-08 §5 |
| OK-03 | Sin PK elegida arbitrariamente: alternativas abiertas documentadas | A-09 §4; A-10 §3 |
| OK-04 | 6 asociativas con atributos propios correctos y minimalidad argumentada | A-05 §§3–10; A-09 §9 |
| OK-05 | Entidad débil Parcela bien representada (PK compuesta, FK identificadora, NOT NULL) | triple cita 3.2/sec. 5/etapa 1; A-09 §8 |
| OK-06 | Jerarquía mapeada condicionada a AMB-07, sin cerrar totalidad/exclusividad | A-06 §6–7; A-09 §10 |
| OK-07 | Análisis de DFs/3FN coherente: separaciones cabecera/renglón y encargado en Localidad evitan parciales/transitivas; sin certificación definitiva (declarado) | A-07 §§3–7 |
| OK-08 | Der↔esquema sin elementos fuera del trazado; FKs ubicadas en el lado de máximo 1 | A-09 §13/§14/§5.2 |
| OK-09 | Esquema↔diccionario 1:1 (29 tablas/128 columnas, nombres idénticos) | A-10 §9.1–9.2 |
| OK-10 | Ninguna UNIQUE/NOT NULL agregada sin respaldo; todas las ambigüedades marcadas PENDIENTE | A-09 §1.8, §6.2; A-10 §5 |

---

## 4. Síntesis de gravedad

Recuento final verificado (OBS-01…OBS-14):

| Gravedad | Cantidad | Observaciones |
|---|---|---|
| Crítica | 0 | — |
| Alta | 4 | OBS-04, OBS-05, OBS-06, OBS-07 |
| Media | 6 | OBS-01, OBS-02, OBS-03, OBS-08, OBS-09, OBS-13 |
| Baja | 3 | OBS-10, OBS-11, OBS-14 |
| Resuelta sin acción | 1 | OBS-12 |

---

## 5. Intervención de Persona B (estado)

- **Revisión de Persona B: PENDIENTE.** No se registró ninguna observación como proveniente de ella.
- Puntos que requieren expresamente su revisión/confirmación:
  1. A-06 (estrategia de mapeo de la jerarquía) — A-06 §7 lo exige.
  2. AMB-07 (totalidad/exclusividad) — decisión conjunta con docente.
  3. OBS-01/02/03 — ya corregidas en A-09 durante el cierre (informe en A-10 §9.3); Persona B valida la corrección al revisar A-09.
  4. OBS-04 (política de NOT NULL vs «Siempre» de A-02) — decisión conjunta antes de A-13.
- Nota de cierre: durante la fase de cierre de issues se corrigieron en A-09 las erratas de OBS-01/02/03 y se propagó DEC-02 (PK de `Lote`); este documento NO se reescribe para no alterar su histórico (razón registrada en A-12 §0). No se declaró aprobada ninguna actividad.

---

## 6. No alcance de esta revisión

- No se revisó la implementación SQL (no existe: A-09/A-10 no incluyen DDL).
- No se evaluaron Docker/PostgreSQL (A-12) ni tipos definitivos ENUM/DOMAIN (A-13): fases 3.

---

### Registro de cambios de este documento
- Cierre: se corrigió la referencia de §1 fila 1 (citaba OBS-05 por OBS-01); el desglose de gravedad de §4 ahora incluye OBS-13 en Media (6 medias, total 14 = 4+6+3+1); OBS-07 deja de incluir la PK de Lote (RESUELTA por DEC-02); nota de cierre sobre correcciones aplicadas en A-09.

- Creación (A-11, PRELIMINAR): revisión técnica independiente de A-01…A-10 contra requisitos; 14
  observaciones (0 críticas, 4 altas, 5 medias, 3 bajas + 1 sin acción), clasificadas en 5
  inconsistencias, 2 mejoras, 7 decisiones pendientes y 10 aspectos correctos; revisión de Persona B
  pendiente; sin modificaciones en documentos fuente.

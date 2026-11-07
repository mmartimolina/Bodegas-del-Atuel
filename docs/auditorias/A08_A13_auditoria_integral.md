# A08_A13_auditoria_integral.md — Auditoría integral de issues A-08 a A-13

> **Estado: informe de auditoría (no modifica documentos).** Verificación objetiva del estado de
> las issues A-08…A-13 contra `docs/requisitos.md` (única fuente de la consigna en este repositorio:
> el PDF original en `docs/Consigna/TPI_Bodegas_del_Atuel.pdf` no es legible en este entorno; toda
> cita proviene de esa transcripción) y contra `docs/modelo/01…13`.
>
> **Notas de método:**
> 1. **No existen archivos de issues en el repositorio** (no se encontró ningún `.md`/`*.yml` que
>    defina A-08…A-13). Sus objetivos/actividades se reconstruyen exclusivamente de (a) las cabeceras
>    y declaraciones de alcance de cada documento A-08…A-13 y (b) la consigna transcrita. No se
>    inventaron actividades ni criterios: cada ítem se cota con la sección de origen.
> 2. **No se modificó ningún documento existente** (incluidas las erratas detectadas, que quedan
>    listadas en §9 solo como hallazgos) ni archivos SQL (no existen: el repositorio no tiene
>    carpeta `db/` ni `.sql`; verificado con listado completo de archivos). Sin commits ni push.
> 3. Clasificación: **COMPLETADA** (verificable contra criterios), **PARCIALMENTE COMPLETADA**
>    (verificable pero con faltantes), **PENDIENTE**, **NO APLICA** (justificado).

---

## 1. Resumen ejecutivo

- Existen 13 documentos de modelo (A-01…A-13) + 8 archivos de diagrama (.drawio + 7 SVG), todos
  **sin aprobar por Persona B** (los A-08…A-13 lo declaran explícitamente). Ningún archivo SQL,
  Docker, tests ni código de aplicación existe todavía (coherente: pertenecen a etapas 2+).
- **Los 6 documentos A-08…A-13 están elaborados y son internamente trazados con la convención
  [R]/[I]/[P].** Su calidad de cobertura es alta (cobertura 29 tablas / 124 columnas verificadas
  dos veces: A-10 §9 y A-13 §8.30).
- **Deuda real:** (a) las **decisiones de claves y de negocio** (9 PK por elegir, AMB-07,
  ON DELETE abiertas) siguen pendientes por diseño deliberado y bloquean el cierre formal de
  A-08/A-09 y con ellos A-10/A-13; (b) **erratas y problemas de formato identificados pero no
  corregidos** (por restricción de la tarea) en A-09, A-10, A-11, A-12 y A-13 (§9); (c) la
  **exportación oficial del DER** (OBS-10 de A-11) espera aprobación de A-08.
- No se detectó **ningún conflicto estructural**: DER↔esquema↔diccionario↔tipos conservan los mismos
  nombres y cantidades (matrices de trazabilidad A-09 §13, A-09 §14, A-10 §9.1, A-13 §8).
- Cierre esperable de A-08…A-13 en dos pasos: (1) revisión de Persona B/docente (aprueba A-08,
  A-06/jerarquía y corrige erratas ya documentadas), (2) cierre de las decisiones pendientes
  catalogadas en A-12 (52 DEC) → entonces A-09/A-10/A-13 dejan de ser PRELIMINARES.

## 2. Estado general de A-08 a A-13

| Issue | Documento | Clasificación global | En una línea |
|---|---|---|---|
| A-08 | `08_diagrama_entidad_relacion.md` (+ .drawio + 7 SVG) | PARCIALMENTE COMPLETADA | DER completo y trazado; sin aprobación (Persona B) ni exportación oficial |
| A-09 | `09_esquema_relacional.md` | PARCIALMENTE COMPLETADA | 29 tablas/34 FK con minimalidad y trazabilidad; PKs y AMB-07 abiertos; 3 erratas sin aplicar |
| A-10 | `10_diccionario_de_datos.md` | PARCIALMENTE COMPLETADA | 124/124 columnas con tipos propuestos; PRELIMINAR por A-09; 1 fila de cabecera corrupta |
| A-11 | `11_revision_tecnica_previa.md` | COMPLETADA (con errata interna) | 14 observaciones verificadas; revisión de Persona B pendiente; desglose por gravedad omite OBS-13 |
| A-12 | `12_matriz_decisiones_pendientes.md` | COMPLETADA (con errata) | 52 DEC catalogadas con matriz de 12 campos y prioritización; fila 3 de prioridad mal titulada |
| A-13 | `13_tipos_postgresql_enum_domain.md` | PARCIALMENTE COMPLETADA | ENUM+DOMAIN propuestos y matriz 124/124; condicionada a PKs y Qs del docente |

---

## 3. Auditoría detallada de A-08

**Fuente:** `docs/modelo/08_diagrama_entidad_relacion.md` (304 líneas), `08_diagrama_entidad_relacion.drawio`, SVGs `08_der_00…06.svg`.

| Aspecto | Verificación |
|---|---|
| **Objetivo** | DER completo: 29 conceptos, atributos de A-02, claves candidatas de A-03 con estado, 25 relaciones de A-04 con cardinalidad por extremo, débil Parcela, jerarquía Cliente (A-06) sin cerrar AMB-07, 7 asociaciones de A-05 (A-08 §1). |
| **Dependencias** | A-01…A-07 (revisadas). No depende de A-09+. |
| **Actividades requeridas** (declaradas en A-08 §1/§2; consigna: herramienta §6, «entregar imagen/PDF y fuente») | Elegir herramienta (§2), notación (§2), 7 páginas (§3), inventario de entidades/claves (§4), representar relaciones/débil/jerarquía/asociaciones, exportación imagen/PDF + fuente (`Carried` §2.1: consigna exige «entregar imagen/PDF y fuente»). |
| **Trabajo realizado** | Herramienta elegida y justificada (draw.io, editable). 7 páginas diseñadas con módulos. `.drawio` generado por script; 7 SVG renderizados del mismo layout. Notación virtual completa ([K]/[K·inf]/[K·pend]/[AK·pend]/[K parcial]). Sin PK cerradas ni ambigüedades resueltas (A-08 §1: «no se hace en este documento»). |
| **Trabajo incompleto / errores** | 1) **Exportación oficial faltante**: los SVG no son exportación de draw.io; la consigna pide imagen/PDF y fuente. Declarado honestamente (A-08 §2.1) = PARCIALMENTE COMPLETADA (criterio «imagen/PDF» a nivel oficial no cumplido). 2) **Aprobación pendiente** (Persona B/docente → no cerrable). 3) Sin errores de contenido detectados (la auditoría A-11 OK-01/OK-02 y A-09 §14 la dan consistente). |
| **Requisitos no aplicados aquí (NO APLICA)** | SQL, cardinalidades físicas, perfiles de carga — pertenecen a A-09+ / etapa 2 (requisitos §5.2/§9.1). |
| **Para cerrar** | (a) aprobación de Persona B/docente; (b) exportación oficial PDF/PNG desde diagrams.net con el `.drawio` como fuente; (c) aplicar o rechazar correcciones sugeridas que la tocan (ninguna directa, salvo decisiones que afectan notación: DEC-51/DEC-52 de A-12, provisionales). |
| **¿Trabajable ahora?** | La elaboración ya está; lo que resta depende de la revisión (Persona B). Exportación: técnicamente posible ya, pero A-08 §2.1 la pospone a post-aprobación (decisión documentada, no reabrir). |

---

## 4. Auditoría detallada de A-09

**Fuente:** `docs/modelo/09_esquema_relacional.md` (574 líneas).

| Aspecto | Verificación |
|---|---|
| **Objetivo** (declarado en cabecera; consigna etapa 1 «esquema relacional») | Transformar el DER en propuesta de esquema relacional **documentado, sin SQL** (A-09 §15.2: sin DDL; los tipos van en etapa 2/A-13). |
| **Dependencias** | A-08 (sujeto a su aprobación), A-01…A-07, requisitos. |
| **Actividades requeridas** | 29 tablas listadas (§2); atributos por tabla (§3); PK con alternativas abiertas + minimalidad argumentada (§4); FKs ubicadas en el lado de máximo 1 (§5); UNIQUE respaldadas vs. no garantizadas (§6.1/§6.2); NOT NULL propuesta (§6.3); acciones referenciales caso por caso (§7); transformación de la débil Parcela (§8); N:M asociativas (§9); jerarquía Cliente condicionada a AMB-07 (§10); stocks 1:1 (§11); decisiones pendientes incorporadas sin abrir temas nuevos (§12, 17 ítems); trazabilidad DER↔esquema (§13); auditoría cruzada (§14). |
| **Trabajo realizado** | Todo lo anterior **verificado**: 29/29 filas de §2; 34 FKs con patrón/página de respaldo (§7.1 #1–#34); PK compuestas con argumento de minimalidad por caso (§4); matrices §13 (27 elementos DER → 29 tablas) y §14 (8 controles, sin elementos fuero del trazado — combinación via cruzar con A-11 OK-08). |
| **Trabajo incompleto** | Por diseño consciente: PK definitivas no elegidas (§4 «PK pendiente»: Localidad, Lote, Vino, Permiso, Comprobante, Ingreso, Transferencia, Transportista, Empleado); AMB-07 abierta; 5 ON DELETE sin decidir (#4/#21/#22/#23/#31); etapa 2 no implementada. Documento correcto en ese estado declarado (PRELIMINAR). |
| **Errores detectados (sin corregir)** | OBS-01: §2 encabezado «17 fuertes» (suma 30) vs tabla de 29 filas (reales 16 fuertes +1 débil) — A-11 §2/OBS-01. OBS-02: §3.12 cita «(RN-06)» para temperatura de Maridaje (fuente errónea) — A-11 OBS-02. OBS-03: §12.7 «35 % cliente (distrib.?)» cuando P-9/U6 refiere a **exportadores** con >3 permisos — A-11 OBS-03. Todas con corrección sugerida documentada y sin aplicar (regla: no modificar). |
| **Para cerrar** | (1) Aprobación de A-08; (2) resolución de las 9 PK (consulta docente por «decisiones de diseño», sec. 5 de la consigna); (3) resolución de AMB-07 (Persona B); (4) aplicar correcciones OBS-01/02/03 aprobadas; (5) revisión final de la propuesta al quedar des-consumado el PRELIMINAR. |
| **¿Trabajable ahora?** | No en su cierre: depende de (3) y de las PK. Re-trabajo no recomendado (ver A-11 OK-01…OK-10 contra requisitos). |

---

## 5. Auditoría detallada de A-10

**Fuente:** `docs/modelo/10_diccionario_de_datos.md` (670 líneas).

| Aspecto | Verificación |
|---|---|
| **Objetivo** (cabecera; consigna etapa 1 «diccionario de datos») | Documentar cada tabla/columna del esquema A-09 con tipo PostgreSQL propuesto, nulabilidad, claves, restricciones respaldables, defaults y descripción; sin cerrar ambigüedades ni agregar UNIQUE/NOT NULL sin respaldo. |
| **Dependencias** | A-09 (PRELIMINAR) y requisitos; deja pendientes para A-12/A-13. |
| **Actividades requeridas** | Diccionario por tabla (§2.1–2.29), claves PK/candidatas (§3), FKs documentadas con # y acciones referenciales (§4), UNIQUE respaldadas vs no respaldadas (§5), CHECK/NOT NULL (§6), tipos propios propuestos ENUM/DOMAIN (§7), dependencias y orden de creación (§8), auditoría (§9: cobertura, conteo, contradicciones, pendientes). |
| **Trabajo realizado (verificado)** | 29/29 tablas; conteo por tabla suma 124 (§9.2) — verificado en esta auditoría: 4+5+5+5+5+3+7+6+3+8+3+3+2+8+1+3+2+4+7+6+6+2+5+3+4+3+3+2+6 = **124**; nombres los mismos que A-09 (control §9.1); tipos marcados [R]/[I]/[P]; 4 contradicciones registradas (§9.3) consistentes con A-11; 52 pendientes catalogadas en A-12 sin trasponer nada aquí. |
| **Trabajo incompleto** | PKs sin elegir (§3 «PENDIENTE»); obligatoriedad física de descriptivos (§6.2 `P`; cf. DEC-14); algunos tipos con precisión sin respaldo (marcados [I], cf. DEC-31). Ninguna de esas faltas es «descuido»: están declaradas. |
| **Errores detectados (sin corregir)** | **§9.1, fila «Registro de contradicciones»**: la etiqueta de la fila aparece con texto corrupto (contiene caracteres de script no válidos: iler «Registro de contradictores») en lugar de «Registro de contradictions» — problema de codificación / glyph en la generación del archivo. Detectado en esta auditoría (no estaba en A-10 §9.3 ni en A-11): inconseqüencia de presentación, afecta solo esa fila (el contenido «Sí — §9.3 (4)» es correcto). Sin acción por restricción de no-modificar. |
| **Para cerrar** | (1) Cierre de A-09 (PKs/AMB-07/erratas); (2) resolución de DEC-14 (NOT NULL policy) y DEC-28/29/30/32 (dominios) que el diccionario marca para A-13; (3) re-verificación final del checksum §9.1-9.2 tras mantener los nombres intactos; (4) corregir la fila corrupta de §9.1. |
| **¿Trabajable ahora?** | No en su cierre (depende de A-09 y de A-12/A-13). Cobertura ya está (COMPLETADA); estado del documento (cierre formal) PENDIENTE. |

---

## 6. Auditoría detallada de A-11

**Fuente:** `docs/modelo/11_revision_tecnica_previa.md` (218 líneas).

| Aspecto | Verificación |
|---|---|
| **Objetivo** (cabecera) | Revisión técnica independiente de A-01…A-10 contra requisitos, **sin sustituir** la revisión de Persona B ni del docente; sin modificar documentos fuente. |
| **Dependencias** | A-01…A-10 completos. |
| **Actividades** | 10 criterios exigidos evaluados (§1); 14 observaciones detalladas con doc/secciíon, evidencia, impacto y decisión (§2); clasificación INC/MEJ/DEC/OK y gravedad (§3); síntesis (§4); intervención de Persona B (§5); no-alcance (§6). |
| **Trabajo realizado (verificado)** | 14 observaciones (OBS-01…OBS-14) listadas; conteos internos coinciden con A-10 §9.3 (4 contradicciones) y A-12 §5; 10 OK justificados con trazabilidad (OK-01…OK-10). |
| **Errores detectados (sin corregir)** | **(a) §4 desglose por gravedad omite OBS-13**: la tabla final registra «Media = 5 (OBS-01, 02, 03, 08, 09)» y separa «Resuelta sin acción = 1 (OBS-12)», pero OBS-13 está clasificada **media** en su propia sección (§2) y falta del desglose; el total declarado (14) es correcto y el desglose suma 13 unidades. Verificado y abierto en A-12 §0 (sin corregir A-11). **(b) §1, fila 1**: referencia a «OBS-05 (aritmética del encabezado)», cuando la observación de la aritmética es OBS-01; OBS-05 es PK de Localidad (la referencia de esa fila estaría mal asignada). Detectado en esta auditoría. |
| **Para cerrar** | (1) Revisión de Persona B (condición del propio documento §5); (2) si se aceptan, aplicar las correcciones sugeridas de A-09 (OBS-01/02/03) y registrar el desglose completo de §4 (incluido OBS-13); (3) corregir la referencia de §1 fila 1. |
| **¿Trabajable ahora?** | El trabajo documental está COMPLETADO; su cierre depende de Persona B/docente (la tarea no pude cerrarse sin su intervención, por diseño). |

---

## 7. Auditoría detallada de A-12

**Fuente:** `docs/modelo/12_matriz_decisiones_pendientes.md` (733 líneas).

| Aspecto | Verificación |
|---|---|
| **Objetivo** (declarado en cabecera) | Matriz consolidada de decisiones pendientes del modelo (52 DEC, grupos A–F), con verificación del desglose de gravedad de A-11 y restricción de no modificar documentos fuente. |
| **Dependencias** | A-01…A-11 y requisitos. |
| **Actividades** | Verificación previa de coherencia (§0); índice (§1); matrices con 12 campos por DEC (§2–§7: A=PKs, B=jerarquía, C=inconsistencias A-10, D=observaciones A-11, E=tipos/restricciones, F=otras); prioritización y grafo de dependencias (§8); resumen (§9). |
| **Trabajo realizado (verificado)** | 52 encabezados «### DEC-…» contados en este repositorio (verificación por `grep`): **52**; 79 líneas de estado «PENDIENTE DE DECISIÓN» (52 encabezados + 27 en cuerpo); §0 registra la discrepancia de A-11 (OBS-13) sin corregirlo; priorización en 5 niveles + grafo con cadenas críticas. |
| **Trabajo incompleto** | Ninguna decisión está tomada (correcto: todas PENDIENTE DE DECISIÓN). El «cierre» de A-12 como documento es atribuible cuando se resuelva lo que la propia matriz cataloga como dependiente de terceros. |
| **Errores detectados (sin corregir)** | **§8.1, fila 3**: título «Bloqueantes para A-12 (Docker + PostgreSQL)» con lista que incluye la anotación corrupta «¿catalog extra tables? complica el esquema» (DEC-38) y la frase «El DDL (001-008)» que remite a archivos de migración inexistentes en el repo de hoy. Problemas: (i) A-12 es la propia matriz, **no** el documento Docker/PostgreSQL; (ii) los archivos `001_esquema.sql`…`008_indices.sql` son del plan de etapas (requisitos §9.1), todavía no creados. La intención de la fila (blockees para el DDL/etapa 2) es correcta pero la numeración de issues y la frase contienen ruido. También: DEC-15 consecuencias usa la redacción «Cuento mínimos: 1 ENUM ya cumplido…» (§-content line 458; sin problema de fondo). Sin corrección por restricción. |
| **Para cerrar** | (1) Una vez resueltas las decisiones (docente/Persona B/equipo), actualizar estados PARCIAL→definida en A-13 y A-09/A-10; (2) corregir la fila §8.1 (título y lista); (3) formalizar el «orden de trabajo» acordado. |
| **¿Trabajable ahora?** | La matriz está COMPLETADA como catálogo. Su «cierre» es una consecuencia de resolver las decisiones catalogadas (dep. de terceros), no de escribir más. |

---

## 8. Auditoría detallada de A-13

**Fuente:** `docs/modelo/13_tipos_postgresql_enum_domain.md` (645 líneas).

| Aspecto | Verificación |
|---|---|
| **Objetivo** (declarado en cabecera) | Definir tipos PostgreSQL para las 124 columnas de A-10, ENUM de estados de documentos, DOMAIN de CUIT (con análisis de dígito verificador), orden de creación/eliminación de tipos y matriz de trazabilidad; sin DDL, migraciones ni cierre automático. |
| **Dependencias** | A-10 (diccionario), A-12 (DEC-25…DEC-33), requisitos. |
| **Actividades** | §2 ENUM; §3 DOMAIN + verificador; §4 tipos por categoría; §5 casos particulares; §6 orden de creación/dependencias/eliminación e implementación posterior; §7 mapeo DEC-25…DEC-33; §8 matriz 124/124; §9 checklist 1–7. |
| **Trabajo realizado (verificado)** | ENUM `estado_documento` con valores [R] y alcance (Ingreso/Transferencia) (**checklist 1 cumplido**); DOMAIN `cuit_dom` (CHAR(11) + CHECK de formato [R]; verificador documentado como PENDIENTE) (**checklist 1 cumplido en DOMAIN**); tipos sin FLOAT/REAL en importes (**checklist 3 cumplido**); matriz de trazabilidad 29/29 tablas y 124/124 columnas con conteo explícito (**checklist 2/§8**); pendientes con actor responsable (**checklist 4**); renombre `cuit`→`cuit_dom` documentado; estado PRELIMINAR explicitado (**no se marca aprobada la issue**) (**checklist 7**). |
| **Trabajo incompleto / condicionado** | Tipos de columnas-FK cuyo objetivo tiene PK sin elegir (§8 filas `pend`); dicotomía porcentaje/importe del descuento (Q-05, §4.1/§4.2/§8.19/§8.20); día de cierre sin dominio cerrado (Q-09); alcances finales de `cuit_dom` en Transportista/Empleado (DEC-26); autogeneración de `id_*` (DEC-10); lista cerrada de volúmenes (P-8); `Cepa.tipo`/`Vino.tipo` como CHECK vs DOMAIN (DEC-28). Todas registradas con alternativas y actores. |
| **Errores detectados (sin corregir)** | **§4.3**: un backtick abierto sin cerrar alrededor de `Comprobante.fecha` («`Comprobante.fecha,`») rompe el formato inline de esa frase; sección §9.5 contiene la frase con ruido «revisada; sin lenguaje, sin SQL…» (sobra la palabra; el sentido — «sin cambios de lenguaje ni SQL» — es el correcto). Sin acción por restricción. |
| **Para cerrar** | (1) Resolución de las PK pendientes (define tipos de ~20 columnas FK/subtipos); (2) respuestas docente Q-05/Q-08/Q-09/P-8 + decisión de dígito verificador (DEC-26); (3) decisiones de equipo DEC-10/DEC-28; (4) re-sellado de la matriz §8 con estados finales y salida del PRELIMINAR. |
| **¿Trabajable ahora?** | No en su totalidad: la matriz puede revisarse ya, pero el cierre formal está bloqueado por A-09 (PKs) y por las [Pregunta] al docente. |

---

## 9. Inconsistencias entre documentos y entregables

| # | Dónde | Descripción | Severidad | Acción sugerida (sin ejecutar) |
|---|---|---|---|---|
| I-1 | A-11 §4 vs §2 | El desglose por gravedad omite OBS-13 (media) y separa OBS-12: desglose suma 13 unidades vs total declarado 14. El total es correcto; ya verificado en A-12 §0. | baja (documental) | Corregir §4 al reintegrar OBS-13 (tras revisión de Persona B). |
| I-2 | A-11 §1 fila 1 | Referencia a «OBS-05 (aritmética del encabezado)»: la observación de la aritmética es OBS-01; OBS-05 es PK de Localidad. | baja (referencia) | Corregir cruce en §1. |
| I-3 | A-09 §2 | Aritmética del encabezado («17 fuertes», suma 30, reales 16 fuertes + 1 débil; tabla correcta en 29 filas). | media | Aplicar corrección OBS-01 tras aprobación. |
| I-4 | A-09 §3.12 | Cita «(RN-06)» como fuente de la temperatura de Maridaje (fuente errónea: 3.3/sec. 5). | media | Aplicar corrección OBS-02; no introducir CHECK de temperatura sin dominio. |
| I-5 | A-09 §12.7 | «35 % cliente (distrib.?)»: P-9/U6 refiere a exportadores con >3 permisos. | media | Aplicar corrección OBS-03; ligada a P-9 (pendiente docente). |
| I-6 | A-10 §9.1 | Fila de cabecera con texto corrupto («Registro de contradictores») en la etiqueta de la fila (contenido correcto). | baja (presentación) | Reparar la fila en la próxima revisión del diccionario. |
| I-7 | A-12 §8.1 fila 3 | Título «Bloqueantes para A-12 (Docker + PostgreSQL)» + nota corrupta «¿catalog extra tables?» y remisión a migraciones `001-008` inexistentes en el repo. A-12 es la propia matriz; el DDL pertenece a etapa 2 (requisitos §9.1). | media (referencia confusa) | Re-titular como «Bloqueantes del DDL (etapa 2)»; quitar ruido. |
| I-8 | A-13 §4.3 | Backtick abierto sin cerrar en `Comprobante.fecha`. | baja (formato) | Reparar formato al re editar el doc. |
| I-9 | A-13 §9.5 | Frase con palabra sobra («sin lenguaje»); sentido correcto («sin cambios de lenguaje ni SQL»). | baja (estilo) | Reparar en próxima revisión. |
| I-10 | A-08 §2.1 | SVGs declarados no oficiales (renderización, no exportación draw.io). La consigna pide imagen/PDF y fuente. Declarado, no inconsistente con el diseño; el criterio «exportación oficial» está comprometido. | media (criterio) | Exportar PDF/PNG oficial post-aprobación (OBS-10; DEC-20 de A-12). |
| I-11 | Todo el modelo | Ningun archivo SQL/Docker/.env existe (repo sin `db/` ni `api/`): coherente con el plan de etapas - NO se considera inconsistencia; lo registrado para evitar falsas expectativas (requisitos 9.1). | - (informativo) | NO APLICA (pertenece a etapas 2+). |
| I-12 | A-11 «No alcance» (§6) vs negocio de A-12/A-13 | A-11 dice «no se evaluaron Docker/PostgreSQL (A-12) ni tipos (A-13): fases 3», remitiendo a una fase «3» — la numeración de fases no está documentada en el repo (no hay archivo de issues). Evitar citar fases sin documento de origen. | baja (referencia) | Unificar referencias con nombres de documentos, no de fases. |

**Sin contradicciones estructurales detectadas:** entidades/atributos (29), cardinalidades y `*`
(inmovizados de A-04 a A-08), débil Parcela (A-09 §8), jerarquía condicionada (A-09 §10),
DFs/3FN (A-07 vía A-11 OK-07), DER y esquema (A-09 §13/§14), restricciones y FKs (A-09 §6–§7,
A-10 §4–§6), tipos PostgreSQL (A-10 §7 / A-13) y objetos SQL (NO APLICA a estas issues; la consigna
los exige en etapa 2/5, requisitos §5.2/§7.2/§9.1) se mantienen consistentes entre documentos.

---

## 10. Decisiones pendientes (foco de riesgo de cierre)

### 10.1 Verificación de las decisiones dadas por sentadas (punto §5 de la tarea)

| Decisión afirmada | ¿Está respaldada y cerrada? | Evidencia |
|---|---|---|
| Jerarquía Cliente (Socio/Distribuidor/Exportador) — «exclusiva y total por decisión documentada» | **PARCIALMENTE**: la **estrategia de mapeo** (supertipo + 3 subtipos con PK/FK heredada) sí está propuesta y justificada en A-06 (ventajas/desventajas, §3–§5) pero está **pendiente de revisión de Persona B** (A-06 §7); la **totalidad y la exclusividad (AMB-07) expresamente NO están cerradas**: A-04 §4 las cataloga abiertas; A-09 §10 dice «no se impone totalidad ni exclusividad (AMB-07 abierta)»; A-10 §9.4 la lista entre pendientes; A-11 la trata como DEC alta (OBS-06); A-12 la tiene en DEC-11/DEC-12 como **PENDIENTES**; A-13 condiciona los tipos de los subtipos a AMB-07. **No re-abrimos la estrategia (está documentada); sí-Encoding que cerrarla sigue siendo bloqueo para el DDL.** |
| Parcela débil identificada por (Finca, n_parcela) | **COMPLETADA y respaldada** (triple cita 3.2 + sec. 5 + UNIQUE (parcela, campaña) de etapa 2; minimalidad arg. en A-09 §4). OK-05 de A-11. No se reabre. Única decisión ligada abierta: ON DELETE de la FK identificadora (#4). |
| Precio histórico de venta conservado en el renglón | **COMPLETADA** como decisión documentada: `Renglon_Comprobante.precio_unitario` = valor histórico capturado (A-02 §2.20, R-4); A-10 §2.20 la propone [R NUMERIC]; coherente con RN-01/RN-13. Estrategia física (guardar vs calcular totales) sigue PENDIENTE (Q-05/R-5, DEC-23): no contradice esta decisión. |
| Suma de porcentajes de composición = 100 | **COMPLETADA** como regla [R] (RN-05) con mecanismo decidido (constraint trigger diferido, etapa 2; no CHECK de fila) — A-11 OK-04; A-10 §6.1. No se reabre. |
| Ausencia de registro de stock ≠ cantidad cero | **Documentada como supuesto/ambigüedad (no cerrada)**: AMB-11 (A-04/A-09 §11/A-10 §2.27) establece que fila ausente ≠ 0 pero el DEFAULT 0 (texto de etapa 2) y P-6 (>0 vs >=0) siguen abiertos; A-12 DEC-19 la cataloga PENDIENTE con docente. La **afirmación semántica** es consistente en todo el modelo; su **consecuencia física** (DEFAULT 0 sí o no) permanece abierta. |
| «Stock_Deposito ya fue analizado y cerrado» | **PARCIALMENTE**: el análisis está hecho (separación de stocks D-3 no cierra; «un solo depósito central» → 1 fila por vino; PK/FK `vino` cond., A-09 §5.3/§11), pero el cierre formal está **condicionado a D-3/AMB-11** (A-09 §12.4; A-10 §2.28; A-12 DEC-19 **PENDIENTE**). No hay contradicción; simplemente no está «cerrada» según los propios documentos (y así lo declara A-13 §8.28 [prop/pend]). |

Conclusión del punto 5: **no hay ninguna decisión que deba reabrirse por análisis incorrecto**;las
cerradas (Parcela, precio histórico, RN-05) están sólidamente documentadas; las «de jerarquía» y
«de stocks» deben tratarse como abiertas tal como los documentos lo declaran.

### 10.2 Inventario activo (resumen operable)

Actors y frecuencia de pendientes (todas en A-12 §2–§7, 52 DEC):

- **Dependen del docente** (consulta batch): 9 PK (DEC-01…09), AMB-07 parcialmente (DEC-11/12),
  Q-03/Q-05 (DEC-34/DEC-23)/Q-08 (DEC-30)/Q-09 (DEC-27), P-6 (DEC-19), P-8 (DEC-29), P-9 (DEC-17),
  4.ª UNIQUE (DEC-21), dígito verificador del CUIT (§3.2 de A-13).
- **Dependen de Persona B**: revisión de A-06 (Dec-13), aprobación de A-08, correcciones
  OBS-01/02/03, OBS-04.
- **Son del equipo (sola decisición escrita exigida por consigna sec. 5)** — R-5 (guardar vs calcular,
  DEC-23), DEC-10 (autogeneración IDs), DEC-14 (política NOT NULL), DEC-24 (ON DELETE con
  consecuencias ya desplegadas), DEC-28 (CHECK/DOMAIN material type), DEC-31 (precisiones), DEC-35…(
  menor).

## 11. Bloqueantes y dependencias

| Bloqueante | Bloquea | Origen |
|---|---|---|
| Aprobación de A-08 (Persona B/docente) | cierre de A-08; revalidación formal de A-09; exportación oficial del DER | A-08 cabecera; A-09 §15.1 |
| Revisión de A-06 (jerarquía) por Persona B + AMB-07 | PK/FK de Socio/Distribuidor/Exportador (#18–20), FK #21, DEC-11/12/13, tipos de subtipos en A-13 | A-06 §7; A-11 OBS-06/OK-06 |
| 9 PK por elegir (Localidad, Lote, Vino, Permiso, Comprobante, Ingreso, Transferencia, Transportista, Empleado) | FKs/renglones/stocks derivados; tipos de columnas en A-13 (§8 filas `pend`); DDL (etapa 2) | sec. 5 «decisiones de designo» |
| [Pregunta] docente (Q-03/05/08/09, P-6/P-8/P-9, 4.ª UNIQUE, dígito verificador, RN-06 vs U6) | dominios y CHECKs; tipo de `descuento`; `dia_semana`; catálogo volúmenes | requisitos §10.2; A-12 DEC-14/21/23/27/29/30/32; A-13 |
| Correcciones erratas aprobables (OBS-01/02/03; I-1…I-9 de §9) | presentación y trazabilidad de A-09…A-13 | A-11 §2; §9 arriba |
| Exportación oficial del DER (OBS-10/DEC-20) | criterio «imagen/PDF oficial» de A-08 | A-08 §2.1 |

---

## 12. Lista priorizada de correcciones (sin ejecutar)

1. **Alta (bloquea DDL y cierre):** resolver la revisión de Persona B (A-08 y A-06/AMB-07) y las
   9 PK (consulta docente). Base de todo lo demás (A-12 §8.1).
2. **Alta (cortos errores de fondo):** aplicar OBS-01/02/03 en A-09 cuando estén aprobadas
   (cambios de texto mínimos, ya redactados en A-11).
3. **Media (trazabilidad):** corregir A-11 §1 (cruce OBS-01/OBS-05) y A-11 §4 (incluir OBS-13 en
   el desglose de «media»).
4. **Media (referencias):** corregir A-12 §8.1 fila 3 (título + lista) para no atribuir Docker a
   A-12 y quitar la referencia a migraciones inexistentes.
5. **Baja (formato):** reparar fila corrupta de A-10 §9.1 (etiqueta «Registro de contradicciones»);
   reponer backticks de A-13 §4.3 y frase «sin lenguaje» de §9.5; revisar estilo («Cuento mínimos»,
   «anciliares» ya corregida parcialmente).
6. **Post-aprobación:** exportar PDF/PNG oficial del DER desde draw.io (criterio A-08).

## 13. Propuesta de orden de trabajo para cerrar A-08 a A-13

1. **Solicitar revisión de Persona B** sobre A-06 (estrategia de jerarquía) y A-08 (DER): es la
   condición declarada en ambos documentos para salir del estado PRELIMINAR (no re-trabajar, solo
   validar).
2. **Enviar consulta batch al docente** con las 9 PK + [Pregunta] abiertas (lista exacta en
   A-12 §8 y requisitos §10.2): es la llave de las FKs renglón/stock y de los tipos de A-13.
3. **Aprobar erratas** (OBS-01/02/03 y hallazgos §9) y aplicarlas en una sola pasada (sin tocar
   decisiones); luego resellar A-09/A-10.
4. **Cerrar decisiones de equipo** (DEC-10, DEC-14, DEC-23, DEC-24, DEC-28, DEC-31/DEC-35…): son
   exigibles por la consigna («justificar por escrito», sec. 5) y no necesitan docente.
5. **Re-sellar documentos**: A-09 (PKs elegidas), A-10 (NOT NULL policy de A-12 DEC-14 aplicada),
   A-13 (matriz §8 con estado final; salida del PRELIMINAR), A-11 (desglose completo).
6. **Exportar DER oficial** (criterio de A-08) y registrar trazabilidad final (A-09 §14, A-13 §9).

| Issue | Estado real | Trabajo faltante | Bloqueantes | Próximo paso recomendado |
|---|---|---|---|---|
| A-08 | PARCIALMENTE COMPLETADA — cobertura completa, sin aprobación ni export oficial | Exportación PDF/PNG oficial; aprobación | Persona B/docente; exportación pospuesta por decisión documentada | Enviar a revisión; exportar tras aprobación |
| A-09 | PARCIALMENTE COMPLETADA — propuesta completa y trazada; PKs/AMB-07 abiertos; 3 erratas | Elegir 9 PK; cerrar AMB-07; aplicar OBS-01/02/03; revisar ON DELETE #4/21/22/23/31 | PKs (docente); AMB-07 (Persona B) | Consulta batch; luego re-sellar PRELIMINAR |
| A-10 | PARCIALMENTE COMPLETADA — 29/29 · 124/124 cobertura; dependiente de A-09 | Cerrar con PKs; política NOT NULL (DEC-14); corregir fila corrupta §9.1 | A-09; DEC-14 | Esperar paso 1/3; luego re-verificar checksum |
| A-11 | COMPLETADA (con 2 erratas propias) — 14 observaciones verificadas | Revisión de Persona B; corregir §1 y §4 (I-1/I-2) | Persona B | Incluir en la misma revisión A-08/A-06 |
| A-12 | COMPLETADA como matriz (52 DEC) — errata en §8.1 fila 3 | Resolver/handler decisiones catalogadas; corregir fila 3 | Docente + Persona B + equipo | Usar la matriz como guía de la consulta batch |
| A-13 | PARCIALMENTE COMPLETADA — ENUM/DOMAIN y matriz de tipos (124/124) propuesta | Tipos de ~20 columnas dependientes de PKs; Q-05/Q-09/P-8; verificador CUIT; dicembre de 4.ª UNIQUE | A-09 (PKs); docente (Q); equipo (DEC-10/28) | Re-sellar tras resultados de 1–3 |

### Clasificación compendio (actividades verificables)

| Clase | Cantidades |
|---|---|
| COMPLETADAS (verificables) | A-11 (documento de auditoría), A-12 (matriz), y dentro de cada otra issue la **elaboración/cobertura** (A-08 §1–§4/§5, A-09 §1–§14, A-10 §1–§9 cobertura, A-13 §2–§8) |
| PARCIALMENTE COMPLETADAS | A-08 (export oficial), A-09 (PK/AMB-07/erratas), A-10 (cierre cond. de dominios), A-13 (tipos dependientes de PKs/Qs) |
| PENDIENTES | Revisión de Persona B/docente; 52 DEC de A-12; exportación oficial; re-sellado de PRELIMINARES |
| NO APLICA | Implementación SQL (DDL/funciones/procs/triggers/vistas/roles/índices/consultas de S1–S12, Docker, API, front, carga masiva): pertenece a etapas 2–8 de la consigna (requisitos §5.2–§8), **fuera de las issues A-08…A-13 documentadas**; su ausencia en el repo no es déficit de estas issues |

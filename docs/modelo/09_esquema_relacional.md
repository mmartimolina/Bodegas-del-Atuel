# A-09 — Propuesta preliminar de esquema relacional

> **Estado: PRELIMINAR, sujeto a la aprobación de A-08** (el DER aún no fue revisado/aprobado; esta
> propuesta deberá revalidarse si A-08 cambia tras la revisión). **No se presenta como definitivo y no
> incluye SQL:** la etapa pide el diseño documental, no el DDL.
>
> Esqueleto de marcaje como en A-03/A-04: [R] = respaldado, [I] = inferido, [P] = pendiente/condicionado.
> **Las PK adoptadas se reflejan como decisiones vigentes**; las condiciones de negocio todavía abiertas
se mantienen identificadas como pendientes. Las FK se definen en función de las PK adoptadas, sin
confundir las decisiones estructurales con las acciones referenciales aún pendientes.
>
> Fuentes: A-08 (DER, páginas 00–06), A-01…A-07 completos, `docs/requisitos.md` (nota: el PDF original no
> es legible en este entorno; todas las citas provienen de esa transcripción). **No se inventan** entidades,
> atributos, claves, restricciones ni acciones referenciales que no deriven de esos documentos.

---

## 1. Criterios de transformación

1. **Una relación/tabla por entidad fuerte** del DER (criterio clásico etapa 1, paso 3), con los
   atributos aprobados en A-02.
2. **Relación 1:N → FK del lado "muchos"** (el extremo con máximo 1). La FK apunta a la clave de la
   entidad del lado "uno". Para el caso 1:1 (relación Vino–Stock de depósito): ver §5.3 y §11.
3. **Relación identificadora (entidad débil)** → la clave del débil se compone de la clave del
   propietario + la clave parcial (Parcela, §8).
4. **Relación N:M** → tabla de la asociación con las dos FK de participantes y sus atributos propios
   (A-05: §9); la minimalidad de cada PK compuesta se argumenta en §4.
5. **Inventarios** (Stock de sala / Stock de depósito) transformados según sus claves con estado
   (§11), sin unificarlos (D-3).
6. **Jerarquía Cliente** según la decisión de A-06 (supertipo + tabla por subtipo) (§10).
7. **Las claves primarias se definen según las decisiones adoptadas y su respaldo**: las alternativas
   resueltas en A-12 se reflejan en §2 y §4; las condiciones de negocio todavía abiertas se conservan
   como pendientes en §12, sin reabrir decisiones estructurales ya adoptadas.
8. **No se agregan UNIQUE/NOT NULL** sin respaldo textual (§6).
9. **Acciones referenciales (ON DELETE/ON UPDATE) propuestas caso por caso** (§7), con patrón, regla
   de respaldo, efecto, consecuencia y necesidad de confirmación — nunca "automáticas".

---

## 2. Listado completo de relaciones/tablas propuestas (preliminar)

29 conceptos (A-08/A-01) → **29 tablas**: 16 de entidades fuertes + 1 débil (Parcela) + 6 asociativas +
2 de stock + 3 subtipos (A-06) + 1 técnica de auditoría.

| # | Tabla | Origen | PK propuesta (estado) |
|---|---|---|---|
| 1 | `Localidad` | entidad fuerte pág. 03 | `id_localidad` [R: PK subrogada adoptada; DEC-01/DEC-10] |
| 2 | `Sala` | entidad fuerte pág. 03 | `id_sala` [R: PK subrogada adoptada; identidad según DEC-10] |
| 3 | `Empleado` | entidad fuerte pág. 03 | `id_empleado` [R: PK subrogada adoptada; DEC-09/DEC-10] |
| 4 | `Finca` | entidad fuerte pág. 01 | `id_finca` [R: PK subrogada adoptada; identidad según DEC-10] |
| 5 | `Parcela` (débil) | pág. 01 | **`(finca, n_parcela)` = ParK-1 [R triple cita]** (ver §8) |
| 6 | `Cepa` | entidad fuerte pág. 01 | `id` [R]; AK `nombre` [P: sin UNIQUE declarada] |
| 7 | `Lote` | entidad fuerte pág. 01 | **`(finca, n_parcela, campania)` = PK compuesta adoptada (DEC-02)**; `n_lote` [I: atributo descriptivo, sin UNIQUE] |
| 8 | `Analisis` | entidad fuerte pág. 01 | `id_analisis` [R: identidad dudosa D-6]; AK `(finca, n_parcela, campania, fecha)` [P sin garantia de unicidad (AMB-13: confirmacion si se permiten dos analisis por fecha); AK-2 extendida a la PK compuesta de `Lote` (DEC-02)] |
| 9 | `Bodega` | entidad fuerte pág. 02 | `cuit` [R: UNIQUE textual de etapa 2] |
| 10 | `Vino` | entidad fuerte pág. 02 | `codigo` [PK adoptada; DEC-03]; UNIQUE adicional `(nombre, anada, volumen_ml)` |
| 11 | `Composicion` (asociativa) | REL-10 | **`(vino, cepa)`** [I: par de participantes; garantía de no repetición pendiente ComK-a; atributo `porcentaje` sujeto a RN-05 «sumar 100 por vino»] |
| 12 | `Maridaje` | entidad fuerte pág. 02 | `id` [R]; AK `nombre` [P] |
| 13 | `Vino_Maridaje` (asociativa) | REL-11 | **`(vino, maridaje)`** [I: VMK-1; D-9 notación sin cerrar] |
| 14 | `Cliente` (supertipo) | pág. 03/A-06 | `id_cliente` [PK subrogada adoptada; DEC-10; jerarquía según DEC-11/DEC-12] |
| 15 | `Socio` (subtipo) | pág. 03/A-06 | `id_cliente` PK/FK heredada [I: mapeo adoptado en A-06] |
| 16 | `Distribuidor` (subtipo) | pág. 03/A-06 | `id_cliente` PK/FK heredada [I: mapeo adoptado en A-06] |
| 17 | `Exportador` (subtipo) | pág. 03/A-06 | `id_cliente` PK/FK heredada [I: mapeo adoptado en A-06] |
| 18 | `Permiso_Exportacion` | entidad fuerte pág. 03 | `codigo` [PK adoptada; DEC-04] |
| 19 | `Comprobante` | entidad fuerte pág. 04 | `numero` [PK adoptada; global; DEC-05] |
| 20 | `Renglon_Comprobante` (asociativa) | REL-14 | **`(comprobante, vino)`** = RK-1 [R textual sec. 5; la repetición del vino queda excluida por la clave] |
| 21 | `Transportista` | entidad fuerte pág. 05 | `codigo` [PK adoptada; DEC-08]; `cuit` se conserva como atributo fiscal sin UNIQUE |
| 22 | `Transportista_Localidad` (asociativa) | REL-17 | **`(transportista, localidad)`** [I; D-9 (¿relación o entidad?)] |
| 23 | `Ingreso` | entidad fuerte pág. 05 | `codigo` [PK adoptada; global; DEC-06] |
| 24 | `Renglon_Ingreso` (asociativa) | REL-20 | **`(ingreso, vino)`** [I por analogía con RK-1 (no textual; RI-a)] |
| 25 | `Transferencia` | entidad fuerte pág. 06 | `numero` [PK adoptada; global; DEC-07] |
| 26 | `Renglon_Transferencia` (asociativa) | REL-22 | **`(transferencia, vino)`** [I por analogía con RK-1 (no textual; RT-a)] |
| 27 | `Stock_Sala` (inventario) | REL-23 | **`(sala, vino)`** = SS-1 [R textual sec. 5] |
| 28 | `Stock_Deposito` (inventario) | REL-24 | **`(vino)`** [PK/FK adoptada; permanece pendiente la definición de negocio D-3/AMB-11] |
| 29 | `Auditoria_Precio` | REL-25 | **`id_auditoria` [R]** (RN-13); UNIQUE `(vino, fecha_hora)` [P: hipótesis técnica del trigger] |

> Nota de consistencia con A-05 §12: las tablas de renglones y cobertura toman como PK el **par de
> las dos entidades participantes**. Para `Renglon_Comprobante` la no-repetición del vino por
> comprobante **está derivada de la clave textual** (sec. 5); para `Renglon_Ingreso` /
> `Renglon_Transferencia` / `Transportista_Localidad` es **abierta** (RI-a / RT-a / sin texto): si la
> respuesta fuera "sí se puede repetir", la PK compuesta debe extenderse con un n.º de renglón.
> La consulta al docente lo resuelve (ver §12). Ninguna respuesta cambia la estructura general,
> sólo la PK/FK de la tabla.

---

## 3. Atributos de cada relación/tabla (sin SQL); dominios y derivados según A-02

Los atributos listados en A-02 como «futuras relaciones» (participantes de una relación) se materializan
aquí como **FKs** (nombre de columna + entidad objetivo).

1. **Localidad**: `id_localidad` (PK subrogada; DEC-01/DEC-10), `codigo_postal` (AK candidata), `nombre`, `provincia`, `encargado_regional` (RN-02).
2. **Sala**: `id_sala` (PK [R]: «ID» textual de la sección 5, formalizada como subrogada), `calle`,
   `numero`, `dia_cierre` (dominio día de la semana: Q-09 sin cierre), FK a *Localidad* (REL-01).
3. **Empleado**: `id_empleado` (PK subrogada; DEC-09/DEC-10), `cuit` (atributo fiscal sin UNIQUE), `nombre`, `fecha_ingreso` (la antigüedad es derivada — `fn_antiguedad_anios` no se almacena), `salario` (Q-08 positividad pendiente), FK a *Sala* (REL-02).

4. **Finca**: `id_finca` (PK [R]), `nombre`, `superficie`, `departamento`, `provincia`
   (Q-11: catálogo/normalización de provincias/departamentos sin cerrar).

5. **Parcela** (débil): `finca` (FK componente de PK, ver §8), `n_parcela` (clave parcial),
   `superficie`, `anio_plantacion`, FK a *Cepa* (REL-05).

6. **Cepa**: `id` (PK [R]), `nombre` (AK [P: sin UNIQUE declarada]), `tipo` (tinta/blanca).

7. **Lote**: `finca` (FK componente de PK, parte de la PK compuesta),
   `n_parcela` (FK componente de PK), `campania` (PK; año: D-5),
   `n_lote` [I] (atributo descriptivo), `fecha_cosecha`, `kg` (> 0: RN-15,
   sin dominio cerrado), FK a *Bodega* `bodega_destino` (REL-07; nombre
   con rol para distinguir la bodega elaboradora, AMB-06).

8. **Analisis**: `id_analisis` (PK [R]; la identidad de fila por sí misma
   es dudosa: D-6), FK compuesta a *Lote* (`finca`, `n_parcela`,
   `campania`) (REL-08), `fecha`, `brix`, `ph`, `acidez`
   (la AK `(finca, n_parcela, campania, fecha)` sin garantía: AMB-13).

 9. **Bodega**: `cuit` (PK [R]: UNIQUE textual de etapa 2 + 3.10),
   `razon_social` (NO UNIQUE: descartada en A-03), `domicilio`.

10. **Vino**: `codigo` (PK adoptada; DEC-03), `nombre`, `tipo` (tinto/blanco/rosado/espumante), `anada` (año),

11. **Composicion**: FK a *Vino* + FK a *Cepa* (REL-10), `porcentaje` (RN-05: la suma por vino debe
    dar 100 — restricción agregada, no depende de la clave por sí).

12. **Maridaje**: `id` (PK [R]), `nombre` (AK [P]), `temperatura` (sección 3.3 / sección 5).

13. **Vino_Maridaje**: FK a *Vino* + FK a *Maridaje* (REL-11); sin atributos propios.

14. **Cliente**: `id_cliente` (PK subrogada; DEC-10), `nombre` (Q-04: persona/empresa), `tipo_doc` + `n_doc`

    (AK candidata [P]), `direccion` (Q-10), FK a *Localidad* (REL-03), `fecha_alta`
    (la etapa 2 dice «fecha actual» al alta), `descuento` persistente, sincronizado mediante `fn_descuento_cliente` (DEC-32; RN-06),
    P-9 (U6): pendiente únicamente la confirmación docente de la regla especial del 35 % para exportadores con más de 3 permisos. El descuento base de 10/20/30 % y su materialización fueron adoptados en DEC-32.

15. **Socio**: `id_cliente` (PK/FK heredada de *Cliente*); sin atributos propios.

16. **Distribuidor**: `id_cliente` (PK/FK heredada de *Cliente*), `zona`, `n_habilitacion`.

17. **Exportador**: `id_cliente` (PK/FK heredada de *Cliente*), `pais`.

18. **Permiso_Exportacion**: `codigo` (PK adoptada; DEC-04), FK a *Exportador* (REL-16), `fecha_emision` [P],
    `fecha_vencimiento` (RN-07: fecha_vencimiento > fecha_emision — CHECK entre columnas),
    vigencia derivada no almacenada (Q-12 [Inferencia]).

19. **Comprobante**: `numero` (PK adoptada, numeración global; DEC-05), `fecha`,
    FK a *Cliente* (REL-12), FK a *Sala* (REL-13), `subtotal`, `descuento`, `total` (derivados
    RN-08: el negocio no los carga manualmente; el almacenamiento o cálculo se justifica por
    escrito en la etapa 2).

20. **Renglon_Comprobante**: FK compuesta a *Comprobante* + FK a *Vino* (REL-14), `cantidad`
    (> 0: RN-15), `precio_unitario` (capturado histórico, no calculado: A-02 §2.20),
    `descuento` (dominio Q-05), `subtotal` (derivado: RN-08).

21. **Transportista**: `codigo` (PK adoptada; DEC-08), `razon_social`, `cuit`, `email`, `telefono`, `domicilio`
   (`cuit` carece de UNIQUE declarada — la única UNIQUE textual de CUIT es la de Bodega; TK-a).

22. **Transportista_Localidad**: FK a *Transportista* + FK a *Localidad*; sin atributos propios
    (tabla de cobertura; sin "frecuencia de cobertura" ni atributo almacenado — no respaldado).

23. **Ingreso**: `codigo` (PK adoptada; DEC-06), `fecha` (semántica sin resolver:
¿fecha de entrada en la bodega de origen o
    en la de destino? Q-03), `estado` (RN-10: `en_confeccion` / `terminado` / `procesado`),
    FK a *Transportista* (REL-19), FK a *Bodega* llamada `bodega_origen` (REL-18).

24. **Renglon_Ingreso**: FK compuesta a *Ingreso* + FK a *Vino* (REL-20), `cantidad` (RN-15: > 0).

25. **Transferencia**: `numero` (PK adoptada, numeración global; DEC-07), `fecha_confeccion` (RN-11: fecha actual al crear, NO modificable
    una vez creada), `estado` (RN-11: `en_confeccion` / `terminado` / `procesado`),
    FK a *Sala* (REL-21).

26. **Renglon_Transferencia**: FK compuesta a *Transferencia* + FK a *Vino* (REL-22),
    `cantidad` (> 0: RN-15).

27. **Stock_Sala**: FK a *Sala* + FK a *Vino* (REL-23), `cantidad` (RN-09: >= 0 con P-6 abierto:
    ¿se permite cantidad 0, o la fila desaparece cuando llega a 0? — ausencia de fila ≠ cantidad 0,
    AMB-11).

28. **Stock_Deposito**: FK a *Vino* (REL-24; `vino` es PK/FK adoptada), `cantidad` (RN-09: >= 0 con P-6 abierto).

29. **Auditoria_Precio**: `id_auditoria` (PK [R] por RN-13), FK a *Vino* (REL-25),
    `precio_anterior`, `precio_nuevo`, `fecha_hora`, `usuario` (Q-07: ¿usuario de la BD o del
    funcional?).

**NO se incluyen como columnas**: stocks/totales calculados que se derivan en consulta (S9: stock
total por vino = stock de depósito + sumatorio de stocks de sala; antigüedad del empleado), ni el
encargado regional como entidad propia (D-4), ni el depósito central como entidad propia (A-01 §5),
ni atributos adicionales en los stocks (Q-13 (a) [Inferencia]: no respaldado).

---

## 4. Claves primarias propuestas (consolidado), sin elección definitiva


**Minimalidad de las pk compuestas** (justificación caso por caso, como pide la consigna):
| Estado | Tablas | Detalle |
|---|---|---|
| PK subrogadas adoptadas | `Localidad` (`id_localidad`), `Sala` (`id_sala`), `Empleado` (`id_empleado`), `Finca` (`id_finca`), `Cepa` (`id`), `Analisis` (`id_analisis`), `Maridaje` (`id`), `Cliente` (`id_cliente`), `Auditoria_Precio` (`id_auditoria`) | Identificadores subrogados; generación `BIGINT GENERATED ALWAYS AS IDENTITY` según DEC-01, DEC-09 y DEC-10, según corresponda. |
| PK naturales adoptadas | `Bodega` (`cuit`), `Vino` (`codigo`), `Permiso_Exportacion` (`codigo`), `Comprobante` (`numero`), `Transportista` (`codigo`), `Ingreso` (`codigo`), `Transferencia` (`numero`) | Identificadores naturales adoptados. Vino: DEC-03; Permiso: DEC-04; Comprobante: DEC-05; Ingreso: DEC-06; Transportista: DEC-08; Transferencia: DEC-07. |
| PK compuestas adoptadas | `Parcela` (`finca`, `n_parcela`), `Lote` (`finca`, `n_parcela`, `campania`), `Composicion` (`vino`, `cepa`), `Vino_Maridaje` (`vino`, `maridaje`), `Renglon_Comprobante` (`comprobante`, `vino`), `Renglon_Ingreso` (`ingreso`, `vino`), `Renglon_Transferencia` (`transferencia`, `vino`), `Transportista_Localidad` (`transportista`, `localidad`), `Stock_Sala` (`sala`, `vino`) | Claves adoptadas según el respaldo textual o la decisión de diseño correspondiente. `Lote`: DEC-02. Las claves de renglones y asociaciones conservan las condiciones de repetición pendientes donde corresponda. |
| PK heredadas del supertipo | `Socio`, `Distribuidor`, `Exportador` → `id_cliente` | PK/FK heredada de `Cliente`; estrategia de mapeo adoptada en DEC-13. |
| PK/FK adoptada; regla de negocio pendiente | `Stock_Deposito` (`vino`) | PK/FK a `Vino` adoptada; se mantiene pendiente la definición semántica de D-3/AMB-11 sobre el depósito central y la fila ausente. |
- `(finca, n_parcela)`: minimal — `n_parcela` solo no es clave (varias fincas numeran «1»), y `finca`
  sola no identifica la parcela; respaldada por la cita triple de la clave del débil.
- `(comprobante, vino)`: minimal — un comprobante contiene varios vinos y un vino se vende en muchos
  comprobantes; textual de la sección 5.
- `(sala, vino)`: minimal — cada sala almacena stock de varios vinos y cada vino se almacena en
  múltiples salas; textual de la sección 5.
- `(vino, cepa)` / `(vino, maridaje)`: minimal — cada lado necesita al otro para identificar el par;
  la repetición permitida o no de la combinación queda abierta (ComK-a).
- `(ingreso, vino)` / `(transferencia, vino)`: minimal **solo si** se mantiene el supuesto
  "(sin repetición del vino por documento)" (RI-a/RT-a abiertas: se pide confirmación docente).
- `(transportista, localidad)`: minimal — par sin atributos y sin texto que indique repetición (D-9).
- `(vino)` (Stock_Deposito): por la condición "un registro por vino" («un solo depósito central»,
  sección 5).

---

## 5. Claves foráneas propuestas

### 5.1 FK del lado 1:N (posee la tabla "muchos"), resumidas por relación

| Tabla.col → Target | Deriva de | Estado de la PK del target |
|---|---|---|
| `Sala.localidad → Localidad` | REL-01 | [P: LK-a/LK-b] |
| `Empleado.sala → Sala` | REL-02 | [R] |
| `Cliente.localidad → Localidad` | REL-03 | [P: LK-a/LK-b] |
| `Parcela.finca → Finca` (FK component) | REL-04 (identificadora débil) | [R] |
| `Parcela.cepa → Cepa` | REL-05 | [R] |
| `Lote.(finca, n_parcela) → Parcela` (FK compuesta) | REL-06 | [R] |
| `Lote.bodega_destino → Bodega` | REL-07 | [R] |
| `Analisis.(finca, n_parcela, campania) → Lote` | REL-08 | [R: PK de Lote adoptada en DEC-02; FK compuesta] |
| `Vino.bodega → Bodega` | REL-09 | [R] |
| `Composicion.vino → Vino` / `Composicion.cepa → Cepa` | REL-10 | [P/I] / [R] |
| `Vino_Maridaje.vino → Vino` / `.maridaje → Maridaje` | REL-11 | [P/I] / [R] |
| `Comprobante.cliente → Cliente` | REL-12 | [R] |
| `Comprobante.sala → Sala` | REL-13 | [R] |
| `Renglon_Comprobante.comprobante → Comprobante` / `.vino → Vino` | REL-14 | [P/I] / [P/I] |
| `Socio.id_cliente → Cliente` (FK PK/FK) | REL-15 (subtipo, A-06) | [R] |
| `Distribuidor.id_cliente → Cliente` (FK PK/FK) | REL-15 (subtipo, A-06) | [R] |
| `Exportador.id_cliente → Cliente` (FK PK/FK) | REL-15 (subtipo, A-06) | [R] |
| `Permiso_Exportacion.exportador → Exportador` | REL-16 | [FK·pend target] (PK heredada, A-06) |
| `Transportista_Localidad.transportista → Transportista` | REL-17 | [P/I] |
| `Transportista_Localidad.localidad → Localidad` | REL-17 | [P] |
| `Ingreso.bodega_origen → Bodega` | REL-18 | [R] |
| `Ingreso.transportista → Transportista` | REL-19 | [P/I] |
| `Renglon_Ingreso.ingreso → Ingreso` / `.vino → Vino` | REL-20 | [P/I] |
| `Transferencia.sala → Sala` | REL-21 | [R] |
| `Renglon_Transferencia.transferencia → Transferencia` / `.vino → Vino` | REL-22 | [P/I] |
| `Stock_Sala.sala → Sala` / `.vino → Vino` | REL-23 | [R] / [P/I] |
| `Stock_Deposito.vino → Vino` | REL-24 | [R: PK/FK adoptada] |
| `Auditoria_Precio.vino → Vino` | REL-25 | [P/I] |

### 5.2 Ubicación (justificada 1:N por el lado de máximo 1):

- Cada relación binaria con un extremo de máximo 1 pone su FK en la tabla de ese extremo; el lado
  "uno" no necesita FK. Las columnas FK usan **nombre con rol** cuando hay varios roles hacia la
  misma entidad (Lote → Bodega como `bodega_destino`; Ingreso → Bodega como `bodega_origen`;
  Permiso → Exportador as `exportador`).
- En las asociativas N:M, cada participante se materializa como parte de la PK compuesta (§4) y
  como FK (§9).
- El débil (Parcela) incorpora su FK propietaria como componente de la clave (§8).

### 5.3 Relación 1:1 (Vino ↔ Stock_Deposito):

- Cada vino registra a lo sumo **un** stock de depósito (relación opcional del lado del vino). En el
  esquema se materializa con la **existencia o no de la fila** en `Stock_Deposito` (no mediante
  NULL), y la FK `vino` actúa como PK (un registro por vino, UNIQUE [I]). No se impone que todo
  vino tenga fila (la obligatoriedad inversa es incierta: AMB-11). No se agrega NOT NULL sobre esa
  FK porque ya es PK. Confirmación: revisar con el docente.

---

## 6. Restricciones de unicidad y obligatoriedad respaldadas (y ausencias justificadas)

### 6.1 UNIQUE textualmente respaldadas

| Tabla | UNIQUE | Fuente |
|---|---|---|
| `Bodega` | `cuit` | etapa 2 (consigna) |
| `Vino` | `(nombre, añada, volumen)` | etapa 2 + 3.3 |
| `Lote` | `(parcela, campaña)` | etapa 2 (con UNIQUE (parcela, campaña)); RN-04 (lotizado c/campaña) |
| `Parcela` | `(finca, n_parcela)` | zona PK |
| `Renglon_Comprobante` | `(comprobante, vino)` | zona PK (sección 5) |
| `Stock_Sala` | `(sala, vino)` | zona PK (sección 5) |
| `Stock_Deposito` | `vino` | PK/FK adoptada; la decisión de negocio sobre mantener o unificar la tabla sigue pendiente (D-3/AMB-11) |
| `Socio`/`Distribuidor`/`Exportador` | `id_cliente` | Derivado de las PK/FK heredadas del mapeo adoptado en A-06; cada subtipo admite como máximo una fila por `id_cliente`. La disyunción entre las tres tablas y la totalidad de la jerarquía requieren mecanismos adicionales de integridad. |
| `Auditoria_Precio` | `id_auditoria` (subrogado) | RN-13 (identificador de la auditoría por cambio de precio) |
| Cliente | (tipo_doc, n_doc) | Decisión de dominio del equipo. |
| Transportista | cuit | Decisión de dominio del equipo. |
| Empleado | cuit | Decisión de dominio del equipo. |

Nota: los UNIQUE de `(comprobante, vino)` y `(sala, vino)` **derivan de las PK textuales de la
sección 5** (el renglón duplicado queda excluido por la clave; A-05 §12). En cambio, los pares de
`Composicion`, `Renglon_Ingreso`, `Renglon_Transferencia` y `Transportista_Localidad` derivan de los
participantes (inferidos): si A-03 dejara las dudas correspondientes abiertas (ComK-a, RI-a, RT-a),
cada UNIQUE queda **marcada como pendiente de confirmación** antes de ejecutarla.

### 6.2 UNIQUE **no garantizadas textualmente** (candidatas; no se agregan sin confirmación)

- `Localidad`: `codigo_postal` y `(nombre, provincia)` — sin UNIQUE declarada.
- `Cepa.nombre`, `Maridaje.nombre` — sin UNIQUE declarada.
- `Vino.codigo` — sin UNIQUE textual (uso del API).
- `Cliente`: `(tipo_doc, n_doc)` sin UNIQUE (posible documento repetido por persona: CliK-b).
- `Distribuidor.n_habilitacion` — sin UNIQUE declarada.
- `Transportista`: `cuit` sin UNIQUE declarada (la única UNIQUE textual de CUIT es la de `Bodega`).
- `Comprobante.numero` / `(sala, numero)` — sin UNIQUE declarada (numeración global vs. por sala
  abierta: CompK-a).
- `Ingreso.codigo` (global vs. por bodega) — no garantizada (IK-a).
- `Transferencia.numero` — no garantizada (TF-a).
- `Auditoria_Precio (vino, fecha_hora)` — hipótesis técnica del trigger de RN-13; sin garantía
  textual.
- `Empleado.cuit` — sin garantía textual (la identidad por CUIT propio de la persona no está
  declarada en la consigna).

### 6.3 NOT NULL (obligatoriedad)

La obligatoriedad conceptual indicada en A-02 («Siempre») se
materializa físicamente mediante NOT NULL cuando el atributo está
definido como obligatorio en el modelo y su función en la regla de
negocio lo respalda.

Se establece el siguiente criterio:

- Todas las columnas componentes de las PK son NOT NULL.
- Las FK con participación mínima 1 respaldada por la consigna
  son NOT NULL.
- Los atributos descriptivos expresamente obligatorios en A-02
  también son NOT NULL, siempre que su obligatoriedad esté
  documentada en A-10.
- Los atributos cuyo dominio, obligatoriedad o significado
  permanecen pendientes se conservan sin NOT NULL hasta resolver
  la decisión correspondiente.

La aplicación es columna por columna: la marca NOT NULL no se
deduce automáticamente por el solo hecho de que un atributo
aparezca en una entidad.

Los atributos derivados o calculados se revisan junto con su
mecanismo de generación para asegurar que el valor esté disponible
antes de exigirlo.

### 6.4 Otras restricciones de negocio (no ejecutables con UNIQUE; etapa 2): RN-01 (`precio > 0`),
RN-05 (los porcentajes de un vino suman 100), RN-07 (`fecha_vencimiento > fecha_emision` — CHECK
entre columnas del permiso), RN-08 (subtotal/total calculados, **no cargados manualmente**),
RN-09 (stock no negativo), RN-10/11 (estados de Ingreso/Transferencia), RN-12 (bloqueo de renglones
fuera de `en_confeccion`), RN-13 (auditoría de precio), RN-15 (positividad de cantidades/superficies/
kilos/precios). Se implementarán como CHECKs/TRIGGERs según la consigna, en la etapa 2.


### 6.5 Estado de implementacion de las restricciones (etapa 2)

Estado fisico real (verificado contra el catalogo de PostgreSQL en bases de prueba):

| Regla | Mecanismo fisico | Migracion | Pruebas |
|---|---|---|---|
| RN-01 | `Vino.precio` unico (una fila por vino, sin columna de precio en stocks) + CHECK `ck_vino_precio_positivo` (`precio > 0`) | 002 | `db/tests/rn01_precio.ok.sql`, `rn01_precio_rechazos.ok.sql` |
| RN-02 | FK `fk_sala_localidad` NOT NULL + `Localidad.encargado_regional` como atributo de la localidad (una fila por localidad => encargado unico, sin contradicciones posibles) | 001 | `db/tests/rn02_sala_localidad.ok.sql`, `rn02_sala_localidad_rechazos.ok.sql` |
| RN-04 | FK `fk_parcela_cepa` (una sola cepa por parcela) + PK de `Lote` `(finca, n_parcela, campania)` (maximo una cosecha por parcela y campania; sin UNIQUE redundante) | 001 | `db/tests/rn04_cosecha_campania.ok.sql`, `rn04_cosecha_campania_rechazos.ok.sql` |
| RN-05 | Constraint trigger `trg_rn05_composicion_suma_100` DEFERRABLE INITIALLY DEFERRED sobre `Composicion` (funcion `fn_composicion_suma_100`; valida la suma por vino al COMMIT) | 003 | `db/tests/rn05_composicion_suma.ok.sql`, `rn05_vinos_independientes.ok.sql`, `rn05_suma_menor/mayor/delete_incompleto.fail.sql` |
| RN-07 | FK `fk_permiso_exportador` (varios permisos por exportador, sin UNIQUE) + CHECK `ck_permiso_fechas_orden` entre columnas | 002 | `db/tests/rn07_permisos.ok.sql`, `rn07_permisos_rechazos.ok.sql` |

RN-08 (subtotal/total calculados) permanece pendiente de A-24 (#30). La función `fn_descuento_cliente` (RN-06, A-22/#26) ya está implementada y probada. Siguen pendientes la definición del descuento del renglón (Q-05) y la decisión de almacenamiento y cálculo de importes (R-5).

---

## 7. Acciones referenciales propuestas (caso por caso, nunca automáticas)

### 7.0 Etiquetas de patrón y argumentos asociados

- **[A = Detalle de documento]**: el renglón no existe sin su cabecera. CASCADE sobre la FK del
  renglón hacia la cabecera elimina los renglones junto con la cabecera. Consecuencia: si se borra
  el comprobante/ingreso/transferencia "de prueba", sus renglones desaparecen con él (sin regla
  textual que lo respalde o lo niegue). **Confirmación** (etapa 2 / §12).
- **[B = Protección referencial / B-ish]**: el borrado del objetivo dejaría la fila origen huérfana.
  RESTRICT es la opción defendible por defecto: el efecto es que el DELETE falla. CASCADE podría
  **perder trazabilidad** (movimientos, ventas, auditorías), lo que no parece la intención del
  negocio (que pide conservar historia); NO se elige CASCADE sin regla que lo respalde.
- **[B textual (RN-14)]**: la regla textual "No se elimina una bodega si tiene vinos, ingresos u
  otros movimientos asociados" implementa directamente RESTRICT para las FK de Vino, Lote e Ingreso
  hacia Bodega (y de Ingreso/Transportista hacia Transportista). Para renglones y stocks el mismo
  sentido se mantiene, pero requiere confirmación explícita (el texto no los cita uno por uno).

### 7.1 Acciones referenciales por FK (ON DELETE / ON UPDATE)

Las acciones referenciales se adoptan considerando la integridad histórica, la dependencia estructural entre entidades y las reglas de negocio documentadas.

| # | Tabla.columna → destino | ON DELETE | ON UPDATE | Patrón | Respaldo / efecto / consecuencia / confirmación |
|---|---|---|---|---|---|
| 1 | `Sala.localidad → Localidad` | RESTRICT | RESTRICT | B-ish | No hay regla textual de borrado de localidades. CASCADE dejaría salas sin localidad. Se adopta RESTRICT para preservar la integridad. |
| 2 | `Empleado.sala → Sala` | RESTRICT | RESTRICT | B-ish/D | No hay regla textual de borrado de salas. CASCADE eliminaría empleados al borrar una sala. Se adopta RESTRICT. |
| 3 | `Cliente.localidad → Localidad` | RESTRICT | RESTRICT | B-ish | No hay regla de borrado de localidades que justifique eliminar clientes automáticamente. Se adopta RESTRICT. |
| 4 | `Parcela.finca → Finca` | RESTRICT | RESTRICT | D | Se adopta RESTRICT para impedir que se elimine una finca mientras tenga parcelas asociadas. Aunque CASCADE sería coherente con la dependencia estructural de la entidad débil, no existe una regla de negocio que autorice eliminar las parcelas automáticamente. |
| 5 | `Parcela.cepa → Cepa` | RESTRICT | NO ACTION | B-ish | Impide eliminar una cepa utilizada en parcelas. La cepa también puede estar referenciada en `Composicion`. Se adopta RESTRICT. |
| 6 | `Lote.(finca, n_parcela) → Parcela` | RESTRICT | RESTRICT | B-ish | Se preserva la trazabilidad de la cosecha. No existe una regla que justifique eliminar lotes automáticamente al borrar parcelas. |
| 7 | `Lote.bodega_destino → Bodega` | RESTRICT | RESTRICT | B textual (RN-14) | RN-14 protege las bodegas con vinos, ingresos u otros movimientos asociados. Se impide eliminar una bodega referenciada por lotes. |
| 8 | `Analisis.(finca, n_parcela, campania) → Lote` | RESTRICT | RESTRICT | B-ish | El análisis de laboratorio identifica un lote mediante su clave compuesta. Se preserva la trazabilidad y no se permite eliminar el lote si tiene análisis asociados. |
| 9 | `Vino.bodega → Bodega` | RESTRICT | RESTRICT | B textual (RN-14) | RN-14 impide eliminar bodegas con vinos o movimientos asociados. Se preserva la información histórica. |
| 10 | `Composicion.vino → Vino` | RESTRICT | NO ACTION | B-ish | Se impide eliminar un vino que tenga una composición registrada. La composición depende de la existencia del vino. |
| 11 | `Composicion.cepa → Cepa` | RESTRICT | NO ACTION | B-ish | Se impide eliminar una cepa utilizada en composiciones de vinos. |
| 12 | `Vino_Maridaje.vino → Vino` | RESTRICT | NO ACTION | B-ish | Se impide eliminar un vino que tenga maridajes asociados. |
| 13 | `Vino_Maridaje.maridaje → Maridaje` | RESTRICT | NO ACTION | B-ish | Se impide eliminar un maridaje que esté asignado a vinos. |
| 14 | `Comprobante.cliente → Cliente` | RESTRICT | RESTRICT | B-ish | Se preserva la integridad histórica de los comprobantes. La política de borrado de clientes y subtipos se define independientemente de la jerarquía adoptada en A-06. |
| 15 | `Comprobante.sala → Sala` | RESTRICT | RESTRICT | B-ish | Se preserva la información histórica de los comprobantes. CASCADE podría eliminar comprobantes al borrar una sala. |
| 16 | `Renglon_Comprobante.comprobante → Comprobante` | CASCADE | NO ACTION | A | El renglón es una extensión del comprobante y no existe independientemente de él. Se adopta CASCADE para eliminar sus renglones cuando se elimina el comprobante. |
| 17 | `Renglon_Comprobante.vino → Vino` | RESTRICT | NO ACTION | B-ish | Se preserva la trazabilidad de las ventas. No se permite eliminar un vino referenciado en renglones de comprobantes. |
| 18 | `Socio.id_cliente → Cliente` | CASCADE | RESTRICT | E | El subtipo no debe quedar sin su registro del supertipo. Se adopta CASCADE para eliminar el registro de Socio cuando se elimina su Cliente. |
| 19 | `Distribuidor.id_cliente → Cliente` | CASCADE | RESTRICT | E | El subtipo no debe quedar sin su registro del supertipo. Se adopta CASCADE para eliminar el registro de Distribuidor cuando se elimina su Cliente. |
| 20 | `Exportador.id_cliente → Cliente` | CASCADE | RESTRICT | E | El subtipo no debe quedar sin su registro del supertipo. Se adopta CASCADE para eliminar el registro de Exportador cuando se elimina su Cliente. La FK #21 protege los permisos asociados. |
| 21 | `Permiso_Exportacion.exportador → Exportador` | RESTRICT | RESTRICT | B-ish/D | Se adopta RESTRICT para preservar los permisos de exportación y evitar su eliminación automática al borrar un exportador. La existencia de permisos impide eliminar el exportador referenciado. |
| 22 | `Transportista_Localidad.transportista → Transportista` | CASCADE | RESTRICT | F/D | Se adopta CASCADE porque `Transportista_Localidad` es una tabla asociativa. Al eliminar un transportista se eliminan sus asociaciones de cobertura, no movimientos históricos. |
| 23 | `Transportista_Localidad.localidad → Localidad` | CASCADE | RESTRICT | F/D | Se adopta CASCADE porque `Transportista_Localidad` es una tabla asociativa. Al eliminar una localidad se eliminan las asociaciones de cobertura correspondientes. |
| 24 | `Ingreso.transportista → Transportista` | RESTRICT | RESTRICT | B textual (RN-14) | Se preserva la trazabilidad de los ingresos y del transportista asociado. No se permite eliminar un transportista con movimientos registrados. |
| 25 | `Ingreso.bodega_origen → Bodega` | RESTRICT | RESTRICT | B textual (RN-14) | Se preserva la trazabilidad del ingreso y de la bodega de origen. Se impide eliminar una bodega referenciada. |
| 26 | `Renglon_Ingreso.ingreso → Ingreso` | CASCADE | NO ACTION | A | El renglón no existe independientemente de su ingreso. Se adopta CASCADE para eliminar los renglones cuando se elimina el ingreso. |
| 27 | `Renglon_Ingreso.vino → Vino` | RESTRICT | NO ACTION | B-ish | Se preserva la trazabilidad de los movimientos de vino. No se permite eliminar un vino referenciado en ingresos. |
| 28 | `Transferencia.sala → Sala` | RESTRICT | RESTRICT | B-ish | Se preserva la información histórica de las transferencias. No se permite eliminar una sala referenciada por transferencias. |
| 29 | `Renglon_Transferencia.transferencia → Transferencia` | CASCADE | NO ACTION | A | El renglón depende de su transferencia. Se adopta CASCADE para eliminar los renglones cuando se elimina la transferencia. |
| 30 | `Renglon_Transferencia.vino → Vino` | RESTRICT | NO ACTION | B-ish | Se preserva la trazabilidad de las transferencias. No se permite eliminar un vino referenciado en sus renglones. |
| 31 | `Stock_Sala.sala → Sala` | RESTRICT | RESTRICT | F/D | Se adopta RESTRICT para impedir que se elimine una sala con existencias registradas. El stock debe resolverse antes de eliminar la sala. |
| 32 | `Stock_Sala.vino → Vino` | RESTRICT | NO ACTION | B-ish | No se permite eliminar un vino con existencias registradas en salas. Se evita perder información de stock automáticamente. |
| 33 | `Stock_Deposito.vino → Vino` | RESTRICT | NO ACTION | B-ish | No se permite eliminar un vino con existencias registradas en depósito. Se preserva la integridad del stock. |
| 34 | `Auditoria_Precio.vino → Vino` | RESTRICT | NO ACTION | B textual (RN-13) | La auditoría debe conservarse. Se impide eliminar un vino que tenga registros de cambios de precio para preservar la trazabilidad histórica. |

**Distribución de acciones implementadas:**

- ON DELETE: 26 RESTRICT y 8 CASCADE.
- ON UPDATE: 20 RESTRICT y 14 NO ACTION.
- No se utilizan SET NULL, SET DEFAULT ni ON UPDATE CASCADE.
- Las 34 FK están implementadas en `001_esquema.sql`.

### 7.2 ON UPDATE

- Para las **FK con clave subrogada** (`id_*`): sin ON UPDATE declarada (el identificador subrogado
  no se re-asigna).
- Para las FK que referencien `Bodega`: **ON UPDATE RESTRICT** como propuesta, independientemente
  de que finalmente se utilice `cuit` o un ID subrogado. La elección de la clave referenciada
  permanece pendiente; no hay regla que respalde propagar cambios de identificadores.
- En general, sin ON UPDATE CASCADE en todo el esquema (no existe regla de reasignación de
  identificadores); se revisa en etapa 2 si la consigna lo pide.

---

## 8. Transformación de la entidad débil Parcela (ver página 01 del A-08)

- Tabla `Parcela` con FK compuesta `finca` → `Finca` + `n_parcela` (clave parcial).
- PK compuesta `(finca, n_parcela)` [R triple cita: 3.2 + etapa 2 + UNIQUE (parcela, campaña)].
- Minimalidad: `n_parcela` solo no es clave (varias fincas numeran «1»); `finca` sola tampoco.
- La FK identificadora (Parcela.finca, componente de PK) con **ON DELETE por decidir** (RESTRICT —
  protege la finca; CASCADE — borra las parcelas, coherente con la dependencia estructural del débil,
  aunque el negocio no explicita borrado de fincas): confirmación en §12. Consecuencias de cada
  opción listadas en §7.1 #4.
- La dependencia existencial del débil (consigna 3.2) se materializa con NOT NULL de la FK
  (columna componente de la PK).
- Única otra tabla que la referencia: `Lote.(finca, n_parcela)` (FK compuesta, REL-06).

---

## 9. Transformación de las asociaciones N:M (A-05)

Cada asociación del DER con atributos propios se materializa en una **relación/tabla de asociación**
(A-05 §3) con la FK a cada participante y sus atributos:

| Asociación | Tabla | PK propuesta | Minimalidad del par | Atributos propios |
|---|---|---|---|---|
| Composición (REL-10) | `Composicion` | **`(vino, cepa)`** [I] | minimal si no se repite la cepa por vino (ComK-a abierta: si se admitiera repetición con otro análisis haría falta columna extra) | `porcentaje` (RN-05) |
| Vino–Maridaje (REL-11) | `Vino_Maridaje` | **`(vino, maridaje)`** [I] | minimal (sin repeticiones declaradas) | — |
| Renglón de comprobante (REL-14) | `Renglon_Comprobante` | **`(comprobante, vino)`** [R] | textual (sec. 5, A-05 §12) | cantidad, precio_unitario (histórico), descuento (Q-05), subtotal |
| Renglón de ingreso (REL-20) | `Renglon_Ingreso` | **`(ingreso, vino)`** [I] | análogo a 2.20 — sin texto explícito (RI-a) | cantidad |
| Renglón de transferencia (REL-22) | `Renglon_Transferencia` | **`(transferencia, vino)`** [I] | por analogía (RT-a: la consigna no explicita la regla) | cantidad |
| Transportista–Localidad (REL-17) | `Transportista_Localidad` | **`(transportista, localidad)`** [I] | minimal (par sin repeticiones; notación D-9) | — |

NINGUNA de éstas es "entidad independiente del negocio"; son tablas de asociación.

---

## 10. Transformación de la jerarquía Cliente (A-06)

La estrategia de transformación adoptada en A-06 es una jerarquía con un supertipo y tres subtipos, con **totalidad y disyunción**. Se trata de una decisión de diseño fundamentada, no de una regla expresamente establecida por la consigna.

- **`Cliente`** (supertipo): PK `id_cliente` [R] (alternativa natural `(tipo_doc, n_doc)` [P, sin garantía textual: CliK-b]); atributos comunes: `nombre` (Q-04), `tipo_doc` + `n_doc`, `direccion` (Q-10), FK a *Localidad* (REL-03), `fecha_alta` ("fecha actual" al alta en etapa 2), `descuento` persistente, sincronizado mediante `fn_descuento_cliente` (DEC-32; RN-06). U6 permanece pendiente por P-9.
- **`Socio`**: PK/FK `id_cliente` → `Cliente`; sin atributos propios.
- **`Distribuidor`**: PK/FK `id_cliente` → `Cliente`; `zona`, `n_habilitacion`.
- **`Exportador`**: PK/FK `id_cliente` → `Cliente`; `pais`; FK con la tabla `Permiso_Exportacion` (columna `exportador`, FK 21).

La decisión adoptada establece que:

- **La jerarquía es total:** todo `Cliente` pertenece a uno de los tres subtipos.
- **La jerarquía es disjunta:** cada `Cliente` pertenece a un único subtipo, sin solapamiento entre `Socio`, `Distribuidor` y `Exportador`.

La estrategia y sus fundamentos están documentados en A-06. No deben tratarse como ambigüedades pendientes de resolución en AMB-07, aunque puedan recibir observaciones posteriores durante la revisión del equipo.

**Implicancias para la implementación:**

- Las PK/FK heredadas de los subtipos establecen su correspondencia con `Cliente`, pero por sí solas no garantizan la totalidad ni la disyunción de la jerarquía.
- Será necesario evaluar mecanismos adicionales de integridad para garantizar ambas reglas en la etapa de implementación.
- Las acciones referenciales `ON DELETE CASCADE` propuestas para las FK #18–20 permitirían eliminar la fila del subtipo cuando se elimina el `Cliente`. Se mantienen como propuestas sujetas a confirmación: la decisión de totalidad y disyunción no determina por sí sola la política de borrado.
- La FK #21 (`Permiso_Exportacion.exportador → Exportador`) conserva su propia decisión pendiente entre `CASCADE` y `RESTRICT`, independiente de la resolución de AMB-07.

---

## 11. Inventario: Stock de sala y Stock de depósito (docs A-04, página 06)

- **`Stock_Sala`**: tabla por par `(sala, vino)` (PK textual de la sección 5) con `cantidad`
  (RN-09 >= 0, con P-6 abierto). FK a *Sala* (RESTRICT/pendiente confirmación) y a *Vino*
  (RESTRICT). Sin atributos adicionales (Q-13: no respaldado). Nota de interpretación: la ausencia
  de fila NO es lo mismo que cantidad 0; y el valor 0 ≠ ausencia (P-6/AMB-11: revisar con docente).
- **`Stock_Deposito`**: tabla con PK/FK `vino` adoptada (REL-24; A-12) + `cantidad`
  (RN-09 con P-6 abierto). D-3 mantiene pendiente la decisión de negocio sobre si el stock de
  depósito debe conservarse como tabla independiente o unificarse con `Stock_Sala`;
  **la PK/FK adoptada no reabre esa decisión estructural.**

- «Un solo depósito central» (sección 5): 1 fila por vino; el identificador del depósito central
  **no aparece en el modelo** (no hay entidad Depósito en A-01 §5); confirmar interpretación con el
  docente si hiciera falta.

---

## 12. Decisiones pendientes (incorporamos las de A-01…A-07, sin abrir temas nuevos)

1. **Claves primarias:** las alternativas de PK sometidas a decisión en A-12 están resueltas
   (DEC-01 a DEC-09), y la generación de los identificadores subrogados está definida en DEC-10.
   §2 y §4 reflejan las claves vigentes. No se mantienen pendientes las alternativas de
   `Localidad`, `Lote`, `Vino`, `Permiso_Exportacion`, `Comprobante`, `Ingreso`, `Transferencia`,
   `Transportista` y `Empleado`. Permanecen abiertas únicamente las condiciones de negocio
   específicas enumeradas en los puntos siguientes, sin reabrir las elecciones de PK adoptadas.
2. **Jerarquía Cliente (D-1/AMB-07):** la estrategia de supertipo `Cliente` y subtipos
   `Socio`, `Distribuidor` y `Exportador`, con totalidad y disyunción, fue adoptada como
   decisión de diseño en A-06. No queda pendiente la decisión conceptual. Sí quedan para
   la etapa de implementación los mecanismos que garanticen totalidad y disyunción, y la
   confirmación independiente de las acciones `ON DELETE` propuestas para las FK #18–20.
   La acción `ON DELETE` de la FK #21 (`Permiso_Exportacion.exportador → Exportador`)
   conserva su decisión propia entre `CASCADE` y `RESTRICT`.
3. **D-2** (asociación vs. débil para renglones/stocks): sin impacto para el esquema (la PK
   compuesta es la misma), sí para la documentación oral.
4. **D-3 / AMB-11**: `Stock_Deposito` con PK `vino` (un registro por vino) frente a la alternativa
   de la «fila ausente» (fila no existente = stock 0); y la unificación física de los stocks de
   sala/deposito (si se consolidan, se cambia la PK del stock).
5. **ComK-a / RI-a / RT-a / TK-a / PerK / VK-a**: repetición o no del par en las tablas de
   asociación/renglones; sin ellas hace falta un n.º de renglón como atributo adicional;
   ninguna decisión cerrada textualmente.
6. **ParK-a** (¿se puede reutilizar n.º de parcela tras borrado?): NO cambia la estructura (la PK es
   `(finca, n_parcela)`; se asume n.º del objeto).
7. **P-9 (U6)**: confirmar con el docente si corresponde un 35% de descuento para exportadores
   con más de 3 permisos. La alternativa de diseño para materializar el descuento fue adoptada
   en DEC-32: columna `Cliente.descuento` sincronizada mediante `fn_descuento_cliente`,
   con valores 10/20/30 según RN-06. Solo queda pendiente la regla especial del 35%.
8. **Q-03**: semántica de `fecha` en Ingreso (¿estadiaje?, ¿fecha de la bodega de destino?).
9. **Q-05**: dominio del `descuento` de `Renglon_Comprobante` (porcentaje del RN-06, o importe).
10. **Q-06/D-6**: identidad del análisis (id [R]) y la AK extendida `(finca, n_parcela, campania, fecha)` [P: sin garantía; resolució.known? ]
11. **Q-07**: qué usuario se audita bajo `usuario` (BD vs. negocio).
12. **Q-08–Q-13**: dominios menores (CHECKs en etapa 2; sin impacto en el esquema).
13. **P-6** (>0 vs. >=0 en stocks/cantidades): CHECKs etapa 2.
14. **P-8**: catálogo de volúmenes de vino (CHECK etapa 2).
15. **Almacenamiento de subtotal/descuento/total** (R-5; RN-08): guardados vs. calculados — decisión
    con justificación por escrito exigida por la sección 5; en esta propuesta los atributos están
    presentes por A-02, el criterio físico queda abierto.
16. **ON DELETE decidibles pendientes en FK #4, #21, #22, #23 y #31** (alternativas RESTRICT/CASCADE
    detalladas en §7.1); ninguna exigida por regla textual (confirmación con equipo/docente).
17. **ON UPDATE**: sin CASCADE (no hay regla que pida cambiar identificadores); confirmación en etapa 2.

---

## 13. Matriz de trazabilidad: elemento del DER (A-08) → tabla (A-09)

| Entidad / relación del DER (página) | Tabla(s) resultantes | FK(s) asociadas (ID §7.1) | Observación |
|---|---|---|---|
| Localidad | `Localidad` | — (objetivo de FKs 1, 3, 23) | PK subrogada `id_localidad` adoptada (DEC-01/DEC-10) |
| Sala | `Sala` | — (objetivo de FKs 2, 15, 28, 31) | PK subrogada `id_sala` [R] |
| Empleado | `Empleado` | 2 | PK subrogada `id_empleado` adoptada (DEC-09/DEC-10); CUIT sin UNIQUE |
| Finca | `Finca` | — (objetivo de FK 4) | PK `id_finca` [R] |
| Parcela (débil) | `Parcela` | 4, 5 (+6 desde Lote) | PK compuesta `(finca, n_parcela)` [R] |
| Cepa | `Cepa` | — (objetivo de FKs 5, 11) | PK `id` [R]; nombre AK [P] |
| Lote | `Lote` | objetivo de FK 8 (compuesta: `finca`, `n_parcela`, `campania`) | PK compuesta adoptada: `(finca, n_parcela, campania)` (DEC-02); `n_lote` descriptivo, sin UNIQUE |
| Analisis | `Analisis` | objetivo de ninguna | PK `id_analisis` [R]; identidad y AK adicional por lote/fecha pendientes de revisión (D-6/AMB-13) |
| Bodega | `Bodega` | — (objetivo de FKs 7, 9, 25) | PK `cuit` [R]; UNIQUE textual de CUIT respaldado |
| Vino | `Vino` | — (objetivo de FKs 10–13, 17, 27, 30, 32–34) | PK `codigo` adoptada (DEC-03); UNIQUE adicional `(nombre, anada, volumen_ml)` |
| Composición (asociativa) | `Composicion` | 10, 11 | PK `(vino, cepa)` [I]; repetición del par pendiente (ComK-a) |
| Maridaje | `Maridaje` | — (objetivo de FK 13) | PK `id` [R]; AK nombre [P] |
| Vino–Maridaje (asociativa) | `Vino_Maridaje` | 12, 13 | PK `(vino, maridaje)` [I]; D-9 pendiente |
| Cliente (supertipo) | `Cliente` | — (objetivo de FKs 14, 18–20) | PK subrogada `id_cliente` adoptada (DEC-10); jerarquía según DEC-11/DEC-12 |
| Socio / Distribuidor / Exportador (subtipos) | `Socio`, `Distribuidor`, `Exportador` | 18, 19, 20 | PK/FK heredada de `Cliente`; mapeo adoptado (DEC-13) |
| Permiso de exportación | `Permiso_Exportacion` | 21 | PK `codigo` adoptada (DEC-04) |
| Comprobante | `Comprobante` | origina FKs 14 (cliente), 15 (sala); objetivo de FK 16 | PK `numero` global adoptada (DEC-05) |
| Renglón de comprobante (asociativa) | `Renglon_Comprobante` | 16, 17 | PK `(comprobante, vino)` [R] textual sec. 5 |
| Transportista | `Transportista` | — (objetivo de FKs 22, 24) | PK `codigo` adoptada (DEC-08); CUIT sin UNIQUE |
| Transportista–Localidad (asociativa) | `Transportista_Localidad` | 22, 23 | PK `(transportista, localidad)` [I]; D-9 pendiente |
| Ingreso | `Ingreso` | origina FKs 24 (transportista), 25 (bodega_origen); objetivo de FK 26 | PK `codigo` global adoptada (DEC-06) |
| Renglón de ingreso (asociativa) | `Renglon_Ingreso` | 26, 27 | PK `(ingreso, vino)` [I]; repetición del par pendiente (RI-a) |
| Transferencia | `Transferencia` | origina FK 28 (sala); objetivo de FK 29 | PK `numero` global adoptada (DEC-07) |
| Renglón de transferencia (asociativa) | `Renglon_Transferencia` | 29, 30 | PK `(transferencia, vino)` [I]; repetición del par pendiente (RT-a) |
| Stock de sala | `Stock_Sala` | 31, 32 | PK `(sala, vino)` [R] sec. 5 |
| Stock de depósito | `Stock_Deposito` | 33 | PK/FK `vino` adoptada; regla de negocio D-3/AMB-11 pendiente |
| Auditoría de precio | `Auditoria_Precio` | 34 | PK `id_auditoria` [R] RN-13 |

---

## 14. Auditoría cruzada A-08 ↔ A-09 (resultados)

| Punto del control de consistencia | Resultado |
|---|---|
| Todas las entidades fuertes del DER tienen su relación correspondiente | OK — 16 tablas de entidades fuertes (§2) trazadas en §13. |
| La entidad débil está correctamente traducida | OK — FK compuesta y clave parcial (§8). |
| Cada asociación N:M con atributos está materializada como tabla | OK — §9 (`Composicion`, `Vino_Maridaje`, `Renglon_Ingreso`, `Renglon_Comprobante`, `Renglon_Transferencia` y `Transportista_Localidad`). |
| Cada relación 1:N se transforma en FK en el lado correspondiente | OK — §5 documenta las 34 FKs y su ubicación. |
| No se pierden atributos de asociaciones o entidades | OK — §9 lista los atributos propios de cada asociación. |
| No se incorporan dependencias funcionales o restricciones sin justificación | OK — §6.2 identifica las UNIQUE no garantizadas y §7 documenta las confirmaciones pendientes. |
| Las claves primarias adoptadas están reflejadas en el esquema | OK — §2, §4 y §13 reflejan las decisiones vigentes de A-12; las condiciones de negocio aún abiertas se mantienen en §12. |
| Las claves foráneas referencian las PK correspondientes | OK — §5.1 documenta los destinos de las FKs; las acciones referenciales pendientes se conservan separadamente. |
| Las decisiones pendientes de A-01…A-07 se mantienen identificadas sin abrir temas nuevos | OK — §12 conserva las cuestiones pendientes de diseño. |

(Ningún punto quedó fuera del trazado; el modelo relacional resultante es coherente con el DER
revisado en A-08 y hereda sus ambigüedades abiertas.)

---

## 15. Limitaciones declaradas

1. **Toda la propuesta es preliminar** y depende de la revisión/aprobación de A-08; si A-08 cambia,
   el esquema deberá re-validarse (cambios en entidad/jerarquía/relaciones se propagarian).
2. No hay SQL DDL ni tipos de datos SQL: corresponden a la **etapa 2** (CHECKs, triggers y
   definiciones físicas); las acciones referenciales de §7 son propuestas, no definiciones.
3. Las PK adoptadas en A-12 se reflejan en este esquema y no se consideran pendientes de aprobación
   nuevamente. Las restricciones UNIQUE y NOT NULL que carecen de respaldo suficiente, las
   condiciones de negocio abiertas y las acciones ON DELETE pendientes se conservan identificadas
   en las secciones correspondientes, sujetas a revisión del equipo/docente.
4. El PDF original no es legible en este entorno: todo respaldo textual viene de `docs/requisitos.md`
   y de los documentos A-01…A-07 y A-08, que han registrado esta misma limitación.

---

### Registro de cambios de este documento

- Creación (A-09, preliminar): 29 tablas (16 fuertes + 1 débil + 6 asociativas + 2 stock + 3 subtipos +
  1 auditoría); atributos por tabla (A-02); PK compuestas con minimalidad de cada una (§4); PK de
  `Lote` resuelta (DEC-02: `(finca, n_parcela, campania)`; FK #8 de `Analisis` convertida en compuesta);
  34 FKs
  (§5) con acciones referenciales caso por caso (§7); transformación de la entidad débil Parcela (§8);
  jerarquía A-06 con Cliente total y disjunta (§10); stocks/inventarios (§11); matriz de
  trazabilidad DER↔esquema (§13); auditoría cruzada (§14); PK adoptadas según A-12; sin SQL y
  con condiciones de negocio y acciones referenciales pendientes identificadas; se requiere
  aprobación de A-08.

- Implementacion etapa 2 (A-17/A-18/A-20/A-21/A-23): contexto y estado fisico en la nueva s 6.5;
  mecanismos verificados en bases de prueba con 13 casos (OK y rechazos esperados) via
  db/tests/run_tests.ps1 (migraciones 001, 002 y 003). Ningun cambio de esquema ni de
  acciones referenciales: las decisiones de s 7.1 siguen vigentes y coinciden con el DDL.

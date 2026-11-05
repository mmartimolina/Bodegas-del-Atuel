# A-03 — Claves candidatas por entidad

> Issue A-03 · Responsable: Persona A · Estado: **borrador conceptual revisado (no decidido)**
> Fuente: `docs/Consigna/TPI_Bodegas_del_Atuel.pdf` (secciones 3, 4, 5 y 7),
> `docs/requisitos.md` y `docs/modelo/01_entidades_candidatas.md` (A-01) / `02_atributos_entidades.md` (A-02).
>
> Convención de marcado:
> - **Explícito** = el dato o la combinación figura en el PDF (se cita la sección). Aun así es un
>   **requisito/referencia de la consigna**, no una decisión de diseño aprobada del equipo: la
>   sección 5 aclara que lo listado es «una guía» y que la elección de clave primaria es una de las
>   «decisiones de diseño que deben tomar y justificar».
> - `[Inferencia]` = propuesto por nosotros con justificación; NO es requisito textual.
>
> Categorías de cada propuesta (se indican en cada tabla):
> - **Candidata respaldada:** cumple unicidad y minimalidad con fundamento suficiente en la consigna
>   (texto o UNIQUE de etapa 2) o en una regla de negocio documentada.
> - **Candidata inferida:** unicidad y minimalidad se justifican mediante una inferencia explícita
>   (dominio, analogía, diseño estándar de asociación N:M), pero no están declaradas textualmente.
> - **Identificador posible pendiente de validación:** todavía no se puede garantizar la unicidad
>   o la minimalidad; se lista como hipótesis, nunca como candidata confirmada.
>
> Nota sobre los atributos «ID» explícitos: la sección 5 los lista como datos. Que la consigna los
> denomine «ID» respalda su **unicidad semántica** como identificador de fila; no implica que el
> equipo haya elegido la PK ni que el ID deba ser autogenerado. La forma concreta y la elección de
> PK se deciden en A-04. Las dudas particulares de cada entidad (p. ej. la identidad de Análisis de
> calidad) se conservan.
>
> Nota central de esta revisión: **no se confunde la existencia de un atributo identificador en la
> consigna con la garantía efectiva de unicidad**. Salvo el caso de un atributo denominado «ID» —cuyo
> significado sí es identificar la fila—, que el PDF liste «código», «número», «CUIT» o «nombre» no
> equivale a que declare una restricción UNIQUE. Tampoco se inventan restricciones que el PDF no
> contiene.
>
> Reglas respetadas en este documento:
> 1. Una clave candidata debe cumplir **unicidad** y **minimalidad** (si al quitar un atributo sigue
>    siendo única, no es minimal).
> 2. No se asume unicidad por «parecer identificador»: cada unicidad se justifica por regla de
>    negocio, cita de la consigna o argumento explícito.
> 3. **No se elige la clave primaria** ni se distingue entre PK y candidatas alternativas: se listan
>    todas las candidatas que cumplen unicidad + minimalidad.
> 4. **No se definen claves foráneas.** Los «participantes» (finca, vino, sala…) aparecen solo como
>    componentes de claves compuestas potenciales, en la medida en que la identidad de la fila los
>    requiera; no es todavía una decisión de FK.
> 5. No se escribe SQL ni se modifica A-01/A-02.
> 6. Las dudas D-1…D-10 de A-01 y Q-01…Q-13 de A-02 **siguen abiertas**; cuando una clave depende de
>    una de ellas, se marca.
> 7. Cuando no hay información suficiente para proponer clave, se lo indica expresamente.

---

## 1. Objetivo y alcance

Identificar y justificar las **claves candidatas** (unicidad + minimalidad) de las 29 entidades
candidatas de A-01, en el mismo orden. Para cada una se documenta:

1. Nombre de la entidad.
2. Clave o claves candidatas posibles.
3. Atributos que componen cada clave.
4. Categoría de la propuesta (respaldada, inferida o pendiente).
5. Justificación basada en reglas de negocio y consigna.
6. Dudas, supuestos y alternativas pendientes.

La sección 5 del PDF pide justificar explícitamente «la elección de criterios entre **CUIT y código
postal frente a identificadores autogenerados**»: este documento prepara esos casos pero **no cierra
la elección** (queda para el diseño del esquema; ver §4).

---

## 2. Claves candidatas por entidad

### 2.1 Localidad

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| LK-1 | codigo_postal | Identificador posible pendiente de validación | La sección 5 lista «código postal» como dato de Localidad y menciona «código postal frente a identificadores autogenerados» como criterio a justificar. Eso respalda la **existencia** del atributo identificador, no la unicidad efectiva: el PDF no declara UNIQUE ni una regla de negocio que impida que un código postal cubra varias localidades. |
| LK-2 | nombre + provincia | Identificador posible pendiente de validación | Dos localidades del mismo nombre raramente coexisten en una provincia; con la provincia acompañante la combinación es plausible. Es solo plausibilidad: no hay regla de negocio ni texto que la respalden, por lo que **no se la declara candidata confirmada**. |

**Minimalidad:** LK-1 es minimal si un código postal no se repite entre localidades/provincias
(hipótesis plausible para Argentina, no confirmada por el PDF). LK-2 podría violar unicidad si
existieran localidades homónimas con límite provincial ambiguo; no hay regla del negocio que
garantice su unicidad, solo plausibilidad: **se clasifica como identificador posible pendiente de
validación**, no como candidata confirmada.

**Respaldos y dudas:**
- La sección 5 (fila Localidad) lista «Código postal, nombre, provincia, encargado regional» sin
  marcar la PK; y en «decisiones de diseño» solo menciona el código postal como frente al ID
  autogenerado (**referencia de la consigna, no decisión aprobada**).
- Duda LK-a: ¿el código postal es único por localidad o puede cubrir varias localidades pequeñas?
  El PDF no lo dice. **Pendiente de validación**; si no es seguro, en A-04 se evaluará código postal
  natural + ID subrogado.
- Duda LK-b: ¿el nombre de localidad es único dentro de la provincia? Sin respaldo textual.

---

### 2.2 Sala de venta

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| SK-1 | id_sala | Candidata respaldada (ID explícito: unicidad semántica) | La sección 5 lista «ID» entre los datos de la sala. Que la consigna lo denomine «ID» respalda la **unicidad semántica** del identificador de fila; no implica que sea la PK elegida ni que deba ser autogenerado. La forma concreta y la elección de PK se deciden en A-04. |

**Minimalidad:** trivial (atributo único).

**Respaldos y dudas:**
- Es la entidad cuya candidata es más directa, pero la sección 5 no explicita si «ID» es un número
  autogenerado, un código de sala, etc. Duda SK-a: ¿el ID de sala es asignado por el negocio o
  autogenerado? Sin respaldo. `[Inferencia]` autogenerado o secuencial.
- `[Inferencia]` ¿es candidata (localidad, calle, numero)? No necesariamente: dos salas podrían
  compartir la misma calle y altura (distinta planta o misma dirección comercial). Sin una regla que
  garantice unicidad de domicilio, **no se propone esta combinación como candidata** (regla: no
  asumir unicidad por coordenadas aparentes).
- Duda SK-b (depende de Q-09 de A-02): el día de cierre no es clave (múltiples salas cierran el mismo
  día); se menciona solo para descartarlo explícitamente.

---

### 2.3 Empleado

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| EK-1 | cuit | Candidata inferida (unicidad fiscal condicionada, no textual) | La sección 5 lista «CUIT» como dato del empleado y lo menciona entre los criterios a justificar frente al ID autogenerado. La **existencia** del dato está respaldada; su unicidad como identificador de empleado se infiere solo si el empleado es una persona física identificada fiscalmente con ese CUIT. El PDF no declara que todo empleado tenga CUIT propio ni que sea persona física, y no establece un UNIQUE para el CUIT de empleado (a diferencia del CUIT de bodega, ver 2.9). |

**Minimalidad:** si se acepta la condición anterior, la clave sería minimal (un atributo). La inferencia
no convierte el CUIT en UNIQUE textual ni obliga a que sea la PK; la duda EK-a se conserva.

**Respaldos y dudas:**
- La unicidad del CUIT de **bodega** está explícita en la etapa 2 (ver 2.9). La del CUIT del
  **empleado** no lo está: es `[Inferencia]` condicionada a que el empleado sea una persona física
  identificada fiscalmente con ese CUIT, no un texto que diga «único». **No se afirma que todo
  empleado tenga un CUIT propio.** **Se marca la diferencia** para no sobre-interpretar.
- Duda EK-a: ¿la empresa contrata personal ajeno (con CUIT de agregado, no el de la persona
  natural)? No hay respaldo textual. Si así fuera, el CUIT no identificaría unívocamente al empleado;
  **no se propusieron otras claves** ante la ausencia de atributos naturales alternativos (nombre no
  es único).
- Alternativa pendiente: un ID subrogado de empleado además del CUIT (`[Inferencia]`), para
  decidir en A-04 con el mismo criterio de la sección 5.

---

### 2.4 Finca

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| FiK-1 | id_finca | Candidata respaldada (ID explícito: unicidad semántica) | La sección 5 lista «ID» para la finca: la consigna respalda la **unicidad semántica** del identificador de fila. No implica elección de PK ni obligación de autogeneración; la forma concreta se decide en A-04. |

**Minimalidad:** trivial.

**Respaldos y dudas:**
- `[Inferencia]` ¿es candidata (nombre, departamento)? No hay garantía: dos fincas del mismo
  departamento podrían llamarse igual (la consigna no lo prohíbe). Sin regla de unicidad textual,
  **no se propone**.
- Duda FiK-a: la sección 5 indica «ID» sin precisar numeración; el Anexo B no carga fincas, así que
  no hay ejemplo de valor. Sin más respaldo, se mantiene id_finca como identificador de fila con
  unicidad semántica y se deja abierto el criterio natural vs. autogenerado (referencia genérica de
  la sección 5).

---

### 2.5 Parcela (entidad débil declarada)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| ParK-1 (compuesta) | finca + n_parcela | Candidata respaldada (cita de la consigna, no decisión aprobada) | 3.2: las parcelas «se identifican por un número **dentro de la finca**» (una parcela no existe sin su finca); la sección 5 dice «Entidad débil: clave (finca, n.° de parcela)»; la etapa 1 exige dibujar «la entidad débil Parcela». Es el caso de identificación débil clásica: el número es relativo a la finca y no es único global. |

**Minimalidad:** n_parcela solo no es clave (múltiples fincas pueden numerar «1»); finca solo no
identifica la parcela. La combinación es minimal si dentro de una finca el número no se repite: es
justamente lo que significa «identifica por número dentro de la finca», textual en 3.2.

**Respaldos y dudas:**
- **Esta es la candidata más respaldada del modelo**: aparece tres veces (3.2, sección 5 y etapa 1,
  paso 2). Aun así, se la registra como **candidata**, no como primaria ya aprobada: qué valor
  físico tendrá el componente «finca» (id_finca o id subrogado) es una decisión posterior.
- No hay alternativa plausible: una clave propia de parcela (id) desmentiría la debilidad textual.
  No se propone.
- Duda ParK-a: ¿el número de parcela se reutiliza cuando se replanta (restauración de número con
  nueva plantación)? El PDF no lo dice; sin respaldo, se asume que el número es del objeto parcela y
  no se reutiliza. Sin efecto sobre la clave.

---

### 2.6 Cepa (catálogo)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| CeK-1 | id | Candidata respaldada (ID explícito: unicidad semántica) | La sección 5 lista «ID»: la consigna respalda la **unicidad semántica** del identificador de fila. No implica elección de PK ni obligación de autogeneración; la forma concreta se decide en A-04. |
| CeK-2 | nombre | Identificador posible pendiente de validación | Es altamente plausible que dos variedades de vid no compartan el mismo nombre (el catálogo de 12 cepas del Anexo B no tiene dos iguales). El PDF, no obstante, **no declara** la unicidad del nombre: sin esa regla, no se la presenta como candidata confirmada. |

**Minimalidad:** CeK-1 es trivial por tratarse de un ID explícito. CeK-2 sería minimal **si se
confirma la unicidad del nombre**; mientras siga pendiente, no se la declara candidata confirmada.

**Respaldos y dudas:**
- CeK-2 es una **candidata no garantizada**: se propone solo como identificador posible (por el uso
  natural del nombre de variedad como dato distintivo), **con la advertencia explícita** de que el
  PDF no la respalda con una regla de unicidad. Si el grupo elige CeK-2 como PK, la justificación
  debe apoyarse en el dominio, no en la consigna.
- No hay una duda D de A-01 asociada específicamente a Cepa. La unicidad del nombre queda pendiente
  de validación; no se la vincula a D-5 (esa duda trata la campaña como catálogo, no el nombre de
  cepa).

---

### 2.7 Lote de uva

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| LoteK-1 | n_lote | Identificador posible pendiente de validación | La sección 5 lista «N.° de lote». Un número de lote es por naturaleza identificador de un suceso, pero el PDF no declara su alcance (global o relativo a parcela/campaña). Mientras esa unicidad global no se confirme, se lo trata como identificador posible, no como candidata confirmada. |
| LoteK-2 (compuesta) | parcela + campania | Identificador posible pendiente de validación (unicidad textual; minimalidad no demostrada) | RN-04: una parcela se cosecha «como máximo una vez por campaña», y la etapa 2 ejemplifica `UNIQUE (parcela, campaña)`. La restricción garantiza la **unicidad de la combinación**. No garantiza por sí sola la **minimalidad**: que ninguno de los atributos por separado sea único es una inferencia del dominio, no un texto de la consigna. |

**Minimalidad de LoteK-1:** sería minimal (un atributo) **si se confirma la unicidad global de
`n_lote`**; hoy su alcance sigue pendiente.

**Minimalidad de LoteK-2:** el UNIQUE de etapa 2 declara la combinación completa. Para afirmar que es
minimal hay que probar que ningún subconjunto propio es único:
- `parcela` sola: parecería no ser única porque una parcela puede cosecharse en varias campañas, pero
  el PDF no dice cuántas veces se cosecha una parcela en su vida; es inferencia.
- `campania` sola: parecería no ser única porque en una campaña se cosechan varias parcelas, pero el
  PDF no lo declara; también es inferencia.
- La lectura natural del negocio (una parcela tiene lotes de varias campañas y una campaña agrupa
  lotes de varias parcelas) es plausible y está alineada con los volúmenes de la etapa 3, pero no es
  una regla textual.
- Conclusión: **LoteK-2 queda como candidata pendiente de confirmación de minimalidad**, no como
  candidata plenamente respaldada.

**Respaldos y dudas:**
- En este caso **coexisten dos candidatas** con naturaleza distinta: una «etiqueta» del suceso
  (n.° de lote) y una «identidad por regla de negocio» (parcela, campaña). La sección 5 y RN-04
  respaldan la existencia de ambas. Qué una se elija como PK (y entonces la otra UNIQUE, o
  viceversa) es la decisión de diseño que la sección 5 pide justificar.
- Duda LoteK-a (Q-02 de A-02 continúa abierta): ¿el n.° de lote es único global o relativo a la
  parcela/campaña? Si fuera relativo, **LoteK-1 dejaría de ser candidata a nivel global** y la
  clave pasaría a ser (parcela, campania, n_lote), poco probable; sin respaldo textual el PDF sugiere
  la lectura global («N.° de lote» como dato propio). **Pendiente de validación.**
- Supuesto LoteK-b: para LoteK-2, el único lote por (parcela, campaña) excluye cosechas parciales
  separadas en el mismo año. RN-04 así lo garantiza; si la cátedra pensara en más de una cosecha
  por campaña (uvas de fechas distintas), habría que agregar un dato. Sin respaldo, no se agrega.

---

### 2.8 Análisis de calidad

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| AK-1 | id_analisis | Candidata respaldada (ID explícito: unicidad semántica; identidad de fila dudosa) | La sección 5 asigna un «ID»: que la consigna lo denomine así respalda la **unicidad semántica** del identificador de fila. No implica que el ID resuelva por sí solo la duda sobre la identidad del análisis (D-6 de A-01 / Q-06 de A-02 siguen abiertas) ni que sea la PK elegida; la forma concreta se decide en A-04. |
| AK-2 (compuesta) | lote + fecha | Identificador posible pendiente de validación | Hipótesis: si el negocio registra como máximo un análisis por lote por día, (lote, fecha) identificaría la fila. La consigna **no lo dice**: podría haber dos análisis del mismo lote en el mismo día (p. ej. duplicado o re-muestra). Sin la regla, AK-2 **no cumple unicidad garantizada** y se lista solo como hipótesis a validar. |

**Minimalidad:** AK-1 trivial. AK-2 sería minimal si se confirmara la unicidad (lote solo no distingue
los análisis del lote; fecha sola no distingue análisis de lotes distintos); esa minimalidad también
queda condicionada a la validación de la unicidad.

**Respaldos y dudas:**
- Duda AK-a (Q-06 de A-02 / D-6 de A-01 citada): la identidad de la fila es la **duda específica de
  esta entidad**; no se cierra. **Si no hay confirmación de unicidad por (lote, fecha), AK-2 no es
  candidata válida** y la única segura sería el ID (con su propia duda).
- Esa entidad queda en la lista de «requieren decisión» (ver §4). No hay otro atributo natural
  identificable (brix/ph/acidez no son únicos ni identificativos: dos análisis distintos podrían dar
  valores iguales).

---

### 2.9 Bodega

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| BK-1 | cuit | Candidata respaldada (UNIQUE explícito de la etapa 2; PK no declarada) | La etapa 2 (sección 7) ejemplifica «CUIT de bodega» como ítem de UNIQUE. La unicidad del CUIT de bodega tiene **respaldo explícito de la consigna** como requisito de integridad. CUIT es también un identificador natural mencionado en «decisiones de diseño» de la sección 5. |
| BK-2 | razon_social | Descartada (sin unicidad) | Dos bodegas podrían tener la misma razón social con CUIT distinto (sociedades homónimas existen); el PDF no dice que la razón social sea única. **No cumple unicidad garantizada; no es candidata.** |

**Minimalidad:** BK-1 trivial.

**Respaldos y dudas:**
- Importante: la etapa 2 lista el UNIQUE sobre CUIT de bodega como **restricción de integridad**;
  eso respalda BK-1 como **candidata**, pero **no implica** que el CUIT sea la PK ni que no se use
  un ID subrogado en su lugar (nota de A-02 2.9). La elección es de las «decisiones de diseño» de la
  sección 5. **Registro como candidata, no como denominación de PK.**
- No hay «ID» atribuido a bodega en la sección 5 (a diferencia de sala, finca, cepa, etc.), por lo
  que no se propone ID subrogado como candidata textual: solo con criterio de diseño en A-04.

---

### 2.10 Vino

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| VK-1 | codigo | Candidata inferida (código de producto + uso en API) | La sección 5 lista «código» del vino; un código de producto es por naturaleza identificador y el endpoint `GET /vinos/{cod}` lo usa para direccionar un vino individual. La existencia del dato está respaldada y la unicidad se infiere de su función y del uso en la API, pero **no hay UNIQUE textual sobre `codigo`**. Queda como inferencia con fundamento, no como restricción confirmada. |
| VK-2 (compuesta) | nombre + anada + volumen_ml | Identificador posible pendiente de validación (unicidad textual; minimalidad no demostrada formalmente) | La etapa 2 ejemplifica «UNIQUE (nombre, añada, volumen) en vino» y 3.3 pide distinguir vinos «con el mismo nombre y distinta añada o presentación». Eso respalda la combinación como **requisito explícito de unicidad**, valor que se mantiene. No demuestra por sí mismo que la combinación sea minimal: ver el análisis de subconjuntos. |

**Minimalidad de VK-1:** sería minimal (un atributo) **si se confirma la unicidad inferida del
`codigo`**; hoy no hay UNIQUE textual.

**Minimalidad de VK-2:** el UNIQUE de etapa 2 declara la unicidad de la combinación completa, mas no
demuestra formalmente que ningún subconjunto propio sea único. Análisis de subconjuntos:
- `nombre` solo: **no es único**, y esto tiene apoyo textual en 3.3, que admite vinos con el mismo
  nombre y distinta añada o presentación.
- `anada` sola: no es única (muchos vinos comparten año); inferencia clara del dominio, sin texto.
- `volumen_ml` solo: no es único (muchos vinos comparten presentación); inferencia clara, sin texto.
- `nombre + anada`: podría repetirse si el mismo vino-añada existe en dos volúmenes; 3.3 menciona
  «distinta… presentación», lo que da apoyo textual parcial, pero no declara que esos pares existan
  necesariamente.
- `nombre + volumen_ml`: podría repetirse si el mismo nombre-presentación existe en dos añadas; 3.3
  menciona «distinta añada», apoyo textual parcial.
- `anada + volumen_ml`: agrupa muchos vinos distintos; inferencia clara, sin texto.
- Conclusión: la minimalidad es **plausible y parcialmente apoyada por 3.3**, pero no está
  demostrada formalmente como regla de negocio. Se mantiene la combinación como requisito explícito
  de unicidad, pero **no se declara su minimalidad demostrada**; se la clasifica como pendiente de
  confirmación (p. ej. ante el docente).

**Respaldos y dudas:**
- Ambas candidatas coexisten de forma análoga a LoteK-1/LoteK-2: un «código de producto» y una
  «identidad de producto» (versión). La elección de cuál es PK (y cuál UNIQUE) es de las decisiones
  de diseño de la sección 5; **no se decide aquí**.
- Duda VK-a (P-8 de `requisitos.md` §10.1.7, citada en A-01 §6.2): si el catálogo de volúmenes fuera
  abierto o cerrado no cambia la clave, sí cambia el CHECK. No afecta a VK-2.
- `[Inferencia]` descartadas: (tipo, anada) no es única (varios vinos tipo tinto de la misma añada);
  (nombre) sola tampoco (3.3 lo dice explícitamente).

---

### 2.11 Composición (vino–cepa)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| ComK-1 (compuesta) | vino + cepa | Candidata inferida (asociación N:M) | La relación es N:M entre Vino y Cepa con atributo «porcentaje» (sección 5: «N:M con atributo; suma 100»). Para una asociación entre dos entidades sin datos adicionales, la fila se identifica por el par de participantes: no se afirma «dos porcentajes distintos para la misma cepa en el mismo vino». Sin regla que permita repetir el par, la combinación es única por la naturaleza del vínculo. Es una **inferencia de diseño** (estándar de tabla N:M con atributo), no una frase de la consigna. |

**Minimalidad:** vino solo no identifica la fila (un vino tiene varias cepas); cepa solo tampoco.
El par es minimal.

**Respaldos y dudas:**
- `[Inferencia]`: a diferencia de Parcela, Stock de sala y Renglón de comprobante, el PDF **no fija
  textualmente** la clave de esta asociativa. La propuesta del par (vino, cepa) es el diseño estándar
  de una tabla N:M con atributo, pero no hay frase «clave (vino, cepa)» en la consigna. **Se registra
  como inferencia a validar.**
- Duda ComK-a: ¿puede haber dos filas para la misma cepa en el mismo vino (p. ej. misma cepa de
  dos lotes distintos)? El PDF no lo considera. `[Supuesto]` no. Si el docente confirma lo
  contrario, habría que agregar un atributo o desdoblar; sin respaldo, no.

---

### 2.12 Maridaje (catálogo)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| MK-1 | id | Candidata respaldada (ID explícito: unicidad semántica) | La sección 5 lista «ID» del maridaje: la consigna respalda la **unicidad semántica** del identificador de fila. No implica elección de PK ni obligación de autogeneración; la forma concreta se decide en A-04. |
| MK-2 | nombre | Identificador posible pendiente de validación | Plausible que la recomendación «carnes rojas» no se duplique en el catálogo (I2 crea «cordero al disco» sin duplicados). El PDF, no obstante, no explicita unicidad del nombre: se lista como hipótesis a validar. |

**Minimalidad:** MK-1 es trivial por ID explícito. MK-2 sería minimal **si se confirma la unicidad
del nombre**; mientras siga pendiente, no se la declara candidata confirmada.

**Respaldos y dudas:**
- Igual que en Cepa: MK-2 es plausible pero no garantizada textualmente.
  `[Pregunta]` qué hacer con maridajes homónimos con distinta temperatura (¿misma recomendación con
  dos temperaturas?). Sin respaldo, se asume que no se permiten duplicados; no es regla textual.
- Duda MK-a: el catálogo se carga por CSV (Anexo B), lo que refuerza la hipótesis de filtro de
  nombre (no se importan repetidos), pero no la garantiza.

---

### 2.13 Vino–maridaje

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| VMK-1 (compuesta) | vino + maridaje | Candidata inferida (asociación N:M) | N:M sin atributos según la consigna (sección 5 «Vino-maridaje… N:M»; «un maridaje puede repetirse para distintos vinos»); la fila se identifica por el par de participantes: un (vino, maridaje) no debería repetirse como fila de asociación. Es la inferencia estándar de una asociación N:M sin atributos: el PDF **no la enumera como clave textual**. |

**Minimalidad:** el par es minimal (cada extremo tiene muchas filas del otro).

**Respaldos y dudas:**
- Sin atributos propios, la identidad de la asociación es necesariamente el par de participantes:
  `[Inferencia]` estándar. El PDF no la enumera como «clave (vino, maridaje)»: inferencia.
- Si se dibujara en el DER como mero relacionamiento (sin tabla estructura), la clave se materializa
  al pasar a relacional: depende de D-9 de A-01 (sigue abierta), aunque no cambia el contenido de la
  clave.

---

### 2.14 Cliente

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| CliK-1 | id_cliente | Candidata respaldada (ID explícito: unicidad semántica) | La sección 5 lista «ID» del cliente: la consigna respalda la **unicidad semántica** del identificador de fila; no implica elección de PK ni obligación de autogeneración. La sección «decisiones de diseño» menciona «CUIT y código postal frente a identificadores autogenerados»: el caso del cliente es exactamente el escenario de elegibilidad entre datos naturales y un ID, que se resuelve en A-04. |
| CliK-2 (compuesta) | tipo_doc + n_doc | Identificador posible pendiente de validación | El par (tipo, número de documento) identifica a una persona/empresa en el registro civil/fiscal en el dominio argentino (p. ej. DNI/CUIT). Es plausible y de uso común; sin embargo, **el PDF no dice que el documento sea único**: solo lo lista como dato. Además, una misma persona podría tener DNI y CUIT. No se lo declara candidata confirmada: hipótesis dominial a validar (ver CliK-b). |

**Minimalidad:** CliK-1 trivial. CliK-2: tipo y número de documento se necesitan juntos (el número de
documento por sí, sin el tipo, puede coincidir entre DNI y CUIT); ambos atributos son necesarios.
**Si se confirma la unicidad del documento**, el par sería minimal; hoy esa unicidad está pendiente.

**Respaldos y dudas:**
- Duda CliK-a (D-1 de A-01; relacionada con Q-04 de A-02): la estrategia de mapeo de la jerarquía no
  cambia las claves candidatas, sí cambia **a qué tabla** llegan los atributos del subtipo. Q-04
  (nombre en uno o dos campos) depende de esa misma decisión. Si se elige «una tabla por subtipo»
  (D-1 opción b), las claves del cliente tendrían que resolverse en cada tabla de subtipo (lo que
  sería peor para la integridad referencial desde comprobantes); la candidata id_cliente del
  supertipo es la más flexible. No se decide: **depende de D-1**.
- Duda CliK-b: el documento del exportador (CUIT de empresa) vs. el del socio (DNI) puede convivir en
  (tipo_doc, n_doc); misma persona con dos documentos distintos (¿DNI y CUIT de persona humana?).
  Duda de dominio sin respuesta textual. Se marca como **requiere consulta al docente** solo si el
  grupo quisiera usar CliK-2 como PK.
- `[Inferencia]` descartadas: nombre sin unicidad (puede haber homónimos); (nombre, localidad)
  tampoco (dos homónimos en una localidad). No son candidatas.

---

### 2.15 Socio del club (subtipo)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| SocK-1 | id_cliente (heredada del supertipo) | Candidata inferida (identidad heredada; condicionada a D-1 de A-01) | Si el subtipo comparte identidad con Cliente (jerarquía), un socio es un cliente: su clave es la heredada. Con estrategia de tabla única (D-1 opción a), la clave es la del Cliente con condición; con (c), la del supertipo se propaga. **La validez de esta candidata queda condicionada a la decisión D-1.** |

**Minimalidad:** trivial por herencia, condicionada a D-1.

**Respaldos y dudas:**
- Sin atributos propios (A-02 2.15), no hay candidata adicional.
- Depende íntegramente de D-1 de A-01: si el mapeo fuera «una tabla por subtipo» **sin tabla común**,
  cada subtabla tendría que llevar su propia ID de cliente y las referencias de los comprobantes
  quedarían repartidas: desenfoque que la sección 5 exige sopesar. No se decide aquí.

---

### 2.16 Distribuidor (subtipo)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| DK-1 | id_cliente (heredada del supertipo) | Candidata inferida (ídem 2.15, condicionada a D-1) | Ídem 2.15. |
| DK-2 | n_habilitacion | Identificador posible pendiente de validación | Un número de habilitación comercial podría identificar al establecimiento en su jurisdicción, pero (a) el PDF no dice que sea único y (b) su alcance es local (una habilitación de una zona); sin dominio definido, **no se garantiza unicidad**. Se lista como posible dato de unicidad a validar en A-04, no como candidata confirmada. |

**Minimalidad:** DK-1 es trivial por herencia (condicionada a D-1). DK-2 sería minimal **si se
confirma la unicidad de `n_habilitacion`**; hoy no está garantizada.

**Respaldos y dudas:**
- `[Pregunta]` candidata al docente: ¿la combinación (tipo_doc, n_doc) del distribuidor garantiza
  unicidad? Ídem CliK-b.

---

### 2.17 Exportador (subtipo)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| XK-1 | id_cliente (heredada del supertipo) | Candidata inferida (ídem 2.15, condicionada a D-1) | Ídem 2.15. |

**Minimalidad:** trivial por herencia, condicionada a D-1.

**Respaldos y dudas:**
- Sin atributos propios adicionales de identidad (el país de destino es un dato del subtipo, no un
  identificador: varios exportadores apuntan al mismo país).
- Si se quisiera usar el CUIT del exportador como clave natural (`[Inferencia]`), el cliente debe
  tener un atributo de documento (ya está en CliK-2); el mismo criterio de 2.14 aplica.

---

### 2.18 Permiso de exportación

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| PerK-1 | codigo | Identificador posible pendiente de validación | La sección 5 lista «código» del permiso: por naturaleza identificador del documento habilitante. La existencia del dato está respaldada, pero **la unicidad del código no está declarada textualmente**: se infiere por su función y queda pendiente de validación. |
| PerK-2 (compuesta) | exportador + fecha_emision | Identificador posible pendiente de validación | Plausible pero **no garantizada**: dos permisos al mismo exportador podrían emitirse el mismo día (¿dos destinos distintos?). El PDF no lo dice. Se lista solo como hipótesis a validar. |

**Minimalidad:** PerK-1 sería minimal **si se confirma la unicidad del código**; mientras siga
pendiente, la propuesta no es candidata confirmada. PerK-2 sería minimal si se confirma la unicidad
del par (exportador solo agrupa varios; fecha sola agrupa los de todos los exportadores).

**Respaldos y dudas:**
- La unicidad del código de permiso no está explícita (existir el atributo «código» sí está en la
  sección 5, pero esa mención no equivale a una garantía de unicidad): se asume por su función de
  documento habilitante, como inferencia. `[Pregunta]` si corresponde confirmarla.
- Duda PerK-a (Q-12 de A-02): el estado vigente/vencido es derivado y no afecta a la clave.

---

### 2.19 Comprobante (cabecera)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| CompK-1 | numero | Identificador posible pendiente de validación | La sección 5 lista «número» y el API se consulta `GET /comprobantes/{nro}`: el número permite direccionar un comprobante individual, lo que sugiere unicidad. La existencia del dato está respaldada; la **garantía efectiva de unicidad global** no está declarada en el PDF: **pendiente de validación** (ver CompK-a). |
| CompK-2 (compuesta) | sala + numero | Identificador posible pendiente de validación | Alternativa si la numeración fuera **por sala** (práctica comercial común: cada caja numera sus comprobantes). Sin respaldo textual de la consigna ni del API, se lista solo como hipótesis a validar. |

**Minimalidad:** CompK-1 sería minimal **si se confirma que la numeración es global**. CompK-2: entre
sala y número ninguno bastaría solo (número compartido entre salas; sala con muchos números), si la
hipótesis por sala se confirmara.

**Respaldos y dudas:**
- Duda CompK-a: ¿la numeración es global o por sala? **La duda queda expresamente abierta.** Sin
  respuesta, se apunta a CompK-1 como candidata principal por el uso del API
  (`/comprobantes/{nro}`, que sugiere unicidad global del número). `[Inferencia]` con base en el API,
  no en la consigna de modelo. **Pendiente la validación de ambas alternativas.**
- Duda CompK-b (importante para el volumen 150.000): la fecha de venta no forma parte de la clave;
  a lo sumo se incorporaría un período si hubiera una **regla documentada de reinicio de numeración**
  (p. ej. reinicio anual). Hoy no existe ese respaldo textual, por lo que **no se propone ninguna
  combinación con fecha**.
- **Propuesta descartada expresamente:** `(sala, numero, fecha)` no se considera candidata. Solo
  tendría sentido si existiera una regla documentada de reinicio periódico de la numeración, y esa
  regla no está en la consigna. Si la numeración resultara por sala, la alternativa a evaluar es
  `(sala, numero)`, no una terna con fecha.

---

### 2.20 Renglón de comprobante

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| RK-1 (compuesta) | comprobante + vino | Candidata respaldada (clave textual de la sección 5, no decisión aprobada) | La sección 5 dice «Clave (comprobante, vino)» para el renglón: es una de las asociativas con clave declarada textualmente, junto con Stock de sala. Es una asociación N:M con atributos (cantidad, precio histórico, descuento, subtotal). |

**Minimalidad:** comprobante solo no distingue renglones (un comprobante tiene varios vinos); vino
solo tampoco (un vino se vende en muchas ventas). El par es minimal asumiendo que **no hay dos
renglones con el mismo vino en un comprobante** (no es textual, pero sí la lectura natural de la
clave dada: si pudiera repetirse, la clave dada por la consigna no funcionaría).

**Respaldos y dudas:**
- La clave está dada explícitamente por la sección 5; sin embargo **es cita de la consigna**: su
  materialización física (id subrogado vs. PK compuesta) es decisión de diseño de A-04.
- Duda RK-a: ¿puede un comprobante tener dos renglones del mismo vino (p. ej. separados por
  precio/promo)? El par dado por la consigna lo excluye; si la cátedra quisiera permitirlo, habría
  que agregar un n.° de renglón. Sin respaldo, se respeta la exclusión (supuesto).

---

### 2.21 Transportista

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| TK-1 | codigo | Identificador posible pendiente de validación | La sección 5 lista «código» del transporte; un código de empresa externa es identificador por naturaleza. La **existencia** del dato está respaldada, pero la **unicidad efectiva** no está declarada (no hay UNIQUE): se infiere por función y queda pendiente de validación. |
| TK-2 | cuit | Candidata inferida (unicidad dominial, no textual) | La unicidad del CUIT como identificador del transportista es una inferencia condicionada al supuesto de que cada transportista está identificado fiscalmente mediante su propio CUIT. El PDF lo lista como dato de transportista y hay DOMAIN de CUIT (11 dígitos) en etapa 2; pero el UNIQUE explícito de etapa 2 solo se refiere al CUIT de **bodega**. La unicidad de CUIT transportista es inferencia dominial explícita, no restricción textual. |
| TK-3 | razon_social | Descartada (sin unicidad) | Homonimia de empresas posible; el PDF no la desalienta ni declara unicidad. **No es candidata garantizada.** |

**Minimalidad:** TK-2 sería minimal **si se confirma la unicidad fiscal inferida**. TK-1 sería
minimal **si se confirma la unicidad del código**; hoy está pendiente. TK-3 descartada.

**Respaldos y dudas:**
- Duda TK-a: ¿servicios de un mismo grupo empresarial con dos CUIT/códigos? Sin respaldo; se asume
  que no (cada contrato con su código).
- La elección de código natural (TK-1) vs CUIT (TK-2) vs ID (no hay «ID» en la sección 5 para esta
  entidad) es la decisión tipo «código natural vs autogenerado» de la sección 5. **Pendiente.**

---

### 2.22 Transportista cubre localidad

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| TCL-1 (compuesta) | transportista + localidad | Candidata inferida (asociación N:M) | N:M simple (sección 5 «Transportista cubre localidad… N:M», 3.5 «a qué localidades alcanza el servicio de cada transportista»). Es una asociación sin atributos; la fila se identifica por el par. **Inferencia de diseño**: el PDF no dice «clave (transportista, localidad)». |

**Minimalidad:** el par es minimal.

**Respaldos y dudas:**
- Igual que Vino–maridaje: el PDF lista la N:M pero no dice «clave (transportista, localidad)»:
  `[Inferencia]`. D-9 de A-01 sigue abierta (entidad vs relación en el DER) y no cambia el
  contenido de la clave.
- Si un transportista cubriera una localidad con fila repetida, la cobertura se duplicaría
  idénticamente: el diseño estándar lo excluye. `[Supuesto]`.

---

### 2.23 Ingreso (cabecera)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| IK-1 | codigo | Identificador posible pendiente de validación | La sección 5 lista «código» de ingreso; el API direcciona ingresos por su código. La **existencia** del dato está respaldada; el **alcance de la unicidad** (¿global o por bodega de origen?) no está declarado: pendiente de validación (ver IK-a). |

**Minimalidad:** sería minimal **si se confirma la unicidad global del código**; mientras el alcance
siga abierto, la propuesta es un identificador posible pendiente.

**Respaldos y dudas:**
- Duda IK-a: ¿numeración global o por bodega de origen? El texto no distingue; el API menciona
  `/ingresos/{codigo}`, lo que sugiere unicidad global del código (`[Inferencia]`, igual que en
  2.19). **Pendiente de validación.**
- Duda IK-b: el estado/fecha no forman parte de la clave (cambian con el ciclo de vida del
  documento; una clave debe ser invariante para la misma fila). No se proponen como candidatos.

---

### 2.24 Renglón de ingreso

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| RI-1 (compuesta) | ingreso + vino | Candidata inferida (por analogía con 2.20) | El ingreso «contiene un conjunto de vinos con su cantidad» (3.5); N:M con atributo «cantidad». Por analogía con el renglón de comprobante (cuya clave la consigna sí explicita), el par (ingreso, vino) identificaría la fila. **El PDF no explicita esta clave** (no aparece en la tabla de la sección 5 con clave textual): es una inferencia por analogía, que **no equivale a una garantía textual** de la combinación. |

**Minimalidad:** el par es minimal, con la misma suposición de 2.20 (no hay dos renglones con el
mismo vino en un ingreso).

**Respaldos y dudas:**
- Duda RI-a: la ausencia de clave textual en la sección 5 (que sí la especifica para el renglón de
  comprobante y para el stock) es una **asimetría notable de la consigna**. Es de las candidatas de
  analogía a validar con el docente si el grupo quisiera darle otro tratamiento (p. ej. n.° de
  renglón subrogado).
- Relacionado con RN-12 (prohibición de tocar renglones fuera de en_confeccion): las filas del
  renglón son objeto de control, lo que refuerza la necesidad de identificar cada fila con precisión.
  No cambia la candidata.

---

### 2.25 Transferencia (cabecera)

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| TF-1 | numero | Identificador posible pendiente de validación | La sección 5 lista «n.° de solicitud»; el API direcciona por `/transferencias/{nro}`. La **existencia** del dato está respaldada; el **alcance de la unicidad** (¿global o por sala solicitante?) no está declarado: pendiente de validación (ver TF-a). |
| TF-2 (compuesta) | sala + numero | Identificador posible pendiente de validación | Alternativa si la numeración fuera por sala solicitante, análoga a CompK-2. Sin respaldo textual de modelo, se lista solo como hipótesis. |

**Minimalidad:** TF-1 sería minimal **si se confirma la unicidad global del número**. TF-2 sería
minimal si se confirma la numeración por sala (sala sola agrupa muchas transferencias; numero solo
podría repetirse entre salas).

**Respaldos y dudas:**
- Duda TF-a: ¿numeración global (depósito único) o por sala solicitante? Mismo esquema de respuesta
  que 2.19/2.23: el API sugiere unicidad global de «n.° de solicitud» (`[Inferencia]`). Sin respaldo
  textual de modelo, **pendiente de validación**. La alternativa (sala, numero) se registra como la
  hipótesis de numeración por sala (también pendiente).
- Duda TF-b: la fecha de confección (RN-11) es fija al crear el documento pero no es clave (varias
  transferencias un mismo día). Descartada.

---

### 2.26 Renglón de transferencia

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| RT-1 (compuesta) | transferencia + vino | Candidata inferida (por analogía con 2.20) | La transferencia «contiene un conjunto de vinos con su cantidad» (3.5); el par identificaría la línea. La sección 5 no le asigna clave textual: inferencia por analogía con 2.20, que **no equivale a una garantía textual** de la combinación. |

**Minimalidad:** el par, con el mismo supuesto (no repetir el vino en la misma transferencia).

**Respaldos y dudas:** ídem 2.24 (asimetría de la consigna respecto del renglón de comprobante).

---

### 2.27 Stock de sala

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| SS-1 (compuesta) | sala + vino | Candidata respaldada (clave textual de la sección 5, no decisión aprobada) | La sección 5 dice «Clave (sala, vino); cantidad >= 0»: es la fila de inventario por par (sala, vino); el par es la única identidad natural de la existencia. |

**Minimalidad:** sala sola no identifica la fila (muchos vinos por sala); vino solo tampoco (varias
salas). El par es minimal.

**Respaldos y dudas:**
- La clave está respaldada explícitamente por la sección 5. La cantidad **no** es parte de la clave
  (es el valor de la fila; varias filas podrían tener igual cantidad). El `CHECK cantidad >= 0` es un
  requisito de integridad del valor, no un atributo de identidad (y la [Pregunta] P-6 sobre `> 0`
  vs `>= 0` sigue abierta en `docs/requisitos.md` §10.1.6).
- Igual que siempre: materializar como PK compuesta o ID subrogado + UNIQUE del par es decisión de
  A-04.

---

### 2.28 Stock de depósito

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| SD-1 | vino | Candidata inferida (condicionada a «un solo registro por vino») | Si hay un solo depósito (sección 5: «Un solo depósito central») y una fila por vino, la clave sería el atributo `vino` a solas: no hace falta componer con «depósito» porque no hay varias filas por depósito. La unicidad por vino es la condición clave: depende de que se mantenga ese **único registro por vino** (D-3 de A-01 sigue abierta). Es una inferencia sobre la base explícita «un solo depósito», no una clave declarada por la consigna. |

**Minimalidad:** sería minimal (un atributo) **si se mantiene un único registro por vino**; la
condición de unicidad sigue atada a D-3.

**Respaldos y dudas:**
- Duda SD-a (D-3 de A-01): si en algún momento se fusionara la estructura con la del stock de sala
  (un solo «stock» con destino), la clave volvería a ser compuesta (destino, vino). Se registra la
  alternativa pero no se decide: **la sección 5 las lista separadas** y sin indicación contraria se
  respeta la separación.
- La unicidad por vino es directa: dos filas con el mismo vino serían la misma existencia duplicada.
  `[Supuesto]` (estándar del dominio), consistente con «un solo depósito».

---

### 2.29 Auditoría de precio

| Candidata | Atributos | Categoría | Justificación |
|---|---|---|---|
| AU-1 | id_auditoria | Candidata respaldada (ID explícito: unicidad semántica; la más segura) | La sección 5 lista «ID» de la fila de auditoría: la consigna respalda la **unicidad semántica** del identificador de fila. No implica elección de PK ni obligación de autogeneración; la forma concreta se decide en A-04. |
| AU-2 (compuesta) | vino + fecha_hora | Identificador posible pendiente de validación (hipótesis técnica) | Hipótesis técnica basada en RN-13: si el trigger audita cada UPDATE, habría a lo sumo una auditoría por (vino, fecha_hora) — la misma fila no puede cambiar de precio dos veces en el mismo instante. `[Supuesto]` del mecanismo de trigger, **no regla textual de negocio**: dos UPDATEs del mismo vino en el mismo instante (o timestamps con menor precisión) no están excluidos por la consigna. No se la declara candidata confirmada. |
| AU-3 (compuesta) | vino + precio_anterior + fecha_hora | Descartada (no minimal si AU-2 vale) | Incluye precio_anterior, que ya queda determinado por (vino, fecha_hora) si AU-2 vale: no es minimal. Se lista solo para documentar el descarte. |

**Minimalidad:** AU-1 trivial. AU-2, si la unicidad se confirmara, sería minimal por inferencia
(vino solo no; fecha_hora sola tampoco); igualmente queda condicionada a la validación de AU-2.

**Respaldos y dudas:**
- Duda AU-a: si dos UPDATEs de precios de vinos **distintos** caen en el mismo timestamp,
  (vino, fecha_hora) sigue siendo única (el vino participa). El riesgo es dos cambios del **mismo**
  vino en el mismo instante: improbable en la práctica del trigger, pero sin garantía textual. No se
  confunde esta duda con Q-07 de A-02, que trata sobre si el «usuario» auditado es de base de datos o
  funcional. **Por defecto, la candidata más segura es AU-1 (ID)**; AU-2 queda como alternativa
  `[Inferencia]`.
- La sección 5 la asigna como entidad para cubrir el criterio «todas las entidades de la sección 5»
  (D-10 de A-01); su identificación «ID» es la literal de la consigna.

---

## 3. Tabla-resumen de candidatas por entidad

> Categorías: **R** = respaldada; **I** = inferida; **P** = identificador posible pendiente de
> validación; **D** = descartada. La tabla no decide PK ni FK. Para los atributos «ID», **R**
> significa **unicidad semántica** del identificador, no elección de PK ni obligación de
> autogeneración.

| # | Entidad | Candidatas propuestas | Categoría y origen |
|---|---|---|---|
| 1 | Localidad | codigo_postal; (nombre, provincia) | P: existe «código postal» textual, unicidad no declarada; (nombre, provincia) sin respaldo textual. |
| 2 | Sala de venta | id_sala | R: «ID» explícito (unicidad semántica); forma y PK en A-04. |
| 3 | Empleado | cuit | I: unicidad fiscal inferida y condicionada a que el empleado sea persona física identificada con ese CUIT; sin UNIQUE textual. |
| 4 | Finca | id_finca | R: «ID» explícito (unicidad semántica). |
| 5 | Parcela | (finca, n_parcela) | R: 3.2, sección 5 y etapa 1. |
| 6 | Cepa | id; nombre | R: «ID» explícito (unicidad semántica). P: nombre sin UNIQUE textual. |
| 7 | Lote de uva | n_lote; (parcela, campania) | P: n_lote con alcance global no declarado. P: (parcela, campania) tiene unicidad textual (UNIQUE) pero minimalidad no demostrada. |
| 8 | Análisis de calidad | id_analisis; (lote, fecha) | R: «ID» explícito (unicidad semántica; identidad de fila dudosa). P: (lote, fecha) sin regla de unicidad. |
| 9 | Bodega | cuit | R: UNIQUE explícito de etapa 2; PK no decidida. |
| 10 | Vino | codigo; (nombre, anada, volumen_ml) | I: código de producto + API, sin UNIQUE textual. P: combinación con unicidad textual y minimalidad no demostrada formalmente. |
| 11 | Composición (vino–cepa) | (vino, cepa) | I: diseño N:M; sin clave textual. |
| 12 | Maridaje | id; nombre | R: «ID» explícito (unicidad semántica). P: nombre sin UNIQUE textual. |
| 13 | Vino–maridaje | (vino, maridaje) | I: diseño N:M; sin clave textual. |
| 14 | Cliente | id_cliente; (tipo_doc, n_doc) | R: «ID» explícito (unicidad semántica). P: documento sin unicidad textual y con posible doble documento por persona. |
| 15 | Socio del club | id_cliente (heredada) | I: identidad heredada, condicionada a D-1. |
| 16 | Distribuidor | id_cliente (heredada); n_habilitacion | I: heredada, condicionada a D-1. P: n_habilitacion sin unicidad garantizada. |
| 17 | Exportador | id_cliente (heredada) | I: identidad heredada, condicionada a D-1. |
| 18 | Permiso de exportación | codigo; (exportador, fecha_emision) | P: código sin UNIQUE textual. P: par sin regla de unicidad. |
| 19 | Comprobante | numero; (sala, numero) | P: número con alcance global vs. por sala abierto. P: (sala, numero) solo si la numeración es por sala. D: (sala, numero, fecha) sin regla de reinicio documentada. |
| 20 | Renglón de comprobante | (comprobante, vino) | R: clave textual de la sección 5. |
| 21 | Transportista | codigo; cuit | P: código sin UNIQUE textual. I: CUIT por unicidad fiscal, sin UNIQUE textual. |
| 22 | Transportista cubre localidad | (transportista, localidad) | I: diseño N:M; sin clave textual. |
| 23 | Ingreso | codigo | P: código con alcance global vs. por bodega abierto. |
| 24 | Renglón de ingreso | (ingreso, vino) | I: analogía con 2.20; sin clave textual. |
| 25 | Transferencia | numero; (sala, numero) | P: número con alcance global vs. por sala abierto. P: (sala, numero) solo como hipótesis. |
| 26 | Renglón de transferencia | (transferencia, vino) | I: analogía con 2.20; sin clave textual. |
| 27 | Stock de sala | (sala, vino) | R: clave textual de la sección 5. |
| 28 | Stock de depósito | vino | I: condicionada a un único registro por vino (D-3). |
| 29 | Auditoría de precio | id_auditoria; (vino, fecha_hora) | R: «ID» explícito (unicidad semántica). P: (vino, fecha_hora) como hipótesis técnica. |

## 4. Clasificación de las propuestas

### 4.1 Claves con respaldo textual

| Entidad / propuesta | Respaldo | Grado |
|---|---|---|
| Parcela: (finca, n_parcela) | 3.2, sección 5 y etapa 1, paso 2 | Respaldo triple; no es decisión de PK. |
| Renglón de comprobante: (comprobante, vino) | Sección 5, clave textual | Respaldo textual; la materialización física queda para A-04. |
| Stock de sala: (sala, vino) | Sección 5, clave textual | Respaldo textual; la materialización física queda para A-04. |
| Bodega: cuit | Etapa 2, UNIQUE explícito | Respaldo textual de unicidad; no decide PK. |
| Sala, Finca, Cepa, Maridaje, Cliente, Análisis y Auditoría: atributo «ID» | Sección 5 | La consigna respalda la **unicidad semántica** del identificador de fila. No implica elección de PK ni obligación de autogeneración; la forma concreta se decide en A-04. Las dudas particulares (p. ej. la identidad de Análisis de calidad) se conservan. |

> Lote (parcela, campania) y Vino (nombre, anada, volumen_ml) **no** se incluyen aquí como claves
> plenamente respaldadas: tienen unicidad textual (UNIQUE de etapa 2), pero su minimalidad no está
> demostrada formalmente. Se listan en 4.3.

### 4.2 Claves inferidas con fundamento suficiente

| Entidad / propuesta | Fundamento de la inferencia | Límite |
|---|---|---|
| Empleado: cuit | Unicidad fiscal inferida, condicionada a que el empleado sea una persona física identificada con ese CUIT. | No hay UNIQUE textual para empleado ni se afirma que todo empleado tenga CUIT propio. |
| Vino: codigo | Código de producto y uso de `/vinos/{cod}` para direccionar un vino. | No hay UNIQUE textual sobre `codigo`. |
| Transportista: cuit | Unicidad fiscal del CUIT de una empresa. | El UNIQUE textual de etapa 2 es solo para CUIT de bodega. |
| Composición: (vino, cepa) | Diseño estándar de asociación N:M con atributo. | El PDF no enumera la clave. |
| Vino–maridaje: (vino, maridaje) | Diseño estándar de asociación N:M sin atributos. | El PDF no enumera la clave; D-9 abierta. |
| Transportista cubre localidad: (transportista, localidad) | Diseño estándar de asociación N:M sin atributos. | El PDF no enumera la clave; D-9 abierta. |
| Renglón de ingreso: (ingreso, vino) | Analogía con el renglón de comprobante. | Asimetría textual: la sección 5 no da clave para este renglón. |
| Renglón de transferencia: (transferencia, vino) | Analogía con el renglón de comprobante. | Asimetría textual: la sección 5 no da clave para este renglón. |
| Stock de depósito: vino | «Un solo depósito central» y un registro por vino. | Condicionada a D-3 y al supuesto de un único registro. |
| Socio, Distribuidor y Exportador: id_cliente heredada | Identidad heredada de la jerarquía Cliente. | Condicionada a D-1. |

### 4.3 Identificadores posibles pendientes de validación

| Entidad / propuesta | Qué falta validar |
|---|---|
| Localidad: codigo_postal | Si un código postal identifica una sola localidad o puede cubrir varias. |
| Localidad: (nombre, provincia) | Si existen homónimos dentro de una provincia. |
| Cepa: nombre | Si el nombre de variedad es único en el catálogo. |
| Maridaje: nombre | Si el nombre de la recomendación es único en el catálogo. |
| Lote de uva: n_lote | Si la numeración es global o relativa a parcela/campaña. |
| Lote de uva: (parcela, campania) | Minimalidad: probar que parcela sola y campania sola no son únicas. |
| Análisis de calidad: (lote, fecha) | Si puede haber más de un análisis del mismo lote el mismo día. |
| Vino: (nombre, anada, volumen_ml) | Minimalidad formal: probar que ningún subconjunto propio es único. |
| Cliente: (tipo_doc, n_doc) | Si el documento es único y si una persona puede tener más de un tipo de documento. |
| Distribuidor: n_habilitacion | Alcance y unicidad de la habilitación comercial. |
| Permiso: codigo | Si el código de permiso es único. |
| Permiso: (exportador, fecha_emision) | Si pueden emitirse dos permisos al mismo exportador el mismo día. |
| Comprobante: numero | Si la numeración es global o por sala. |
| Comprobante: (sala, numero) | Solo tiene sentido si se confirma la numeración por sala. |
| Transportista: codigo | Si el código de la empresa es único. |
| Ingreso: codigo | Si la numeración es global o por bodega de origen. |
| Transferencia: numero | Si la numeración es global o por sala solicitante. |
| Transferencia: (sala, numero) | Solo tiene sentido si se confirma la numeración por sala. |
| Auditoría de precio: (vino, fecha_hora) | Si dos cambios del mismo vino pueden coincidir en el mismo timestamp. |

> Ninguna propuesta listada aquí se considera candidata confirmada mientras su unicidad o su
> minimalidad sigan pendientes; en particular, la minimalidad de las propuestas de un solo atributo se
> afirma solo condicionalmente.

### 4.4 Entidades que requieren una decisión de diseño o consulta al docente

| Entidad / tema | Qué falta | Referencia |
|---|---|---|
| Vino–maridaje, Transportista cubre localidad y Composición | Confirmar que la cátedra espera el par de participantes como clave y no un ID propio para la asociación. | Sección 5; D-9 de A-01. |
| Renglón de ingreso y Renglón de transferencia | Asimetría frente al renglón de comprobante; preguntar si la cátedra quiere un n.° de renglón explícito. | 3.5; sección 5; RN-12. |
| Análisis de calidad | Unicidad de (lote, fecha) no garantizada. | D-6 de A-01 / Q-06 de A-02. |
| Comprobante, Ingreso y Transferencia | Alcance de la numeración: global o por sala/bodega. | Sección 5; API. |
| Localidad | Unicidad del código postal y de (nombre, provincia). | Sección 5. |
| Cepa, Maridaje, Cliente | Unicidad del nombre o del documento. | Sección 5; Anexo B. |
| Lote de uva | Alcance de n_lote y minimalidad de (parcela, campania). | RN-04; Q-02 de A-02. |
| Vino | Minimalidad de (nombre, anada, volumen_ml) y alcance del catálogo de volúmenes. | 3.3; etapa 2; P-8 de `requisitos.md` §10.1.7. |
| Empleado y Transportista | CUIT como clave natural vs. identificador subrogado; confirmar si todo empleado es persona física con CUIT propio y el alcance del CUIT de transportista. | Sección 5; etapa 2. |
| Bodega | Elegir CUIT o ID subrogado como PK, sin perder el UNIQUE de CUIT. | Etapa 2; sección 5. |
| Permiso de exportación | Unicidad del código y del par (exportador, fecha_emision). | Sección 5; Q-12 de A-02. |
| Distribuidor | Unicidad y alcance de n_habilitacion. | Sección 5. |
| Subtipos de Cliente | Clave heredada; bloqueada por D-1 (mapeo de jerarquía). | D-1 de A-01; Q-04 de A-02. |
| Stock de depósito | Depende de mantener la separación del stock de sala. | D-3 de A-01. |

---

## 5. Preguntas abiertas de otras issues que impactan claves (cross-check)

- **P-9 de `requisitos.md` §10.1.5:** RN-06 (30 % exportador) vs. U6 (35 % con más de 3 permisos):
  no cambia ninguna clave.
- **P-6 de `requisitos.md` §10.1.6:** `> 0` vs `>= 0` en stocks/cantidades: afecta al CHECK del valor
  de la fila, no a ninguna clave.
- **P-8 de `requisitos.md` §10.1.7:** catálogo de volúmenes abierto/cerrado: afecta al CHECK del
  volumen del vino, no a VK-2.
- **Pregunta sobre el 4.º UNIQUE de etapa 2** (`requisitos.md` §5.2 y §10.2, punto 6): si la cátedra
  confirmara un cuarto UNIQUE por otro atributo (p. ej. razón social de transportista), podrían
  aparecer claves candidatas nuevas. Pendientes las respuestas.
- **Dudas de A-01 que impactan claves:** D-1 (jerarquía de Cliente), D-3 (stock de depósito),
  D-6 (identidad del análisis), D-9 (N:M como entidad o relación) y D-10 (auditoría en el DER).
- **Dudas de A-02 que impactan claves:** Q-02 (identidad del lote), Q-06 (identidad del análisis) y
  Q-12 (estado del permiso, solo como referencia). Q-01, Q-03, Q-04, Q-05, Q-07, Q-08, Q-09, Q-10,
  Q-11 y Q-13 no modifican las claves analizadas (afectan atributos, dominios o valores derivados).

---

## 6. Referencias a la consigna

| Bloque de este documento | Referencia en el PDF |
|---|---|
| Entidades y orden de análisis | Sección 5 (tabla «Modelo de datos: entidades mínimas») |
| Debilidad de Parcela y su clave | 3.2 + 5 + etapa 1, paso 2 |
| Clave de renglón de comprobante y de stock de sala | Sección 5 (columna de observaciones) |
| UNIQUE (parcela, campania), (nombre, anada, volumen_ml), CUIT de bodega | Sección 7, etapa 2 |
| Vinos con el mismo nombre y distinta añada o presentación | Sección 3.3 |
| Elección de claves y criterio natural vs. autogenerado (CUIT, código postal) | Sección 5 «decisiones de diseño que deben tomar y justificar por escrito» |
| Reglas que condicionan unicidad o identidad (lotes por campaña, vinos por presentación, stock) | RN-04, RN-01, RN-09 |
| Consistencia entre atributos derivados y claves (subtotales, sumas) | RN-05, RN-08 |
| Uso del número/código en la API | Endpoints `/vinos/{cod}`, `/comprobantes/{nro}`, `/ingresos/{codigo}`, `/transferencias/{nro}` |
| Antecedentes inmediatos | `docs/modelo/01_entidades_candidatas.md` (A-01), `docs/modelo/02_atributos_entidades.md` (A-02) |

---

### Registro de cambios de este documento

- Creación (A-03, borrador): candidatas por entidad (incluir claves explícitas/inferidas, dudas
  asociadas, ejemplo de heredada en la jerarquía de cliente, comparaciones naturales vs.
  autogeneradores dejadas abiertas para A-04), tabla-resumen de candidatas y listado de pendientes
  de decisión/consulta.
- Revisión conceptual integral (A-03): se separan con claridad las tres categorías (respaldada,
  inferida y pendiente de validación); se diferencia la existencia de un atributo identificador en la
  consigna de la garantía efectiva de unicidad; se revisa la minimalidad de (parcela, campania) y de
  (nombre, anada, volumen_ml); se elimina (sala, numero, fecha) como candidata de Comprobante y se
  deja (sala, numero) solo como alternativa condicionada; se corrigen referencias equivocadas
  (la duda de Cepa, la de Auditoría, la pregunta del 4.º UNIQUE y la atribución de P-8);
  se reemplazan etiquetas de candidatas que colisionaban (PK/FK/SK) por etiquetas inequívocas; se
  corrigen tablas Markdown y se mantiene el orden de las 29 entidades.
- Corrección final de consistencia (A-03): se unifica el tratamiento de los atributos «ID» como
  unicidad semántica del identificador, sin confundirla con la elección de PK ni con la
  autogeneración; se matiza el CUIT de Empleado como inferencia condicionada a que sea persona
  física identificada fiscalmente; se condiciona la minimalidad de las propuestas de un solo
  atributo cuya unicidad sigue pendiente; se alinean §2, §3 y §4; se corrigen espacios y formato.

# A-04 — Relaciones y cardinalidades

> Issue A-04 · Responsable: Persona A · Estado: borrador conceptual revisado (pre-DER)
> Fuente principal: `docs/Consigna/TPI_Bodegas_del_Atuel.pdf` (secciones 3, 4, 5, 7 y 8), `docs/requisitos.md`,
> `docs/modelo/01_entidades_candidatas.md` (A-01), `docs/modelo/02_atributos_entidades.md` (A-02)
> y `docs/modelo/03_claves_candidatas.md` (A-03).
>
> Convención de lectura:
> - `A x..y — z..w B` significa: cada instancia de `A` se vincula con entre `x` e `y` instancias de
>   `B`; cada instancia de `B` con entre `z` y `w` instancias de `A`. Los dos rangos son independientes.
> - `*` se coloca junto al extremo cuyo valor es inferido, interpretativo o dependiente de una decisión
>   pendiente; no es una regla numérica formal. Ejemplos: `2*..N` (mínimo 2 inferido), `1*..N` (mínimo 1
>   inferido), `1*..1` (mínimo 1 inferido, máximo 1 respaldado), `1*..1*` (ambos extremos inferidos),
>   `0*..N` (mínimo 0 inferido) y `1..N*` (máximo N inferido). Los extremos sin `*` tienen respaldo
>   suficiente según la justificación de la relación.
> - **C** = respaldo textual claro en ambos extremos.
> - **P** = parcial: algún extremo (mínimo o máximo) es inferido, indirecto o pendiente.
> - **J** = jerarquía; totalidad y exclusividad no están determinadas.
>
> Este documento **no** elige claves primarias ni foráneas, **no** construye el DER definitivo, **no** diseña
> tablas físicas y **no** resuelve las dudas D-1…D-10 ni Q-01…Q-13. Las relaciones N:M se describen
> conceptualmente; su materialización como entidad asociativa o relación queda abierta.

---

## 1. Objetivo y alcance

Identificar y justificar las **25 relaciones** del modelo conceptual de «Bodegas del Atuel», con su
cardinalidad mínima y máxima en ambos extremos, el fragmento de la consigna que las respalda y la
clasificación de ese respaldo.

El documento usa identificadores propios REL-01 a REL-25, ordenados por área funcional. No agrega,
elimina ni fusiona relaciones. Tampoco convierte una inferencia en una regla explícita: el extremo que no
tiene respaldo suficiente se marca con `*` junto a su valor y se remite a la ambigüedad correspondiente.

Criterios transversales:

- La **cardinalidad de negocio** se distingue de un **estado transitorio de alta**. Que una sala pueda
  insertarse antes de tener empleados, o una bodega antes de tener vinos, no demuestra por sí solo que el
  mínimo de negocio sea 0.
- Una **fila de stock inexistente** no es equivalente a una **cantidad de stock igual a cero**. Son estados
  diferentes.
- La notación **N:M** de la consigna respalda multiplicidad máxima, pero no fija por sí sola el mínimo 1.
- Las relaciones que no tienen respaldo suficiente se listan como descartadas en §6; no se incorporan por
  conveniencia técnica.

---

## 2. Convención de cardinalidades y participación

Para una relación binaria se usa una notación independiente por extremo:

`A x..y — z..w B`

- Cada instancia de `A` se vincula con entre `x` e `y` instancias de `B`.
- Cada instancia de `B` se vincula con entre `z` y `w` instancias de `A`.
- Los dos rangos son independientes; el mínimo y el máximo de un extremo no se deducen del otro.

Ejemplo: `Localidad 0*..N — 1..1 Sala de venta` significa que una localidad puede tener entre 0 y N
salas (mínimo 0 inferido), y que cada sala pertenece a exactamente una localidad.

`*` se escribe junto al extremo cuyo valor es inferido, interpretativo o dependiente de una decisión
pendiente; no es una regla numérica formal. Ejemplos: `2*..N` (mínimo 2 inferido), `1*..N` (mínimo 1
inferido), `1*..1` (mínimo 1 inferido y máximo 1 respaldado), `1*..1*` (ambos extremos inferidos),
`0*..N` (mínimo 0 inferido) y `1..N*` (máximo N inferido). Un extremo sin `*` tiene respaldo suficiente
según la justificación de la relación. En particular, `2*..N` no afirma que «varios» cuantifique un
máximo: solo respalda la lectura abierta de N.

La **participación mínima** indica cuántas instancias del otro extremo deben existir para una instancia
dada. La **participación máxima** indica el límite superior declarado. En las relaciones N:M se informan
ambos extremos, aunque la consigna solo diga «N:M».

---

## 3. Relaciones REL-01 a REL-25

### 3.1 Red comercial

#### REL-01 — Localidad–Sala de venta

- **Participantes:** Localidad (A) y Sala de venta (B).
- **Cardinalidad:** A `0*..N` salas; B `1..1` localidad.
- **Clasificación:** P.
- **Respaldo:** «Una sala está ubicada en una sola localidad, pero en una localidad puede haber más de una
  sala.» (p. 4, §3.1).
- **Justificación:** B→A: cada sala pertenece a una sola localidad; está expreso. A→B: «más de una» respalda
  la lectura abierta de máximo N, pero no lo cuantifica expresamente; el mínimo 0 es inferido, porque la
  consigna no declara que toda localidad deba tener una sala.
- **Aclaración:** si el negocio exigiera al menos una sala por localidad, el mínimo sería 1; no está
  establecido. Ver AMB-01 y AMB-04b.

#### REL-02 — Sala de venta–Empleado

- **Participantes:** Sala de venta (A) y Empleado (B).
- **Cardinalidad provisional:** A `2*..N` empleados; B `1..1` sala. **El mínimo de A no está determinado
  para el DER:** `2*..N` es la hipótesis literal de «varios», no una cardinalidad definitiva.
- **Clasificación:** P.
- **Respaldo:** «En cada sala trabajan varios empleados.» y «Cada empleado trabaja en una sola sala.»
  (p. 4, §3.1).
- **Justificación:** B→A: cada empleado trabaja en una sola sala; está expreso. A→B: «varios» respalda
  literalmente que hay más de uno y la lectura abierta de máximo N; no cuantifica expresamente un máximo.
  El mínimo 2 se infiere de «varios» en lectura literal (más de uno), pero no hay una frase numérica que
  diga «dos o más».
- **Aclaración:** una sala recién creada puede estar transitoriamente sin empleados; ese estado de alta no
  determina la cardinalidad de negocio. Falta decidir si el mínimo 2 es una regla formal, inmediata o
  diferida; I5 permite el alta de una sala sin actividad y no resuelve la cuestión. I4 se refiere a la
  bodega, no a esta relación. No se reemplaza automáticamente por `1..N` ni por `0..N`. Ver AMB-02.

#### REL-03 — Localidad–Cliente

- **Participantes:** Localidad (A) y Cliente (B).
- **Cardinalidad:** A `0*..N` clientes; B `1*..1` localidad.
- **Clasificación:** P.
- **Respaldo:** «De cada cliente se guarda su ID, apellido y nombre o razón social, tipo y número de
  documento, dirección, localidad y fecha de alta.» (p. 5, §3.4). La tabla de §5 vuelve a listar
  «localidad» entre los datos del cliente (p. 7, §5).
- **Justificación:** B→A: cada cliente se asocia con una localidad; el singular del atributo lo respalda,
  pero el mínimo 1 es inferido. A→B: el máximo N es propio de la relación; el mínimo 0 es inferido porque
  no toda localidad debe tener clientes.
- **Aclaración:** no se declara que el cliente deba comprar en una sala de su propia localidad, ni existe
  una relación directa Cliente–Sala. Ver AMB-04a y AMB-04b.

### 3.2 Producción de uva

#### REL-04 — Finca–Parcela

- **Participantes:** Finca (A) y Parcela (B).
- **Cardinalidad:** A `1*..N` parcelas; B `1..1` finca.
- **Clasificación:** P.
- **Respaldo:** «Cada finca se divide en parcelas, identificadas por un número dentro de la finca: una
  parcela no existe sin su finca.» (p. 4, §3.2). La sección 5 la declara entidad débil con clave
  `(finca, n.° de parcela)` (p. 7, §5).
- **Justificación:** B→A: cada parcela pertenece a una finca y no existe sin ella; está expreso. A→B:
  «parcelas» respalda la lectura abierta de máximo N, pero no lo cuantifica expresamente; el mínimo 1 es
  inferido de «cada finca se divide en parcelas», pero no hay una cuantificación formal «una o más».
- **Aclaración:** si se admitiera una finca todavía no subdividida, el mínimo podría ser 0; si se leyera
  «parcelas» como plural estricto, podría ser 2. Ninguna de esas lecturas está confirmada. Ver AMB-03.

#### REL-05 — Parcela–Cepa

- **Participantes:** Parcela (A) y Cepa (B).
- **Cardinalidad:** A `1..1` cepa; B `0*..N*` parcelas.
- **Clasificación:** P.
- **Respaldo:** «De cada parcela se conoce su superficie, el año de plantación y la cepa que tiene plantada
  (una sola).» (p. 4, §3.2). «Una parcela tiene una sola cepa y se cosecha como máximo una vez por
  campaña.» (p. 6, RN-04). «Eliminar las cepas que no componen ningún vino ni están plantadas en ninguna
  parcela.» (p. 21, §8.3, D2).
- **Justificación:** A→B: mínimo 1 y máximo 1 expresos en §3.2 y RN-04. B→A: el mínimo 0 es inferido/indirecto
  por D2, que contempla cepas no plantadas; el máximo N es inferido, porque una variedad puede
  estar plantada en varias parcelas, pero la consigna no lo cuantifica.
- **Aclaración:** el mínimo 1 es el de cada Parcela respecto de su Cepa; los extremos mínimo 0 y máximo N
  son inferidos/indirectos del lado Cepa. No se modela historia de replantaciones ni una tabla intermedia
  parcela–cepa. Ver AMB-12 y D-7.

#### REL-06 — Parcela–Lote de uva

- **Participantes:** Parcela (A) y Lote de uva (B).
- **Cardinalidad:** A `0*..N` lotes; B `1*..1` parcela.
- **Clasificación:** P.
- **Respaldo:** «En cada campaña (año de cosecha), cada parcela puede cosecharse a lo sumo una vez, lo que
  genera un lote de uva.» (p. 4, §3.2). La sección 5 observa «Una cosecha por parcela y campaña»
  (p. 7, §5).
- **Justificación:** B→A: cada lote se origina en una parcela; el singular lo respalda, pero el mínimo 1 es
  inferido. A→B: el máximo es 1 por campaña y N a lo largo de varias campañas; el mínimo 0 es inferido
  porque una parcela puede no cosecharse en una campaña o no haber sido cosechada nunca.
- **Aclaración:** el límite de 1 es por campaña, no por vida de la parcela. La identidad y numeración del
  lote siguen en Q-02.

#### REL-07 — Lote de uva–Bodega

- **Participantes:** Lote de uva (A) y Bodega (B).
- **Cardinalidad:** A `1..1` bodega; B `0*..N` lotes.
- **Clasificación:** P.
- **Respaldo:** «De cada lote se registra su número, la fecha de cosecha, los kilos cosechados y la bodega
  a la que fue entregado.» (p. 4, §3.2). La sección 5 lista «bodega destino» (p. 7, §5).
- **Justificación:** A→B: cada lote se entrega a una sola bodega; está expreso. B→A: el máximo N es
  propio de la relación; el mínimo 0 es inferido porque no toda bodega debe recibir lotes.
- **Aclaración:** no se declara que un lote pueda repartirse entre varias bodegas. La bodega destino del
  lote es un rol distinto de la bodega que elabora el vino y de la bodega origen de un ingreso. Ver AMB-06
  y AMB-17.

#### REL-08 — Lote de uva–Análisis de calidad

- **Participantes:** Lote de uva (A) y Análisis de calidad (B).
- **Cardinalidad:** A `1..N*` análisis; B `1*..1*` lote. El máximo N de análisis por Lote y ambos extremos
  de Lote por Análisis son inferidos.
- **Clasificación:** P.
- **Respaldo:** «A cada lote de uva se le practican uno o más análisis de calidad, de los que se conoce la
  fecha, el grado Brix, el pH y la acidez total (g/L).» (p. 4, §3.2). La sección 5 observa «Varios análisis
  por lote» (p. 7, §5).
- **Justificación:** A→B: el mínimo 1 está expreso en «uno o más»; el máximo N no está cuantificado
  expresamente y se infiere de «Varios análisis por lote». B→A: mínimo 1 y máximo 1; no hay una frase
  numérica que diga «cada análisis pertenece a un solo lote», pero se infiere de «A cada lote se le
  practican…» y del atributo singular «lote» de §5.
- **Aclaración:** el rango `1*..1*` del lado Lote es inferido, no expreso; por eso la clasificación se
  corrige de C a P sin cambiar el valor. La identidad del análisis y la posibilidad de dos análisis del
  mismo lote en la misma fecha siguen abiertas. Ver AMB-13, D-6 y Q-06.

### 3.3 Bodega y vino

#### REL-09 — Bodega–Vino

- **Participantes:** Bodega (A) y Vino (B).
- **Cardinalidad provisional:** A `2*..N` vinos; B `1..1` bodega. **El mínimo de A no está determinado
  para el DER:** `2*..N` es la hipótesis literal de «varios», no una cardinalidad definitiva.
- **Clasificación:** P.
- **Respaldo:** «Una bodega elabora varios vinos.» (p. 4, §3.3). La sección 5 observa «Un vino lo elabora
  una bodega» (p. 7, §5).
- **Justificación:** B→A: cada vino lo elabora una sola bodega; está expreso. A→B: «varios» respalda
  literalmente que hay más de uno y la lectura abierta de máximo N; no cuantifica expresamente un máximo.
  El mínimo 2 se infiere de «varios» en lectura literal, pero no hay una regla numérica formal que diga
  «como mínimo dos».
- **Aclaración:** una bodega puede insertarse antes de registrar vinos (I4, p. 21), pero ese es un estado
  transitorio y no demuestra que el mínimo de negocio sea 0. Falta decidir si el mínimo 2 es una regla
  formal, inmediata o diferida; I4 permite el alta de una bodega sin actividad y no resuelve la cuestión.
  I5 se refiere a la sala, no a esta relación. No se reemplaza automáticamente por `1..N` ni por `0..N`.
  Ver AMB-05 y AMB-06.

#### REL-10 — Vino–Cepa (Composición)

- **Participantes:** Vino (A) y Cepa (B), mediante la composición con porcentaje de corte.
- **Cardinalidad:** A `1..N` cepas; B `0*..N` vinos.
- **Clasificación:** P.
- **Respaldo:** «Un vino puede estar compuesto por una o más cepas, cada una en un determinado porcentaje
  de corte (la suma de los porcentajes debe ser 100).» (p. 4, §3.3). La sección 5 observa «N:M con
  atributo; suma 100 por vino» (p. 7, §5). «Eliminar las cepas que no componen ningún vino ni están
  plantadas en ninguna parcela.» (p. 21, §8.3, D2).
- **Justificación:** A→B: el mínimo 1 está expreso en «una o más cepas»; «suma 100 por vino» refuerza que
  no puede haber un vino sin cepas. El máximo N se respalda como lectura abierta de la N:M; no está
  cuantificado expresamente. B→A: mínimo 0 con respaldo indirecto en D2 (cepas que no componen ningún
  vino); máximo N respaldado por «vinos de una misma cepa» (p. 4, §3.3) y por la notación N:M.
- **Aclaración:** la notación N:M no fija el mínimo; el mínimo 1 del lado Vino sí es explícito. El mínimo 0
  del lado Cepa es inferido/indirecto. No se decide si Composición se dibuja como entidad asociativa o
  relación, ni si el par puede repetirse. Ver D-9.

#### REL-11 — Vino–Maridaje

- **Participantes:** Vino (A) y Maridaje (B).
- **Cardinalidad:** A `1..N` maridajes; B `0*..N` vinos.
- **Clasificación:** P.
- **Respaldo:** «Además, cada vino tiene uno o más maridajes recomendados.» y «un maridaje puede repetirse
  para distintos vinos.» (p. 4, §3.3). La sección 5 observa «N:M» (p. 7, §5).
- **Justificación:** A→B: el mínimo 1 está expreso en «uno o más»; el máximo N se respalda como lectura
  abierta de la N:M, pero no está cuantificado expresamente. B→A: «puede repetirse para distintos vinos»
  respalda la lectura abierta de máximo N; el mínimo 0 es inferido, porque el catálogo puede contener
  maridajes que no estén recomendados para ningún vino.
- **Aclaración:** no se declara que todo maridaje del catálogo deba estar asociado al menos a un vino. La
  notación N:M solo respalda la multiplicidad máxima. Ver AMB-16 y D-9.

### 3.4 Clientes y ventas

#### REL-12 — Cliente–Comprobante

- **Participantes:** Cliente (A) y Comprobante (B).
- **Cardinalidad:** A `0*..N*` comprobantes; B `1..1` cliente. El mínimo 0 y el máximo N del lado Cliente
  son inferidos/provisionales.
- **Clasificación:** P.
- **Respaldo:** «De cada venta se genera un comprobante que contiene: número, fecha, cliente, sala en la que
  se realizó…» (p. 5, §3.4). D4: «Borrar los clientes socios que nunca compraron y se dieron de alta hace
  más de 5 años.» y D6: «Borrar los clientes socios sin compras que viven en una localidad específica.»
  (p. 21–22, §8.3) contemplan clientes sin compras.
- **Justificación:** B→A: cada comprobante tiene un cliente; está expreso. A→B: D4/D6 solo respaldan la
  existencia de **socios** sin compras; no fijan el mínimo 0 para todos los clientes ni el máximo N. Ambos
  extremos del lado Cliente se mantienen como inferidos.
- **Aclaración:** no hay una relación directa Cliente–Sala; el vínculo se produce a través del comprobante.
  La jerarquía de Cliente sigue pendiente. Ver REL-15, AMB-04b y AMB-07.

#### REL-13 — Sala de venta–Comprobante

- **Participantes:** Sala de venta (A) y Comprobante (B).
- **Cardinalidad:** A `0*..N` comprobantes; B `1..1` sala.
- **Clasificación:** P.
- **Respaldo:** «De cada venta se genera un comprobante que contiene: número, fecha, cliente, sala en la que
  se realizó…» (p. 5, §3.4). I5 permite «Insertar una nueva sala de venta» (p. 21, §8.2).
- **Justificación:** B→A: cada comprobante registra una sola sala; está expreso. A→B: el máximo N es
  propio de la relación; el mínimo 0 es inferido, porque una sala nueva o sin actividad puede no tener
  comprobantes.
- **Aclaración:** no se declara que toda sala deba tener al menos una venta. Ver AMB-04b y AMB-14.

#### REL-14 — Comprobante–Vino (Renglón de comprobante)

- **Participantes:** Comprobante (A) y Vino (B), mediante el renglón de comprobante.
- **Cardinalidad:** A `1*..N*` vinos; B `0*..N` comprobantes.
- **Clasificación:** P.
- **Respaldo:** «Cada comprobante incluye un conjunto de vinos con los siguientes datos: código de vino,
  cantidad, precio unitario al momento de la venta, descuento aplicado… y subtotal del renglón.»
  (p. 5, §3.4). La sección 5 lista «Comprobante, vino, cantidad, precio unitario, descuento, subtotal»
  (p. 7, §5).
- **Justificación:** A→B: el máximo N se infiere de «conjunto de vinos»; el mínimo 1 es inferido de la idea
  de venta con al menos un renglón, pero no hay una regla formal que impida un comprobante vacío. B→A:
  mínimo 0 inferido (un vino puede no venderse nunca); máximo N.
- **Aclaración:** los asteriscos indican que el mínimo de negocio y el máximo N son inferidos/provisionales.
  Si se admitiera un comprobante vacío, el mínimo podría ser 0; no se decide. Es una N:M con atributos
  propios; no se decide si se dibuja como entidad asociativa o relación. Ver AMB-10a, D-2 y D-9.

#### REL-15 — Cliente–Socio / Distribuidor / Exportador

- **Participantes:** Cliente (A) como supertipo y Socio, Distribuidor y Exportador (B) como subtipos.
- **Cardinalidad:** A **no determinada**; B `1*..1*` cliente, como supuesto de trabajo.
- **Clasificación:** J.
- **Respaldo:** «Existen tres tipos de cliente: • Socios del club… • Distribuidores… • Exportadores…»
  (p. 5, §3.4). La sección 5 indica «Supertipo de una jerarquía con 3 subtipos» y exige «Decidir y
  justificar la estrategia de mapeo» (p. 7, §5).
- **Justificación:** B→A: cada fila de subtipo representa un cliente; se toma como supuesto de herencia,
  no como decisión cerrada. A→B: no se puede fijar cardinalidad sin saber si la jerarquía es total o
  parcial y si es disjunta o solapada. Las alternativas son `1..1`, `1..N`, `0..1` o `0..N`.
- **Aclaración:** el supuesto de trabajo cubre ambos extremos (`1*..1*`) y no decide totalidad, exclusividad
  ni mapeo. Un cliente podría, en principio, no tener subtipo, tener exactamente uno o tener más de uno; el
  texto no lo aclara. Ver AMB-07, D-1 y Q-04.

#### REL-16 — Exportador–Permiso de exportación

- **Participantes:** Exportador (A) y Permiso de exportación (B).
- **Cardinalidad:** A `0..N` permisos; B `1*..1` exportador.
- **Clasificación:** P.
- **Respaldo:** «Un exportador puede tener varios permisos; de cada uno se conoce el código, la fecha de
  emisión y la fecha de vencimiento.» (p. 5, §3.4). La sección 5 observa «Varios por exportador»
  (p. 7, §5) y RN-07 exige que el vencimiento sea posterior a la emisión (p. 6).
- **Justificación:** B→A: el vínculo posesivo y «de cada uno» permiten inferir que cada permiso pertenece a
  un exportador; el mínimo 1 es inferido. A→B: el mínimo 0 está respaldado por «puede tener»; el máximo N
  es la lectura abierta de «varios», no un máximo cuantificado expresamente.
- **Aclaración:** no se declara que un permiso pueda compartirse entre exportadores. El estado
  vigente/vencido es derivado y no afecta la cardinalidad. Ver AMB-08 y Q-12.

### 3.5 Logística, depósito y comercialización

#### REL-17 — Transportista–Localidad (cobertura)

- **Participantes:** Transportista (A) y Localidad (B).
- **Cardinalidad:** A `0*..N` localidades; B `0*..N` transportistas.
- **Clasificación:** P.
- **Respaldo:** «Además, se debe conocer a qué localidades alcanza el servicio de cada transportista.»
  (p. 5, §3.5). La sección 5 observa «N:M» (p. 7, §5); I1 inserta una nueva cobertura (p. 21, §8.2).
- **Justificación:** máximo N en ambos extremos por la N:M y por «localidades» en plural. Mínimo 0 en
  ambos: no se declara que todo transportista deba cubrir al menos una localidad ni que toda localidad
  deba estar cubierta.
- **Aclaración:** la cobertura del transportista no es la zona del distribuidor; son conceptos distintos.
  La distinción está resuelta en A-02 R-11 (AMB-15, resuelta); la cobertura sigue abierta en AMB-09.

#### REL-18 — Bodega–Ingreso

- **Participantes:** Bodega (A) e Ingreso (B).
- **Cardinalidad:** A `0*..N` ingresos; B `1..1` bodega.
- **Clasificación:** P.
- **Respaldo:** «De cada ingreso se registra: código de ingreso, fecha, estado, transportista que efectuó
  el traslado y bodega de origen.» (p. 5, §3.5). La sección 5 lista «bodega» entre los datos del ingreso
  (p. 7, §5).
- **Justificación:** B→A: cada ingreso tiene una bodega de origen; está expreso. A→B: máximo N propio de
  la relación; mínimo 0 inferido, porque no toda bodega debe tener ingresos.
- **Aclaración:** la bodega de origen del ingreso es un rol distinto de la bodega destino del lote y de la
  bodega elaboradora del vino. Ver AMB-06 y AMB-14.

#### REL-19 — Transportista–Ingreso

- **Participantes:** Transportista (A) e Ingreso (B).
- **Cardinalidad:** A `0*..N` ingresos; B `1..1` transportista.
- **Clasificación:** P.
- **Respaldo:** «De cada ingreso se registra: código de ingreso, fecha, estado, transportista que efectuó
  el traslado y bodega de origen.» (p. 5, §3.5). La sección 5 lista «transportista» entre los datos del
  ingreso (p. 7, §5).
- **Justificación:** B→A: cada ingreso registra un transportista; está expreso. A→B: máximo N propio de la
  relación; mínimo 0 inferido, porque no todo transportista debe tener ingresos.
- **Aclaración:** no se prevé una excepción de transporte interno; si existiera, requeriría confirmación y
  no se inventa. Ver AMB-14.

#### REL-20 — Ingreso–Vino (Renglón de ingreso)

- **Participantes:** Ingreso (A) y Vino (B), mediante el renglón de ingreso.
- **Cardinalidad:** A `1*..N*` vinos; B `0*..N` ingresos.
- **Clasificación:** P.
- **Respaldo:** «Cada ingreso contiene un conjunto de vinos con su cantidad de botellas.» (p. 5, §3.5).
  La sección 5 lista «vino y cantidad» (p. 7, §5); RN-12 bloquea cambios de renglones fuera de
  `en_confeccion` (p. 6).
- **Justificación:** A→B: el máximo N se infiere de «conjunto de vinos»; el mínimo 1 es inferido de la idea
  de ingreso con contenido, pero no hay regla formal que exija al menos un renglón. B→A: mínimo 0 inferido
  (un vino puede no ingresar nunca); máximo N.
- **Aclaración:** en estado `en_confeccion` el ingreso puede estar transitoriamente sin renglones; no se
  usa ese estado para fijar el mínimo de negocio. Es una N:M con cantidad; no se decide su materialización.
  Ver AMB-10b, AMB-14, D-2 y D-9.

#### REL-21 — Sala de venta–Transferencia

- **Participantes:** Sala de venta (A) y Transferencia (B).
- **Cardinalidad:** A `0*..N` transferencias; B `1..1` sala.
- **Clasificación:** P.
- **Respaldo:** «Cada sala que necesite vinos los debe requerir al depósito central por medio de
  TRANSFERENCIAS, que contienen: número de solicitud, sala solicitante y fecha de confección…»
  (p. 5, §3.5). La sección 5 lista «sala» entre los datos de la transferencia (p. 8, §5).
- **Justificación:** B→A: cada transferencia tiene una sala solicitante; está expreso. A→B: máximo N
  propio de la relación; mínimo 0 inferido, porque una sala puede no solicitar transferencias.
- **Aclaración:** no se declara que toda sala deba tener al menos una transferencia. Ver AMB-14.

#### REL-22 — Transferencia–Vino (Renglón de transferencia)

- **Participantes:** Transferencia (A) y Vino (B), mediante el renglón de transferencia.
- **Cardinalidad:** A `1*..N*` vinos; B `0*..N` transferencias.
- **Clasificación:** P.
- **Respaldo:** «Cada transferencia contiene un conjunto de vinos con su cantidad y tiene un estado…»
  (p. 5, §3.5). La sección 5 lista «vino y cantidad» (p. 8, §5); RN-11 y RN-12 regulan estado y renglones
  (p. 6).
- **Justificación:** A→B: el máximo N se infiere de «conjunto de vinos»; el mínimo 1 es inferido de la idea
  de transferencia con contenido. B→A: mínimo 0 inferido (un vino puede no transferirse nunca); máximo N.
- **Aclaración:** en `en_confeccion` puede estar transitoriamente sin renglones; no se usa ese estado para
  fijar el mínimo de negocio. Es una N:M con cantidad. Ver AMB-10b, AMB-14, D-2 y D-9.

#### REL-23 — Sala de venta–Vino (Stock de sala)

- **Participantes:** Sala de venta (A) y Vino (B), mediante la fila de stock de sala.
- **Cardinalidad:** A `0*..N` vinos; B `0*..N` salas.
- **Clasificación:** P.
- **Respaldo:** «Para poder efectivizar una venta, cada sala posee su stock de cada vino.» (p. 5, §3.5).
  La sección 5 lista «Sala, vino, cantidad» y «cantidad >= 0» (p. 7, §5); RN-09 exige stock no negativo
  (p. 6).
- **Justificación:** máximo N en ambos extremos por la relación de inventario. Mínimo 0 en ambos: una sala
  puede no tener stock de un vino y un vino puede no estar en una sala; no se declara una fila universal
  para todo par.
- **Aclaración:** una fila inexistente no equivale a una fila con cantidad 0. La ausencia puede significar
  «sin registro de stock»; la cantidad 0 significa «registrado con existencia cero». S6 no demuestra que
  la ausencia de fila sea válida: solo compara vinos sin stock en sala con stock en el depósito. No se
  decide si debe existir fila para todo par. Ver AMB-11 y D-3.

#### REL-24 — Vino–Stock de depósito

- **Participantes:** Vino (A) y Stock de depósito (B), entendido como una fila/instancia de ese stock.
- **Cardinalidad:** `Vino 0*..1 — 1..1 Stock de depósito`, es decir, A `0*..1`; B `1..1` vino.
- **Clasificación:** P.
- **Respaldo:** «La empresa cuenta con un depósito central… El depósito tiene su propio stock por vino.»
  (p. 5, §3.5). La sección 5 observa «Un solo depósito central; cantidad >= 0» (p. 8, §5). S6 compara
  vinos sin stock en sala con stock en el depósito (p. 22, §8.4).
- **Justificación:** A→B: máximo 1 porque hay un solo depósito y su stock se lleva por vino; mínimo 0
  porque un vino puede no tener fila de stock en el depósito. B→A: cada fila de stock corresponde a un
  único vino; mínimo 1 y máximo 1.
- **Aclaración:** «fila» designa una instancia de Stock de depósito, no una entidad distinta. Ausencia de
  fila ≠ cantidad 0. S6 no determina si la ausencia de fila es válida; solo compara stock de sala con stock
  de depósito. Si el negocio exigiera una fila para todo vino, el mínimo sería 1; no está declarado. No hay
  una entidad Depósito con varias filas; el stock de depósito es el registro de existencia del vino en el
  único depósito. Ver AMB-11 y D-3.

#### REL-25 — Vino–Auditoría de precio

- **Participantes:** Vino (A) y Auditoría de precio (B).
- **Cardinalidad:** A `0*..N` auditorías; B `1..1` vino.
- **Clasificación:** P.
- **Respaldo:** La sección 5 lista «Auditoría de precio: ID, vino, precio anterior, precio nuevo, fecha y
  hora, usuario» y observa «La completa un trigger» (p. 8, §5). RN-13 exige auditar todo cambio de precio
  (p. 6).
- **Justificación:** B→A: cada fila de auditoría corresponde a un vino; está expreso. A→B: mínimo 0
  inferido, porque un vino puede no haber cambiado nunca de precio; máximo N, porque cada cambio genera
  una fila.
- **Aclaración:** el mínimo 0 es una **inferencia**, no una regla respaldada: RN-13 exige auditar todo
  cambio de precio, pero no exige que todo vino haya cambiado alguna vez. No se decide si el alta de un vino
  genera auditoría; RN-13 habla de cambio de precio, no de inserción. El usuario auditado es Q-07; la
  presencia de la entidad en el modelo es D-10.

---

## 4. Ambigüedades AMB-01 a AMB-17 y decisiones resueltas

| ID | Ambigüedad | Relaciones afectadas | Fundamento y estado |
|---|---|---|---|
| AMB-01 | ¿Toda Localidad debe tener al menos una Sala? | REL-01 | El texto solo dice que una localidad puede tener más de una sala; no declara un mínimo. Se propone `0*..N`; `1..N` requeriría una regla adicional. Pendiente. |
| AMB-02 | ¿«Varios empleados» significa ≥2? ¿Cómo se representa una sala recién creada? | REL-02 | La lectura literal de «varios» es más de uno; no hay una regla numérica formal. El alta de una sala sin empleados es un estado transitorio. Alternativas: `2*..N`, `1..N` si «varios» es coloquial, o `0..N` si se modelan estados transitorios. `2*..N` no se adopta como definitiva para el DER. Pendiente. |
| AMB-03 | ¿Toda Finca debe tener al menos una Parcela? | REL-04 | «Cada finca se divide en parcelas» sugiere `1*..N`, pero no cuantifica formalmente. Podría ser `0..N` si se admite una finca sin subdividir, o `2..N` si «parcelas» se lee como plural estricto. Pendiente. |
| AMB-04a | ¿Toda Localidad debe tener al menos un Cliente? | REL-03 | Se guarda la localidad del cliente, pero no se declara un mínimo de clientes por localidad. El mínimo 0 del lado Localidad es inferido. Pendiente. |
| AMB-04b | ¿El Cliente debe comprar en una Sala de su Localidad? | REL-01, REL-03, REL-12, REL-13 | No hay regla que relacione la localidad del cliente con la localidad de la sala; el vínculo Cliente–Sala es indirecto a través de Comprobante. Si se exigiera, afectaría estas relaciones. Pendiente. |
| AMB-05 | ¿Una Bodega puede existir sin Vinos? | REL-09 | «Una bodega elabora varios vinos» sugiere mínimo 2, pero no es una regla formal. I4 permite insertar una bodega antes de cargar vinos; eso no demuestra que una bodega vacía sea un estado final válido. Alternativas `2*..N`, `1..N` o `0..N`; `2*..N` no se adopta como definitiva para el DER. Pendiente. |
| AMB-06 | ¿La bodega destino del Lote, la elaboradora del Vino y la origen del Ingreso son la misma? | REL-07, REL-09, REL-18 | El texto usa «bodega» en tres roles; no impone igualdad. Se modelan como tres vínculos separados. Pendiente; no se infiere identidad. |
| AMB-07 | Jerarquía Cliente: ¿es total y disjunta? | REL-15 | No se declara si todo cliente tiene subtipo, ni si los subtipos son excluyentes. Alternativas: `1..1`, `1..N`, `0..1` o `0..N` desde Cliente. El lado Subtipo→Cliente se toma como `1*..1*` solo como supuesto de trabajo: ambos extremos son inferidos, no confirmados. Ver D-1 y Q-04. Pendiente. |
| AMB-08 | ¿Todo Exportador tiene al menos un Permiso? ¿Un Permiso puede pertenecer a varios exportadores? | REL-16 | «Puede tener varios» permite cero; no se declara un mínimo. El texto presenta los permisos como del exportador, pero no discute compartición. Se propone `0..N` y `1*..1`; pendiente de confirmación. |
| AMB-09 | ¿Todo Transportista cubre al menos una Localidad? ¿Toda Localidad está cubierta? | REL-17 | El texto solo exige conocer «a qué localidades alcanza»; no fija mínimos. Se propone `0*..N` en ambos extremos. Pendiente. |
| AMB-10a | ¿Un Comprobante puede existir sin renglones? | REL-14 | «Contiene un conjunto de vinos» sugiere al menos uno, pero no hay una regla formal. RN-12 no regula Comprobante. La posibilidad de un comprobante vacío queda abierta; el mínimo de negocio se propone `1*..N*`. Pendiente. |
| AMB-10b | ¿Un Ingreso o una Transferencia pueden quedar vacíos y, si sí, en qué estado? | REL-20, REL-22 | «Contiene un conjunto» sugiere al menos uno, pero no hay una regla formal. RN-12 solo prohíbe agregar, modificar o quitar renglones fuera de `en_confeccion`; no declara si un documento vacío es válido como estado final. La propuesta `1*..N*` no se adopta como definitiva. La relación entre estado y renglones se trata en AMB-14. Pendiente. |
| AMB-11 | ¿Debe existir una fila de stock por cada par Sala–Vino y por cada Vino en el depósito? ¿Qué significa una fila ausente? | REL-23, REL-24 | El texto dice «stock de cada vino», pero S6 no distingue una fila ausente de una cantidad cero ni determina si la ausencia es válida. Fila ausente ≠ cantidad cero. No se declara una fila universal. Pendiente; ver D-3. |
| AMB-12 | ¿La cepa de una Parcela es solo la actual o debe conservarse historia de replantaciones? | REL-05 | §3.2 asigna una sola cepa; no hay historia. Si una parcela se replanta, la relación podría cambiar, pero no se especifica. Pendiente; ver D-7. |
| AMB-13 | ¿Puede haber dos Análisis del mismo Lote en la misma fecha? ¿Cómo se identifica cada análisis? | REL-08 | La relación `Lote 1..N* Análisis` es clara, pero la identidad del análisis y la posibilidad de duplicados diarios no están declaradas. Pendiente; ver D-6 y Q-06. |
| AMB-14 | ¿Cómo se relaciona el estado del documento con la exigencia de renglones y con las entidades sin actividad? | REL-13, REL-18, REL-19, REL-20, REL-21, REL-22 | RN-12 solo permite agregar, modificar o quitar renglones en `en_confeccion`, pero no fija el mínimo de negocio ni el estado final válido. Salas, bodegas y transportistas pueden no tener actividad como estado transitorio de alta. No se usa ese estado para fijar el mínimo de negocio. La validez y el estado de un documento vacío se preguntan en AMB-10a y AMB-10b; aquí se trata la relación estado–renglones. Pendiente. |
| AMB-16 | ¿Todo Maridaje debe estar recomendado por al menos un Vino? | REL-11 | «Cada vino tiene uno o más maridajes» fija el mínimo del lado Vino, pero no exige que todo maridaje del catálogo esté asociado. El mínimo 0 del lado Maridaje es inferido. Pendiente. |
| AMB-17 | ¿Toda Bodega debe tener al menos un Lote recibido? | REL-07 | El texto dice que los lotes se entregan a una bodega, pero no fija un mínimo de lotes por bodega. I4 permite el alta de una bodega sin actividad. El mínimo 0 es inferido. Pendiente. |

### 4.1 Decisiones resueltas

| ID | Tema | Relaciones | Resolución |
|---|---|---|---|
| AMB-15 (resuelta) | ¿La cobertura del Transportista y la zona del Distribuidor son el mismo concepto? | REL-17 | **No.** La cobertura es una relación N:M con Localidad; la zona es un atributo del subtipo Distribuidor. No se unifican. Resuelta por la redundancia R-11 de A-02; no es una ambigüedad abierta. |

---

## 5. Cruce con D-1 a D-10 y Q-01 a Q-13

| Duda | Tema | Relaciones o ambigüedades afectadas | Tratamiento en A-04 |
|---|---|---|---|
| D-1 | Mapeo de la jerarquía Cliente | REL-15, AMB-07 | No se decide; la cardinalidad Cliente→subtipo queda no determinada. |
| D-2 | Renglones y stocks: débil vs. asociativa | REL-14, REL-20, REL-22, REL-23; AMB-10a, AMB-10b, AMB-11 | REL-14, REL-20, REL-22 y REL-23 se describen como N:M; no se decide su materialización. |
| D-3 | Separación del stock de depósito | REL-23, REL-24; AMB-11 | Se mantiene la separación conceptual; REL-24 es 1:1 opcional; no se decide si existe una fila universal. |
| D-4 | Encargado regional | Sin relación propia | Es atributo de Localidad en A-01/A-02; no genera una relación en A-04. |
| D-5 | Campaña como catálogo | REL-06 | La campaña se usa como atributo del Lote; no se crea una relación Campaña–Lote. |
| D-6 | Identidad del Análisis de calidad | REL-08, AMB-13 | La relación se mantiene; la identidad de la fila sigue abierta. |
| D-7 | Tabla intermedia parcela–cepa | REL-05, AMB-12 | No se agrega relación ni entidad intermedia; no se modela historia de plantación. |
| D-8 | Transportista en el comprobante | Relación descartada | No hay respaldo textual; no se incorpora. |
| D-9 | N:M como entidad o relación | REL-10, REL-11, REL-14, REL-17, REL-20, REL-22, REL-23 | Se conserva la N:M conceptual; no se elige notación definitiva. |
| D-10 | Auditoría en el DER conceptual | REL-25 | Se incluye como relación; no se decide su tratamiento gráfico final. |
| Q-01 | Descuento: atributo vs. función | REL-12, REL-14 | No cambia cardinalidades; es un atributo/derivado del cliente o del renglón. |
| Q-02 | Identidad del Lote | REL-06, REL-07, REL-08 | No cambia las cardinalidades; la identidad y numeración siguen abiertas. |
| Q-03 | Fecha del Ingreso | REL-18, REL-19, REL-20; AMB-14 | No cambia las cardinalidades; la semántica temporal sigue abierta. |
| Q-04 | Nombre del Cliente y jerarquía | REL-15, AMB-07 | No se decide la forma del nombre ni el mapeo. |
| Q-05 | Descuento del renglón: porcentaje o importe | REL-14 | No cambia la relación ni sus extremos. |
| Q-06 | Identidad del Análisis | REL-08, AMB-13 | No se resuelve; la relación se mantiene. |
| Q-07 | Usuario de la auditoría | REL-25 | No cambia la cardinalidad; el origen del usuario sigue abierto. |
| Q-08 | Salario positivo | Sin relación | Es un atributo de Empleado; no afecta A-04. |
| Q-09 | Dominio de `dia_cierre` | Sin relación | Es un atributo de Sala; no afecta cardinalidades. |
| Q-10 | Direcciones desglosadas | Sin relación directa | Es una decisión de atributos de Sala o Cliente; no modifica cardinalidades de A-04. |
| Q-11 | Departamento/provincia como catálogo | Sin relación directa | Es una decisión de atributos de Localidad o Finca; no modifica cardinalidades de A-04. |
| Q-12 | Estado del Permiso | REL-16 | No cambia la cardinalidad; el estado es derivado. |
| Q-13 | Atributos extra de stock | REL-23, REL-24 | No cambian los extremos; no se agregan atributos. |

---

## 6. Relaciones consideradas y descartadas

| Relación considerada | Tratamiento | Motivo |
|---|---|---|
| Lote–Vino | Descartada | La consigna relaciona Lote con Bodega y Vino con Bodega, pero no declara trazabilidad lote→vino. No se infiere. |
| Cliente–Sala directa | Descartada | El vínculo es a través de Comprobante. No se declara que el cliente deba comprar en la sala de su localidad. |
| Comprobante–Transportista | Descartada | §3.4 no menciona transportista en la venta; coincide con D-8 de A-01. |
| Empleado–Localidad | No directa | Se obtiene por Empleado→Sala→Localidad. |
| Cepa–Lote | No directa | Se obtiene por Lote→Parcela→Cepa. |
| Finca–Bodega | No directa | Se obtiene por Finca→Parcela→Lote→Bodega. |
| Bodega–Depósito | No directa | No hay entidad Depósito; el vínculo operativo pasa por Ingreso y Stock de depósito. |
| Campaña–Lote | No modelada como relación | La campaña es un atributo del Lote; D-5 sigue abierto. |
| Vino–Sala por venta | No directa | Se deriva de Comprobante–Vino; el stock de sala es una relación distinta. |
| Permiso–Cliente general | No directa | El permiso se asocia al subtipo Exportador, no a cualquier Cliente. |
| Transportista–Sala o Transportista–Cliente | Descartada | No hay respaldo textual; el transportista se vincula con Ingreso y con Localidad por cobertura. |
| Análisis–Parcela | No directa | El análisis se practica sobre el Lote, no directamente sobre la Parcela. |
| Depósito–Stock | No modelada | No hay entidad Depósito; el stock de depósito se representa por vino. |

No se agregó ninguna relación por conveniencia técnica. Las relaciones que no tienen respaldo suficiente
quedan fuera hasta que exista una decisión o una consulta al docente.

---

## 7. Resumen de decisiones respaldadas, inferencias y pendientes

### 7.1 Clasificación de las 25 relaciones

| Clasificación | Relaciones | Total |
|---|---|---|
| C — respaldo textual claro | — | 0 |
| P — parcial, inferida o pendiente | REL-01, REL-02, REL-03, REL-04, REL-05, REL-06, REL-07, REL-08, REL-09, REL-10, REL-11, REL-12, REL-13, REL-14, REL-16, REL-17, REL-18, REL-19, REL-20, REL-21, REL-22, REL-23, REL-24, REL-25 | 24 |
| J — jerarquía | REL-15 | 1 |

### 7.2 Decisiones con respaldo textual

- Cada Sala pertenece a una sola Localidad; cada Empleado a una sola Sala; cada Parcela a una sola Finca
  y tiene una sola Cepa; cada Lote se origina en una Parcela y se entrega a una Bodega; cada Vino lo
  elabora una Bodega; cada Comprobante tiene un Cliente y una Sala; cada Ingreso tiene una Bodega y un
  Transportista; cada Transferencia tiene una Sala.
- Los mínimos 1 de Lote–Análisis, Vino–Cepa y Vino–Maridaje están expresos en «uno o más», «una o más
  cepas» y «cada vino tiene uno o más maridajes». Los máximos N no están cuantificados expresamente: se
  infieren de la lectura abierta de «uno o más», de «Varios análisis por lote» y de la N:M.
- REL-12: el mínimo 0 está respaldado indirectamente por D4/D6, que contemplan **socios** sin compras; no
  establecen el mínimo 0 para todos los clientes ni el máximo N del lado Cliente. Ambos extremos se
  mantienen como inferidos/provisionales.

### 7.3 Inferencias principales

- REL-02: `Sala 2*..N` y REL-09: `Bodega 2*..N`; el 2 se infiere de «varios» en lectura literal, no de
  una regla numérica formal. **El mínimo no se traslada como definitivo al DER** hasta decidir si es
  regla formal, inmediata o diferida; no se reemplaza automáticamente por `1..N` ni por `0..N`.
- REL-04: `Finca 1*..N`; el mínimo 1 se infiere de «cada finca se divide en parcelas».
- REL-03, REL-06, REL-08, REL-15 y REL-16: el mínimo 1 inferido se marca junto a ese extremo; en REL-08
  también los dos extremos del lado Lote, y en REL-15 ambos extremos del supuesto de trabajo.
- REL-01, REL-07 y REL-12: el mínimo 0 inferido se escribe `0*..`; en REL-12 también el máximo N es
  inferido (`0*..N*`).
- REL-05, REL-10 y REL-11: los mínimos 1 de Parcela→Cepa, Vino→Cepa y Vino→Maridaje son explícitos; los
  extremos Cepa→Parcela (`0*..N*`), Cepa→Vino (`0*..N`) y Maridaje→Vino (`0*..N`) son inferidos o
  indirectos.
- REL-14, REL-20 y REL-22: `1*..N*` refleja que el mínimo de negocio y el máximo de renglones son
  inferidos para un documento con contenido; el estado transitorio sin renglones no se usa para fijar el
  mínimo final.
- REL-23 y REL-24: los mínimos 0 son inferidos y se escriben `0*..`; una fila ausente no equivale a
  cantidad cero. S6 no determina si la ausencia de fila es válida.
- REL-25: el mínimo 0 es inferido y se escribe `0*..N`; RN-13 no exige una auditoría por vino ni demuestra
  que todo vino haya cambiado de precio.

### 7.4 Cuestiones pendientes

- Las **18 ambigüedades abiertas**: AMB-01, AMB-02, AMB-03, AMB-04a, AMB-04b, AMB-05, AMB-06, AMB-07,
  AMB-08, AMB-09, AMB-10a, AMB-10b, AMB-11, AMB-12, AMB-13, AMB-14, AMB-16 y AMB-17.
- **AMB-15 está resuelta** por A-02 R-11: cobertura del transportista y zona del distribuidor son
  conceptos distintos.
- Totalidad y exclusividad de la jerarquía Cliente (D-1, Q-04).
- Si una bodega, sala, finca o localidad puede existir sin sus entidades relacionadas (AMB-01, AMB-03,
  AMB-04a, AMB-05, AMB-17).
- Si el cliente debe comprar en una sala de su propia localidad (AMB-04b).
- Si el mínimo 2 de empleados por sala y de vinos por bodega es una regla formal, inmediata o diferida
  (AMB-02, AMB-05); el mínimo no está determinado para el DER.
- Si los documentos pueden existir sin renglones (AMB-10a, AMB-10b).
- Si todo maridaje del catálogo debe estar recomendado por al menos un vino (AMB-16).
- Si debe existir una fila de stock para todo par Sala–Vino o para todo Vino en el depósito (AMB-11).
- Si la bodega destino del Lote, la elaboradora del Vino y la origen del Ingreso deben coincidir
  (AMB-06).
- La identidad del Análisis (D-6, Q-06), la identidad del Lote (Q-02), la semántica del Ingreso (Q-03)
  y el usuario de la auditoría (Q-07).

No se eligieron claves primarias ni foráneas, no se definió el DER definitivo y no se resolvieron las
dudas que requieren confirmación del docente o del equipo.

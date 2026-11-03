# A-01 — Entidades candidatas del modelo de datos

> Issue A-01 · Responsable: Persona A · Estado: borrador conceptual (pre-DER)
> Fuente: `docs/Consigna/TPI_Bodegas_del_Atuel.pdf` (secciones 3, 4 y 5) y `docs/requisitos.md`.
> Convención: los números de página del PDF no se pudieron verificar con certeza, por lo que se cita
> la **sección numerada** del documento. Todo lo que sea interpretación propia se marca `[Inferencia]`.

---

## 1. Objetivo

Este documento identifica y justifica las **entidades candidatas** del negocio «Bodegas del Atuel»,
como primer paso del diseño conceptual (etapa 1 del TPI). Su alcance es deliberadamente limitado:

- Se listan las entidades y se explica qué representan y por qué deben existir como entidades independientes.
- **No** se definen claves primarias ni foráneas, cardinalidades, atributos completos con tipos de datos
  ni relaciones (eso corresponde a A-02 y a las etapas siguientes).
- **No** se crean tablas SQL ni se elabora el DER.

La lista se apoya en tres fuentes de la consigna:
1. Los **procesos** del negocio (sección 3 del PDF).
2. Las **reglas de negocio RN-01 a RN-15** (sección 4 del PDF).
3. La tabla de **entidades mínimas** de la sección 5 del PDF, cuyo exacto cumplimiento exige el
   criterio de aceptación de la etapa 1: «Todas las entidades de la sección 5 están representadas».

La sección 5 aclara que los atributos y claves listados son «una guía: el grupo puede agregar los que
considere necesarios y debe justificar sus decisiones». Por eso este documento solo agrega conceptos
adicionales cuando hay respaldo textual en el escenario, las reglas o las consultas del PDF.

---

## 2. Entidades candidatas identificadas

Para cada entidad se indica: qué representa en el negocio, qué información propia necesita a nivel
conceptual, por qué merece ser una entidad independiente, y qué parte de la consigna la respalda.

### 2.1 Localidad

- **Qué representa:** localidad geográfica donde hay salas de venta (y viven o actúan clientes).
- **Información propia:** código postal, nombre, provincia, encargado regional.
- **Por qué entidad independiente:** es el punto de referencia de las salas (3.1), de los clientes
  (3.4) y de la cobertura de transportistas (3.5). El encargado regional es una **propiedad de la
  localidad**, no de la sala: RN-02 («Cada localidad tiene un único encargado regional») y el paso 4
  de la etapa 1 usan como ejemplo de dependencia funcional `localidad → encargado regional`. Si el
  encargado se guardara en cada sala, la relación quedaría repetida (dependencia parcial/transitiva).
- **Respaldo:** sección 5, primera fila («El encargado depende de la localidad»); sección 3.1; RN-02.

### 2.2 Sala de venta

- **Qué representa:** punto de venta de la red, ubicado en una localidad.
- **Información propia:** ID, calle, número, día de cierre semanal.
- **Por qué entidad independiente:** en ella trabajan empleados, se emiten comprobantes, se solicitan
  transferencias y se gestiona su propia existencia de stock. Es un objeto con existencia propia, no
  un atributo de otro concepto. Una localidad puede tener varias salas (3.1), lo que descarta tratarla
  como subdato de la localidad.
- **Respaldo:** sección 5; sección 3.1; RN-02, RN-03, RN-09, RN-11.

### 2.3 Empleado

- **Qué representa:** persona que trabaja en una sala de venta.
- **Información propia:** CUIT, nombre, fecha de ingreso laboral, salario.
- **Por qué entidad independiente:** tiene identidad propia (CUIT) y atributos propios. La operación
  U2 («aumentar 20 % el salario de empleados con más de 5 años de antigüedad») exige conservar la
  fecha de ingreso por cada empleado. RN-03 fija su vínculo con una única sala.
- **Respaldo:** sección 5; sección 3.1; RN-03; U2; función `fn_antiguedad_anios` (etapa 2).

### 2.4 Finca

- **Qué representa:** establecimiento agrícola donde la empresa cultiva uva.
- **Información propia:** ID, nombre, superficie total en hectáreas, departamento y provincia de ubicación.
- **Por qué entidad independiente:** es el contenedor de las parcelas; la superficie total es su dato
  propio, distinto de la suma de parcelas (valor derivable, no almacenado). La consulta S10 compara el
  rendimiento kg/ha de cada parcela con el promedio **de su finca**, lo que exige agrupar por finca.
- **Respaldo:** sección 5; sección 3.2; S10.

### 2.5 Parcela — **entidad débil declarada por la consigna**

- **Qué representa:** subdivisión de una finca donde se planta una cepa.
- **Información propia:** número de parcela (identificador relativo **dentro de la finca**),
  superficie, año de plantación, cepa plantada (una sola).
- **Por qué entidad independiente (y débil):** el texto de 3.2 es explícito: las parcelas se
  «identifican por un número dentro de la finca: una parcela no existe sin su finca». Eso es la
  definición clásica de entidad débil: identificación dependiente de la propietaria. La sección 5 la
  declara «Entidad débil: clave (finca, n.° de parcela)» y la etapa 1 exige dibujarla así («la entidad
  débil Parcela», etapa 1, paso 2). Una finca se divide en **varias** parcelas (1:N con dependencia).
- **Respaldo:** secciones 3.2 y 5; RN-04; etapa 1, paso 2.
- **Nota:** la cepa plantada es una propiedad de la parcela (RN-04: una sola cepa por parcela). No
  proponemos entidad intermedia tipo «plantación» porque el texto no le asigna atributos más allá de
  ese vínculo directo (duda registrada en §6, D-7).

### 2.6 Cepa (catálogo)

- **Qué representa:** variedad de vid (Malbec, Chardonnay, …) con su tipo tinta/blanca.
- **Información propia:** nombre, tipo (tinta o blanca).
- **Por qué entidad independiente (catálogo):** es compartida desde dos áreas muy distintas del
  negocio: las parcelas (2.5) y la composición de vinos (2.11). La consulta D2 confirma ese doble rol
  («eliminar las cepas que no componen ningún vino ni están plantadas en ninguna parcela»). El
  Anexo B lista cepas reales para cargar desde CSV, lo que confirma su rol catálogo cerrado.
- **Respaldo:** sección 5 («Catálogo real»); sección 3.2; Anexo B; D2.

### 2.7 Lote de uva

- **Qué representa:** resultado de la cosecha de una parcela en una campaña (año), entregado a una bodega.
- **Información propia:** número de lote, fecha de cosecha, kilos cosechados, bodega destino.
- **Por qué entidad independiente:** es el puente entre la producción agrícola y la elaboración. Los
  análisis de calidad (2.8) se practican sobre **el lote** y la consulta S10 calcula rendimiento
  kilos/hectárea a partir de sus kilos. RN-04 garantiza que cada cosecha es un suceso identificable
  por (parcela, campaña) y la sección 5 le da su propia identidad («N.° de lote…»).
- **Respaldo:** sección 5; sección 3.2; RN-04; S10.

### 2.8 Análisis de calidad

- **Qué representa:** medición de calidad practicada a un lote de uva.
- **Información propia:** fecha, grado Brix, pH, acidez total (g/L).
- **Por qué entidad independiente:** «A cada lote se le practican **uno o más** análisis» (3.2) y la
  tabla de la sección 5 dice «Varios análisis por lote»: es una relación 1:N con atributos propios,
  lo que exige filas distintas por análisis. Sin entidad propia no podría guardarse más de un análisis
  por lote.
- **Respaldo:** secciones 3.2 y 5.
- **Duda abierta:** la sección 5 le asigna un «ID» (¿clave propia o solo identificador de la fila?).
  Se decide al pasar a esquema relacional (§6, D-6).

### 2.9 Bodega

- **Qué representa:** establecimiento elaborador de vinos del grupo.
- **Información propia:** CUIT, razón social, domicilio.
- **Por qué entidad independiente:** recibe lotes, elabora vinos y origina ingresos al depósito. RN-14
  prohíbe borrarla si tiene movimientos asociados, y la operación I4 da de alta bodegas nuevas: la
  cátedra la trata como objeto de gestión autónomo. «Una bodega elabora varios vinos» (3.3).
- **Respaldo:** sección 5; sección 3.3; RN-14; RN-10; I4.

### 2.10 Vino

- **Qué representa:** producto embotellado que la red vende.
- **Información propia:** código, nombre comercial, tipo (tinto, blanco, rosado, espumante), añada,
  volumen en ml, graduación alcohólica, precio de venta (único para toda la red y > 0: RN-01).
- **Por qué entidad independiente:** es la pieza central de la comercialización: existe en
  comprobantes, ingresos, transferencias, los dos stocks y la auditoría de precio. El `UNIQUE
  (nombre, anada, volumen_ml)` permite distinguir «versiones» (misma receta con distinta añada o
  presentación) como filas distintas, tal como piden 3.3 («consultar… vinos con el mismo nombre y
  distinta añada o presentación») y la sección 7 (etapa 2). Ejemplo textual: «Malbec Reserva»,
  añada 2021, 750 ml, $12.500, 14°.
- **Respaldo:** sección 5; sección 3.3; RN-01, RN-13, RN-14, RN-15; etapa 2 (filas UNIQUE); CRUD `/vinos` (API).

### 2.11 Composición (vino–cepa) — **candidata a entidad asociativa con atributo**

- **Qué representa:** el vínculo entre un vino y las cepas que lo componen, con un dato propio: el
  **porcentaje de corte** de cada cepa en ese vino.
- **Información propia:** porcentaje de corte (los porcentajes de un vino deben sumar 100: RN-05).
- **Por qué se lista como entidad candidata:** es la relación N:M clásica entre Vino y Cepa, pero
  **tiene un atributo propio consignado por la consigna** (3.3: «compuesto por una o más cepas, cada
  una en un determinado porcentaje de corte»), por lo que la sección 5 la lista como entidad
  («N:M con atributo; suma 100 por vino») y la etapa 1 exige dibujar en el DER las «relaciones N:M
  con atributos (composición, renglón de comprobante, etc.)».
- **Respaldo:** secciones 3.3 y 5; RN-05; etapa 1, paso 2.

### 2.12 Maridaje (catálogo)

- **Qué representa:** tipo de acompañamiento gastronómico recomendado («carnes rojas», etc.) con su
  temperatura de servicio sugerida.
- **Información propia:** nombre, temperatura de servicio en °C.
- **Por qué entidad independiente (catálogo):** «un maridaje puede repetirse para distintos vinos»
  (3.3): el catálogo se referencia desde varios vinos, separándolo de la asociación. I2 («crear el
  maridaje "cordero al disco" y asociarlo a todos los vinos tintos con graduación ≥ 14») solo puede
  resolverse así: primero el maridaje existe, luego se vincula. Anexo B lo carga desde CSV.
- **Respaldo:** sección 5 («Catálogo»); sección 3.3; I2; Anexo B.

### 2.13 Vino–maridaje — **candidata a entidad asociativa**

- **Qué representa:** la recomendación de un maridaje para un vino (N:M sin atributos propios más
  allá de sus participantes, según la consigna).
- **Información propia:** ninguna adicional, según la consigna.
- **Por qué se lista como entidad candidata:** la sección 5 la lista explícitamente («Vino-maridaje…
  N:M»); en el DER puede quedar como relación entre las dos entidades y dar origen a su propia tabla
  en el esquema relacional (etapa 1, paso 3: «una relación por entidad **y por relación N:M**»).
  La decisión de dibujarla como entidad o solo como relación se anota en §6 (D-9).
- **Respaldo:** secciones 3.3 y 5.

### 2.14 Cliente — **candidata a supertipo de jerarquía**

- **Qué representa:** persona o empresa que compra en las salas de venta.
- **Información propia (en el supertipo):** ID, apellido y nombre o razón social, tipo y número de
  documento, dirección, localidad, fecha de alta, descuento (función del tipo: RN-06).
- **Por qué entidad independiente:** los comprobantes los emiten clientes de cualquier tipo, por lo
  que el «comprador» debe identificarse de forma única e independiente del subtipo concreto. El
  volumen de carga pide 20.000 clientes como población única. La sección 5 la define «Supertipo de
  una jerarquía con 3 subtipos», y la sección 5 «decisiones de diseño» exige por escrito elegir y
  justificar la estrategia de mapeo (tabla única / una tabla por subtipo / supertipo + subtipos).
  **Aqui no se elige la estrategia**: queda registrada como decisión abierta (§6, D-1).
- **Respaldo:** secciones 3.4 y 5; RN-06; etapa 1, paso 3; S3, D1, D4, D6 (consultas por tipo).

### 2.15 Socio del club — **candidata a subtipo de Cliente**

- **Qué representa:** cliente consumidor final miembro del club, con 10 % de descuento (RN-06).
- **Información propia:** la sección 5 asigna a los subtipos solo «zona y habilitación (distribuidor);
  país de destino (exportador)» y el texto de 3.4 no asigna datos adicionales propios del socio, más
  allá de condición de «socio del club». Distinción funcional: el descuento del 10 % y las reglas de
  la sección 8 (D1: «clientes socios del club», D4 y D6: socios sin compras).
- **Respaldo:** secciones 3.4 y 5; RN-06; D1, D4, D6.

### 2.16 Distribuidor — **candidata a subtipo de Cliente**

- **Qué representa:** cliente mayorista, con 20 % de descuento (RN-06).
- **Información propia:** zona de cobertura y número de habilitación (3.4 y 5).
- **Respaldo:** secciones 3.4 y 5; RN-06.

### 2.17 Exportador — **candidata a subtipo de Cliente**

- **Qué representa:** cliente que compra para exportar, con 30 % de descuento (RN-06).
- **Información propia:** país de destino principal (3.4). Sus permisos se modelan aparte (2.18) por
  ser varios por exportador.
- **Respaldo:** secciones 3.4 y 5; RN-06; U6 (ajuste de descuento para exportadores con muchos permisos).

### 2.18 Permiso de exportación

- **Qué representa:** autorización para exportar, emitida a un exportador.
- **Información propia:** código, fecha de emisión, fecha de vencimiento (la emisión debe preceder al
  vencimiento: RN-07, CHECK entre columnas).
- **Por qué entidad independiente:** «Un exportador puede tener **varios** permisos» (3.4) y la
  sección 5 dice «Varios por exportador»: relación 1:N desde el subtipo exportador, no un atributo
  repetible dentro de la fila del cliente. U6 cuenta permisos por exportador («más de 3 permisos»),
  lo que refuerza su modelado como filas propias.
- **Respaldo:** secciones 3.4 y 5; RN-07; U6.

### 2.19 Comprobante (cabecera)

- **Qué representa:** documento de una venta realizada por un cliente en una sala.
- **Información propia:** número, fecha, subtotal, descuento, total. Estos importes son derivados
  (RN-08: «No se carga a mano»); la decisión de guardarlos o calcularlos es de las «decisiones de
  diseño» de la sección 5 y queda para A-02.
- **Por qué entidad independiente:** es el registro comercial de la venta: se consulta por número
  (`GET /comprobantes/{nro}`), se borra por antigüedad/tipo (D1) y se calculan sus totales con
  `fn_total_comprobante`. Volumen de carga: 150.000 filas.
- **Respaldo:** secciones 3.4 y 5; RN-08, RN-09; I3; D1; API y etapa 2.

### 2.20 Renglón de comprobante — **candidata a entidad asociativa/débil con atributos**

- **Qué representa:** cada línea de vino vendida en un comprobante.
- **Información propia:** cantidad, precio unitario **al momento de la venta** (histórico, distinto
  del precio vigente del vino), descuento aplicado y subtotal del renglón.
- **Por qué se lista como entidad candidata:** el comprobante «incluye un conjunto de vinos» (3.4),
  relación N:M entre Comprobante y Vino con atributos propios reconocidos por la consigna (la
  sección 5 da la clave: «(comprobante, vino)»). El precio histórico es la razón técnica principal
  para no tratar la venta como simple referencia al vino: el «renglón» conserva el precio de ese
  momento. RN-09 valida el stock al insertar el renglón. Volumen: 500.000 filas.
- **Respaldo:** secciones 3.4 y 5; RN-08, RN-09; etapa 1, paso 2.

### 2.21 Transportista

- **Qué representa:** empresa de transporte externa que realiza los traslados.
- **Información propia:** código de transporte, razón social, CUIT, e-mail, teléfono, domicilio.
- **Por qué entidad independiente:** participa en los ingresos (traslado bodega → depósito) y en la
  cobertura de localidades (2.22); S7 mide la actividad de las empresas. RN-14 prohíbe borrar un
  transportista con movimientos asociados. `[Inferencia]` El comprobante de venta (3.4) no menciona
  transportista, por lo que no se le asigna una relación con ventas.
- **Respaldo:** secciones 3.5 y 5; RN-14; I1, I6; S7.

### 2.22 Transportista cubre localidad — **candidata a entidad asociativa**

- **Qué representa:** la cobertura geográfica del servicio de un transportista (a qué localidades
  llega a trasladar).
- **Información propia:** ninguna adicional, según la consigna.
- **Por qué se lista como entidad candidata:** la sección 5 la lista («Transportista cubre
  localidad… N:M»). 3.5 exige conocer «a qué localidades alcanza el servicio de cada transportista».
  En el DER puede representarse como relación N:M; en el esquema relacional da una tabla propia.
- **Respaldo:** secciones 3.5 y 5; I1 (borrar/insertar coberturas).

### 2.23 Ingreso (cabecera)

- **Qué representa:** documento por el que una bodega entrega vinos al depósito central.
- **Información propia:** código de ingreso, fecha, estado (`en_confeccion → terminado → procesado`,
  sin retroceso: RN-10, con ENUM). El transportista y la bodega de origen son participantes de sus
  relaciones.
- **Por qué entidad independiente:** es un objeto con ciclo de vida propio (estado), con
  procedimiento específico (`sp_procesar_ingreso`) y bloqueo de renglones (RN-12). Solo el ingreso
  «terminado» impacta el stock del depósito, y al impactar pasa a «procesado» (3.5, RN-10).
- **Respaldo:** secciones 3.5 y 5; RN-10, RN-12; I6, D5; API (`/ingresos/...`).

### 2.24 Renglón de ingreso — **candidata a entidad asociativa/débil con atributos**

- **Qué representa:** cada línea de vino incluida en un ingreso.
- **Información propia:** vino y cantidad (de botellas).
- **Por qué se lista como entidad candidata:** el ingreso «contiene un conjunto de vinos con su
  cantidad» (3.5), N:M entre Ingreso y Vino; la sección 5 la lista («Ingreso / Renglón de ingreso»).
  RN-12 prohíbe agregar, modificar o quitar renglones fuera de `en_confeccion` (trigger sobre los
  renglones: se necesita la fila/entidad del renglón como objeto de control); volumen 3.000–15.000.
- **Respaldo:** secciones 3.5 y 5; RN-12.

### 2.25 Transferencia (cabecera)

- **Qué representa:** solicitud de una sala al depósito central de un conjunto de vinos.
- **Información propia:** número de solicitud, fecha de confección (**la fecha actual, no
  modificable**: RN-11), estado (ENUM, mismo ciclo de RN-10 aplicado a transferencias: RN-11). La
  sala solicitante es participante de su relación.
- **Por qué entidad independiente:** al procesarla se descuenta el stock del depósito y se suma al de
  la sala; no puede procesarse si el depósito no tiene stock suficiente (3.5). Tiene procedimiento
  propio (`sp_procesar_transferencia`) y endpoints propios en la API. S4 y S5 consultan salas y
  transferencias por antigüedad y estado pendiente.
- **Respaldo:** secciones 3.5 y 5; RN-11, RN-12; S4, S5; API (`/transferencias/...`).

### 2.26 Renglón de transferencia — **candidata a entidad asociativa/débil con atributos**

- **Qué representa:** cada línea de vino y cantidad solicitada en una transferencia.
- **Información propia:** vino y cantidad.
- **Por qué se lista como entidad candidata:** igual que 2.24, con la transferencia en su rol.
- **Respaldo:** secciones 3.5 y 5; RN-11, RN-12.

### 2.27 Stock de sala

- **Qué representa:** existencia (unidades) de un vino en una sala de venta.
- **Información propia:** cantidad (con la regla de stock no negativo: RN-09 y la sección 5
  ejemplifican `CHECK (cantidad >= 0)`; la ambigüedad sobre «positivo» está pendiente como
  [Pregunta] en `docs/requisitos.md` §10.1.6).
- **Por qué entidad (inventario, no evento):** es una **existencia persistente por par (sala, vino)**,
  no un suceso: la sección 5 le asigna «Clave (sala, vino); cantidad >= 0», clave compuesta distinta
  de las de los documentos. Es inventario con estado propio, actualizado por
  ventas (RN-09) y por transferencias (RN-11), y consultado por `fn_stock_sala`, S6, S9 y el tablero.
- **Respaldo:** secciones 3.5 y 5; RN-09.

### 2.28 Stock de depósito

- **Qué representa:** existencia de un vino en el depósito central (único).
- **Información propia:** cantidad (con la misma regla de no negatividad; mismo encuadre que 2.27).
- **Por qué entidad (inventario, no evento):** es el inventario central contra el cual impactan los
  ingresos (RN-10) y del que se descuentan las transferencias (RN-11). S6 y S9 lo comparan con el
  stock de sala. La sección 5 lo lista como entidad propia («Stock de depósito… Un solo depósito
  central»), separada del stock de sala aunque comparten estructura. `[Inferencia]` «Un solo
  depósito central» indica que no hay una entidad «Depósito» con varias filas; el único stock lo
  representa.
- **Respaldo:** secciones 3.5 y 5; RN-10, RN-11; S6, S9.
- **Duda abierta:** el PDF las lista separadas; ¿cabría unificarlas físicamente? Se registra la
  alternativa pero se respeta la separación mientras no haya indicación en contra (§6, D-3).

### 2.29 Auditoría de precio

- **Qué representa:** registro histórico de cada cambio de precio de un vino.
- **Información propia:** precio anterior, precio nuevo, fecha y hora, usuario.
- **Por qué entidad independiente:** RN-13 exige auditar **todo** cambio de precio con esos datos, y
  la sección 5 lista «Auditoría de precio» como entidad mínima, señalando «La completa un trigger»
  (AFTER UPDATE): es una entidad tecnológica, motivada por el requisito RN-13 y no por los procesos
  descriptos en la sección 3. Cada cambio de precio genera una fila nueva: el historial no puede resolverse con un único atributo de precio en la fila del vino.
- **Respaldo:** sección 5; RN-13.

---

## 3. Clasificación por área del negocio

| Área | Entidades |
|---|---|
| **Red comercial (localidades, salas, personal)** | Localidad, Sala de venta, Empleado |
| **Producción de uva** | Finca, Parcela (débil), Cepa (catálogo), Lote de uva, Análisis de calidad |
| **Elaboración de vinos (bodega y producto)** | Bodega, Vino, Composición vino–cepa (asoc.), Maridaje (catálogo), Vino–maridaje (asoc.) |
| **Clientes y comercialización** | Cliente (supertipo), Socio, Distribuidor, Exportador (subtipos), Permiso de exportación |
| **Ventas** | Comprobante, Renglón de comprobante |
| **Logística** | Transportista, Transportista cubre localidad |
| **Depósito, aprovisionamiento e inventario** | Ingreso, Renglón de ingreso, Transferencia, Renglón de transferencia, Stock de sala, Stock de depósito |
| **Control interno (técnico)** | Auditoría de precio |

Se listan **29 conceptos**, que se agrupan en 27 si los tres subtipos de Cliente se cuentan como un
solo concepto. Un grupo de estos (2.11, 2.13, 2.20, 2.22, 2.24, 2.26) son **relaciones N:M
que la sección 5 lista como entidades**: se mantienen aquí porque la consigna las exige y porque en
el esquema relacional (etapa 1, paso 3) cada una se transforma en una relación/tabla propia. En el
DER puro puede modelarse varias como relación, no como entidad: punto a resolver en A-02.

Los subtipos de Cliente (2.15–2.17) **no se cuentan como entidades separadas del Cliente**: son
subtipos de la misma jerarquía, y su mapeo físico (tabla única / tabla por subtipo / supertipo +
subtipos) es exactamente una de las «decisiones de diseño» de la sección 5. Se listan por separado
solo para poder justificar cada uno.

---

## 4. Entidades débiles, asociativas y jerarquías detectadas

### 4.1 Entidad débil declarada

| Entidad | Dependencia identificadora | Respaldo |
|---|---|---|
| **Parcela** | No existe sin su Finca; su número identifica la parcela **dentro** de la finca | 3.2: «identificadas por un número dentro de la finca: una parcela no existe sin su finca»; 5: «Entidad débil: clave (finca, n.° de parcela)»; etapa 1, paso 2: «la entidad débil Parcela» |

Además, la sección 5 asigna claves compuestas a los renglones («Clave (comprobante, vino)») y al
stock de sala («Clave (sala, vino)»). `[Inferencia]` Eso indica que esas filas dependen de un
«propietario» (la cabecera / la sala). Pero el PDF los agrupa bajo «relaciones N:M con atributos»
(etapa 1, paso 2). La notación final (débil vs. asociativa) se decidirá en A-02; el resultado
relacional es el mismo: claves compuestas.

### 4.2 Candidatas a entidades asociativas (N:M)

| Asociación | Participantes | ¿Atributos propios? | Respaldo |
|---|---|---|---|
| Composición (vino–cepa) | Vino, Cepa | porcentaje de corte (suma 100: RN-05) | 5; 3.3; RN-05 |
| Vino–maridaje | Vino, Maridaje | no, según consigna | 5; 3.3 |
| Transportista cubre localidad | Transportista, Localidad | no, según consigna | 5; 3.5; I1 |
| Renglón de comprobante | Comprobante, Vino | cantidad, precio histórico, descuento, subtotal | 3.4; 5 |
| Renglón de ingreso | Ingreso, Vino | cantidad | 3.5; 5 |
| Renglón de transferencia | Transferencia, Vino | cantidad | 3.5; 5 |

No se detecta otra relación N:M en la sección 5. `[Inferencia]` Las demás conexiones del
escenario (empleado–sala, lote–parcela, etc.) son 1:N y no requieren entidad asociativa.

### 4.3 Jerarquía (generalización/especialización)

- **Cliente (supertipo) → Socio / Distribuidor / Exportador (subtipos).** Literal de las secciones 3.4
  y 5. La estrategia de mapeo (tabla única con columna tipo / una tabla por subtipo / supertipo +
  subtipos) **no se elige aquí**: es decisión de A-02 con la justificación por escrito que exige la
  sección 5. Factores ya visibles ahora: descuento común (RN-06), permisos anexos al exportador
  (RN-07, 1:N), volumen 20.000, consultas por tipo (S3, D1, D4, D6).
- `[Inferencia]` No se detecta otra jerarquía declarada en la consigna. El «encargado regional» de la
  localidad podría sugerir una jerarquía persona-empleado, pero la sección 5 lo lista como **atributo
  de Localidad** y RN-02 lo resuelve con «FK + diseño normalizado (3FN)» + dependencia funcional
  `localidad → encargado regional` (etapa 1, paso 4). No se subtipifica sin respaldo; ver §6, D-4.

---

## 5. Conceptos que NO deben modelarse como entidades independientes

Estos conceptos aparecen en la consigna pero las señales textuales indican que **no** son entidades:
son atributos, catálogos de apoyo o mecanismos de proceso. Si alguien los propusiera como entidades,
tendría que justificarlo contra la sección 5.

| Concepto | Por qué no es entidad propia (indicación textual) | Qué es en su lugar |
|---|---|---|
| **Encargado regional** | La sección 5 lo lista como **atributo de Localidad** («Código postal, nombre, provincia, encargado regional»; «El encargado depende de la localidad») y RN-02 lo resuelve como «FK + diseño normalizado (3FN)» con dependencia funcional `localidad → encargado regional`. El PDF no le asigna atributos propios al encargado. | Atributo de Localidad (con dato de contacto y nombre si se quisiera; la consigna no lo pide). |
| **Campaña** | 3.2 la define como el «año de cosecha» del lote y el `UNIQUE (parcela, campaña)` de RN-04/5.1 la usa como atributo. El Anexo B menciona campañas («los últimos 5 años, con cosecha entre febrero y abril») solo como guía de datos de prueba, no como catálogo CSV (los catálogos CSV explícitos son cepas, maridajes y departamentos). | Atributo (año) del Lote de uva. |
| **Zona de cobertura (distribuidor)** | 3.4: «Se guarda su zona de cobertura» – es un dato del subtipo, no un objeto. | Atributo del subtipo Distribuidor. |
| **Descuento** | RN-06 lo fija por tipo de cliente con función `fn_descuento_cliente`; 3.4 lo llama dato «directamente relacionado al tipo de cliente». La consigna no le da estructura propia. | Atributo (descuento propio según tipo). El valor histórico del descuento en cada venta queda registrado en el renglón (2.20). |
| **Estado (en_confeccion / terminado / procesado)** | Sección 5: «Estado con tipo ENUM» y RN-10: «Tipo ENUM». Es un tipo de datos, no un catálogo de negocio. Las transiciones se controlan con triggers/procedimiento. | Atributo de Ingreso y de Transferencia (implementación a decidir en etapa 2). |
| **Día de cierre (sala)** | 3.1 lo da como dato simple de la sala. U4 lo modifica masivamente; no hay operación que lo manipule como objeto. | Atributo de Sala de venta. |
| **Depósito central** | Sección 5: «**Un solo depósito central**». Es un contexto fijo del negocio, no una población de objetos con atributos propios (ni siquiera conserva un domicilio del depósito). | Contexto de los stocks: lo relevante (2.28) ya se captura como estado; RN-10 y RN-11 lo usan como actor fijo de los procesos. |
| **Total / subtotal (cálculos del comprobante)** | RN-08: «No se carga a mano». Es un valor derivado; su almacenamiento es la decisión abierta de la sección 5. | Atributo derivado (a decidir si físico o calculado). |
| **Presentación (volumen de vino)** | 3.3 y 5 lo listan como atributo del Vino («volumen en ml»). El debate 3.3 vs Anexo B (187/3000 ml) está registrado en `docs/requisitos.md` §10.1.7; mientras sea atributo, los `CHECK` correspondientes se resuelven en etapa 2 y no hay más concepto. | Atributo del Vino. |

---

## 6. Decisiones y dudas pendientes

### 6.1 Conceptos dudosos y alternativas de representación (sin decisiones definitivas)

| N.° | Duda o concepto | Alternativas de representación | Estado / decisión prevista |
|---|---|---|---|
| D-1 | **Mapeo de la jerarquía Cliente → 3 subtipos** (obligación de decidir por escrito) | (a) tabla única con columna de tipo (con atributos de los 3 subtipos, algunos a NULL); (b) una tabla duplicada por subtipo (sin tabla común); (c) supertipo + tablas de subtipo | La sección 5 exige elegir y justificar (ventajas/desventajas). Insumos: descuento común (RN-06), permisos del exportador (RN-07, 1:N), volumen 20.000, consultas por tipo (S3, D1, D4, D6). Decisión en A-02 |
| D-2 | **Renglones y stocks: ¿entidad débil o relación asociativa?** | (a) modelar en el DER como entidad débil del documento/sala; (b) modelarlos como relación N:M con atributos (como sugiere etapa 1, paso 2) | El esquema relacional es igual (claves compuestas), pero la notación y la defensa oral cambian. Decidir en A-02. |
| D-3 | **Stock de depósito: ¿tabla física separada del stock de sala?** | (a) estructura aparte (como la lista la sección 5); (b) unificar en una sola estructura de stock con un «destino» (depósito/sala) | El PDF las lista separadas; no hay ninguna indicación de fusión. Respetar separación salvo justificación técnica más fuerte en A-02. |
| D-4 | **¿«Encargado regional» es atributo o persona con identidad propia?** | (a) atributo de Localidad (texto literal de 5); (b) entidad tipo «empleado encargado» con sus datos | El PDF solo le asigna la localidad. Sin atributos propios, la modelización como atributo es la única sostenible. Tal vez convenga una [Pregunta] al docente solo por si hay detalle no textual (contacto, CUIT). En A-01: atributo. |
| D-5 | **¿Campaña como catálogo?** | (a) año en el lote (como lista la sección 5); (b) tabla catálogo de campañas (año + descripción) | El PDF lista catálogos de carga CSV (cepas, maridajes, departamentos) que no incluyen campañas. `[Inferencia]` atributo. Si el docente confirma lo contrario sería agregar una entidad más. Sin indicación, se queda como atributo. |
| D-6 | **¿El análisis de calidad es débil del lote?** | (a) entidad ordinaria con identificación propia (ID); (b) entidad débil identificada por (lote, fecha o n.° de análisis) | La sección 5 le da «ID» pero no dice si es clave propia o identificador de fila. Resolver al pasar a esquema relacional. |
| D-7 | **¿Hace falta una tabla intermedia parcela–cepa («plantación»)?** | (a) vínculo directo de parcela a cepa (la referencia es directa: «la parcela tiene plantada la cepa X»); (b) tabla intermedia con fecha de plantación / historia | La consigna solo pide la cepa plantada, sin historia. No se agrega tabla intermedia (respecto de 3FN tampoco aporta normalización). En A-01: no intermedia. |
| D-8 | **¿El comprobante de venta tiene transportista?** | (a) sin relación (como texto de 3.4); (b) agrega relación con Transportista | No hay respaldo textual para (b); no se agrega. Si la cátedra planteara distribución a domicilio sería un requerimiento ajeno al PDF. Sin cambios. |
| D-9 | **¿Vino–maridaje y Transportista–cubre–localidad como entidades o solo relaciones en el DER?** | (a) relación N:M simple (típica en ER); (b) dibujarlas como entidades «asociativas» | El esquema relacional (etapa 1, paso 3) les da tabla igual; en el DER la notación elegida debe ser consistente. Decidir en A-02 al dibujar el DER. |
| D-10 | **¿Auditoría de precio pertenece al DER conceptual o solo al esquema físico?** | (a) entidad del DER (contempla el criterio de aceptación «todas las entidades de la sección 5»); (b) tabla técnica sin aparición en el DER | La sección 5 la lista como entidad mínima; incluir (a) es lo seguro. Notar que su motivación es RN-13, no el escenario 3. |

### 6.2 Preguntas pendientes vinculadas (importadas de `docs/requisitos.md` §10.1–10.2)

- **P-6 / §10.1.6:** ¿«positivo» en RN-15 es `> 0` o el stock admite `>= 0` con DEFAULT 0? Afecta a
  stocks (2.27, 2.28), cantidades de renglones, kilos del lote y superficies de finca/parcela.
- **P-9 / §10.1.5:** ¿cómo se relacionan RN-06 (30 % general exportador) y U6 (35 % con más de 3
  permisos)? No cambia la lista de entidades, pero sí dónde vive el descuento (atributo del cliente
  frente a función; ver 2.14 / 2.17).
- **P-8 / §10.1.7:** catálogo de volúmenes abierto o cerrado (3.3 vs Anexo B). Mientras sea atributo de
  Vino (como lista la sección 5), no agrega entidades.

---

## 7. Referencias a la consigna

| Bloque de este documento | Referencia en el PDF / repo |
|---|---|
| Contexto del negocio y procesos | Sección 3 («Escenario propuesto»): 3.1 localidades/salas/empleados, 3.2 producción de uva, 3.3 bodegas y vinos, 3.4 clientes y ventas, 3.5 stock/depósito/ingresos/transferencias |
| Reglas que validan la existencia de entidades | Sección 4 (RN-01 a RN-15) |
| Entidades mínimas y decisiones de diseño obligatorias | Sección 5 («Modelo de datos: entidades mínimas», «Decisiones de diseño que deben tomar y justificar») |
| Cómo deben dibujarse en el DER las débiles, jerarquías y N:M con atributos | Sección 7, etapa 1, pasos 2–3, y criterio de aceptación «todas las entidades de la sección 5 están representadas» |
| Claves compuestas, UNIQUE, ENUM, DOMAIN, funciones y procedimientos sobre las entidades | Sección 7, etapa 2 («Requisitos mínimos») |
| Volúmenes de carga por tabla (apunta la entidad de alta frecuencia) | Sección 7, etapa 3 (y Anexo B para catálogos) |
| Operaciones que confirman el tratamiento de cada entidad | Sección 8 (consultas U1–U6, I1–I6, D1–D6, S1–S12) |
| Resumen previo de la consigna ya transcrito y analizado | `docs/requisitos.md` (con la marcación explícita/inferencia/pregunta de su sección 10) |

> Documento siguiente previsto: **A-02** — DER y esquema relacional, resolviendo las decisiones
> abiertas D-1 a D-10 de la sección 6.

---

### Registro de cambios de este documento

- Creación (A-01): listado y justificación de 29 conceptos candidatos, clasificación por área,
  débil/asociativas/jerarquía, lista de «no entidades» y diez decisiones abiertas (D-1…D-10).

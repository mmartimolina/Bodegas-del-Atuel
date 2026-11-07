# A-07 — Dependencias funcionales y normalización

## 1. Objetivo y alcance

El objetivo de este documento es identificar las dependencias funcionales relevantes del modelo de datos de Bodegas del Atuel y justificar su normalización hasta la tercera forma normal (3FN), conforme a los requisitos de la etapa 1 del trabajo práctico.

El análisis toma como base los documentos anteriores:

- A-01 — Entidades candidatas.
- A-02 — Atributos de las entidades.
- A-03 — Claves candidatas.
- A-04 — Relaciones y cardinalidades.
- A-05 — Entidades débiles y asociativas.
- A-06 — Mapeo de la jerarquía de clientes.

Se consideran las dependencias entre identificadores y atributos, las dependencias parciales asociadas a claves compuestas y las dependencias transitivas que podrían introducir redundancia.

El análisis presta especial atención a los datos de ventas, composición de vinos, existencias, permisos de exportación e ingresos y transferencias de mercadería.

Este documento no cierra las decisiones que permanecen abiertas en los análisis anteriores. Cuando la unicidad o minimalidad de una clave no está confirmada, la dependencia correspondiente se identifica como propuesta o condicionada.

El alcance es el análisis lógico del modelo. La definición definitiva de claves primarias, restricciones y mecanismos de implementación corresponde a las etapas posteriores del diseño.

## 2. Criterios de análisis

### 2.1. Dependencia funcional

Una dependencia funcional X → Y indica que, para cualquier par de filas de una relación, si ambas tienen el mismo valor para X, necesariamente deben tener el mismo valor para Y.

- X es el determinante.
- Y es el atributo o conjunto de atributos determinado.
- X puede estar formado por uno o varios atributos.

Una dependencia funcional no implica necesariamente que X sea una clave candidata: para serlo también debe cumplir las condiciones de unicidad y minimalidad.

### 2.2. Identificación de claves

Las dependencias se analizan considerando las claves candidatas documentadas en A-03 y las decisiones de mapeo de A-06.

Se distingue entre:

- **Respaldada:** existe evidencia suficiente en la consigna o en las decisiones ya justificadas para sostener la identificación utilizada.
- **Inferida:** se propone a partir de la estructura del negocio o de una interpretación razonable, pero no existe confirmación textual completa.
- **Condicionada o pendiente:** depende de resolver una ambigüedad sobre unicidad, minimalidad, identidad o reglas del negocio.

Una dependencia basada en una clave inferida o pendiente no se presenta como una propiedad definitivamente confirmada del modelo.

### 2.3. Formas normales

Se utilizan los siguientes criterios:

- **Primera forma normal (1FN):** cada atributo contiene valores atómicos y no se representan grupos repetitivos mediante listas o conjuntos dentro de una misma fila.
- **Segunda forma normal (2FN):** la relación está en 1FN y cada atributo no primo depende funcionalmente de la clave candidata completa, sin depender de una parte propia de una clave compuesta.
- **Tercera forma normal (3FN):** la relación está en 2FN y, para toda dependencia funcional no trivial X → A, se cumple que X es superclave o A es un atributo primo.

La presencia de una clave simple descarta dependencias parciales respecto de esa clave, pero no demuestra por sí sola que la relación esté en 3FN. También deben analizarse las dependencias transitivas y las demás dependencias funcionales relevantes.

### 2.4. Dependencias funcionales y reglas de negocio

No toda regla del negocio constituye una dependencia funcional.

Se distinguen, entre otras:

- Las dependencias funcionales entre atributos de una relación.
- Las restricciones de dominio y de fila, como cantidades no negativas.
- Las restricciones que involucran varias filas, como la suma de porcentajes de composición de un vino.
- Las reglas de cardinalidad y participación entre entidades.

Estas reglas se documentan en su categoría correspondiente y no se presentan como dependencias funcionales si no cumplen su definición.

## 3. Dependencias funcionales relevantes

### 3.1. Localidad, Sala y Empleado

**Localidad**

La consigna establece que cada localidad tiene un único encargado regional. Esta regla permite identificar una dependencia funcional conceptual entre la identidad de la localidad y su encargado regional, aunque todavía no se haya confirmado el atributo o conjunto de atributos que identifica unívocamente a cada Localidad.

Sin embargo, A-03 no confirma cuál es la clave candidata definitiva de Localidad:

- `codigo_postal` es un identificador posible, pero su unicidad no está confirmada.
- `(nombre, provincia)` es una combinación plausible, pero tampoco está respaldada como única.

Por este motivo, no se afirma todavía una dependencia formal basada en ninguno de esos identificadores. La dependencia conceptual se expresa como:

`identidad_localidad → encargado_regional`

Su implementación requiere resolver previamente la identificación de Localidad.

**Sala de venta**

A-03 respalda `id_sala` como identificador de Sala. A-04 establece que cada sala pertenece a una sola localidad.

Por lo tanto:

`id_sala → calle, numero, dia_cierre, localidad`

La localidad depende de la sala, pero una localidad puede tener varias salas. No existe una dependencia inversa `localidad → id_sala`.

**Empleado**

A-04 establece que cada empleado pertenece a una sola sala. Si se confirma CUIT como identificador de empleado, la dependencia propuesta es:

`cuit_empleado → nombre, fecha_ingreso, salario, sala`

La identificación de empleado se encuentra condicionada por la revisión de A-03. No se afirma que el nombre del empleado sea único.

**Análisis de redundancia**

Si el encargado regional se almacenara también en Sala, aparecería la siguiente dependencia transitiva:

`id_sala → localidad → encargado_regional`

Esto provocaría que el encargado de una misma localidad se repitiera en cada sala perteneciente a ella. Mantener el encargado regional asociado a Localidad evita esa redundancia.

De forma similar, almacenar en Empleado los datos descriptivos de su Sala o Localidad duplicaría información que puede obtenerse mediante las relaciones correspondientes.

### 3.2. Cliente y jerarquía de subtipos

Según A-06, se adopta como estrategia de mapeo un supertipo `Cliente` y tres subtipos: `Socio`, `Distribuidor` y `Exportador`.

La dependencia funcional del supertipo, tomando `id_cliente` como identificador, es:

`id_cliente → nombre, tipo_doc, n_doc, direccion, localidad, fecha_alta, descuento`

En los subtipos se proponen las siguientes dependencias:

- **Socio:** `id_cliente` identifica su pertenencia al subtipo. No tiene atributos propios documentados.
- **Distribuidor:** `id_cliente → zona, n_habilitacion`.
- **Exportador:** `id_cliente → pais`.

En el esquema relacional propuesto, `id_cliente` funciona como clave primaria de cada subtipo y como clave foránea hacia `Cliente`.

Esta separación permite evitar la repetición de los datos generales del cliente en cada subtipo. Los atributos específicos permanecen en la tabla correspondiente.

La ubicación de `descuento` en `Cliente` respeta A-02. Las dudas sobre su aplicación y obligatoriedad permanecen abiertas y no se resuelven mediante este análisis.

**Decisión de diseño:** según lo documentado en A-06, se adopta una jerarquía total y disjunta: todo Cliente pertenece exactamente a uno de los subtipos Socio, Distribuidor o Exportador. Esta decisión no constituye un requisito textual explícito de la consigna. Su implementación requiere mecanismos adicionales de integridad, ya que las claves foráneas por sí solas no garantizan totalidad ni exclusividad.


### 3.3. Permisos de exportación y documentos de ventas

**Permiso de exportación**

A-02 identifica los atributos `codigo`, `fecha_emision` y `fecha_vencimiento`. A-04 establece que un Exportador puede tener varios permisos.

A-03 identifica dos posibles alternativas de clave para Permiso de exportación, aunque ninguna tiene su unicidad confirmada.

Si se confirma que `codigo` es único globalmente, la dependencia funcional sería:

`codigo → fecha_emision, fecha_vencimiento`

Como alternativa, si se confirma la unicidad del par `(exportador, fecha_emision)`, la dependencia sería:

`(exportador, fecha_emision) → codigo, fecha_vencimiento`

Ambas propuestas permanecen condicionadas a las validaciones pendientes de A-03. Por lo tanto, todavía no se puede establecer una clave candidata definitiva.

La separación de Permiso de Exportación respecto de Exportador permite representar varios permisos para un mismo exportador sin almacenar grupos repetitivos en una fila.

La condición `fecha_vencimiento > fecha_emision` es una restricción de validación, no una dependencia funcional.

**Comprobante**

A-02 identifica los atributos `numero`, `fecha`, `subtotal`, `descuento` y `total`. Cada comprobante corresponde a un Cliente y a una Sala, según A-04.

La dependencia funcional depende del alcance de la numeración:

- Si `numero` es único globalmente: `numero → fecha, subtotal, descuento, total, cliente, sala`.
- Si la numeración se reinicia por Sala: `(sala, numero) → fecha, subtotal, descuento, total, cliente`.

A-03 mantiene pendiente esta decisión, por lo que ninguna de las dos alternativas se considera confirmada.

En estas dependencias, cliente y sala representan referencias al Cliente y a la Sala relacionados con el comprobante. No implican almacenar en la cabecera sus datos descriptivos, que permanecen en sus respectivas relaciones.

Los importes `subtotal` y `total`, aunque puedan calcularse a partir de los renglones, se analizan como atributos almacenados según el modelo documentado. Su consistencia con los detalles de la venta deberá garantizarse mediante las reglas de negocio correspondientes.

**Renglón de comprobante**

A-03 respalda la clave compuesta `(comprobante, vino)` para identificar cada renglón.

La dependencia funcional es:

`(comprobante, vino) → cantidad, precio_unitario, descuento, subtotal`

El precio unitario corresponde al valor histórico aplicado en el momento de la venta, por lo que debe conservarse en el renglón y no reemplazarse por el precio actual del vino.

Si los datos de cabecera del comprobante se almacenaran junto con los renglones, aparecerían dependencias parciales respecto de la clave compuesta. Por ejemplo:

`comprobante → fecha, cliente, sala`

Estos datos dependen del comprobante completo, no de la combinación de comprobante y vino. Por eso se separan la cabecera Comprobante y sus Renglones, evitando una violación de 2FN.



### 3.4. Composición de vinos y existencias

**Composición de vino por cepa**

A-04 identifica la composición como una relación N:M entre Vino y Cepa, con el atributo `porcentaje`.

A-03 propone como clave de la asociación la combinación `(vino, cepa)`. La dependencia funcional correspondiente es:

`(vino, cepa) → porcentaje`

El porcentaje depende de la combinación completa: un vino puede contener varias cepas y una misma cepa puede participar en distintos vinos.

No se consideran válidas las dependencias `vino → porcentaje` ni `cepa → porcentaje`, porque ninguna de las dos entidades determina por sí sola el porcentaje de cada asociación.

La regla de RN-05 que exige que los porcentajes de composición de un vino sumen 100 % es una restricción agregada sobre varias filas. No constituye una dependencia funcional.

**Stock de sala**

La consigna establece que el stock de sala se identifica mediante la combinación de Sala y Vino.

La dependencia funcional es:

`(sala, vino) → cantidad`

La cantidad disponible depende de qué vino se encuentra en qué sala. Ni la sala ni el vino determinan por separado una cantidad única.

A-04 documenta esta relación como N:M. La ausencia de una fila de stock no debe interpretarse automáticamente como una cantidad igual a cero; esa regla permanece sujeta a la ambigüedad AMB-11.

**Stock de depósito**

La consigna establece la existencia de un depósito central único y un stock asociado a cada vino.

Bajo la propuesta de una sola fila por vino, se plantea la dependencia:

`vino → cantidad`

Esta dependencia queda condicionada a confirmar que el modelo registra como máximo una fila de stock por vino y que la ausencia de una fila tiene el significado definido por las reglas del negocio.

**Análisis de normalización**

Las asociaciones de composición y stock utilizan claves compuestas. Sus atributos no clave dependen de la combinación completa propuesta, no de una parte individual de ella.

En consecuencia, no se identifican dependencias parciales en estas estructuras bajo las claves analizadas. La conclusión definitiva sobre las formas normales depende de confirmar las claves y reglas pendientes.


### 3.5. Ingresos y transferencias

**Ingreso**

A-02 identifica los atributos de la cabecera Ingreso: código, fecha, estado, transportista y bodega de origen.

A-03 considera `codigo` como identificador posible, pero deja pendiente confirmar el alcance de su numeración.

Si se confirma que `codigo` es único globalmente, la dependencia funcional sería:

`codigo → fecha, estado, transportista, bodega_origen`

Como alternativa, si la numeración depende de la bodega de origen, deberá evaluarse la identificación mediante `(bodega_origen, codigo)` y la dependencia funcional correspondiente:

`(bodega_origen, codigo) → fecha, estado, transportista`

Ninguna de estas alternativas se considera confirmada hasta validar la unicidad y el alcance de la numeración.

**Renglón de ingreso**

Cada renglón relaciona un ingreso con un vino e indica una cantidad.

La clave propuesta es `(ingreso, vino)`, por lo que se plantea:

`(ingreso, vino) → cantidad`

Esta clave se considera inferida por la estructura de la asociación y debe confirmarse.

**Transferencia**

A-02 identifica los atributos de la cabecera Transferencia: número, fecha de confección, estado y sala solicitante.

A-03 considera dos posibles alternativas de identificación para Transferencia, ninguna confirmada.

Si se confirma que `numero` es único globalmente, la dependencia funcional sería:

`numero → fecha_confeccion, estado, sala_solicitante`

Como alternativa, si la numeración depende de la sala solicitante, se plantea:

`(sala, numero) → fecha_confeccion, estado`

Ambas propuestas permanecen condicionadas a confirmar el alcance de la numeración y la unicidad correspondiente.

**Renglón de transferencia**

Cada renglón relaciona una transferencia con un vino e indica una cantidad.

La clave propuesta es `(transferencia, vino)`, por lo que se plantea:

`(transferencia, vino) → cantidad`

También es una propuesta inferida pendiente de confirmación.

**Análisis de normalización**

En ambos casos se separan los datos de cabecera de los renglones. La fecha, el estado y la entidad participante dependen del identificador del documento; la cantidad depende de la combinación del documento y el vino.

Si cabecera y renglones se almacenaran en una misma tabla con clave compuesta, los atributos de cabecera dependerían solo de una parte de esa clave. La separación evita esa dependencia parcial y favorece el cumplimiento de 2FN.

Los estados de confección y la posibilidad de que un documento todavía no tenga renglones son reglas del negocio y cuestiones de cardinalidad; no constituyen dependencias funcionales.


### 3.6. Finca, Parcela, Cepa y Lote

**Finca**

A-03 respalda `id_finca` como clave candidata.

La dependencia funcional es:

`id_finca → nombre, superficie, departamento, provincia`

Los atributos descriptivos dependen de la identificación de la finca.

**Parcela**

A-05 analiza Parcela como entidad débil cuya identificación depende de Finca. Su clave propuesta es `(finca, n_parcela)`.

La dependencia funcional es:

`(finca, n_parcela) → superficie, anio_plantacion`

La combinación identifica una parcela dentro de una finca. Ni la finca ni el número de parcela, considerados por separado, identifican necesariamente una parcela en todo el sistema.

Si los atributos de Finca se almacenaran junto con los de Parcela, los datos propios de la finca dependerían solamente de una parte de la clave compuesta. Esto produciría una dependencia parcial y redundancia. Mantener Finca y Parcela separadas evita ese problema.

**Cepa**

A-03 respalda `id` como clave candidata.

La dependencia funcional es:

`id → nombre, tipo`

El nombre y el tipo dependen de la identificación de la cepa.

**Lote**

La consigna establece como regla que una parcela puede tener como máximo una cosecha por campaña. A partir de esa regla se propone la dependencia:

`(finca, n_parcela, campania) → n_lote, fecha_cosecha, kg, bodega_destino`

La combinación se considera una clave propuesta, cuya minimalidad debe confirmarse según A-03. El alcance de `n_lote` como identificador global también permanece pendiente.

La separación entre Parcela y Lote permite mantener los datos propios de la parcela independientemente de cada cosecha. No se deben incorporar los atributos descriptivos de Finca o Parcela en Lote si ya pueden obtenerse mediante sus relaciones.

**Análisis de normalización**

La separación de Finca y Parcela evita dependencias parciales sobre la clave compuesta de la entidad débil. La identificación propuesta de Lote mediante parcela y campaña permite representar la regla de una cosecha por campaña sin repetir los datos de la parcela.

Estas conclusiones quedan sujetas a la confirmación de las claves y de las reglas pendientes identificadas en A-03 y A-04.



### 3.7. Bodega, Vino y Maridaje

**Bodega**

A-03 respalda `cuit` como clave candidata de Bodega, por la restricción de unicidad explícita.

La dependencia funcional es:

`cuit → razon_social, domicilio`

El CUIT identifica a la bodega y determina sus datos descriptivos. Esto no obliga a utilizarlo como clave primaria: podría conservarse como clave alternativa si se eligiera un identificador subrogado.

**Vino**

A-03 no confirma una clave candidata definitiva para Vino. El atributo `codigo` es un identificador posible, pero su unicidad no está respaldada explícitamente.

La combinación `(nombre, anada, volumen_ml)` presenta unicidad textual en el análisis, aunque su minimalidad no está demostrada.

Por lo tanto, se considera condicionada la dependencia:

`(nombre, anada, volumen_ml) → codigo, tipo, graduacion, precio, bodega`

No se afirma que `codigo` determine los demás atributos hasta confirmar su unicidad. A-04 establece que cada vino es elaborado por una sola bodega, pero esto no implica que una bodega determine un único vino.

**Maridaje**

A-03 respalda `id` como clave candidata de Maridaje.

La dependencia funcional es:

`id → nombre, temperatura`

Los atributos descriptivos dependen de la identificación del maridaje.

**Asociación Vino–Maridaje**

La asociación entre Vino y Maridaje no tiene atributos propios identificados en A-02. Si se representa mediante una tabla intermedia, se propone la clave compuesta `(vino, maridaje)`.

Al no existir atributos no clave en esa asociación, no se identifican dependencias funcionales adicionales que deban analizarse para 2FN o 3FN.

**Análisis de normalización**

Separar Bodega de Vino evita repetir los datos descriptivos de la bodega en cada vino. La relación se representa mediante la referencia correspondiente desde Vino hacia Bodega.

La asociación Vino–Maridaje permite representar la relación N:M sin almacenar grupos repetitivos de maridajes dentro de Vino.


### 3.8. Transportista y cobertura de localidades

**Transportista**

A-02 identifica los atributos código, razón social, CUIT, email, teléfono y domicilio.

A-03 considera `codigo` un identificador posible, pero su unicidad está pendiente de confirmación. También analiza `cuit` como clave candidata inferida, condicionada a que cada transportista tenga un CUIT propio y único.

Por lo tanto, se plantean las siguientes dependencias condicionadas:

`codigo → razon_social, cuit, email, telefono, domicilio`

`cuit → razon_social, codigo, email, telefono, domicilio`

Ninguna debe considerarse definitiva hasta confirmar la unicidad del identificador correspondiente. La razón social no se toma como clave porque pueden existir empresas con nombres iguales o similares.

**Cobertura de localidades**

A-04 establece una relación N:M entre Transportista y Localidad, sin atributos propios identificados en A-02.

Si se materializa mediante una tabla intermedia, se propone la clave compuesta `(transportista, localidad)`.

Al no identificarse atributos no clave en esta asociación, no se plantean dependencias funcionales adicionales.

La cobertura de localidades de un Transportista no debe confundirse con la zona de un Distribuidor: son conceptos diferentes, tal como quedó resuelto en AMB-15.

**Análisis de normalización**

Separar la cobertura territorial evita repetir localidades en atributos multivaluados de Transportista y permite representar correctamente la relación N:M.

La confirmación de las claves de Transportista queda pendiente de resolver las dudas de unicidad identificadas en A-03.




### 3.9. Auditoría de precios

A-02 identifica los atributos `id_auditoria`, vino, `precio_anterior`, `precio_nuevo`, `fecha_hora` y `usuario`.

A-03 respalda `id_auditoria` como clave candidata.

La dependencia funcional es:

`id_auditoria → vino, precio_anterior, precio_nuevo, fecha_hora, usuario`

Cada registro de auditoría identifica un cambio de precio y determina los datos asociados a ese cambio.

Un mismo vino puede tener múltiples registros de auditoría a lo largo del tiempo. Por lo tanto, `vino` no determina un único registro ni puede utilizarse por sí solo como clave de esta entidad.

**Análisis de normalización**

Mantener la auditoría separada de Vino permite conservar el historial de cambios sin repetir múltiples valores de precio y fecha en una misma fila de Vino.

El precio actual del vino y los precios registrados históricamente cumplen funciones diferentes: la auditoría conserva los cambios anteriores, mientras que Vino mantiene el precio vigente según el modelo.



## 4. Primera forma normal (1FN)

### 4.1. Criterio aplicado

Una relación cumple la primera forma normal cuando cada atributo contiene valores atómicos para el dominio considerado y no existen grupos de atributos repetidos ni listas de valores dentro de una misma fila.

En este análisis, la atomicidad se evalúa según el significado de cada dato en el negocio. No alcanza con almacenar varios valores como texto separado por comas o utilizar otro formato que los agrupe en una única columna.

### 4.2. Aplicación al modelo

El inventario de A-02 permite identificar los datos correspondientes a cada entidad. Los atributos descriptivos se mantienen separados y las relaciones entre entidades se representan mediante las asociaciones correspondientes.

Los principales casos que requieren atención son:

- **Composición de vinos:** cada combinación de Vino y Cepa se representa como una ocurrencia independiente de la asociación, con su atributo `porcentaje`. No se almacenan varias cepas ni varios porcentajes en una única columna de Vino.
- **Cobertura de transportistas:** cada combinación de Transportista y Localidad se representa mediante una asociación independiente. No se guarda una lista de localidades dentro de Transportista.
- **Renglones de comprobantes:** cada vino incluido en un comprobante se representa en un renglón separado, con su cantidad, precio unitario histórico, descuento y subtotal.
- **Renglones de ingresos y transferencias:** cada vino incluido en el documento se representa en un renglón independiente, con la cantidad correspondiente.
- **Composición de otros vínculos N:M:** las asociaciones sin atributos propios, como Vino–Maridaje, también se representan mediante ocurrencias separadas y no mediante listas de valores.

### 4.3. Entidad débil y valores atómicos

La identificación compuesta de Parcela mediante `(finca, n_parcela)` no contradice la primera forma normal.

La clave compuesta está formada por dos atributos individuales que, en conjunto, identifican cada parcela. No representa una lista ni un grupo repetitivo de valores.

### 4.4. Alcance de la verificación

La documentación conceptual identifica las estructuras necesarias para evitar grupos repetitivos y atributos multivaluados.

La confirmación definitiva de 1FN deberá realizarse sobre cada relación del esquema relacional cuando se complete su transformación, verificando que los atributos tengan dominios atómicos y que no se incorporen listas o grupos repetidos.


## 5. Segunda forma normal (2FN)

### 5.1. Criterio aplicado

Una relación cumple la segunda forma normal cuando cumple 1FN y cada atributo no primo depende funcionalmente de la clave candidata completa, sin depender solamente de una parte propia de una clave candidata compuesta.

Las dependencias parciales solo pueden presentarse respecto de claves candidatas compuestas. Por lo tanto, una relación cuya única clave candidata sea simple no presenta dependencias parciales respecto de esa clave.

El análisis debe considerar todas las claves candidatas identificadas, sin asumir que una clave propuesta o inferida ya fue aprobada como decisión definitiva.

### 5.2. Casos con claves compuestas

**Parcela**

La clave candidata respaldada por la consigna es `(finca, n_parcela)`.

La dependencia funcional propuesta es:

`(finca, n_parcela) → superficie, anio_plantacion`

Los atributos propios de la parcela dependen de su identificación completa. Si se mezclaran en una misma relación los datos descriptivos de Finca y Parcela, los atributos de Finca dependerían únicamente de `finca`, que es una parte de la clave compuesta. Esa estructura produciría una dependencia parcial.

Mantener Finca y Parcela separadas evita esa dependencia parcial y también la repetición de datos de la finca en cada parcela.

**Renglón de comprobante**

La consigna respalda la clave candidata `(comprobante, vino)`.

La dependencia funcional propuesta es:

`(comprobante, vino) → cantidad, precio_unitario, descuento, subtotal`

Los datos propios de la cabecera, como fecha, cliente y sala, dependen del comprobante y no de la combinación completa. Por eso deben permanecer en Comprobante y no repetirse en cada renglón.

Esta separación evita que los datos de cabecera dependan solo de una parte de la clave compuesta.

**Composición Vino–Cepa**

La clave candidata propuesta por inferencia es `(vino, cepa)`.

La dependencia funcional propuesta es:

`(vino, cepa) → porcentaje`

El porcentaje describe la participación de una cepa determinada en un vino determinado. No depende exclusivamente de Vino ni exclusivamente de Cepa.

Esta clave es una inferencia de diseño pendiente de validación, no una clave textual de la consigna.

**Stock de sala**

La consigna respalda la clave candidata `(sala, vino)`.

La dependencia funcional es:

`(sala, vino) → cantidad`

La cantidad identifica el stock de un vino en una sala determinada. No corresponde atribuirla únicamente a Sala o únicamente a Vino.

**Renglones de ingreso y transferencia**

Las claves propuestas son `(ingreso, vino)` y `(transferencia, vino)`, respectivamente. Ambas son inferencias por analogía con el renglón de comprobante y permanecen pendientes de validación.

Las dependencias propuestas son:

`(ingreso, vino) → cantidad`

`(transferencia, vino) → cantidad`

Los datos de cabecera de cada documento dependen de su propio identificador y deben mantenerse separados de los renglones. Esta separación evita dependencias parciales si se confirman las claves compuestas propuestas.

### 5.3. Relaciones con claves candidatas simples

Respecto de una clave candidata simple, no puede existir una dependencia parcial, porque no tiene partes propias no vacías.

Sin embargo, para determinar si una relación cumple 2FN deben considerarse todas sus claves candidatas. Si una relación también tuviera una clave candidata compuesta, habría que comprobar que sus atributos no primos dependan de la clave completa.

Por lo tanto, la identificación de una clave candidata simple en entidades como Finca, Cepa, Maridaje y Auditoría de precios no alcanza, por sí sola, para afirmar que esas relaciones cumplen 2FN.

### 5.4. Alcance y cuestiones pendientes

El análisis identifica las principales dependencias parciales que se evitan mediante la separación de entidades y documentos en cabecera y renglones.

La conclusión definitiva de 2FN deberá revisarse sobre el esquema relacional completo, una vez seleccionadas las claves primarias y alternativas y validadas las claves inferidas.

En particular, permanecen pendientes de validación las claves propuestas para Composición, Renglón de ingreso y Renglón de transferencia.



## 6. Tercera forma normal (3FN)

### 6.1. Criterio aplicado

Una relación cumple la tercera forma normal cuando cumple 2FN y, para toda dependencia funcional no trivial `X → A`, se cumple al menos una de estas condiciones:

- `X` es una superclave de la relación.
- `A` es un atributo primo, es decir, forma parte de alguna clave candidata.

El análisis debe considerar todas las claves candidatas y las dependencias funcionales relevantes de cada relación.

Una dependencia transitiva puede producir una violación de 3FN cuando un atributo no primo depende de otro atributo que no es superclave, en lugar de depender directamente de una clave candidata.

La existencia de una dependencia entre entidades relacionadas no implica automáticamente que deban almacenarse todos sus atributos en una misma relación. Debe analizarse en qué relación se representan esos datos y qué dependencias funcionales existen dentro de ella.

### 6.2. Localidad, Sala y encargado regional

El caso de Localidad, Sala y encargado regional se analiza especialmente porque la consigna establece que cada localidad tiene un único encargado regional.

Si se almacenara el encargado regional como atributo de Sala, y cada Sala perteneciera a una Localidad, podría producirse la siguiente cadena de dependencias:

`id_sala → localidad`

`identidad_localidad → encargado_regional`

En ese diseño, el encargado regional se repetiría en todas las salas pertenecientes a una misma localidad. La información dependería de la localidad y no directamente de la identificación de cada sala.

La alternativa propuesta es mantener el encargado regional asociado a Localidad, evitando repetirlo en cada Sala.

La identidad de Localidad continúa pendiente de una clave candidata definitiva, según lo documentado en A-03. Por lo tanto, esta cadena expresa una dependencia conceptual que deberá formalizarse cuando se confirme su identificador.


### 6.3. Jerarquía de clientes

Según la decisión documentada en A-06, se propone representar la jerarquía mediante el supertipo `Cliente` y las tablas de subtipos `Socio`, `Distribuidor` y `Exportador`.

En `Cliente`, la dependencia funcional propuesta es:

`id_cliente → nombre, tipo_doc, n_doc, direccion, localidad, fecha_alta, descuento`

En `Distribuidor`, se propone:

`id_cliente → zona, n_habilitacion`

En `Exportador`, se propone:

`id_cliente → pais`

En los subtipos, `id_cliente` funciona como clave primaria y como clave foránea hacia `Cliente`. En `Socio` no se identifican atributos propios adicionales.

Esta distribución permite que los atributos comunes dependan de la identificación del cliente y que los atributos específicos dependan de la identificación del subtipo correspondiente. Evita repetir los datos generales del cliente en las tablas de cada subtipo.

Los permisos de exportación se mantienen en una relación independiente, ya que un Exportador puede tener varios permisos. De esta manera, los datos de cada permiso no se repiten dentro de Exportador.

La estrategia de mapeo no demuestra por sí sola que todas las relaciones estén en 3FN. La verificación definitiva requiere considerar las claves candidatas y las dependencias funcionales de cada relación.

Según la decisión documentada en A-06, se adopta una jerarquía total y disjunta. Esta es una decisión de diseño fundamentada, no un requisito textual explícito. Su implementación requiere mecanismos adicionales de integridad, ya que las claves foráneas por sí solas no garantizan totalidad ni exclusividad.


### 6.4. Permisos de exportación

Según A-04 (REL-16), un Exportador puede tener varios permisos y cada Permiso pertenece a un Exportador, como supuesto de trabajo. Por esta razón, los datos del permiso se mantienen en una relación independiente de Exportador.

A-02 identifica los siguientes atributos del permiso: `codigo`, `fecha_emision` y `fecha_vencimiento`. A-03 analiza dos posibles claves, pero ninguna tiene su unicidad confirmada.

Si se confirma que `codigo` es único globalmente, la dependencia funcional sería:

`codigo → exportador, fecha_emision, fecha_vencimiento`

Como alternativa, si se confirma la unicidad del par `(exportador, fecha_emision)`, la dependencia sería:

`(exportador, fecha_emision) → codigo, fecha_vencimiento`

Ambas propuestas permanecen condicionadas a las validaciones pendientes de A-03. Por lo tanto, todavía no se puede establecer una clave candidata definitiva ni cerrar el análisis de dependencias funcionales del permiso.

La fecha de vencimiento posterior a la fecha de emisión, exigida por RN-07, constituye una restricción de negocio y no una dependencia funcional.

El estado vigente o vencido se considera derivado, según Q-12 de A-04, por lo que no se utiliza como determinante ni como fundamento de una dependencia funcional.

Mantener los permisos separados evita repetir sus datos cuando un Exportador tiene varios. La verificación definitiva de 3FN requiere confirmar la clave y las dependencias funcionales de esta relación.


### 6.5. Comprobantes y renglones de comprobantes

A-02 distingue los datos de la cabecera del comprobante de los datos propios de cada renglón. A-03 documenta como clave respaldada del renglón el par `(comprobante, vino)`, mientras que la identificación de la cabecera continúa pendiente de validar.

Para la cabecera, si se confirma que la numeración es global, la dependencia funcional propuesta sería:

`numero → fecha, subtotal, descuento, total, cliente, sala`

Si se confirma que la numeración es independiente por sala, la dependencia propuesta sería:

`(sala, numero) → fecha, subtotal, descuento, total, cliente`

Ambas alternativas permanecen condicionadas a la resolución de CompK-a en A-03. No se incorpora la fecha a la clave porque no existe una regla documentada de reinicio periódico de numeración.

En estas dependencias, cliente y sala representan las referencias al Cliente y a la Sala relacionados con el comprobante. No implican almacenar en la cabecera sus datos descriptivos, que permanecen en sus respectivas relaciones.

Para el renglón, la dependencia funcional respaldada por la clave propuesta es:

`(comprobante, vino) → cantidad, precio_unitario, descuento, subtotal`

La separación entre cabecera y renglones evita que los datos propios del comprobante dependan solo de una parte de la clave compuesta del renglón. La fecha, el cliente y la sala corresponden a la cabecera; la cantidad, el precio histórico y los importes propios de cada línea corresponden al renglón.

El `precio_unitario` del renglón se conserva como valor histórico del momento de la venta, según RN-01. Aunque su valor se obtiene del precio vigente del vino al registrar la operación, no debe reemplazarse por el precio actual en consultas posteriores.

Los atributos `subtotal`, `descuento` y `total` tienen carácter derivado según A-02 y RN-08. Su almacenamiento exige mantener la consistencia con los importes de los renglones y las reglas de cálculo correspondientes. Estas reglas de cálculo no constituyen, por sí mismas, dependencias funcionales adicionales.

La separación de cabecera y renglones evita repetir los datos generales del comprobante en cada vino vendido. La verificación definitiva de 3FN de la cabecera queda condicionada a la confirmación de su clave; la del renglón se apoya en la clave compuesta documentada, sin perjuicio de revisar las reglas de negocio asociadas a los importes.



### 6.6. Ingresos y transferencias

**Ingresos**

A-02 distingue la cabecera del ingreso de sus renglones. La cabecera contiene `codigo`, `fecha` y `estado`; el Transportista y la Bodega de origen son participantes de relaciones, no atributos descriptivos propios.

Si se confirma que el código de ingreso es único globalmente, la dependencia funcional propuesta sería:

`codigo → fecha, estado, transportista, bodega_origen`

Si la numeración fuera independiente por Bodega de origen, la alternativa sería:

`(bodega_origen, codigo) → fecha, estado, transportista`

Ambas alternativas permanecen condicionadas a la resolución de IK-a en A-03. La fecha del ingreso tiene además una semántica pendiente de aclaración, según A-02 y Q-03.

Para el renglón, A-03 propone por inferencia la clave compuesta `(ingreso, vino)`. Bajo ese supuesto, la dependencia funcional sería:

`(ingreso, vino) → cantidad`

Esta clave no está expresamente indicada en la consigna. Su minimalidad supone que no se repite el mismo vino en un ingreso; si se permitieran renglones repetidos para un mismo vino, habría que revisar la identificación de cada fila.

**Transferencias**

A-02 identifica en la cabecera los atributos `numero`, `fecha_confeccion` y `estado`. La Sala solicitante participa de la relación con Transferencia.

Si se confirma que el número de solicitud es único globalmente, la dependencia funcional propuesta sería:

`numero → fecha_confeccion, estado, sala`

Si la numeración fuera independiente por Sala solicitante, la alternativa sería:

`(sala, numero) → fecha_confeccion, estado`

Ambas alternativas permanecen condicionadas a la resolución de TF-a en A-03. La fecha de confección no se utiliza como determinante: aunque se fija al crear la transferencia según RN-11, no identifica de manera única cada documento.

Para el renglón, A-03 propone por inferencia la clave compuesta `(transferencia, vino)`. Bajo ese supuesto, la dependencia funcional sería:

`(transferencia, vino) → cantidad`

Al igual que en el ingreso, esta clave se basa en la suposición de que un mismo vino no aparece en más de un renglón de la misma transferencia. Si esa posibilidad estuviera permitida, sería necesario revisar la identificación de las filas.

La separación entre cabeceras y renglones evita repetir los datos generales de cada documento por cada vino incluido. En los renglones, la cantidad depende de la combinación del documento y el vino, no de cada componente por separado.

Los estados de Ingreso y Transferencia representan el ciclo de vida de cada documento. Sus cambios no generan nuevas dependencias funcionales ni convierten al estado en parte de la clave.

La verificación definitiva de 3FN de las cabeceras queda condicionada a confirmar sus claves candidatas. En los renglones, el análisis se apoya en claves inferidas, por lo que también requiere validar el supuesto de identificación de cada combinación documento-vino.


### 6.7. Bodega, Vino, composición, maridajes y existencias

**Bodega**

A-03 respalda `cuit` como clave candidata de Bodega, debido al requisito explícito de unicidad de la consigna. La dependencia funcional propuesta es:

`cuit → razon_social, domicilio`

La razón social no se considera clave candidata, porque no existe una regla que garantice su unicidad. Que `cuit` sea una clave candidata no obliga a elegirlo como clave primaria: esa decisión puede considerar una clave subrogada, sin alterar la dependencia funcional.

**Vino**

A-03 analiza dos alternativas para identificar un Vino. La primera es `codigo`, cuya unicidad se infiere de su función identificadora y del uso en el API, pero no está respaldada por una restricción UNIQUE explícita.

Si se confirma esa unicidad, la dependencia funcional sería:

`codigo → nombre, tipo, anada, volumen_ml, graduacion, precio, bodega`

La segunda alternativa es la combinación `(nombre, anada, volumen_ml)`, cuya unicidad sí está indicada en la consigna. Bajo esa regla, se propone:

`(nombre, anada, volumen_ml) → codigo, tipo, graduacion, precio, bodega`

La minimalidad de esta combinación no está demostrada formalmente en A-03. Por lo tanto, no se la presenta como clave candidata definitiva sin esa validación.

En ambas dependencias, `bodega` representa la referencia a la Bodega elaboradora. No implica repetir sus datos descriptivos en Vino. La separación entre ambas relaciones evita duplicar razón social y domicilio en cada vino.

**Composición Vino–Cepa**

La composición es una asociación N:M con el atributo `porcentaje`. A-03 propone por inferencia la clave compuesta `(vino, cepa)`. Bajo ese supuesto, la dependencia funcional es:

`(vino, cepa) → porcentaje`

Ni `vino` ni `cepa` determinan por separado el porcentaje de cada combinación. La regla RN-05, que exige que los porcentajes de composición de un vino sumen 100%, es una restricción agregada y no una dependencia funcional.

La separación de esta asociación permite representar varias cepas por vino sin almacenar listas o grupos repetidos en la relación Vino.

**Maridaje y asociación Vino–Maridaje**

A-03 respalda `id` como clave candidata del catálogo Maridaje. La dependencia funcional es:

`id → nombre, temperatura`

La unicidad de `nombre` no está confirmada, por lo que no se utiliza como determinante respaldado.

La asociación Vino–Maridaje no tiene atributos propios según A-02. Si se materializa como una relación intermedia, se propone por inferencia la clave `(vino, maridaje)`. Al no tener atributos no clave propios, no se identifican dependencias funcionales adicionales dentro de esa asociación.

La regla que exige uno o más maridajes por vino es una restricción de participación y cardinalidad, no una dependencia funcional.

**Existencias**

Para el stock de sala, A-03 identifica como clave respaldada el par `(sala, vino)`. La dependencia funcional correspondiente es:

`(sala, vino) → cantidad`

Ni la sala ni el vino por separado identifican una fila de stock.

Para el stock de depósito, A-03 propone `vino` como clave inferida, condicionada a que exista un único registro por vino en el depósito central. Si se confirma esa condición, la dependencia funcional sería:

`vino → cantidad`

La condición continúa pendiente según D-3 de A-01 y AMB-11 de A-04. No se afirma que deba existir obligatoriamente una fila para cada vino ni que una fila ausente equivalga a una cantidad igual a cero.

La separación entre stock de sala y stock de depósito conserva sus identidades y reglas propias. La verificación definitiva de 3FN del stock de depósito requiere confirmar su clave y la política de existencia de filas.

En conjunto, estas relaciones evitan repetir datos descriptivos de Bodega y Maridaje, y representan las asociaciones y existencias mediante sus propias combinaciones de participantes. Las conclusiones sobre 3FN quedan condicionadas a las claves inferidas y a las validaciones pendientes indicadas.





### 6.8. Transportista, cobertura de localidades y auditoría de precios

**Transportista**

A-03 analiza dos posibles identificadores para Transportista: `codigo` y `cuit`. La unicidad de `codigo` está pendiente de confirmación, mientras que la de `cuit` se plantea como inferencia condicionada a que cada Transportista tenga un CUIT propio y único.

Si se confirma la unicidad de `codigo`, la dependencia funcional sería:

`codigo → razon_social, cuit, email, telefono, domicilio`

Si se confirma la unicidad de `cuit`, la dependencia funcional alternativa sería:

`cuit → razon_social, codigo, email, telefono, domicilio`

No se consideran ambas dependencias definitivas hasta resolver las dudas de A-03. La razón social no se utiliza como determinante, porque no existe una regla que garantice su unicidad.

La verificación de 3FN de Transportista queda condicionada a la confirmación de sus claves candidatas y de las dependencias correspondientes.

**Cobertura de localidades**

A-04 establece una asociación N:M entre Transportista y Localidad, sin atributos propios identificados en A-02.

Si se materializa mediante una tabla intermedia, se propone por inferencia la clave compuesta `(transportista, localidad)`. Al no existir atributos no clave en esta asociación, no se identifican dependencias funcionales adicionales que deban analizarse para 3FN.

La separación de esta asociación evita almacenar listas de localidades dentro de Transportista y permite representar cada vínculo de cobertura de manera independiente.

La cobertura territorial de Transportista no debe confundirse con la zona de Distribuidor: son conceptos diferentes, según lo resuelto en AMB-15 de A-04.

**Auditoría de precios**

A-02 identifica los atributos `id_auditoria`, `vino`, `precio_anterior`, `precio_nuevo`, `fecha_hora` y `usuario`. A-03 respalda `id_auditoria` como clave candidata.

La dependencia funcional es:

`id_auditoria → vino, precio_anterior, precio_nuevo, fecha_hora, usuario`

Todos los datos del registro de auditoría dependen de su identificador. Un mismo vino puede tener varios registros a lo largo del tiempo, por lo que `vino` no determina un único registro de auditoría.

Mantener la auditoría separada de Vino permite conservar el historial de cambios sin almacenar múltiples precios y fechas en una misma fila. El precio vigente se mantiene en Vino, mientras que la auditoría registra los cambios históricos.

La dependencia funcional respaldada por `id_auditoria` permite justificar la identificación de cada registro. La verificación definitiva de 3FN también requiere considerar las demás claves candidatas posibles y las dependencias que pudieran confirmarse.





### 6.9. Síntesis del análisis de 3FN

El análisis realizado permite identificar decisiones de diseño que contribuyen a evitar dependencias parciales y transitivas en las relaciones propuestas.

La separación entre entidades y sus datos descriptivos evita repetir información que depende de identificadores de otras entidades. Esto se observa, por ejemplo, en la separación entre Sala y Localidad, Cliente y sus subtipos, Exportador y Permiso, Bodega y Vino, y Vino y Auditoría de precios.

Asimismo, separar las cabeceras de comprobantes, ingresos y transferencias de sus respectivos renglones permite distinguir los atributos que dependen de la identificación del documento de aquellos que dependen de la combinación entre documento y vino.

Las asociaciones N:M y las estructuras de composición y existencias se analizan mediante sus propias combinaciones de participantes. Su normalización definitiva dependerá de confirmar las claves propuestas y las reglas de identificación de cada relación.

No obstante, todavía existen cuestiones que impiden afirmar que todas las relaciones cumplen definitivamente 3FN:

- Algunas claves candidatas están respaldadas por la consigna, mientras que otras son inferidas o permanecen condicionadas a reglas de unicidad pendientes.
- La identificación de Localidad y las dependencias asociadas a su encargado regional requieren confirmar una clave candidata.
- Permanecen pendientes definiciones sobre la identificación de Vino, Comprobante, Permiso, Ingreso, Transferencia, Transportista y Stock de depósito, entre otras cuestiones documentadas en A-01, A-03 y A-04.
- La jerarquía de clientes se definió como total y disjunta según la decisión de diseño documentada en A-06. Su implementación requiere mecanismos adicionales de integridad para garantizar la totalidad y exclusividad de los subtipos.
- Las relaciones asociativas cuya clave se propone por inferencia requieren validar las reglas de identificación y la posible repetición de participantes.

Por lo tanto, este documento presenta un análisis de dependencias funcionales y de normalización hasta 3FN sobre el modelo conceptual propuesto, pero no constituye una certificación definitiva de que todas las relaciones del esquema relacional cumplen esa forma normal.

La comprobación final deberá realizarse sobre el esquema relacional completo, una vez definidas las claves candidatas, las restricciones de unicidad y las reglas de negocio que permanecen pendientes.


## 7. Descomposiciones y redundancias

Las descomposiciones analizadas buscan mantener cada atributo en la relación donde depende de la identificación correspondiente. De esta manera, se evita repetir información descriptiva y se reducen las anomalías de inserción, actualización y eliminación.

Las propuestas de esta sección sintetizan decisiones ya analizadas en las secciones anteriores. No constituyen una selección definitiva de claves primarias ni resuelven las ambigüedades que continúan pendientes.

### 7.1. Separación de entidades y atributos descriptivos

Se propone mantener separadas las entidades cuyos atributos dependen de identificadores diferentes. Entre los principales casos se encuentran:

- **Localidad y Sala:** los datos propios de cada sala se mantienen separados de los datos de la localidad y de su encargado regional.
- **Cliente y subtipos:** los atributos comunes se mantienen en Cliente y los específicos en Socio, Distribuidor y Exportador.
- **Exportador y Permiso:** los permisos se representan independientemente porque un Exportador puede tener varios.
- **Bodega y Vino:** los datos descriptivos de la bodega elaboradora no se repiten en cada vino.
- **Finca y Parcela:** los atributos propios de la finca no se repiten en cada parcela.
- **Vino y Auditoría de precios:** el precio vigente se mantiene en Vino y los cambios históricos se registran separadamente.

Estas separaciones evitan almacenar varias veces información que depende de la identificación de otra entidad.

### 7.2. Separación de cabeceras y renglones de documentos

Los comprobantes, ingresos y transferencias se analizan mediante una relación de cabecera y otra de renglones.

En cada documento, los atributos generales dependen de su identificador, mientras que los datos de cada vino incluido dependen de la combinación entre el documento y el vino.

Esta separación evita repetir en cada renglón los datos generales del documento y permite representar varios vinos en una misma operación.

En particular:

- La fecha, el cliente y la sala corresponden a la cabecera del comprobante.
- La cantidad, el precio unitario histórico y los demás datos propios de la operación corresponden al renglón de comprobante.
- La fecha y el estado corresponden a las cabeceras de ingresos y transferencias.
- La cantidad de cada vino corresponde al renglón del documento respectivo.

Las claves compuestas propuestas para los renglones de ingreso y transferencia continúan pendientes de validación, como se indicó en 5.2.

### 7.3. Separación de asociaciones N:M

Las asociaciones N:M se representan mediante relaciones independientes cuando requieren almacenar vínculos entre participantes o atributos propios de cada combinación.

Los principales casos identificados son:

- **Composición Vino–Cepa:** permite registrar el porcentaje de cada cepa en un vino.
- **Transportista–Localidad:** permite representar las localidades cubiertas por cada transportista.
- **Vino–Maridaje:** permite registrar los maridajes asociados a cada vino.
- **Comprobante–Vino:** permite representar los renglones de cada comprobante.
- **Ingreso–Vino:** permite registrar los vinos y sus cantidades en cada ingreso.
- **Transferencia–Vino:** permite registrar los vinos y sus cantidades en cada transferencia.

La separación evita almacenar listas de valores o grupos repetidos dentro de una sola relación. Las claves compuestas propuestas para estas asociaciones deberán validarse según las reglas de identificación correspondientes.

### 7.4. Datos históricos y atributos derivados

El modelo distingue entre los datos que deben conservarse como parte de una operación y aquellos que pueden obtenerse mediante cálculos.

El `precio_unitario` de cada renglón de comprobante se conserva como valor histórico del momento de la venta, según RN-01. No debe reemplazarse por el precio vigente de Vino, porque eso alteraría la información de operaciones anteriores.

Por otra parte, los atributos `subtotal`, `descuento` y `total` de los comprobantes tienen carácter derivado según A-02 y RN-08. Su almacenamiento y consistencia deben respetar las reglas de negocio correspondientes.

La auditoría de precios conserva los valores anteriores y nuevos, junto con la fecha y el usuario del cambio. Esta información histórica no debe confundirse con el precio vigente de Vino.

### 7.5. Descomposiciones pendientes de validación

Las descomposiciones propuestas no permiten cerrar todas las claves y dependencias funcionales del modelo. Permanecen pendientes, entre otras, las siguientes cuestiones:

- Confirmar las claves de Localidad, Vino, Comprobante, Permiso, Ingreso y Transferencia.
- Validar las claves propuestas por inferencia para Composición, Renglón de ingreso y Renglón de transferencia.
- Confirmar las reglas de identificación de Transportista y Stock de depósito.
- Resolver las ambigüedades de cardinalidad y participación documentadas en A-04 que puedan afectar la estructura definitiva.

Por lo tanto, las descomposiciones descriptas justifican decisiones orientadas a reducir redundancias y dependencias parciales o transitivas, pero deberán verificarse nuevamente sobre el esquema relacional definitivo.



## 8. Preservación de dependencias

La descomposición de una relación debe procurar que las dependencias funcionales relevantes puedan verificarse sobre las relaciones resultantes, sin necesidad de realizar combinaciones entre ellas para controlar cada restricción.

La preservación de dependencias es una propiedad que debe evaluarse sobre el conjunto de relaciones y las dependencias funcionales definidas. La separación de entidades, por sí sola, no demuestra que todas las dependencias estén preservadas.

### 8.1. Criterio de preservación

Una descomposición preserva las dependencias funcionales cuando el conjunto de dependencias proyectadas sobre las relaciones resultantes permite comprobar las dependencias originales.

En términos prácticos, cada dependencia funcional relevante debería poder controlarse en una relación individual o mediante las restricciones apropiadas del esquema, sin tener que reconstruir la relación original mediante JOIN.

Este análisis requiere conocer las claves candidatas y las dependencias funcionales definitivas. Por esa razón, las dependencias inferidas o condicionadas no pueden considerarse preservadas de manera definitiva.

### 8.2. Dependencias conservadas en relaciones individuales

Las dependencias funcionales cuyos atributos determinante y determinados pertenecen a una misma relación pueden controlarse dentro de ella, siempre que estén respaldadas por las reglas de identificación y las restricciones de integridad correspondientes.

Entre los casos identificados se encuentran:

- `id_finca → nombre, superficie, departamento, provincia`, en Finca.
- `id → nombre, tipo`, en Cepa.
- `cuit → razon_social, domicilio`, en Bodega.
- `id → nombre, temperatura`, en Maridaje.
- `id_auditoria → vino, precio_anterior, precio_nuevo, fecha_hora, usuario`, en Auditoría de precios.

Estas dependencias cuentan con identificadores respaldados por A-03. Su implementación deberá respetar las restricciones de unicidad correspondientes.

También se identifican dependencias propuestas para Cliente, sus subtipos y otras entidades. Su preservación definitiva requiere confirmar las claves y las reglas de identificación documentadas en A-03.

### 8.3. Dependencias de asociaciones y documentos

Las dependencias funcionales de las relaciones asociativas pueden controlarse dentro de las relaciones propuestas cuando sus atributos pertenecen a ellas y se confirma la validez de las claves candidatas correspondientes.

Por ejemplo:

- `(sala, vino) → cantidad`, en Stock de sala.
- `(vino, cepa) → porcentaje`, en Composición.
- `(comprobante, vino) → cantidad, precio_unitario, descuento, subtotal`, en Renglón de comprobante.
- `(ingreso, vino) → cantidad`, en Renglón de ingreso, como clave inferida.
- `(transferencia, vino) → cantidad`, en Renglón de transferencia, como clave inferida.

En los documentos, las dependencias de cabecera se mantienen separadas de las dependencias de sus renglones. Esta organización permite controlar los datos generales del documento en su propia relación y los datos de cada vino en la relación de detalle.

La preservación de las dependencias de las asociaciones cuya clave se propone por inferencia queda condicionada a la validación de esas claves.

### 8.4. Dependencias pendientes de validación

No es posible afirmar la preservación definitiva de todas las dependencias mientras continúen abiertas las siguientes cuestiones:

- La identificación de Localidad y la dependencia asociada a su encargado regional.
- Las claves candidatas de Vino, Comprobante, Permiso, Ingreso, Transferencia y Transportista.
- Las claves inferidas para Composición, Renglón de ingreso, Renglón de transferencia y Stock de depósito.
- Las reglas de identificación de las asociaciones N:M y la posible repetición de participantes.

Además, algunas reglas de negocio no son dependencias funcionales y requieren mecanismos de control propios. Entre ellas se encuentran las restricciones de porcentajes de composición, las cantidades no negativas, las cardinalidades y las condiciones de estado de los documentos.

### 8.5. Alcance de la verificación

El análisis identifica dependencias que pueden controlarse directamente en las relaciones propuestas y señala aquellas cuya preservación depende de decisiones todavía pendientes.

La verificación completa deberá realizarse sobre el esquema relacional definitivo, comprobando las dependencias proyectadas, las claves candidatas y las restricciones de integridad implementadas.

Por lo tanto, esta sección documenta el criterio de preservación y su aplicación preliminar al modelo, pero no afirma que todas las dependencias estén preservadas definitivamente.




## 9. Decisiones pendientes y limitaciones

El análisis realizado permite identificar las principales dependencias funcionales y justificar las descomposiciones propuestas. Sin embargo, algunas decisiones del modelo conceptual y de su futura transformación relacional todavía requieren confirmación.

Estas cuestiones se mantienen abiertas para evitar considerar definitivas claves, restricciones o reglas de negocio que no cuentan con respaldo suficiente.

### 9.1. Identificación y claves candidatas pendientes

Las siguientes decisiones pueden modificar las dependencias funcionales que finalmente se implementarán:

- **Localidad:** todavía no se confirmó una clave candidata definitiva. Esta decisión es necesaria para formalizar la dependencia entre la identificación de la localidad y su encargado regional.
- **Vino:** no se confirmó la unicidad de `codigo` ni la minimalidad de `(nombre, anada, volumen_ml)`.
- **Comprobante:** debe definirse si `numero` es único globalmente o si la identificación requiere combinarlo con la sala.
- **Permiso de exportación:** deben confirmarse la unicidad de `codigo` y la posible identificación mediante Exportador y fecha de emisión.
- **Ingreso:** debe confirmarse si `codigo` es único globalmente o si la identificación requiere combinarlo con la bodega de origen.
- **Transferencia:** debe definirse si `numero` es único globalmente o si la identificación requiere combinarlo con la sala solicitante.
- **Transportista:** deben confirmarse las reglas de unicidad de `codigo` y CUIT.
- **Lote:** quedan pendientes la identificación mediante `n_lote` y la validación de la combinación de parcela y campaña.
- **Cliente:** debe confirmarse la identificación mediante tipo y número de documento.
- **Empleado:** la utilización del CUIT como identificador requiere confirmar que sea propio y único.

Las claves propuestas por inferencia deberán contrastarse con las reglas de negocio y las restricciones de unicidad antes de utilizarlas como fundamento definitivo de las dependencias funcionales.

### 9.2. Ambigüedades de relaciones y reglas de negocio

También permanecen abiertas algunas cuestiones del análisis de relaciones y cardinalidades:

- **Jerarquía de Cliente:** se adoptó una jerarquía total y disjunta, según lo documentado en A-06. Queda pendiente definir e implementar los mecanismos de integridad necesarios para garantizar esa regla.
- **AMB-08:** debe confirmarse la regla de pertenencia de los permisos de exportación.
- **AMB-10a, AMB-10b y AMB-14:** permanecen pendientes la posibilidad de que un Comprobante, Ingreso o Transferencia exista sin renglones y la relación entre el estado del documento y esa condición.
- **AMB-11:** debe definirse si la ausencia de una fila de stock es válida y cómo se representa una existencia igual a cero. La ausencia de una fila no equivale automáticamente a una cantidad cero.

Estas ambigüedades pueden afectar las restricciones de integridad y las condiciones de participación de las relaciones, aunque no todas constituyen dependencias funcionales.

### 9.3. Claves inferidas en asociaciones y existencias

Las siguientes identificaciones requieren validación adicional:

- `(vino, cepa)` para Composición.
- `(vino, maridaje)` para la asociación entre Vino y Maridaje.
- `(transportista, localidad)` para la cobertura de localidades.
- `(ingreso, vino)` para los renglones de ingreso.
- `(transferencia, vino)` para los renglones de transferencia.
- `vino` para Stock de depósito, condicionado a que exista un único registro por vino.

También debe confirmarse si las reglas del negocio permiten repetir participantes en estas asociaciones. La clave definitiva debe impedir únicamente las repeticiones que el modelo no admita.

### 9.4. Restricciones y datos derivados

La normalización mediante dependencias funcionales no resuelve por sí sola todas las reglas de negocio identificadas.

Entre las cuestiones que deberán controlarse mediante restricciones u otros mecanismos apropiados se encuentran:

- La suma de los porcentajes de composición de cada vino.
- La prohibición de cantidades negativas.
- La coherencia entre los renglones y los totales de los documentos.
- La validez de los estados y las transiciones de los documentos.
- Las cardinalidades y condiciones de participación de las relaciones.

Asimismo, deberán respetarse los datos históricos y las reglas sobre atributos derivados. En particular, el precio unitario registrado en un renglón de comprobante debe conservar su valor histórico, aunque posteriormente cambie el precio vigente del vino.

### 9.5. Limitaciones del análisis

El presente documento analiza las dependencias funcionales y las formas normales sobre el modelo conceptual y las claves candidatas identificadas hasta el momento.

Como todavía no se dispone del esquema relacional definitivo ni se han resuelto todas las claves y reglas pendientes, no corresponde afirmar que cada relación cumple definitivamente 1FN, 2FN y 3FN, ni que todas las dependencias están preservadas.

La validación final deberá realizarse sobre el conjunto de relaciones resultante, considerando todas sus claves candidatas, las dependencias funcionales definitivas y las restricciones de integridad correspondientes.

Por lo tanto, las conclusiones de este documento constituyen una justificación preliminar de la normalización propuesta, sujeta a las decisiones pendientes y a la posterior verificación del esquema relacional.


## 10. Conclusión

El análisis desarrollado permitió identificar las principales dependencias funcionales del modelo de Bodegas del Atuel y estudiar las descomposiciones necesarias para reducir redundancias y evitar dependencias parciales y transitivas.

Se justificó la separación de entidades y asociaciones, la organización de los documentos mediante cabeceras y renglones, el tratamiento de las entidades débiles y la conservación de datos históricos, como el precio unitario registrado en cada venta.

También se analizaron las condiciones de primera, segunda y tercera forma normal, considerando las claves candidatas respaldadas, las identificaciones propuestas por inferencia y las decisiones que todavía requieren confirmación.

El trabajo permite fundamentar las decisiones de normalización adoptadas hasta esta etapa, pero no constituye una certificación definitiva de que todas las relaciones cumplen 3FN. Esa comprobación dependerá de la definición del esquema relacional completo, la validación de sus claves candidatas y la resolución de las reglas de negocio pendientes.

Por lo tanto, el modelo cuenta con una justificación preliminar de normalización hasta 3FN, que deberá verificarse nuevamente cuando se complete su transformación al esquema relacional.

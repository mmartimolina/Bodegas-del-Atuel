# A-05 — Entidades débiles y asociaciones

## 1. Objetivo y alcance

Este documento analiza los casos especiales del modelo conceptual identificados durante A-01, A-02, A-03 y A-04.

Se estudian:
- La entidad débil Parcela.
- Las relaciones N:M que poseen atributos propios.
- Las relaciones N:M sin atributos propios.
- Las claves candidatas de las entidades o asociaciones resultantes.
- Las decisiones respaldadas por la consigna, las inferencias de diseño y las cuestiones pendientes de validación.

El objetivo es justificar cómo representar estos casos en el modelo conceptual, sin definir todavía las claves primarias y foráneas definitivas del modelo relacional.

## 2. Fuentes y metodología

Para el análisis se consideran las siguientes fuentes del proyecto:

- Consigna del TPI, especialmente las secciones 3, 4 y 5, y los anexos correspondientes.
- `docs/requisitos.md`.
- `docs/modelo/01_entidades_candidatas.md`.
- `docs/modelo/02_atributos_entidades.md`.
- `docs/modelo/03_claves_candidatas.md`.
- `docs/modelo/04_relaciones_cardinalidades.md`.

Se distingue entre tres niveles de respaldo:

- **Explícito:** la consigna establece directamente la característica o regla.
- **Inferido:** se propone una solución de modelado razonable a partir de la información disponible, pero no está establecida literalmente por la consigna.
- **Pendiente:** existe una ambigüedad que requiere validación del equipo o de la cátedra.

Las claves indicadas en este documento son claves candidatas propuestas. No constituyen todavía una selección definitiva de claves primarias.

## 3. Criterios de clasificación

Para analizar cada caso se consideran los siguientes criterios:

1. Si la consigna identifica una entidad independiente o una entidad cuya existencia depende de otra.
2. Si la relación posee atributos propios que describen la asociación entre sus participantes.
3. Si una misma combinación de participantes puede aparecer más de una vez.
4. Si existe respaldo textual para identificar cada ocurrencia mediante la combinación de las claves de sus participantes.
5. Si la consigna establece una clave o si esta debe inferirse.

Una asociación N:M puede representarse mediante una entidad asociativa cuando resulta necesario identificar sus ocurrencias y registrar atributos propios. Esto no significa que automáticamente se convierta en una entidad independiente del dominio del negocio.

## 4. Parcela como entidad débil

### 4.1. Respaldo en la consigna

La consigna caracteriza a Parcela como una entidad débil y establece que su clave está compuesta por la finca a la que pertenece y el número de parcela.

En la sección 3.2 se establece que una parcela no existe sin una finca. La sección 5 explicita la identificación mediante la combinación de finca y número de parcela.

Por lo tanto, la dependencia de Parcela respecto de Finca y su identificación mediante una clave compuesta tienen respaldo explícito.

### 4.2. Identificación y atributos

Los atributos identificados en A-02 son:

- `n_parcela`: número de parcela dentro de una finca.
- `superficie`: superficie de la parcela.
- `anio_plantacion`: año de plantación.

La cepa asociada a la parcela se representa como participante de una relación con la entidad Cepa, no como un atributo que sustituya dicha relación.

La clave candidata identificada en A-03 es:

**ParK-1: `(finca, n_parcela)`**

Esta clave se considera respaldada explícitamente por la consigna. El número de parcela no identifica por sí solo una parcela en todo el sistema, ya que su alcance está limitado a la finca correspondiente.

### 4.3. Consecuencias para el modelo conceptual

Parcela debe representarse como entidad débil, dependiente de Finca.

La identificación de una parcela requiere considerar conjuntamente:
- La finca propietaria.
- El número de parcela dentro de esa finca.

No corresponde proponer un identificador independiente como decisión definitiva, ya que la consigna establece expresamente la identificación compuesta.

La relación Finca–Parcela debe conservar la dependencia existencial de Parcela respecto de Finca.

### 4.4. Cuestiones pendientes

La cardinalidad mínima de parcelas que debe tener una finca continúa siendo una inferencia y se encuentra vinculada con la ambigüedad AMB-03 de A-04.

Esta cuestión no modifica la identificación de Parcela como entidad débil ni la clave candidata `(finca, n_parcela)`.

## 5. Composición entre Vino y Cepa

### 5.1. Naturaleza de la relación

La consigna establece una relación N:M entre Vino y Cepa con un atributo propio: el porcentaje de participación de cada cepa en la composición de un vino.

También establece que cada vino debe componerse de una o más cepas y que los porcentajes correspondientes a un vino deben sumar 100.

Por lo tanto, la existencia de una asociación entre Vino y Cepa y el atributo `porcentaje` tienen respaldo explícito.

### 5.2. Atributo propio

A-02 identifica el siguiente atributo:

- `porcentaje`: porcentaje de corte de una cepa en un vino.

Este atributo describe la participación de una cepa en la composición de un vino. No pertenece exclusivamente a Vino ni exclusivamente a Cepa.

La regla de suma del 100 % debe evaluarse para el conjunto de asociaciones correspondientes a cada vino, de acuerdo con la consigna y RN-05.

### 5.3. Clave candidata propuesta

A-03 propone:

**ComK-1: `(vino, cepa)`**

Esta clave es inferida. La consigna establece la relación N:M y el atributo porcentaje, pero no determina expresamente la clave de la asociación.

La propuesta supone que una misma cepa no puede aparecer en más de una ocurrencia de composición para el mismo vino.

### 5.4. Cuestión pendiente

Permanece abierta la duda ComK-a: si un vino podría registrar más de una ocurrencia de la misma cepa por motivos que la consigna no contempla, como distinguir lotes o partidas.

Si se permitiera esa repetición, la combinación `(vino, cepa)` no sería suficiente para identificar cada ocurrencia y habría que analizar un identificador adicional.

La consigna disponible no aporta respaldo suficiente para afirmar que esa repetición esté permitida. Por lo tanto, no corresponde incorporarla como regla del negocio ni descartarla como posibilidad definitivamente resuelta.

### 5.5. Consecuencias para el modelo conceptual

Composición debe representarse como una asociación entre Vino y Cepa que permita almacenar el porcentaje correspondiente.

Puede modelarse como entidad asociativa en el DER para representar claramente el atributo propio y su identificación, manteniendo explícito que se trata de una asociación y no de una entidad independiente del negocio.

La elección definitiva de la notación queda relacionada con la decisión general D-9, todavía pendiente.

## 6. Renglón de comprobante: asociación entre Comprobante y Vino

### 6.1. Naturaleza de la asociación

La consigna establece que un comprobante contiene vinos y que cada renglón registra información específica de la venta.

La relación entre Comprobante y Vino es N:M y posee atributos propios. Por ese motivo, resulta necesario representar los renglones como asociaciones identificables.

### 6.2. Atributos propios

A-02 identifica los siguientes atributos:

- `cantidad`: cantidad de botellas del vino incluidas en el renglón.
- `precio_unitario`: precio unitario vigente al momento de la venta, que debe conservarse como valor histórico.
- `descuento`: descuento aplicado al renglón. Su dominio exacto, porcentaje o importe, permanece pendiente de aclaración.
- `subtotal`: importe resultante del cálculo del renglón, considerando cantidad, precio unitario y descuento.

El precio unitario histórico no debe confundirse con el precio vigente del vino. Su conservación permite mantener el valor que correspondía a la operación cuando se realizó.

El subtotal es un valor derivado según RN-08. La decisión de almacenarlo o calcularlo deberá justificarse en la etapa correspondiente.

### 6.3. Clave candidata

A-03 identifica la siguiente clave:

**RK-1: `(comprobante, vino)`**

Esta clave tiene respaldo explícito en la sección 5 de la consigna, que identifica el renglón mediante el comprobante y el vino.

La propuesta supone que un mismo vino no aparece más de una vez dentro del mismo comprobante.

### 6.4. Alcance de la regla de identificación

La identificación del renglón mediante la combinación `(comprobante, vino)` implica que un mismo vino no se repite en más de un renglón del mismo comprobante, según la regla textual de la consigna.

Si una necesidad futura del negocio exigiera registrar el mismo vino en varios renglones por condiciones comerciales diferentes, sería necesario revisar esa regla y analizar una clave ampliada, por ejemplo, incorporando un número de renglón. Esta posibilidad no constituye una ambigüedad de la consigna vigente.

Permanece pendiente AMB-10a de A-04, referida a si puede existir un comprobante sin renglones.
### 6.5. Consecuencias para el modelo conceptual

El renglón de comprobante debe representarse como una asociación entre Comprobante y Vino con atributos propios.

Su identificación mediante la combinación de ambos participantes está respaldada por la consigna, bajo el supuesto de que no se repite un mismo vino dentro del comprobante.

## 7. Renglón de ingreso: asociación entre Ingreso y Vino

### 7.1. Naturaleza de la asociación

La consigna establece una relación N:M entre Ingreso y Vino. Cada renglón registra la cantidad de botellas de un vino que forma parte del ingreso.

La relación y el atributo cantidad tienen respaldo explícito en las secciones 3.5 y 5.

### 7.2. Atributo propio

A-02 identifica el siguiente atributo:

- `cantidad`: cantidad de botellas del vino incluidas en el renglón.

Este dato pertenece a la asociación entre Ingreso y Vino, porque representa la cantidad de un vino específico dentro de un ingreso determinado.

### 7.3. Clave candidata propuesta

A-03 propone:

**RI-1: `(ingreso, vino)`**

Esta clave es inferida. La consigna establece la relación N:M y el atributo cantidad, pero no explicita que la combinación de ingreso y vino sea única.

La propuesta sigue el criterio utilizado para identificar el renglón de comprobante, pero esa analogía no constituye por sí sola una regla del negocio.

### 7.4. Cuestiones pendientes

Permanece abierta RI-a: si un mismo vino puede aparecer en más de un renglón del mismo ingreso.

Si esa repetición estuviera permitida, sería necesario analizar un número de renglón u otro identificador adicional.

También permanecen abiertas las ambigüedades AMB-10b y AMB-14 de A-04, relacionadas con la existencia de ingresos sin renglones y con las condiciones de los renglones según el estado del documento.

RN-12 establece restricciones para modificar, agregar o quitar renglones mientras el ingreso se encuentra en estado `en_confeccion`, pero no determina por sí sola si un ingreso debe contar con al menos un renglón para considerarse válido.

### 7.5. Consecuencias para el modelo conceptual

El renglón de ingreso debe representarse como una asociación entre Ingreso y Vino con el atributo cantidad.

La clave `(ingreso, vino)` puede utilizarse como propuesta inicial, pero debe conservarse su clasificación inferida hasta validar si se permite repetir un vino dentro de un mismo ingreso.

## 8. Renglón de transferencia: asociación entre Transferencia y Vino

### 8.1. Naturaleza de la asociación

La consigna establece una relación N:M entre Transferencia y Vino. Cada renglón registra la cantidad de botellas solicitadas de un vino determinado.

La relación y el atributo cantidad tienen respaldo explícito en las secciones 3.5 y 5.

### 8.2. Atributo propio

A-02 identifica el siguiente atributo:

- `cantidad`: cantidad de botellas del vino solicitadas en el renglón.

El atributo describe la participación de un vino específico dentro de una transferencia.

### 8.3. Clave candidata propuesta

A-03 propone:

**RT-1: `(transferencia, vino)`**

Esta clave es inferida. La consigna establece la relación N:M y el atributo cantidad, pero no determina expresamente la unicidad de la combinación de transferencia y vino.

La propuesta sigue el criterio de identificación planteado para los otros renglones, aunque debe validarse como regla del negocio.

### 8.4. Cuestiones pendientes

Permanece abierta RT-a: si un mismo vino puede aparecer más de una vez en una misma transferencia.

Si se permitiera esa repetición, la combinación `(transferencia, vino)` no sería suficiente para identificar cada ocurrencia y sería necesario analizar un número de renglón u otro identificador.

También permanecen abiertas las ambigüedades AMB-10b y AMB-14 de A-04, relacionadas con las transferencias sin renglones y con las condiciones de los renglones según el estado del documento.

RN-11 y RN-12 regulan los estados y las modificaciones de las transferencias, pero no permiten concluir por sí solas cuál es la cantidad mínima de renglones exigida para cada estado.

### 8.5. Consecuencias para el modelo conceptual

El renglón de transferencia debe representarse como una asociación entre Transferencia y Vino con el atributo cantidad.

La clave `(transferencia, vino)` se mantiene como propuesta inferida y queda sujeta a la validación de la posible repetición de vinos dentro de una misma transferencia.


## 9. Cobertura de Transportista sobre Localidad

### 9.1. Naturaleza de la relación

La consigna establece una relación N:M entre Transportista y Localidad para representar las localidades alcanzadas por el servicio de cada transportista.

La existencia de esta relación tiene respaldo explícito en las secciones 3.5 y 5.

### 9.2. Atributos propios

A-02 no identifica atributos propios para esta asociación.

Es importante distinguir esta cobertura de la zona comercial del Distribuidor. La zona pertenece al subtipo Distribuidor, mientras que la cobertura de localidades corresponde a Transportista.

Esta distinción también fue establecida en A-04 mediante la resolución de AMB-15.

### 9.3. Clave candidata propuesta

A-03 propone:

**TCL-1: `(transportista, localidad)`**

Esta clave es inferida, ya que la consigna establece la relación N:M, pero no especifica expresamente su clave.

La propuesta supone que una localidad no se registra más de una vez para un mismo transportista.

### 9.4. Cuestiones pendientes

AMB-09 de A-04 mantiene pendiente la validación de las condiciones de cobertura y sus cardinalidades mínimas.

No existe respaldo suficiente para agregar atributos, como fechas de vigencia, costos o condiciones de servicio, que no aparecen en la consigna.

### 9.5. Consecuencias para el modelo conceptual

La relación Transportista–Localidad debe conservarse como una asociación N:M sin atributos propios.

Puede representarse como entidad asociativa en el DER si la notación elegida lo requiere, pero no debe confundirse con una entidad independiente del negocio.

La combinación `(transportista, localidad)` se mantiene como clave candidata inferida.

## 10. Relación entre Vino y Maridaje

### 10.1. Naturaleza de la relación

La consigna establece una relación N:M entre Vino y Maridaje.

Cada vino debe tener uno o más maridajes y un mismo maridaje puede asociarse con distintos vinos.

La existencia de la relación N:M tiene respaldo explícito en las secciones 3.3 y 5.

### 10.2. Atributos propios

A-02 no identifica atributos propios para la asociación Vino–Maridaje.

Los datos `nombre` y `temperatura` pertenecen a la entidad Maridaje, no a la asociación entre Vino y Maridaje.

### 10.3. Clave candidata propuesta

A-03 propone:

**VMK-1: `(vino, maridaje)`**

Esta clave es inferida, porque la consigna no establece expresamente la identificación de cada asociación.

La propuesta supone que un mismo maridaje no se repite para un mismo vino.

### 10.4. Cuestiones pendientes

Permanece pendiente AMB-16 de A-04, relacionada con la posibilidad de que existan maridajes que todavía no estén asociados a ningún vino.

La cardinalidad mínima de cero para Maridaje es una inferencia de diseño y no debe presentarse como una regla explícita de la consigna.

También permanece pendiente D-9 respecto de la notación definitiva de las asociaciones N:M en el DER.

### 10.5. Consecuencias para el modelo conceptual

Vino–Maridaje debe representarse como una asociación N:M sin atributos propios.

La clave `(vino, maridaje)` se mantiene como propuesta inferida, sujeta a la validación de las reglas de unicidad.

No corresponde duplicar en la asociación los atributos `nombre` y `temperatura`, ya que pertenecen a Maridaje.



## 11. Cuadro comparativo de los casos analizados

| Caso | Participantes | Atributos propios | Clave candidata | Respaldo |
|---|---|---|---|---|
| Parcela | Parcela (débil), Finca | n_parcela, superficie, anio_plantacion | (finca, n_parcela) | Explícito: entidad débil y clave compuesta |
| Composición | Vino, Cepa | porcentaje | (vino, cepa) | Inferido |
| Renglón de comprobante | Comprobante, Vino | cantidad, precio_unitario, descuento, subtotal | (comprobante, vino) | Explícito: sección 5 |
| Renglón de ingreso | Ingreso, Vino | cantidad | (ingreso, vino) | Inferido |
| Renglón de transferencia | Transferencia, Vino | cantidad | (transferencia, vino) | Inferido |
| Cobertura de transportista | Transportista, Localidad | Ninguno | (transportista, localidad) | Inferido |
| Vino–Maridaje | Vino, Maridaje | Ninguno | (vino, maridaje) | Inferido |

El cuadro resume las propuestas de identificación, pero no implica que todas las claves tengan el mismo grado de respaldo.

Parcela posee una identificación compuesta explícita. El renglón de comprobante también cuenta con respaldo textual para su identificación mediante comprobante y vino. En los demás casos, las claves se proponen como inferencias sujetas a validación.

## 12. Decisiones y ambigüedades pendientes

A partir del análisis se mantienen las siguientes cuestiones abiertas:

| Referencia | Caso | Cuestión pendiente |
|---|---|---|
| AMB-03 | Finca–Parcela | Validar la cardinalidad mínima de parcelas por finca. |
| D-9 | Asociaciones N:M | Definir la notación definitiva de las asociaciones en el DER. |
| ComK-a | Composición | Validar si puede repetirse una cepa dentro de la composición de un mismo vino. |
| AMB-10a | Comprobante | Determinar si puede existir un comprobante sin renglones. |
| RI-a | Renglón de ingreso | Validar si puede repetirse un vino dentro del mismo ingreso. |
| RT-a | Renglón de transferencia | Validar si puede repetirse un vino dentro de la misma transferencia. |
| AMB-10b | Ingreso y transferencia | Determinar las condiciones de existencia de documentos sin renglones. |
| AMB-14 | Ingreso y transferencia | Validar las restricciones de los renglones según el estado del documento. |
| AMB-09 | Transportista–Localidad | Validar las condiciones de cobertura y sus cardinalidades mínimas. |
| AMB-16 | Vino–Maridaje | Determinar si pueden existir maridajes sin vinos asociados. |

La consigna vigente establece que un mismo vino no aparece más de una vez dentro del mismo comprobante. Por lo tanto, no se trata de una ambigüedad pendiente. Si una necesidad futura del negocio exigiera registrar el mismo vino en varios renglones por condiciones comerciales diferentes, sería necesario revisar esa regla y analizar una clave ampliada, por ejemplo, incorporando un número de renglón.

Las cuestiones anteriores no deben resolverse mediante supuestos presentados como reglas explícitas. Hasta contar con validación, las propuestas conservan su clasificación y justificación.

## 13. Impacto en el futuro modelo relacional

El análisis permite anticipar algunas necesidades de transformación al modelo relacional, sin definir todavía su implementación definitiva.

### 13.1. Entidad débil Parcela

La identificación de Parcela deberá contemplar la clave de Finca y el número de parcela.

La dependencia identificada en el modelo conceptual deberá conservarse en el modelo relacional mediante una referencia a Finca y una restricción de unicidad sobre la combinación correspondiente.

### 13.2. Asociaciones N:M con atributos

Composición, renglón de comprobante, renglón de ingreso y renglón de transferencia deberán poder almacenar los atributos propios identificados.

Su transformación requerirá estructuras que permitan relacionar las claves de las entidades participantes y conservar los atributos de cada asociación.

La definición de sus claves dependerá de las decisiones de identificación y de las ambigüedades pendientes.

### 13.3. Asociaciones N:M sin atributos

Transportista–Localidad y Vino–Maridaje también requerirán representar las asociaciones entre sus participantes.

Aunque no poseen atributos propios identificados, su cardinalidad N:M implica que no deben perderse las combinaciones existentes entre ambas entidades.

La implementación relacional concreta se definirá en la etapa correspondiente.

## 14. Conclusiones

El análisis distingue una entidad débil de las asociaciones N:M, evitando tratarlas como si fueran el mismo tipo de estructura conceptual.

Parcela constituye un caso explícito de entidad débil: depende de Finca y se identifica mediante la combinación de finca y número de parcela.

Composición y los tres tipos de renglones poseen atributos propios que describen cada asociación. Por ello, resulta conveniente analizarlos como conceptos asociativos en el DER.

Transportista–Localidad y Vino–Maridaje son asociaciones N:M sin atributos propios identificados. Su eventual representación como entidades asociativas dependerá de la notación adoptada para el DER.

Las claves candidatas propuestas no tienen todas el mismo respaldo: algunas están indicadas por la consigna, mientras que otras son inferencias que requieren validación.

En consecuencia, este análisis proporciona criterios para construir el DER y continuar con el diseño relacional, pero no reemplaza las decisiones pendientes ni establece todavía las claves primarias definitivas.

## 15. Alcance y limitaciones

Este documento no define:

- Las claves primarias y foráneas definitivas.
- La estructura SQL de las tablas.
- Las restricciones de implementación.
- La notación gráfica definitiva del DER.
- La resolución de las ambigüedades que requieren validación.

Estas decisiones corresponden a las etapas posteriores del proyecto y deberán mantener coherencia con los requisitos, las relaciones y las claves candidatas documentadas anteriormente.

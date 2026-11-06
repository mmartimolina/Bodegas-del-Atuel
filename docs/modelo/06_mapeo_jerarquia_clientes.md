# A-06 — Evaluación del mapeo de la jerarquía de clientes

## 1. Objetivo y alcance

Evaluar las tres estrategias de mapeo de la jerarquía Cliente–Socio–Distribuidor–Exportador mencionadas en la sección 5 de la consigna, comparar sus ventajas y desventajas y justificar una alternativa para el sistema.

Este análisis utiliza como antecedentes A-01 (entidades candidatas), A-02 (atributos) y A-04 (relaciones y cardinalidades).

La elección de una estrategia de mapeo no resuelve por sí misma la totalidad ni la exclusividad de la jerarquía. Esas cuestiones permanecen abiertas en AMB-07 de A-04.

## 2. Distribución de atributos

### 2.1. Supertipo Cliente

A-02 identifica los siguientes atributos comunes:

- `id_cliente`: identificador del cliente.
- `nombre`: apellido y nombre de la persona física o razón social de la empresa.
- `tipo_doc` y `n_doc`: identificación documental.
- `direccion`: dirección del cliente.
- `localidad`: localidad asociada.
- `fecha_alta`: fecha de alta.
- `descuento`: porcentaje de descuento habitual.

La materialización de `descuento` permanece pendiente (Q-01 de A-02): RN-06 exige una función de descuento y un CHECK de rango, mientras que la sección 5 también lo enumera como atributo. La contradicción entre RN-06 y U6 (P-9) tampoco está resuelta. Por lo tanto, no se toma este atributo como fundamento de la decisión de mapeo.

### 2.2. Subtipos

- **Socio:** no se identifican atributos propios adicionales. Su condición se relaciona con la pertenencia al club y el descuento previsto por RN-06.
- **Distribuidor:** `zona` y `n_habilitacion`.
- **Exportador:** `pais`, correspondiente al país de destino principal.

Los permisos de exportación se mantienen como registros independientes relacionados con Exportador, dado que un exportador puede tener varios permisos (RN-07).

## 3. Estrategias de mapeo evaluadas

### 3.1. Una única tabla con discriminador

Se utiliza una sola tabla `Cliente`, con un atributo que identifica el tipo de cliente. La tabla contiene tanto los atributos comunes como los específicos de cada subtipo.

**Ventajas:**
- Las consultas generales sobre clientes son directas.
- Las consultas por tipo se resuelven filtrando por el discriminador.
- No requiere JOIN para recuperar los datos de un cliente.

**Desventajas:**
- Los atributos específicos de cada subtipo pueden quedar en NULL para los demás tipos.
- Se necesitan restricciones condicionales para validar qué atributos corresponden a cada tipo.
- La estructura presupone una única clasificación por cliente si se utiliza un discriminador simple; esto no debe adoptarse sin resolver la exclusividad de la jerarquía.

### 3.2. Una tabla independiente por subtipo

Se crean tablas para Socio, Distribuidor y Exportador. Cada una contiene tanto los atributos comunes como los específicos, sin una tabla compartida para Cliente.

**Ventajas:**
- Cada tabla contiene únicamente los atributos correspondientes a su subtipo.
- Las consultas específicas de cada tipo son directas.
- No se generan columnas específicas sin valor para los demás tipos.

**Desventajas:**
- Se repiten los atributos comunes en las distintas tablas.
- Los datos generales de un cliente deben mantenerse en la tabla correspondiente a su subtipo.
- Las consultas sobre el conjunto de clientes requieren combinar las tablas mediante UNION.
- La actualización de atributos comunes puede exigir operaciones sobre distintas tablas.

### 3.3. Supertipo más tablas de subtipos

Se crea una tabla `Cliente` con los atributos comunes y una tabla para cada subtipo. Cada tabla de subtipo utiliza el identificador del cliente como clave primaria y, a la vez, como clave foránea hacia `Cliente`.

**Ventajas:**
- Los atributos comunes se almacenan una sola vez.
- Los atributos específicos se mantienen únicamente en el subtipo correspondiente.
- No se necesitan columnas específicas vacías en la tabla común.
- Las consultas generales parten de `Cliente`.
- Las consultas específicas pueden combinar `Cliente` con la tabla del subtipo mediante JOIN.
- La estructura permite representar pertenencias múltiples si las reglas del negocio finalmente las admiten.

**Desventajas:**
- Las consultas que requieren datos comunes y específicos necesitan JOIN.
- Las claves foráneas garantizan que cada subtipo corresponda a un cliente existente, pero por sí solas no garantizan exclusividad ni totalidad.
- Si se establecieran reglas de exclusividad o pertenencia obligatoria, sería necesario implementar mecanismos adicionales de integridad.

## 4. Comparación

| Criterio | Tabla única | Una tabla por subtipo | Supertipo + subtipos |
|---|---|---|---|
| Atributos comunes | Una vez | Repetidos | Una vez |
| Atributos específicos | En la tabla común | En cada tabla | En cada subtipo |
| Valores NULL específicos | Posibles | No necesarios | No necesarios |
| Redundancia de datos comunes | Baja | Alta | Baja |
| Consultas generales | Directas | Requieren UNION | Desde Cliente |
| Consultas específicas | Filtro por tipo | Directas | JOIN |
| Integridad de la jerarquía | Restricciones condicionales | Datos comunes repetidos | PK/FK y restricciones adicionales según reglas |

## 5. Decisión propuesta

Se propone adoptar la estrategia de **supertipo Cliente más una tabla por cada subtipo: Socio, Distribuidor y Exportador**.

La elección se fundamenta en que la jerarquía presenta varios atributos comunes y pocos atributos específicos. Mantener los datos compartidos en una única tabla evita su repetición y facilita las consultas generales sobre los 20.000 clientes previstos.

A su vez, separar los atributos específicos permite representar los datos propios de Distribuidor y Exportador sin incorporar columnas que quedarían vacías para los demás tipos. La ausencia de atributos propios de Socio no impide representarlo mediante una tabla cuya clave sea también una referencia al supertipo.

La estrategia ofrece un equilibrio entre reducción de redundancia, claridad conceptual e integridad referencial. Si bien algunas consultas específicas requieren JOIN, este costo se considera razonable frente a las ventajas de mantener los datos comunes centralizados.

## 6. Cuestiones que permanecen abiertas

La decisión de mapeo no resuelve las siguientes cuestiones:

- **AMB-07 (A-04):** no está determinado si la jerarquía es total o parcial, ni si los subtipos son excluyentes o pueden solaparse.
- **Q-01 (A-02):** permanece pendiente decidir la materialización del descuento habitual del cliente.
- **P-9:** permanece pendiente la interpretación de la diferencia entre RN-06 y U6.
- **Q-04 (A-02):** permanece pendiente decidir si el nombre se mantiene como un único atributo o se descompone según el tipo de persona.

Estas cuestiones deberán resolverse en las etapas correspondientes y no se consideran supuestos de esta decisión.

## 7. Estado de revisión

**Decisión propuesta:** supertipo más tablas de subtipos.

**Revisión de Persona B:** pendiente.

La decisión deberá ser revisada por el segundo integrante antes de considerar cumplido el criterio de aceptación correspondiente a A-06.

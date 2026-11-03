# A-02 — Atributos de las entidades candidatas

> Issue A-02 · Responsable: Persona A · Estado: borrador conceptual (continúa A-01)
> Fuente: `docs/Consigna/TPI_Bodegas_del_Atuel.pdf` (secciones 3, 4 y 5), `docs/requisitos.md`
> y `docs/modelo/01_entidades_candidatas.md` (A-01, aún sin revisar por Persona B).
> Convención de marcado:
> - **Explícito** = el dato figura en el texto del PDF (se cita la sección).
> - `[Inferencia]` = propuesto por nosotros con justificación; NO es requisito textual.
> - Obligatoriedad: «Siempre», «Opcional» o «Indeterminado».
> Limitación (igual que A-01): los números de página del PDF no se verificaron con certeza, por lo que
> se cita la **sección numerada** como referencia principal.
> Restricción respetada: en este documento **no** se eligen claves primarias ni foráneas, no se
> definen cardinalidades, no se construye el DER, no se indican tipos de datos SQL y no se decide
> qué atributos derivados se almacenan o se calculan (decisión que la sección 5 exige justificar
> por escrito; queda para A-03+).
> Sobre combinaciones de atributos citadas (p. ej. clave (finca, n.° de parcela), `UNIQUE (parcela,
> campaña)` o `UNIQUE (nombre, añada, volumen)`): son **citas textuales de la consigna** (sección 5
> y sección 7, etapa 2) que acreditan la existencia del dato; **no** son decisiones de diseño del
> equipo. La elección de claves y restricciones se hará en A-03+, caso por caso (sección 5,
> «decisiones de diseño»).
> Los conceptos dudosos de A-01 (D-1…D-10) continúan **provisionales**; nada se descartó aquí.

---

## 1. Objetivo y alcance

Inventariar y justificar los **atributos de cada entidad candidata** identificada en A-01, para que
el diseño conceptual siguiente (relaciones, cardinalidades, DER, esquema relacional) parta de un
inventario completo y trazable a la consigna.

Para cada atributo se documenta: nombre propuesto, descripción, entidad, si es explícito o
inferencia, si es Siempre / Opcional / Indeterminado, y su referencia en el PDF.

Además se identifican: los **atributos derivados** (como inventario, sin decidir su modo de
obtención), las posibles **redundancias** o dependencias entre entidades, y las **dudas** a
discutir con Persona B y con el docente.

Nota sobre la convención «Siempre»: significa que todos los casos descriptos del negocio cuentan con
el dato. No anticipa la decisión física de `NOT NULL`; que se justifica al transformar a esquema
relacional (etapa 1). En general todo lo explícito de la sección 5 se presume requerido salvo
indicación contraria del negocio; lo Opcional es lo que la consigna permite omitir en algún caso.

---

## 2. Atributos por entidad

### 2.1 Localidad

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| codigo_postal | Código postal de la localidad | Explícito | Siempre | Sec. 5 (fila Localidad) y 3.1 |
| nombre | Nombre de la localidad | Explícito | Siempre | Sec. 5 y 3.1 |
| provincia | Provincia de la localidad | Explícito | Siempre | Sec. 5 y 3.1 |
| encargado_regional | Responsable comercial de la localidad (único por localidad) | Explícito | Siempre | Sec. 5 («El encargado depende de la localidad») y 3.1; RN-02 |

Duda: 3.1 y la sección 5 no asignan atributos propios al encargado (ni contacto). La alternativa de
vincularlo a la entidad Empleado es solo hipotética: sin respaldo textual no se agrega (D-4 de A-01,
provisional; ver §4/§6).

### 2.2 Sala de venta

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| id_sala | Identificador de la sala | Explícito | Siempre | Sec. 5 («ID») y 3.1 |
| calle | Componente de la dirección | Explícito | Siempre | Sec. 5 («calle, número») y 3.1 |
| numero | Altura en la dirección | Explícito | Siempre | Sec. 5 y 3.1 |
| dia_cierre | Día semanal de cierre de la sala | Explícito | Siempre | Sec. 5 y 3.1; U4 lo actualiza en bloque |
| localidad | Localidad donde opera la sala (la sección 5 la lista entre los datos de la sala) | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5 («día de cierre, localidad») y 3.1; RN-02 |

Duda: dominio de `dia_cierre` (¿lunes a domingo? ¿puede no haber cierre?). El PDF solo muestra el
caso de U4. Ver §5, Q-09.

### 2.3 Empleado

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| cuit | Identificador natural de la persona | Explícito | Siempre | Sec. 5 y 3.1 |
| nombre | Nombre del empleado | Explícito | Siempre | Sec. 5 y 3.1 |
| fecha_ingreso | Fecha de inicio laboral; permite calcular la antigüedad (U2) | Explícito | Siempre | Sec. 5 y 3.1; función `fn_antiguedad_anios` (etapa 2) |
| salario | Remuneración del empleado | Explícito | Siempre | Sec. 5 y 3.1 |
| sala | Sala de venta donde se desempeña (la sección 5 la lista entre los datos del empleado) | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5 («salario, sala») y 3.1; RN-03 |

Duda: revisar si RN-15 (positividad de «cantidades, superficies, kilos y precios») incluye el
salario. En el PDF no aparece mencionado. Ver §5, Q-08.

### 2.4 Finca

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| id_finca | Identificador de la finca | Explícito | Siempre | Sec. 5 y 3.2 |
| nombre | Nombre de la finca | Explícito | Siempre | Sec. 5 y 3.2 |
| superficie | Superficie total en hectáreas | Explícito | Siempre | Sec. 5 («superficie (ha)») y 3.2; RN-15 |
| departamento | Departamento de ubicación | Explícito | Siempre | Sec. 5 y 3.2; Anexo B lista departamentos de Mendoza |
| provincia | Provincia de la finca | Explícito | Siempre | Sec. 5 y 3.2 |

Duda: ¿departamento y provincia quedan como atributos sueltos o con tablas de catálogo? (El
Anexo B lista departamentos de Mendoza para la carga masiva). Ver §5, Q-11.

### 2.5 Parcela (entidad débil declarada, según A-01 y sección 5)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| n_parcela | Número de parcela **dentro de su finca** (identificación débil) | Explícito | Siempre | Sec. 5 («Entidad débil: clave (finca, n.° de parcela)») y 3.2 — la combinación es **cita de la consigna, no decisión de diseño** (ver nota inicial de §2) |
| superficie | Superficie de la parcela en hectáreas | Explícito | Siempre | Sec. 5 y 3.2; RN-15 |
| anio_plantacion | Año de plantación | Explícito | Siempre | Sec. 5 y 3.2 |
| cepa | Cepa plantada (una sola para la parcela). A nivel conceptual es un vínculo con la entidad Cepa; la sección 5 lo lista entre los atributos de la parcela | Explícito (como dato de la parcela; será una relación en el DER) | Siempre | Sec. 5 y 3.2; RN-04 |

Duda: la consigna dice solo «año de plantación», no fecha; si la cátedra quisiera fecha exacta,
habría que agregarla. No se agrega sin respaldo (y D-7 de A-01 que no haya tabla intermedia
parcela–cepa sigue provisionales).

### 2.6 Cepa (catálogo)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| id | Identificador de la cepa | Explícito | Siempre | Sec. 5 («ID») |
| nombre | Nombre de la variedad (Malbec, Chardonnay,…) | Explícito | Siempre | Sec. 5 y 3.2; Anexo B (siete tintas y cinco blancas) |
| tipo | Tipo de uva: tinta o blanca | Explícito | Siempre | Sec. 5 y 3.2 |

### 2.7 Lote de uva

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| n_lote | Identificador del lote | Explícito | Siempre | Sec. 5 («N.° de lote») y 3.2 |
| parcela | Parcela de origen del lote (la sección 5 la lista entre los datos del lote) | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5 («N.° de lote, parcela, campaña…») y 3.2 |
| campania | Año de la campaña en que se cosechó (una cosecha por parcela y campaña) | Explícito | Siempre | Sec. 5 y 3.2; RN-04; el `UNIQUE (parcela, campaña)` de la etapa 2 es **cita de la consigna, no decisión de diseño** (ver nota inicial de §2) |
| fecha_cosecha | Fecha de cosecha | Explícito | Siempre | Sec. 5 y 3.2 |
| kg | Kilos cosechados | Explícito | Siempre | Sec. 5 («kg») y 3.2; RN-15; S10 lo usa para rendimiento |
| bodega_destino | Bodega a la que se entregó el lote (vínculo con la entidad Bodega) | Explícito (dato del lote; relación en el DER) | Siempre | Sec. 5 y 3.2 |

Dudas: (a) ¿el número de lote es global o relativo a la parcela? El PDF no lo aclara. La nota
`UNIQUE (parcela, campaña)` de RN-04 identifica al lote sin ambigüedad, y el
n.° de lote podría ser además un identificador propio. Ver §5, Q-02. (b) Relación entre
`fecha_cosecha` y `campania` (que deben ser coherentes: mes de febrero–abril según Anexo B para los
datos de prueba, no como regla del negocio).

### 2.8 Análisis de calidad

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| id_analisis | Identificador de la fila de análisis (la sección 5 lo llama «ID») | Explícito (con identidad dudosa: ver D-6 de A-01) | Indeterminado | Sec. 5 («ID») |
| lote | Lote de uva analizado (la sección 5 lo lista entre los datos del análisis) | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5 («ID, lote, fecha…») y 3.2 |
| fecha | Fecha del análisis | Explícito | Siempre | Sec. 5 y 3.2 |
| brix | Grados Brix del lote según el análisis | Explícito | Siempre | Sec. 5 y 3.2 |
| ph | pH de la muestra | Explícito | Siempre | Sec. 5 y 3.2 |
| acidez | Acidez total (g/L) | Explícito | Siempre | Sec. 5 y 3.2 |

Duda: identidad de la fila de análisis: ¿puede haber dos análisis del mismo lote el mismo día? La
consigna no dice cómo se identifican los distintos análisis (¿número de análisis dentro del lote?,
¿combinación (lote, fecha)?). D-6 de A-01 sigue provisional. Ver §5, Q-06.

### 2.9 Bodega

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| cuit | Identificador fiscal | Explícito | Siempre | Sec. 5 y 3.3 |
| razon_social | Razón social de la bodega | Explícito | Siempre | Sec. 5 y 3.3 |
| domicilio | Domicilio de la bodega | Explícito | Siempre | Sec. 5 y 3.3 |

Nota sobre el CUIT: la mención del `UNIQUE` de bodega sobre CUIT proviene de los **ejemplos de
restricciones de la etapa 2** (sección 7). Es un requisito de integridad del esquema, pero **no**
implica que ya se haya decidido que el CUIT sea clave primaria de bodega, ni si se usará una clave
subrogada en su lugar (decisión de la sección 5, «decisiones de diseño», pendiente para A-03+).
Ver §4, R-12.

### 2.10 Vino

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| codigo | Código del vino | Explícito | Siempre | Sec. 5 y 3.3 |
| nombre | Nombre comercial del vino («Malbec Reserva») | Explícito | Siempre | Sec. 5 y 3.3; el grupo (nombre, añada, volumen) se pide único en etapa 2 — **cita de la consigna, no decisión de diseño** (ver nota inicial de §2) |
| tipo | Tipo del vino: tinto, blanco, rosado o espumante | Explícito | Siempre | Sec. 5 y 3.3; I2 filtra por «tintos» (es el tipo del vino, no de la cepa) |
| anada | Añada (año de elaboración) | Explícito | Siempre | Sec. 5 y 3.3 |
| volumen_ml | Volumen de la presentación (ml) | Explícito | Siempre | Sec. 5 y 3.3; lista de volúmenes posibles con [Pregunta] P-8 (¿abierta o cerrada?) |
| graduacion | Graduación alcohólica (°) | Explícito | Siempre | Sec. 5 y 3.3; RN-15 (entre 5 y 20) |
| precio | Precio de venta; único para toda la red y > 0 | Explícito | Siempre | Sec. 5 y 3.3; RN-01 |
| bodega | Bodega elaboradora del vino (la sección 5 la lista entre los datos del vino: «precio, bodega») | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5 («Un vino lo elabora una bodega») y 3.3; RN-14; U3 agrupa por bodega del vino |

### 2.11 Composición (vino–cepa)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| porcentaje | Porcentaje de corte de una cepa en un vino; los porcentajes de un vino deben sumar 100 | Explícito | Siempre | Sec. 5 («N:M con atributo; suma 100») y 3.3; RN-05 |

### 2.12 Maridaje (catálogo)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| id | Identificador del maridaje | Explícito | Siempre | Sec. 5 («ID») |
| nombre | Nombre del maridaje («carnes rojas», «cordero al disco» de I2) | Explícito | Siempre | Sec. 5 y 3.3 |
| temperatura | Temperatura sugerida de servicio (°C) | Explícito | Siempre | Sec. 5 y 3.3 |

### 2.13 Vino–maridaje

Sin atributos propios según la consigna (solo participantes; se define en A-01: D-9 ¿en el DER como
entidad o como relación?).

### 2.14 Cliente

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| id_cliente | Identificador del cliente | Explícito | Siempre | Sec. 5 y 3.4 |
| nombre | Apellido y nombre (persona física) o razón social (empresa) | Explícito | Siempre | Sec. 5 («nombre o razón social») y 3.4 |
| tipo_doc | Tipo de documento (la consigna no fija dominio) | Explícito | Siempre | Sec. 5 y 3.4 |
| n_doc | Número de documento asociado al tipo anterior | Explícito | Siempre | Sec. 5 y 3.4 |
| direccion | Dirección del cliente | Explícito | Siempre | Sec. 5 y 3.4 |
| localidad | Localidad del cliente (la entidad Localidad) | Explícito (será una relación en el DER) | Siempre | Sec. 5 y 3.4 |
| fecha_alta | Fecha de alta del cliente | Explícito | Siempre | Sec. 5 y 3.4; DEFAULT «fecha de alta actual» (etapa 2) |
| descuento | Porcentaje de descuento del cliente | Explícito | Siempre | Sec. 5; RN-06; U6 (por subida de descuento a exportadores con más de 3 permisos) |

Dudas: (a) ¿el nombre del cliente en un campo o dos (persona vs. empresa)? Se definirá con D-1 de A-01. (b) ¿el descuento es atributo persistente o se obtiene directamente con una función
(`fn_descuento_cliente`)? Ver §5, Q-01. [Pregunta] P-9 (RN-06 vs U6) está pendiente.

### 2.15 Socio del club (subtipo)

Sin atributos propios según la consigna (ni 3.4 ni la sección 5 asignan datos adicionales; solo son
cliente con descuento del 10 % por RN-06). D-1 de A-01 (mapeo de la jerarquía) sigue provisional.

### 2.16 Distribuidor (subtipo)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| zona | Zona de cobertura comercial del distribuidor | Explícito | Siempre | Sec. 5 («zona y habilitación») y 3.4 |
| n_habilitacion | Número de habilitación comercial | Explícito | Siempre | Sec. 5 y 3.4 |

Nota: la zona es un dato del subtipo. La cobertura de localidades de transportistas (2.22) es otra
cosa (relación N:M). Ver §4, R-11.

### 2.17 Exportador (subtipo)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| pais | País de destino principal de la exportación | Explícito | Siempre | Sec. 5 y 3.4 |

Sus permisos son filas propias (2.18) por «puede tener varios» (3.4/RN-07).

### 2.18 Permiso de exportación

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| codigo | Código del permiso | Explícito | Siempre | Sec. 5 y 3.4 |
| fecha_emision | Fecha de emisión | Explícito | Siempre | Sec. 5 y 3.4 |
| fecha_vencimiento | Fecha de vencimiento (debe ser posterior a la emisión: CHECK entre columnas de RN-07) | Explícito | Siempre | Sec. 5 y 3.4; RN-07 |

Duda: ¿conviene un «estado» (vigente/vencido)? La consigna no lo pide; sería un estado derivado
de la fecha ([Inferencia]). Ver §5, Q-12.

### 2.19 Comprobante (cabecera)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| numero | Número de comprobante | Explícito | Siempre | Sec. 5 y 3.4 |
| fecha | Fecha de la venta | Explícito | Siempre | Sec. 5 y 3.4 |
| subtotal | Suma de subtotales de renglones (antes del descuento global) | Explícito (derivado) | Siempre, derivado | Sec. 5; RN-08 |
| descuento | Descuento del comprobante (por tipo de cliente) | Explícito (derivado) | Siempre, derivado | Sec. 5; RN-08 |
| total | Total del comprobante (subtotal menos descuento) | Explícito (derivado) | Siempre, derivado | Sec. 5; RN-08 |

Dudas: «cliente» y «sala» de la sección 5 se listan como datos del comprobante, pero a nivel de
entidad son participantes de relaciones (A-01 los modela así). La decisión «guardar o calcular» los
tres importes es la clásica y se queda para etapa 1/A-03 con justificación de forma escrita (§3 y §5).

### 2.20 Renglón de comprobante

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| cantidad | Botellas del vino en el renglón | Explícito | Siempre | Sec. 5 y 3.4; RN-15 |
| precio_unitario | Precio unitario **al momento de la venta** (histórico, distinto del precio vigente del vino: RN-01). Es un **valor histórico capturado y almacenado** (copia del precio vigente tomada al registrar la venta), no un valor que se calcule en consulta | Explícito | Siempre | Sec. 5 y 3.4; RN-01 |
| descuento | Descuento aplicado al renglón (duda: ¿porcentaje o importe?) | Explícito (con dominio dudoso) | Siempre (derivado) | Sec. 5 y 3.4; RN-08 |
| subtotal | Importe del renglón (cantidad por precio unitario, menos su descuento) | Explícito (derivado) | Siempre (derivado) | Sec. 5 y 3.4; RN-08 |

(el vino es participante de la relación; ver A-01 2.20.)

### 2.21 Transportista

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| codigo | Código del transporte | Explícito | Siempre | Sec. 5 y 3.5 |
| razon_social | Razón social de la empresa | Explícito | Siempre | Sec. 5 y 3.5 |
| cuit | Identificador fiscal (la etapa 2 prevé un DOMAIN para CUIT de 11 dígitos) | Explícito | Siempre | Sec. 5 y 3.5 |
| email | Correo de contacto | Explícito | Siempre | Sec. 5 y 3.5 |
| telefono | Teléfono de contacto | Explícito | Siempre | Sec. 5 y 3.5 |
| domicilio | Domicilio de la empresa | Explícito | Siempre | Sec. 5 y 3.5 |

### 2.22 Transportista cubre localidad

Sin atributos propios según la consigna (sección 5 lo lista como N:M Transportista–Localidad). En
el DER puede ser entidad asociativa o relación (D-9 de A-01, provisional).

### 2.23 Ingreso (cabecera)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| codigo | Código de ingreso | Explícito | Siempre | Sec. 5 y 3.5 |
| fecha | Fecha del ingreso (semántica sin definir: la consigna solo dice «fecha», sin aclarar con respecto de qué fase) | Explícito | Siempre (con valor semántico dudoso) | Sec. 5 y 3.5; para la transferencia, la misma sección fija la fecha de confección con «es la fecha actual y no puede modificarse» (RN-11) |
| estado | Estado del ingreso: en_confeccion / terminado / procesado (ENUM; ciclo de estados de RN-10) | Explícito | Siempre | Sec. 5 y 3.5; RN-10; DEFAULT «en_confeccion» (etapa 2) |
| transportista | Transportista que traslada el lote (la sección 5 lo lista entre los datos del ingreso) | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5 («Código, fecha, estado, transportista, bodega») y 3.5; RN-14 |
| bodega_origen | Bodega que remite el lote (la sección 5 la lista entre los datos del ingreso) | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5 («…transportista, bodega») y 3.5; RN-14 |

Dudas: (a) ¿la fecha del ingreso es una fecha de confección, como la de la transferencia? No hay
respaldo textual para extender la regla de RN-11 al ingreso (§5, Q-03). (b) No hay atributo adicional
para «fecha de proceso»: la consigna no lo pide; sería inferido del estado y su momento, si la
cátedra lo quisiera. (c) Borrado: la restricción de no borrar bodega/transportista con
movimientos es RN-14; no es atributo, y se tratará como acción referencial en A-03).

### 2.24 Renglón de ingreso

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| cantidad | Botellas del vino en el renglón | Explícito | Siempre | Sec. 5 y 3.5; RN-15 |

(el vino es participante de la relación entre Ingreso y Vino; ver A-01 2.24.)

### 2.25 Transferencia (cabecera)

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| numero | Número de solicitud | Explícito | Siempre | Sec. 5 y 3.5 |
| fecha_confeccion | Fecha de confección (es la fecha actual al crearlo, no modificable) | Explícito | Siempre | Sec. 5 y 3.5; RN-11 |
| estado | Estado: en_confeccion / terminado / procesado | Explícito | Siempre | Sec. 5 y 3.5; RN-11; DEFAULT «en_confeccion» |

(la sala solicitante es participante de la relación; ver A-01 2.25.)

### 2.26 Renglón de transferencia

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| cantidad | Botellas del vino solicitadas | Explícito | Siempre | Sec. 5 y 3.5; RN-15 |

(el vino es participante; ver A-01 2.26.)

### 2.27 Stock de sala

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| cantidad | Existencia del vino en la sala; con regla de no negatividad (RN-09; `[Pregunta]` P-6: ¿`> 0` o `>= 0`?) | Explícito | Siempre | Sec. 5 («Clave (sala, vino); cantidad >= 0») y 3.5 — la combinación (sala, vino) es **cita de la consigna, no decisión de diseño** (ver nota inicial de §2) |

Nota: la consigna no aporta otros atributos para stocks (p. ej. fecha de última actualización); el
detalle de movimientos es revisible en la historia de los documentos (ventas, transferencias,
ingresos). Si la cátedra pidiera más, se agregará en revisiones posteriores.

### 2.28 Stock de depósito

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| cantidad | Existencia del vino en el depósito central (único; nunca negativa) | Explícito | Siempre | Sec. 5 y 3.5; RN-09, RN-10, RN-11 |

### 2.29 Auditoría de precio

| Atributo | Descripción | Origen | Obligatoriedad | Referencia |
|---|---|---|---|---|
| id_auditoria | Identificador de la fila de auditoría (la sección 5 lo llama «ID») | Explícito | Siempre | Sec. 5 («ID, vino, precio anterior…») |
| vino | Vino cuyo precio se auditó (la sección 5 lo lista entre los datos de la fila) | Explícito (participante; será una relación en el DER) | Siempre | Sec. 5; RN-13 |
| precio_anterior | Precio previo al cambio | Explícito | Siempre | Sec. 5; RN-13 |
| precio_nuevo | Precio en vigor después del cambio | Explícito | Siempre | Sec. 5; RN-13 |
| fecha_hora | Fecha y hora del cambio | Explícito | Siempre | Sec. 5 («fecha y hora»); RN-13 |
| usuario | Usuario que efectuó el cambio | Explícito | Siempre | Sec. 5 («fecha, usuario, precio anterior y nuevo»); RN-13 |

Duda: ¿«usuario» es el usuario de BD del UPDATE (CURRENT_USER, roles de etapa 2) o un usuario
funcional de la aplicación? La consigna no lo define. Ver §5, Q-07.

---

## 3. Atributos derivados o calculados (sin decidir si se almacenan o se calculan)

La sección 5 exige decidir y justificar «cuáles se almacenan, cuáles se calculan y cómo se garantiza
su consistencia». Aquí solo se los inventaria; la elección queda abierta para A-03+:

| Atributo derivado | Dónde se presenta | Cómo se calcula (según la consigna) | Referencia |
|---|---|---|---|
| descuento (habitual) | Cliente | Según tipo: 10/20/30 % (RN-06) con `fn_descuento_cliente`; variante U6 (35 % si exportador con más de 3 permisos) pendiente de [Pregunta] P-9 | Sec. 5; RN-06; U6 |
| descuento (aplicado a la venta) | Renglón de comprobante | Relacionado al tipo del cliente del comprobante (3.4) | Sec. 5; 3.4; RN-08 |
| subtotal (renglón) | Renglón de comprobante | Cantidad por precio unitario con su descuento (RN-08) | Sec. 5; RN-08 |
| subtotal (cabecera) | Comprobante | Suma de subtotales de renglones | Sec. 5; RN-08 |
| total | Comprobante | Suma de renglones con el descuento; «No se carga a mano» (RN-08) con `fn_total_comprobante` | Sec. 5; RN-08; etapa 2 |
| stock total de un vino | Consulta (S9) | Stock de depósito más stock de salas; se calcula en la consulta, no se almacena | S9 |
| movimiento / actividad | Consultas (S4, S7) | Agregación en la consulta, no atributo | Sec. 8 |
| rendimiento kg/ha | Consulta (S10) | kg del lote ÷ superficie (parcela/finca), se calcula en la consulta | S10 |
| antigüedad (años) | Empleado | Años desde fecha_ingreso (`fn_antiguedad_anios`), sin atributo almacenado | Sec. 5; etapa 2; U2 |
| vigencia de permiso | Permiso de exportación | `[Inferencia]` derivable de fecha_vencimiento (sin atributo almacenado) | RN-07 |

Nota: el **precio unitario del renglón** ya **no** figura en esta tabla. Aunque su valor proviene
del precio del vino, la consigna lo define explícitamente como dato del renglón conservado «al
momento de la venta» (3.4): es un **valor histórico capturado y almacenado**, no un cálculo. Se
distingue así de los verdaderamente calculados (subtotal, descuento y total). Cómo se captura ese
valor al registrar la venta (mecanismo de implementación) queda indeciso para A-03+.
| pendientes por sala (derivado) | Consulta (S5) | Se obtiene del estado de las transferencias; sin atributo adicional | S5 |

> La «regla de oro» (sección 6) dice que la API no recalcula; todos estos cálculos deben quedar en
> funciones/triggers de la base. La **materialización física** (guardar o calcular) es la decisión
> pedida por escrito por la sección 5 y queda pendiente para A-03+.

---

## 4. Posibles redundancias o atributos que podrían depender de otra entidad

Observaciones para la revisión de normalización (hasta 3FN, etapa 1 paso 4), sin decidir nada:

| N.° | Posible redundancia / dependencia | Situación | Referencia |
|---|---|---|---|
| R-1 | Encargado regional en Localidad vs. en cada Sala | Si estuviera repetido por sala, dependería de una propiedad de la localidad (dependencia transitiva). La etapa 1 usa justamente `localidad → encargado regional` como ejemplo de dependencia funcional. | 3.1; 5; RN-02; etapa 1, paso 4 |
| R-2 | Provincia en Localidad y en Finca (y departamento en función de la finca) | El Anexo B lista departamentos de Mendoza (catálogo de carga). ¿Catálogo o atributos sueltos? sin decisión (Q-11). | 3.1; 3.2; Anexo B |
| R-3 | Descuento del Cliente (habitual) vs. descuento del Comprobante (aplicado a la venta) vs. descuento del Renglón (por línea) | Tres niveles con roles distintos; el renglón guarda el valor histórico del momento. | 3.4; 5; RN-06, RN-08 |
| R-4 | Precio actual del vino vs. precio unitario del renglón | El renglón copia el precio al momento de la venta (histórico): no cambia aunque el precio del vino cambie; esa copia es lo que garantiza que las ventas antiguas no se reescriban (RN-01 y RN-13 están alineados). | 3.3; 3.4; RN-01, RN-13 |
| R-5 | Total del comprobante vs. suma de renglones con descuento | Si se guarda, hay que garantizar la igualdad (trigger/fn). Punto explícito del PDF: «No se carga a mano». | RN-08; sección 5 «decisiones de diseño» |
| R-6 | Stock total de un vino (depósito + salas) | Es derivado por consulta (S9), no atributo que se almacene por vino. | S9; secciones 5 y 3.5 |
| R-7 | Superficie total de la finca vs. suma de superficies de parcelas | La superficie de la finca es su propio dato; la suma de parcelas se calcula si se necesita (S10 usa datos de parcela y finca por separado en consultas). | 3.2; 5; S10 |
| R-8 | kg del lote y superficie del lote en parcela/campaña | kg residen en el lote (fuente única); no habría «producción total» como atributo de finca. | 3.2; 5; S10 |
| R-9 | Estado del documento (ingreso/transferencia) como fuente de verdad | La consulta de «pendientes» (S5) deriva del estado; no hay atributo adicional de «pendiente». | 3.5; RN-10, RN-11 |
| R-10 | Descuento como atributo vs. función de descuento | Si el descuento vive tanto en el cliente como en la función, hay que evitar dos definiciones divergentes (la función + CHECK de rango previene inconsistencias, como pide RN-06). | 5; RN-06 |
| R-11 | Zona de cobertura del distribuidor vs. cobertura de localidades del transportista | Dos conceptos distintos que comparten la palabra «cobertura». No unificar sin respaldo. | 3.4; 3.5 |
| R-12 | CUIT y código postal como claves naturales vs. IDs subrogados | La sección 5 pide justificar la elección caso por caso («CUIT y código postal frente a identificadores autogenerados»). No se decide aquí. | 5 «decisiones de diseño» |

---

## 5. Atributos dudosos y decisiones pendientes

Se numera cada duda (Q-01, Q-02, …) para la discusión con Persona B y el docente:

| N.° | Duda | Alternativas | Estado / qué falta |
|---|---|---|---|
| Q-01 | Descuento del cliente: ¿atributo almacenado o función? | (a) atributo en Cliente/subtipo; (b) solo `fn_descuento_cliente` + CHECK de rango; (c) híbrido: función para el vigente y valor histórico en el renglón | RN-06: «Función de descuento + CHECK»; la sección 5 lista «descuento» como atributo de Cliente; la [Pregunta] P-9 (RN-06 vs U6) está pendiente en `requisitos.md`. No decidir hasta aclararlo |
| Q-02 | Identidad del lote de uva | (a) n.° de lote como identificador propio; (b) identidad (parcela, campaña) con el UNIQUE de RN-04 | La sección 5 habla de «N.° de lote»; RN-04 ya marca cada lote por (parcela, campaña). No resuelto |
| Q-03 | Semántica de la «fecha» del Ingreso | (a) fecha de confección del documento (análoga a la de la transferencia de RN-11); (b) fecha del traslado a depósito | 3.5 dice «fecha» sin más; RN-11 solo aclara el caso de la transferencia. [Inferencia] (a). **[Pregunta] candidata para el docente** |
| Q-04 | Nombre del Cliente: un campo único o dos atributos | (a) uno («apellido y nombre o razón social»); (b) dos (persona/empresa) según subtipo | Depende de D-1 de A-01; decidir con Q-03 |
| Q-05 | ¿El descuento del renglón es porcentaje o importe? | (a) porcentaje; (b) importe; (c) ambos | 3.4 dice «descuento aplicado (directamente relacionado al tipo de cliente)», sin dominio exacto |
| Q-06 | Identidad de la fila de análisis de calidad | (a) ID propia (como la asigna la sección 5); (b) identidad derivada de (lote, fecha) | D-6 de A-01, provisional. Pendiente de confirmar reglas del negocio |
| Q-07 | ¿«Usuario» de la auditoría es el usuario de BD o uno funcional? | (a) usuario de BD (roles de etapa 2); (b) usuario funcional si existiera | La consigna describe 3 roles de BD, sin usuarios de aplicación |
| Q-08 | ¿El salario está alcanzado por la positividad de RN-15? | (a) sí, con CHECK; (b) no; la regla no lo menciona | RN-15 menciona «cantidades, superficies, kilos y precios», sin salarios. **[Pregunta] candidata** |
| Q-09 | Dominio de dia_cierre | (a) lunes–domingo; (b) con un valor «sin cierre» | PDF no lo acota; U4 usa lunes/miércoles |
| Q-10 | Direcciones: un solo campo o desglosadas (piso, depto., etc.) | (a) campo único; (b) desglosado | La consigna solo pide «dirección» (3.4/5) y «calle y número» (3.1/5); sin indicación textual adicional |
| Q-11 | ¿Departamento/provincia como catálogo? | (a) atributos sueltos; (b) catálogo de departamentos (Anexo B) | Anexo B carga departamentos de Mendoza vía CSV; pendiente de decidir su rol |
| Q-12 | ¿Estado (vigente/vencido) del permiso de exportación? | (a) no modelarlo (derivable de la fecha); (b) atributo de estado | La consigna no lo pide; `[Inferencia]` (a) y revisar si alguna consulta lo usa (ninguna consulta la usa por ahora) |
| Q-13 | ¿Guarda atributos extra para stocks (fecha de última actualización, histórico)? | (a) solo cantidad (como la consigna); (b) agregar fecha_hora de actualización | La consigna lista solo cantidad; sin respaldo no se agrega |

Y los **conceptos provisionales de A-01 continúan abiertos** (sin descartar): D-1 (mapeo de la
jerarquía Cliente), D-2 (débil vs. asociativa para renglones y stocks), D-3 (stock de depósito
separado), D-4 (encargado regional), D-5 (campaña como atributo del lote), D-6 (análisis de calidad:
débil o no), D-7 (sin tabla intermedia parcela–cepa), D-8 (sin transportista en comprobantes de
venta), D-9 (N:M como entidad vs. relación en el DER), D-10 (auditoría de precio dentro del DER).

---

## 6. Referencias a la consigna

| Bloque de este documento | Referencia en el PDF |
|---|---|
| Lista primaria de atributos por entidad (§2) | Sección 5 (tabla «Modelo de datos: entidades mínimas») |
| Descripción detallada de cada dato (apellido/nombre o razón social, fecha de confección, kilos, Brix/pH/acidez, zona y habilitación, país de destino, etc.) | Sección 3.1–3.5 |
| Reglas que condicionan atributos (positividad; graduación 5–20; suma 100; vencimiento > emisión; stock no negativo; precio único > 0) | Sección 4, RN-01…RN-15 |
| Reglas que evitan recálculos manuales (descuento por tipo, total no manual, fecha de confección no modificable, auditoría de precio) | RN-06, RN-08, RN-11, RN-13 |
| Atributos derivados a decidir (guardar vs. calcular y justificar) | Sección 5 «decisiones de diseño que deben tomar y justificar por escrito» |
| Restricciones de formato: DOMAIN CUIT (11 dígitos), ENUM de estado, UNIQUE (nombre, añada, volumen) en vino; (parcela, campaña) en lote; CUIT de bodega; DEFAULT (estado en_confeccion; fecha de alta actual) | Sección 7, etapa 2 («Requisitos mínimos») |
| Consultas que confirman el uso de cada atributo | Sección 8 (U1–U6, I1–I6, D1–D6, S1–S12) |
| Catálogos de carga (cepas, maridajes, departamentos; volúmenes de presentación) | Anexo B |
| Antecedente inmediato | `docs/modelo/01_entidades_candidatas.md` (A-01) |

---

## 7. Resumen de cuestiones que deben revisarse con Persona B

Ordenado por impacto estimado en el resto del diseño:

1. **D-1 de A-01 + Q-04:** estrategia de mapeo de la jerarquía Cliente y, acorde a eso, cómo
   representar el nombre (persona/empresa) y los atributos de subtipos (zona, habilitación, país).
2. **Q-05 + R-3 + R-10:** qué significa exactamente el «descuento» del renglón/comprobante (¿% o
   importe?) y dónde vive el valor: función (RN-06) frente a valores guardados.
3. **R-5 (pedido explícito de la sección 5):** subtotal/total del Comprobante: ¿guardar o calcular?
   Impacta triggers de etapa 2 (RN-08) y pruebas.
4. **Q-02:** identidad del lote (n.° de lote vs. (parcela, campaña)).
5. **Q-03:** semántica de la fecha del Ingreso (¿fecha de confección como en la Transferencia?).
6. **Q-01:** descuento: atributo vs. función (con la [Pregunta] P-9: RN-06 30 % general vs U6 35 %).
7. **D-2/D-9 de A-01:** notación de renglones/stocks y N:M en el DER (débil vs. asociativa); no
   cambia la lista de atributos, sí la justificación.
8. **D-4 de A-01 + R-1:** encargado regional: atributo de Localidad (o datos de contacto adicionales;
   hipotéticamente, su posible vínculo con la entidad Empleado).
9. **D-6 de A-01 + Q-06:** identidad de la fila de análisis de calidad (ID propia vs (lote, fecha)).
10. **Q-07:** qué usuario se audita (BD vs. aplicación) y su relación con los roles de etapa 2.
11. **Q-08–Q-13:** dominios menores sin exigencia textual (salario positivo, días de cierre, campo
    único de dirección, catálogo de provincias/departamentos, estado de permiso, atributos extra de
    stocks) — consultar al docente si no hay indicación en la consigna.
12. **D-3 de A-01:** separación física del stock de sala y del stock de depósito (provisional:
    separados, como la sección 5).
13. **D-5/D-7/D-8/D-10 de A-01:** campaña como atributo; sin tabla intermedia parcela–cepa; sin
    transportista en comprobantes; auditoría de precio en el DER (provisionales, alineados con A-01).

> Documento siguiente previsto: **A-03** — relaciones, cardinalidades y resolución de las decisiones
> abiertas pertinentes antes de armar el DER definitivo.

---

### Registro de cambios de este documento

- Creación (A-02): inventario de atributos por entidad (con origen explícito/inferencia,
  obligatoriedad conceptual y referencia al PDF), atributos derivados inventariados sin decidir su
  materialización, redundancias candidatas, dudas Q-01…Q-13 y vínculo con conceptos provisionales de
  A-01 (D-1…D-10).
- Revisión tras auditoría interna: se incorporan los participantes explícitos de la sección 5 que
  faltaban (Sala→localidad, Empleado→sala, Lote→parcela, Análisis→lote, Vino→bodega,
  Ingreso→transportista/bodega, Auditoría→ID/vino), todos marcados como datos explícitos que serán
  relaciones en el DER (sin claves ni cardinalidades). El precio unitario del renglón se reclasifica
  como valor histórico capturado y almacenado (ya no como derivado). Las dudas se renombran
  Q-01…Q-13 para no colisionar con las issues A-01/A-03. Notas aclaratorias sobre el CUIT de bodega
  (UNIQUE de la etapa 2) y sobre combinaciones citadas por la consigna (no son decisiones de diseño).

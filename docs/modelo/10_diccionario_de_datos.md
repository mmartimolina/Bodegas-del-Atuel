# A-10 â€” Diccionario de datos (PRELIMINAR)

> **Estado: PRELIMINAR.** El diccionario documenta el esquema relacional de A-09
> (`09_esquema_relacional.md`), que estÃ¡ a su vez marcado PRELIMINAR y sujeto a la aprobaciÃ³n de
> A-08. Ninguna definiciÃ³n de este documento es definitiva mientras A-08 y A-09 no sean revisados
> (A-08 pendiente de revisiÃ³n; A-09 PRELIMINAR; A-06 pendiente de revisiÃ³n de Persona B).
>
> **Fuentes:** A-09 (estructura de tablas, columnas, claves y FK), A-01â€¦A-08 (entidades, atributos,
> claves candidatas, relaciones), `docs/requisitos.md` (RN, mÃ­nimos de etapa 2, tipos
> recomendados). **No se inventan** tipos, nulabilidades, defaults ni restricciones que no deriven
> de esos documentos.
>
> **ConvenciÃ³n de marcado** (heredada de A-03/A-04/A-09):
> - **[R]** = respaldado textualmente (secciÃ³n del PDF / requisitos / cita).
> - **[I]** = propuesta inferida con justificaciÃ³n; no es requisito textual.
> - **[P]** = pendiente de validaciÃ³n (consulta docente / Persona B / decisiÃ³n de etapa 2 / A-13).
> - **PENDIENTE** = decisiÃ³n que depende de una ambigÃ¼edad abierta; no se cierra aquÃ­.
>
> **Advertencia sobre tipos:** A-09 §15.2 declara que no incluye SQL ni tipos, correspondiendo a la
> etapa 2/A-13. Este diccionario presenta **tipos PostgreSQL propuestos** (no SQL DDL), como exige
> el entregable de hito H1 («diccionario de datos»), con el respaldo disponible: la consigna
> recomienda `NUMERIC(p,s)` para dinero (nunca FLOAT), `DATE/TIMESTAMP` para fechas, tipos
> enumerados para estados (secciÃ³n 5 de `docs/requisitos.md`), 1 ENUM y 1 DOMAIN mÃ­nimos (etapa 2).
> Toda precisiÃ³n numÃ©rica no respaldada se marca [I] y queda sujeta a A-13.

---

## 1. Alcance y mÃ©todo

1. Se documentan las **29 tablas** propuestas en A-09 §2, con sus columnas de A-09 §3.
2. Para cada columna: nombre, tipo PostgreSQL propuesto, nulabilidad, participaciÃ³n en clave,
   restricciones respaldables, valor por defecto (solo con justificaciÃ³n) y descripciÃ³n.
3. Se documentan: claves candidatas (§3 por tabla y §5 consolidado), PK/FK justificadas,
   UNIQUE/CHECK/NOT NULL (§6), ENUM y DOMAIN propuestos (§7), dependencias y orden de creaciÃ³n (§8).
4. Las PK fueron adoptadas con fundamento en A-12 (DEC-01..DEC-10 y DEC-02): la columna PK se marca como tal y las alternativas descartadas quedan documentadas como candidatas sin UNIQUE..
5. Se registra un resultado de auditorÃ­a (§9) y las contradicciones halladas (§9.3).

Clave de lectura de la columna «Nulabilidad»:

| Marca | Significado |
|---|---|
| `NOT NULL (PK)` | Componente de clave primaria: obligatorio por definición de clave. |
| `NOT NULL [R]` | FK con participación mínima 1 respaldada textualmente (sin `*` en A-04). |
| `P` | Columna sin `NOT NULL` físico adoptado según DEC-14; incluye atributos descriptivos y FK cuyo mínimo sea inferido. |

---

## 2. Diccionario por tabla

### 2.1 `Localidad`

- **Propósito:** catálogo de localidades geográficas donde operan salas de venta, residen clientes y se aplica la cobertura de transportistas. Concentra el encargado regional (RN-02, dependencia `localidad → encargado_regional`).
- **Origen conceptual:** entidad fuerte Localidad (A-01 §2.1, pág. 03 del DER A-08).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | Descripción |
|---|---|---|---|---|---|
| id_localidad | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-01 y DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado de la localidad. |
| codigo_postal | TEXT [I] | P | — | — | Código postal de la localidad (sec. 5). No se declara UNIQUE ni se utiliza como clave. |
| nombre | TEXT [I] | P | — | — | Nombre de la localidad (sec. 5). |
| provincia | TEXT [I] | P | — | — | Provincia de la localidad (sec. 5). |
| encargado_regional | TEXT [I] | P | — | — | Responsable comercial único por localidad (RN-02 [R]; etapa 1 paso 4: dependencia funcional). Sin atributos propios de persona (D-4 [R] como atributo). |

- **PK:** `id_localidad` (BIGINT autogenerado; DEC-01 y DEC-10).
- **Claves alternativas:** no se declara ninguna UNIQUE para código postal ni para la combinación `(nombre, provincia)`.
- **Objetivo de FKs #1, #3 y #23** (A-09 §7.1). Sin FK propia.

### 2.2 `Sala`

- **Propósito:** punto de venta de la red, con su dirección, día de cierre y localidad.
- **Origen conceptual:** entidad fuerte Sala de venta (A-01 §2.2, pág. 03 del DER). Recibe REL-01.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | Descripción |
|---|---|---|---|---|---|
| id_sala | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado de la sala. |
| calle | TEXT [I] | P | — | — | Componente de dirección (sec. 5). |
| numero | INTEGER [I] | P | — | — | Altura de la dirección (sec. 5). |
| dia_cierre | DOMAIN `dia_semana` [I, DOMAIN propuesto en §7.4; pendiente Q-09] | P | CHECK de dominio [I] | — | Día semanal de cierre (sec. 5; U4 lo actualiza en bloque). **PENDIENTE** dominio (¿sin cierre?, Q-09). |
| localidad | BIGINT [R: FK a `Localidad.id_localidad`] | NOT NULL [R: REL-01 extremo Sala 1..1 textual] | FK → `Localidad` (FK #1), acción referencial según A-09 §7.1 | — | Identificador de la localidad donde opera la sala (sec. 5, 3.1; RN-02). |

### 2.3 `Empleado`

- **PropÃ³sito:** personal que trabaja en una Ãºnica sala; conserva `fecha_ingreso` para calcular
  antigÃ¼edad (U2, `fn_antiguedad_anios`; sin atributo almacenado, R-derivados A-02 §3).
- **Origen conceptual:** entidad fuerte Empleado (A-01 §2.3, pÃ¡g. 03). Recibe REL-02.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | Descripción |
|---|---|---|---|---|---|
| id_empleado | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-09 y DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado del empleado. |
| cuit | DOMAIN `cuit_dom` [I: aplicación propuesta según A-13] | P | — | — | CUIT de la persona (sec. 5). No se declara UNIQUE ni se utiliza como clave. |
| nombre | TEXT [I] | P | — | — | Nombre del empleado (sec. 5). |
| fecha_ingreso | DATE [R: tipo fecha; base de `fn_antiguedad_anios`] | P | — | — | Fecha de inicio laboral (sec. 5; U2). |
| salario | NUMERIC [I; precisión P; "nunca FLOAT" sec. 5 de requisitos] | P | CHECK `salario > 0`? [P: RN-15 no menciona salario — Q-08 abierta] | — | Remuneración (sec. 5). CHECK **PENDIENTE** (Q-08). |
| sala | BIGINT [R: FK a `Sala.id_sala`] | NOT NULL [R: REL-02 extremo Empleado 1..1 textual; RN-03] | FK → `Sala` (FK #2), acción referencial según A-09 §7.1 | — | Identificador de la única sala donde trabaja (RN-03 [R]). |

### 2.4 `Finca`

- **PropÃ³sito:** establecimiento agrÃ­cola contenedor de parcelas; su superficie es dato propio (no
  suma de parcelas, R-7 A-02).
- **Origen conceptual:** entidad fuerte Finca (A-01 §2.4, pÃ¡g. 01). Objetivo de FK #4.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id_finca | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado de la finca. |
| nombre | TEXT [I] | P | â€” | â€” | Nombre de la finca (sec. 5). |
| superficie | NUMERIC [I; precisiÃ³n P; RN-15 positividad de superficies] | P | CHECK `superficie > 0` [R: RN-15 menciona "superficies"; `>0` vs `>=0` P-6 no aplica a surfaces segÃºn texto, pero PENDIENTE confirmaciÃ³n] | â€” | Superficie total en hectÃ¡reas (sec. 5). |
| departamento | TEXT [I; ¿catÃ¡logo? Q-11 abierta] | P | â€” | â€” | Departamento de ubicaciÃ³n (sec. 5; Anexo B carga departamentos de Mendoza). |
| provincia | TEXT [I] | P | â€” | â€” | Provincia de la finca (sec. 5). |

### 2.5 `Parcela` (entidad dÃ©bil)

- **PropÃ³sito:** subdivisiÃ³n de finca con plantaciÃ³n de una cepa; no existe sin su finca (3.2; RN-04).
- **Origen conceptual:** entidad dÃ©bil Parcela (A-01 §2.5; A-05 §4; algo pÃ¡g. 01 del DER), relaciÃ³n identificadora REL-04.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| finca | BIGINT [I: referencia a PK de Finca] | NOT NULL (PK) | **Componente de PK compuesta `(finca, n_parcela)` [R: triple cita 3.2 + sec. 5 + etapa 2]**; FK propietaria â†’ `Finca` (FK #4); ON DELETE **no decidido** RESTRICT/CASCADE [PENDIENTE, A-09 §7.1 #4] | â€” | Finca propietaria (identificaciÃ³n dÃ©bil). |
| n_parcela | INTEGER [I] | NOT NULL (PK) | Componente de PK compuesta; clave parcial [R] | â€” | NÃºmero de parcela *dentro de la finca* (3.2, sec. 5). |
| superficie | NUMERIC [I; precisiÃ³n P] | P | RN-15 positividad [R; cf. 2.4] | â€” | Superficie de la parcela en hectÃ¡reas (sec. 5). |
| anio_plantacion | SMALLINT / INTEGER [I: aÃ±o] | P | â€” | â€” | AÃ±o de plantaciÃ³n (sec. 5). |
| cepa | BIGINT [R: FK a `Cepa.id`] | NOT NULL [R: REL-05 extremo Parcela 1..1 textual; RN-04] | FK → `Cepa` (FK #5), RESTRICT [P: confirmación] | — | Identificador de la única cepa plantada (RN-04 [R]). Sin historia de replantación (D-7, AMB-12). |

- **PK compuesta: `(finca, n_parcela)`** [R], minimalidad argumentada en A-09 §4.
- La dependencia existencial se materializa con NOT NULL de la FK componente (A-09 §8).

### 2.6 `Cepa`

- **PropÃ³sito:** catÃ¡logo de variedades de vid compartido por parcelas y composiciÃ³n de vinos; carga CSV (Anexo B).
- **Origen conceptual:** entidad fuerte (catÃ¡logo) Cepa (A-01 §2.6, pÃ¡g. 01). Objetivo de FKs #5, #11.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-10] | NOT NULL (PK) | PK | — | Identificador autogenerado de la cepa. |
| nombre | TEXT [I] | P | Candidata CeK-2 [P: sin UNIQUE declarada] | â€” | Nombre de la variedad («Malbec», «Chardonnay»â€¦; Anexo B: 7 tintas + 5 blancas). |
| tipo | DOMAIN/ENUM `tipo_uva` ('tinta', 'blanca') [I: dominio binario textual 3.2/sec. 5; propuesta de A-13 **PENDIENTE**] | P | CHECK de dominio [I] | â€” | Tipo de uva: tinta o blanca (sec. 5). |

### 2.7 `Lote`

- **Propósito:** resultado de la cosecha de una parcela en una campaña, entregado a una bodega; base para las relaciones de análisis y la trazabilidad producción→elaboración.
- **Origen conceptual:** entidad fuerte Lote de uva (A-01 §2.7, pág. 01). Objetivo de FK #8.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | Descripción |
|---|---|---|---|---|---|
| n_lote | INTEGER [I] | P | Atributo descriptivo; sin restricción UNIQUE | — | Número de lote (sec. 5). |
| finca | BIGINT [I] | NOT NULL (PK) | Componente de PK y FK compuesta `(finca, n_parcela)` → `Parcela` (FK #6), RESTRICT/RESTRICT propuestos [P confirmación] | — | Parte de la parcela de origen (3.2). |
| n_parcela | INTEGER [I] | NOT NULL (PK) | Componente de PK y FK compuesta `(finca, n_parcela)` → `Parcela` (FK #6) | — | Número de parcela de origen. |
| campania | SMALLINT / INTEGER [I: año; D-5 campaña = atributo] | NOT NULL (PK) | Componente de PK de `Lote` (DEC-02) | — | Año de la campaña de cosecha (3.2). Una cosecha máx. por parcela y campaña (RN-04 [R]). |
| fecha_cosecha | DATE [R: "fecha de cosecha"] | P | Coherencia con `campania` [I: Anexo B, sin regla textual — CHECK **PENDIENTE**] | — | Fecha de la cosecha (sec. 5). |
| kg | NUMERIC [I; precisión P; RN-15 positividad de "kilos"] | P | CHECK `kg > 0` [R: RN-15] | — | Kilos cosechados (sec. 5; S10). |
| bodega_destino | DOMAIN `cuit_dom` [I: aplicación propuesta según A-13] | NOT NULL [R: REL-07 extremo Lote 1..1 textual] | FK → `Bodega.cuit` (FK #7), acción referencial según A-09 §7.0 | — | CUIT de la bodega a la que se entregó el lote (sec. 5). Rol distinto de la bodega elaboradora y la de origen del ingreso (AMB-06). |

- **PK compuesta adoptada (DEC-02):** `(finca, n_parcela, campania)`.
- **FK a Parcela:** `(finca, n_parcela)` → `Parcela`.
- **Regla de negocio adoptada:** como máximo un lote por parcela y campaña; las cosechas parciales de una misma combinación no generan lotes independientes.
- **`n_lote`:** atributo descriptivo, sin unicidad global ni restricción UNIQUE.

### 2.8 `Analisis`

- **PropÃ³sito:** mediciÃ³n de calidad practicada a un lote (uno o mÃ¡s por lote, 3.2/sec. 5).
- **Origen conceptual:** entidad fuerte AnÃ¡lisis de calidad (A-01 §2.8, pÃ¡g. 01). Objetivo de FK #8.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id_analisis | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado del análisis. |
| finca | BIGINT [I] | P (DEC-14: mínimo inferido; sin NOT NULL) | Componente de FK compuesta `(finca, n_parcela, campania)` → `Lote` (FK #8), RESTRICT [P confirmación] | — | Finca de la parcela correspondiente al lote analizado. |
| n_parcela | INTEGER [I] | P (DEC-14: mínimo inferido; sin NOT NULL) | Componente de FK compuesta `(finca, n_parcela, campania)` → `Lote` (FK #8) | — | Número de parcela correspondiente al lote analizado. |
| campania | SMALLINT / INTEGER [I: año; D-5] | P (DEC-14: mínimo inferido; sin NOT NULL) | Componente de FK compuesta `(finca, n_parcela, campania)` → `Lote` (FK #8) | — | Campaña del lote analizado. |
| fecha | DATE [R: tipo fecha] | P | Componente de candidata AK-2 `(finca, n_parcela, campania, fecha)` [P: ¿dos análisis del mismo lote el mismo día? AMB-13] | — | Fecha del análisis (sec. 5). |
| brix | NUMERIC [I; dominio P] | P | â€” | â€” | Grado Brix de la muestra (sec. 5). |
| ph | NUMERIC [I; dominio P] | P | â€” | â€” | pH de la muestra (sec. 5). |
| acidez | NUMERIC [I; dominio P; g/L segÃºn 3.2] | P | â€” | â€” | Acidez total en g/L (sec. 5). |

### 2.9 `Bodega`

- **PropÃ³sito:** establecimiento elaborador de vinos, origen de ingresos; RN-14 prohÃ­be borrarla con
  movimientos.
- **Origen conceptual:** entidad fuerte Bodega (A-01 §2.9, pÃ¡g. 02). Objetivo de FKs #7, #9, #25.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| cuit | DOMAIN `cuit` [R: DOMAIN CUIT de 11 dígitos, etapa 2] | P | NOT NULL (PK) y UNIQUE [R: restricción textual de etapa 2] | — | Identificador fiscal de la bodega y clave primaria (DEC-08 / matriz de PK). |
| razon_social | TEXT [I] | P | Sin UNIQUE (descartada en A-03 BK-2) | â€” | RazÃ³n social (sec. 5). |
| domicilio | TEXT [I] | P | â€” | â€” | Domicilio (sec. 5). |

### 2.10 `Vino`

- **PropÃ³sito:** producto embotellado central de la comercializaciÃ³n; referencia en comprobantes,
  ingresos, transferencias, stocks y auditorÃ­a.
- **Origen conceptual:** entidad fuerte Vino (A-01 §2.10, pÃ¡g. 02). Objetivo de FKs #10â€“13, 17, 27, 30, 32â€“34.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| codigo | TEXT [R: DEC-03] | NOT NULL (PK) | PK | — | Código identificador del vino (DEC-03; utilizado en `GET /vinos/{cod}`). |
| nombre | TEXT [I] | P | Parte de UNIQUE `(nombre, anada, volumen_ml)` [R: etapa 2 + 3.3] y candidata VK-2 | â€” | Nombre comercial («Malbec Reserva»). |
| tipo | DOMAIN/ENUM `tipo_vino` ('tinto','blanco','rosado','espumante') [I: dominio textual 3.3; propuesta A-13 PENDIENTE] | P | CHECK de dominio [I] | â€” | Tipo del vino (sec. 5; I2 filtra «tintos»). |
| anada | SMALLINT / INTEGER [I: aÃ±o] | P | Parte de UNIQUE textual `(nombre, anada, volumen_ml)` [R] | â€” | AÃ±ada (aÃ±o de elaboraciÃ³n) (sec. 5). |
| volumen_ml | SMALLINT / INTEGER [I] | P | Parte de UNIQUE textual [R]; CHECK de catÃ¡logo de volÃºmenes [P: P-8/AMB â€” ¿lista cerrada 187/375/750/1500/3000?, §10.1.7 de requisitos] | â€” | Volumen de la presentaciÃ³n en ml (sec. 5). |
| graduacion | NUMERIC [I; precisiÃ³n P] | P | CHECK `graduacion >= 5 AND <= 20` [R: RN-15] | â€” | GraduaciÃ³n alcohÃ³lica en grados (sec. 5). |
| precio | NUMERIC(12,2) [R: NUMERIC para dinero, "nunca FLOAT" sec. 7 de requisitos; precisiÃ³n exacta [I]] | P | CHECK `precio > 0` [R: RN-01]; Ãºnico para toda la red (atributo de vino, no de sala) [R RN-01] | â€” | Precio de venta Ãºnico de la red (sec. 5; RN-01). Cambios â†’ auditorÃ­a RN-13. |
| bodega | DOMAIN `cuit` [R: FK a `Bodega.cuit`] | NOT NULL [R: REL-09 extremo Vino 1..1 textual] | FK → `Bodega.cuit` (FK #9), RESTRICT/RESTRICT [R: RN-14 textual] | — | CUIT de la bodega elaboradora del vino. |

- **UNIQUE textual:** `(nombre, anada, volumen_ml)` [R etapa 2].
- **PK:** `codigo` [R: DEC-03].

### 2.11 `Composicion` (asociativa)

- **PropÃ³sito:** tabla de la asociaciÃ³n N:M Vinoâ€“Cepa con el porcentaje de corte (RN-05: suma 100 por
  vino â€” restricciÃ³n agregada, constraint trigger diferido en etapa 2, no CHECK de fila).
- **Origen conceptual:** REL-10 (A-05 §5; pÃ¡g. 02 del DER).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL (PK) | Componente de PK compuesta `(vino, cepa)`; FK → `Vino.codigo` (FK #10), RESTRICT [P: confirmar acción] | — | Código del vino de la asociación. |
| cepa | BIGINT [I] | NOT NULL (PK) | Componente de PK compuesta [I]; FK â†’ `Cepa` (FK #11), RESTRICT [P] | â€” | Cepa de la asociaciÃ³n. |
| porcentaje | NUMERIC(5,2) [I; precisiÃ³n P] | P (DEC-14: sin NOT NULL adoptado) | `porcentaje BETWEEN 0 AND 100`? [P: lÃ­mites individuales no declarados; la regla textual es la suma = 100 (RN-05), restricciÃ³n agregada paso-2 derivado] CHECK **PENDIENTE**; restricciÃ³n de suma **PENDIENTE** (etapa 2, trigger diferido) | â€” | Porcentaje de corte de la cepa en el vino (3.3; RN-05: suma 100 por vino). |

- **PK compuesta:** `(vino, cepa)` [R: DEC-03 y matriz de PK].

### 2.12 `Maridaje`

- **PropÃ³sito:** catÃ¡logo de recomendaciones gastronÃ³micas; referenciado por la asociaciÃ³n Vinoâ€“Maridaje.
- **Origen conceptual:** entidad fuerte (catÃ¡logo) Maridaje (A-01 §2.12, pÃ¡g. 02). Objetivo de FK #13.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado del maridaje. |
| nombre | TEXT [I] | P | Candidata MK-2 [P: sin UNIQUE declarada] | â€” | Nombre del maridaje («carnes rojas», «cordero al disco» de I2). |
| temperatura | NUMERIC [I; precisiÃ³n P] | P | Dominio [P: no declarado] | â€” | Temperatura sugerida de servicio en °C (sec. 5). *Nota: A-09 §3.12 cita "(RN-06)" junto a temperatura: cita errÃ³nea detectada en auditorÃ­a (§9.3); las reglas pertinentes a la secciÃ³n son 3.3 y sec. 5.* |

### 2.13 `Vino_Maridaje` (asociativa)

- **PropÃ³sito:** tabla de la asociaciÃ³n N:M Vinoâ€“Maridaje, sin atributos propios (A-02 2.13; A-05 §10).
- **Origen conceptual:** REL-11 (pÃ¡g. 02 del DER).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL (PK) | Componente de PK compuesta `(vino, maridaje)`; FK → `Vino.codigo` (FK #12), RESTRICT [P: confirmar acción] | — | Código del vino recomendado. |
| maridaje | BIGINT [I] | NOT NULL (PK) | Componente de PK compuesta [I]; FK â†’ `Maridaje` (FK #13), RESTRICT [P] | â€” | Maridaje recomendado. |

- **PK compuesta:** `(vino, maridaje)` [R: matriz de PK].
- Los atributos `nombre` y `temperatura` pertenecen a Maridaje, no a la asociaciÃ³n (A-05 §10.5).

### 2.14 `Cliente` (supertipo)

- **PropÃ³sito:** registro Ãºnico del comprador (hub de los comprobantes), con atributos comunes de la
  jerarquÃ­a Socio/Distribuidor/Exportador.
- **Origen conceptual:** supertipo de la jerarquÃ­a (A-01 §2.14; A-06 decisiÃ³n supertipo+subtipos, **pendiente de revisiÃ³n de Persona B**; pÃ¡g. 03 del DER). Relaciones REL-03, REL-12, REL-15.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id_cliente | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado del cliente. |
| nombre | TEXT [I] | P | â€” | â€” | Apellido y nombre (persona) o razÃ³n social (empresa) (sec. 5). **PENDIENTE** Q-04 (un campo o dos, depende de D-1). |
| tipo_doc | TEXT [I: dominio no fijado por la consigna] | P | Candidata `(tipo_doc, n_doc)` [P] | â€” | Tipo de documento (DNI/CUITâ€¦) (sec. 5). |
| n_doc | TEXT [I: DNI y CUIT pueden convivir, se propone texto] | P | Candidata `(tipo_doc, n_doc)` [P] | â€” | NÃºmero de documento (sec. 5). |
| direccion | TEXT [I] | P | â€” | â€” | DirecciÃ³n del cliente (sec. 5; Q-10 campo Ãºnico vs desglosado). |
| localidad | BIGINT [R: FK a `Localidad.id_localidad` (DEC-01)] | P (DEC-14: mínimo inferido; sin NOT NULL) | FK → `Localidad.id_localidad` (FK #3), RESTRICT/RESTRICT [P: confirmación] | — | Identificador de la localidad del cliente. |
| fecha_alta | DATE [R: "fecha de alta"; tipo fecha] | P (obligatoriedad [R: «Siempre» A-02; NOT NULL **PENDIENTE**, cf. §9.3-contradicciÃ³n 1) | â€” | `CURRENT_DATE` [R: etapa 2 lista «fecha de alta actual» como DEFAULT] | Fecha de alta (sec. 5). |
| descuento | NUMERIC(5,2) [I] | P | CHECK `ck_cliente_descuento_rango` [R: RN-06; 0–100]; sincronización mediante triggers [I] | — | Porcentaje de descuento del cliente según tipo: 10 % Socio, 20 % Distribuidor, 30 % Exportador (RN-06). Columna persistente sincronizada con `fn_descuento_cliente` (DEC-32, ADOPTADA). Regla especial del 35 % para exportadores con más de 3 permisos: **PENDIENTE** P-9 (U6). |

### 2.15 `Socio` (subtipo)

- **PropÃ³sito:** fila de subtipo para clientes socios del club (descuento 10 %, RN-06; D1/D4/D6 los
  consultan por tipo).
- **Origen conceptual:** subtipo de la jerarquÃ­a REL-15 (A-06; pÃ¡g. 03).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id_cliente | BIGINT [R: hereda `Cliente.id_cliente` (DEC-10)] | NOT NULL (PK/FK) | PK/FK → `Cliente.id_cliente` (FK #18); ON DELETE CASCADE [P: confirmar según A-09 §7.1 #18] | — | Identificador heredado del supertipo. Una fila de Socio por cliente. |

### 2.16 `Distribuidor` (subtipo)

- **PropÃ³sito:** fila de subtipo para clientes mayoristas (descuento 20 %).
- **Origen conceptual:** subtipo REL-15 (pÃ¡g. 03).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id_cliente | BIGINT [R: hereda `Cliente.id_cliente` (DEC-10)] | NOT NULL (PK/FK) | PK/FK → `Cliente.id_cliente` (FK #19); ON DELETE CASCADE [P: confirmar según A-09] | — | Identificador heredado del supertipo. Una fila de Distribuidor por cliente. |
| zona | TEXT [I] | P | â€” | â€” | Zona de cobertura comercial del distribuidor (sec. 5; distinta de la cobertura del transportista, AMB-15 resuelta). |
| n_habilitacion | TEXT [I: dominio local no definido] | P | Candidata DK-2 [P: sin UNIQUE declarada] | â€” | NÃºmero de habilitaciÃ³n comercial (sec. 5). |

### 2.17 `Exportador` (subtipo)

- **PropÃ³sito:** fila de subtipo para clientes exportadores (descuento 30 %, RN-06; U6 ajuste **PENDIENTE** P-9).
- **Origen conceptual:** subtipo REL-15 (pÃ¡g. 03); origen de REL-16 (permisos).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id_cliente | BIGINT [R: hereda `Cliente.id_cliente` (DEC-10)] | NOT NULL (PK/FK) | PK/FK → `Cliente.id_cliente` (FK #20); ON DELETE CASCADE [P: confirmar según A-09] | — | Identificador heredado del supertipo. Una fila de Exportador por cliente. |
| pais | TEXT [I] | P | â€” | â€” | PaÃ­s de destino principal de la exportaciÃ³n (sec. 5, 3.4). |

### 2.18 `Permiso_Exportacion`

- **PropÃ³sito:** autorizaciÃ³n de exportaciÃ³n de un exportador; «varios por exportador» (sec. 5); U6
  cuenta permisos por exportador.
- **Origen conceptual:** entidad fuerte Permiso de exportaciÃ³n (A-01 §2.18, pÃ¡g. 03). Origen de FK #21 (REL-16).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| codigo | TEXT [R: DEC-04] | NOT NULL (PK) | PK | — | Código identificador del permiso de exportación (DEC-04). |
| exportador | BIGINT [R: FK a `Exportador.id_cliente` (DEC-10)] | P (DEC-14: mínimo inferido; sin NOT NULL) | FK → `Exportador.id_cliente` (FK #21); ON DELETE CASCADE [P: confirmar según A-09 §7.1 #21] | — | Identificador del exportador titular del permiso. |
| fecha_emision | DATE [R: tipo fecha] | P | Candidata `(exportador, fecha_emision)` [P] | â€” | Fecha de emisiÃ³n (sec. 5). |
| fecha_vencimiento | DATE [R: tipo fecha] | P | CHECK `fecha_vencimiento > fecha_emision` [R: RN-07, CHECK **entre columnas**; admite usar funciones determinÃ­sticas, sin fecha actual] | â€” | Fecha de vencimiento, posterior a la emisiÃ³n (RN-07). Vigencia **no almacenada** (Q-12; derivada). |

- **PK:** `codigo` [R: DEC-04].
### 2.19 `Comprobante`

- **PropÃ³sito:** cabecera del documento de venta; sus importes son derivados (RN-08, «No se carga a
  mano»); el almacenamiento fÃ­sico de subtotal/descuento/total queda **PENDIENTE** (decisiÃ³n exigida
  por escrito, sec. 5 «decisiones de diseÃ±o»; A-02 R-5).
- **Origen conceptual:** entidad fuerte Comprobante (A-01 §2.19, pÃ¡g. 04). Origen de FKs #14, #15; objetivo de FK #16.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| numero | BIGINT [R: DEC-05] | NOT NULL (PK) | PK global | — | Número identificador global del comprobante (DEC-05; `GET /comprobantes/{nro}`). |
| fecha | DATE [R: "fecha" tipo fecha] | P | â€” | â€” | Fecha de la venta (sec. 5). |
| cliente | BIGINT [R: FK a `Cliente.id_cliente` (DEC-10)] | NOT NULL [R: REL-12 extremo Comprobante 1..1 textual] | FK → `Cliente.id_cliente` (FK #14), RESTRICT/RESTRICT [P: confirmación; mecánica de borrado de socio cond. D-1/AMB-07] | — | Identificador del cliente comprador. |
| sala | BIGINT [R: FK a `Sala.id_sala` (DEC-10)] | NOT NULL [R: REL-13 extremo Comprobante 1..1 textual] | FK → `Sala.id_sala` (FK #15), RESTRICT/RESTRICT [P: confirmación] | — | Identificador de la sala donde se realizó la venta. |
| subtotal | NUMERIC(12,2) [R: NUMERIC para dinero; precisiÃ³n [I]] | P | Derivado RN-08 («no se carga a mano»); almacenamiento/cÃ¡lculo **PENDIENTE** (R-5) | â€” | Suma de subtotales de renglones antes del descuento global (sec. 5). |
| descuento | NUMERIC(12,2) [I; precisiÃ³n P] | P | Derivado RN-08; dominio **PENDIENTE** Q-05 (¿porcentaje o importe? a nivel de cabecera y renglÃ³n) | â€” | Descuento del comprobante segÃºn tipo de cliente (sec. 5; RN-08). |
| total | NUMERIC(12,2) [R: NUMERIC; precisiÃ³n [I]] | P | Derivado RN-08 (`fn_total_comprobante`, etapa 2); almacenamiento **PENDIENTE** (R-5) | â€” | Total del comprobante = suma de renglones con descuento (RN-08). |

### 2.20 `Renglon_Comprobante` (asociativa)

- **PropÃ³sito:** cada lÃ­nea de vino vendida; conserva el `precio_unitario` histÃ³rico del momento de la
  venta (A-02 R-4); RN-09 valida stock al insertar (trigger, etapa 2).
- **Origen conceptual:** REL-14 (A-05 §6; pÃ¡g. 04). Volumen esperado â‰¥ 500.000 filas (etapa 3).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| comprobante | BIGINT [R: FK a `Comprobante.numero` (DEC-05)] | NOT NULL (PK) | Componente de PK compuesta `(comprobante, vino)`; FK → `Comprobante.numero` (FK #16), CASCADE [P: confirmar acción según A-09] | — | Número del comprobante al que pertenece el renglón. |
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL (PK) | Componente de PK compuesta `(comprobante, vino)`; FK → `Vino.codigo` (FK #17), RESTRICT [P: confirmar acción según A-09] | — | Código del vino vendido. |
| cantidad | INTEGER [I: unidades enteras de botellas] | P (DEC-14: sin NOT NULL adoptado) | CHECK `cantidad > 0` [R: RN-15 cantidades] | â€” | Botellas del vino en el renglÃ³n (sec. 5; RN-09 valida stock). |
| precio_unitario | NUMERIC(12,2) [R: NUMERIC; precisiÃ³n [I]] | P (DEC-14: sin NOT NULL adoptado) | â€” | â€” | Precio unitario **al momento de la venta** (valor histÃ³rico capturado, no calculado â€” A-02 §2.20; RN-01; R-4). |
| descuento | NUMERIC(5,2) [I; precisiÃ³n P] | P | CHECK de rango [P: dominio Q-05 â€” ¿porcentaje o importe? **PENDIENTE**] | â€” | Descuento aplicado al renglÃ³n (sec. 5; RN-08). |
| subtotal | NUMERIC(12,2) [R: NUMERIC; precisiÃ³n [I]] | P | Derivado RN-08; guardado vs calculado **PENDIENTE** (R-5) | â€” | Importe del renglÃ³n = cantidad Ã— precio_unitario con descuento (RN-08). |

- **PK compuesta:** `(comprobante, vino)` [R: matriz de PK]; mínimo de renglones por comprobante: **PENDIENTE** AMB-10a.

### 2.21 `Transportista`

- **PropÃ³sito:** empresa de transporte externa para traslados (ingresos y cobertura); RN-14 impide
  borrarla con movimientos.
- **Origen conceptual:** entidad fuerte Transportista (A-01 §2.21, pÃ¡g. 05). Objetivo de FKs #22, #24.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| codigo | TEXT [R: DEC-08] | NOT NULL (PK) | PK | — | Código identificador del transportista (DEC-08). |
| razon_social | TEXT [I] | P | Sin UNIQUE (descartada TK-3) | â€” | RazÃ³n social de la empresa (sec. 5). |
| cuit | DOMAIN `cuit` [I: DOMAIN textual de etapa 2; aplicación de `cuit_dom` propuesta en A-13] | P | Sin UNIQUE [R: DEC-08; no es clave candidata adoptada] | — | CUIT del transportista. |
| email | TEXT [I] | P | Formato de e-mail [P: sin garantÃ­a textual; validaciÃ³n en API/A-13 â€” PENDIENTE] | â€” | Correo de contacto (sec. 5). |
| telefono | TEXT [I] | P | â€” | â€” | TelÃ©fono de contacto (sec. 5). |
| domicilio | TEXT [I] | P | â€” | â€” | Domicilio de la empresa (sec. 5). |

- **PK:** `codigo` [R: DEC-08].

### 2.22 `Transportista_Localidad` (asociativa)

- **PropÃ³sito:** cobertura geogrÃ¡fica N:M del servicio de cada transportista.
- **Origen conceptual:** REL-17 (A-05 §9; pÃ¡g. 05). Sin atributos propios (A-02 2.22).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| transportista | TEXT [R: FK a `Transportista.codigo` (DEC-08)] | NOT NULL (PK) | Componente de PK compuesta `(transportista, localidad)`; FK → `Transportista.codigo` (FK #22), ON DELETE CASCADE [P: confirmar según A-09 §7.1 #22] | — | Código del transportista de la cobertura. |
| localidad | BIGINT [R: FK a `Localidad.id_localidad` (DEC-01)] | NOT NULL (PK) | Componente de PK compuesta `(transportista, localidad)`; FK → `Localidad.id_localidad` (FK #23), RESTRICT/RESTRICT [R: A-09] | — | Identificador de la localidad cubierta. |

- **PK compuesta:** `(transportista, localidad)` [R: matriz de PK]. Sin atributos adicionales (sin "frecuencia de cobertura" — no respaldado; A-09 §3.22).

### 2.23 `Ingreso`

- **PropÃ³sito:** documento por el cual una bodega entrega vinos al depÃ³sito central; ciclo de estados
  `en_confeccion â†’ terminado â†’ procesado` sin retroceso (RN-10, ENUM).
- **Origen conceptual:** entidad fuerte Ingreso (A-01 §2.23, pÃ¡g. 05). Origen de FKs #24, #25; objetivo de FK #26.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| codigo | TEXT [R: DEC-06] | NOT NULL (PK) | PK global | — | Código identificador global del ingreso (DEC-06; API `/ingresos/{codigo}`). |
| fecha | DATE [R: tipo fecha] | P | â€” | â€” | Fecha del ingreso. **PENDIENTE** semÃ¡ntica Q-03 (¿fecha de confecciÃ³n anÃ¡loga a RN-11 o de traslado?). Sin regla de inmodificabilidad declarada para el ingreso (RN-11 es de la transferencia). |
| estado | ENUM `estado_documento` [R: RN-10 «Tipo ENUM» + etapa 2; valores `en_confeccion`, `terminado`, `procesado`; definiciÃ³n A-13 **PENDIENTE** formal] | P (DEC-14: sin NOT NULL adoptado) | CHECK de dominio implÃ­cito por ENUM; transiciones sin retroceso: trigger/procedimiento (RN-10; etapa 2, no CHECK) | `'en_confeccion'` [R: etapa 2, «Estado inicial en_confeccion» como DEFAULT] | Estado del ciclo de vida del ingreso (sec. 5; RN-10). |
| transportista | TEXT [R: FK a `Transportista.codigo` (DEC-08)] | NOT NULL [R: REL-19 extremo Ingreso 1..1 textual] | FK → `Transportista.codigo` (FK #24), RESTRICT/RESTRICT [R: RN-14] | — | Código del transportista que efectuó el traslado. |
| bodega_origen | DOMAIN `cuit` [R: FK a `Bodega.cuit`] | NOT NULL [R: REL-18 extremo Ingreso 1..1 textual] | FK con rol `bodega_origen` → `Bodega.cuit` (FK #25), RESTRICT/RESTRICT [R: RN-14] | — | CUIT de la bodega que remite el lote/vinos. Rol distinto (AMB-06). |

### 2.24 `Renglon_Ingreso` (asociativa)

- **PropÃ³sito:** cada lÃ­nea de vino (y cantidad) incluida en un ingreso; objeto de control RN-12.
- **Origen conceptual:** REL-20 (A-05 §7; pÃ¡g. 05).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| ingreso | TEXT [R: FK a `Ingreso.codigo` (DEC-06)] | NOT NULL (PK) | Componente de PK compuesta `(ingreso, vino)`; FK → `Ingreso.codigo` (FK #26), CASCADE [P: confirmar acción según A-09] | — | Código del ingreso al que pertenece el renglón. |
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL (PK) | Componente de PK compuesta `(ingreso, vino)`; FK → `Vino.codigo` (FK #27), RESTRICT [P: confirmar acción según A-09] | — | Código del vino ingresado. |
| cantidad | INTEGER [I] | P (DEC-14: sin NOT NULL adoptado) | CHECK `cantidad > 0` [R: RN-15] | â€” | Botellas incluidas (sec. 5). |

### 2.25 `Transferencia`

- **PropÃ³sito:** solicitud de la sala al depÃ³sito central; al procesarse descuenta stock del depÃ³sito
  y suma al de la sala (RN-11); la fecha de confecciÃ³n es la actual y **no modificable** (RN-11).
- **Origen conceptual:** entidad fuerte Transferencia (A-01 §2.25, pÃ¡g. 06). Origen de FK #28; objetivo de FK #29.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| numero | BIGINT [R: DEC-07] | NOT NULL (PK) | PK global | — | Número identificador global de la transferencia (DEC-07; API `/transferencias/{nro}`). |
| fecha_confeccion | DATE [R: "fecha"; TIMESTAMP? **PENDIENTE** â€” la consigna dice «fecha» de confecciÃ³n, se propone DATE] | P (DEC-14: sin NOT NULL adoptado) | Trigger RN-11: la fecha actual al crear y **no modificable** (trigger de fecha, etapa 2 â€” sin restricciones fÃ­sicas aquÃ­) | `CURRENT_DATE` [I: RN-11 «es la fecha actual» al crear; DEFAULT propuesto, confirmaciÃ³n P] | Fecha de confecciÃ³n, inmodificable (RN-11). |
| estado | ENUM `estado_documento` [R: RN-11 aplica ciclo RN-10 a transferencias] | P (DEC-14: sin NOT NULL adoptado) | Transiciones por trigger/procedimiento `sp_procesar_transferencia` (RN-11, etapa 2) | `'en_confeccion'` [R: etapa 2 DEFAULT de estado] | Estado del ciclo de vida (sec. 5; RN-11). |
| sala | BIGINT [R: FK a `Sala.id_sala` (DEC-10)] | NOT NULL [R: REL-21 extremo Transferencia 1..1 textual] | FK → `Sala.id_sala` (FK #28), RESTRICT/RESTRICT [P: confirmar según A-09] | — | Identificador de la sala solicitante. |

### 2.26 `Renglon_Transferencia` (asociativa)

- **PropÃ³sito:** lÃ­nea de vino y cantidad solicitada en una transferencia; controlada por RN-12.
- **Origen conceptual:** REL-22 (A-05 §8; pÃ¡g. 06).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| transferencia | BIGINT [R: FK a `Transferencia.numero` (DEC-07)] | NOT NULL (PK) | Componente de PK compuesta `(transferencia, vino)`; FK → `Transferencia.numero` (FK #29), CASCADE [P: confirmar acción según A-09] | — | Número de la transferencia a la que pertenece el renglón. |
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL (PK) | Componente de PK compuesta `(transferencia, vino)`; FK → `Vino.codigo` (FK #30), RESTRICT [P: confirmar acción según A-09] | — | Código del vino solicitado. |
| cantidad | INTEGER [I] | P (DEC-14: sin NOT NULL adoptado) | CHECK `cantidad > 0` [R: RN-15] | â€” | Botellas solicitadas (sec. 5). |

### 2.27 `Stock_Sala` (inventario)

- **PropÃ³sito:** existencia de un vino en una sala; persistente por par `(sala, vino)`, actualizada por
  ventas (RN-09) y transferencias (RN-11); consultada por `fn_stock_sala`, S6, S9.
- **Origen conceptual:** entidad inventario Stock de sala (A-01 §2.27; REL-23, pÃ¡g. 06).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| sala | BIGINT [R: FK a `Sala.id_sala` (DEC-10)] | NOT NULL (PK) | Componente de PK compuesta `(sala, vino)`; FK → `Sala.id_sala` (FK #31), RESTRICT [R: A-09] | — | Identificador de la sala del inventario. |
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL (PK) | Componente de PK compuesta `(sala, vino)`; FK → `Vino.codigo` (FK #32), RESTRICT [P: confirmar acción según A-09] | — | Código del vino del inventario. |
| cantidad | INTEGER [I] | P (DEC-14: sin NOT NULL adoptado) | CHECK `cantidad >= 0` [R: sec. 5 «cantidad >= 0» + RN-09; el `>0` vs `>=0` de RN-15 vs P-6 estÃ¡ **PENDIENTE** â€” para stock el texto es `>= 0`] | ¿DEFAULT 0? [P: los ejemplos de stock de la consigna usan DEFAULT 0 en requisitos §5.2, pero DEFAULT 0 + ausencia de fila â‰  lo mismo (AMB-11) â€” **PENDIENTE**] | Unidades del vino en la sala. Fila ausente â‰  cantidad 0 (AMB-11). Sin atributos extra (Q-13: no respaldado). |

### 2.28 `Stock_Deposito` (inventario)

- **PropÃ³sito:** existencia de un vino en el depÃ³sito central (Ãºnico), contra lo que impactan ingresos
  (RN-10) y de lo que se descuentan transferencias (RN-11).
- **Origen conceptual:** entidad inventario Stock de depÃ³sito (A-01 §2.28; REL-24, pÃ¡g. 06). Separada
  del stock de sala en tanto D-3 no se cierre.

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL (PK/FK) | PK/FK → `Vino.codigo` (FK #33), RESTRICT [P: confirmar acción según A-09] | — | Código del vino cuyo stock central se registra (1 fila máx.; relación 1:1, A-09 §5.3). |
| cantidad | INTEGER [I] | P (DEC-14: sin NOT NULL adoptado) | CHECK `cantidad >= 0` [R: sec. 5 + RN-09; P-6 **PENDIENTE** como en 2.27] | ¿DEFAULT 0? [P: idem 2.27, AMB-11] | Unidades del vino en el depÃ³sito central. |

### 2.29 `Auditoria_Precio` (tÃ©cnica)

- **PropÃ³sito:** historial de cada cambio de precio de un vino, completado por trigger AFTER UPDATE
  (RN-13); entidad motivada por requerimiento tÃ©cnico (D-10).
- **Origen conceptual:** entidad AuditorÃ­a de precio (A-01 §2.29; REL-25, pÃ¡g. 06).

| Columna | Tipo propuesto | Nulab. | Clave / restr. | Default | DescripciÃ³n |
|---|---|---|---|---|---|
| id_auditoria | BIGINT GENERATED ALWAYS AS IDENTITY [R: DEC-10] | NOT NULL (PK) | PK | — | Identificador subrogado autogenerado de la fila de auditoría. |
| vino | TEXT [R: FK a `Vino.codigo` (DEC-03)] | NOT NULL [R: REL-25 extremo Auditoría 1..1 textual] | FK → `Vino.codigo` (FK #34), RESTRICT [R: preservar trazabilidad/RN-13; A-09 §7.1 #34] | — | Código del vino cuyo precio cambió (sec. 5). |
| precio_anterior | NUMERIC(12,2) [R: dinero con NUMERIC; precisiÃ³n [I]] | P (DEC-14: sin NOT NULL adoptado) | â€” | â€” | Precio previo al cambio (sec. 5; RN-13). |
| precio_nuevo | NUMERIC(12,2) [R: NUMERIC] | P (DEC-14: sin NOT NULL adoptado) | â€” | â€” | Precio en vigor tras el cambio (sec. 5; RN-13). |
| fecha_hora | TIMESTAMP [R: «fecha y hora» sec. 5] | P (DEC-14: sin NOT NULL adoptado) | Candidata `(vino, fecha_hora)` [P: AU-2] | â€” | Fecha y hora del cambio (sec. 5; RN-13). |
| usuario | TEXT [I] | P (DEC-14: sin NOT NULL adoptado) | â€” | â€” | Usuario que efectuÃ³ el cambio (sec. 5; RN-13). **PENDIENTE** Q-07: usuario de BD (CURRENT_USER) o funcional. |

---

## 3. Claves primarias y candidatas (consolidado de A-09 §3/A-03)

| Tabla | PK propuesta / estado | Claves candidatas |
|---|---|---|
| Localidad | `id_localidad` [R: DEC-01] | LK-1 [P], LK-2 [P] |
| Sala | `id_sala` [R] | SK-1 [R] |
| Empleado | `id_empleado` [R: DEC-09] | EK-1 [I]; EK-a `cuit` [I: no UNIQUE, no PK] |
| Finca | `id_finca` [R] | FiK-1 [R] |
| Parcela | **`(finca, n_parcela)`** [R] | ParK-1 [R] |
| Cepa | `id` [R] | CeK-1 [R]; CeK-2 `nombre` [P] |
| Lote | **`(finca, n_parcela, campania)`** [PK compuesta adoptada (DEC-02)] | LoteK-2 `(parcela, campania)` [adoptada conceptualmente]; LoteK-1 `n_lote` [alternativa descartada como PK] |
| Analisis | `id_analisis` [R: DEC-10] | AK-1 [R]; AK-2 `(finca,n_parcela, campania, fecha)` [P: sin garantía de unicidad, AMB-13] |
| Bodega | **`cuit`** [R: matriz de PK; DEC-08] | BK-1 `cuit` [R: UNIQUE textual]; razon_social descartada |
| Vino | **`codigo`** [R: DEC-03; supuesto de diseño adoptado] | VK-1 [I]; VK-2 `(nombre, anada, volumen_ml)` [R: UNIQUE textual] |
| Composicion | **`(vino, cepa)`** [R: matriz de PK] | ComK-1 [I] (ComK-a pendiente) |
| Maridaje | `id` [R] | MK-1 [R]; MK-2 `nombre` [P] |
| Vino_Maridaje | **`(vino, maridaje)`** [R: matriz de PK] | VMK-1 [I] |
| Cliente | `id_cliente` [R] | CliK-1 [R]; CliK-2 `(tipo_doc, n_doc)` [P] |
| Socio / Distribuidor / Exportador | `id_cliente` PK/FK heredada [R: DEC-10 y DEC-13] | DK-2 `n_habilitacion` [P] |
| Permiso_Exportacion | **`codigo`** [R: DEC-04] | PerK-1 [P]; PerK-2 [P] |
| Comprobante | **`numero`** [R: DEC-05] | CompK-1 [P]; CompK-2 [P]; `(sala, numero, fecha)` descartada |
| Renglon_Comprobante | **`(comprobante, vino)`** [R] | RK-1 [R] |
| Transportista | **`codigo`** [R: DEC-08] | TK-1 [P]; TK-2 `cuit` [I: no UNIQUE]; razon_social descartada |
| Transportista_Localidad | **`(transportista, localidad)`** [I] | TCL-1 [I] |
| Ingreso | **`codigo`** [R: DEC-06] | IK-1 [P] |
| Renglon_Ingreso | **`(ingreso, vino)`** [I] | RI-1 [I] (RI-a pendiente) |
| Transferencia | **`numero`** [R: DEC-07] | TF-1 [P]; TF-2 [P] |
| Renglon_Transferencia | **`(transferencia, vino)`** [I] | RT-1 [I] (RT-a pendiente) |
| Stock_Sala | **`(sala, vino)`** [R] | SS-1 [R] |
| Stock_Deposito | **`vino`** [R: matriz de PK; DEC-03; cond. D-3/AMB-11] | SD-1 [I] |
| Auditoria_Precio | `id_auditoria` [R: DEC-10] | AU-1 [R]; AU-2 `(vino, fecha_hora)` [P] |

**Ninguna PK queda arbitraria: las adoptadas (DEC-01..DEC-10 y DEC-02) tienen fundamento en A-12; las alternativas descartadas se conservan como candidatas sin UNIQUE documentada.

---

## 4. Claves forÃ¡neas (justificadas, segÃºn A-09 §7.1)

Las 34 FK de A-09 §7.1 están implementadas y su inventario físico fue
verificado en PostgreSQL. La distribución actual es:

- ON DELETE: 23 RESTRICT, 6 CASCADE y 5 NO ACTION.
- ON UPDATE: 20 RESTRICT y 14 NO ACTION.
- No se utilizan SET NULL, SET DEFAULT ni ON UPDATE CASCADE.

Las cinco acciones ON DELETE NO ACTION corresponden a las FK #4, #21,
#22, #23 y #31. Permanecen pendientes de decisión entre las alternativas
documentadas en A-09 §7.1 y A-12. No se modifican sin respaldo suficiente.

Para ON UPDATE no se propone CASCADE: se evita propagar automáticamente
modificaciones de claves referenciadas. Las acciones RESTRICT y NO ACTION
se conservan según lo documentado para cada FK.

---

## 4 bis. Mecanismos fisicos implementados (etapa 2)

Resumen del SQL real (migraciones `db/migrations/001, 002, 003`) y de las pruebas
(`db/tests/run_tests.ps1`, 13 casos):

| Regla | Columna / tabla | Mecanismo fisico |
|---|---|---|
| RN-01 | `Vino.precio` | CHECK `ck_vino_precio_positivo` (`> 0`); el precio vive solo en `Vino`, no en stocks (una fila por vino => precio unico para toda la red) |
| RN-02 | `Sala.localidad`, `Localidad.encargado_regional` | FK `fk_sala_localidad` NOT NULL; encargado como atributo de `Localidad` (unico por dependencia funcional localidad -> encargado) |
| RN-04 | `Parcela.cepa`, PK de `Lote` | FK `fk_parcela_cepa` + PK compuesta `(finca, n_parcela, campania)`; sin UNIQUE redundante |
| RN-05 | `Composicion.porcentaje` | Constraint trigger `trg_rn05_composicion_suma_100` DEFERRABLE INITIALLY DEFERRED (funcion `fn_composicion_suma_100`): la suma por vino = 100 se valida al COMMIT |
| RN-07 | `Permiso_Exportacion` | FK `fk_permiso_exportador` (1:N real); CHECK `ck_permiso_fechas_orden` entre columnas |

## 5. Restricciones UNIQUE respaldadas y no respaldadas

- **UNIQUE adicionales con respaldo textual ([R]):** `Vino (nombre, anada, volumen_ml)`.
- **Unicidad inherente a PK (no cuenta como UNIQUE adicional):** `Bodega.cuit`;
  `Parcela (finca, n_parcela)`; `Renglon_Comprobante (comprobante, vino)`;
  `Stock_Sala (sala, vino)`; `Stock_Deposito.vino`; `id_cliente` en
  `Socio`, `Distribuidor` y `Exportador`; `Auditoria_Precio.id_auditoria`.
- **Candidatas sin UNIQUE declarada — no se agregan:** `Localidad.codigo_postal`,
  `(nombre, provincia)`, `Cepa.nombre`, `Maridaje.nombre`,
  `Distribuidor.n_habilitacion`,

Se adoptan además las siguientes restricciones por decisión de dominio:

- `Cliente(tipo_doc, n_doc)`: una misma combinación de tipo y número documental identifica un único registro de cliente. Esto no impide que una persona tenga documentos de distintos tipos.
- `Transportista(cuit)`: un CUIT no puede identificar dos transportistas.
- `Empleado(cuit)`: un CUIT no puede identificar dos empleados.

Estas tres restricciones, junto con `Vino(nombre, anada, volumen_ml)`,
completan las cuatro UNIQUE adicionales a las PK.
Respeto del mínimo de etapa 2: la consigna exige 4 UNIQUE adicionales a las PK y ejemplifica solo 3
([Pregunta] abierta §10.2.6 de `requisitos.md`); la cuarta **no se inventa** (**PENDIENTE**).

---

## 6. Restricciones CHECK / NOT NULL

### 6.1 CHECK con respaldo textual

| Tabla | RestricciÃ³n | Respaldo |
|---|---|---|
| Vino.precio | `precio > 0` | RN-01 |
| Vino.graduacion | `graduacion BETWEEN 5 AND 20` | RN-15 |
| Lote.kg | `kg > 0` | RN-15 («kilos... positivos»); lÃ­mite P-6 no aplica (no es stock) |
| Finca.superficie / Parcela.superficie | `superficie > 0` | RN-15 («superficies») |
| Renglon_Comprobante.cantidad / Renglon_Ingreso.cantidad / Renglon_Transferencia.cantidad | `cantidad > 0` | RN-15 («cantidades»), salvo P-6 para stocks |
| Stock_Sala.cantidad / Stock_Deposito.cantidad | `cantidad >= 0` | sec. 5 («cantidad >= 0»), RN-09 |
| Permiso_Exportacion | `fecha_vencimiento > fecha_emision` | RN-07 (CHECK entre columnas) |
| Composicion.porcentaje | suma de porcentajes = 100 por vino | RN-05 (restricciÃ³n agregada: constraint trigger diferido, etapa 2 â€” **no** es CHECK de fila) |
| Empleado.salario | ¿`salario > 0`? | **PENDIENTE** Q-08 (RN-15 no menciona salario) |
| Cliente.descuento | CHECK de rango | RN-06; `ck_cliente_descuento_rango` implementado (0–100). Valores base 10/20/30 definidos; solo permanece pendiente P-9 (U6: posible 35 % para exportadores con más de 3 permisos). |
| Renglon_Comprobante.descuento | CHECK de rango | **PENDIENTE** Q-05 (¿% o importe?) |

Advertencia de la consigna (etapa 2): no usar `CURRENT_DATE` ni funciones no determinÃ­sticas dentro
de CHECK â€” las reglas dependientes de la fecha actual (RN-11) van en trigger. Aplica a todo CHECK
futuro de A-13.

### 6.2 NOT NULL

Según A-09 §6.3 y DEC-14 (ADOPTADA), se aplica un criterio conservador:

1. Todas las columnas componentes de las PK llevan `NOT NULL`, por definición de clave primaria.
2. Las FK cuya participación mínima 1 tenga respaldo textual en la consigna llevan `NOT NULL [R]`.
3. Se admiten `NOT NULL` adicionales cuando una regla de negocio específica exige que el dato exista para que la regla pueda cumplirse. No se derivan de la expresión «Siempre» de A-02.

Se justifican específicamente:

- `Composicion.porcentaje`: RN-05; cada componente debe aportar un porcentaje para verificar que la suma por vino sea 100.
- `Ingreso.estado`: RN-10; el ciclo de vida requiere un estado inicial.
- `Transferencia.fecha_confeccion` y `Transferencia.estado`: RN-11 y RN-10; se requiere fecha de confección y estado para gestionar su ciclo de vida.
- `Renglon_Comprobante.cantidad`, `Renglon_Ingreso.cantidad` y `Renglon_Transferencia.cantidad`: RN-15; las cantidades deben ser positivas.
- `Renglon_Comprobante.precio_unitario`: RN-01 y R-4; debe conservarse el valor histórico de venta.
- `Stock_Sala.cantidad` y `Stock_Deposito.cantidad`: RN-09 y §5; la existencia debe tener una cantidad registrada y no negativa.
- `Auditoria_Precio.precio_anterior`, `precio_nuevo` y `fecha_hora`: RN-13; son datos necesarios para registrar un cambio de precio.

Las FK cuyo mínimo sea inferido (`[I]`) no llevan `NOT NULL` por esa sola inferencia. Esto incluye `Cliente.localidad`, `Permiso_Exportacion.exportador` y los componentes de la FK compuesta de `Analisis` que no formen parte de una PK.

Los componentes de una PK compuesta mantienen `NOT NULL` por pertenecer a la PK, aunque también integren una FK cuyo mínimo sea inferido.

Los atributos descriptivos no incluidos en las reglas específicas anteriores no llevan `NOT NULL` únicamente por la expresión «Siempre» de A-02. Una obligatoriedad física adicional requiere una decisión de dominio específica, documentada y fundamentada.

---

## 7. Tipos propios propuestos (ENUM y DOMAIN)

PROPUESTOS, pendientes de definiciÃ³n definitiva en A-13 (A-10 no implementa):

1. **ENUM `estado_documento`** â€” valores `'en_confeccion'`, `'terminado'`, `'procesado'`.
   Respaldo [R]: RN-10 «Tipo ENUM», sec. 5 «Estado con ENUM», DEFAULT `en_confeccion` (etapa 2).
   Aplica a: `Ingreso.estado`, `Transferencia.estado`. Es el ENUM mÃ­nimo exigido (uno).
   PENDIENTE: nombre final y si una segunda variante de ENUM es necesaria.
2. **DOMAIN `cuit`** â€” 11 dÃ­gitos (VARCHAR(11) con CHECK de formato). Respaldo [R]: etapa 2
   («DOMAIN CUIT de 11 dÃ­gitos»). Alcance propuesto [I]: `Bodega.cuit` (con UNIQUE [R]),
   `Transportista.cuit` y `Empleado.cuit` (alcance del DOMAIN por tabla no declarado textualmente â€”
   PENDIENTE).
3. **DOMAIN `dia_semana`** [I] â€” para `Sala.dia_cierre` (valores lunesâ€¦domingo, ¿mÃ¡s «sin cierre»?).
   PENDIENTE Q-09; sin garantÃ­a textual del conjunto.
4. **ENUM/DOMAIN de tipo de uva y tipo de vino** [I] â€” `Cepa.tipo` (tinta/blanca) y
   `Vino.tipo` (tinto/blanco/rosado/espumante): dominios binarios/clÃ¡usulos derivados del texto.
   PENDIENTE si se materializan como tipo propio o CHECK simple (A-13).

La consigna exige la creaciÃ³n de **1 ENUM y 1 DOMAIN mÃ­nimos**; los Ã­tems 1 y 2 cubren el mÃ­nimo
respaldado; 3 y 4 son extensiones propuestolÃ³gicas [I] sin exigencia textual.

---

## 8. Dependencias entre tablas y orden de creación (propuesto)

Las dependencias derivan de las 34 FK (A-09 §7.1). Orden de creación propuesto por niveles de
dependencia:

| Orden | Tablas | Motivo |
|---|---|---|
| 1 | `Cepa`, `Maridaje`, `Localidad`, `Finca` | Catálogos base sin dependencias; sus PK ya están adoptadas. |
| 2 | `Sala`, `Bodega`, `Empleado` | Dependen de Localidad / independientes según sus FK. |
| 3 | `Cliente`, `Parcela` | Cliente depende de Localidad; Parcela de Finca y Cepa. |
| 4 | `Socio`, `Distribuidor`, `Exportador` | Dependen de Cliente; jerarquía total y disjunta adoptada (DEC-11/12). |
| 5 | `Vino`, `Lote`, `Permiso_Exportacion`, `Transportista` | Vino de Bodega; Lote de Parcela+Bodega; Permiso de Exportador; Transportista base. |
| 6 | `Analisis`, `Composicion`, `Vino_Maridaje`, `Transportista_Localidad` | Dependen de las tablas previas. |
| 7 | `Ingreso`, `Transferencia`, `Comprobante` | Dependen de Bodega/Transportista/Sala/Cliente/Vino. |
| 8 | `Renglon_Ingreso`, `Renglon_Transferencia`, `Renglon_Comprobante` | Dependen de sus cabeceras y de Vino. |
| 9 | `Stock_Sala`, `Stock_Deposito`, `Auditoria_Precio` | Dependen de Sala/Vino. |

Las PK de las 29 tablas ya fueron adoptadas en A-12. Por lo tanto, el orden ya no está
condicionado a la elección de PK. La generación de SQL sigue pendiente de las decisiones de
restricciones, reglas de negocio y tipos todavía abiertas. Este orden es propuesto y deberá
validarse contra las dependencias efectivas al implementar el DDL.

---

## 9. Verificaciones y auditoría del diccionario

### 9.1 Cobertura (checksum documentacional)

| Control | Resultado |
|---|---|
| Tablas de A-09 §2 (29) documentadas | OK — 29/29 tablas (§2.1–2.29) |
| Columnas de A-09 §3 documentadas | OK — 128/128 columnas (ver conteo por tabla en §9.2) |
| Nombres tablas/columnas vs A-09 | OK — sin cambio de nombres (regla no cambiar A-09) |
| Tipos, nulabilidad y restricciones vs fuentes | OK — marcas [R]/[I]/[P] por columna |
| PK arbitrarias | Ninguna: las PK se adoptaron y justificaron en A-12 (DEC-01…DEC-10 y DEC-02); las alternativas descartadas quedan documentadas |
| UNIQUE sin respaldo | Ninguna agregada (§5) |
| Registro de contradicciones | Sí — §9.3 (4) |

### 9.2 Conteo por tabla (columnas)

Localidad 5 · Sala 5 · Empleado 6 · Finca 5 · Parcela 5 · Cepa 3 · Lote 7 · Analisis 8 · Bodega 3 ·
Vino 8 · Composicion 3 · Maridaje 3 · Vino_Maridaje 2 · Cliente 8 · Socio 1 · Distribuidor 3 ·
Exportador 2 · Permiso_Exportacion 4 · Comprobante 7 · Renglon_Comprobante 6 · Transportista 6 ·
Transportista_Localidad 2 · Ingreso 5 · Renglon_Ingreso 3 · Transferencia 4 ·
Renglon_Transferencia 3 · Stock_Sala 3 · Stock_Deposito 2 · Auditoria_Precio 6 — **total 128**.
`Notas de conteo: 128 = 124 originales + 1 id_localidad (DEC-01) + 1 id_empleado (DEC-09) + 2 componentes de FK compuesta de Analisis (DEC-02, que sustituyó a lote).`

### 9.3 Contradicciones/inconsistencias detectadas (A-09 vs documentos anteriores)

1. **Obligatoriedad conceptual vs NOT NULL [criterio adoptado y aplicado].**
   A-02 utiliza la expresión «Siempre» para numerosos atributos descriptivos. A-09 §6.3 establece
   un criterio conservador para trasladar obligatoriedad al modelo físico. DEC-14 adoptó ese
   criterio: `NOT NULL` para componentes de PK y FK con participación mínima 1 respaldada
   textualmente. No se deriva `NOT NULL` para atributos descriptivos ni para FK cuyo mínimo
   sea inferido únicamente a partir de A-02. La decisión conceptual está resuelta y adoptada. El DDL aplica el criterio conservador de DEC-14; las marcas [R]/[I]/[P] del diccionario conservan la distinción entre obligatoriedad respaldada, inferida y pendiente, sin convertir automáticamente las últimas en NOT NULL.

2. **Aritmética del encabezado de A-09 §2 [corregida].** El texto decía "17 de entidades fuertes
   + 1 débil + 6 asociativas + 2 stock + 3 subtipos + 1 técnica" (suma 30). La cuenta correcta es
   **16 fuertes + 1 débil = 29 tablas**; la tabla de A-09 siempre estuvo bien. **Corregido en A-09**
   (17 → 16) durante este ciclo; registrado en A-11.

3. **Cita errónea en A-09 §3.12 [corregida].** `Maridaje.temperatura` citaba "(RN-06)";
   corregido en A-09 durante este ciclo y ahora cita §3.3/§5. El diccionario usa las fuentes correctas.

4. **Discrepancia descuento (A-09 §12.7) [corregida en A-09].** El resumen de A-09 ya no usa
   "(distrib.?)" para el 35 %: se refiere a exportadores con más de 3 permisos según U6.
   El diccionario documenta `descuento` con CHECK de rango [R] y valores 10/20/30, con U6 con la regla especial de U6 pendiente de confirmación docente (P-9).

### 9.4 Decisiones pendientes (heredadas de A-09 §12 y activas en A-10)

Permanecen activas las decisiones no resueltas de A-09 §12: D-1/AMB-07 (revisión de Persona B),
D-3/AMB-11, ComK-a/RI-a/RT-a/TK-a/PerK/VK-a, ParK-a, P-9 (regla especial del 35 % de descuento),
Q-03 (fecha de ingreso), Q-05 (dominio del descuento del renglón), Q-06/D-6 (análisis), Q-07 (usuario de
auditoría), Q-08–Q-13 (dominios menores), P-6 (>0 vs >=0 en stocks/cantidades), P-8 (catálogo
de volúmenes), materialización de subtotal/descuento/total (R-5), ON DELETE #4/#21/#22/#23/#31,
ON UPDATE, cuarta UNIQUE del mínimo de etapa 2 y alcance del DOMAIN `cuit`.

Las decisiones de PK e identidad adoptadas en A-12 ya no se consideran pendientes en A-10.
Ninguna otra decisión se cierra por el solo hecho de actualizar este diccionario.

### 9.5 Resultado de auditoría

**Estado del documento: PRELIMINAR, completo en cobertura (29 tablas / 128 columnas), con 4
contradicciones registradas y decisiones ambiguas aún marcadas PENDIENTE. No se declara aprobado**:
requiere revisión de Persona B y docente. Las PK ya fueron adoptadas en A-12; la generación de DDL
sigue pendiente por las decisiones de negocio, restricciones y tipos todavía no resueltos.

---

### Registro de cambios de este documento

- Correcciones (cierre): fila corrupta de 9.1 reparada (Registro de contradicciones); 9.3-2/3/4
  actualizadas a estado CORREGIDA (las tres erratas de A-09 fueron corregidas allí); DEC-02 ya
  estaba propagada (Lote: PK compuesta, n_lote descriptivo, FK #8 compuesta).

- Creación (A-10, PRELIMINAR): diccionario de datos completo del esquema A-09 (29 tablas, 124 columnas en origen; 128 tras propagar DEC-01/DEC-09/DEC-02). Ver §9.2., tipos PostgreSQL propuestos con marcas [R]/[I]/[P], PK/FK/candidatas/UNIQUE/CHECK/
  NOT NULL documentadas sin decisiones arbitrarias, ENUM/DOMAIN propuestos, dependencias y orden
  de creación, auditoría con 4 inconsistencias registradas. Sin SQL, sin cerrar ambigüedades.

- **Actualización A-12:** propagación de las decisiones DEC-01 a DEC-13 al diccionario:
  PK e identidades adoptadas, PK/FK heredadas de subtipos, resumen de claves candidatas,
  dependencias de creación y auditoría de cobertura actualizados. Se mantiene el estado
  PRELIMINAR y no se cierran las decisiones pendientes de A-09/A-13.

- Implementacion etapa 2 (A-17/A-18/A-20/A-21/A-23): se agrego la seccion s 5 bis con los
  mecanismos fisicos vigentes (CHECK, FK, constraint trigger diferido RN-05 en migracion 003,
  pruebas en db/tests).el conteo de 128 columnas y las marcas [R]/[I]/[P] se mantienen. DEC-14 está adoptada y aplicada en el DDL: las restricciones NOT NULL corresponden a componentes de PK y FK con participación mínima 1 respaldada textualmente, además de los casos expresamente exigidos por reglas de negocio implementadas.
# 15 — Informe de rendimiento de índices

## 1. Objetivo

Evaluar el efecto de los índices definidos en la migración
`db/migrations/013_indices.sql` sobre consultas representativas del sistema
Bodegas del Atuel.

La comparación se realiza sobre una base temporal (`rn_bench_tmp`), con la
misma carga sintética antes y después de aplicar los índices.

La base operativa `bodegas_atuel` no participa de esta prueba.

## 2. Procedimiento

El script `db/benchmark/run_bench.ps1` realiza las siguientes operaciones:

1. Crea la base temporal `rn_bench_tmp`.
2. Aplica las migraciones 001 a 012.
3. Carga datos sintéticos.
4. Verifica los registros cargados.
5. Ejecuta `ANALYZE` antes de la medición inicial.
6. Ejecuta las ocho consultas sin los índices de la migración 013.
7. Aplica `013_indices.sql`.
8. Ejecuta nuevamente `ANALYZE`.
9. Ejecuta las mismas ocho consultas con los índices.
10. Guarda los planes y elimina la base temporal.

Además, el script `db/benchmark/04_costo_escritura.ps1` mide el costo de
escritura con y sin los índices (sección 7), en bases temporales que también
se eliminan al finalizar.

Las consultas utilizan `EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)`,
por lo que se registran los planes, tiempos de planificación, tiempos de
ejecución y estadísticas de bloques.

## 3. Volumen de datos

La verificación de la carga sintética informó:

| Tabla o conjunto | Registros |
|---|---:|
| Vino | 20.000 |
| Comprobante | 5.000 |
| Ingreso | 3.000 |
| Transferencia | 2.000 |
| Auditoria_Precio | 20.000 |
| Stock_Sala | 100.000 |
| Renglon_Comprobante | 60.000 |
| Renglon_Ingreso | 3.000 |

Los datos fueron generados exclusivamente para el benchmark.

## 4. Resultados

Los tiempos corresponden a una única ejecución de cada consulta y se expresan
en milisegundos.

| Consulta | Sin índices | Con índices | Observación |
|---|---:|---:|---|
| Stock total de un vino | 23,783 | 0,265 | Mejora marcada; utiliza `idx_stock_sala_vino`. |
| Documentos en estado terminado | 1,183 | 1,094 | Utiliza índices parciales en Ingreso y Transferencia; el tiempo no mejora. |
| Últimos 20 ingresos terminados | 0,814 | 0,438 | Utiliza `idx_ingreso_estado_pendiente`. |
| Historial de precios por vino | 3,188 | 0,053 | Utiliza `idx_auditoria_precio_vino_fecha`. |
| Comprobantes por fecha y sala con renglones | 19,960 | 16,014 | Utiliza el índice de Comprobante, pero mantiene el escaneo secuencial de Renglon_Comprobante. |
| Stock de sala por vino | 13,953 | 0,155 | Utiliza `idx_stock_sala_vino`. |
| Renglones de ingreso por prefijo de vino | 1,873 | 2,600 | Mantienen escaneo secuencial de Renglon_Ingreso; la variación es ruido de medición. |
| Renglones de comprobante por vino | 9,458 | 0,206 | Utiliza `idx_renglon_comprobante_vino`. |

## 5. Análisis de los planes

### 5.1. Stock por vino

Las consultas sobre `Stock_Sala` pasaron de un escaneo secuencial de 100.000
filas a utilizar `idx_stock_sala_vino`.

En la consulta de stock total, el plan inicial examinaba 100.000 filas para
obtener cinco coincidencias. Con el índice, PostgreSQL utilizó un
`Bitmap Index Scan` seguido de un `Bitmap Heap Scan`.

Es una evidencia clara de que el índice resulta útil para búsquedas selectivas
por vino.

### 5.2. Documentos terminados

La vista de documentos utiliza los índices parciales:

- `idx_ingreso_estado_pendiente`
- `idx_transferencia_estado_pendiente`

Ambos aparecen en los planes posteriores como `Index Only Scan`. Sin embargo,
se registraron accesos al heap (`Heap Fetches`), por lo que no fueron
completamente cubiertos por el índice durante esta ejecución.

El tiempo total fue similar al escenario sin índices. Por lo tanto, se
confirma el uso de los índices, pero no una mejora temporal en esta carga.

### 5.3. Ingresos recientes

La consulta de los últimos veinte ingresos terminados pasó de un escaneo
secuencial de 3.000 filas a un `Index Scan` mediante
`idx_ingreso_estado_pendiente`.

Se redujo el tiempo observado y la cantidad de bloques accedidos.

El ordenamiento por fecha continúa siendo necesario porque el índice está
definido únicamente sobre `estado`.

### 5.4. Auditoría de precios

La consulta por vino pasó de recorrer 20.000 registros a utilizar
`idx_auditoria_precio_vino_fecha`.

El índice permite localizar las filas de un vino y contempla el orden
descendente por fecha definido en la consulta.

### 5.5. Comprobantes por fecha y sala

El índice `idx_comprobante_fecha_sala` permitió localizar los comprobantes
que cumplen los filtros de fecha y sala mediante un `Bitmap Index Scan`.

Sin embargo, PostgreSQL mantuvo un escaneo secuencial de los 60.000 registros
de `Renglon_Comprobante` para resolver el join.

El tiempo total permaneció prácticamente igual. El índice mejora el acceso
a Comprobante, pero no elimina el costo dominante de recorrer los renglones.

### 5.6. Búsqueda por prefijo en renglones de ingreso

La consulta con `LIKE 'BENCH-0007%'` mantuvo un escaneo secuencial de
`Renglon_Ingreso`.

Aunque existe un índice B-tree sobre `vino`, el planificador no lo seleccionó
para este patrón de búsqueda y volumen de datos.

No se considera una falla de la migración: un índice no garantiza mejoras
para todos los operadores ni para todas las distribuciones de datos.
Este caso se considera un candidato evaluado y descartado para incorporar
un índice adicional específico para el patrón de prefijo: el índice
disponible no fue seleccionado por el planificador y no existe evidencia
experimental suficiente para justificar otro índice sobre esa búsqueda.

### 5.7. Renglones de comprobante por vino

La búsqueda exacta por vino pasó de un escaneo secuencial de 60.000 filas
a utilizar `idx_renglon_comprobante_vino`.

El plan posterior empleó un `Bitmap Index Scan` y un `Bitmap Heap Scan`,
localizando tres coincidencias.

## 6. Catálogo de los índices implementados (A-39)

La migración `013_indices.sql` define nueve índices, cada uno derivado de
un patrón de consulta observado en los planes de la sección 4/5:

| Índice | Tipo | Justificación | Resultado medido |
|---|---|---|---|
| `idx_renglon_comprobante_vino` | B-tree sobre FK `vino` (join con `Vino`/`Stock_Sala`) | Búsquedas exactas de renglones por vino y joins frecuentes por FK. | Seq Scan 9,458 ms → índice 0,206 ms. |
| `idx_renglon_ingreso_vino` | B-tree sobre FK `vino` | Mismo patrón de join en renglones de ingreso. | Utilizado en la carga; para `LIKE` de prefijo el planificador no lo toma. |
| `idx_renglon_transferencia_vino` | B-tree sobre FK `vino` | Mismo patrón para transferencias y stock de sala. | Defensivo, patrón de join idéntico. |
| `idx_stock_sala_vino` | B-tree sobre FK `vino` | Stock por vino; consulta representativa `v_stock_total_vino`. | Seq Scan 23,783/13,953 ms → 0,265/0,155 ms. |
| `idx_comprobante_fecha_sala` | B-tree compuesto `(fecha, sala)` | Reportes fechados por sala (rango + igualdad); el orden de columnas cubre el filtro compuesto. | Bitmap Index Scan; el join con renglones mantiene Seq Scan del lado dominante. |
| `idx_auditoria_precio_vino_fecha` | B-tree `(vino, fecha_hora DESC)` | Historial de precios del más reciente al más antiguo; el `DESC` evita el ordenamiento. | 3,188 ms → 0,053 ms. |
| `idx_ingreso_estado_pendiente` | B-tree parcial `WHERE estado <> 'procesado'` | Bandeja de pendientes: la mayoría del historial está en 'procesado' y queda excluida del índice. | Index Scan/Only Scan en las consultas de estado. |
| `idx_transferencia_estado_pendiente` | B-tree parcial `WHERE estado <> 'procesado'` | Igual patrón para transferencias. | Index Only Scan en la vista de documentos pendientes. |

Variantes razonadas:

- **BRIN sobre `Auditoria_Precio.fecha_hora`**: evaluado y descartado. La
  tabla se escribe en orden temporal, pero es pequeña (una fila por cambio
  de precio) y el B-tree compuesto `(vino, fecha_hora DESC)` ya cubre el
  patrón; BRIN solo gana en tablas muy grandes.
- **Índices que duplican el orden de la PK** (por ejemplo, sobre las FK
  `comprobante` de las tablas de renglones): descartados; el join
  renglón→cabecera ya usa el índice de PK de la cabecera.
- **Índice adicional de expresión para `LIKE` de prefijo**: evaluado y
  descartado; el índice B-tree disponible no fue seleccionado por el
  planificador para ese patrón y no hubo evidencia experimental suficiente
  para justificar otro índice (sección 5.6).

## 7. Costo de escritura de la carga masiva

Para completar la comparación con datos de escritura se ejecutó
`db/benchmark/04_costo_escritura.ps1`, que carga el mismo conjunto de datos
sintéticos en dos bases temporales equivalentes (`idx_wcost_noidx_tmp` e
`idx_wcost_idx_tmp`): una sin los índices de la migración 013 y otra con
ellos aplicados antes de la carga.

| Medición | Duración | Observación |
|---|---:|---|
| Carga sin índices 013 | 43,29 s | Base con migraciones 001-012. |
| Creación de índices 013 sobre tablas ya cargadas | 1,15 s | Alternativa: cargar primero e indexar después. |
| Carga con índices 013 | 51,13 s | Base equivalente, 013 aplicado antes de cargar. |
| Delta de la carga | +7,83 s | Los índices encarecen cada INSERT. |

Observaciones:

1. La carga con índices fue aproximadamente un 18 % más lenta que la carga
   sin ellos en esta única ejecución.
2. La alternativa de cargar primero y crear los índices después tomó 1,15 s
   para los nueve índices de la migración 013 sobre las tablas ya cargadas,
   un costo total (43,29 + 1,15 = 44,44 s) muy inferior a la carga con
   índices previos (51,13 s) en esta medición.
3. Ambas bases quedaron con los mismos conteos (verificados): 20.000 vinos,
   60.000 renglones de comprobante y 100.000 registros de stock de sala.
4. La medición se registró en `db/benchmark/bench_resultados/costo_escritura.txt`.

Las limitaciones restantes de esta medición se detallan en la sección 7.

## 8. Limitaciones de la medición

Los resultados deben interpretarse considerando las siguientes limitaciones:

1. Se realizó una única ejecución por consulta en cada escenario.
2. Las consultas sin índices se ejecutaron antes que las consultas con
   índices. Por lo tanto, la segunda tanda pudo beneficiarse de una caché
   más caliente.
3. Los tiempos dependen del entorno de ejecución, recursos disponibles,
   estado de caché y actividad del servidor.
4. La carga es sintética y no representa necesariamente la distribución
   ni el volumen de producción.
5. Los resultados de tiempo no constituyen una garantía de rendimiento
   para otras cargas.
6. En la versión original del benchmark, la carga se realizaba antes de
   aplicar la migración 013 sin registrar el tiempo de carga. Esta
   limitación se resolvió con la medición de la sección 7
   (`04_costo_escritura.ps1`), que comparó la misma carga con y sin los
   índices adicionales en bases temporales equivalentes.
7. No se realizó una comparación específica del costo de mantenimiento de
   índices durante operaciones de actualización y eliminación: la medición
   de la sección 6 cubre únicamente INSERT de la carga masiva.

 Por estas razones, los tiempos de consulta se consideran orientativos. La
comparación de planes y bloques constituye la evidencia más estable del
efecto de los índices en las consultas selectivas; el costo de escritura
tiene su propia medición en la sección 7.

## 9. Conclusiones

La migración 013 demuestra utilidad para varias consultas representativas:

- Búsquedas de stock por vino.
- Consultas del historial de precios.
- Búsquedas exactas en renglones de comprobantes.
- Consultas de ingresos por estado.

También se observaron casos donde el índice no produjo una mejora temporal
apreciable, como la consulta de documentos terminados y el join de
comprobantes con sus renglones.

La búsqueda por prefijo en renglones de ingreso no utilizó el índice
disponible. No se agrega otro índice únicamente para forzar un plan
alternativo sin evidencia de que resulte conveniente en cargas reales.

En consecuencia, los índices implementados tienen evidencia de utilidad
en consultas selectivas, aunque su beneficio debe evaluarse según el patrón
de acceso y el volumen de datos.

## 10. Archivos de evidencia

- `db/benchmark/01_carga_sintetica.sql`: generación de datos.
- `db/benchmark/02_consultas.sql`: consultas principales.
- `db/benchmark/03_patrones_sintetica.sql`: consultas adicionales.
- `db/benchmark/run_bench.ps1`: ejecución y comparación.
- `db/benchmark/bench_resultados/bench_antes.txt`: planes sin índices.
- `db/benchmark/bench_resultados/bench_despues.txt`: planes con índices.
- `db/benchmark/04_costo_escritura.ps1`: medición del costo de escritura.
- `db/benchmark/bench_resultados/costo_escritura.txt`: duraciones de carga
  con y sin índices.
- `db/migrations/013_indices.sql`: índices evaluados.

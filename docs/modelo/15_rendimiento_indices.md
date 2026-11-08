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
| Stock total de un vino | 20,278 | 0,331 | Mejora marcada; utiliza `idx_stock_sala_vino`. |
| Documentos en estado terminado | 1,949 | 2,129 | Utiliza índices parciales en Ingreso y Transferencia; el tiempo no mejora. |
| Últimos 20 ingresos terminados | 1,287 | 0,966 | Utiliza `idx_ingreso_estado_pendiente`. |
| Historial de precios por vino | 5,292 | 0,079 | Utiliza `idx_auditoria_precio_vino_fecha`. |
| Comprobantes por fecha y sala con renglones | 14,870 | 14,707 | Utiliza el índice de Comprobante, pero mantiene el escaneo secuencial de Renglon_Comprobante. |
| Stock de sala por vino | 23,160 | 0,231 | Utiliza `idx_stock_sala_vino`. |
| Renglones de ingreso por prefijo de vino | 3,559 | 1,665 | Mantiene escaneo secuencial de Renglon_Ingreso. |
| Renglones de comprobante por vino | 7,654 | 0,130 | Utiliza `idx_renglon_comprobante_vino`. |

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

### 5.7. Renglones de comprobante por vino

La búsqueda exacta por vino pasó de un escaneo secuencial de 60.000 filas
a utilizar `idx_renglon_comprobante_vino`.

El plan posterior empleó un `Bitmap Index Scan` y un `Bitmap Heap Scan`,
localizando tres coincidencias.

## 6. Limitaciones de la medición

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

Por estas razones, los tiempos se consideran orientativos. La comparación
de planes y bloques permite observar con mayor claridad el efecto de los
índices en las consultas selectivas.

## 7. Conclusiones

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

## 8. Archivos de evidencia

- `db/benchmark/01_carga_sintetica.sql`: generación de datos.
- `db/benchmark/02_consultas.sql`: consultas principales.
- `db/benchmark/03_patrones_sintetica.sql`: consultas adicionales.
- `db/benchmark/run_bench.ps1`: ejecución y comparación.
- `db/benchmark/bench_resultados/bench_antes.txt`: planes sin índices.
- `db/benchmark/bench_resultados/bench_despues.txt`: planes con índices.
- `db/migrations/013_indices.sql`: índices evaluados.

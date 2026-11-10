# Carga masiva de datos — Bodegas del Atuel (issues B-01, B-04, B-05)

Genera el dataset completo del TPI respetando las reglas de negocio de la base
(29 tablas, triggers RN-01..RN-15) y los volúmenes exigidos por la consigna:

| Tabla | Filas |
|---|---|
| Cliente (Socio / Distribuidor / Exportador) | 20.000 (60% / 25% / 15%) |
| Comprobante | 150.000 |
| Renglon_Comprobante | 500.000+ |
| Fincas / Parcelas / Lotes / Análisis | 30 / ~150 / ~300 / ~600 |
| Bodegas / Vinos / Composición | 8 / 140 / ~200 |
| Salas / Empleados / Transportistas | 24 / 120 / 15 |
| Ingresos / Transferencias | 1.200 / 900 |

Todas las tablas quedan con al menos una fila; tres superan las 10.000 filas
(Cliente, Comprobante, Renglon_Comprobante) y una supera las 100.000.

## Requisitos

- PostgreSQL con el esquema del proyecto aplicado (`db/migrations/001..013`).
- Python 3.12+ con `psycopg` (3.x) y `faker`:
  `pip install psycopg faker`

## Configuración de conexión (sin secretos en el repo)

El script **no contiene ninguna contraseña**: se conecta con variables de
entorno estándar de libpq. Podés definirlas en el entorno o copiar el
`.env.example` de la raíz del proyecto como `db/seed/.env` (está en
`.gitignore`, nunca se commitea):

```
PGHOST=localhost
PGPORT=5432
PGUSER=postgres
PGDATABASE=bodegas_del_atuel
PGPASSWORD=...            # nunca la escribas en el codigo ni la commitees
```

> Seguridad: una versión anterior de `generador_masivo.py` subió una clave al
> repositorio. Si esa clave sigue siendo válida en tu PostgreSQL local,
> **cambiala** (`ALTER USER postgres PASSWORD '...'`).

## Ejecución

```
python db/seed/generador_masivo.py              # carga completa + benchmark
python db/seed/generador_masivo.py --sin-benchmark
```

El script arranca con `TRUNCATE ... RESTART IDENTITY CASCADE` de las 29 tablas:
la base queda con el dataset nuevo (los datos previos se pierden).

Salida: conteos por tabla, tiempos por fase, comparación fila-a-fila vs lotes y
consultas de control. Todo queda en `db/seed/resultados/reporte_carga.txt`.

## Catálogos desde CSV (Anexo B — issue B-01)

Los catálogos **no se generan al azar**: se cargan desde `catalogos/`.

| Archivo | Columnas | Fuente |
|---|---|---|
| `cepas.csv` | `nombre,tipo` (7 tintas + 5 blancas) | Anexo B.1 |
| `maridajes.csv` | `nombre,temperatura` (8) | Anexo B.2 |
| `localidades.csv` | `nombre,codigo_postal,provincia,encargado_regional` (18) | Anexo B.3 |
| `tipos_vino.csv` | `tipo` (tinto, blanco, rosado, espumante) | Anexo B.4 |
| `presentaciones.csv` | `volumen_ml,nombre` (187/375/750/1500/3000) | Anexo B.4 |

Notas de formato: CSV UTF-8 con coma y encabezado. Los nombres están
normalizados **sin tildes** para evitar diferencias de codificación entre
herramientas (psql, COPY, editores). Los códigos postales y encargados
regionales son orientativos/ficticios (el Anexo B no los define). Los nombres
de bodegas, fincas, clientes y transportistas sí se generan con Faker, como
permite el Anexo B.4.

## Orden de carga (dependencias FK)

```
Cepa ─┐
Maridaje ─┐
Localidad ─┼─► Finca ─► Parcela ─► Lote ─► Analisis
          │      (Cepa)   (Finca)    (Bodega)
Bodega ──┤                          │
Transportista ─► Transportista_Localidad
          │
          └─► Sala ─► Empleado
              │
Vino (Bodega, Cepa) ─► Composicion, Vino_Maridaje, Stock_Deposito
    │
    ├─► Ingreso (Transportista, Bodega) ─► Renglon_Ingreso
    │        └─ sp_procesar_ingreso ─► Stock_Deposito += renglones
    ├─► Transferencia (Sala) ─► Renglon_Transferencia
    │        └─ sp_procesar_transferencia ─► Stock_Deposito -= / Stock_Sala +=
    └─► Comprobante (Cliente, Sala) ─► Renglon_Comprobante ─► consume Stock_Sala
Cliente ─► Socio / Distribuidor / Exportador ─► Permiso_Exportacion
```

## Manejo de triggers (decisión documentada)

1. **Cadena productiva y de stock con triggers ACTIVOS**: los ingresos se
   insertan en `en_confeccion`, se les agregan renglones, pasan a `terminado`
   y se procesan con `CALL sp_procesar_ingreso(...)` (RN-10). Las
   transferencias ídem con `sp_procesar_transferencia` (RN-11), que descuenta
   el depósito y acredita las salas (RN-09). Los clientes y subtipos se cargan
   con los triggers RN-06 activos (el descuento lo calcula la base, no el
   script).
2. **Historial de ventas (150k comprobantes / 500k+ renglones) con los
   triggers de `Comprobante` y `Renglon_Comprobante` DESACTIVADOS**
   (`ALTER TABLE ... DISABLE TRIGGER USER`) durante la carga masiva, porque
   ejecutar el recálculo de totales por renglón 500.000 veces duplica el costo
   de la carga. Al terminar:
   - los importes de cabecera se recalculan con **una sola** operación de
     conjunto con la misma fórmula de RN-08;
   - el stock de sala se descuenta con **una sola** operación de conjunto
     (equivalente al efecto del trigger RN-09);
   - los triggers se reactivan (`ENABLE TRIGGER USER`).
   Riesgo controlado: entre el `DISABLE` y el `ENABLE` las reglas no vigilan;
   por eso la fase final ejecuta **consultas de control** que verifican
   importes, descuentos históricos, stock nunca negativo y ausencia de filas
   huérfanas. Si algo no cuadra, el script termina con código de error.

## Reproducibilidad (semilla fija — issue B-03)

`random.seed(42)` + `Faker.seed(42)`. Dos ejecuciones el mismo día producen
exactamente los mismos datos. Las fechas se anclan a `CURRENT_DATE` (exigencia
de la consigna para "última semana/trimestre"), por lo que ejecuciones en días
distintos desplazan la ventana temporal manteniendo la misma forma y valores.

## Comparación fila-a-fila vs por lotes

El script incluye un benchmark (en una transacción con `ROLLBACK`, sin dejar
datos): inserta la misma cantidad de renglones uno por uno y con
`executemany`, y reporta ambos tiempos y la aceleración. Las tablas masivas
se cargan con `COPY` (el método más rápido de PostgreSQL) y las chicas con
`executemany`. Los tiempos quedan en `resultados/reporte_carga.txt`.

## Volcado completo (`dump_completo.sql.gz`)

El dump del dataset cargado pesa decenas de MB, por eso se genera aparte:

```
pg_dump -h localhost -U postgres -d bodegas_del_atuel \
        --no-owner --no-privileges | gzip > dump_completo.sql.gz
```

## Consultas de control incluidas

1. Renglones de comprobante sin cabecera (huérfanas) = 0.
2. Stock de sala / depósito negativo = 0.
3. Cabeceras con `total` ≠ suma de subtotales de renglones = 0.
4. Renglones con descuento ≠ descuento del cliente = 0.
5. Vinos con composición cuya suma ≠ 100 = 0.
6. Tablas sin filas = 0.
7. Comprobantes anteriores al alta del cliente = 0.
8. Clientes sin exactamente un subtipo = 0.

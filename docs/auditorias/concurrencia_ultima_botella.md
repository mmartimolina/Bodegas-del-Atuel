# A-37 — Demostración de concurrencia al vender la última botella

Issue: #43 (A-37). Reproducible con `db/concurrency/run_concurrencia.ps1`.

## 1. Objetivo

Demostrar con dos sesiones PostgreSQL independientes (`psql`) que no es
posible vender dos veces la última botella disponible, gracias al bloqueo
de fila `SELECT ... FOR UPDATE` implementado por la migración
`006_rn09_stock_ventas.sql` (funciones `fn_rn09_consumir_stock`,
`fn_rn09_reponer_stock` y el trigger `trg_renglon_comprobante_stock`), y
mostrar cuál sería el riesgo si ese bloqueo no existiera.

## 2. Escenario reproducido

- Base temporal con las migraciones 001 a 012 (esquema productivo).
- Datos mínimos (`a37_seed_ultima_botella.sql`): una sala (777701), un vino
  `A37-V1` con **stock inicial = 1** en `Stock_Sala`, cliente socio y un
  comprobante vacío (777701).
- Dos procesos `psql` independientes se conectan a la **misma base temporal**
  y ejecutan cada uno una "venta" en paralelo (el script lanza ambos
  procesos y coordinador monitorea `pg_stat_activity` durante ~10 s).

El nivel de aislamiento es el predeterminado de PostgreSQL,
**READ COMMITTED** (no se define ningún nivel especial).

## 3. Fase 1 — con el mecanismo RN-09 (FOR UPDATE)

Sesión A: `INSERT INTO "Renglon_Comprobante" ...` dentro de una transacción
abierta. El trigger `trg_renglon_comprobante_stock` consume el stock bajo
`SELECT ... FOR UPDATE` y la transacción se mantiene abierta 6 s
(`pg_sleep(6)`).

Sesión B: el mismo `INSERT`, lanzado ~2 s después.

Resultados observados (ejecución del 2026-11-08; evidencia cruda en
`docs/auditorias/concurrencia_ultima_botella_raw.txt`):

1. La sesión B se quedó **bloqueada en espera**: `pg_stat_activity` mostró
   durante los 4 s de espera las dos sesiones, con
   `wait_event_type = Lock`, `wait_event = transactionid`, mientras la
   sesión A hacía `pg_sleep(6)`.
2. El `INSERT` de la sesión B tardó **4,005 s** en resolver
   (`Time: 4004,648 ms`): esperó hasta el COMMIT de A.
3. Al obtener la fila ya actualizada (stock = 0), `fn_rn09_consumir_stock`
   rechazó la venta:
   `ERROR: RN-09: stock insuficiente en la sala 777701 para el vino A37-V1
   (disponible: 0, requerido: 1)`.
4. La transacción de B quedó abortada (el rechazo es antes de mover el
   stock); su `psql` terminó con error y no persistió datos.
5. Estado final de la base: `stock final = 0,
   renglones de A37-V1 en el comprobante = 1`.

## 4. Fase 2 — comparación controlada sin FOR UPDATE

En una **segunda base temporal independiente**
(`a37_ultima_botella_noblock_tmp`), con el mismo seed, se simuló la venta
sin el mecanismo de bloqueo: dos `UPDATE` directos de stock por cada sesión
(esta fase no usa el trigger de RN-09). Además, únicamente en esta base
temporal se retiró el `CHECK` de stock no negativo
(`ck_stock_sala_cantidad_no_negativa`) para exhibir el defecto completo; la
base de producción `bodegas_atuel` no se modificó.

- Sesión A: `UPDATE Stock_Sala SET cantidad = cantidad - 1`, tx abierta 6 s.
- Sesión B: primero valida el stock con un `SELECT` propio, **sin bloquear
  filas**, y luego aplica su venta con otro `UPDATE` sin revalidar.

Resultados observados:

1. El `SELECT` de validación de B leyó `stock leido por la sesion B: 1`
   (la venta de A estaba sin confirmar), por lo que B "valida" una
   existencia que no es real.
2. El `UPDATE` de B esperó **4,0 s** en `Lock | transactionid` y, después
   del COMMIT de A, se aplicó sobre el dato **nuevo** (posterior a la
   validación): `stock final = -1`, es decir, **venta doble** de la última
   botella.
3. Sin el `CHECK` (retirado en la base temporal de la comparación) y sin el
   bloqueo, dos sesiones confirman la misma unidad.

## 5. Interpretación

- **Con FOR UPDATE:** la validación del stock ocurre *después* de esperar el
  estado confirmado de la otra venta: la sesión B espera primero (evidencia
  en `pg_stat_activity`) y solo entonces evalúa la disponibilidad. La
  segunda venta se rechaza con `RN-09 ... stock insuficiente`; nunca se
  autoricen dos ventas ni un stock negativo; la operación fallida no deja
  datos parciales (el rechazo es anterior a cualquier escritura de B).
- **Sin FOR UPDATE:** la validación (lectura) y la modificación son
  sentencias separadas que no coordinan entre sí. Con READ COMMITTED cada
  sentencia ve la última confirmación, pero la decisión de B (`stock = 1`)
  ya no es válida cuando el `UPDATE` se ejecuta tras el COMMIT de A: la
  venta se descuenta sobre un stock que ya no existía. El `CHECK` de stock
  no negativo habría rechazado ese `UPDATE` (segunda línea de defensa, con
  el rechazo después de la validación); el mecanismo correcto es el bloqueo `SELECT ... FOR UPDATE` de RN-09, que desplaza la espera
  *antes* de la validación y evita el coste de descubrir el problema una
  vez aplicada la operación.

## 6. Limitaciones de la demostración

- La fase 2 es una comparación controlada sobre una base temporal donde se
  simularon las ventas con `UPDATE` directos (y se retiró el `CHECK`),
  porque el esquema productivo no debe modificarse para simular el error.
- El coordinador (script PowerShell) lanza dos procesos `psql` reales e
  independientes; la coordinación por tiempos (`pg_sleep(6)`) es automática
  y la evidencia de espera proviene del propio servidor
  (`pg_stat_activity` y `EXPLAIN` de tiempos informado por `psql`).
- La ejecución se repitió dos veces con resultados equivalentes (espera de
  ~4 s en Lock y rechazo RN-09 en fase 1).
- Los tiempos dependen del entorno del servidor (container local).

## 7. Archivos

- `db/concurrency/run_concurrencia.ps1`: orquestador (crea la base temporal,
  aplica migraciones, lanza las dos sesiones, monitorea y verifica).
- `db/concurrency/a37_seed_ultima_botella.sql`: datos mínimos (stock = 1).
- `db/concurrency/a37_sesion_a.sql` y `a37_sesion_b.sql`: fase 1.
- `db/concurrency/a37_sesion_a_sin_bloqueo.sql`, `a37_sesion_b_sin_bloqueo.sql`
  y `a37_retirar_check.sql`: fase 2 (comparación controlada).
- `docs/auditorias/concurrencia_ultima_botella_raw.txt`: salidas crudas de
  las sesiones y del monitoreo.
- Bases temporales utilizadas (eliminadas al finalizar):
  `a37_ultima_botella_tmp`, `a37_ultima_botella_noblock_tmp`.

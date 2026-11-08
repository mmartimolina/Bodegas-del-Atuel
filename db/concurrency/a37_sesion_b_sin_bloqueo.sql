-- a37_sesion_b_sin_bloqueo.sql
-- Comparacion controlada sin SELECT ... FOR UPDATE (issue #43 / A-37).
-- Sesion B: valida el stock en una sentencia propia (sin bloquear ninguna
-- fila), y aplica la venta con una sentencia UPDATE propia. La validacion
-- queda desactualizada: ve el stock de A no confirmado (o el previo) y
-- descuenta igual; tras el COMMIT de A, el UPDATE de B aplica sobre el dato
-- nuevo y el stock termina en -1 (venta doble de la ultima botella).

\echo '--- SESION B (venta concurrente SIN bloqueo) ---'
SELECT clock_timestamp() AS b_inicio_tx;

BEGIN;

-- 1) Validacion en una sentencia propia: sin FOR UPDATE esta lectura NO
--    coordina con la transaccion abierta de la sesion A.
SELECT clock_timestamp() AS b_valida_stock_antes;
SELECT 'stock leido por la sesion B: ' || cantidad AS b_stock_leido
  FROM "Stock_Sala" WHERE sala = 777701 AND vino = 'A37-V1';

\timing on
-- 2) Aplicacion de la venta sin revalidar ni bloquear.
UPDATE "Stock_Sala" SET cantidad = cantidad - 1
 WHERE sala = 777701 AND vino = 'A37-V1';
\timing off

COMMIT;
SELECT clock_timestamp() AS b_commit_hecho;

--Resultado observable de la base tras ambas ventas (lo verifica el runner):
SELECT 'SESION B: la actualizacion se aplico tras esperar el COMMIT de A.' AS resultado;

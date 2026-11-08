-- a37_sesion_a_sin_bloqueo.sql
-- Comparacion controlada sin SELECT ... FOR UPDATE (issue #43 / A-37), en una
-- base temporal independiente donde el CHECK de stock no negativo de la tabla
-- Stock_Sala se retira para mostrar el riesgo completo: la actualizacion se
-- aplica sobre el dato nuevo tras la espera, y el stock termina negativo
-- (venta doble de la ultima botella).
--
-- Sesion A simula la venta de forma directa (trial sin el mecanismo RN-09):
--   UPDATE Stock_Sala SET cantidad = cantidad - 1, y mantiene la tx abierta.

\echo '--- SESION A (venta SIN bloqueo) ---'
SELECT clock_timestamp() AS a_inicio_tx;

BEGIN;
\timing on
UPDATE "Stock_Sala" SET cantidad = cantidad - 1
 WHERE sala = 777701 AND vino = 'A37-V1';
\timing off

SELECT cantidad AS a_stock_en_mi_tx FROM "Stock_Sala" WHERE sala = 777701 AND vino = 'A37-V1';

SELECT clock_timestamp() AS a_venta_aplicada_mantengo_tx;
SELECT pg_sleep(6);
SELECT clock_timestamp() AS a_antes_del_commit;
COMMIT;
SELECT clock_timestamp() AS a_commit_hecho;

SELECT 'SESION A: venta sin bloqueo confirmada (sin RN-09, con CHECK retirado).' AS resultado;

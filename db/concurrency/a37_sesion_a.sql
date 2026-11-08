-- a37_sesion_a.sql (con bloqueo)
-- Sesion A de la demostracion de concurrencia (issue #43 / A-37).
-- Inserta el renglon de la venta (dispara el consumo de stock de RN-09 bajo
-- SELECT ... FOR UPDATE) y mantiene la transaccion abierta unos segundos
-- para que la sesion B deba esperar el COMMIT.

\echo '--- SESION A (venta con bloqueo) ---'
SELECT clock_timestamp() AS a_inicio_tx;

BEGIN;
\timing on
INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
VALUES (777701, 'A37-V1', 1, 123.00);
\timing off

SELECT clock_timestamp() AS a_venta_registrada_mantengo_tx;
SELECT pg_sleep(6);
SELECT clock_timestamp() AS a_antes_del_commit;
COMMIT;
SELECT clock_timestamp() AS a_commit_hecho;

SELECT 'SESION A: venta confirmada; la fila de stock quedo bloqueada por FOR UPDATE hasta este COMMIT.' AS resultado;

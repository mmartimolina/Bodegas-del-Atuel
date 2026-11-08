-- a37_sesion_b.sql (con bloqueo)
-- Sesion B de la demostracion de concurrencia (issue #43 / A-37).
-- Intenta vender la misma ultima botella mientras la sesion A mantiene una
-- transaccion abierta con la fila de Stock_Sala bloqueada por
-- SELECT ... FOR UPDATE. El INSERT de B debe bloquearse (wait_event Lock,
-- relation de Stock_Sala) hasta el COMMIT de A y entonces rechazarse por
-- RN-09 (stock insuficiente), dejando la venta de A como unica.

\echo '--- SESION B (venta concurrente con bloqueo) ---'
SELECT clock_timestamp() AS b_inicio_tx;

BEGIN;
\timing on
INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
VALUES (777701, 'A37-V1', 1, 123.00);
\timing off

SELECT clock_timestamp() AS b_venta_registrada_no_deberia_pasar;
COMMIT;

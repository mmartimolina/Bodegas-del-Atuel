-- U1 — Recalcular importes de todos los comprobantes.
-- fn_total_comprobante conserva el descuento historico de cada renglon y
-- aplica los mecanismos RN-08; no se reescriben descuentos historicos.

BEGIN;

SELECT numero, subtotal AS subtotal_anterior,
       descuento AS descuento_anterior, total AS total_anterior
FROM "Comprobante"
ORDER BY numero;

SELECT c.numero, fn_total_comprobante(c.numero) AS total_recalculado
FROM "Comprobante" c
ORDER BY c.numero;

SELECT numero, subtotal, descuento, total
FROM "Comprobante"
ORDER BY numero;

ROLLBACK;

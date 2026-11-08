-- 02_consultas.sql
-- Consultas de medicion (#44/#46): cada consulta imprime EXPLAIN (ANALYZE, BUFFERS)
-- - con/without indices (013) ejecutan заранес y se mide en tiempo real.
-- El runner ejecuta este archivo dos veces (antes/despues de 013) y las salidas
-- se comparan en docs/modelo/15_rendimiento_indices.md.

\set ON_ERROR_STOP on
\timing off

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT stock_deposito, stock_salas
  FROM v_stock_total_vino
 WHERE vino = 'BENCH-004997';

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT count(*)
  FROM v_documentos_pendientes
 WHERE estado = 'terminado';

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT codigo, fecha
  FROM "Ingreso"
 WHERE estado = 'terminado'
 ORDER BY fecha DESC
 LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT precio_anterior, precio_nuevo, fecha_hora
  FROM "Auditoria_Precio"
 WHERE vino = 'BENCH-000123'
 ORDER BY fecha_hora DESC
 LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT count(*), sum(r.subtotal)
  FROM "Comprobante" c
  JOIN "Renglon_Comprobante" r ON r.comprobante = c.numero
 WHERE c.fecha BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'
   AND c.sala = 990012;

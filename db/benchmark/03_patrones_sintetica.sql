-- 03_patrones_sintetica.sql
-- Consultas adicionales sobre patrones de acceso a datos sinteticos.
-- Complementa las consultas principales de 02_consultas.sql.
-- Permite observar el comportamiento de indices sobre stock y renglones.

\set ON_ERROR_STOP on

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT cantidad
  FROM "Stock_Sala"
 WHERE vino = 'BENCH-002222';

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT sum(r.cantidad)
  FROM "Renglon_Ingreso" r
  JOIN "Vino" v ON v.codigo = r.vino
 WHERE r.vino LIKE 'BENCH-0007%';

EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT count(*)
  FROM "Renglon_Comprobante" r
 WHERE r.vino = 'BENCH-009999';

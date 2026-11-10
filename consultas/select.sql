-- Issue B-68: consultas S1-S12 del punto 8.4 y 8.5.
-- Requiere psql. Los scripts conservan sus consultas de contexto y control;
-- consulta_s7 y consulta_s12 revierten los datos demostrativos con ROLLBACK.

\set ON_ERROR_STOP on
\ir consulta_s1_ranking_vinos_mas_vendidos.sql
\ir consulta_s2_vinos_vendidos_en_todas_salas.sql
\ir consulta_s3_clientes_por_tipo_sala_semana.sql
\ir consulta_s4_top_salas_transferencia_vino.sql
\ir consulta_s5_salas_menos_transferencias_pendientes.sql
\ir consulta_s6_vinos_sin_stock_sala.sql
\ir consulta_s7_transportista_mas_activo_mes.sql
\ir consulta_s8_ventas_por_sala_trimestre.sql
\ir consulta_s9_ficha_vino.sql
\ir consulta_s10_rendimiento_por_hectarea.sql
\ir consulta_s11_ranking_vinos_y_acumulado_sala.sql
\ir consulta_s12_division_bodega_y_sin_tintos.sql

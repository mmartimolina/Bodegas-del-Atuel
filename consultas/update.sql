-- Issue B-66: ejecutar las seis consignas UPDATE del punto 8.1.
-- Requiere psql. Cada archivo muestra el estado previo y posterior, y termina
-- con ROLLBACK para que la ejecucion de verificacion no persista cambios.
-- Para aplicar una consigna de forma permanente, revisar sus filas y cambiar
-- su ROLLBACK final por COMMIT antes de ejecutarla individualmente.

\set ON_ERROR_STOP on
\ir update_recalcular_comprobantes.sql
\ir update_salarios.sql
\ir update_precio_bodega.sql
\ir update_intercambiar_dias.sql
\ir update_descuento_menos_vendidos.sql
\ir update_descuento_exportadores.sql

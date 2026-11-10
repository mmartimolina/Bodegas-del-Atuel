-- Issue B-65: ejecutar las seis consignas INSERT del punto 8.2.
-- Requiere psql; cada archivo implementa y verifica una consigna.

\set ON_ERROR_STOP on
\ir asignar_cobertura_general_alvear.sql
\ir maridaje_cordero_al_disco.sql
\ir crear_comprobante_tres_renglones.sql
\ir insertar_bodega.sql
\ir insertar_sala.sql
\ir crear_ingreso_confeccion.sql

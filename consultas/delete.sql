-- Issue B-67: borrados D1-D6 de la seccion 8.3.
-- Requiere psql. Estas operaciones eliminan datos; por seguridad no se
-- ejecutan implicitamente al abrir el archivo. Primero inspeccione cada
-- script en una base desechable y ejecute de a uno.
--
-- Uso explicito: psql ... -v apply_deletes=true -f consultas/delete.sql

\set ON_ERROR_STOP on
\if :{?apply_deletes}
    \if :apply_deletes
        \ir borrar_comprobantes_socios.sql
        \ir borrar_cepas_sin_uso.sql
        \ir borrar_empleados_sala_baja.sql
        \ir borrar_socios_antiguos_sin_compras.sql
        \ir borrar_ingresos_procesados_antiguos.sql
        \ir borrar_socios_sin_compras_localidad.sql
    \else
        \echo 'Borrados omitidos. Revise las consultas y use -v apply_deletes=true para ejecutarlas.'
    \endif
\else
    \echo 'Borrados omitidos. Revise las consultas y use -v apply_deletes=true para ejecutarlas.'
\endif

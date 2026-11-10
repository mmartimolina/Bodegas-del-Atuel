-- Issue B-25 / D5: eliminar ingresos procesados antiguos
-- Consigna (sección 8.3, D5): eliminar los ingresos en estado procesado
-- de hace más de 365 días.
--
-- Dependencias y triggers:
--   * La FK fk_renglon_ingreso_ingreso es ON DELETE CASCADE: los renglones
--     se borran junto con su ingreso.
--   * El trigger trg_renglon_ingreso_confeccion (RN-12) impide borrar
--     renglones cuya cabecera salió de en_confeccion. Al borrarse la
--     cabecera en cascada, el trigger ya no encuentra el ingreso y falla
--     con "RN-12: no existe la cabecera de ingreso ...". Para este borrado
--     de MANTENIMIENTO de históricos se deshabilita el trigger dentro de
--     la MISMA transacción y se rehabilita antes de confirmar: en
--     PostgreSQL el DDL es transaccional, así que si algo falla, el
--     ROLLBACK también revierte el estado del trigger.
--   * El stock del depósito NO se modifica: el stock se aplicó al
--     procesar cada ingreso mediante el procedure sp_procesar_ingreso
--     (operación de negocio), no por triggers de fila; borrar el histórico
--     no revierte movimientos ya realizados.

BEGIN;

-- 1. Pre-verificación: ingresos procesados con más de 365 días (los que
--    se van a borrar).
SELECT COUNT(*) AS ingresos_procesados_viejos
FROM "Ingreso"
WHERE estado = 'procesado' AND fecha < CURRENT_DATE - 365;

-- 2. Pre-verificación de la cascada: renglones que se borrarán junto con
--    esas cabeceras.
SELECT COUNT(*) AS renglones_afectados
FROM "Renglon_Ingreso" ri
JOIN "Ingreso" i ON i.codigo = ri.ingreso
WHERE i.estado = 'procesado' AND i.fecha < CURRENT_DATE - 365;

-- 3. Pre-verificación de contraste: ingresos procesados recientes (menos
--    de 365 días) NO deben borrarse, y tampoco los terminados.
SELECT estado, COUNT(*) AS cantidad
FROM "Ingreso"
GROUP BY estado;

-- 4. Deshabilitar RN-12 solo para el borrado masivo de históricos
--    (ver cabecera: el DDL es transaccional y se rehabilita en el paso 6).
ALTER TABLE "Renglon_Ingreso" DISABLE TRIGGER trg_renglon_ingreso_confeccion;

-- 5. Eliminación dentro de la transacción.
DELETE FROM "Ingreso"
WHERE estado = 'procesado' AND fecha < CURRENT_DATE - 365;

-- 6. Rehabilitar el trigger dentro de la misma transacción.
ALTER TABLE "Renglon_Ingreso" ENABLE TRIGGER trg_renglon_ingreso_confeccion;

-- 7. Post-verificación: no quedan ingresos procesados con más de 365 días.
SELECT COUNT(*) AS procesados_viejos_restantes
FROM "Ingreso"
WHERE estado = 'procesado' AND fecha < CURRENT_DATE - 365;

-- 8. Post-verificación: quedan exactamente los ingresos recientes y los
--    terminados (los que mostró el paso 3).
SELECT estado, COUNT(*) AS cantidad, MIN(fecha) AS fecha_min, MAX(fecha) AS fecha_max
FROM "Ingreso"
GROUP BY estado;

-- 9. Post-verificación de la cascada: no quedan renglones huérfanos.
SELECT COUNT(*) AS renglones_huerfanos
FROM "Renglon_Ingreso" ri
WHERE NOT EXISTS (SELECT 1 FROM "Ingreso" i WHERE i.codigo = ri.ingreso);

-- 10. Post-verificación: el trigger quedó habilitado (tgenabled = 'O').
SELECT t.tgname AS trigger, t.tgenabled AS estado
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
WHERE c.relname = 'Renglon_Ingreso'
  AND t.tgname = 'trg_renglon_ingreso_confeccion';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;

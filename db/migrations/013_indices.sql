-- 013_indices.sql
-- Issues #45 / #46: indices de acceso sobre relaciones con alto volumen o con
-- predicates / joins frecuentes; se evitan los indices que no aportan (ver
-- docs/modelo/15_rendimiento_indices.md para el detalle y mediciones).
--
-- Candidata descartada con justificacion (issue #45):
--   * BRIN sobre Auditoria_Precio.fecha_hora: la tabla se escribe en orden
--     temporal, pero pocas filas (una por cambio de precio) y con indice btree
--     (vino, fecha_hora DESC) basta; BRIN solo gana en tablas muy grandes.
--   * Indices que duplican el orden de la PK (p.ej. idx_renglon... por cabecera):
--     las FK de renglones apuntan a cabeceras por su PK, no al reves; el join
--     renglon->cabecera usa el indice de PK de la cabecera.
--
-- todos son CREATE INDEX IF NOT EXISTS: la migracion es re-ejecutacion.

BEGIN;

-- RN-09: por cada movimiento de stock se filtra por vino (y sala) en ambas
-- tablas de stock; las PK (sala, vino) y (vino) ayudan a las lecturas por
-- clave primaria, pero el join de stock con vino/renglones se beneficia de
-- un indice lider por vino.
CREATE INDEX IF NOT EXISTS idx_renglon_comprobante_vino
    ON "Renglon_Comprobante" (vino);

CREATE INDEX IF NOT EXISTS idx_renglon_ingreso_vino
    ON "Renglon_Ingreso" (vino);

CREATE INDEX IF NOT EXISTS idx_renglon_transferencia_vino
    ON "Renglon_Transferencia" (vino);

CREATE INDEX IF NOT EXISTS idx_stock_sala_vino
    ON "Stock_Sala" (vino);

-- Consultas por sala (informes de movimientos/partes diarias de la sala de
-- ventas: reportes fechados por sala), lideran por fecha.
CREATE INDEX IF NOT EXISTS idx_comprobante_fecha_sala
    ON "Comprobante" (fecha, sala);

-- RN-13: historial de precios por vino, con el mas reciente primero.
CREATE INDEX IF NOT EXISTS idx_auditoria_precio_vino_fecha
    ON "Auditoria_Precio" (vino, fecha_hora DESC);

-- v_documentos_pendientes y sp_procesar_* filtran por estado (bandeja de
-- pendientes); parciales: se excluye 'procesado', la mayoria del historial.
CREATE INDEX IF NOT EXISTS idx_ingreso_estado_pendiente
    ON "Ingreso" (estado)
    WHERE estado <> 'procesado';

CREATE INDEX IF NOT EXISTS idx_transferencia_estado_pendiente
    ON "Transferencia" (estado)
    WHERE estado <> 'procesado';

COMMIT;

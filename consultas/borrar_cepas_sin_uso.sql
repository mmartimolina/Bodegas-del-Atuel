-- Issue B-22 / D2: Eliminar cepas sin usos
-- Consigna (sección 8.3, D2): eliminar las cepas que no componen ningún
-- vino ni están plantadas en ninguna parcela.
--
-- Estado del dataset: las 12 cepas del catálogo del Anexo B se usan TODAS
-- en composiciones y parcelas (lo verifica el paso 1), por lo que el
-- borrado real sobre el catálogo afecta 0 filas. Para demostrar el DELETE
-- con filas reales, el paso 2 incorpora UNA cepa demostrativa sin usos
-- dentro de la misma transacción; el paso 4 la elimina con el DELETE
-- general. Al confirmar la transacción la base queda sin datos demo.
--
-- Dependencias FK (ambas ON DELETE RESTRICT):
--   * fk_composicion_cepa : "Composicion".cepa -> "Cepa".id
--   * fk_parcela_cepa     : "Parcela".cepa     -> "Cepa".id
-- Una cepa en uso NO puede borrarse: el paso 6 prueba el rechazo real.

BEGIN;

-- 1. Pre-verificación: cepas del catálogo sin uso (sin composición ni
--    parcela). Con el Anexo B completo el resultado es 0 filas.
SELECT c.id, c.nombre, c.tipo
FROM "Cepa" c
WHERE NOT EXISTS (SELECT 1 FROM "Composicion" co WHERE co.cepa = c.id)
  AND NOT EXISTS (SELECT 1 FROM "Parcela" p WHERE p.cepa = c.id);

-- 2. Cepa demostrativa sin usos (dentro de la transacción) para que el
--    DELETE tenga filas reales que eliminar.
INSERT INTO "Cepa" (nombre, tipo)
VALUES ('Cepa Demo Sin Uso', 'tinta');

-- 3. Pre-verificación: ahora existe exactamente 1 cepa sin uso.
SELECT c.id, c.nombre, c.tipo
FROM "Cepa" c
WHERE NOT EXISTS (SELECT 1 FROM "Composicion" co WHERE co.cepa = c.id)
  AND NOT EXISTS (SELECT 1 FROM "Parcela" p WHERE p.cepa = c.id);

-- 4. Eliminación dentro de la transacción: solo cepas SIN composición
--    y SIN parcela.
DELETE FROM "Cepa" c
WHERE NOT EXISTS (SELECT 1 FROM "Composicion" co WHERE co.cepa = c.id)
  AND NOT EXISTS (SELECT 1 FROM "Parcela" p WHERE p.cepa = c.id);

-- 5. Post-verificación: no queda ninguna cepa sin uso.
SELECT COUNT(*) AS cepas_sin_uso_restantes
FROM "Cepa" c
WHERE NOT EXISTS (SELECT 1 FROM "Composicion" co WHERE co.cepa = c.id)
  AND NOT EXISTS (SELECT 1 FROM "Parcela" p WHERE p.cepa = c.id);

-- 6. Prueba de dependencias FK: borrar una cepa EN USO debe ser
--    rechazado. Malbec (id 1) participa en 15 composiciones y está
--    plantada en 8 parcelas. La excepción se captura para mostrar el
--    rechazo sin abortar el script; si la base lo ACEPTARA, el script falla.
--    Nota: en PostgreSQL 18 el rechazo de un ON DELETE RESTRICT llega con
--    SQLSTATE 23001 (restrict_violation); se capturan ambos códigos por
--    compatibilidad (23001 y 23503 foreign_key_violation).
DO $$
BEGIN
    BEGIN
        DELETE FROM "Cepa" WHERE id = 1;
        RAISE EXCEPTION
            'PRUEBA FALLIDA: la base acepto borrar una cepa en uso (Malbec)';
    EXCEPTION
        WHEN restrict_violation OR foreign_key_violation THEN
            RAISE NOTICE 'OK: cepa en uso rechazada (%)', SQLERRM;
    END;
END $$;

-- 7. Verificación final: el catálogo queda intacto (las 12 cepas del
--    Anexo B, sin datos demostrativos).
SELECT COUNT(*) AS cepas_totales FROM "Cepa";

-- Confirmar transacción
COMMIT;
-- ROLLBACK;

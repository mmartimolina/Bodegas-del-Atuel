-- Issue B-19 / I5: Insertar una nueva sala de venta
-- Consigna (sección 8.2, I5): crear una nueva sala de venta ubicada en una
-- localidad existente (cumpliendo la FK) y verificar su incorporación.
--
-- Valores determinados elegidos del dataset cargado (db/seed):
--   * Localidad existente: San Rafael (Mendoza, CP 5600) — catálogo Anexo B.3
--   * Sala              : Avenida Mitre 1500, día de cierre Lunes
--
-- Criterios de la issue #77:
--   1. Se elige una localidad EXISTENTE (no un LIMIT 1 cualquiera).
--   2. Se inserta la sala cumpliendo la FK y se verifica el registro.
--   3. Se verifica el día de cierre (día de semana válido).
--   4. Se PRUEBA el rechazo de la FK: una sala con localidad inexistente
--      debe ser rechazada por la base (foreign key violation).
-- La prueba de rechazo se ejecuta en un bloque DO con captura de excepción:
-- muestra el rechazo real sin abortar el script, y falla ruidosamente si la
-- base aceptara un dato inválido.

BEGIN;

-- 1. Pre-verificación: mostrar la localidad existente elegida para la sala.
SELECT id_localidad, nombre, codigo_postal, provincia
FROM "Localidad"
WHERE nombre = 'San Rafael';

-- 2. Insertar la sala vinculada a la localidad existente (FK #1).
--    INSERT ... SELECT con NOT EXISTS: el script es idempotente y no
--    duplica la sala si se re-ejecuta (id_sala es surrogate, no hay
--    clave natural con ON CONFLICT).
INSERT INTO "Sala" (calle, numero, dia_cierre, localidad)
SELECT 'Avenida Mitre', 1500, 'Lunes', l.id_localidad
FROM "Localidad" l
WHERE l.nombre = 'San Rafael'
  AND NOT EXISTS (
      SELECT 1
      FROM "Sala" s
      WHERE s.calle = 'Avenida Mitre'
        AND s.numero = 1500
        AND s.dia_cierre = 'Lunes'
        AND s.localidad = l.id_localidad
  );

-- 3. Verificación del registro incorporado: la sala quedó asociada a la
--    localidad válida y su día de cierre es un día de semana correcto.
SELECT s.id_sala, s.calle, s.numero, s.dia_cierre,
       l.nombre AS localidad, l.provincia,
       CASE WHEN s.dia_cierre IN ('Lunes', 'Martes', 'Miercoles', 'Jueves',
                                 'Viernes', 'Sabado', 'Domingo')
            THEN 'valido' ELSE 'INVALIDO' END AS dia_cierre_ok
FROM "Sala" s
JOIN "Localidad" l ON l.id_localidad = s.localidad
WHERE s.calle = 'Avenida Mitre'
  AND s.numero = 1500
  AND l.nombre = 'San Rafael';

-- 4. Prueba de rechazo de la FK: una sala con localidad inexistente debe ser
--    rechazada por la FK sala -> localidad. Se captura la excepción para
--    mostrar el rechazo sin abortar el script; si la base lo ACEPTARA,
--    el script falla.
DO $$
BEGIN
    BEGIN
        INSERT INTO "Sala" (calle, numero, dia_cierre, localidad)
        VALUES ('Calle Inexistente', 999, 'Martes', 999999);
        RAISE EXCEPTION
            'PRUEBA FALLIDA: la base acepto una sala con localidad inexistente (999999)';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: localidad inexistente rechazada (%)', SQLERRM;
    END;
END $$;

-- 5. Verificación final: la prueba de rechazo no dejó filas basura
--    (exactamente una sala en Avenida Mitre 1500 de San Rafael).
SELECT COUNT(*) AS salas_mitre_1500_san_rafael
FROM "Sala" s
JOIN "Localidad" l ON l.id_localidad = s.localidad
WHERE s.calle = 'Avenida Mitre'
  AND s.numero = 1500
  AND l.nombre = 'San Rafael';

-- Confirmar transacción
COMMIT;
-- ROLLBACK;

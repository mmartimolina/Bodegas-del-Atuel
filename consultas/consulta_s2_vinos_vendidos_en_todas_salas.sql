-- Issue B-28 / S2: Listar códigos y nombres de los vinos que se vendieron
-- en todas las salas (división relacional).
--
-- División relacional: vinos ÷ salas. Un vino aparece si NO EXISTE una
-- sala en la que ese vino NO se haya vendido (doble negación clásica).
-- "Vendido en una sala" = existe un renglón de un comprobante de esa
-- sala con ese vino.
--
-- DECISIÓN documentada sobre el alcance de "todas las salas":
--   * La tabla Sala tiene 25 salas registradas: las 24 de la carga masiva
--     y la sala 25 (Avenida Mitre 1500, San Rafael), incorporada por
--     consultas/insertar_sala.sql (issue B-19 / I5) que aún no registró
--     ninguna venta.
--   * La división ESTRICTA (paso 2) se formula sobre TODAS las salas
--     registradas: como la sala 25 no vendió nada, ningún vino puede
--     cumplir "vendido en todas" y el resultado es 0 filas (correcto y
--     consistente con el criterio de la issue: solo aparecen vinos
--     vendidos en cada sala existente).
--   * El paso 3 repite la MISMA división sobre la red activa (salas con
--     ventas registradas), que es la interpretación operativa del
--     informe: sobre el dataset actual devuelve V0011 (Semillon clasico),
--     vendido en las 24 salas activas.

-- 1. Contexto: salas registradas y salas sin ninguna venta.
SELECT COUNT(*) AS salas_registradas FROM "Sala";

SELECT s.id_sala, s.calle, s.numero
FROM "Sala" s
WHERE NOT EXISTS (SELECT 1 FROM "Comprobante" c WHERE c.sala = s.id_sala);

-- 2. CONSULTA PRINCIPAL (división estricta): vinos vendidos en TODAS
--    las salas registradas de la tabla Sala.
SELECT v.codigo,
       v.nombre
FROM "Vino" v
WHERE NOT EXISTS (
    SELECT 1
    FROM "Sala" s
    WHERE NOT EXISTS (
        SELECT 1
        FROM "Renglon_Comprobante" rc
        JOIN "Comprobante" c ON c.numero = rc.comprobante
        WHERE rc.vino = v.codigo
          AND c.sala = s.id_sala
    )
)
ORDER BY v.codigo;

-- 3. Misma división sobre la red activa (salas con ventas registradas).
SELECT v.codigo,
       v.nombre
FROM "Vino" v
WHERE NOT EXISTS (
    SELECT 1
    FROM "Sala" s
    WHERE EXISTS (SELECT 1 FROM "Comprobante" c2 WHERE c2.sala = s.id_sala)
      AND NOT EXISTS (
          SELECT 1
          FROM "Renglon_Comprobante" rc
          JOIN "Comprobante" c ON c.numero = rc.comprobante
          WHERE rc.vino = v.codigo
            AND c.sala = s.id_sala
      )
)
ORDER BY v.codigo;

-- 4. Pruebas pedidas por la issue (vendido en todas / algunas / ninguna):
--    distribución de vinos según la cantidad de salas en que se vendieron.
--    "Todas" = bucket de 24 salas (V0011); "algunas" = buckets intermedios;
--    "ninguna" = la consulta del paso 5 (0 vinos sobre este dataset).
SELECT t.salas_alcanzadas,
       COUNT(*) AS vinos
FROM (
    SELECT rc.vino,
           COUNT(DISTINCT c.sala) AS salas_alcanzadas
    FROM "Renglon_Comprobante" rc
    JOIN "Comprobante" c ON c.numero = rc.comprobante
    GROUP BY rc.vino
) t
GROUP BY t.salas_alcanzadas
ORDER BY t.salas_alcanzadas DESC;

-- 5. Prueba "ninguna sala": vinos sin ningún renglón de venta en la red.
SELECT COUNT(*) AS vinos_sin_ventas_en_ninguna_sala
FROM "Vino" v
WHERE NOT EXISTS (SELECT 1 FROM "Renglon_Comprobante" rc WHERE rc.vino = v.codigo);

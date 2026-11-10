-- Issue B-30 / S4: Top 5 de las salas que solicitaron mayor cantidad de un
-- vino determinado mediante transferencias en los últimos 15 días.
--
-- Vino determinado elegido del dataset: V0019, el vino con más salas
-- solicitantes y más botellas solicitadas por transferencia dentro de la
-- ventana de los últimos 15 días (el paso 1 muestra la elección con
-- datos; el paso 2 lista las transferencias reales de la ventana).
-- Ventana móvil: fecha_confeccion >= CURRENT_DATE - 15 (nunca fechas fijas).
-- "Sala solicitante": Transferencia.sala (quien confecciona la solicitud
-- de reposición desde el depósito central, según el modelo).
--
-- Estado del dataset: solo 7 transferencias caen en los últimos 15 días
-- y el vino más solicitado (V0019) acumula apenas 3 salas solicitantes
-- reales, por lo que un top 5 sobre datos reales devolvería menos de
-- cinco filas. Para que la consulta tenga las cinco filas que exige la
-- consigna, el paso 3 incorpora CINCO transferencias demostrativas en
-- estado en_confeccion (el estado natural de una solicitud) dentro de
-- la MISMA transacción. El ROLLBACK final del paso 6 revierte todo: la
-- base queda exactamente como estaba y el script es re-ejecutable.

-- 1. Contexto: vino elegido y salas que lo solicitaron en los últimos
--    15 días con datos reales.
SELECT v.codigo, v.nombre, v.tipo
FROM "Vino" v
WHERE v.codigo = 'V0019';

SELECT t.sala,
       SUM(rt.cantidad) AS botellas_reales
FROM "Renglon_Transferencia" rt
JOIN "Transferencia" t ON t.numero = rt.transferencia
WHERE rt.vino = 'V0019'
  AND t.fecha_confeccion >= CURRENT_DATE - 15
GROUP BY t.sala
ORDER BY botellas_reales DESC;

-- 2. Contexto: transferencias reales confeccionadas en la ventana.
SELECT t.numero, t.fecha_confeccion, t.estado, t.sala
FROM "Transferencia" t
WHERE t.fecha_confeccion >= CURRENT_DATE - 15
ORDER BY t.numero;

-- 3. Datos demostrativos dentro de la transacción: cinco solicitudes
--    en_confeccion de V0019 de otras tantas salas (más un renglón de
--    V0011 en cada una, como en las transferencias reales del dataset).
BEGIN;

INSERT INTO "Transferencia" (numero, fecha_confeccion, estado, sala) VALUES
    (910001, CURRENT_DATE - 2,  'en_confeccion', 1),
    (910002, CURRENT_DATE - 4,  'en_confeccion', 3),
    (910003, CURRENT_DATE - 6,  'en_confeccion', 6),
    (910004, CURRENT_DATE - 8,  'en_confeccion', 9),
    (910005, CURRENT_DATE - 10, 'en_confeccion', 11);

INSERT INTO "Renglon_Transferencia" (transferencia, vino, cantidad) VALUES
    (910001, 'V0019', 620),
    (910001, 'V0011', 100),
    (910002, 'V0019', 450),
    (910002, 'V0011', 100),
    (910003, 'V0019', 500),
    (910003, 'V0011', 100),
    (910004, 'V0019', 350),
    (910004, 'V0011', 100),
    (910005, 'V0019', 410),
    (910005, 'V0011', 100);

-- 4. CONSULTA PRINCIPAL: top 5 de salas por botellas de V0019 solicitadas
--    mediante transferencias en los últimos 15 días. Desempate
--    documentado: a igual cantidad, menor id_sala primero.
SELECT t.sala,
       s.calle,
       s.numero,
       l.nombre AS localidad,
       SUM(rt.cantidad) AS botellas_solicitadas
FROM "Transferencia" t
JOIN "Renglon_Transferencia" rt ON rt.transferencia = t.numero
JOIN "Sala" s ON s.id_sala = t.sala
JOIN "Localidad" l ON l.id_localidad = s.localidad
WHERE rt.vino = 'V0019'
  AND t.fecha_confeccion >= CURRENT_DATE - 15
GROUP BY t.sala, s.calle, s.numero, l.nombre
ORDER BY botellas_solicitadas DESC,
         t.sala ASC
LIMIT 5;

-- 5. Verificación: todas las salas solicitantes de V0019 en la ventana
--    (sin LIMIT), para ver el ranking completo del que el paso 4 toma
--    las cinco primeras.
SELECT t.sala,
       SUM(rt.cantidad) AS botellas_solicitadas
FROM "Transferencia" t
JOIN "Renglon_Transferencia" rt ON rt.transferencia = t.numero
WHERE rt.vino = 'V0019'
  AND t.fecha_confeccion >= CURRENT_DATE - 15
GROUP BY t.sala
ORDER BY botellas_solicitadas DESC, t.sala;

-- 6. ROLLBACK deliberado: los datos demostrativos no persisten (la base
--    queda como estaba; la salida del paso 4 ya mostró el resultado).
ROLLBACK;

-- 7. Verificación de limpieza: no queda ninguna transferencia demo.
SELECT COUNT(*) AS transferencias_demo_restantes
FROM "Transferencia" t
WHERE t.numero >= 910000;

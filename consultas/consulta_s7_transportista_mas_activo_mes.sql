-- Issue B-33 / S7: ¿Cuál es la empresa de transporte con mayor actividad
-- en el último mes?
--
-- Actividad DEFINIDA según los movimientos que transporta: cantidad de
-- ingresos (envíos de bodegas al depósito central) confeccionados en el
-- período. El Ingreso es el documento que asigna el transportista.
-- Ventana móvil: fecha >= CURRENT_DATE - 30 (nunca fechas fijas).
-- Desempate EXPLÍCITO y documentado:
--   1) más ingresos confeccionados en el período;
--   2) a igual cantidad de ingresos, más botellas trasladadas (suma de
--      las cantidades de los renglones de esos ingresos);
--   3) a persistir el empate, menor código de transportista (alfabético).
--
-- Estado del dataset: los ingresos del dataset terminan el 2025-12-20,
-- por lo que en el último mes real hay 0 ingresos (lo muestran los
-- pasos 1 y 2). Para responder la pregunta con datos, el paso 3 incorpora
-- ingresos demostrativos dentro de la MISMA transacción, con un EMPATE
-- deliberado en cantidad de envíos entre TR013 y TR009 que se resuelve
-- por el desempate de botellas (el criterio documentado arriba). El
-- ROLLBACK final revierte todo: la base queda como estaba.

-- 1. Contexto: situación real del período móvil.
SELECT COUNT(*) AS ingresos_ultimo_mes,
       MAX(fecha) AS fecha_del_ultimo_ingreso_real
FROM "Ingreso"
WHERE fecha >= CURRENT_DATE - 30;

-- 2. Contexto: transportistas disponibles.
SELECT codigo, razon_social
FROM "Transportista"
ORDER BY codigo
LIMIT 5;

-- 3. Datos demostrativos dentro de la transacción: diez ingresos del
--    último mes repartidos entre tres transportistas (TR013: 4 envíos
--    con 210 botellas, TR009: 4 envíos con 50 botellas, TR001: 2 envíos
--    aún sin renglones). El empate 4-4 se resuelve por botellas: gana
--    TR013.
BEGIN;

INSERT INTO "Ingreso" (codigo, fecha, estado, transportista, bodega_origen) VALUES
    ('DEMO-S7-001', CURRENT_DATE - 3,  'en_confeccion', 'TR013', '30237566698'),
    ('DEMO-S7-002', CURRENT_DATE - 5,  'en_confeccion', 'TR013', '30237566698'),
    ('DEMO-S7-003', CURRENT_DATE - 8,  'en_confeccion', 'TR013', '30702918179'),
    ('DEMO-S7-004', CURRENT_DATE - 11, 'en_confeccion', 'TR013', '30702918179'),
    ('DEMO-S7-005', CURRENT_DATE - 4,  'en_confeccion', 'TR009', '30237566698'),
    ('DEMO-S7-006', CURRENT_DATE - 7,  'en_confeccion', 'TR009', '30702918179'),
    ('DEMO-S7-007', CURRENT_DATE - 9,  'en_confeccion', 'TR009', '30237566698'),
    ('DEMO-S7-008', CURRENT_DATE - 12, 'en_confeccion', 'TR009', '30702918179'),
    ('DEMO-S7-009', CURRENT_DATE - 6,  'en_confeccion', 'TR001', '30237566698'),
    ('DEMO-S7-010', CURRENT_DATE - 13, 'en_confeccion', 'TR001', '30702918179');

INSERT INTO "Renglon_Ingreso" (ingreso, vino, cantidad) VALUES
    ('DEMO-S7-001', 'V0011', 120),
    ('DEMO-S7-002', 'V0074', 90),
    ('DEMO-S7-006', 'V0060', 50);

-- 4. CONSULTA PRINCIPAL: ranking de actividad del último mes por
--    transportista (el ORDER BY documenta el desempate completo).
SELECT tr.codigo,
       tr.razon_social,
       COUNT(DISTINCT i.codigo) AS ingresos_confeccionados,
       COALESCE(SUM(ri.cantidad), 0) AS botellas_trasladadas
FROM "Transportista" tr
LEFT JOIN "Ingreso" i ON i.transportista = tr.codigo
                     AND i.fecha >= CURRENT_DATE - 30
LEFT JOIN "Renglon_Ingreso" ri ON ri.ingreso = i.codigo
GROUP BY tr.codigo, tr.razon_social
HAVING COUNT(DISTINCT i.codigo) > 0
ORDER BY ingresos_confeccionados DESC,
         botellas_trasladadas DESC,
         tr.codigo ASC;

-- 5. Respuesta directa a la pregunta: la empresa con mayor actividad
--    del último mes (misma consulta, primera fila).
SELECT tr.codigo,
       tr.razon_social,
       COUNT(DISTINCT i.codigo) AS ingresos_confeccionados,
       COALESCE(SUM(ri.cantidad), 0) AS botellas_trasladadas
FROM "Transportista" tr
LEFT JOIN "Ingreso" i ON i.transportista = tr.codigo
                     AND i.fecha >= CURRENT_DATE - 30
LEFT JOIN "Renglon_Ingreso" ri ON ri.ingreso = i.codigo
GROUP BY tr.codigo, tr.razon_social
HAVING COUNT(DISTINCT i.codigo) > 0
ORDER BY ingresos_confeccionados DESC,
         botellas_trasladadas DESC,
         tr.codigo ASC
LIMIT 1;

-- 6. ROLLBACK deliberado: los datos demostrativos no persisten (la base
--    queda como estaba; los pasos 4 y 5 ya mostraron el resultado).
ROLLBACK;

-- 7. Verificación de limpieza: no queda ningún ingreso demo.
SELECT COUNT(*) AS ingresos_demo_restantes
FROM "Ingreso"
WHERE codigo LIKE 'DEMO-S7-%';

-- Issue B-31 / S5: Listado de las salas con menor cantidad de
-- transferencias pendientes (no procesadas).
--
-- "Pendiente" según el enunciado: transferencia NO procesada, es decir
-- estado <> 'procesado' (los estados del ENUM estado_documento son
-- en_confeccion, terminado y procesado; los dos primeros son pendientes
-- de procesamiento). Sobre el dataset: 87 en_confeccion + 95 terminado
-- = 182 pendientes de 900 transferencias.
-- Se incluyen TODAS las salas registradas (LEFT JOIN): una sala sin
-- transferencias pendientes tiene 0, que es el mínimo posible, y debe
-- encabezar el listado (la sala 25, creada por insertar_sala.sql, no
-- tiene ninguna).
-- Desempate documentado: a igual cantidad de pendientes, menor id_sala
-- primero (orden determinístico que hace visibles los empates).
-- Nota: existe la vista v_documentos_pendientes (ingresos + transferencias
-- sin procesar); esta consulta filtra solo transferencias como pide la
-- consigna, así que se consulta la tabla directamente.

-- 1. Contexto: distribución de transferencias por estado.
SELECT estado,
       COUNT(*) AS transferencias
FROM "Transferencia"
GROUP BY estado
ORDER BY estado;

-- 2. CONSULTA PRINCIPAL: salas ordenadas por cantidad de transferencias
--    pendientes (ascendente: las de menor cantidad primero).
SELECT s.id_sala,
       s.calle,
       s.numero,
       l.nombre AS localidad,
       COUNT(t.numero) FILTER (WHERE t.estado <> 'procesado') AS transferencias_pendientes
FROM "Sala" s
LEFT JOIN "Transferencia" t ON t.sala = s.id_sala
LEFT JOIN "Localidad" l ON l.id_localidad = s.localidad
GROUP BY s.id_sala, s.calle, s.numero, l.nombre
ORDER BY transferencias_pendientes ASC,
         s.id_sala ASC;

-- 3. Verificación: el total de pendientes del listado debe igualar las
--    transferencias no procesadas de toda la base.
SELECT COUNT(*) AS pendientes_totales
FROM "Transferencia"
WHERE estado <> 'procesado';

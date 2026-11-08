-- rn39_vistas.ok.sql
-- Issue #39: las tres vistas existen y devuelven datos coherentes:
--   v_stock_total_vino, v_ventas_mensuales_sala, v_documentos_pendientes.

BEGIN;

INSERT INTO "Localidad"(id_localidad, nombre)
OVERRIDING SYSTEM VALUE VALUES (304401, 'Localidad RN-39');

INSERT INTO "Sala"(id_sala, localidad)
OVERRIDING SYSTEM VALUE VALUES (304401, 304401);

INSERT INTO "Bodega"(cuit, razon_social)
VALUES ('30777777841', 'Bodega RN-39');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (304401, 'Cepa RN-39', 'tinta');

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE VALUES (304401, 'Cliente RN-39');

INSERT INTO "Socio"(id_cliente) VALUES (304401);

INSERT INTO "Transportista"(codigo, razon_social)
VALUES ('TR-39', 'Transportista RN-39');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, bodega, precio)
VALUES ('B-39-V1', 'Vino vista', 'tinto', 2019, '30777777841', 100.00);

INSERT INTO "Composicion"(vino, cepa, porcentaje)
VALUES ('B-39-V1', 304401, 100.00);

-- Deposito 20 + sala 30 = 50.
INSERT INTO "Stock_Deposito"(vino, cantidad)
VALUES ('B-39-V1', 20);

INSERT INTO "Stock_Sala"(sala, vino, cantidad)
VALUES (304401, 'B-39-V1', 30);

-- venta de 4 en la sala.
INSERT INTO "Comprobante"(numero, fecha, cliente, sala)
VALUES (304401, DATE '2026-05-10', 304401, 304401);

INSERT INTO "Renglon_Comprobante"(comprobante, vino, cantidad, precio_unitario)
VALUES (304401, 'B-39-V1', 4, 100.00);

-- Dos ingresos pendientes (uno terminado, otro en confeccion): los renglones
-- se cargan durante la confeccion (RN-12) y recien despues se marca terminado.
INSERT INTO "Ingreso"(codigo, fecha, transportista, bodega_origen)
VALUES
    ('ING-39-1', CURRENT_DATE,     'TR-39', '30777777841'),
    ('ING-39-2', DATE '2026-05-01', 'TR-39', '30777777841');

INSERT INTO "Renglon_Ingreso"(ingreso, vino, cantidad)
VALUES ('ING-39-1', 'B-39-V1', 2), ('ING-39-2', 'B-39-V1', 5);

UPDATE "Ingreso" SET estado = 'terminado' WHERE codigo = 'ING-39-1';

-- v_stock_total_vino: deposito 20 + salas 30, menos las 4 vendidas = 26.
DO $$
DECLARE
    v_dep BIGINT;
    v_sal BIGINT;
BEGIN
    SELECT stock_deposito, stock_salas
      INTO v_dep, v_sal
      FROM v_stock_total_vino
     WHERE vino = 'B-39-V1';

    IF v_dep <> 20 OR v_sal <> 26 THEN
        RAISE EXCEPTION 'RN-39 FALLO: v_stock_total_vino = %/% (esperado 20/26)', v_dep, v_sal;
    END IF;

    RAISE NOTICE 'OK RN-39: v_stock_total_vino muestra deposito (20) y salas (26, netos de la venta)';
END;
$$;

-- v_ventas_mensuales_sala: anio-mes '2026-05', 4 unidades; el importe neto
-- aplica el descuento de Socio (10 %, RN-06/RN-08): 4 x 100 x 0.9 = 360.00.
-- v_ventas_mensuales_sala: anio-mes '2026-05', 4 unidades; el importe neto
-- aplica el descuento de Socio (10 %, RN-06/RN-08): 4 x 100 x 0.9 = 360.00.
DO $$
DECLARE
    r RECORD;
BEGIN
    SELECT * INTO r
      FROM v_ventas_mensuales_sala
     WHERE sala = 304401 AND anio_mes = '2026-05';

    IF r IS NULL OR r.unidades_vendidas <> 4 OR r.importe_neto <> 360.00 THEN
        RAISE EXCEPTION 'RN-39 FALLO: v_ventas_mensuales_sala inconsistente (%, %)',
            r.unidades_vendidas, r.importe_neto;
    END IF;

    RAISE NOTICE 'OK RN-39: v_ventas_mensuales_sala agrega mes/sala (4 unidades, 360.00 netos)';
END;
$$;

-- v_documentos_pendientes: los dos ingresos no procesados aparecen.
DO $$
DECLARE
    v_pendientes INTEGER;
BEGIN
    SELECT count(*) INTO v_pendientes
      FROM v_documentos_pendientes
     WHERE tipo = 'INGRESO' AND documento IN ('ING-39-1', 'ING-39-2');

    IF v_pendientes <> 2 THEN
        RAISE EXCEPTION 'RN-39 FALLO: v_documentos_pendientes no incluye ambos ingresos (%)', v_pendientes;
    END IF;

    RAISE NOTICE 'OK RN-39: v_documentos_pendientes expone ambos ingresos sin procesar';
END;
$$;

-- Al procesar un ingreso, sale de la vista.
CALL sp_procesar_ingreso('ING-39-1');

DO $$
DECLARE
    v_pendientes INTEGER;
BEGIN
    SELECT count(*) INTO v_pendientes
      FROM v_documentos_pendientes
     WHERE tipo = 'INGRESO' AND documento = 'ING-39-1';

    IF v_pendientes <> 0 THEN
        RAISE EXCEPTION 'RN-39 FALLO: el ingreso procesado sigue en pendientes';
    END IF;

    RAISE NOTICE 'OK RN-39: procesado sale de v_documentos_pendientes';
END;
$$;

COMMIT;

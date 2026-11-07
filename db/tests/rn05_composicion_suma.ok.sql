-- rn05_composicion_suma.ok.sql
-- A21 (issue #25): RN-05 — suma 100 al COMMIT (constraint trigger diferido).
-- Este archivo DEBE terminar sin errores: demuestra que la transaccion acepta estados
-- intermedios con suma distinta de 100 y que el COMMIT valida el estado final.
BEGIN;

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

INSERT INTO "Cepa"(id, nombre, tipo)
OVERRIDING SYSTEM VALUE VALUES (1, 'Malbec', 'tinta'), (2, 'Syrah', 'tinta');

INSERT INTO "Vino"(codigo, nombre, tipo, anada, volumen_ml, graduacion, precio, bodega)
VALUES ('VINO1', 'Corte Reserva', 'tinto', 2023, 750, 14.0, 234.50, '30712345678');

-- estado intermedio: 60 (suma provisional distinta de 100) debe ser aceptado DENTRO de la txn
INSERT INTO "Composicion"(vino, cepa, porcentaje)
OVERRIDING SYSTEM VALUE VALUES ('VINO1', 1, 60.00);

DO $t$ BEGIN
    IF (SELECT COALESCE(SUM(porcentaje),0) FROM "Composicion" WHERE vino='VINO1') <> 100 THEN
        RAISE NOTICE 'OK RN-05 (deferido): estado intermedio 60 aceptado antes del COMMIT';
    END IF;
END $t$;

-- correccion en la misma transaccion: completa a 100
INSERT INTO "Composicion"(vino, cepa, porcentaje)
OVERRIDING SYSTEM VALUE VALUES ('VINO1', 2, 40.00);

UPDATE "Composicion" SET porcentaje = 65.00 WHERE vino = 'VINO1' AND cepa = 1;
UPDATE "Composicion" SET porcentaje = 35.00 WHERE vino = 'VINO1' AND cepa = 2;

-- transicion por reingreso: borrar y volver a crear con otra suma parcial
DELETE FROM "Composicion" WHERE vino = 'VINO1' AND cepa = 2;
INSERT INTO "Composicion"(vino, cepa, porcentaje)
OVERRIDING SYSTEM VALUE VALUES ('VINO1', 2, 35.00);

COMMIT;

-- RN-05: un vino no puede confirmarse sin composicion.
-- El constraint trigger diferido debe rechazar el COMMIT.

BEGIN;

INSERT INTO "Bodega"(cuit, razon_social, domicilio)
VALUES ('30712345678', 'Bodega Atuel SA', 'Calle 1');

INSERT INTO "Vino"(
    codigo, nombre, tipo, anada, volumen_ml,
    graduacion, precio, bodega
)
VALUES (
    'VINO_SIN_CEPA', 'Vino sin composicion', 'tinto',
    2023, 750, 14.0, 234.50, '30712345678'
);

-- No se inserta ninguna fila en Composicion.
-- El COMMIT debe fallar por RN-05.
COMMIT;

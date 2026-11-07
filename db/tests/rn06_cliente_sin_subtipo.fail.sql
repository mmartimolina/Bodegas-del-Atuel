-- RN-06: no se puede confirmar un Cliente sin exactamente un subtipo.
-- El constraint trigger diferido debe rechazar el COMMIT.

BEGIN;

INSERT INTO "Cliente"(id_cliente, nombre)
OVERRIDING SYSTEM VALUE
VALUES (952001, 'Cliente sin subtipo');

COMMIT;

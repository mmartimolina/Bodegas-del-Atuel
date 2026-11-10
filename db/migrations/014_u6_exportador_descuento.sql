-- U6: sincroniza el descuento derivado de Exportador.descuento cuando cambian
-- sus permisos. Más de tres permisos corresponden a un descuento del 35 %.

BEGIN;

CREATE OR REPLACE FUNCTION fn_permiso_exportacion_sincronizar_descuento()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE "Cliente"
           SET descuento = fn_descuento_cliente(OLD.exportador)
         WHERE id_cliente = OLD.exportador;
        RETURN OLD;
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.exportador IS DISTINCT FROM NEW.exportador THEN
        UPDATE "Cliente"
           SET descuento = fn_descuento_cliente(OLD.exportador)
         WHERE id_cliente = OLD.exportador;
    END IF;

    UPDATE "Cliente"
       SET descuento = fn_descuento_cliente(NEW.exportador)
     WHERE id_cliente = NEW.exportador;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION fn_permiso_exportacion_sincronizar_descuento()
    FROM PUBLIC;
GRANT EXECUTE ON FUNCTION fn_permiso_exportacion_sincronizar_descuento()
    TO bodegas_admin, bodegas_api;

CREATE TRIGGER trg_permiso_exportacion_sincronizar_descuento
AFTER INSERT OR UPDATE OR DELETE ON "Permiso_Exportacion"
FOR EACH ROW
EXECUTE FUNCTION fn_permiso_exportacion_sincronizar_descuento();

COMMENT ON TRIGGER trg_permiso_exportacion_sincronizar_descuento
ON "Permiso_Exportacion" IS
    'U6: recalcula el descuento derivado del exportador al cambiar sus permisos.';

COMMIT;

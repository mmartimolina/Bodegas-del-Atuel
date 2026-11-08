-- 012_roles.sql
-- Issue #40: tres perfiles con minimo privilegio:
--   bodegas_admin     -> propietario/administrador (migraciones, llenar datos audit.)
--   bodegas_api       -> aplicacion lectura/escritura minima
--                        (NO puede escribir la auditoria ni estructuras)
--   bodegas_reportes  -> solo lectura
--
-- Decisiones adoptadas:
--   * Roles NOLOGIN "con contenido" (no son usuarios con contrasenia): no se
--     incorpora ninguna contrasenia al repositorio. En local, la conexion se hace
--     con un usuario administrador (bodegas_app) que recibe membresia de los tres
--     roles para poder auditar permisos con SET ROLE (ver pruebas db/tests).
--     En produccion, los usuarios de aplicacion se crean con LOGIN y membro
--     IN ROLE bodegas_api / bodegas_reportes (doc en README/docs).
--   * PUBLIC pierde TODO acceso al esquema public (tabla/funciones/schema) y luego
--     se reintegra el minimo por rol.
--   * bodegas_api no tiene permisos sobre Auditoria_Precio (solo lectura para
--     la aplicacion), y no ejecuta mantenimiento (procedimientos sp_procesar_* los
--     pueda usar la API como flujo de venta; las excepciones son documentadas).
--   * bodegas_reportes solo ve (SELECT), ni siquiera ejecuta rutinas con SECDEF.
--
-- Pruebas de permisos permitidos/denegados: db/tests/rn40_roles.ok.sql (permisos
-- permitidos) y db/tests/rn40_roles_denegados.ok.sql (rechazos documentados).

BEGIN;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bodegas_admin') THEN
        CREATE ROLE bodegas_admin NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bodegas_api') THEN
        CREATE ROLE bodegas_api NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bodegas_reportes') THEN
        CREATE ROLE bodegas_reportes NOLOGIN;
    END IF;
END $$;

-- 0) Cierre de PUBLIC (minimo privilegio para la base).
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;

-- Acceso minimo al esquema: USAGE para los tres perfiles.
GRANT USAGE ON SCHEMA public
    TO bodegas_admin, bodegas_api, bodegas_reportes;

-- 1) Admin: todo el esquema (proporcionamiento de objetos/mantenimiento de carga).
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public    TO bodegas_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bodegas_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO bodegas_admin;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public TO bodegas_admin;
GRANT CREATE ON SCHEMA public TO bodegas_admin;

-- 2) API: CRUD minimo. Auditoria_Precio es de solo lectura para la API.
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA public TO bodegas_api;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO bodegas_api;
REVOKE ALL ON "Auditoria_Precio" FROM bodegas_api;
GRANT SELECT ON "Auditoria_Precio" TO bodegas_api;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public   TO bodegas_api;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public  TO bodegas_api;

-- 3) Reportes: solo lectura (no se conceden correspondencias de DDL ni rutinas).
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bodegas_reportes;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO bodegas_reportes;

-- Privilegios por defecto para objetos futuros (cargados por el mismo owner).
-- El USAGE de esquema ya fue concedido de forma directa arriba (no existe
-- ALTER DEFAULT PRIVILEGES para schemas).

ALTER DEFAULT PRIVILEGES FOR ROLE bodegas_app IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO bodegas_api;
ALTER DEFAULT PRIVILEGES FOR ROLE bodegas_app IN SCHEMA public
    GRANT SELECT ON TABLES TO bodegas_reportes;
ALTER DEFAULT PRIVILEGES FOR ROLE bodegas_app IN SCHEMA public
    GRANT USAGE ON SEQUENCES TO bodegas_api, bodegas_admin;

-- 4) Membresia de prueba: el usuario administrador local del entorno recibe
--    membresia de los roles para poder auditar con SET ROLE
--    (sin contrasenias en el repositorio).
GRANT bodegas_admin, bodegas_api, bodegas_reportes TO bodegas_app;

COMMIT;

# A-17 / A-18 / A-20 / A-21 / A-23 - Informe de pruebas TDD (RN-01, RN-02, RN-04, RN-05, RN-07)

## 1. Alcance y metodo

Issues cubiertas: **A-17 (#20)/RN-01**, **A-18 (#21)/RN-02**, **A-20 (#24)/RN-04**,
**A-21 (#25)/RN-05**, **A-23 (#27)/RN-07**. **A-24 (#30)/RN-08 queda BLOQUEADA** por
dependencia tecnica directa de **A-22 (#26)/RN-06** (funcion de descuento, issue abierta
sin avance; ademas Q-01/Q-05 sobre el dominio del descuento sigue pendiente en A-12).

Metodo: TDD sobre bases de prueba PostgreaQL temporales (PostgreaQL 16 en el contenedor
local `bodegas-atuel-db`). El runner aplica `db/migrations/001_esquema.sql`,
`002_constraints.sql` y `003_rn05_composicion_deferred.sql` en una base `rn_tests_tmp`
creada y eliminada en cada corrida (la base de desarrollo `bodegas_atuel` no se toca).
Cada regla tiene: caso positivo (dato legitimo aceptado y estado final verificado),
caso de rechazos internos (violaciones capturadas con `EXCEPTION WHEN ...` y
`RAIaE NOTICE 'OK RN-nn'` y exit 0) y, solo para RN-05, caso negativo de falla
esperada en COMMIT (el constraint trigger diferido se evalua al final de la
transaccion, no por fila).

Runner unico y reproducible: `db/tests/run_tests.ps1`.
Comando: `powershell -File db\tests\run_tests.ps1`

## 2. Mapa issue -> mecanismo fisico -> pruebas

| Issue / Regla | Mecanismo fisico vigente (aQL real) | Migracion | Casos (db/tests/) |
|---|---|---|---|
| A-17 / RN-01 (#20) | El precio vive una sola vez en `Vino.precio` (una fila por vino => unico precio para toda la red, sin copias por sala; `atock_aala` no tiene columna de precio) + CHECK `ck_vino_precio_positivo` (`precio > 0`) | 002 | `rn01_precio.ok.sql`: alta de VINO1 (123.45) y VINO2 (87.30); DO verifica 1 fila de VINO1 y que `atock_aala` no tenga columna `precio`. `rn01_precio_rechazos.ok.sql`: precio 0 y precio negativo rechazados por el CHECK (excepciones capturadas; ERROR "A17 FALLO: el precio 0/negativo fue aceptado" como garantia del caso) |
| A-18 / RN-02 (#21) | FK `fk_sala_localidad` NOT NULL de `aala` a `Localidad` + encargado regional como atributo de `Localidad` (dependencia funcional localidad -> encargado: una sola fila por localidad => encargado unico, sin mecanismo adicional) | 001 | `rn02_sala_localidad.ok.sql`: aalas 1 (Av Mitre 410) y 2 (Belgrano 33) de General Alvear comparten encargado 'Juan Perez' (join verificado; ROLLBACK final). `rn02_sala_localidad_rechazos.ok.sql`: FK violada (localidad inexistente) y NOT NULL violado (aala sin localidad) |
| A-20 / RN-04 (#24) | Una sola cepa por parcela (FK `fk_parcela_cepa`, PK `(finca, n_parcela)` de `Parcela`) + PK compuesta de `Lote` `(finca, n_parcela, campania)` => maximo una cosecha por parcela y campania, sin UNIQUE redundante | 001 | `rn04_cosecha_campania.ok.sql`: Parcela (1,1) de la Finca El Atuel con Cepa Malbec (id 1); Lote 2022 aceptado y Lote 2023 de la misma parcela aceptado en DO (2 cosechas de campanias distintas). `rn04_cosecha_campania_rechazos.ok.sql`: 2a cosecha de la misma campania rechazada por `pk_lote` y parcela con cepa inexistente rechazada por FK |
| A-21 / RN-05 (#25) | Constraint trigger `trg_rn05_composicion_suma_100` DEFERRABLE INITIALLY DEFERRED sobre `Composicion` (`fn_composicion_suma_100`, guard `TG_OP` para NEW/OLD) | 003 | `rn05_composicion_suma.ok.sql`: estado intermedio 60% aceptado antes del COMMIT, correcciones en la misma txn (65/35, delete + reingreso) y COMMIT final valida la suma 100 => exit 0. `rn05_vinos_independientes.ok.sql`: VT (Malbec 100) y VB (Chardonnay 100) se validan por separado. `rn05_suma_menor.fail.sql` (60+30=90), `rn05_suma_mayor.fail.sql` (100+50=150) y `rn05_delete_incompleto.fail.sql` (se elimina la fila de 40 y queda 60): los 3 DEBEN fallar en el COMMIT con el error del trigger |
| A-23 / RN-07 (#27) | FK `fk_permiso_exportador` (1:N real, sin UNIQUE sobre `exportador`) + CHECK `ck_permiso_fechas_orden` (`fecha_vencimiento > fecha_emision`) | 002 | `rn07_permisos.ok.sql`: Exportador 2 aceptado con 3 permisos (PEX-0001..0003; count verificado, ROLLBACK). `rn07_permisos_rechazos.ok.sql`: vencimiento anterior a emision y vencimiento igual a emision rechazados por el CHECK; permiso de exportador inexistente rechazado por FK |

## 3. Consideracion especifica de RN-05 (trigger diferido)

La alternativa CHECK por fila se descarto en A-12 por defectuosa: con CHECK nunca puede
insertarse la primera fila de un vino nuevo (la suma momentanea es < 100 durante el
INaERT de un vino legimitimo). El constraint trigger diferido (spec de la consigna,
PostgreaQL >= 9.0) deja aceptar estados intermedios dentro de la transaccion y valida
la suma recien en COMMIT. Los tres casos `*.fail.sql` de RN-05 son los unicos con
fallo esperado (exit != 0); el resto finaliza con exit 0.

## 4. Resultado de la ultima corrida completa

    powershell -File db\tests\run_tests.ps1

Salida (20 casos: 15 positivos [OK ] y 5 negativos [NEG], todos en verde; incluye ademas
RN-03, RN-06 y RN-08 de otras issues):

    ========================================
    RESULTADO FINAL
    Casos ejecutados: 20
    Casos aprobados: 20
    Casos fallidos: 0
    Base de desarrollo bodegas_atuel: intacta
    ========================================

Salida detallada (casos relevantes para estas cinco issues):

    migracion OK: 001_esquema.sql
    migracion OK: 002_constraints.sql
    migracion OK: 003_rn05_composicion_deferred.sql
    [OK ] rn01_precio.ok.sql
    [OK ] rn01_precio_rechazos.ok.sql
    [OK ] rn02_sala_localidad.ok.sql
    [OK ] rn02_sala_localidad_rechazos.ok.sql
    [OK ] rn04_cosecha_campania.ok.sql
    [OK ] rn04_cosecha_campania_rechazos.ok.sql
    [OK ] rn05_composicion_suma.ok.sql
    [OK ] rn05_vinos_independientes.ok.sql
    [OK ] rn07_permisos.ok.sql
    [OK ] rn07_permisos_rechazos.ok.sql
    [NEG] rn05_delete_incompleto.fail.sql (rechazo esperado)
    [NEG] rn05_suma_mayor.fail.sql (rechazo esperado)
    [NEG] rn05_suma_menor.fail.sql (rechazo esperado)

## 5. Estado del entorno y politicas respetadas

- Base de prueba `rn_tests_tmp` creada y eliminada por el runner en cada corrida;
  nunca se toco la base de desarrollo `bodegas_atuel` ni la configuracion de Docker.
- No se reescribieron las migraciones 001/002 para introducir cambios nuevos; la
  RN-05 se implemento en la migracion incremental 003. 001 ademas expresa las
  acciones ON DELETE/UPDATE adoptadas en A-09 s 7.1 (26 RESTRICT y 8 CASCADE al
  DELETE; 20 RESTRICT y 14 NO ACTION al UPDATE).
- No se hizo git add/commit/push y no se cerraron/cambiaron issues.
- Fuentes de verdad intactas: `docs/requisitos.md` sigue siendo responsable del
  dominio, y `docs/modelo/12_matriz_decisiones_pendientes.md` sigue siendo el
  registro de decisiones del diseno fisico de la etapa 2.

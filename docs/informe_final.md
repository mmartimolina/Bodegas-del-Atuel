# Informe final — Bodegas del Atuel

> Plantilla de trabajo. Completar los campos entre corchetes con evidencia
> verificada; no presentar resultados pendientes como realizados.

## 1. Introducción

Este trabajo integrador desarrolla un sistema de gestión de información para
una bodega vitivinícola. El repositorio incluye el modelo relacional, reglas de
negocio implementadas en PostgreSQL, consultas y herramientas de operación.

**Integrantes:** [nombres y apellidos]  
**Asignatura / comisión:** [completar]  
**Fecha de entrega:** [completar]

## 2. Objetivos y alcance

### 2.1 Objetivo general

Diseñar y validar una solución de base de datos para gestionar información
vitivinícola, inventario por sala y depósito, ventas, transferencias, ingresos
y consultas de gestión.

### 2.2 Alcance funcional

- Mantener entidades de producción, vinos, clientes y logística.
- Registrar ventas con importes derivados y reglas de stock.
- Gestionar ingresos y transferencias mediante estados y procedimientos de
  PostgreSQL.
- Proveer consultas de selección y reportes del escenario.
- [Describir las pantallas y servicios implementados con evidencia.]

### 2.3 Fuera de alcance

- [Indicar exclusiones confirmadas por la consigna/equipo.]

## 3. Organización y responsabilidades

| Rol o área | Responsable | Actividades y entregables |
|---|---|---|
| Análisis y modelo de datos | [integrante] | [completar] |
| Reglas de negocio, migraciones y pruebas DB | [integrante] | [completar] |
| API y acceso a datos | [integrante] | [completar] |
| Frontend e integración | [integrante] | [completar] |
| Documentación, QA y despliegue | [integrante] | [completar] |

La asignación nominal debe acordarse por el equipo; los roles anteriores son
espacios de organización y no presuponen una distribución ya realizada.

## 4. Modelo y reglas de negocio

Describir el esquema, las decisiones de normalización y las reglas
implementadas. La matriz de trazabilidad RN-01..RN-15 se mantiene en
[`docs/auditorias/trazabilidad_RN01_RN15.md`](./auditorias/trazabilidad_RN01_RN15.md).

## 5. Arquitectura y despliegue

- Base de datos: PostgreSQL [versión].
- API: [tecnología y versión].
- Frontend: [tecnología y versión].
- Ejecución reproducible: [comandos y configuración sin secretos].
- Diagrama de arquitectura: [enlace/archivo].

## 6. Pruebas y resultados

| Suite / verificación | Comando | Resultado medido | Evidencia |
|---|---|---|---|
| Reglas de negocio DB | `.\db\tests\run_tests.ps1` | [ejecutar y completar] | [archivo/log] |
| API | [comando] | [ejecutar y completar] | [archivo/log] |
| Lint y tipos | [comando] | [ejecutar y completar] | [archivo/log] |
| Build e integración | [comando] | [ejecutar y completar] | [archivo/log] |

## 7. Rendimiento

Referenciar los planes, dataset temporal, métodos y resultados medidos en
[`docs/modelo/15_rendimiento_indices.md`](./modelo/15_rendimiento_indices.md).
Separar mediciones observadas de estimaciones.

## 8. Respaldo, restauración y seguridad

Referenciar el procedimiento reproducible en
[`docs/backup_restore.md`](./backup_restore.md). Documentar permisos, manejo de
variables, limitaciones y cualquier riesgo pendiente.

## 9. Conclusiones y trabajo pendiente

- Resultados comprobados: [completar con evidencia].
- Limitaciones: [completar].
- Trabajo pendiente: [completar].

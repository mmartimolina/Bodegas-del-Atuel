from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from psycopg import Connection

from app.database import get_connection
from app.repositories import commerce, customers, movements, reports, system, wines
from app.schemas import (
    CustomerInput,
    IncomeInput,
    IncomeLineInput,
    IncomeLinesInput,
    SaleInput,
    TransferInput,
    TransferLineInput,
    TransferLinesInput,
    WineInput,
)

router = APIRouter()


@router.get("/salud", tags=["salud"], summary="Verificar disponibilidad de PostgreSQL")
def health(connection: Connection = Depends(get_connection)) -> dict[str, bool | str]:
    system.check_database(connection)
    return {"estado": "ok", "base_de_datos": "disponible"}


@router.get("/vinos", tags=["vinos"], summary="Listar vinos con filtros y paginación")
def list_wines(
    limit: int = Query(default=20, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    tipo: str | None = None,
    cepa: int | None = Query(default=None, gt=0),
    bodega: str | None = None,
    anada: int | None = Query(default=None, ge=0, le=32767),
    connection: Connection = Depends(get_connection),
) -> dict:
    return wines.list_wines(
        connection,
        limit=limit,
        offset=offset,
        tipo=tipo,
        cepa=cepa,
        bodega=bodega,
        anada=anada,
    )


@router.get("/vinos/{codigo}", tags=["vinos"], summary="Consultar detalle de vino")
def get_wine(codigo: str, connection: Connection = Depends(get_connection)) -> dict:
    result = wines.get_wine(connection, codigo)
    if result is None:
        raise HTTPException(status_code=404, detail="El vino solicitado no existe.")
    return result


@router.post(
    "/vinos",
    tags=["vinos"],
    status_code=status.HTTP_201_CREATED,
    summary="Crear vino con composición y maridajes",
)
def create_wine(
    wine: WineInput, connection: Connection = Depends(get_connection)
) -> dict:
    return wines.create_wine(connection, wine)


@router.put("/vinos/{codigo}", tags=["vinos"], summary="Actualizar vino y composición")
def update_wine(
    codigo: str, wine: WineInput, connection: Connection = Depends(get_connection)
) -> dict:
    if wine.codigo != codigo:
        raise HTTPException(
            status_code=422,
            detail="El código del cuerpo debe coincidir con la ruta.",
        )
    result = wines.update_wine(connection, codigo, wine)
    if result is None:
        raise HTTPException(status_code=404, detail="El vino solicitado no existe.")
    return result


@router.delete(
    "/vinos/{codigo}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["vinos"],
    summary="Eliminar vino sin dependencias",
)
def delete_wine(
    codigo: str, connection: Connection = Depends(get_connection)
) -> Response:
    if not wines.delete_wine(connection, codigo):
        raise HTTPException(status_code=404, detail="El vino solicitado no existe.")
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/clientes", tags=["clientes"], summary="Listar clientes por subtipo")
def list_customers(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    subtipo: str | None = Query(
        default=None, pattern="^(Socio|Distribuidor|Exportador)$"
    ),
    q: str | None = Query(default=None, max_length=100),
    connection: Connection = Depends(get_connection),
) -> dict:
    return customers.list_customers(
        connection, limit=limit, offset=offset, subtipo=subtipo, query=q
    )


@router.get("/clientes/{customer_id}", tags=["clientes"], summary="Consultar cliente")
def get_customer(
    customer_id: int, connection: Connection = Depends(get_connection)
) -> dict:
    result = customers.get_customer(connection, customer_id)
    if result is None:
        raise HTTPException(status_code=404, detail="El cliente solicitado no existe.")
    return result


@router.post(
    "/clientes",
    tags=["clientes"],
    status_code=status.HTTP_201_CREATED,
    summary="Crear cliente y subtipo",
)
def create_customer(
    customer: CustomerInput, connection: Connection = Depends(get_connection)
) -> dict:
    return customers.create_customer(connection, customer)


@router.put("/clientes/{customer_id}", tags=["clientes"], summary="Actualizar cliente")
def update_customer(
    customer_id: int,
    customer: CustomerInput,
    connection: Connection = Depends(get_connection),
) -> dict:
    existing = customers.get_customer(connection, customer_id)
    if existing is None:
        raise HTTPException(status_code=404, detail="El cliente solicitado no existe.")
    if existing["subtipo"] != customer.subtipo:
        raise HTTPException(
            status_code=422,
            detail="No se permite cambiar el subtipo de un cliente existente.",
        )
    result = customers.update_customer(connection, customer_id, customer)
    if result is None:
        raise HTTPException(status_code=404, detail="El cliente solicitado no existe.")
    return result


@router.delete(
    "/clientes/{customer_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["clientes"],
    summary="Eliminar cliente sin comprobantes ni permisos protegidos",
)
def delete_customer(
    customer_id: int, connection: Connection = Depends(get_connection)
) -> Response:
    if not customers.delete_customer(connection, customer_id):
        raise HTTPException(status_code=404, detail="El cliente solicitado no existe.")
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/salas", tags=["salas"], summary="Listar salas de venta")
def list_salas(connection: Connection = Depends(get_connection)) -> list[dict]:
    return customers.list_salas(connection)


@router.get("/catalogos", tags=["catalogos"], summary="Listar datos auxiliares de formularios")
def list_catalogs(connection: Connection = Depends(get_connection)) -> dict:
    return customers.list_catalogs(connection)


@router.post(
    "/comprobantes",
    tags=["comprobantes"],
    status_code=status.HTTP_201_CREATED,
    summary="Crear comprobante de venta de forma atómica",
)
def create_comprobante(
    sale: SaleInput, connection: Connection = Depends(get_connection)
) -> dict:
    try:
        return commerce.create_comprobante(connection, sale)
    except LookupError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error


@router.get(
    "/comprobantes/{numero}",
    tags=["comprobantes"],
    summary="Consultar comprobante y renglones",
)
def get_comprobante(
    numero: int, connection: Connection = Depends(get_connection)
) -> dict:
    result = commerce.get_comprobante(connection, numero)
    if result is None:
        raise HTTPException(status_code=404, detail="El comprobante solicitado no existe.")
    return result


@router.post(
    "/transferencias",
    tags=["transferencias"],
    status_code=status.HTTP_201_CREATED,
    summary="Crear transferencia en confección",
)
def create_transfer(
    transfer: TransferInput, connection: Connection = Depends(get_connection)
) -> dict:
    return movements.create_transfer(connection, transfer)


@router.get(
    "/transferencias/{numero}",
    tags=["transferencias"],
    summary="Consultar transferencia y renglones",
)
def get_transfer(
    numero: int, connection: Connection = Depends(get_connection)
) -> dict:
    result = movements.get_transfer(connection, numero)
    if result is None:
        raise HTTPException(status_code=404, detail="La transferencia no existe.")
    return result


@router.post(
    "/transferencias/{numero}/renglones",
    tags=["transferencias"],
    summary="Agregar renglones a transferencia",
)
def add_transfer_lines(
    numero: int,
    body: TransferLinesInput,
    connection: Connection = Depends(get_connection),
) -> dict:
    result = movements.add_transfer_lines(connection, numero, body.renglones)
    if result is None:
        raise HTTPException(status_code=404, detail="La transferencia no existe.")
    return result


@router.post(
    "/transferencias/{numero}/terminar",
    tags=["transferencias"],
    summary="Cerrar confección de transferencia",
)
def finish_transfer(
    numero: int, connection: Connection = Depends(get_connection)
) -> dict:
    result = movements.change_transfer_state(connection, numero, "terminado")
    if result is None:
        raise HTTPException(status_code=404, detail="La transferencia no existe.")
    return result


@router.post(
    "/transferencias/{numero}/procesar",
    tags=["transferencias"],
    summary="Procesar transferencia mediante procedimiento PostgreSQL",
)
def process_transfer(
    numero: int, connection: Connection = Depends(get_connection)
) -> dict:
    result = movements.process_transfer(connection, numero)
    if result is None:
        raise HTTPException(status_code=404, detail="La transferencia no existe.")
    return result


@router.post(
    "/ingresos",
    tags=["ingresos"],
    status_code=status.HTTP_201_CREATED,
    summary="Crear ingreso en confección",
)
def create_income(
    income: IncomeInput, connection: Connection = Depends(get_connection)
) -> dict:
    return movements.create_income(connection, income)


@router.get("/ingresos/{codigo}", tags=["ingresos"], summary="Consultar ingreso")
def get_income(codigo: str, connection: Connection = Depends(get_connection)) -> dict:
    result = movements.get_income(connection, codigo)
    if result is None:
        raise HTTPException(status_code=404, detail="El ingreso no existe.")
    return result


@router.post(
    "/ingresos/{codigo}/renglones",
    tags=["ingresos"],
    summary="Agregar renglones a ingreso",
)
def add_income_lines(
    codigo: str,
    body: IncomeLinesInput,
    connection: Connection = Depends(get_connection),
) -> dict:
    result = movements.add_income_lines(connection, codigo, body.renglones)
    if result is None:
        raise HTTPException(status_code=404, detail="El ingreso no existe.")
    return result


@router.post("/ingresos/{codigo}/terminar", tags=["ingresos"], summary="Terminar ingreso")
def finish_income(codigo: str, connection: Connection = Depends(get_connection)) -> dict:
    result = movements.change_income_state(connection, codigo, "terminado")
    if result is None:
        raise HTTPException(status_code=404, detail="El ingreso no existe.")
    return result


@router.post(
    "/ingresos/{codigo}/procesar",
    tags=["ingresos"],
    summary="Procesar ingreso mediante procedimiento PostgreSQL",
)
def process_income(codigo: str, connection: Connection = Depends(get_connection)) -> dict:
    result = movements.process_income(connection, codigo)
    if result is None:
        raise HTTPException(status_code=404, detail="El ingreso no existe.")
    return result


@router.get(
    "/reportes/top-vinos",
    tags=["reportes"],
    summary="Ranking de vinos más vendidos",
)
def report_top_wines(
    limit: int = Query(default=10, ge=1, le=100),
    connection: Connection = Depends(get_connection),
) -> list[dict]:
    return reports.top_wines(connection, limit)


@router.get(
    "/reportes/ventas-por-sala",
    tags=["reportes"],
    summary="Ventas por sala del último trimestre",
)
def report_sales_by_sala(
    connection: Connection = Depends(get_connection),
) -> list[dict]:
    return reports.sales_by_sala(connection)


@router.get(
    "/reportes/vinos-sin-stock",
    tags=["reportes"],
    summary="Vinos sin stock en sala con existencia en depósito",
)
def report_wines_without_stock(
    sala: int = Query(gt=0),
    connection: Connection = Depends(get_connection),
) -> list[dict]:
    return reports.wines_without_sala_stock(connection, sala)


@router.get(
    "/reportes/transportista-activo",
    tags=["reportes"],
    summary="Actividad de transportistas del último mes",
)
def report_active_carriers(
    connection: Connection = Depends(get_connection),
) -> list[dict]:
    return reports.active_carriers(connection)


@router.get(
    "/reportes/trazabilidad/{codigo}",
    tags=["reportes"],
    summary="Consultar trazabilidad de vino por código",
)
def report_wine_traceability(
    codigo: str, connection: Connection = Depends(get_connection)
) -> dict:
    result = reports.wine_traceability(connection, codigo)
    if result is None:
        raise HTTPException(status_code=404, detail="El vino solicitado no existe.")
    return result

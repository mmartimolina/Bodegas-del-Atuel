import asyncio
from unittest.mock import Mock

from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from psycopg.errors import CheckViolation, RaiseException, SerializationFailure, UniqueViolation

from app.config import Settings
from app.database import get_connection
from app.main import create_app
from app.repositories import customers, wines


class FakeConnection:
    def __init__(self) -> None:
        self.statements: list[tuple[str, tuple[object, ...]]] = []

    def execute(self, query: str, params: tuple[object, ...] = ()) -> Mock:
        self.statements.append((query, params))
        result = Mock()
        result.fetchone.return_value = {"ok": 1}
        return result


def build_app() -> tuple[FastAPI, FakeConnection]:
    config = Settings(
        db_host="localhost",
        db_port=5432,
        db_name="test",
        db_user="test",
        db_password="test",
        db_role="bodegas_api",
        api_host="127.0.0.1",
        api_port=8000,
        cors_origins=(),
        pool_min_size=1,
        pool_max_size=1,
    )
    application = create_app(config)
    connection = FakeConnection()
    application.dependency_overrides[get_connection] = lambda: connection
    return application, connection


def request(
    application: FastAPI, method: str, path: str, **kwargs: object
):
    async def send():
        async with AsyncClient(
            transport=ASGITransport(app=application), base_url="http://test"
        ) as client:
            return await client.request(method, path, **kwargs)

    return asyncio.run(send())


def test_health_checks_database_connection() -> None:
    application, connection = build_app()

    response = request(application, "GET", "/salud")

    assert response.status_code == 200
    assert response.json() == {"estado": "ok", "base_de_datos": "disponible"}
    assert connection.statements[0][0] == "SELECT 1"


def test_wine_filters_are_forwarded_to_repository(monkeypatch) -> None:
    application, _ = build_app()
    repository = Mock(return_value={"items": [], "total": 0, "limit": 20, "offset": 0})
    monkeypatch.setattr(wines, "list_wines", repository)

    response = request(
        application,
        "GET",
        "/vinos?tipo=Malbec&cepa=4&bodega=30700000001&anada=2020",
    )

    assert response.status_code == 200
    assert repository.call_args.kwargs == {
        "limit": 20,
        "offset": 0,
        "tipo": "Malbec",
        "cepa": 4,
        "bodega": "30700000001",
        "anada": 2020,
    }


def test_wine_list_rejects_limit_over_maximum() -> None:
    application, _ = build_app()

    response = request(application, "GET", "/vinos?limit=501")

    assert response.status_code == 422


def test_create_wine_returns_created_resource(monkeypatch) -> None:
    application, _ = build_app()
    created = {"codigo": "TEST-01", "nombre": "Prueba", "composicion": []}
    repository = Mock(return_value=created)
    monkeypatch.setattr(wines, "create_wine", repository)

    response = request(
        application,
        "POST",
        "/vinos",
        json={
            "codigo": "TEST-01",
            "nombre": "Prueba",
            "tipo": "Tinto",
            "anada": 2020,
            "volumen_ml": 750,
            "graduacion": 13,
            "precio": 1000,
            "bodega": "30700000001",
            "composicion": [{"cepa": 1, "porcentaje": 100}],
        },
    )

    assert response.status_code == 201
    assert response.json() == created
    repository.assert_called_once()


def test_update_wine_rejects_mismatched_path_code() -> None:
    application, _ = build_app()

    response = request(
        application,
        "PUT",
        "/vinos/ONE",
        json={
            "codigo": "TWO",
            "nombre": "Prueba",
            "tipo": "Tinto",
            "anada": 2020,
            "volumen_ml": 750,
            "graduacion": 13,
            "precio": 1000,
            "bodega": "30700000001",
            "composicion": [{"cepa": 1, "porcentaje": 100}],
        },
    )

    assert response.status_code == 422


def test_sale_rejects_duplicate_wines() -> None:
    application, _ = build_app()

    response = request(
        application,
        "POST",
        "/comprobantes",
        json={
            "cliente": 1,
            "sala": 1,
            "renglones": [
                {"vino": "WINE-1", "cantidad": 1},
                {"vino": "WINE-1", "cantidad": 2},
            ],
        },
    )

    assert response.status_code == 422


def test_missing_sale_reference_returns_not_found(monkeypatch) -> None:
    application, _ = build_app()

    def reject_sale(*_args, **_kwargs):
        raise LookupError("El cliente indicado no existe.")

    monkeypatch.setattr("app.routes.commerce.create_comprobante", reject_sale)
    response = request(
        application,
        "POST",
        "/comprobantes",
        json={"cliente": 1, "sala": 1, "renglones": [{"vino": "WINE-1", "cantidad": 1}]},
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "El cliente indicado no existe."


def test_unique_violation_is_translated_without_database_details(monkeypatch) -> None:
    application, _ = build_app()
    monkeypatch.setattr(
        "app.routes.customers.create_customer",
        Mock(side_effect=UniqueViolation("sensitive database detail")),
    )
    response = request(
        application,
        "POST",
        "/clientes",
        json={
            "nombre": "Cliente",
            "tipo_doc": "DNI",
            "n_doc": "123",
            "subtipo": "Socio",
        },
    )

    assert response.status_code == 409
    assert response.json() == {"detail": "El recurso ya existe."}
    assert "sensitive database detail" not in response.text


def test_stock_check_violation_is_translated_to_validation_error(monkeypatch) -> None:
    application, _ = build_app()
    monkeypatch.setattr(
        "app.routes.commerce.create_comprobante",
        Mock(side_effect=CheckViolation("stock insuficiente")),
    )

    response = request(
        application,
        "POST",
        "/comprobantes",
        json={"cliente": 1, "sala": 1, "renglones": [{"vino": "WINE-1", "cantidad": 1}]},
    )

    assert response.status_code == 422
    assert response.json() == {"detail": "La operación viola una regla de negocio."}


def test_invalid_document_transition_is_translated(monkeypatch) -> None:
    application, _ = build_app()
    monkeypatch.setattr(
        "app.routes.movements.process_transfer",
        Mock(side_effect=RaiseException("transition rejected")),
    )

    response = request(application, "POST", "/transferencias/1/procesar")

    assert response.status_code == 422
    assert "transition rejected" not in response.text


def test_serialization_failure_requests_retry(monkeypatch) -> None:
    application, _ = build_app()
    monkeypatch.setattr(
        "app.routes.commerce.create_comprobante",
        Mock(side_effect=SerializationFailure("internal details")),
    )

    response = request(
        application,
        "POST",
        "/comprobantes",
        json={"cliente": 1, "sala": 1, "renglones": [{"vino": "WINE-1", "cantidad": 1}]},
    )

    assert response.status_code == 503
    assert response.headers["retry-after"] == "1"
    assert "internal details" not in response.text


def test_openapi_documents_required_workflows() -> None:
    application, _ = build_app()

    response = request(application, "GET", "/openapi.json")
    paths = response.json()["paths"]

    assert response.status_code == 200
    assert "/vinos" in paths
    assert "/comprobantes" in paths
    assert "/transferencias/{numero}/procesar" in paths
    assert "/reportes/trazabilidad/{codigo}" in paths


def test_customer_search_is_parameterized_against_sql_injection() -> None:
    connection = Mock()
    count_result = Mock()
    count_result.fetchone.return_value = {"total": 0}
    rows_result = Mock()
    rows_result.fetchall.return_value = []
    connection.execute.side_effect = [count_result, rows_result]
    attack = "' OR 1=1 --"

    customers.list_customers(
        connection, limit=10, offset=0, subtipo=None, query=attack
    )

    count_sql, count_params = connection.execute.call_args_list[0].args
    assert attack not in count_sql
    assert count_params[-3:] == (attack, attack, attack)

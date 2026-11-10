from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field, model_validator


class CompositionInput(BaseModel):
    cepa: int = Field(gt=0)
    porcentaje: Decimal = Field(gt=0, le=100)


class WineInput(BaseModel):
    codigo: str = Field(min_length=1, max_length=64)
    nombre: str = Field(min_length=1, max_length=200)
    tipo: str = Field(min_length=1, max_length=50)
    anada: int = Field(ge=0, le=32767)
    volumen_ml: int = Field(gt=0, le=32767)
    graduacion: Decimal = Field(ge=5, le=20)
    precio: Decimal = Field(gt=0)
    bodega: str = Field(min_length=1, max_length=11)
    composicion: list[CompositionInput] = Field(min_length=1)
    maridajes: list[int] = Field(default_factory=list)


class PermissionInput(BaseModel):
    codigo: str = Field(min_length=1, max_length=100)
    fecha_emision: date
    fecha_vencimiento: date


class CustomerInput(BaseModel):
    nombre: str = Field(min_length=1, max_length=200)
    tipo_doc: str = Field(min_length=1, max_length=30)
    n_doc: str = Field(min_length=1, max_length=50)
    direccion: str | None = Field(default=None, max_length=250)
    localidad: int | None = Field(default=None, gt=0)
    fecha_alta: date = Field(default_factory=date.today)
    subtipo: Literal["Socio", "Distribuidor", "Exportador"]
    zona: str | None = Field(default=None, max_length=150)
    n_habilitacion: str | None = Field(default=None, max_length=100)
    pais: str | None = Field(default=None, max_length=100)
    permisos: list[PermissionInput] = Field(default_factory=list)


class SaleLineInput(BaseModel):
    vino: str = Field(min_length=1, max_length=64)
    cantidad: int = Field(gt=0)


class SaleInput(BaseModel):
    fecha: date = Field(default_factory=date.today)
    cliente: int = Field(gt=0)
    sala: int = Field(gt=0)
    renglones: list[SaleLineInput] = Field(min_length=1)

    @model_validator(mode="after")
    def unique_wines(self) -> SaleInput:
        codes = [line.vino for line in self.renglones]
        if len(codes) != len(set(codes)):
            raise ValueError("Cada vino debe aparecer una sola vez en la venta.")
        return self


class TransferLineInput(BaseModel):
    vino: str = Field(min_length=1, max_length=64)
    cantidad: int = Field(gt=0)


class TransferInput(BaseModel):
    sala: int = Field(gt=0)


class TransferLinesInput(BaseModel):
    renglones: list[TransferLineInput] = Field(min_length=1)

    @model_validator(mode="after")
    def unique_wines(self) -> TransferLinesInput:
        codes = [line.vino for line in self.renglones]
        if len(codes) != len(set(codes)):
            raise ValueError("Cada vino debe aparecer una sola vez en la transferencia.")
        return self


class IncomeInput(BaseModel):
    transportista: str = Field(min_length=1, max_length=64)
    bodega_origen: str = Field(min_length=11, max_length=11)


class IncomeLineInput(BaseModel):
    vino: str = Field(min_length=1, max_length=64)
    cantidad: int = Field(gt=0)


class IncomeLinesInput(BaseModel):
    renglones: list[IncomeLineInput] = Field(min_length=1)

    @model_validator(mode="after")
    def unique_wines(self) -> IncomeLinesInput:
        codes = [line.vino for line in self.renglones]
        if len(codes) != len(set(codes)):
            raise ValueError("Cada vino debe aparecer una sola vez en el ingreso.")
        return self

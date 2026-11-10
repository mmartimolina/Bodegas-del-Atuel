from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv
from psycopg.conninfo import make_conninfo

PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")


@dataclass(frozen=True)
class Settings:
    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str
    db_role: str
    api_host: str
    api_port: int
    cors_origins: tuple[str, ...]
    pool_min_size: int
    pool_max_size: int

    @classmethod
    def from_env(cls) -> Settings:
        origins = os.getenv("API_CORS_ORIGINS", "http://localhost:8080")
        role = os.getenv("DB_ROLE", "bodegas_api")
        if role != "bodegas_api":
            raise ValueError("DB_ROLE debe ser bodegas_api.")

        pool_min_size = int(os.getenv("DB_POOL_MIN_SIZE", "1"))
        pool_max_size = int(os.getenv("DB_POOL_MAX_SIZE", "10"))
        if pool_min_size < 1 or pool_max_size < pool_min_size:
            raise ValueError("El tamaño del pool debe ser positivo y maximo >= minimo.")

        return cls(
            db_host=os.getenv("DB_HOST", "localhost"),
            db_port=int(os.getenv("DB_PORT", os.getenv("POSTGRES_PORT", "5433"))),
            db_name=os.getenv("POSTGRES_DB", "bodegas_atuel"),
            db_user=os.getenv("POSTGRES_USER", "bodegas_app"),
            db_password=os.getenv("POSTGRES_PASSWORD", ""),
            db_role=role,
            api_host=os.getenv("API_HOST", "127.0.0.1"),
            api_port=int(os.getenv("API_PORT", "8000")),
            cors_origins=tuple(origin.strip() for origin in origins.split(",") if origin.strip()),
            pool_min_size=pool_min_size,
            pool_max_size=pool_max_size,
        )

    @property
    def conninfo(self) -> str:
        return make_conninfo(
            host=self.db_host,
            port=self.db_port,
            dbname=self.db_name,
            user=self.db_user,
            password=self.db_password,
            connect_timeout=5,
        )


settings = Settings.from_env()

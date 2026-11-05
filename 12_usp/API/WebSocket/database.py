from contextlib import contextmanager
from typing import Any, Iterator
import pyodbc
from .config import get_settings


def connection_string() -> str:
    s = get_settings()
    parts = [
        f"DRIVER={s.db_driver}", f"SERVER={s.db_server}", f"DATABASE={s.db_database}",
        f"Encrypt={'yes' if s.db_encrypt else 'no'}",
        f"TrustServerCertificate={'yes' if s.db_trust_server_certificate else 'no'}",
    ]
    if s.db_trusted_connection:
        parts.append("Trusted_Connection=yes")
    else:
        parts.extend([f"UID={s.db_username}", f"PWD={s.db_password}"])
    return ";".join(parts) + ";"


@contextmanager
def get_connection() -> Iterator[pyodbc.Connection]:
    connection = pyodbc.connect(connection_string(), timeout=8)
    try:
        yield connection
    finally:
        connection.close()


def row_to_dict(cursor: pyodbc.Cursor, row: Any) -> dict[str, Any]:
    result = {}
    for column, value in zip((col[0] for col in cursor.description), row):
        result[column] = value.isoformat() if hasattr(value, "isoformat") else value
    return result

from datetime import datetime, timedelta, timezone
from typing import Annotated
import jwt
from fastapi import Depends, Header, HTTPException
from jwt import InvalidTokenError
from .config import get_settings
from .database import get_connection, row_to_dict


def authenticate_user(username: str, password: str) -> dict | None:
    """Compara la contraseña cifrada usando la misma función de SQL Server del USP."""
    sql = """
    OPEN SYMMETRIC KEY KEY_HASH DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;
    SELECT TOP (1) userId, userFullName, userName, userRolId, userEnable
    FROM SQM_SECURITY.TBL_Users
    WHERE userName = ?
      AND CONVERT(VARCHAR(256), DECRYPTBYKEY(userPassword)) = ?
      AND userEnable = 1;
    CLOSE SYMMETRIC KEY KEY_HASH;
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        try:
            cursor.execute(sql, username, password)
            row = cursor.fetchone()
            return row_to_dict(cursor, row) if row else None
        finally:
            # La conexión se cierra aunque falle la consulta; SQL Server libera la clave.
            cursor.close()


def create_access_token(user: dict) -> str:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    claims = {
        "sub": str(user["userId"]),
        "role_id": int(user["userRolId"]),
        "user_name": user["userName"],
        "iat": now,
        "exp": now + timedelta(minutes=settings.jwt_expire_minutes),
    }
    return jwt.encode(claims, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def get_current_user(authorization: Annotated[str | None, Header()] = None) -> dict:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Debes enviar un token Bearer válido.", headers={"WWW-Authenticate": "Bearer"})
    token = authorization.split(" ", 1)[1].strip()
    settings = get_settings()
    try:
        claims = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
        user_id = int(claims["sub"])
    except (InvalidTokenError, KeyError, TypeError, ValueError):
        raise HTTPException(status_code=401, detail="El token es inválido o expiró.", headers={"WWW-Authenticate": "Bearer"})

    # Verifica que el usuario siga activo; el token no sustituye el estado actual de la BD.
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT userId, userFullName, userName, userRolId, userEnable
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = ? AND userEnable = 1
        """, user_id)
        row = cursor.fetchone()
        user = row_to_dict(cursor, row) if row else None
    if not user:
        raise HTTPException(status_code=401, detail="El usuario no existe o está deshabilitado.")
    return user


CurrentUser = Annotated[dict, Depends(get_current_user)]


def get_admin_user(current_user: CurrentUser) -> dict:
    admin_role_id = get_settings().jwt_admin_role_id
    if int(current_user["userRolId"]) != admin_role_id:
        raise HTTPException(status_code=403, detail="No tienes permisos para esta operación.")
    return current_user


AdminUser = Annotated[dict, Depends(get_admin_user)]

from fastapi import APIRouter, Depends, HTTPException, Query
from .database import get_connection, row_to_dict
from .models import AuthenticateRequest
from .security import authenticate_user, create_access_token, AdminUser

router = APIRouter(prefix="/websocket/users", tags=["Usuarios"])


@router.post("/authenticate")
def authenticate(payload: AuthenticateRequest):
    try:
        user = authenticate_user(payload.userName, payload.userPassword)
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Error al validar las credenciales en la base de datos.") from exc
    if not user:
        raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos.", headers={"WWW-Authenticate": "Bearer"})
    return {
        "access_token": create_access_token(user),
        "token_type": "bearer",
        "message_user": "AUTENTICACION CORRECTA",
    }


@router.get("/list")
def list_users(
    _admin: AdminUser,
    page: int = Query(default=1, ge=1),
    rows_per_page: int = Query(default=100, ge=1, le=500),
):
    """Lista usuarios llamando al procedimiento almacenado USP_Users, acción S."""
    try:
        with get_connection() as connection:
            cursor = connection.cursor()
            cursor.execute(
                "EXEC SQM_SECURITY.USP_Users @i_PageNumber=?, @i_RowsPerPage=?, @w_Accion=?",
                page, rows_per_page, "S",
            )
            rows = cursor.fetchall() if cursor.description else []
            data = [row_to_dict(cursor, row) for row in rows]
        return {
            "status_code": 200 if data else 204,
            "message_user": "USUARIOS LISTADOS CORRECTAMENTE" if data else "NO HAY USUARIOS PARA LISTAR",
            "data": data,
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Error al obtener usuarios mediante USP_Users.") from exc

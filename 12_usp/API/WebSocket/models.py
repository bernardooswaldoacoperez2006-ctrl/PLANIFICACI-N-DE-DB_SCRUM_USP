from pydantic import BaseModel, Field, ConfigDict


class AuthenticateRequest(BaseModel):
    userName: str = Field(min_length=1, max_length=80)
    userPassword: str = Field(min_length=1, max_length=256)

    model_config = ConfigDict(str_strip_whitespace=True)


class AuthenticateResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    message_user: str = "AUTENTICACION CORRECTA"


class UserListResponse(BaseModel):
    status_code: int
    message_user: str
    data: list[dict]

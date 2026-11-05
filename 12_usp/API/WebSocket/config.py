from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    db_driver: str = "{ODBC Driver 18 for SQL Server}"
    db_server: str = "localhost"
    db_database: str = "DB_SCRUM_PLANNING"
    db_username: str = "sa"
    db_password: str = ""
    db_trusted_connection: bool = False
    db_encrypt: bool = False
    db_trust_server_certificate: bool = True

    jwt_secret_key: str = ""
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60
    jwt_admin_role_id: int = 1
    api_host: str = "127.0.0.1"
    api_port: int = 8000

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    if not settings.jwt_secret_key or len(settings.jwt_secret_key) < 32:
        raise RuntimeError("JWT_SECRET_KEY debe configurarse con al menos 32 caracteres.")
    return settings

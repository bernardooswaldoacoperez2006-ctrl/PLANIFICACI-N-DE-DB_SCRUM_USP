# SCRUM_PLANNING – adaptación de las 12 USP a la API de la imagen

## Contenido
- `DB/00_CreateDatabase.sql`: crea la base de datos si no existe.
- `DB/01_Schemas_Security.sql`: esquemas, certificado, clave AES-256 y función de cifrado.
- `DB/02_Tables.sql`: tablas necesarias para los 12 procedimientos almacenados.
- `DB/03_Seed_Catalogs.sql`: rol administrador (ID 1), rol usuario y catálogos iniciales.
- `DB/04_Install_All_USP.sql`: instala los 12 procedimientos almacenados.
- `DB/05_Create_Admin_User_TEMPLATE.sql`: crea el usuario de prueba CALHECTOR con la contraseña 12345678, tal como pide la imagen del profesor.
- `API/`: FastAPI, autenticación JWT y endpoint protegido para listar usuarios.
- `Postman/`: colección de pruebas.

## 1. Preparar SQL Server
Abre SSMS y ejecuta los scripts en este orden: `00`, `01`, `02`, `03`, `04`.
Después ejecuta `05_Create_Admin_User_TEMPLATE.sql` para crear el usuario CALHECTOR con contraseña 12345678. El rol administrador tiene ID 1. Estas credenciales son para la práctica académica; no las uses en producción.

**Importante sobre cifrado:** el proyecto original utiliza `KEY_HASH`, `CERT_SCRUMPLANNING` y `SQM_SECURITY.Fn_EncryptByKey`. El script 01 crea esos objetos. Cambia la contraseña de la Database Master Key en el script 01 antes de producción y conserva una copia segura. El cifrado reversible sirve para mantener compatibilidad con las USP existentes; en un sistema real conviene migrar a hash de contraseñas (Argon2/bcrypt) en la aplicación.

## 2. Configurar la API
En `API/`, copia `.env.example` como `.env` y completa `DB_SERVER`, `DB_USERNAME`, `DB_PASSWORD` y `JWT_SECRET_KEY`. Genera una clave JWT aleatoria de al menos 32 caracteres. No subas `.env` a GitHub.

Instala el controlador ODBC 18 de Microsoft para SQL Server y luego ejecuta:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --reload
```

La terminal debe mostrar que Uvicorn está escuchando en `http://127.0.0.1:8000`.

## 3. Probar en Postman
1. POST `http://127.0.0.1:8000/websocket/users/authenticate` con JSON:
   `{ "userName": "CALHECTOR", "userPassword": "12345678" }`
2. Copia `access_token` de la respuesta.
3. GET `http://127.0.0.1:8000/websocket/users/list` con Authorization → Bearer Token.
4. Debes obtener `200 OK` y el arreglo `data`. Sin token: `401`; con usuario no administrador: `403`.

Documentación interactiva: `http://127.0.0.1:8000/docs`.

## Alcance y verificación
Los scripts crean una base de datos inicial compatible con las columnas usadas por los procedimientos incluidos. No puedo ejecutar la instalación en tu instancia de SQL Server desde aquí; por eso debes ejecutar los scripts y comprobarlos en tu equipo. Si tu base ya tiene tablas con otros tipos/columnas, haz respaldo y revisa antes de ejecutar; los scripts no eliminan tablas existentes.

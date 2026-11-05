# API SCRUM_PLANNING

La guía completa de instalación y pruebas está en `../README_INSTALACION.md`.

Rutas:
- `POST /websocket/users/authenticate`: valida credenciales y entrega JWT.
- `GET /websocket/users/list`: requiere Bearer JWT y rol administrador (ID 1); ejecuta `SQM_SECURITY.USP_Users` con acción `S`.
- `GET /`: comprobación de estado.

Configura `.env` usando `.env.example` antes de iniciar el servidor.

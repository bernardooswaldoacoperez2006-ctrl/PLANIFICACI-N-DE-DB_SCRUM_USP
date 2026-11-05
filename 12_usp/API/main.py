from fastapi import FastAPI
from WebSocket.users import router as users_router

app = FastAPI(
    title="SCRUM_PLANNING API",
    description="Autenticación JWT y administración de usuarios conectada a DB_SCRUM_PLANNING.",
    version="1.0.0",
)
app.include_router(users_router)


@app.get("/", tags=["Estado"])
def health_check():
    return {"status": "ok", "message": "API SCRUM_PLANNING en ejecución"}

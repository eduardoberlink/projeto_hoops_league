from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
# Importe suas rotas aqui, ex: from routes import players

app = FastAPI(title="Hoops League API")

# Configuração de CORS - Essencial para integração
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite qualquer origem (ideal para desenvolvimento)
    allow_credentials=True,
    allow_methods=["*"],  # Permite GET, POST, PUT, DELETE, etc.
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Hoops League API is running"}

# Certifique-se de incluir seus roteadores abaixo
# app.include_router(players.router)
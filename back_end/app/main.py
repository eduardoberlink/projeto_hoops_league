from fastapi import FastAPI
from routes.auth_routes import auth_router
from routes.jogo_routes import jogo_router
from routes.comp_routes import comp_router  

app= FastAPI()
 


app.include_router(auth_router)
app.include_router(jogo_router)
app.include_router(comp_router) 

#uvicorn app.main:app --reload
from fastapi import Depends,HTTPException
from models.models import db
from app.config import SECRET_KEY, ALGORITHM,oauth2_schema
from sqlalchemy.orm import sessionmaker, Session
from models.models import Jogador
from jose import jwt, JWTError


def pegar_sessao():
    try:
        Session= sessionmaker(bind=db)
        session= Session()
        yield session
    finally:    
        session.close()

def verificar_token(token: str =Depends(oauth2_schema),session: Session=Depends(pegar_sessao)):
    try:
        dic_info=jwt.decode(token,SECRET_KEY, ALGORITHM)
        id_usuario=dic_info.get("sub")
    except JWTError :    
        raise HTTPException(status_code=401,detail="acesso Negado,verifique a validade do token")
    usuario=session.query(Jogador).filter(Jogador.id==id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=401,datail="Acesso Invalido")
    return usuario       
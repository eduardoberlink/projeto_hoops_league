from fastapi import APIRouter,Depends, HTTPException
from app.config import bcrypy_context, ALGORITHM,SECRET_KEY,ACESS_TOKEN_EXPIRE_MINUTES
from app.dependencies import pegar_sessao,verificar_token
from models.models import Jogador
from schemas.schemas import UsuarioSchema,LoginSchema,UsuarioPublico,EditarUsuarioSchema
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from jose import jwt
from datetime import datetime,timedelta,timezone



auth_router = APIRouter(prefix="/auth",tags=["auth"])
@auth_router.get("/")
async def autenticar(): 
    """
    rota padrao de pedidos
    """
    return {"mensagem":"voce acessou a rota padrao de autenticação"}

def autenticar_usuario(email,senha,session):
    usuario=session.query(Jogador).filter(Jogador.email==email).first()
    if not usuario:
        return False
    elif not bcrypy_context.verify(senha,usuario.senha):
        return False
    return usuario

def criar_token(id_usuario,duracao_token=timedelta(minutes=ACESS_TOKEN_EXPIRE_MINUTES)):
    data_expiracao=datetime.now(timezone.utc) + duracao_token
    dic_info = {"sub": str(id_usuario),"exp": data_expiracao}
    print(f"DEBUG SECRET: {SECRET_KEY}")
    print(f"DEBUG ALGO: {ALGORITHM}")
    jwt_codificado=jwt.encode(dic_info,SECRET_KEY,algorithm=ALGORITHM)
    return jwt_codificado

@auth_router.post("/criar-conta")
async def criar_conta(usuario_schema:UsuarioSchema,session: Session=Depends(pegar_sessao)):
    usuario=session.query(Jogador).filter(Jogador.email==usuario_schema.email).first()
    if usuario:
        raise HTTPException(status_code=400,detail="Email já cadastrado")
    else:
        senha_criptografada=bcrypy_context.hash(usuario_schema.senha)
        novo_usuario = Jogador(
            user=usuario_schema.user,
            nome=usuario_schema.nome,
            idade=usuario_schema.idade,
            email=usuario_schema.email,
            altura=usuario_schema.altura,
            posicao_preferida=usuario_schema.posicao_preferida, 
            senha=senha_criptografada,
            pontos=0,
            assistencias=0,
            rebotes=0,
            roubos=0,
            bloqueios=0,
            ativo=True,
            jogos=0,
            overall=0
        )
        try:
            session.add(novo_usuario)
            session.commit()
            session.refresh(novo_usuario)
            return {"mensagem":"Usuario criado com sucesso"}
        except Exception as e:
            session.rollback()
            raise HTTPException(status_code=500,detail=f"erro ao salvar no banco de dados")
@auth_router.post("/login")
async def login(login_schema:LoginSchema,session:Session = Depends(pegar_sessao)):
    usuario=autenticar_usuario(login_schema.email,login_schema.senha,session)
    if not usuario:
        raise HTTPException(status_code=400, detail="Usuario não encontrado ou credenciais invalidas")
    else:
        access_token = criar_token(usuario.id)
        refresh_token=criar_token(usuario.id,duracao_token=timedelta(days=7))
        return{
            "acess_token": access_token,
            "refresh_token": refresh_token,
            "token_type":"Bearer"
        }
    
@auth_router.post("/login-form")
async def login(dados_formulario: OAuth2PasswordRequestForm = Depends(),session:Session = Depends(pegar_sessao) ):
    usuario=autenticar_usuario(dados_formulario.username,dados_formulario.password,session)
    if not usuario:
        raise HTTPException(status_code=400, detail="Usuario não encontrado ou credenciais invalidas")
    else:
        access_token = criar_token(usuario.id)
        return{
            "access_token": access_token,
            "token_type":"Bearer"
        }      
    
@auth_router.get("/buscar-usuario/{user}", response_model=UsuarioPublico)
async def buscar_jogador(user:str,session:Session=Depends(pegar_sessao),usuario:Jogador=Depends(verificar_token)):
    if usuario.ativo!=True:
        raise HTTPException(status_code=500,detail="Seu Usuario não existe")
    usuarios=session.query(Jogador).filter(Jogador.user.ilike(f"%{user}%")).all  
    return usuarios
 
@auth_router.get("/me", response_model=UsuarioPublico)
async def visualizar_meu_perfil(usuario: Jogador = Depends(verificar_token)):
    if usuario.ativo!=True:
        raise HTTPException(status_code=500,detail="Seu Usuario não existe")
    return usuario

@auth_router.put("editar-me")
async def editar_usuario(atualizar_usuario:EditarUsuarioSchema,session:Session=Depends(pegar_sessao),usuario:Jogador=Depends(verificar_token)):
    if usuario.ativo!=True:
        raise HTTPException(status_code=500,detail="Seu Usuario não existe")
    senha_criptografada=bcrypy_context.hash(atualizar_usuario.senha)
    usuario.nome=atualizar_usuario.nome
    usuario.idade=atualizar_usuario.idade
    usuario.email=atualizar_usuario.email
    usuario.altura=atualizar_usuario.altura
    usuario.posicao_preferida=atualizar_usuario.posicao_preferida
    usuario.senha=senha_criptografada
    try:
        session.add(usuario)
        session.commit(usuario)
        session.refresh(usuario)
        return{
            "mensagem":"Pefil atualizado com sucesso",
            "usuario":usuario
        }
    except Exception:
        session.rollback()
        raise HTTPException(status_code=500,detail="erro ao atulizar perfil")
    
@auth_router.put("/deletar-usuario")
async def delete_user(session:Session=Depends(pegar_sessao),usuario:Jogador=Depends(verificar_token)):
    usuario.ativo=False
    try:
        session.add(usuario)
        session.commit(usuario)
        session.refresh(usuario)
        return{
            "mensagem":"Pefil apagado com sucesso",
        }
    except Exception:
        session.rollback()
        raise HTTPException(status_code=500,detail="erro a apagar perfil")

@auth_router.get("/refresh")    
async def use_refresh_token(usuario: Jogador = Depends(verificar_token)):
    if usuario.ativo!=True:
        raise HTTPException(status_code=500,detail="Seu Usuario não existe")
    access_token=criar_token(usuario.id)
    return{
            "access_token": access_token,
            "token_type":"Bearer"
        }

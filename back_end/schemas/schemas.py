from pydantic import BaseModel,EmailStr,Field,model_validator
from typing import Optional,List
from datetime import date, time
from models.models import Posicao,StatusComp, Visibilidade, TipoCompeticao,ResultadoJogo

class UsuarioSchema(BaseModel):
    user:str
    nome:str
    idade: int
    email: str
    altura: float
    posicao_preferida: Posicao
    senha: str
    confirmar_senha: str

    @model_validator(mode='after')
    def verificar_senha(self):
        s1=self.senha
        s2=self.confirmar_senha
        if s1 != s2:
            raise ValueError("As senhas não coincidem")
        return self
    
    class Config:
        from_attributes = True 

class LoginSchema(BaseModel):
    email: str
    senha: str

    class Config:
        from_attributes = True

class UsuarioPublico(BaseModel):
    id: int
    user:str
    nome:str
    email:str
    idade:int
    altura: float
    pontos:int
    assistencias:int
    rebotes:int
    roubos:int
    bloqueios:int
    jogos:int
    overall:int
    posicao_preferida:Posicao

class Config:
    from_attributes = True

class EditarUsuarioSchema(BaseModel):
    nome: Optional[str] = None
    idade: Optional[int] = None
    email: Optional[str] = None
    altura: Optional[float] = None
    posicao_preferida: Optional[str] = None
    senha: Optional[str] = None
    confirmar_senha: Optional[str] = None

    @model_validator(mode='after')
    def verificar_senha(self):
        s1=self.senha
        s2=self.confirmar_senha
        if s1 != s2:
            raise ValueError("As senhas não coincidem")
        return self
    
    class Config:
        from_attributes = True 
        
class CompeticaoCreate(BaseModel):
    local: str
    status: StatusComp = StatusComp.em_aberto
    visibilidade: Visibilidade
    qtd_times: int
    tipo: TipoCompeticao
    qtd_max_jogadores: int
    
    data_inscricoes: date | None = None
    data_inicio: date | None = None
    data_fim: date | None = None
    
    data_partida: date | None = None
    horario_partida: time | None = None 
    class Config:
        from_attributes = True 

class JogadoresEstatisticas(BaseModel):
    fk_jogador_id: int
    fk_time_id:int
    pontos:int
    assistencias:int
    rebotes:int
    roubos:int  
    bloqueios:int

    class Config:
        from_attributes = True
class CriarJogo(BaseModel):
    fk_Competicao_id: Optional[int] = None
    data: date
    horario: time
    local: str
    class Config:
        from_attributes = True    

class FinalizarJogo(BaseModel):
    pontuacao_1:int
    pontuacao_2:int
    resultado:ResultadoJogo
    estatisticas_jogadores:List[JogadoresEstatisticas]
    class Config:
        from_attributes=True                           
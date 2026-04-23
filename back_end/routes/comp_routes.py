from fastapi import APIRouter,Depends,HTTPException
from app.dependencies import verificar_token,pegar_sessao
from models.models import Jogador,Competicao,TipoCompeticao,Torneio,Partida
from sqlalchemy.orm import Session 
from schemas.schemas import CompeticaoCreate

comp_router=APIRouter(prefix="/comp",tags=["order"],dependencies=[Depends(verificar_token)])

@comp_router.post("/criar")
async def criar_competicao(
    dados: CompeticaoCreate, 
    session: Session = Depends(pegar_sessao),
    usuario: Jogador = Depends(verificar_token)
):
    nova_comp = Competicao(
        local=dados.local,
        status=dados.status,
        visibilidade=dados.visibilidade,
        qtd_times=dados.qtd_times,
        tipo=dados.tipo,
        fk_Jogador_id=usuario.id,
        qtd_max_jogadores=dados.qtd_max_jogadores
    )
    
    try:
        session.add(nova_comp)
        session.flush() 

        
        if dados.tipo == TipoCompeticao.torneio:
            if not dados.data_inicio:
                raise HTTPException(status_code=400, detail="Torneios precisam de datas.")
            
            novo_torneio = Torneio(
                fk_Competicao_id=nova_comp.id,
                data_inscricoes=dados.data_inscricoes,
                data_inicio=dados.data_inicio,
                data_fim=dados.data_fim
            )
            session.add(novo_torneio)

        elif dados.tipo == TipoCompeticao.partida:
            nova_partida = Partida(
                fk_Competicao_id=nova_comp.id,
                data=dados.data_partida,
                horario=dados.horario_partida
            )
            session.add(nova_partida)

        session.commit()
        return {"mensagem": "Competição criada com sucesso", "id": nova_comp.id}
    
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao criar: {str(e)}")

@comp_router.get("/")
async def listar_competicoes(session: Session = Depends(pegar_sessao)):
    return session.query(Competicao).all()

@comp_router.put("/atualizar/{comp_id}")
async def atualizar_competicao(
    comp_id: int, 
    dados: CompeticaoCreate, 
    session: Session = Depends(pegar_sessao),
    usuario: Jogador = Depends(verificar_token)
):

    comp = session.get(Competicao, comp_id)

    if not comp:
        raise HTTPException(status_code=404, detail="Competição não encontrada")

    if comp.fk_Jogador_id != usuario.id:
        raise HTTPException(status_code=403, detail="Você não tem permissão para alterar esta competição")

    try:
        comp.local = dados.local
        comp.status = dados.status
        comp.visibilidade = dados.visibilidade
        comp.qtd_times = dados.qtd_times
        comp.qtd_max_jogadores = dados.qtd_max_jogadores
       
        if comp.tipo == TipoCompeticao.torneio:
            torneio = session.query(Torneio).filter_by(fk_Competicao_id=comp.id).first()
            if torneio:
                torneio.data_inscricoes = dados.data_inscricoes
                torneio.data_inicio = dados.data_inicio
                torneio.data_fim = dados.data_fim

        elif comp.tipo == TipoCompeticao.partida:
            partida = session.query(Partida).filter_by(fk_Competicao_id=comp.id).first()
            if partida:
                partida.data = dados.data_partida
                partida.horario = dados.horario_partida

        session.commit()
        return {"mensagem": "Competição atualizada com sucesso"}

    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar: {str(e)}")

@comp_router.delete("/deletar/{comp_id}")
async def deletar_competicao(
    comp_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: Jogador = Depends(verificar_token)
):

    comp = session.get(Competicao, comp_id)

    if not comp:
        raise HTTPException(status_code=404, detail="Competição não encontrada")
    
    if comp.fk_Jogador_id != usuario.id:
        raise HTTPException(status_code=403, detail="Permissão negada")

    if comp.status == "encerrado": 
        raise HTTPException(
            status_code=400, 
            detail="Não é possível deletar uma competição que já aconteceu ou foi finalizada"
        )

    try:
        session.delete(comp)
        session.commit()
        
        return {"mensagem": f"Competição {comp_id} excluída com sucesso"}

    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao excluir: {str(e)}")

from fastapi import APIRouter, Depends, HTTPException
from app.dependencies import verificar_token, pegar_sessao
from models.models import Jogador, Competicao, TipoCompeticao, Torneio, Partida, Participacao, RespostaParticipacao
from sqlalchemy.orm import Session
from schemas.schemas import CompeticaoCreate

comp_router = APIRouter(prefix="/comp", tags=["order"], dependencies=[Depends(verificar_token)])


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
    comps = session.query(Competicao).all()
    return [
        {
            "id": comp.id,
            "local": comp.local,
            "status": comp.status.value,
            "visibilidade": comp.visibilidade.value,
            "qtd_times": comp.qtd_times,
            "tipo": comp.tipo.value,
            "qtd_max_jogadores": comp.qtd_max_jogadores,
            "fk_Jogador_id": comp.fk_Jogador_id,
        }
        for comp in comps
    ]


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


@comp_router.get("/{comp_id}")
async def buscar_competicao(
    comp_id: int,
    session: Session = Depends(pegar_sessao)
):
    comp = session.get(Competicao, comp_id)
    if not comp:
        raise HTTPException(status_code=404, detail="Competição não encontrada")

    resultado = {
        "id": comp.id,
        "local": comp.local,
        "status": comp.status.value,
        "visibilidade": comp.visibilidade.value,
        "qtd_times": comp.qtd_times,
        "tipo": comp.tipo.value,
        "qtd_max_jogadores": comp.qtd_max_jogadores,
        "partida": None
    }

    if comp.tipo.value == "partida":
        partida = session.query(Partida).filter_by(fk_Competicao_id=comp.id).first()
        if partida:
            resultado["partida"] = {
                "data": str(partida.data),
                "horario": str(partida.horario)
            }

    return resultado


# ── Participação / Convite ─────────────────────────────────────────────────────

@comp_router.post("/{comp_id}/convidar/{jogador_id}")
async def convidar_jogador(
    comp_id: int,
    jogador_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: Jogador = Depends(verificar_token)
):
    comp = session.get(Competicao, comp_id)
    if not comp:
        raise HTTPException(status_code=404, detail="Competição não encontrada")

    if comp.fk_Jogador_id != usuario.id:
        raise HTTPException(status_code=403, detail="Apenas o dono pode convidar jogadores")

    jogador = session.get(Jogador, jogador_id)
    if not jogador or not jogador.ativo:
        raise HTTPException(status_code=404, detail="Jogador não encontrado")

    ja_existe = (
        session.query(Participacao)
        .filter_by(fk_Jogador_id=jogador_id, fk_Competicao_id=comp_id)
        .first()
    )
    if ja_existe:
        raise HTTPException(status_code=400, detail="Jogador já foi convidado para esta partida")

    total = (
        session.query(Participacao)
        .filter_by(fk_Competicao_id=comp_id)
        .count()
    )
    if comp.qtd_max_jogadores and total >= comp.qtd_max_jogadores:
        raise HTTPException(status_code=400, detail="Partida já está com o número máximo de jogadores")

    try:
        participacao = Participacao(
            fk_Jogador_id=jogador_id,
            fk_Competicao_id=comp_id,
            resposta=RespostaParticipacao.esperando_retorno
        )
        session.add(participacao)
        session.commit()
        return {"mensagem": f"Jogador {jogador.user} convidado com sucesso"}

    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao convidar: {str(e)}")


@comp_router.get("/{comp_id}/jogadores")
async def listar_jogadores_competicao(
    comp_id: int,
    session: Session = Depends(pegar_sessao)
):
    comp = session.get(Competicao, comp_id)
    if not comp:
        raise HTTPException(status_code=404, detail="Competição não encontrada")

    participacoes = (
        session.query(Participacao)
        .filter_by(fk_Competicao_id=comp_id)
        .all()
    )
    resultado = []
    for p in participacoes:
        jogador = session.get(Jogador, p.fk_Jogador_id)
        if jogador:
            resultado.append({
                "id": jogador.id,
                "user": jogador.user,
                "nome": jogador.nome,
                "overall": jogador.overall,
                "resposta": p.resposta.value if p.resposta else None
            })
    return resultado


@comp_router.delete("/{comp_id}/remover/{jogador_id}")
async def remover_jogador(
    comp_id: int,
    jogador_id: int,
    session: Session = Depends(pegar_sessao),
    usuario: Jogador = Depends(verificar_token)
):
    comp = session.get(Competicao, comp_id)
    if not comp:
        raise HTTPException(status_code=404, detail="Competição não encontrada")

    if comp.fk_Jogador_id != usuario.id:
        raise HTTPException(status_code=403, detail="Apenas o dono pode remover jogadores")

    participacao = (
        session.query(Participacao)
        .filter_by(fk_Jogador_id=jogador_id, fk_Competicao_id=comp_id)
        .first()
    )
    if not participacao:
        raise HTTPException(status_code=404, detail="Jogador não está nesta partida")

    try:
        session.delete(participacao)
        session.commit()
        return {"mensagem": "Jogador removido com sucesso"}

    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Erro ao remover: {str(e)}")
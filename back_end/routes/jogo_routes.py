from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.dependencies import pegar_sessao, verificar_token
from schemas.schemas import CriarJogo,FinalizarJogo
from models.models import Jogo, Competicao, Time_Jogo, Jogador, ResultadoTimeJogo,Estatistica,ResultadoJogo

jogo_router = APIRouter(prefix="/jogos", tags=["jogos"])

@jogo_router.post("/criar")
async def criar_jogo(
    dados: CriarJogo , 
    session: Session = Depends(pegar_sessao),
    usuario_logado: Jogador = Depends(verificar_token)
):
    competicao = session.query(Competicao).filter(Competicao.id == dados.fk_Competicao_id).first()
    if not competicao:
        raise HTTPException(status_code=404, detail="Competição não encontrada")

    if competicao.fk_Jogador_id != usuario_logado.id:
        raise HTTPException(status_code=403, detail="Apenas o criador da competição pode marcar jogos")

    novo_jogo = Jogo(
        fk_Competicao_id=dados.fk_Competicao_id,
        data=dados.data,
        horario=dados.horario,

    )

    try:
        session.add(novo_jogo)
        session.commit()
        session.refresh(novo_jogo)
        return {"mensagem": "Jogo agendado com sucesso", "id_jogo": novo_jogo.id}
    except Exception:
        session.rollback()
        raise HTTPException(status_code=500, detail="Erro ao agendar jogo")

@jogo_router.post("/jogos/{jogo_id}/finalizar")
async def finalizar_jogo_completo(
    jogo_id: int, 
    dados: FinalizarJogo, 
    session: Session = Depends(pegar_sessao),
    usuario_logado: Jogador = Depends(verificar_token) 
):
    jogo = session.query(Jogo).filter(Jogo.id == jogo_id).first()
    if not jogo:
        raise HTTPException(status_code=404, detail="Jogo não encontrado")

    try:
        jogo.pontuacao_1 = dados.pontuacao_1
        jogo.pontuacao_2 = dados.pontuacao_2
        jogo.resultado = dados.resultado_geral


        res_t1 = ResultadoTimeJogo.vitoria if dados.resultado_geral == ResultadoJogo.time_1 else ResultadoTimeJogo.derrota
        tj1 = Time_Jogo(
            fk_Time_id=dados.id_time_1,
            fk_Jogo_id=jogo_id,
            resultado=res_t1,
            pontuacao_total=dados.pontuacao_1
        )

        res_t2 = ResultadoTimeJogo.vitoria if dados.resultado_geral == ResultadoJogo.time_2 else ResultadoTimeJogo.derrota
        tj2 = Time_Jogo(
            fk_Time_id=dados.id_time_2,
            fk_Jogo_id=jogo_id,
            resultado=res_t2,
            pontuacao_total=dados.pontuacao_2
        )
        session.add_all([tj1, tj2])

        for est in dados.estatisticas_jogadores:
            
            nova_est = Estatistica(
                fk_Jogador_id=est.jogador_id,
                fk_Jogo_id=jogo_id,
                fk_Time_id=est.time_id,
                roubos=est.roubos,
                rebotes=est.rebotes,
                assistencias=est.assistencias,
                bloqueios=est.bloqueios,
                pontos=est.pontos
            )
            session.add(nova_est)

           
            atleta = session.query(Jogador).filter(Jogador.id == est.jogador_id).first()
            if atleta:
                atleta.pontos += est.pontos
                atleta.assistencias += est.assistencias
                atleta.rebotes += est.rebotes
                atleta.roubos += est.roubos
                atleta.bloqueios += est.bloqueios
                atleta.jogos += 1
                
           
                
                soma_stats = (atleta.pontos + atleta.assistencias + atleta.rebotes + atleta.roubos + atleta.bloqueios)
                atleta.overall = int(soma_stats / (atleta.jogos * 5)) if atleta.jogos > 0 else 0

     
        session.commit()
        return {"mensagem": "Jogo finalizado, placares registrados e estatísticas de jogadores atualizadas com sucesso."}

    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=f"Erro crítico ao processar fim de jogo: {str(e)}")
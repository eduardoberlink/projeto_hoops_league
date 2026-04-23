from datetime import date, time
from typing import List, Optional
from enum import Enum as PyEnum

from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship
from sqlalchemy import String, ForeignKey, Enum, create_engine
from sqlalchemy.dialects.mysql import INTEGER, TINYINT, SMALLINT, DECIMAL

DATABASE_URL="mysql+pymysql://root:12344321@localhost:3306/projetopds"

db = create_engine(DATABASE_URL,echo=True)
class Base(DeclarativeBase):
    pass


class Posicao(PyEnum):
    armador = 'armador'
    ala_armador = 'ala_armador'
    ala = 'ala'
    ala_pivo = 'ala_pivo'
    pivo = 'pivo'
    nao_sei = 'nao_sei'

class StatusComp(PyEnum):
    em_aberto = 'em_aberto'
    cancelado = 'cancelado'
    confirmado = 'confirmado'
    encerrado = 'encerrado'

class Visibilidade(PyEnum):
    publico = 'publico'
    privado = 'privado'

class TipoCompeticao(PyEnum):
    torneio = 'torneio'
    partida = 'partida'

class ResultadoJogo(PyEnum):
    time_1 = 'time_1'
    time_2 = 'time_2'

class ResultadoTimeJogo(PyEnum):
    vitoria = 'vitoria'
    derrota = 'derrota'
    empate = 'empate'

class RespostaParticipacao(PyEnum):
    confirmado = 'confirmado'
    recusado = 'recusado'
    esperando_retorno = 'esperando_retorno'


class Jogador(Base):
    __tablename__ = "Jogador"

    id: Mapped[int] = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    user: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    nome: Mapped[str] = mapped_column(String(250), nullable=False)
    idade: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
    email: Mapped[str] = mapped_column(String(200), nullable=False)
    altura: Mapped[float] = mapped_column(DECIMAL(3,2, unsigned=True), nullable=False)
    pontos: Mapped[int] = mapped_column(SMALLINT(unsigned=True), nullable=False)
    assistencias: Mapped[int] = mapped_column(SMALLINT(unsigned=True), nullable=False)
    rebotes: Mapped[int] = mapped_column(SMALLINT(unsigned=True), nullable=False)
    roubos: Mapped[int] = mapped_column(SMALLINT(unsigned=True), nullable=False)
    bloqueios: Mapped[int] = mapped_column(SMALLINT(unsigned=True), nullable=False)
    ativo: Mapped[bool] = mapped_column(nullable=False)
    jogos: Mapped[int] = mapped_column(SMALLINT(unsigned=True), nullable=False)
    overall: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
    posicao_preferida: Mapped[Posicao] = mapped_column(Enum(Posicao), nullable=False)
    senha: Mapped[str] = mapped_column(String(512), nullable=False)

    competicoes_criadas: Mapped[List["Competicao"]] = relationship(back_populates="criador")


class Time(Base):
    __tablename__ = "Time"

    id: Mapped[int] = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    nome: Mapped[str] = mapped_column(String(150), nullable=False)


class Competicao(Base):
    __tablename__ = "Competicao"

    id: Mapped[int] = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    local: Mapped[str] = mapped_column(String(300), nullable=False)
    status: Mapped[StatusComp] = mapped_column(Enum(StatusComp), nullable=False)
    visibilidade: Mapped[Visibilidade] = mapped_column(Enum(Visibilidade), nullable=False)
    qtd_times: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
    tipo: Mapped[TipoCompeticao] = mapped_column(Enum(TipoCompeticao), nullable=False)
    fk_Jogador_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Jogador.id", ondelete="RESTRICT"),
        nullable=False
    )
    qtd_max_jogadores: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)

    criador: Mapped["Jogador"] = relationship(back_populates="competicoes_criadas")


class Jogo(Base):
    __tablename__ = "Jogo"

    id: Mapped[int] = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    resultado: Mapped[Optional[ResultadoJogo]] = mapped_column(Enum(ResultadoJogo))
    pontuacao_2: Mapped[Optional[int]] = mapped_column(TINYINT(unsigned=True))
    pontuacao_1: Mapped[Optional[int]] = mapped_column(TINYINT(unsigned=True))
    fk_Competicao_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Competicao.id", ondelete="RESTRICT"),
        nullable=False
    )
    data: Mapped[date] = mapped_column(nullable=False)
    horario: Mapped[time] = mapped_column(nullable=False)

class Torneio(Base):
    __tablename__ = "Torneio"

    fk_Competicao_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Competicao.id", ondelete="CASCADE"),
        primary_key=True
    )
    data_inscricoes: Mapped[date] = mapped_column(nullable=False)
    data_inicio: Mapped[date] = mapped_column(nullable=False)
    data_fim: Mapped[date] = mapped_column(nullable=False)



class Partida(Base):
    __tablename__ = "Partida"

    fk_Competicao_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Competicao.id", ondelete="CASCADE"),
        primary_key=True
    )
    data: Mapped[date] = mapped_column(nullable=False)
    horario: Mapped[time] = mapped_column(nullable=False)


class Participacao(Base):
    __tablename__ = "Participacao"

    fk_Jogador_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Jogador.id", ondelete="RESTRICT"),
        primary_key=True
    )
    fk_Competicao_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Competicao.id", ondelete="RESTRICT"),
        primary_key=True
    )
    resposta: Mapped[Optional[RespostaParticipacao]] = mapped_column(Enum(RespostaParticipacao))


class Formacao_Time(Base):
    __tablename__ = "Formacao_Time"

    fk_Jogador_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Jogador.id", ondelete="RESTRICT"),
        primary_key=True
    )
    fk_Competicao_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Competicao.id", ondelete="RESTRICT"),
        primary_key=True
    )
    fk_Time_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Time.id", ondelete="CASCADE"),
        nullable=False
    )


class Classificacao(Base):
    __tablename__ = "Classificacao"

    fk_Time_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Time.id", ondelete="RESTRICT"),
        primary_key=True
    )
    fk_Torneio_fk_Competicao_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Torneio.fk_Competicao_id", ondelete="RESTRICT"),
        primary_key=True
    )
    classificacao: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)


class Time_Jogo(Base):
    __tablename__ = "Time_Jogo"

    fk_Time_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Time.id", ondelete="RESTRICT"),
        primary_key=True
    )
    fk_Jogo_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Jogo.id", ondelete="RESTRICT"),
        primary_key=True
    )
    resultado: Mapped[Optional[ResultadoTimeJogo]] = mapped_column(Enum(ResultadoTimeJogo))
    pontuacao_total: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)


class Estatistica(Base):
    __tablename__ = "Estatistica"

    fk_Jogador_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Jogador.id", ondelete="RESTRICT"),
        primary_key=True
    )
    fk_Jogo_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Jogo.id", ondelete="RESTRICT"),
        primary_key=True
    )
    fk_Time_id: Mapped[int] = mapped_column(
        INTEGER(unsigned=True),
        ForeignKey("Time.id", ondelete="RESTRICT"),
        nullable=False
    )
    roubos: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
    rebotes: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
    assistencias: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
    bloqueios: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
    pontos: Mapped[int] = mapped_column(TINYINT(unsigned=True), nullable=False)
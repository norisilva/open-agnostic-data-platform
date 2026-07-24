# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Retrieval Agents - Multi-Bases (Plataforma Core)
# Domínio: Plataforma Agnóstica — Épico 2
# Autor: Time de Engenharia da Plataforma
# =============================================================================

Funcionalidade: Agentes Investigadores Autônomos Multi-Bases
  Como a inteligência cognitiva da Plataforma (ai-predictor-worker)
  Quero atuar como um Agente Autônomo para invocar ferramentas e APIs de terceiros
  Para embasar minhas predições quando os dados internos do Redis forem insuficientes

  Contexto:
    Dado que a Plataforma está operando com IA Forte sob "Soft Rules"
    E a Célula cadastrou um catálogo de Ferramentas (APIs de Bureau, CRMs, etc) no payload

  Cenário: IA toma decisão com base na Federação Dinâmica de Dados
    Dado que o evento em análise não possui histórico suficiente na Camada Ouro interna (Redis)
    E a Célula informou no contrato que o LLM pode usar a tool "buscar_score_bureau(cpf)"
    Quando o LLM diagnostica incerteza na predição primária
    Então o LLM pausa a predição para invocar a tool "buscar_score_bureau"
    E a plataforma orquestra a chamada para a API externa da Célula
    E o resultado externo (ex: Score de 850) é injetado no contexto do LLM
    E o LLM consolida todos os dados para emitir um "prediction.completed" altamente preciso

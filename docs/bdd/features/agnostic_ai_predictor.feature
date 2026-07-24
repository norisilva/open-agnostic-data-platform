# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Agnostic AI Predictor Engine (Plataforma Core)
# Domínio: Plataforma Agnóstica — Avaliação com SLA, Hard Rules e Soft Rules
# Autor: Time de Engenharia da Plataforma
# =============================================================================

Funcionalidade: Motor Preditivo de IA Agnóstico
  Como a plataforma de eventos inteligente (ai-predictor-worker)
  Quero processar eventos de qualquer célula (Risco, E-commerce, Logística, etc)
  Para devolver um veredito baseado em Inteligência Artificial, respeitando SLAs, Hard Rules e utilizando Soft Rules

  Contexto:
    Dado que o "ai-predictor-worker" está ativo escutando eventos no NATS JetStream
    E o Redis (Feature Store) está populado com os "Golden Signals" da entidade

  # ---------------------------------------------------------------------------
  # SUCESSO - HARD E SOFT RULES
  # ---------------------------------------------------------------------------

  Cenário: Evento agnóstico processado com sucesso respeitando Hard Rules
    Dado que a plataforma recebe um evento preditivo genérico
    E o payload inclui uma "Hard Rule": "Se score < 300, negar imediatamente"
    E a consulta ao Redis retorna os Golden Signals da entidade indicando score = 250
    Quando o worker injeta as regras e os sinais no prompt via LangChain4j
    E o LLM devolve a análise
    Então o resultado final da predição deve ser "NEGADO"
    E a justificativa do LLM deve constar a violação da "Hard Rule"
    E o evento de "prediction.completed" deve ser emitido via SNS no tópico adequado
    E o timer de fallback no NATS-Schedule deve ser cancelado

  Cenário: IA aplica Soft Rules e utiliza avaliação probabilística para otimização
    Dado que a plataforma recebe um evento preditivo genérico
    E o payload inclui uma "Soft Rule": "Otimizar para rentabilidade a longo prazo"
    E não há violação de nenhuma "Hard Rule"
    E a consulta ao Redis retorna métricas financeiras variadas
    Quando a IA (Agent) analisa cruzamentos complexos das métricas
    Então o LLM deve devolver um veredito probabilístico (ex: "APROVADO com 85% de confiança")
    E o evento de "prediction.completed" deve ser emitido
    E o timer de fallback no NATS-Schedule deve ser cancelado

  # ---------------------------------------------------------------------------
  # SLA E FALLBACK
  # ---------------------------------------------------------------------------

  Cenário: LLM sofre timeout e a plataforma executa Fallback via SLA
    Dado que a plataforma recebe um evento preditivo genérico com SLA de "5000ms"
    E o worker de IA agenda uma mensagem de "fallback" no NATS-Schedule para 5000ms
    E a chamada ao LLM demora 8000ms (timeout)
    Quando o SLA expira
    Então o NATS-Schedule entrega a mensagem de fallback incondicionalmente
    E o evento "prediction.timeout" deve ser emitido com a decisão paliativa (ex: mini-negativa)
    E o processo bloqueado original deve ser interrompido e descartado

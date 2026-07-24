# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Webhook Validation & Action (Plataforma Core)
# Domínio: Plataforma Agnóstica
# Autor: Time de Engenharia da Plataforma
# =============================================================================

Funcionalidade: Integração com Células via Webhooks e Sagas
  Como os workers de integração da Plataforma (webhook-validator e webhook-action)
  Quero despachar eventos para as APIs (Webhooks) geridas pelas Células
  Para validar regras de negócio cliente-específicas ou executar ações, lidando com falhas via Saga

  Contexto:
    Dado que os workers de webhook estão consumindo das filas SQS genéricas
    E a Célula configurou suas URLs de validação e ação nas variáveis de ambiente

  Cenário: Webhook Validator aprova evento
    Dado que o "webhook-validator" consome um evento pendente de validação
    Quando o worker faz um POST HTTP para a URL da Célula com o envelope CloudEvent
    E a Célula responde com HTTP 200 (OK)
    Então o worker publica um novo evento "event-validated" no ecossistema

  Cenário: Webhook Validator rejeita evento por regra de negócio da Célula
    Dado que o "webhook-validator" despacha o evento para a Célula
    E a Célula responde com HTTP 422 (Unprocessable Entity) e uma mensagem de erro (ex: "Boleto Vencido")
    Quando o worker processa a resposta negativa
    Então o worker emite o evento "event-validation-failed" contendo o erro da Célula
    E o ciclo de vida do evento original é encerrado

  Cenário: Falha de rede e Compensação de Saga no Webhook Action
    Dado que o "webhook-action" precisa efetivar uma transação na API da Célula
    E a API da Célula retorna HTTP 500 ou dá timeout sistematicamente
    Quando o worker atinge o limite máximo de retries via Backoff Exponencial
    Então o worker deve abortar a tentativa
    E deve emitir o evento "action-failed" para acionar mecanismos compensatórios (Saga)
    E deve emitir um "notification.requested" alertando o time técnico da Célula

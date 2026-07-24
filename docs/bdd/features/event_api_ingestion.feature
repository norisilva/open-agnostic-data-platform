# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Event API - Ingestão e Idempotência (Plataforma Core)
# Domínio: Plataforma Agnóstica
# Autor: Time de Engenharia da Plataforma
# =============================================================================

Funcionalidade: Recebimento e Roteamento Genérico de Eventos
  Como o Gateway principal da Plataforma (event-api)
  Quero receber eventos genéricos via HTTP POST e aplicar políticas de idempotência
  Para empacotá-los em CloudEvents e despachar rapidamente (Fast Dispatching) para SNS sem bloquear I/O

  Contexto:
    Dado que o "event-api" está disponível
    E o Redis está ativo para controle de idempotência
    E o schema registry (Apicurio) está operacional

  Cenário: Recebimento de evento inédito com sucesso
    Dado que o cliente envia um POST para "/api/v1/events" com um payload JSON genérico
    E o header "X-Cell-Id" possui o valor "cell-financeira"
    E o header "X-Event-Type" possui o valor "br.com.platform.credit.solicitation.v1"
    E o header "Idempotency-Key" possui um valor UUID válido
    Quando o "event-api" processa a requisição
    Então o payload deve ser validado contra o schema "credit.solicitation" do Apicurio
    E o payload deve ser empacotado em um envelope "CloudEvents 1.0"
    E o evento deve ser publicado no tópico SNS associado à célula
    E a chave de idempotência deve ser salva no Redis com TTL de 24 horas
    E a API deve retornar HTTP status code 202 (Accepted)

  Cenário: Chamada duplicada interceptada pela Idempotência
    Dado que o cliente envia um POST idêntico utilizando a mesma "Idempotency-Key" de uma chamada anterior bem-sucedida
    E a chave ainda está presente no Redis
    Quando o "event-api" verifica a chave no Redis
    Então o serviço não deve republicar o evento no SNS
    E a API deve retornar sucesso (HTTP 202) silenciosamente (Cached Response)

# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Compensação do Padrão Saga
# Domínio: PaymentRenegotiation — rollback distribuído via Saga Choreography
# Autor: Time de Engenharia — Multiframeworks Renegociation
# Criado em: 2026-07-23
# =============================================================================

Funcionalidade: Compensação do Padrão Saga em Renegociações
  Como o orquestrador de transações distribuídas
  Quero garantir que qualquer falha em etapas intermediárias do fluxo de renegociação
  Dispare as devidas transações de compensação para manter a consistência dos dados
  Para que o sistema não fique em estado inconsistente após falhas parciais

  Contexto:
    Dado que o sistema de renegociação utiliza o padrão Saga Choreography
    E o mecanismo de Dead Letter Queue (DLQ) está configurado no tópico "renegotiation.dlq"
    E o número máximo de retentativas configurado é 3
    E o serviço de auditoria está operacional e registrando todos os eventos de compensação
    E o banco de dados transacional está acessível

  # ---------------------------------------------------------------------------
  # TIMEOUT NO VALIDADOR DE BARCODE — COMPENSAÇÃO
  # ---------------------------------------------------------------------------

  Cenário: Timeout no serviço de validação de barcode dispara compensação e atualiza status para FAILED
    Dado que a renegociação "rng-saga-001" está no status "PROCESSING"
    E a renegociação foi publicada no tópico "renegotiation.received"
    E o serviço de validação de barcode não responde dentro de "5 segundos" (timeout configurado)
    Quando o consumer do tópico "renegotiation.received" detecta timeout no validador
    Então o evento "BarcodeValidationTimeoutEvent" deve ser publicado no tópico "renegotiation.saga.compensate"
    E o consumer de compensação deve consumir o evento "BarcodeValidationTimeoutEvent"
    E o status da renegociação "rng-saga-001" deve ser atualizado para "FAILED"
    E o campo "motivoFalha" deve conter "BARCODE_VALIDATION_TIMEOUT"
    E a entrada deve ser registrada na tabela de auditoria com tipo "COMPENSACAO_TIMEOUT_VALIDACAO"
    E o log deve registrar "Compensação iniciada para rng-saga-001: BarcodeValidationTimeoutEvent"

  Cenário: Timeout no validador de barcode após 2 retentativas bem-sucedidas é compensado corretamente
    Dado que a renegociação "rng-saga-002" está no status "PROCESSING"
    E as tentativas 1 e 2 de chamar o validador de barcode falharam com timeout
    E a tentativa 3 de chamar o validador de barcode também falhou com timeout
    Quando o consumer esgota as retentativas para "rng-saga-002"
    Então o sistema deve publicar o evento "BarcodeValidationTimeoutEvent" no tópico de compensação
    E o status da renegociação deve ser atualizado para "FAILED"
    E a mensagem deve ser roteada para a DLQ "renegotiation.barcode.dlq" com metadados de falha

  Cenário: Timeout no validador é temporário e a terceira tentativa tem sucesso (sem compensação)
    Dado que a renegociação "rng-saga-003" está no status "PROCESSING"
    E as tentativas 1 e 2 falharam com timeout no validador de barcode
    E a tentativa 3 retorna sucesso com barcode válido
    Quando o consumer processa a terceira tentativa para "rng-saga-003"
    Então nenhum evento de compensação deve ser publicado
    E o status da renegociação deve ser atualizado para "VALIDATED"
    E o evento "BarcodeValidatedEvent" deve ser publicado no tópico "renegotiation.validated"

  # ---------------------------------------------------------------------------
  # FALHA NA EMISSÃO DO COMPROVANTE — ROLLBACK DE STATUS
  # ---------------------------------------------------------------------------

  Cenário: Falha na emissão do comprovante dispara rollback do status da renegociação
    Dado que a renegociação "rng-saga-004" está no status "VALIDATED"
    E o evento "BarcodeValidatedEvent" foi publicado no tópico "renegotiation.validated"
    E o serviço de emissão de comprovantes falha em todas as 3 tentativas com erro 500
    Quando o consumer de emissão esgota as retentativas para "rng-saga-004"
    Então o evento "ReceiptEmissionFailedEvent" deve ser publicado no tópico "renegotiation.saga.compensate"
    E o consumer de compensação deve consumir o evento "ReceiptEmissionFailedEvent"
    E o status da renegociação "rng-saga-004" deve ser atualizado de "VALIDATED" para "FAILED"
    E o campo "statusAnterior" na auditoria deve ser "VALIDATED"
    E o campo "statusAtual" na auditoria deve ser "FAILED"
    E o campo "motivoFalha" deve conter "RECEIPT_EMISSION_FAILURE_MAX_RETRIES"

  Cenário: Falha na emissão dispara rollback e notifica o time de operações via alerta
    Dado que a renegociação "rng-saga-005" está no status "VALIDATED"
    E o serviço de emissão de comprovantes falha em todas as 3 tentativas
    Quando o sistema dispara a compensação para "rng-saga-005"
    Então o status deve ser atualizado para "FAILED"
    E um alerta deve ser enviado para o tópico SNS "ops-alerts" com assunto "RECEIPT_EMISSION_FAILED"
    E o alerta deve conter o idRenegociation "rng-saga-005"
    E o alerta deve conter o timestamp da falha

  # ---------------------------------------------------------------------------
  # SUCESSO PARCIAL — BARCODE VÁLIDO, COMPROVANTE FALHA
  # ---------------------------------------------------------------------------

  Cenário: Sucesso parcial — barcode validado mas emissão de comprovante falha após 3 tentativas
    Dado que a renegociação "rng-saga-006" passou pela validação de barcode com sucesso
    E o status foi atualizado para "VALIDATED"
    E o sistema externo de comprovantes está completamente indisponível
    Quando o serviço de emissão não consegue processar "rng-saga-006" após 3 tentativas
    Então o evento de compensação "ReceiptEmissionFailedEvent" deve ser publicado
    E o status deve regredir de "VALIDATED" para "FAILED"
    E a transação de compensação deve reverter qualquer reserva de recurso associada
    E o log deve registrar "Sucesso parcial detectado: barcode validado mas comprovante não emitido para rng-saga-006"

  Cenário: Sucesso parcial — comprovante gerado no sistema externo mas falha ao persistir internamente
    Dado que a renegociação "rng-saga-007" está no status "VALIDATED"
    E o sistema externo gerou o comprovante com externalId "ext-saga-007-external"
    E a persistência interna na tabela "comprovante" falha com deadlock
    Quando o serviço detecta a falha de persistência para "rng-saga-007"
    Então o serviço deve publicar o evento "ReceiptPersistenceFailedEvent" no tópico de compensação
    E o consumer de compensação deve chamar o endpoint de cancelamento no sistema externo com externalId "ext-saga-007-external"
    E o status da renegociação deve ser atualizado para "FAILED"
    E o campo "motivoFalha" deve conter "RECEIPT_PERSISTENCE_FAILED_DEADLOCK"

  # ---------------------------------------------------------------------------
  # ROTEAMENTO PARA DLQ APÓS MÁXIMO DE RETENTATIVAS
  # ---------------------------------------------------------------------------

  Cenário: Mensagem é roteada para DLQ após esgotar máximo de retentativas
    Dado que a renegociação "rng-saga-008" gerou o evento "BarcodeValidatedEvent"
    E o consumer de emissão falhou 3 vezes consecutivas ao processar o evento
    Quando o framework de mensageria (Kafka) atinge o limite de retentativas "3"
    Então a mensagem deve ser automaticamente movida para a DLQ "renegotiation.receipt.dlq"
    E a mensagem na DLQ deve conter o header "x-retry-count" com valor "3"
    E a mensagem na DLQ deve conter o header "x-original-topic" com valor "renegotiation.validated"
    E a mensagem na DLQ deve conter o header "x-failure-reason" com a descrição do erro
    E o status da renegociação "rng-saga-008" deve ser "FAILED"
    E uma entrada na tabela "dlq_audit" deve ser criada com os metadados da mensagem

  Esquema do Cenário: Roteamento para DLQ correto por tipo de falha
    Dado que a renegociação "<idRenegociation>" falhou na etapa "<etapa_falha>"
    E o número de retentativas esgotadas foi "<max_retentativas>"
    Quando o framework roteia a mensagem para a DLQ
    Então a mensagem deve ser enviada para a DLQ "<dlq_destino>"
    E o header "x-failure-stage" deve conter "<etapa_falha>"
    E o status final da renegociação deve ser "FAILED"

    Exemplos:
      | idRenegociation | etapa_falha           | max_retentativas | dlq_destino                          |
      | rng-dlq-001     | BARCODE_VALIDATION    | 3                | renegotiation.barcode.dlq            |
      | rng-dlq-002     | RECEIPT_EMISSION      | 3                | renegotiation.receipt.dlq            |
      | rng-dlq-003     | NOTIFICATION          | 3                | renegotiation.notification.dlq       |
      | rng-dlq-004     | PERSISTENCE           | 3                | renegotiation.persistence.dlq        |

  # ---------------------------------------------------------------------------
  # COMPENSAÇÃO COM IDEMPOTÊNCIA
  # ---------------------------------------------------------------------------

  Cenário: Evento de compensação processado duas vezes não duplica a compensação (idempotência da compensação)
    Dado que o evento "ReceiptEmissionFailedEvent" para "rng-saga-009" foi publicado
    E o consumer de compensação já processou o evento e atualizou o status para "FAILED"
    Quando o mesmo evento "ReceiptEmissionFailedEvent" para "rng-saga-009" é recebido novamente
    Então o consumer de compensação deve detectar que já foi processado (via tabela de idempotência)
    E o status da renegociação deve permanecer "FAILED" (sem alteração)
    E nenhum novo evento de compensação deve ser publicado
    E o log deve registrar "Evento de compensação duplicado ignorado para rng-saga-009"

  Cenário: Status COMPENSATED é atribuído após compensação bem-sucedida completa
    Dado que a renegociação "rng-saga-010" teve todas as etapas de compensação executadas com sucesso
    E os seguintes eventos de compensação foram publicados e processados:
      | evento                          | tópico                        |
      | ReceiptEmissionFailedEvent      | renegotiation.saga.compensate |
      | ResourceReservationCancelledEvent | renegotiation.saga.compensate |
    Quando o consumer de compensação confirma que todas as etapas foram revertidas
    Então o status final da renegociação "rng-saga-010" deve ser "COMPENSATED"
    E o campo "compensatedAt" deve conter o timestamp da compensação
    E a entrada de auditoria deve registrar o evento "CompensationCompletedEvent"

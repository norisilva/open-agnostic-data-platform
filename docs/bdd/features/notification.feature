# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Notificação do Pagador
# Domínio: PaymentRenegotiation — envio de e-mail de confirmação ao pagador
# Autor: Time de Engenharia — Multiframeworks Renegociation
# Criado em: 2026-07-23
# =============================================================================

Funcionalidade: Notificação do Pagador após Renegociação
  Como o serviço de notificações
  Quero enviar um e-mail de confirmação ao pagador após a emissão do comprovante
  Contendo o internalId, externalId e o link para download do PDF
  Para que o pagador tenha ciência formal do processamento da renegociação

  Contexto:
    Dado que o serviço de notificações está operacional
    E o servidor SMTP (Amazon SES via LocalStack) está disponível
    E o template de e-mail "renegotiation-receipt-notification" está configurado
    E o serviço de emissão de comprovantes publicou o evento "ReceiptEmittedEvent"
    E o consumer "notification-service" está inscrito no tópico "renegotiation.receipt.emitted"

  # ---------------------------------------------------------------------------
  # E-MAIL ENVIADO APÓS EMISSÃO DO COMPROVANTE — HAPPY PATH
  # ---------------------------------------------------------------------------

  Cenário: E-mail de confirmação é enviado ao pagador após emissão bem-sucedida do comprovante
    Dado que o evento "ReceiptEmittedEvent" foi publicado com os dados:
      | campo            | valor                                    |
      | idRenegociation  | rng-abc123def456                         |
      | internalId       | cmp-int-7f9a3b2e1d4c                     |
      | externalId       | ext-8a7b6c5d4e3f                         |
      | emailPagador     | joao.silva@example.com                   |
      | cpfCnpj          | 12345678909                              |
      | valorPago        | 250.00                                   |
      | pdfUrl           | https://s3.amazonaws.com/comprovantes/rng-abc123def456.pdf |
    Quando o consumer "notification-service" processa o evento "ReceiptEmittedEvent"
    Então um e-mail deve ser enviado para "joao.silva@example.com"
    E o e-mail deve ter o assunto "Confirmação de Renegociação — Comprovante Disponível"
    E o e-mail deve ser enviado a partir de "noreply@renegociacao.com.br"
    E o status da notificação deve ser registrado como "SENT" na tabela "notification_log"
    E o campo "sentAt" deve conter o timestamp do envio

  Cenário: E-mail contém todos os dados obrigatórios do comprovante
    Dado que o evento "ReceiptEmittedEvent" para "rng-abc123def456" foi consumido pelo serviço de notificações
    E o internalId é "cmp-int-7f9a3b2e1d4c"
    E o externalId é "ext-8a7b6c5d4e3f"
    E a URL do PDF é "https://s3.amazonaws.com/comprovantes/rng-abc123def456.pdf"
    Quando o serviço de notificações prepara o e-mail para "joao.silva@example.com"
    Então o corpo do e-mail deve conter o texto "Comprovante Interno: cmp-int-7f9a3b2e1d4c"
    E o corpo do e-mail deve conter o texto "Comprovante Externo: ext-8a7b6c5d4e3f"
    E o corpo do e-mail deve conter o texto "Renegociação: rng-abc123def456"
    E o corpo do e-mail deve conter o link "https://s3.amazonaws.com/comprovantes/rng-abc123def456.pdf"
    E o corpo do e-mail deve conter o texto "Valor Pago: R$ 250,00"
    E o corpo do e-mail deve conter o texto "CPF/CNPJ: ***.456.789-**" (mascarado)
    E o corpo do e-mail deve ser gerado a partir do template HTML "renegotiation-receipt-notification"

  Cenário: E-mail é enviado com dados mascarados para proteger informações sensíveis
    Dado que o evento "ReceiptEmittedEvent" contém cpfCnpj "12345678909"
    Quando o serviço de notificações prepara o corpo do e-mail
    Então o CPF no corpo do e-mail deve ser exibido como "***.456.789-**"
    E o e-mail não deve conter o CPF completo "12345678909" em nenhuma parte do corpo

  Cenário: E-mail para pagador com CNPJ é formatado corretamente
    Dado que o evento "ReceiptEmittedEvent" para "rng-cnpj-001" contém cpfCnpj "11222333000181"
    E o emailPagador é "financeiro@empresa.com.br"
    Quando o serviço de notificações prepara o e-mail
    Então o CNPJ no corpo do e-mail deve ser exibido como "**.222.333/0001-**"
    E o e-mail deve ser enviado para "financeiro@empresa.com.br"

  # ---------------------------------------------------------------------------
  # ENDPOINT DE REENVIO
  # ---------------------------------------------------------------------------

  Cenário: Endpoint de reenvio de e-mail funciona para renegociação com comprovante emitido
    Dado que a renegociação "rng-abc123def456" está no status "RECEIPT_SENT"
    E o comprovante foi emitido com internalId "cmp-int-7f9a3b2e1d4c"
    E o e-mail original foi enviado para "joao.silva@example.com" em "2026-07-23T01:00:00-03:00"
    Quando o sistema envia uma requisição POST para "/api/v1/renegotiations/rng-abc123def456/notifications/resend"
    Então a API deve retornar o HTTP status code 200
    E o e-mail deve ser reenviado para "joao.silva@example.com"
    E o campo "resentAt" deve conter o timestamp do reenvio
    E uma nova entrada deve ser criada na tabela "notification_log" com tipo "RESENT"
    E o campo "originalSentAt" na nova entrada deve conter "2026-07-23T01:00:00-03:00"

  Cenário: Endpoint de reenvio rejeita solicitação se a renegociação não está no status RECEIPT_SENT
    Dado que a renegociação "rng-saga-004" está no status "FAILED"
    Quando o sistema envia uma requisição POST para "/api/v1/renegotiations/rng-saga-004/notifications/resend"
    Então a API deve retornar o HTTP status code 422
    E o corpo da resposta deve conter o campo "error" com valor "INVALID_STATUS_FOR_RESEND"
    E o campo "message" deve conter "Reenvio de e-mail disponível apenas para renegociações com status RECEIPT_SENT. Status atual: FAILED"

  Cenário: Endpoint de reenvio retorna 404 para renegociação inexistente
    Quando o sistema envia uma requisição POST para "/api/v1/renegotiations/rng-nao-existe/notifications/resend"
    Então a API deve retornar o HTTP status code 404
    E o corpo da resposta deve conter o campo "error" com valor "RENEGOTIATION_NOT_FOUND"

  Cenário: Limite de reenvios por renegociação é de 3 tentativas manuais
    Dado que a renegociação "rng-reenvio-001" está no status "RECEIPT_SENT"
    E o e-mail já foi reenviado manualmente "3" vezes
    Quando o sistema envia uma requisição POST para "/api/v1/renegotiations/rng-reenvio-001/notifications/resend"
    Então a API deve retornar o HTTP status code 429
    E o corpo da resposta deve conter o campo "error" com valor "RESEND_LIMIT_EXCEEDED"
    E o campo "message" deve conter "Limite máximo de 3 reenvios manuais atingido para esta renegociação"

  # ---------------------------------------------------------------------------
  # FALHA NO ENVIO DO E-MAIL — COMPROVANTE NÃO EMITIDO
  # ---------------------------------------------------------------------------

  Cenário: E-mail NÃO é enviado se o comprovante não foi emitido (status FAILED)
    Dado que a renegociação "rng-saga-008" está no status "FAILED"
    E o evento "ReceiptEmissionFailedEvent" foi publicado para "rng-saga-008"
    Quando o consumer "notification-service" verifica os eventos pendentes para "rng-saga-008"
    Então nenhum e-mail deve ser enviado para o pagador
    E o log deve registrar "Notificação suprimida para rng-saga-008: comprovante não emitido (status: FAILED)"
    E nenhuma entrada de notificação deve ser criada na tabela "notification_log" com status "SENT"

  Cenário: E-mail NÃO é enviado se o status da renegociação é PROCESSING (emissão ainda em andamento)
    Dado que a renegociação "rng-proc-001" está no status "PROCESSING"
    Quando o serviço de notificações verifica se deve enviar e-mail para "rng-proc-001"
    Então nenhum e-mail deve ser enviado
    E o log deve registrar "Notificação adiada para rng-proc-001: aguardando emissão do comprovante"

  # ---------------------------------------------------------------------------
  # FALHA NO SERVIDOR SMTP — RETRY
  # ---------------------------------------------------------------------------

  Cenário: Falha temporária no SMTP é retentada automaticamente (2 tentativas)
    Dado que o evento "ReceiptEmittedEvent" para "rng-smtp-001" foi consumido
    E o servidor SMTP retorna erro de conexão na primeira tentativa
    E o servidor SMTP está disponível e responde na segunda tentativa
    Quando o serviço de notificações processa o evento para "rng-smtp-001"
    Então o e-mail deve ser enviado com sucesso na segunda tentativa
    E o log deve registrar "Tentativa SMTP 1 falhou para rng-smtp-001. Retentando..."
    E o log deve registrar "E-mail enviado com sucesso para rng-smtp-001 na tentativa 2"
    E o status na tabela "notification_log" deve ser "SENT"

  Cenário: Falha permanente no SMTP após 3 tentativas envia alerta e registra falha
    Dado que o evento "ReceiptEmittedEvent" para "rng-smtp-002" foi consumido
    E o servidor SMTP falha em todas as 3 tentativas de envio
    Quando o serviço de notificações esgota as retentativas para "rng-smtp-002"
    Então o e-mail não deve ser enviado
    E o status na tabela "notification_log" deve ser "FAILED"
    E o campo "failureReason" deve conter "SMTP_MAX_RETRIES_EXCEEDED"
    E a mensagem deve ser roteada para a DLQ "renegotiation.notification.dlq"
    E um alerta deve ser enviado ao tópico SNS "ops-alerts" com assunto "NOTIFICATION_FAILED"

  # ---------------------------------------------------------------------------
  # VALIDAÇÃO DE DADOS DO E-MAIL — PARAMETRIZADO
  # ---------------------------------------------------------------------------

  Esquema do Cenário: E-mail enviado com dados corretos para diferentes pagadores
    Dado que o evento "ReceiptEmittedEvent" para "<idRenegociation>" contém:
      | campo           | valor           |
      | emailPagador    | <emailPagador>  |
      | internalId      | <internalId>    |
      | externalId      | <externalId>    |
      | valorPago       | <valorPago>     |
    Quando o serviço de notificações processa o evento
    Então o e-mail deve ser enviado para "<emailPagador>"
    E o corpo do e-mail deve conter "Comprovante Interno: <internalId>"
    E o corpo do e-mail deve conter "Comprovante Externo: <externalId>"
    E o status da notificação deve ser "SENT"

    Exemplos:
      | idRenegociation | emailPagador                | internalId            | externalId            | valorPago |
      | rng-notif-001   | joao.silva@example.com      | cmp-int-aaa111bbb222  | ext-zzz999yyy888      | 250.00    |
      | rng-notif-002   | maria.souza@example.com     | cmp-int-ccc333ddd444  | ext-xxx777www666      | 1500.00   |
      | rng-notif-003   | financeiro@empresa.com.br   | cmp-int-eee555fff666  | ext-vvv555uuu444      | 8750.50   |
      | rng-notif-004   | carlos.pereira@example.com  | cmp-int-ggg777hhh888  | ext-ttt333sss222      | 99.99     |
      | rng-notif-005   | ana.lima@contabilidade.net  | cmp-int-iii999jjj000  | ext-rrr111qqq000      | 3200.00   |

  # ---------------------------------------------------------------------------
  # AUDITORIA E RASTREABILIDADE
  # ---------------------------------------------------------------------------

  Cenário: Log de notificação registra todos os metadados necessários para auditoria
    Dado que o e-mail foi enviado com sucesso para "joao.silva@example.com" para "rng-abc123def456"
    Quando o serviço de notificações registra o evento na tabela "notification_log"
    Então a entrada deve conter os seguintes campos preenchidos:
      | campo              | descrição                                 |
      | notificationId     | UUID único da notificação                 |
      | idRenegociation    | rng-abc123def456                          |
      | emailDestino       | joao.silva@example.com                    |
      | tipo               | RECEIPT_CONFIRMATION                      |
      | status             | SENT                                      |
      | sentAt             | Timestamp do envio                        |
      | messageId          | ID retornado pelo servidor SMTP/SES       |
      | internalId         | cmp-int-7f9a3b2e1d4c                      |
      | externalId         | ext-8a7b6c5d4e3f                          |
      | templateUsed       | renegotiation-receipt-notification        |

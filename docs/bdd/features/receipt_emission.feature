# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Emissão do Comprovante de Renegociação
# Domínio: PaymentRenegotiation — geração e entrega do comprovante ao pagador
# Autor: Time de Engenharia — Multiframeworks Renegociation
# Criado em: 2026-07-23
# =============================================================================

Funcionalidade: Emissão do Comprovante de Renegociação
  Como o serviço de emissão de comprovantes
  Quero gerar um comprovante com identificadores internos e externos
  E disponibilizar o PDF do comprovante via URL pré-assinada
  Para que o pagador tenha evidência formal da renegociação processada

  Contexto:
    Dado que o serviço de emissão de comprovantes está disponível
    E o sistema externo de geração de documentos está acessível
    E o bucket S3 "comprovantes-renegociacao" está disponível no LocalStack
    E a renegociação com idRenegociation "rng-abc123def456" está no status "VALIDATED"
    E o evento "BarcodeValidatedEvent" foi consumido pelo consumer "receipt-emission-service"

  # ---------------------------------------------------------------------------
  # EMISSÃO BEM-SUCEDIDA
  # ---------------------------------------------------------------------------

  Cenário: Comprovante emitido com sucesso gerando internalId e externalId
    Dado que a renegociação "rng-abc123def456" possui os dados:
      | campo         | valor                                    |
      | codigoBarra   | 34191090086352135000200006146000951037000025000 |
      | valorPago     | 250.00                                   |
      | cpfCnpj       | 12345678909                              |
      | emailPagador  | joao.silva@example.com                   |
    E o sistema externo de comprovantes está disponível e responde em menos de 3 segundos
    Quando o serviço de emissão processa a renegociação "rng-abc123def456"
    Então o comprovante deve ser criado com um "internalId" no formato UUID v4
    E o comprovante deve ser criado com um "externalId" retornado pelo sistema externo
    E o status da renegociação deve ser atualizado para "RECEIPT_SENT"
    E o evento "ReceiptEmittedEvent" deve ser publicado no tópico "renegotiation.receipt.emitted"
    E o comprovante deve ser persistido na tabela "comprovante" com status "EMITIDO"

  Cenário: Comprovante contém todos os dados corretos da renegociação
    Dado que a renegociação "rng-abc123def456" foi processada com sucesso
    E o comprovante foi gerado com internalId "cmp-int-7f9a3b2e1d4c" e externalId "ext-8a7b6c5d4e3f"
    Quando o serviço consulta os dados do comprovante pelo internalId "cmp-int-7f9a3b2e1d4c"
    Então o comprovante deve conter os seguintes campos:
      | campo                 | valor                                            |
      | internalId            | cmp-int-7f9a3b2e1d4c                             |
      | externalId            | ext-8a7b6c5d4e3f                                 |
      | idRenegociation       | rng-abc123def456                                 |
      | codigoBarra           | 34191090086352135000200006146000951037000025000   |
      | valorPago             | 250.00                                           |
      | cpfCnpj               | 12345678909                                      |
      | dataEmissao           | 2026-07-23                                       |
      | status                | EMITIDO                                          |

  Cenário: URL pré-assinada do PDF é gerada com TTL de 24 horas
    Dado que o comprovante com internalId "cmp-int-7f9a3b2e1d4c" foi emitido com sucesso
    E o arquivo PDF foi armazenado no bucket S3 "comprovantes-renegociacao"
    Quando o serviço gera a URL pré-assinada para o comprovante "cmp-int-7f9a3b2e1d4c"
    Então a URL deve iniciar com "https://comprovantes-renegociacao.s3.amazonaws.com/"
    E a URL deve conter o parâmetro "X-Amz-Expires" com valor "86400" (24 horas)
    E a URL deve conter o parâmetro "X-Amz-Signature"
    E a URL deve ser acessível e retornar o PDF com Content-Type "application/pdf"
    E o campo "pdfUrl" da resposta da API GET "/api/v1/renegotiations/rng-abc123def456" deve conter essa URL

  Cenário: Comprovante é gerado com número de protocolo único e sequencial
    Dado que os últimos 3 comprovantes gerados possuem protocolos "PRO-20260723-001", "PRO-20260723-002", "PRO-20260723-003"
    Quando o serviço de emissão processa uma nova renegociação
    Então o comprovante deve receber o protocolo "PRO-20260723-004"
    E o protocolo deve ser único no sistema

  # ---------------------------------------------------------------------------
  # SISTEMA EXTERNO INDISPONÍVEL — RETRY
  # ---------------------------------------------------------------------------

  Cenário: Sistema externo indisponível na primeira tentativa é retentado automaticamente
    Dado que a renegociação "rng-def456ghi789" está no status "VALIDATED"
    E o sistema externo de comprovantes falha na primeira tentativa com erro 503
    E o sistema externo de comprovantes responde com sucesso na segunda tentativa
    Quando o serviço de emissão tenta processar a renegociação "rng-def456ghi789"
    Então o serviço deve aguardar "2 segundos" antes da segunda tentativa (backoff exponencial)
    E o comprovante deve ser criado com sucesso na segunda tentativa
    E o status da renegociação deve ser atualizado para "RECEIPT_SENT"
    E o log deve registrar "Tentativa 1 falhou. Retentando em 2s..."
    E o log deve registrar "Tentativa 2 bem-sucedida para renegociation rng-def456ghi789"

  Cenário: Sistema externo indisponível na primeira e segunda tentativa, bem-sucedido na terceira
    Dado que a renegociação "rng-ghi789jkl012" está no status "VALIDATED"
    E o sistema externo de comprovantes falha nas tentativas 1 e 2 com erro 503
    E o sistema externo de comprovantes responde com sucesso na tentativa 3
    Quando o serviço de emissão tenta processar a renegociação "rng-ghi789jkl012"
    Então o serviço deve realizar exatamente 3 tentativas
    E o intervalo entre tentativa 1 e 2 deve ser de "2 segundos"
    E o intervalo entre tentativa 2 e 3 deve ser de "4 segundos"
    E o comprovante deve ser criado com sucesso
    E o status da renegociação deve ser "RECEIPT_SENT"

  # ---------------------------------------------------------------------------
  # SISTEMA EXTERNO FALHA 3 VEZES — COMPENSAÇÃO
  # ---------------------------------------------------------------------------

  Cenário: Sistema externo falha em todas as 3 tentativas e dispara compensação Saga
    Dado que a renegociação "rng-jkl012mno345" está no status "VALIDATED"
    E o sistema externo de comprovantes falha em todas as 3 tentativas com erro 503
    E o número máximo de tentativas configurado é 3
    Quando o serviço de emissão esgota todas as tentativas para a renegociação "rng-jkl012mno345"
    Então o serviço não deve fazer uma quarta tentativa
    E o evento "ReceiptEmissionFailedEvent" deve ser publicado no tópico "renegotiation.saga.compensate"
    E o status da renegociação deve ser atualizado para "FAILED"
    E a mensagem deve ser encaminhada para a Dead Letter Queue "renegotiation.receipt.dlq"
    E o log deve registrar "Máximo de tentativas atingido. Iniciando compensação Saga para rng-jkl012mno345"

  Cenário: Sistema externo retorna erro 400 (erro de negócio) não dispara retry mas dispara compensação imediata
    Dado que a renegociação "rng-mno345pqr678" está no status "VALIDATED"
    E o sistema externo de comprovantes retorna erro 400 com corpo:
      """
      {
        "code": "INVALID_DOCUMENT",
        "message": "CPF inválido no sistema externo"
      }
      """
    Quando o serviço de emissão tenta processar a renegociação "rng-mno345pqr678"
    Então o serviço NÃO deve realizar tentativas adicionais (erro não retentável)
    E o evento "ReceiptEmissionFailedEvent" deve ser publicado imediatamente
    E o status da renegociação deve ser atualizado para "FAILED"
    E o campo "motivoFalha" deve conter "INVALID_DOCUMENT: CPF inválido no sistema externo"

  # ---------------------------------------------------------------------------
  # DADOS DO COMPROVANTE — PARAMETRIZADO
  # ---------------------------------------------------------------------------

  Esquema do Cenário: Comprovante emitido contém dados corretos para diferentes pagadores
    Dado que a renegociação "<idRenegociation>" está no status "VALIDATED" com os dados:
      | campo        | valor          |
      | cpfCnpj      | <cpfCnpj>      |
      | valorPago    | <valorPago>    |
      | emailPagador | <emailPagador> |
    E o sistema externo está disponível
    Quando o serviço de emissão processa a renegociação "<idRenegociation>"
    Então o comprovante gerado deve conter o campo "cpfCnpj" com valor "<cpfCnpj>"
    E o comprovante gerado deve conter o campo "valorPago" com valor "<valorPago>"
    E o comprovante gerado deve conter o campo "emailPagador" com valor "<emailPagador>"
    E o status da renegociação deve ser "<statusEsperado>"

    Exemplos:
      | idRenegociation    | cpfCnpj        | valorPago | emailPagador                | statusEsperado |
      | rng-test-001       | 12345678909    | 250.00    | joao.silva@example.com      | RECEIPT_SENT   |
      | rng-test-002       | 98765432100    | 1500.00   | maria.souza@example.com     | RECEIPT_SENT   |
      | rng-test-003       | 11222333000181 | 8750.50   | financeiro@empresa.com.br   | RECEIPT_SENT   |
      | rng-test-004       | 52998224725    | 99.99     | carlos.pereira@example.com  | RECEIPT_SENT   |

  # ---------------------------------------------------------------------------
  # REEMISSÃO DE COMPROVANTE
  # ---------------------------------------------------------------------------

  Cenário: Reemissão de comprovante já emitido retorna o mesmo internalId e externalId
    Dado que o comprovante da renegociação "rng-abc123def456" já foi emitido
    E o internalId existente é "cmp-int-7f9a3b2e1d4c"
    E o externalId existente é "ext-8a7b6c5d4e3f"
    Quando o serviço de emissão recebe novamente o evento para "rng-abc123def456"
    Então o serviço deve detectar que o comprovante já existe
    E o internalId retornado deve ser "cmp-int-7f9a3b2e1d4c" (mesmo valor)
    E o externalId retornado deve ser "ext-8a7b6c5d4e3f" (mesmo valor)
    E nenhum novo documento deve ser gerado no sistema externo
    E o log deve registrar "Comprovante já emitido para rng-abc123def456. Retornando dados existentes."

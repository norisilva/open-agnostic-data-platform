# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Idempotência de Renegociações
# Domínio: PaymentRenegotiation — garantia de processamento único via Idempotency-Key
# Autor: Time de Engenharia — Multiframeworks Renegociation
# Criado em: 2026-07-23
# =============================================================================

Funcionalidade: Idempotência de Requisições de Renegociação
  Como o gateway de API do sistema de renegociação
  Quero garantir que requisições repetidas com a mesma Idempotency-Key
  Não criem múltiplas renegociações no sistema
  Para que retentativas de clientes não causem processamento duplicado

  Contexto:
    Dado que o sistema de idempotência utiliza Redis como repositório de chaves
    E o TTL padrão de uma Idempotency-Key é de 24 horas
    E o banco Redis está operacional e acessível
    E a tabela de idempotência "idempotency_keys" está disponível no banco de dados relacional
    E o sistema de renegociação está operacional

  # ---------------------------------------------------------------------------
  # MESMA IDEMPOTENCY-KEY DUPLICADA — 409
  # ---------------------------------------------------------------------------

  Cenário: Segunda requisição com a mesma Idempotency-Key retorna 409 e dados da renegociação original
    Dado que uma requisição com Idempotency-Key "550e8400-e29b-41d4-a716-446655440100" foi processada com sucesso
    E a renegociação "rng-idem-001" foi criada com status "RECEIVED"
    E a Idempotency-Key "550e8400-e29b-41d4-a716-446655440100" está armazenada no Redis com TTL de 24 horas
    Quando o cliente envia uma segunda requisição POST para "/api/v1/renegotiations" com o mesmo header "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440100"
    Então a API deve retornar o HTTP status code 409
    E o corpo da resposta deve conter o campo "error" com valor "IDEMPOTENCY_CONFLICT"
    E o corpo da resposta deve conter o campo "idRenegociation" com valor "rng-idem-001"
    E o corpo da resposta deve conter o campo "status" com valor "RECEIVED"
    E o corpo da resposta deve conter o campo "message" com valor "Requisição duplicada. A renegociação já foi criada com esta Idempotency-Key."
    E nenhuma nova renegociação deve ser criada no banco de dados
    E nenhum evento deve ser publicado no tópico Kafka "renegotiation.received"

  Cenário: Terceira requisição com a mesma Idempotency-Key ainda retorna 409 (idempotência mantida em múltiplas tentativas)
    Dado que uma requisição com Idempotency-Key "550e8400-e29b-41d4-a716-446655440101" foi processada com sucesso
    E a renegociação "rng-idem-002" foi criada com status "RECEIPT_SENT"
    E a segunda requisição com a mesma Idempotency-Key já retornou 409
    Quando o cliente envia uma terceira requisição POST com o mesmo header "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440101"
    Então a API deve retornar o HTTP status code 409
    E o corpo da resposta deve conter o campo "idRenegociation" com valor "rng-idem-002"
    E exatamente "1" renegociação deve existir no banco com essa Idempotency-Key

  Cenário: Requisição duplicada com Idempotency-Key para uma renegociação FAILED também retorna 409
    Dado que uma requisição com Idempotency-Key "550e8400-e29b-41d4-a716-446655440102" foi processada
    E a renegociação "rng-idem-003" falhou com status "FAILED"
    E a Idempotency-Key ainda está no Redis dentro do TTL de 24 horas
    Quando o cliente reenvia a requisição com o mesmo header "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440102"
    Então a API deve retornar o HTTP status code 409
    E o corpo da resposta deve conter o campo "status" com valor "FAILED"
    E o campo "message" deve orientar o cliente a usar uma nova Idempotency-Key para reprocessamento

  # ---------------------------------------------------------------------------
  # CHAVE DIFERENTE COM MESMO BARCODE — NOVA RENEGOCIAÇÃO
  # ---------------------------------------------------------------------------

  Cenário: Requisição com Idempotency-Key diferente e mesmo barcode cria nova renegociação
    Dado que a Idempotency-Key "550e8400-e29b-41d4-a716-446655440100" está no Redis (renegociação rng-idem-001 existente)
    E o barcode "34191090086352135000200006146000951037000025000" foi usado na renegociação "rng-idem-001"
    Quando o cliente envia uma nova requisição POST com Idempotency-Key "550e8400-e29b-41d4-a716-446655440200" e o mesmo barcode
    Então a API deve retornar o HTTP status code 202
    E uma nova renegociação deve ser criada com um novo idRenegociation diferente de "rng-idem-001"
    E o novo idRenegociation NÃO deve ser "rng-idem-001"
    E a nova Idempotency-Key "550e8400-e29b-41d4-a716-446655440200" deve ser armazenada no Redis
    E o evento "RenegotiationReceivedEvent" deve ser publicado para a nova renegociação

  Cenário: Múltiplas renegociações com Idempotency-Keys distintas para o mesmo barcode são todas criadas
    Dado que o barcode "34191090086352135000200006146000951037000025000" pode ser renegociado múltiplas vezes
    Quando o cliente envia 3 requisições POST com Idempotency-Keys distintas:
      | idempotency_key                      |
      | 550e8400-e29b-41d4-a716-446655440300 |
      | 550e8400-e29b-41d4-a716-446655440301 |
      | 550e8400-e29b-41d4-a716-446655440302 |
    Então "3" renegociações distintas devem ser criadas no banco de dados
    E cada renegociação deve ter um idRenegociation único
    E "3" entradas distintas devem existir na tabela de idempotência

  # ---------------------------------------------------------------------------
  # CHAVE EXPIRADA (TTL DE 24H) — REPROCESSAMENTO PERMITIDO
  # ---------------------------------------------------------------------------

  Cenário: Idempotency-Key expirada após 24 horas permite criar nova renegociação com a mesma chave
    Dado que a Idempotency-Key "550e8400-e29b-41d4-a716-446655440103" foi usada há 25 horas
    E a chave expirou do Redis (TTL de 24 horas esgotado)
    E a renegociação "rng-idem-004" criada com essa chave está no status "RECEIPT_SENT"
    Quando o cliente envia uma nova requisição POST com o mesmo header "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440103"
    Então a API deve retornar o HTTP status code 202 (nova renegociação criada)
    E uma nova renegociação deve ser criada com um novo idRenegociation
    E o novo idRenegociation deve ser diferente de "rng-idem-004"
    E a Idempotency-Key "550e8400-e29b-41d4-a716-446655440103" deve ser rearmazenada no Redis com novo TTL de 24 horas
    E o log deve registrar "Idempotency-Key reutilizada após expiração para nova renegociação"

  Cenário: Idempotency-Key expira exatamente no limite de 24 horas (caso de borda temporal)
    Dado que a Idempotency-Key "550e8400-e29b-41d4-a716-446655440104" foi criada em "2026-07-22T01:28:00-03:00"
    E a data/hora atual é "2026-07-23T01:28:01-03:00" (24 horas e 1 segundo após a criação)
    E a chave expirou do Redis
    Quando o cliente envia uma requisição POST com o header "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440104"
    Então a API deve retornar o HTTP status code 202 (tratada como nova requisição)

  Cenário: Idempotency-Key ainda válida com 23 horas e 59 minutos não permite reprocessamento
    Dado que a Idempotency-Key "550e8400-e29b-41d4-a716-446655440105" foi criada em "2026-07-22T01:29:00-03:00"
    E a data/hora atual é "2026-07-23T01:28:00-03:00" (23 horas e 59 minutos após a criação)
    E a chave ainda está ativa no Redis (TTL restante: 60 segundos)
    Quando o cliente envia uma requisição POST com o header "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440105"
    Então a API deve retornar o HTTP status code 409
    E o campo "ttlRestante" deve conter "60" segundos (aproximadamente)

  # ---------------------------------------------------------------------------
  # FORMATO E VALIDAÇÃO DA IDEMPOTENCY-KEY
  # ---------------------------------------------------------------------------

  Esquema do Cenário: Idempotency-Key com formato inválido é rejeitada
    Dado que o cliente envia uma requisição POST com o header "Idempotency-Key: <chave_invalida>"
    Quando a API valida o header "Idempotency-Key"
    Então a API deve retornar o HTTP status code 400
    E o corpo da resposta deve conter o campo "error" com valor "INVALID_IDEMPOTENCY_KEY_FORMAT"
    E o corpo da resposta deve conter a mensagem "<mensagem_erro>"

    Exemplos:
      | chave_invalida               | mensagem_erro                               |
      | chave-muito-curta            | Idempotency-Key: deve ser um UUID v4 válido |
      | 123456789                    | Idempotency-Key: deve ser um UUID v4 válido |
      | nao-e-um-uuid-valido-aqui    | Idempotency-Key: deve ser um UUID v4 válido |
      | 550e8400-e29b-41d4-a716      | Idempotency-Key: UUID incompleto            |

  # ---------------------------------------------------------------------------
  # CONCORRÊNCIA — RACE CONDITION
  # ---------------------------------------------------------------------------

  Cenário: Duas requisições simultâneas com a mesma Idempotency-Key — apenas uma é processada
    Dado que o mecanismo de lock distribuído está habilitado para a Idempotency-Key "550e8400-e29b-41d4-a716-446655440106"
    Quando duas requisições POST chegam simultaneamente com o header "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440106"
    Então exatamente "1" renegociação deve ser criada no banco de dados
    E uma das requisições deve retornar HTTP status code 202
    E a outra requisição deve retornar HTTP status code 409
    E o lock distribuído deve ser liberado após o processamento

  # ---------------------------------------------------------------------------
  # AUDITORIA DE IDEMPOTÊNCIA
  # ---------------------------------------------------------------------------

  Cenário: Todas as Idempotency-Keys são registradas na tabela de auditoria para rastreabilidade
    Dado que o sistema recebe uma requisição com Idempotency-Key "550e8400-e29b-41d4-a716-446655440107"
    Quando a requisição é processada com sucesso e a renegociação "rng-idem-005" é criada
    Então uma entrada deve ser criada na tabela "idempotency_keys" com os seguintes dados:
      | campo             | valor                                    |
      | idempotencyKey    | 550e8400-e29b-41d4-a716-446655440107     |
      | idRenegociation   | rng-idem-005                             |
      | createdAt         | (timestamp atual)                        |
      | expiresAt         | (timestamp atual + 24 horas)             |
      | status            | ACTIVE                                   |
    E quando a chave expirar, o status na tabela deve ser atualizado para "EXPIRED"

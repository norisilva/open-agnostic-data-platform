# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Iniciando uma Renegociação de Pagamento
# Domínio: PaymentRenegotiation — dívidas com atraso superior a 180 dias
# Autor: Time de Engenharia — Multiframeworks Renegociation
# Criado em: 2026-07-23
# =============================================================================

Funcionalidade: Iniciando uma Renegociação de Pagamento
  Como um pagador com dívidas em atraso superior a 180 dias
  Quero submeter uma solicitação de renegociação via API
  Para que minha dívida seja registrada, validada e um comprovante seja emitido

  Contexto:
    Dado que o sistema de renegociação está operacional
    E o serviço de validação de barcode está disponível
    E o serviço de emissão de comprovantes está disponível
    E o banco de dados de idempotência está acessível
    E o tópico Kafka "renegotiation.received" está disponível

  # ---------------------------------------------------------------------------
  # HAPPY PATH
  # ---------------------------------------------------------------------------

  Cenário: Renegociação submetida com sucesso para dívida acima de 180 dias
    Dado que o pagador com CPF "123.456.789-09" possui uma dívida com atraso de 200 dias
    E o barcode "34191.09008 63521.350002 00061.460009 5 10370000025000" é válido no formato FEBRABAN
    E o valor pago "R$ 250,00" é positivo
    E o header "Idempotency-Key" possui o valor "550e8400-e29b-41d4-a716-446655440001"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo:
      """
      {
        "codigoBarra": "34191090086352135000200006146000951037000002500",
        "valorPago": 250.00,
        "cpfCnpj": "12345678909",
        "emailPagador": "joao.silva@example.com"
      }
      """
    Então a API deve retornar o HTTP status code 202
    E o corpo da resposta deve conter o campo "idRenegociation" não nulo
    E o corpo da resposta deve conter o campo "status" com valor "RECEIVED"
    E o evento "RenegotiationReceivedEvent" deve ser publicado no tópico Kafka "renegotiation.received"
    E a renegociação deve ser persistida no banco de dados com status "RECEIVED"

  Cenário: Renegociação aceita para valor exato de R$ 0,01 (limite mínimo positivo)
    Dado que o pagador com CPF "987.654.321-00" possui uma dívida com atraso de 185 dias
    E o barcode "34191.09008 63521.350002 00061.460009 5 10370000000001" é válido no formato FEBRABAN
    E o header "Idempotency-Key" possui o valor "550e8400-e29b-41d4-a716-446655440002"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo:
      """
      {
        "codigoBarra": "34191090086352135000200006146000951037000000001",
        "valorPago": 0.01,
        "cpfCnpj": "98765432100",
        "emailPagador": "maria.souza@example.com"
      }
      """
    Então a API deve retornar o HTTP status code 202
    E o corpo da resposta deve conter o campo "status" com valor "RECEIVED"

  Cenário: Renegociação aceita com CNPJ válido como identificador do pagador
    Dado que a empresa com CNPJ "11.222.333/0001-81" possui uma dívida com atraso de 210 dias
    E o barcode "34191.09008 63521.350002 00061.460009 5 10370000150000" é válido no formato FEBRABAN
    E o header "Idempotency-Key" possui o valor "550e8400-e29b-41d4-a716-446655440003"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo:
      """
      {
        "codigoBarra": "34191090086352135000200006146000951037000150000",
        "valorPago": 1500.00,
        "cpfCnpj": "11222333000181",
        "emailPagador": "financeiro@empresa.com.br"
      }
      """
    Então a API deve retornar o HTTP status code 202
    E o corpo da resposta deve conter o campo "status" com valor "RECEIVED"

  # ---------------------------------------------------------------------------
  # CAMPOS INVÁLIDOS
  # ---------------------------------------------------------------------------

  Cenário: Rejeição quando o campo emailPagador está em formato inválido
    Dado que o pagador com CPF "111.444.777-35" possui uma dívida com atraso de 190 dias
    E o header "Idempotency-Key" possui o valor "550e8400-e29b-41d4-a716-446655440004"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo:
      """
      {
        "codigoBarra": "34191090086352135000200006146000951037000025000",
        "valorPago": 250.00,
        "cpfCnpj": "11144477735",
        "emailPagador": "email-invalido-sem-arroba"
      }
      """
    Então a API deve retornar o HTTP status code 422
    E o corpo da resposta deve conter o campo "error" com valor "VALIDATION_ERROR"
    E o corpo da resposta deve conter a mensagem "emailPagador: formato de e-mail inválido"
    E nenhum evento deve ser publicado no tópico Kafka "renegotiation.received"

  Cenário: Rejeição quando o cpfCnpj não possui dígito verificador válido
    Dado que o header "Idempotency-Key" possui o valor "550e8400-e29b-41d4-a716-446655440005"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo:
      """
      {
        "codigoBarra": "34191090086352135000200006146000951037000025000",
        "valorPago": 250.00,
        "cpfCnpj": "11111111111",
        "emailPagador": "pagador@example.com"
      }
      """
    Então a API deve retornar o HTTP status code 422
    E o corpo da resposta deve conter o campo "error" com valor "VALIDATION_ERROR"
    E o corpo da resposta deve conter a mensagem "cpfCnpj: documento inválido"

  Cenário: Rejeição quando o campo codigoBarra está no formato incorreto
    Dado que o pagador com CPF "123.456.789-09" possui uma dívida com atraso de 200 dias
    E o header "Idempotency-Key" possui o valor "550e8400-e29b-41d4-a716-446655440006"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo:
      """
      {
        "codigoBarra": "BARCODE_INVALIDO_ABC",
        "valorPago": 250.00,
        "cpfCnpj": "12345678909",
        "emailPagador": "joao.silva@example.com"
      }
      """
    Então a API deve retornar o HTTP status code 422
    E o corpo da resposta deve conter o campo "error" com valor "VALIDATION_ERROR"
    E o corpo da resposta deve conter a mensagem "codigoBarra: formato FEBRABAN inválido"

  # ---------------------------------------------------------------------------
  # CAMPOS OBRIGATÓRIOS AUSENTES
  # ---------------------------------------------------------------------------

  Esquema do Cenário: Rejeição quando campo obrigatório está ausente
    Dado que o header "Idempotency-Key" possui o valor "<idempotency_key>"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo "<corpo_json>"
    Então a API deve retornar o HTTP status code 400
    E o corpo da resposta deve conter o campo "error" com valor "MISSING_REQUIRED_FIELD"
    E o corpo da resposta deve conter a mensagem "<mensagem_erro>"

    Exemplos:
      | idempotency_key                      | corpo_json                                                                                                              | mensagem_erro                        |
      | 550e8400-e29b-41d4-a716-446655440010 | {"valorPago":250.00,"cpfCnpj":"12345678909","emailPagador":"a@b.com"}                                                  | codigoBarra: campo obrigatório       |
      | 550e8400-e29b-41d4-a716-446655440011 | {"codigoBarra":"34191090086352135000200006146000951037000025000","cpfCnpj":"12345678909","emailPagador":"a@b.com"}      | valorPago: campo obrigatório         |
      | 550e8400-e29b-41d4-a716-446655440012 | {"codigoBarra":"34191090086352135000200006146000951037000025000","valorPago":250.00,"emailPagador":"a@b.com"}           | cpfCnpj: campo obrigatório           |
      | 550e8400-e29b-41d4-a716-446655440013 | {"codigoBarra":"34191090086352135000200006146000951037000025000","valorPago":250.00,"cpfCnpj":"12345678909"}            | emailPagador: campo obrigatório      |
      | 550e8400-e29b-41d4-a716-446655440014 | {}                                                                                                                      | campos obrigatórios ausentes         |

  # ---------------------------------------------------------------------------
  # VALOR INVÁLIDO (NEGATIVO / ZERO)
  # ---------------------------------------------------------------------------

  Esquema do Cenário: Rejeição quando valorPago é inválido (negativo ou zero)
    Dado que o pagador com CPF "123.456.789-09" possui uma dívida com atraso de 200 dias
    E o header "Idempotency-Key" possui o valor "<idempotency_key>"
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" com o corpo:
      """
      {
        "codigoBarra": "34191090086352135000200006146000951037000025000",
        "valorPago": <valor>,
        "cpfCnpj": "12345678909",
        "emailPagador": "joao.silva@example.com"
      }
      """
    Então a API deve retornar o HTTP status code 422
    E o corpo da resposta deve conter o campo "error" com valor "VALIDATION_ERROR"
    E o corpo da resposta deve conter a mensagem "<mensagem_erro>"
    E nenhum evento deve ser publicado no tópico Kafka "renegotiation.received"

    Exemplos:
      | idempotency_key                      | valor    | mensagem_erro                                       |
      | 550e8400-e29b-41d4-a716-446655440020 | 0.00     | valorPago: deve ser maior que zero                  |
      | 550e8400-e29b-41d4-a716-446655440021 | -1.00    | valorPago: deve ser maior que zero                  |
      | 550e8400-e29b-41d4-a716-446655440022 | -999.99  | valorPago: deve ser maior que zero                  |
      | 550e8400-e29b-41d4-a716-446655440023 | -0.01    | valorPago: deve ser maior que zero                  |

  # ---------------------------------------------------------------------------
  # HEADER OBRIGATÓRIO AUSENTE
  # ---------------------------------------------------------------------------

  Cenário: Rejeição quando o header Idempotency-Key está ausente
    Dado que o pagador com CPF "123.456.789-09" possui uma dívida com atraso de 200 dias
    Quando o pagador envia uma requisição POST para "/api/v1/renegotiations" sem o header "Idempotency-Key" com o corpo:
      """
      {
        "codigoBarra": "34191090086352135000200006146000951037000025000",
        "valorPago": 250.00,
        "cpfCnpj": "12345678909",
        "emailPagador": "joao.silva@example.com"
      }
      """
    Então a API deve retornar o HTTP status code 400
    E o corpo da resposta deve conter o campo "error" com valor "MISSING_REQUIRED_HEADER"
    E o corpo da resposta deve conter a mensagem "Idempotency-Key: header obrigatório ausente"

  # ---------------------------------------------------------------------------
  # CONSULTA DE STATUS
  # ---------------------------------------------------------------------------

  Cenário: Consulta de status de renegociação existente retorna dados completos
    Dado que existe uma renegociação com idRenegociation "rng-abc123def456" e status "PROCESSING"
    Quando o sistema envia uma requisição GET para "/api/v1/renegotiations/rng-abc123def456"
    Então a API deve retornar o HTTP status code 200
    E o corpo da resposta deve conter o campo "idRenegociation" com valor "rng-abc123def456"
    E o corpo da resposta deve conter o campo "status" com valor "PROCESSING"
    E o corpo da resposta deve conter o campo "cpfCnpj"
    E o corpo da resposta deve conter o campo "createdAt"

  Cenário: Consulta de renegociação inexistente retorna 404
    Quando o sistema envia uma requisição GET para "/api/v1/renegotiations/rng-nao-existe-000"
    Então a API deve retornar o HTTP status code 404
    E o corpo da resposta deve conter o campo "error" com valor "RENEGOTIATION_NOT_FOUND"

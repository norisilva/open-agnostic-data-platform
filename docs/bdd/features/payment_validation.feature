# language: pt
# encoding: UTF-8
# =============================================================================
# Feature: Validação do Barcode FEBRABAN
# Domínio: PaymentRenegotiation — validação estrutural e de negócio do código de barras
# Autor: Time de Engenharia — Multiframeworks Renegociation
# Criado em: 2026-07-23
# =============================================================================

Funcionalidade: Validação do Código de Barras FEBRABAN
  Como o serviço de validação de renegociações
  Quero garantir que o código de barras submetido seja estruturalmente válido no padrão FEBRABAN
  E que a dívida associada ao barcode possua atraso superior a 180 dias
  Para que apenas renegociações elegíveis sejam processadas

  Contexto:
    Dado que o serviço de validação de barcode está disponível
    E o serviço de consulta de dívidas está operacional
    E o banco de dados de dívidas está acessível
    E a data de referência para cálculo de atraso é "2026-07-23"

  # ---------------------------------------------------------------------------
  # BARCODE FEBRABAN VÁLIDO
  # ---------------------------------------------------------------------------

  Cenário: Barcode válido no padrão FEBRABAN com 47 dígitos é aceito
    Dado que o barcode "34191090086352135000200006146000951037000025000" possui 47 dígitos numéricos
    E o dígito verificador do barcode é calculado corretamente pelo módulo 10
    E a dívida associada ao barcode possui data de vencimento "2026-01-02" (atraso de 202 dias)
    Quando o serviço de validação processa o barcode "34191090086352135000200006146000951037000025000"
    Então o resultado da validação deve ser "VÁLIDO"
    E o campo "diasAtraso" deve retornar o valor 202
    E o campo "valorOriginal" deve retornar 250.00
    E o evento "BarcodeValidatedEvent" deve ser publicado no tópico "renegotiation.validated"

  Cenário: Barcode da linha digitável (com pontuação) é normalizado e aceito
    Dado que o barcode informado é "34191.09008 63521.350002 00061.460009 5 10370000025000" (linha digitável)
    E a dívida associada possui atraso de 202 dias
    Quando o serviço de validação normaliza e processa o barcode
    Então o barcode deve ser convertido para o formato numérico "34191090086352135000200006146000951037000025000"
    E o resultado da validação deve ser "VÁLIDO"

  # ---------------------------------------------------------------------------
  # DÍGITO VERIFICADOR INVÁLIDO
  # ---------------------------------------------------------------------------

  Cenário: Barcode com dígito verificador incorreto é rejeitado
    Dado que o barcode "34191090086352135000200006146000051037000025000" possui dígito verificador "0" na posição 20
    E o dígito verificador esperado para esse barcode é "9"
    Quando o serviço de validação processa o barcode "34191090086352135000200006146000051037000025000"
    Então o resultado da validação deve ser "INVÁLIDO"
    E o campo "motivoRejeicao" deve retornar "DIGITO_VERIFICADOR_INCORRETO"
    E o evento "BarcodeRejectedEvent" deve ser publicado no tópico "renegotiation.rejected"
    E a renegociação deve ter status atualizado para "FAILED"

  # ---------------------------------------------------------------------------
  # DÍVIDA COM ATRASO INSUFICIENTE (MENOR QUE 180 DIAS)
  # ---------------------------------------------------------------------------

  Cenário: Barcode estruturalmente válido mas dívida com atraso de 179 dias é rejeitado
    Dado que o barcode "34191090086352135000200006146000951037000050000" é estruturalmente válido
    E a dívida associada ao barcode possui data de vencimento "2026-01-24" (atraso de 179 dias)
    Quando o serviço de validação processa o barcode "34191090086352135000200006146000951037000050000"
    Então o resultado da validação deve ser "INVÁLIDO"
    E o campo "motivoRejeicao" deve retornar "ATRASO_INSUFICIENTE"
    E o campo "diasAtraso" deve retornar o valor 179
    E a mensagem de erro deve conter "A dívida possui apenas 179 dias de atraso. Mínimo exigido: 180 dias"
    E o evento "BarcodeRejectedEvent" deve ser publicado no tópico "renegotiation.rejected"

  Cenário: Dívida com 90 dias de atraso (muito abaixo do mínimo) é rejeitada
    Dado que o barcode "34191090086352135000200006146000951037000075000" é estruturalmente válido
    E a dívida associada ao barcode possui data de vencimento "2026-04-23" (atraso de 90 dias)
    Quando o serviço de validação processa o barcode "34191090086352135000200006146000951037000075000"
    Então o resultado da validação deve ser "INVÁLIDO"
    E o campo "motivoRejeicao" deve retornar "ATRASO_INSUFICIENTE"
    E o campo "diasAtraso" deve retornar o valor 90

  # ---------------------------------------------------------------------------
  # CASO LIMITE: DÍVIDA EXATAMENTE COM 180 DIAS (BOUNDARY VALUE)
  # ---------------------------------------------------------------------------

  Cenário: Dívida com exatamente 180 dias de atraso está no limite e é rejeitada (regra: estritamente maior que 180)
    Dado que o barcode "34191090086352135000200006146000951037000100000" é estruturalmente válido
    E a dívida associada ao barcode possui data de vencimento "2026-01-23" (atraso de exatamente 180 dias)
    Quando o serviço de validação processa o barcode "34191090086352135000200006146000951037000100000"
    Então o resultado da validação deve ser "INVÁLIDO"
    E o campo "motivoRejeicao" deve retornar "ATRASO_INSUFICIENTE"
    E a mensagem de erro deve conter "A dívida possui apenas 180 dias de atraso. Mínimo exigido: mais de 180 dias"

  Cenário: Dívida com exatamente 181 dias de atraso atende ao critério mínimo e é aceita
    Dado que o barcode "34191090086352135000200006146000951037000120000" é estruturalmente válido
    E a dívida associada ao barcode possui data de vencimento "2026-01-22" (atraso de exatamente 181 dias)
    Quando o serviço de validação processa o barcode "34191090086352135000200006146000951037000120000"
    Então o resultado da validação deve ser "VÁLIDO"
    E o campo "diasAtraso" deve retornar o valor 181
    E o evento "BarcodeValidatedEvent" deve ser publicado no tópico "renegotiation.validated"

  # ---------------------------------------------------------------------------
  # TAMANHO INCORRETO DO BARCODE
  # ---------------------------------------------------------------------------

  Esquema do Cenário: Barcode com comprimento diferente de 47 dígitos é rejeitado
    Dado que o barcode "<barcode>" possui "<quantidade_digitos>" dígitos
    Quando o serviço de validação processa o barcode "<barcode>"
    Então o resultado da validação deve ser "INVÁLIDO"
    E o campo "motivoRejeicao" deve retornar "COMPRIMENTO_INVALIDO"
    E a mensagem de erro deve conter "codigoBarra: comprimento inválido. Esperado: 47 dígitos, recebido: <quantidade_digitos>"

    Exemplos:
      | barcode                                         | quantidade_digitos |
      | 3419109008635213500020000614600095103700002500   | 46                 |
      | 341910900863521350002000061460009510370000250001 | 48                 |
      | 3419109                                         | 7                  |
      | 3419109008635213500020000614600095103700002500000000 | 51              |

  # ---------------------------------------------------------------------------
  # BARCODE COM ESPAÇOS / CARACTERES NÃO NUMÉRICOS
  # ---------------------------------------------------------------------------

  Cenário: Barcode com espaços internos após normalização mantém o comprimento correto e é aceito
    Dado que o barcode informado é "34191 09008 63521 35000 20000 61460 00951 03700 0025000"
    E após remoção de espaços resulta em "34191090086352135000200006146000951037000025000" com 47 dígitos
    E a dívida associada possui atraso de 200 dias
    Quando o serviço de validação normaliza e processa o barcode
    Então o resultado da validação deve ser "VÁLIDO"

  Cenário: Barcode com caracteres alfabéticos é rejeitado imediatamente
    Dado que o barcode informado é "34191A9008B3521C5000D0000E1460F0095103G000025000"
    Quando o serviço de validação processa o barcode "34191A9008B3521C5000D0000E1460F0095103G000025000"
    Então o resultado da validação deve ser "INVÁLIDO"
    E o campo "motivoRejeicao" deve retornar "CARACTERES_NAO_NUMERICOS"
    E a mensagem de erro deve conter "codigoBarra: contém caracteres não numéricos"

  Cenário: Barcode vazio é rejeitado com mensagem específica
    Dado que o barcode informado é "" (vazio)
    Quando o serviço de validação processa o barcode vazio
    Então o resultado da validação deve ser "INVÁLIDO"
    E o campo "motivoRejeicao" deve retornar "BARCODE_VAZIO"
    E a mensagem de erro deve conter "codigoBarra: não pode ser nulo ou vazio"

  # ---------------------------------------------------------------------------
  # VALIDAÇÃO COMBINADA POR PARÂMETROS
  # ---------------------------------------------------------------------------

  Esquema do Cenário: Validação de múltiplos barcodes com diferentes cenários de atraso
    Dado que o barcode "<barcode>" é estruturalmente válido
    E a dívida associada possui "<dias_atraso>" dias de atraso
    Quando o serviço de validação processa o barcode "<barcode>"
    Então o resultado da validação deve ser "<resultado>"
    E o campo "diasAtraso" deve retornar o valor <dias_atraso>

    Exemplos:
      | barcode                                         | dias_atraso | resultado |
      | 34191090086352135000200006146000951037000025000  | 365         | VÁLIDO    |
      | 34191090086352135000200006146000951037000050000  | 730         | VÁLIDO    |
      | 34191090086352135000200006146000951037000075000  | 181         | VÁLIDO    |
      | 34191090086352135000200006146000951037000100000  | 180         | INVÁLIDO  |
      | 34191090086352135000200006146000951037000120000  | 150         | INVÁLIDO  |
      | 34191090086352135000200006146000951037000150000  | 90          | INVÁLIDO  |
      | 34191090086352135000200006146000951037000175000  | 0           | INVÁLIDO  |

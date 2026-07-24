# BDD — Multiframeworks Renegociation

> Documentação dos testes de Behavior-Driven Development (BDD) para o sistema de renegociação de dívidas em atraso superior a 180 dias.

---

## Índice

1. [Visão Geral](#visão-geral)
2. [Estrutura de Diretórios](#estrutura-de-diretórios)
3. [Fluxo de Status da Renegociação](#fluxo-de-status-da-renegociação)
4. [Feature Files](#feature-files)
5. [Configuração do Ambiente](#configuração-do-ambiente)
6. [Dependência: LocalStack](#dependência-localstack)
7. [Dados de Teste](#dados-de-teste)
8. [Executando com Cucumber (Java)](#executando-com-cucumber-java)
9. [Executando com gotestsum (Go)](#executando-com-gotestsum-go)
10. [Integração CI/CD](#integração-cicd)
11. [Convenções de Escrita](#convenções-de-escrita)

---

## Visão Geral

Este diretório contém os **Feature Files** em Gherkin (pt-BR) que descrevem o comportamento esperado do sistema de renegociação de pagamentos. Os cenários cobrem:

| Feature                     | Arquivo                          | Cenários |
|-----------------------------|----------------------------------|----------|
| Iniciando Renegociação      | `renegotiation_payment.feature`  | 13       |
| Validação de Barcode        | `payment_validation.feature`     | 14       |
| Emissão de Comprovante      | `receipt_emission.feature`       | 13       |
| Compensação Saga            | `saga_compensation.feature`      | 14       |
| Idempotência                | `idempotency.feature`            | 13       |
| Notificação do Pagador      | `notification.feature`           | 16       |

---

## Estrutura de Diretórios

```
docs/bdd/
├── README.md                          # Este arquivo
└── features/
    ├── renegotiation_payment.feature  # Submissão e consulta de renegociações
    ├── payment_validation.feature     # Validação FEBRABAN do barcode
    ├── receipt_emission.feature       # Emissão e reemissão do comprovante
    ├── saga_compensation.feature      # Compensação distribuída (Saga Choreography)
    ├── idempotency.feature            # Controle de idempotência com Redis
    └── notification.feature           # Envio de e-mail ao pagador
```

Para os step definitions (implementações dos passos Gherkin), consulte:

```
# Java (Spring Boot / Cucumber)
src/test/java/br/com/renegociacao/bdd/steps/

# Go (Godog)
test/bdd/steps/
```

---

## Fluxo de Status da Renegociação

```
                    ┌──────────────────────────────────────────────────────────┐
                    │                 FLUXO PRINCIPAL (happy path)             │
                    └──────────────────────────────────────────────────────────┘

  POST /api/v1/renegotiations
          │
          ▼
    ┌──────────┐   Kafka: renegotiation.received    ┌─────────────┐
    │ RECEIVED │ ──────────────────────────────────▶│  PROCESSING │
    └──────────┘                                    └─────────────┘
                                                           │
                                          Kafka: renegotiation.validated
                                                           │
                                                           ▼
                                                   ┌───────────────┐
                                                   │   VALIDATED   │
                                                   └───────────────┘
                                                           │
                                       Kafka: renegotiation.receipt.emitted
                                                           │
                                                           ▼
                                                  ┌────────────────┐
                                                  │  RECEIPT_SENT  │ ◀── Estado final de sucesso
                                                  └────────────────┘

                    ┌──────────────────────────────────────────────────────────┐
                    │                 FLUXO DE FALHA (compensação)             │
                    └──────────────────────────────────────────────────────────┘

  Qualquer etapa pode falhar
          │
          ▼
      ┌────────┐   Kafka: renegotiation.saga.compensate   ┌─────────────┐
      │ FAILED │ ─────────────────────────────────────────▶ COMPENSATED │
      └────────┘                                          └─────────────┘
          │
          ▼
      DLQ (Dead Letter Queue)
```

---

## Feature Files

### 1. `renegotiation_payment.feature`
Cobre o ciclo de vida completo da submissão de uma renegociação via `POST /api/v1/renegotiations`.

**Cenários principais:**
- Happy path: renegociação aceita com CPF, CNPJ, valor mínimo (R$ 0,01)
- Campos inválidos: e-mail, CPF com dígito verificador errado, barcode malformado
- Campos obrigatórios ausentes (Scenario Outline com Examples table)
- valorPago negativo e zero (Scenario Outline)
- Header `Idempotency-Key` ausente
- Consulta de status: `GET /api/v1/renegotiations/{id}`

### 2. `payment_validation.feature`
Cobre a validação estrutural e de negócio do código de barras FEBRABAN.

**Cenários principais:**
- Barcode 47 dígitos válido com dígito verificador correto (módulo 10)
- Linha digitável com pontuação é normalizada
- Dígito verificador incorreto → rejeição
- Dívida < 180 dias → `ATRASO_INSUFICIENTE`
- Boundary: exatamente 180 dias → rejeitado; 181 dias → aceito
- Comprimento inválido (Scenario Outline: 46, 48, 7, 51 dígitos)
- Caracteres não numéricos, barcode com espaços, barcode vazio
- Matriz de validação diasAtraso × resultado (Scenario Outline)

### 3. `receipt_emission.feature`
Cobre a geração do `Comprovante` com `internalId` e `externalId`.

**Cenários principais:**
- Emissão bem-sucedida, persistência e evento publicado
- Dados do comprovante completos e corretos
- URL pré-assinada S3 com TTL de 24 horas
- Número de protocolo sequencial
- Sistema externo indisponível: retry na 2ª tentativa, retry na 3ª tentativa
- Sistema externo falha 3x → compensação Saga + DLQ
- Erro 400 do externo (não retentável) → compensação imediata
- Reemissão idempotente retorna mesmo `internalId`/`externalId`

### 4. `saga_compensation.feature`
Cobre o padrão Saga Choreography para rollback distribuído.

**Cenários principais:**
- Timeout no validador de barcode → `BarcodeValidationTimeoutEvent` → status `FAILED`
- Timeout temporário (3ª tentativa com sucesso) → sem compensação
- Falha na emissão → rollback de `VALIDATED` para `FAILED`
- Alerta SNS para o time de operações
- Sucesso parcial: barcode validado, comprovante falha
- Falha de persistência interna após sucesso no externo → cancelamento no externo
- DLQ routing por etapa de falha (Scenario Outline)
- Idempotência da compensação (mesmo evento processado 2x)
- Status `COMPENSATED` após compensação completa

### 5. `idempotency.feature`
Cobre o controle de idempotência via header `Idempotency-Key` com Redis.

**Cenários principais:**
- 2ª requisição com mesma chave → 409 com dados da renegociação original
- 3ª requisição → ainda 409 (consistência)
- Renegociação `FAILED` + mesma chave → 409
- Chave diferente, mesmo barcode → nova renegociação (202)
- 3 chaves distintas → 3 renegociações distintas
- Chave expirada (25h) → 202 (nova renegociação)
- Boundary TTL: 24h+1s → expirado; 23h59m → ainda ativo (409)
- Formato UUID v4 inválido → 400 (Scenario Outline)
- Race condition com lock distribuído
- Auditoria na tabela `idempotency_keys`

### 6. `notification.feature`
Cobre o envio de e-mail de confirmação ao pagador após emissão do comprovante.

**Cenários principais:**
- E-mail enviado após `ReceiptEmittedEvent`
- Corpo do e-mail contém `internalId`, `externalId`, link PDF
- CPF mascarado no e-mail (`***.456.789-**`)
- CNPJ mascarado (`**.222.333/0001-**`)
- Endpoint `POST /resend` funciona para status `RECEIPT_SENT`
- Reenvio rejeita status `FAILED` → 422
- Reenvio rejeita renegociação inexistente → 404
- Limite de 3 reenvios manuais → 429
- E-mail NÃO enviado para status `FAILED` e `PROCESSING`
- Retry SMTP em falha temporária (2ª tentativa)
- SMTP falha 3x → DLQ + alerta SNS
- Dados para múltiplos pagadores (Scenario Outline)
- Auditoria completa na tabela `notification_log`

---

## Configuração do Ambiente

### Variáveis de Ambiente

```bash
# Banco de dados
DB_HOST=localhost
DB_PORT=5432
DB_NAME=renegociacao_db
DB_USER=renegociacao_user
DB_PASSWORD=renegociacao_pass

# Redis (idempotência)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_TTL_SECONDS=86400

# Kafka
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_CONSUMER_GROUP_ID=renegociacao-bdd-test
KAFKA_TOPIC_RECEIVED=renegotiation.received
KAFKA_TOPIC_VALIDATED=renegotiation.validated
KAFKA_TOPIC_EMITTED=renegotiation.receipt.emitted
KAFKA_TOPIC_COMPENSATE=renegotiation.saga.compensate
KAFKA_TOPIC_DLQ=renegotiation.dlq

# LocalStack (AWS mock)
LOCALSTACK_ENDPOINT=http://localhost:4566
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
S3_BUCKET_COMPROVANTES=comprovantes-renegociacao
SNS_TOPIC_OPS_ALERTS=arn:aws:sns:us-east-1:000000000000:ops-alerts

# SMTP (SES via LocalStack)
SES_ENDPOINT=http://localhost:4566
EMAIL_FROM=noreply@renegociacao.com.br
EMAIL_TEMPLATE=renegotiation-receipt-notification

# Sistema externo de comprovantes
EXTERNAL_RECEIPT_URL=http://localhost:8081/api/receipts
EXTERNAL_RECEIPT_TIMEOUT_SECONDS=5
EXTERNAL_RECEIPT_MAX_RETRIES=3

# API do serviço
API_BASE_URL=http://localhost:8080
```

---

## Dependência: LocalStack

O LocalStack simula os serviços AWS necessários para os testes de integração BDD. Utilize o `docker-compose` para iniciar:

```yaml
# docker-compose.localstack.yml
version: '3.8'
services:
  localstack:
    image: localstack/localstack:3.4
    container_name: localstack-renegociacao
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,sqs,sns,ses,secretsmanager
      - DEFAULT_REGION=us-east-1
      - DEBUG=1
      - DATA_DIR=/var/lib/localstack/data
    volumes:
      - ./infra/localstack/init-scripts:/etc/localstack/init/ready.d
      - localstack_data:/var/lib/localstack

  redis:
    image: redis:7.2-alpine
    container_name: redis-renegociacao
    ports:
      - "6379:6379"

  kafka:
    image: confluentinc/cp-kafka:7.6.0
    container_name: kafka-renegociacao
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_LOG_RETENTION_MS: 86400000

  zookeeper:
    image: confluentinc/cp-zookeeper:7.6.0
    container_name: zookeeper-renegociacao
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

volumes:
  localstack_data:
```

**Inicialização dos recursos AWS:**

```bash
# Script de inicialização LocalStack (infra/localstack/init-scripts/01-setup.sh)

#!/bin/bash
set -e

echo "Criando bucket S3..."
aws --endpoint-url=http://localhost:4566 s3 mb s3://comprovantes-renegociacao

echo "Configurando política de CORS no bucket..."
aws --endpoint-url=http://localhost:4566 s3api put-bucket-cors \
  --bucket comprovantes-renegociacao \
  --cors-configuration file:///etc/localstack/cors-policy.json

echo "Criando tópico SNS para alertas..."
aws --endpoint-url=http://localhost:4566 sns create-topic \
  --name ops-alerts

echo "Verificando identidade SES..."
aws --endpoint-url=http://localhost:4566 ses verify-email-identity \
  --email-address noreply@renegociacao.com.br

echo "LocalStack inicializado com sucesso."
```

**Subindo o ambiente:**

```bash
# Subir todos os serviços
docker-compose -f docker-compose.localstack.yml up -d

# Aguardar LocalStack estar saudável
docker wait localstack-renegociacao || true
curl -s http://localhost:4566/_localstack/health | jq .services
```

---

## Dados de Teste

### CPFs Válidos para Testes

| CPF (formatado)   | CPF (numérico) | Uso                          |
|-------------------|----------------|------------------------------|
| 123.456.789-09    | 12345678909    | Pagador pessoa física padrão |
| 987.654.321-00    | 98765432100    | Pagador alternativo          |
| 111.444.777-35    | 11144477735    | Validação de e-mail inválido |
| 529.982.247-25    | 52998224725    | Testes de comprovante        |

### CNPJs Válidos para Testes

| CNPJ (formatado)      | CNPJ (numérico) | Uso                     |
|-----------------------|-----------------|-------------------------|
| 11.222.333/0001-81    | 11222333000181  | Empresa padrão          |
| 84.684.620/0001-42    | 84684620000142  | Empresa alternativa     |

### Barcodes FEBRABAN Válidos (47 dígitos)

| Barcode                                         | Valor (R$) | Banco     | Produto |
|-------------------------------------------------|------------|-----------|---------|
| 34191090086352135000200006146000951037000025000  | 250,00     | Itaú (341)| Boleto  |
| 34191090086352135000200006146000951037000000001  | 0,01       | Itaú (341)| Boleto  |
| 34191090086352135000200006146000951037000150000  | 1.500,00   | Itaú (341)| Boleto  |
| 34191090086352135000200006146000951037000050000  | 500,00     | Itaú (341)| Boleto  |
| 34191090086352135000200006146000951037000075000  | 750,00     | Itaú (341)| Boleto  |
| 34191090086352135000200006146000951037000100000  | 1.000,00   | Itaú (341)| Boleto  |
| 34191090086352135000200006146000951037000120000  | 1.200,00   | Itaú (341)| Boleto  |

> [!NOTE]
> Os barcodes acima seguem o padrão FEBRABAN com banco código 341 (Itaú). 
> O dígito verificador (posição 20 do código de barras) é calculado pelo módulo 10.
> Para gerar novos barcodes de teste, utilize a biblioteca `febraban-boleto-utils` ou
> o utilitário em `src/test/resources/barcode-generator.py`.

### Datas de Referência para Testes de Atraso

A data de referência usada nos testes é **2026-07-23** (data de criação dos feature files).

| Vencimento     | Dias de Atraso | Resultado           |
|----------------|----------------|---------------------|
| 2026-01-02     | 202 dias       | ACEITO (> 180)      |
| 2026-01-22     | 181 dias       | ACEITO (> 180)      |
| 2026-01-23     | 180 dias       | REJEITADO (= 180)   |
| 2026-01-24     | 179 dias       | REJEITADO (< 180)   |
| 2026-04-23     | 90 dias        | REJEITADO (< 180)   |

---

## Executando com Cucumber (Java)

### Pré-requisitos

- Java 17+
- Maven 3.9+ ou Gradle 8+
- Docker (para LocalStack, Kafka, Redis)

### Dependências Maven (`pom.xml`)

```xml
<dependencies>
    <!-- Cucumber -->
    <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-java</artifactId>
        <version>7.15.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-spring</artifactId>
        <version>7.15.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.cucumber</groupId>
        <artifactId>cucumber-junit-platform-engine</artifactId>
        <version>7.15.0</version>
        <scope>test</scope>
    </dependency>

    <!-- JUnit 5 -->
    <dependency>
        <groupId>org.junit.platform</groupId>
        <artifactId>junit-platform-suite</artifactId>
        <version>1.10.2</version>
        <scope>test</scope>
    </dependency>

    <!-- REST Assured -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.4.0</version>
        <scope>test</scope>
    </dependency>

    <!-- Testcontainers -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>testcontainers</artifactId>
        <version>1.19.6</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>localstack</artifactId>
        <version>1.19.6</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>kafka</artifactId>
        <version>1.19.6</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Runner Class

```java
// src/test/java/br/com/renegociacao/bdd/CucumberRunner.java
package br.com.renegociacao.bdd;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectClasspathResource;
import org.junit.platform.suite.api.Suite;

import static io.cucumber.junit.platform.engine.Constants.*;

@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("features")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME,
    value = "pretty, html:target/cucumber-reports/report.html, json:target/cucumber-reports/report.json")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME,
    value = "br.com.renegociacao.bdd.steps")
@ConfigurationParameter(key = FEATURES_PROPERTY_NAME,
    value = "src/test/resources/features")
@ConfigurationParameter(key = FILTER_TAGS_PROPERTY_NAME,
    value = "not @Skip")
public class CucumberRunner {
}
```

### Executando todos os testes BDD

```bash
# Subir infraestrutura de teste
docker-compose -f docker-compose.localstack.yml up -d

# Aguardar serviços saudáveis
sleep 10

# Executar todos os feature files
mvn test -Dtest=CucumberRunner

# Executar uma feature específica
mvn test -Dtest=CucumberRunner -Dcucumber.features=src/test/resources/features/idempotency.feature

# Executar por tag
mvn test -Dtest=CucumberRunner -Dcucumber.filter.tags="@HappyPath"

# Executar com relatório HTML
mvn test -Dtest=CucumberRunner -Dcucumber.plugin="pretty,html:target/cucumber-reports/index.html"

# Parar infraestrutura
docker-compose -f docker-compose.localstack.yml down
```

### Executando feature por feature

```bash
# Feature 1: Renegociação
mvn test -Dtest=CucumberRunner \
  -Dcucumber.features="src/test/resources/features/renegotiation_payment.feature"

# Feature 2: Validação de Barcode
mvn test -Dtest=CucumberRunner \
  -Dcucumber.features="src/test/resources/features/payment_validation.feature"

# Feature 3: Emissão de Comprovante
mvn test -Dtest=CucumberRunner \
  -Dcucumber.features="src/test/resources/features/receipt_emission.feature"

# Feature 4: Compensação Saga
mvn test -Dtest=CucumberRunner \
  -Dcucumber.features="src/test/resources/features/saga_compensation.feature"

# Feature 5: Idempotência
mvn test -Dtest=CucumberRunner \
  -Dcucumber.features="src/test/resources/features/idempotency.feature"

# Feature 6: Notificação
mvn test -Dtest=CucumberRunner \
  -Dcucumber.features="src/test/resources/features/notification.feature"
```

### Estrutura de Steps (Java)

```
src/test/java/br/com/renegociacao/bdd/steps/
├── RenegotiationSteps.java        # Steps de renegotiation_payment.feature
├── PaymentValidationSteps.java    # Steps de payment_validation.feature
├── ReceiptEmissionSteps.java      # Steps de receipt_emission.feature
├── SagaCompensationSteps.java     # Steps de saga_compensation.feature
├── IdempotencySteps.java          # Steps de idempotency.feature
├── NotificationSteps.java         # Steps de notification.feature
└── CommonSteps.java               # Steps compartilhados (Contexto/Background)

src/test/java/br/com/renegociacao/bdd/config/
├── CucumberSpringConfig.java      # Configuração Spring para Cucumber
└── TestContainersConfig.java      # Configuração Testcontainers
```

---

## Executando com gotestsum (Go)

> Aplicável ao microsserviço escrito em Go (ex.: `barcode-validator-service`).

### Pré-requisitos

- Go 1.22+
- `gotestsum` instalado: `go install gotest.tools/gotestsum@latest`
- `godog` (Cucumber para Go): `go get github.com/cucumber/godog@v0.14.1`
- Docker (para LocalStack, Kafka, Redis)

### Estrutura de Testes BDD em Go

```
test/bdd/
├── main_test.go                   # Entry point dos testes BDD com Godog
├── steps/
│   ├── renegotiation_steps.go     # Step definitions
│   ├── validation_steps.go
│   ├── receipt_steps.go
│   ├── saga_steps.go
│   ├── idempotency_steps.go
│   └── notification_steps.go
└── testdata/
    ├── barcodes.json              # Barcodes de teste válidos
    └── cpf_cnpj.json             # CPFs e CNPJs de teste válidos
```

### `go.mod` — Dependências Relevantes

```go
require (
    github.com/cucumber/godog v0.14.1
    github.com/testcontainers/testcontainers-go v0.29.1
    github.com/aws/aws-sdk-go-v2 v1.26.0
    github.com/redis/go-redis/v9 v9.5.1
    github.com/segmentio/kafka-go v0.4.47
    gotest.tools/gotestsum v1.11.0
)
```

### Entry Point `main_test.go`

```go
package bdd_test

import (
    "context"
    "os"
    "testing"

    "github.com/cucumber/godog"
    "github.com/cucumber/godog/colors"
    "github.com/renegociacao/test/bdd/steps"
)

func TestBDD(t *testing.T) {
    opts := godog.Options{
        Output:    colors.Colored(os.Stdout),
        Format:    "pretty",
        Paths:     []string{"../../docs/bdd/features"},
        Randomize: -1, // Ordenação aleatória para detectar dependências
        Tags:      os.Getenv("BDD_TAGS"), // Ex: "@HappyPath"
    }

    suite := godog.TestSuite{
        Name:                 "renegociacao-bdd",
        ScenarioInitializer:  steps.InitializeScenario,
        Options:              &opts,
    }

    if status := suite.Run(); status != 0 {
        t.Fail()
    }
}

func InitializeScenario(ctx *godog.ScenarioContext) {
    s := steps.NewStepState()
    s.RegisterAllSteps(ctx)
}
```

### Executando com gotestsum

```bash
# Subir infraestrutura de teste
docker-compose -f docker-compose.localstack.yml up -d && sleep 10

# Executar todos os testes BDD com saída formatada
gotestsum --format testdox -- -v -count=1 ./test/bdd/...

# Executar com timeout estendido (útil para testes de retry/timeout)
gotestsum --format testdox -- -v -count=1 -timeout 5m ./test/bdd/...

# Executar apenas cenários com tag específica
BDD_TAGS="@HappyPath" gotestsum --format testdox -- -v ./test/bdd/...

# Gerar relatório JUnit XML (para CI/CD)
gotestsum --junitfile reports/bdd-results.xml --format testdox -- -v ./test/bdd/...

# Executar e exibir somente falhas
gotestsum --format dots -- -v ./test/bdd/...

# Rodar com race detector (detectar race conditions — ver idempotency.feature)
gotestsum --format testdox -- -race -v ./test/bdd/...

# Parar infraestrutura
docker-compose -f docker-compose.localstack.yml down
```

### Makefile de Conveniência

```makefile
# Makefile (raiz do projeto)

.PHONY: bdd-up bdd-down bdd-java bdd-go bdd-all bdd-report

bdd-up:
	docker-compose -f docker-compose.localstack.yml up -d
	@echo "Aguardando infraestrutura..." && sleep 12

bdd-down:
	docker-compose -f docker-compose.localstack.yml down -v

# Java: todos os feature files
bdd-java: bdd-up
	mvn test -Dtest=CucumberRunner
	$(MAKE) bdd-down

# Java: feature específica (uso: make bdd-java-feature FEATURE=idempotency)
bdd-java-feature: bdd-up
	mvn test -Dtest=CucumberRunner \
	  -Dcucumber.features="src/test/resources/features/$(FEATURE).feature"
	$(MAKE) bdd-down

# Go: todos os feature files
bdd-go: bdd-up
	gotestsum --format testdox -- -v -count=1 -timeout 5m ./test/bdd/...
	$(MAKE) bdd-down

# Ambos: Java e Go
bdd-all: bdd-up
	mvn test -Dtest=CucumberRunner
	gotestsum --format testdox -- -v -count=1 -timeout 5m ./test/bdd/...
	$(MAKE) bdd-down

# Gerar relatório HTML (Java)
bdd-report:
	open target/cucumber-reports/report.html
```

---

## Integração CI/CD

### GitHub Actions

```yaml
# .github/workflows/bdd-tests.yml
name: BDD Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  bdd-java:
    name: BDD Tests (Java / Cucumber)
    runs-on: ubuntu-latest
    services:
      localstack:
        image: localstack/localstack:3.4
        ports:
          - 4566:4566
        env:
          SERVICES: s3,sqs,sns,ses
          DEFAULT_REGION: us-east-1
      redis:
        image: redis:7.2-alpine
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Inicializar LocalStack
        run: |
          aws --endpoint-url=http://localhost:4566 s3 mb s3://comprovantes-renegociacao
          aws --endpoint-url=http://localhost:4566 sns create-topic --name ops-alerts
        env:
          AWS_ACCESS_KEY_ID: test
          AWS_SECRET_ACCESS_KEY: test
          AWS_DEFAULT_REGION: us-east-1

      - name: Executar testes BDD
        run: mvn test -Dtest=CucumberRunner

      - name: Publicar relatório Cucumber
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: target/cucumber-reports/report.json

  bdd-go:
    name: BDD Tests (Go / Godog)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Instalar gotestsum
        run: go install gotest.tools/gotestsum@latest

      - name: Executar testes BDD Go
        run: |
          gotestsum --junitfile reports/bdd-go-results.xml \
                    --format testdox \
                    -- -v -count=1 -timeout 5m ./test/bdd/...

      - name: Publicar resultados
        uses: mikepenz/action-junit-report@v4
        if: always()
        with:
          report_paths: 'reports/bdd-go-results.xml'
```

---

## Convenções de Escrita

### Idioma e Terminologia

| Categoria                   | Convenção                                                        |
|-----------------------------|------------------------------------------------------------------|
| Palavras-chave Gherkin      | Em português: `Funcionalidade`, `Cenário`, `Dado`, `Quando`, `Então`, `E`, `Mas` |
| Termos técnicos             | Em inglês: `API`, `POST`, `GET`, `HTTP status code`, `header`, `event`, `topic`, `DLQ`, `UUID`, `TTL`, `SMTP`, `S3`, `SNS`, `Redis`, `Kafka` |
| Nomes de campos             | Em inglês (camelCase): `idRenegociation`, `codigoBarra`, `valorPago`, `cpfCnpj`, `emailPagador`, `internalId`, `externalId` |
| Status de renegociação      | Em inglês (SCREAMING_SNAKE_CASE): `RECEIVED`, `PROCESSING`, `VALIDATED`, `RECEIPT_SENT`, `FAILED`, `COMPENSATED` |
| Erros/códigos de negócio    | Em inglês (SCREAMING_SNAKE_CASE): `VALIDATION_ERROR`, `BARCODE_VALIDATION_TIMEOUT`, `ATRASO_INSUFICIENTE` (exceção: regra de negócio em pt-BR) |
| Tópicos Kafka               | Em inglês (kebab-case): `renegotiation.received`, `renegotiation.validated` |
| Nomes de tabelas BD         | Em inglês (snake_case): `idempotency_keys`, `notification_log`, `comprovante` |

### Tags de Cenários (recomendadas)

```gherkin
@HappyPath      # Fluxo principal sem erros
@EdgeCase       # Valores de borda (boundary values)
@ErrorCase      # Cenários de erro e rejeição
@Idempotency    # Testes de idempotência
@Saga           # Testes de compensação Saga
@Notification   # Testes de envio de e-mail
@Slow           # Testes com sleep/timeout (> 5s)
@Skip           # Cenários desabilitados temporariamente
```

### Boas Práticas

1. **Cada `Cenário` deve ser independente**: utilize o `Contexto`/`Background` para setup compartilhado.
2. **Dados de teste reais**: use CPFs, CNPJs e barcodes matematicamente válidos.
3. **Sem lógica nos steps Gherkin**: os steps apenas declaram intenção; a implementação fica nas step definition classes.
4. **Scenario Outline** para casos parametrizados com 3+ variações de dados.
5. **Nomenclatura clara**: o nome do cenário deve descrever o comportamento esperado, não a implementação.
6. **Máximo de 10 steps por cenário**: cenários muito longos indicam responsabilidades múltiplas.
7. **Evite `E` encadeado excessivo**: prefira dividir em múltiplos `Então`.

---

## Referências

- [Cucumber Documentation](https://cucumber.io/docs/cucumber/)
- [Godog — Cucumber for Go](https://github.com/cucumber/godog)
- [gotestsum](https://github.com/gotestyourself/gotestsum)
- [Gherkin Reference](https://cucumber.io/docs/gherkin/reference/)
- [FEBRABAN — Padrão de Boleto Bancário](https://www.febraban.org.br/associados/utilitarios/padrao-boleto.asp)
- [Testcontainers Java](https://testcontainers.com/guides/getting-started-with-testcontainers-for-java/)
- [LocalStack](https://docs.localstack.cloud/getting-started/)
- [Saga Pattern — Microservices.io](https://microservices.io/patterns/data/saga.html)

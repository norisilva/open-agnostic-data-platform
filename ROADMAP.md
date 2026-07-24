# 🗺️ ROADMAP — Plataforma Agnóstica Multi-Celular

> **⚠️ INSTRUÇÃO OBRIGATÓRIA PARA TODA IA (Antigravity, Cursor, Copilot, etc):**
>
> Este é o **documento-mestre de progresso** do projeto. Você é **OBRIGADO(A)** a:
>
> 1. **LER** este arquivo completo antes de iniciar qualquer trabalho.
> 2. **ATUALIZAR** o status de cada item ao terminar (marcar `[x]`), ao iniciar (`[/]`) ou ao bloquear (`[!]`).
> 3. **NUNCA** pular uma fase. A ordem é sequencial dentro de cada fase.
> 4. **REGISTRAR** a data e sessão no campo "Última atualização" abaixo.
> 5. Quando terminar uma **sub-fase inteira**, atualizar a % na linha da sub-fase.
> 6. Quando terminar uma **fase inteira**, marcar o status da fase como `✅ DONE`.
> 7. Se encontrar um bloqueio, marcar `[!]` e descrever o motivo.
> 8. **Não criar** novos documentos de tracking. Este é o único.
>
> **Arquivos de apoio (ler se precisar de detalhes):**
> - `PROJECT_CONTEXT.md` → Decisões arquiteturais e configuração
> - `docs/sdd/sdd.md` → Design de domínio
> - `docs/sda/sda.md` → Design de arquitetura
> - `docs/api-audit.md` → 12 problemas da API legada
> - `docs/services-design.md` → Detalhamento dos 5 serviços originais
> - `docs/observability-design.md` → Stack LGTM

**Última atualização:** 2026-07-23 | Sessão: 02
**Progresso global:** ██░░░░░░░░░░░░░░░░░░ 10%

---

## Legenda de Status

```
[ ]  = Pendente (não iniciado)
[/]  = Em progresso (IA trabalhando agora)
[x]  = Concluído e verificado
[!]  = Bloqueado (motivo descrito ao lado)
[-]  = Cancelado / descartado
```

---

## Visão Geral das Fases

| # | Fase | Status | Progresso | Estimativa |
|---|------|--------|-----------|------------|
| 0 | Fundação & Documentação | ✅ DONE | 100% | — (feita) |
| 1 | Plataforma Core (CloudEvents, Schema Registry, Cell Router, Schema Validator) | ✅ DONE | 100% | — |
| 2 | Plataforma: Serviços Java Genéricos (event-api, notification-service) | ✅ DONE | 100% | — |
| 3 | Célula Renegociação — Serviços Go (Workers) | ⬜ TODO | 0% | ~3 dias |
| 4 | Infraestrutura Local (K8s + Podman Kube Play) | ⬜ TODO | 0% | ~2 dias |
| 5 | Observabilidade LGTM + Dashboards | ⬜ TODO | 0% | ~2 dias |
| 6 | Lakehouse Medallion (Bronze → Silver → Gold) | ⬜ TODO | 0% | ~3 dias |
| 7 | Testes (Unitário, Integração, BDD, Carga k6) | ⬜ TODO | 0% | ~4 dias |
| 8 | IaC (Terraform Cell Modules) | ⬜ TODO | 0% | ~2 dias |
| 9 | Refinamento, Demo & Documentação Final | ⬜ TODO | 0% | ~2 dias |

---

# FASE 0 — Fundação & Documentação

**Status:** ✅ DONE (100%)
**Objetivo:** Levantar toda a documentação de base do projeto.

### 0.1 — Análise do Legado
- [x] Explorar projeto existente (`quarkus-api-renegociation-with-sns-output-main`)
- [x] Auditar API existente — 12 problemas catalogados → `docs/api-audit.md`

### 0.2 — Design de Serviços
- [x] Definir 5 microsserviços com responsabilidades e contratos → `docs/services-design.md`
- [x] Definir stack de observabilidade LGTM com 6 dashboards → `docs/observability-design.md`

### 0.3 — Documentos de Arquitetura
- [x] Gerar SDD → `docs/sdd/sdd.md`
- [x] Gerar SDA → `docs/sda/sda.md`
- [x] Gerar BDD feature files → `docs/bdd/features/*.feature` (83 cenários)
- [x] Criar `PROJECT_CONTEXT.md`
- [x] Criar `README.md`

### 0.4 — Evolução para Plataforma Agnóstica (NOVA)
- [x] Criar `docs/platform/platform-design.md` — design multi-celular completo
- [x] Criar `docs/platform/cloudevents-envelope.md` — spec do envelope CloudEvents 1.0
- [x] Criar `docs/platform/cell-specification.md` — template de célula
- [x] Criar `docs/platform/schema-registry-guide.md` — Apicurio Registry 3.x
- [x] Criar `docs/platform/lakehouse-design.md` — Medallion (Bronze/Silver/Gold)
- [x] Atualizar `PROJECT_CONTEXT.md` com decisões da plataforma
- [x] Atualizar `docs/sdd/sdd.md` — addendum ADR-008 (Multi-Celular), ADR-009 (CloudEvents)
- [x] Atualizar `docs/sda/sda.md` — addendum seção Plataforma e Células

---

# FASE 1 — Plataforma Core

**Status:** 🏗️ IN_PROGRESS
**Objetivo:** Criar os componentes compartilhados que viabilizam a plataforma agnóstica.

### 1.1 — Envelope CloudEvents (Biblioteca Compartilhada)
- [x] Criar `platform/cloudevents-sdk/` — lib Java (jar)
  - [x] Classe `PlatformCloudEvent` com todos os campos (specversion, id, source, type, buzid, correlationid, traceparent, data)
  - [x] Builder pattern para construção fluida
  - [x] Serialização/Desserialização JSON (Jackson)
  - [x] Testes unitários da lib
- [x] Criar `platform/cloudevents-go/` — lib Go (module)
  - [x] Struct `PlatformCloudEvent` equivalente
  - [x] Marshal/Unmarshal JSON
  - [x] Testes unitários

### 1.2 — Apicurio Schema Registry (Setup Local)
- [x] Adicionar Apicurio Registry 3.x ao manifesto K8s (`infra/k8s-local/00-platform.yaml`)
- [x] Criar schemas iniciais do produto Renegociação:
  - [x] `schemas/renegotiation/payment-received.json` (JSON Schema)
  - [x] `schemas/renegotiation/payment-validated.json`
  - [x] `schemas/renegotiation/receipt-generated.json`
  - [x] `schemas/renegotiation/receipt-failed.json`
  - [x] `schemas/renegotiation/notification-sent.json`
- [x] Script de bootstrap: registrar schemas no Apicurio via API REST
- [x] Testar UI do Apicurio em `localhost:8081`

### 1.3 — Cell Router (Quarkus — API Gateway da Plataforma)
- [x] Criar `platform/cell-router/` — Quarkus Java 25+
  - [x] `pom.xml` com Quarkus 3.21, quarkus-rest-jackson, quarkus-amazon-sns, quarkus-redis-client
  - [x] Endpoint `POST /platform/v1/events` (agnóstico)
  - [x] Validação do payload contra schema do Apicurio (HTTP client + cache Redis)
  - [x] Encapsulamento em CloudEvent envelope
  - [x] Roteamento para fila SQS correta baseado no `type` do evento
  - [x] `@RunOnVirtualThread`
  - [x] Endpoint `GET /platform/v1/cells` — lista células ativas
  - [x] Endpoint `GET /platform/v1/schemas/{group}` — proxy para Apicurio
  - [x] `application.properties` com perfis `%dev`/`%prod`
  - [x] Health check + OTel
  - [x] Containerfile (Native GraalVM)
  - [x] Testes unitários

### 1.4 — Schema Validator (Go — Worker de Validação)
- [x] Criar `platform/schema-validator/` — Go 1.22
  - [x] Consumer SQS genérico (lê eventos CloudEvents)
  - [x] Valida `data` contra schema cacheado do Apicurio
  - [x] Reject → DLQ com motivo detalhado
  - [x] Accept → re-publica no SQS de destino
  - [x] Cache local de schemas (TTL 5min)
  - [x] OTel setup
  - [x] Containerfile (distroless ~8MB)
  - [x] Testes unitários

---

# FASE 2 — Plataforma: Serviços Java Genéricos (Quarkus)

**Status:** ✅ DONE
**Objetivo:** Criar serviços de plataforma 100% agnósticos e vendaveis. Sem nenhuma referência a `renegotiation`, `payment` ou qualquer domínio de negócio. O cliente final (banco, RH, etc.) customiza via schemas (Apicurio), templates e env vars — zero código.
**Convenção:** Pacotes `br.com.platform.*`, diretórios `platform/event-api/` e `platform/notification-service/`. Java 25 + GraalVM + Virtual Threads obrigatórios.

### 2.1 — `platform/event-api/` (API de Entrada Genérica / Command Gateway — CQRS Fast Dispatching)
- [x] Criar `platform/event-api/` — Quarkus 3.37.4, Java 25, GraalVM native
- [x] `pom.xml`: groupId `br.com.platform`, pacote `br.com.platform.eventapi`
- [x] `POST /api/v1/events` — recebe qualquer payload JSON (Fast Dispatching para SQS via Command Gateway)
  - [x] Header `X-Cell-Id` identifica a célula (grupo no Apicurio)
  - [x] Header `X-Event-Type` identifica o tipo de evento
  - [x] Header `Idempotency-Key` (deduplicacao via Redis, TTL configuravel)
  - [x] Valida payload contra schema do Apicurio (via `cell-router` ou direto)
  - [x] Publica CloudEvent no SNS (topic ARN configurado por env var)
  - [x] Retorna HTTP 202 Accepted sem bloquear I/O de disco
- [x] POJO `PlatformEvent` em memória para serialização
- [x] `@RunOnVirtualThread` nos endpoints
- [x] SmallRye Health + OTel
- [x] `application.properties` 12-Factor compliant
- [x] Containerfile nativo (ubi-micro + GraalVM runner)
- [x] Testes unitários

### 2.2 — `platform/notification-service/` (Notificador Genérico)
- [x] Criar `platform/notification-service/` — Quarkus 3.37.4, Java 25
- [x] Consumer SQS genérico: lê qualquer CloudEvent do tipo `notification.requested`
- [x] Renderiza template HTML via Qute (template filename vem no payload do evento)
- [x] SMTP configuravel: Mailpit (dev) / SES (prod) via env vars
- [x] `POST /api/v1/notifications/resend/{eventId}` — reenvia qualquer notificacao
- [x] `GET /api/v1/notifications/{eventId}/status`
- [x] Tabela `notification_log` (Flyway): `event_id`, `template_name`, `recipient`, `status`
- [x] OTel + Virtual Threads
- [x] `application.properties` 12-Factor compliant
- [x] Containerfile nativo
- [x] Testes unitários

### 2.3 — `platform/event-persister/` (CQRS Persist Function com MongoDB)
- [ ] Criar `platform/event-persister/` — Quarkus 3.37.4, Java 25
- [ ] Consumer SQS genérico `persist-queue` (assina todos os tópicos SNS de células)
- [ ] Conecta no **MongoDB** para salvar eventos brutos (Collection `platform_events`, append-only)
- [ ] Garante que o Gateway fique 100% livre de bloqueios síncronos com o Event Store
- [ ] OTel + Virtual Threads

### 2.4 — `platform/event-cdc-publisher/` (CDC Mongo -> Kafka/Redis)
- [ ] Criar `platform/event-cdc-publisher/` — Quarkus 3.37.4, Java 25
- [ ] **Change Streams (CDC)**: Implementa um Watch cursor na coleção `platform_events` do MongoDB
- [ ] Ao detectar evento inserido, atualiza/invalida status no cache do **Redis**
- [ ] Ao detectar evento inserido, publica no **Kafka/Redpanda** (tópico: `platform.events.raw.v1`) para a malha analítica
- [ ] OTel + Virtual Threads

---

# FASE 3 — Componentes Agnósticos de Integração (Webhooks)

**Status:** ⬜ TODO
**Objetivo:** Criar serviços de plataforma genéricos para integrar com APIs de negócio dos clientes via Webhooks, mantendo a plataforma 100% agnóstica.

### 3.1 — `platform/webhook-validator` (Validação de Negócio)
- [ ] Criar `platform/webhook-validator/` — Quarkus 3.37.4, Java 25, Virtual Threads
- [ ] Consumer SQS `validation-queue`
- [ ] `application.properties`: URL do webhook configurável por variável de ambiente (`WEBHOOK_VALIDATOR_URL`)
- [ ] Despacha HTTP POST assíncrono para o cliente contendo o CloudEvent
- [ ] **Tratamento HTTP 200:** Validação passou, publica no tópico `event-validated`
- [ ] **Tratamento HTTP 400/422:** Validação de negócio falhou (ex: "boleto vencido").
  - Extrai a mensagem de erro do payload do cliente.
  - Publica evento `event-validation-failed` no SNS para registrar a falha (trilha de auditoria / atualização de status).
  - Publica evento `notification.requested` no SNS para alertar o chamador.
- [ ] OTel + Métricas (taxa de erro do webhook, latência)

### 3.2 — `platform/webhook-action` (Execução de Ações/Saga)
- [ ] Criar `platform/webhook-action/` — Quarkus 3.37.4, Java 25, Virtual Threads
- [ ] Consumer SQS para fila de execução (`action-queue`)
- [ ] `application.properties`: URL do webhook de ação (`WEBHOOK_ACTION_URL`)
- [ ] Tenta executar a ação no cliente (ex: efetivar pagamento/recibo)
- [ ] **Retry Pattern:** Backoff exponencial para timeouts/HTTP 500
- [ ] **Compensação (Saga):** Após N falhas, publica evento `action-failed` e notifica via `notification-service`
- [ ] Se sucesso, publica `action-completed`

---

# FASE 4 — Infraestrutura Local (Kubernetes + Podman Kube Play)

**Status:** ⬜ TODO
**Objetivo:** Subir toda a stack local com `podman kube play`.

### 4.1 — Manifestos de Plataforma (compartilhados)
- [ ] `infra/k8s-local/00-platform.yaml`:
  - [ ] Pod Apicurio Registry 3.x (porta 8081)
  - [ ] Pod OTel Collector (portas 4317, 4318)
  - [ ] Pod Mailpit (portas 8025, 1025)

### 4.2 — Manifestos de Bancos de Dados
- [ ] `infra/k8s-local/01-databases.yaml`:
  - [ ] Pod PostgreSQL 16 (porta 5432) + ConfigMap `init.sql`
  - [ ] Pod Redis 7 Alpine (porta 6379) + ConfigMap `redis.conf`
  - [ ] Pod MongoDB 7 (porta 27017) + ConfigMap `init.js` (replica set para Change Streams)

### 4.3 — Manifestos de Mensageria
- [ ] `infra/k8s-local/02-messaging.yaml`:
  - [ ] Pod LocalStack (porta 4566) + ConfigMap `init-aws.sh`
  - [ ] Script cria: SNS topics, SQS queues, subscriptions, DLQs
  - [ ] Pod **Redpanda (Kafka)** (porta 9092) para stream CDC analítico
  - [ ] (Futuro) DynamoDB cell-registry table

### 4.4 — Manifestos de Observabilidade
- [ ] `infra/k8s-local/03-observability.yaml`:
  - [ ] Pod Prometheus (porta 9090) + ConfigMap `prometheus.yml`
  - [ ] Pod Grafana Tempo (porta 3200) + ConfigMap `tempo.yaml`
  - [ ] Pod Grafana Loki (porta 3100) + ConfigMap `loki.yaml`
  - [ ] Pod Grafana Alloy + ConfigMap `alloy-config.river`
  - [ ] Pod Grafana (porta 3000) + ConfigMaps datasources + dashboards

### 4.5 — Manifestos dos Serviços
- [ ] `infra/k8s-local/04-services.yaml`:
  - [ ] Pod cell-router (porta 8080)
  - [ ] Pod quarkus-renegotiation-api (porta 8082)
  - [ ] Pod quarkus-notification-service (porta 8083)
  - [ ] Pod go-barcode-validator
  - [ ] Pod go-audit-logger
  - [ ] Pod go-receipt-worker
  - [ ] Pod schema-validator

### 4.6 — Validação Completa
- [ ] `podman kube play infra/k8s-local/00-platform.yaml` — sucesso
- [ ] `podman kube play infra/k8s-local/01-databases.yaml` — sucesso
- [ ] `podman kube play infra/k8s-local/02-messaging.yaml` — sucesso
- [ ] Verificar LocalStack: SNS/SQS criados corretamente
- [ ] `podman kube play infra/k8s-local/03-observability.yaml` — sucesso
- [ ] `podman kube play infra/k8s-local/04-services.yaml` — sucesso
- [ ] Healthchecks OK em todos os serviços

---

# FASE 5 — Observabilidade LGTM + Dashboards

**Status:** ⬜ TODO
**Objetivo:** Configurar coleta de traces, logs, métricas e dashboards E2E.

### 5.1 — OTel Collector
- [ ] `infra/observability/otel-collector-config.yaml`
  - [ ] Receivers: OTLP gRPC (4317) + OTLP HTTP (4318)
  - [ ] Processors: batch, memory_limiter, resource
  - [ ] Exporters: prometheusremotewrite, otlp (Tempo), loki
- [ ] Validar: traces Java→Go chegam no Tempo com traceId correto

### 5.2 — Alloy (Log Collection)
- [ ] `infra/observability/alloy-config.river`
- [ ] Coleta stdout/stderr de todos os pods
- [ ] Labels: `service_name`, `buzid`, `cell_name`
- [ ] Forward para Loki

### 5.3 — Grafana Datasources
- [ ] `infra/observability/grafana/datasources/datasources.yaml`
  - [ ] Prometheus, Tempo, Loki configurados

### 5.4 — Dashboards Grafana (6 dashboards)
- [ ] Dashboard 1: `renegotiation-e2e.json` — fluxo completo ponta a ponta
- [ ] Dashboard 2: `infrastructure-health.json` — saúde dos containers/pods
- [ ] Dashboard 3: `jvm-virtual-threads.json` — pool de VTs, latência p99
- [ ] Dashboard 4: `go-workers.json` — goroutines, SQS poll rate
- [ ] Dashboard 5: `saga-tracker.json` — sucesso/falha/compensação por saga
- [ ] Dashboard 6: `dlq-monitor.json` — mensagens em DLQs, taxa de erro

### 5.5 — Validação E2E
- [ ] Enviar request → verificar trace completo no Tempo (Java→SQS→Go→Go→Java)
- [ ] Verificar logs correlacionados no Loki por traceId
- [ ] Verificar métricas customizadas no Prometheus
- [ ] Screenshot de cada dashboard funcionando

---

# FASE 6 — Lakehouse Medallion (Bronze → Silver → Gold)

**Status:** ⬜ TODO
**Objetivo:** Pipeline analítico agnóstico particionado por célula/produto.

### 6.1 — Bronze Layer (Ingestão Bruta via CDC Kafka)
- [ ] LocalStack S3 bucket `s3://bronze/`
- [ ] Script Spark/Databricks simulado consome mensagens do tópico Kafka `platform.events.raw.v1`
- [ ] Grava CloudEvents brutos no S3 como Parquet/JSON
- [ ] Particionamento: `buzid/year/month/day/`
- [ ] Apache Iceberg table definition (append-only)

### 6.2 — Silver Layer (Limpeza e Conformidade)
- [ ] LocalStack S3 bucket `s3://silver/`
- [ ] Job Spark (container) ou script Python (PyIceberg)
  - [ ] Lê Bronze
  - [ ] Valida contra schema do Apicurio
  - [ ] Deduplica (CDC)
  - [ ] Converte `data` em colunas Iceberg tipadas
- [ ] Schema evolution dinâmica acompanhando Apicurio

### 6.3 — Gold Layer (Modelagem Dimensional)
- [ ] LocalStack S3 bucket `s3://gold/`
- [ ] Tabela: `renegotiation_summary` (visão de negócio do produto renegociação)
- [ ] Tabela: `platform_events_daily` (visão agnóstica por célula)
- [ ] Consultável via PyIceberg / Spark

### 6.4 — Catálogo e Consultas
- [ ] AWS Glue simulado (LocalStack) como catálogo Iceberg
- [ ] Script de consulta exemplo com PyIceberg
- [ ] Documentar caminho de evolução para Athena/EMR real

---

# FASE 7 — Testes (Unitário, Integração, BDD, Carga)

**Status:** ⬜ TODO
**Objetivo:** Cobertura de testes em todas as camadas.

### 7.1 — Testes Unitários
- [ ] Java (JUnit 5 + Mockito): domínio + usecases do SVC-01 e SVC-05
- [ ] Go (`go test`): domínio puro dos SVC-02, SVC-03, SVC-04
- [ ] Go: domínio do schema-validator
- [ ] Java: domínio do cell-router

### 7.2 — Testes de Integração
- [ ] Quarkus `@QuarkusTest` com LocalStack (SVC-01)
- [ ] Go integration tests com LocalStack SQS (SVC-02, SVC-04)
- [ ] MongoDB integration tests (SVC-03, SVC-04)
- [ ] Redis integration tests (idempotência SVC-01)
- [ ] Cell Router: validação contra Apicurio Registry real (test container)

### 7.3 — BDD (Cucumber + Godog)
- [ ] Implementar step definitions Cucumber (Java) para SVC-01 e SVC-05
- [ ] Implementar step definitions Godog (Go) para SVC-02, SVC-03, SVC-04
- [ ] Criar feature files novos:
  - [ ] `platform_cell_provisioning.feature`
  - [ ] `schema_registry_validation.feature`
- [ ] Integrar BDD no script de teste
- [ ] Gerar relatório HTML dos testes BDD

### 7.4 — Testes E2E
- [ ] Postman/Newman collection para fluxo completo (POST → CloudEvent → Saga → Receipt → Email)
- [ ] Script de smoke test automatizado

### 7.5 — Testes de Carga (k6)
- [ ] Script k6: stress test na API do cell-router (500 VUs)
- [ ] Script k6: validar throughput do SQS + workers Go
- [ ] Script k6: cenário multi-célula (envios simultâneos de produtos diferentes)
- [ ] Validar métricas SLI no Prometheus sob carga
- [ ] Validar alertas Grafana sob carga
- [ ] Documentar resultados e limites encontrados

---

# FASE 8 — IaC (Terraform Cell Modules)

**Status:** ⬜ TODO
**Objetivo:** Provisionar células automaticamente via Terraform + LocalStack.

### 8.1 — Módulo Cell
- [ ] `infra/terraform/modules/cell/main.tf`
  - [ ] Variáveis: `cell_name`, `buzid`, `sns_topics`, `sqs_queues`, `services`
  - [ ] Cria SNS topics para a célula
  - [ ] Cria SQS queues + subscriptions
  - [ ] Cria DLQs
  - [ ] (Futuro) Cria DynamoDB cell-registry entry

### 8.2 — Ambiente Local
- [ ] `infra/terraform/environments/local/main.tf`
  - [ ] Provider: AWS com LocalStack endpoint
  - [ ] Instancia módulo cell para `renegotiation-cell-a`
  - [ ] `terraform init` + `terraform apply` funciona contra LocalStack

### 8.3 — Documentação
- [ ] README do Terraform com instruções de uso
- [ ] Documentar caminho para multi-célula (cell-b, cell-c)

---

# FASE 9 — Refinamento, Demo & Documentação Final

**Status:** ⬜ TODO
**Objetivo:** Fechar o projeto com qualidade.

### 9.1 — Documentação
- [ ] `README.md` completo com instruções de start local (passo a passo)
- [ ] Atualizar todos os documentos `docs/` com estado final
- [ ] Atualizar `PROJECT_CONTEXT.md` com todas as decisões tomadas

### 9.2 — Demo
- [ ] Script de demo automatizado (`scripts/demo.sh`):
  - [ ] Sobe toda a infra (`podman kube play`)
  - [ ] Registra schemas no Apicurio
  - [ ] Envia request de renegociação
  - [ ] Mostra trace no Grafana
  - [ ] Mostra email no Mailpit
  - [ ] Mostra dados no Lakehouse Bronze
- [ ] Gravar/documentar o fluxo completo (screenshots ou script narrado)

### 9.3 — Revisão Final
- [ ] Smoke test completo do sistema
- [ ] Revisar todos os Containerfiles
- [ ] Revisar todos os schemas no Apicurio
- [ ] Verificar que nenhum secret/credential está hardcoded
- [ ] Marcar este roadmap como 100% ✅

---

# Changelog (Registro de mudanças no Roadmap)

| Data | Sessão | Mudança |
|------|--------|---------|
| 2026-07-23 | 01 | Criação inicial (sistema de renegociação) |
| 2026-07-23 | 01 | Evolução para Plataforma Agnóstica Multi-Celular |
| 2026-07-23 | 01 | Apicurio Registry confirmado (não Apitomy — Apitomy é tooling separado) |
| 2026-07-23 | 01 | `services/` → `cells/renegotiation/` + `platform/` (nova estrutura) |
| 2026-07-23 | 01 | CloudEvents 1.0 como envelope obrigatório |
| 2026-07-23 | 01 | Lakehouse Medallion com Apache Iceberg + LocalStack S3 |
| 2026-07-23 | 02 | Definido padrão de scripts operacionais sempre em Bash (.sh) para ECS/EKS/WSL |

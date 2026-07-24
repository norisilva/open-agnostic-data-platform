# ROADMAP - Plataforma Agnostica Multi-Celular

> **INSTRUCAO OBRIGATORIA PARA TODA IA (Antigravity, Cursor, Copilot, etc):**
>
> Este e o **documento-mestre de progresso** do projeto. Voce e **OBRIGADO(A)** a:
>
> 1. **LER** este arquivo completo antes de iniciar qualquer trabalho.
> 2. **ATUALIZAR** o status de cada item ao terminar (marcar `[x]`), ao iniciar (`[/]`) ou ao bloquear (`[!]`).
> 3. **NUNCA** pular uma fase. A ordem e sequencial dentro de cada fase.
> 4. **REGISTRAR** a data e Revisao no campo "Ultima atualizacao" abaixo.
> 5. Quando terminar uma **sub-fase inteira**, atualizar a % na linha da sub-fase.
> 6. Quando terminar uma **fase inteira**, marcar o status da fase como ` DONE`.
> 7. Se encontrar um bloqueio, marcar `[!]` e descrever o motivo.
> 8. **Nao criar** novos documentos de tracking. Este e o unico.
>
> **Arquivos de apoio (ler se precisar de detalhes):**
> - `PROJECT_CONTEXT.md` - Decisoes arquiteturais e configuracao
> - `docs/sdd/sdd.md` - Design de dominio
> - `docs/sda/sda.md` - Design de arquitetura
> - `docs/api-audit.md` - 12 problemas da API legada
> - `docs/services-design.md` - Detalhamento dos servicos da Plataforma
> - `docs/observability-design.md` - Stack LGTM

**Ultima atualizacao:** 2026-07-24 | Revisao: 03
**Progresso global:** ██░░░░░░░░░░░░░░░░░░ 10%

---

## Legenda de Status

```
[ ]  = Pendente (nao iniciado)
[/]  = Em progresso (IA trabalhando agora)
[x]  = Concluido e verificado
[!]  = Bloqueado (motivo descrito ao lado)
[-]  = Cancelado / descartado
```

---

## Visao Geral das Fases

| # | Fase | Status | Progresso | Estimativa |
|---|------|--------|-----------|------------|
| 0 | Fundacao & Documentacao |  DONE | 100% |  (feita) |
| 1 | Plataforma Core (CloudEvents, Schema Registry, Schema Validator) | IN_PROGRESS | 80% |  |
| 2 | Plataforma: Servicos Java Genericos (event-api, notification-service) | IN_PROGRESS | 50% |  |
| 3 | Componentes Agnosticos de Integracao (Webhooks e CDC) | ⬜ TODO | 0% | ~3 dias |
| 4 | Infraestrutura Local (K8s + Podman Kube Play) | ⬜ TODO | 0% | ~2 dias |
| 5 | Observabilidade LGTM + Dashboards | ⬜ TODO | 0% | ~2 dias |
| 6 | Lakehouse Medallion (Bronze -> Silver -> Gold) | ⬜ TODO | 0% | ~3 dias |
| 7 | Testes (Unitario, Integracao, BDD, Carga k6) | ⬜ TODO | 0% | ~4 dias |
| 8 | IaC (Terraform Cell Modules) | ⬜ TODO | 0% | ~2 dias |
| 9 | Refinamento, Demo & Documentacao Final | ⬜ TODO | 0% | ~2 dias |

---

# FASE 0 - Fundacao & Documentacao

**Status:**  DONE (100%)
**Objetivo:** Levantar toda a documentacao de base do projeto.

### 0.1 - Analise do Legado
- [x] Explorar projeto existente (legado isolado de renegociacao)
- [x] Auditar API existente - 12 problemas catalogados -> `docs/api-audit.md`

### 0.2 - Design de Servicos
- [x] Definir 5 microsservicos com responsabilidades e contratos -> `docs/services-design.md`
- [x] Definir stack de observabilidade LGTM com dashboards -> `docs/observability-design.md`

### 0.3 - Documentos de Arquitetura
- [x] Gerar SDD -> `docs/sdd/sdd.md`
- [x] Gerar SDA -> `docs/sda/sda.md`
- [x] Gerar BDD feature files -> `docs/bdd/features/*.feature` (83 cenarios)
- [x] Criar `PROJECT_CONTEXT.md`
- [x] Criar `README.md`

### 0.4 - Evolucao para Plataforma Agnostica (NOVA)
- [x] Criar `docs/platform/platform-design.md` - design multi-celular completo
- [x] Criar `docs/platform/cloudevents-envelope.md` - spec do envelope CloudEvents 1.0
- [x] Criar `docs/platform/cell-specification.md` - template de celula
- [x] Criar `docs/platform/schema-registry-guide.md` - Apicurio Registry 3.x
- [x] Criar `docs/platform/lakehouse-design.md` - Medallion (Bronze/Silver/Gold)
- [x] Atualizar `PROJECT_CONTEXT.md` com decisoes da plataforma
- [x] Atualizar `docs/sdd/sdd.md` - addendum ADR-008 (Multi-Celular), ADR-009 (CloudEvents)
- [x] Atualizar `docs/sda/sda.md` - addendum secao Plataforma e Celulas

---

# FASE 1 - Plataforma Core

**Status:** IN_PROGRESS (80%)
**Objetivo:** Criar os componentes compartilhados que viabilizam a plataforma agnostica.

### 1.1 - Envelope CloudEvents (Biblioteca Compartilhada)
- [x] Criar `platform/cloudevents-sdk/` - lib Java (jar)
  - [x] Classe `PlatformCloudEvent` com todos os campos (specversion, id, source, type, buzid, correlationid, traceparent, data)
  - [x] Builder pattern para construcao fluida
  - [x] Serializacao/Desserializacao JSON (Jackson)
  - [x] Testes unitarios da lib
- [x] Criar `platform/cloudevents-go/` - lib Go (module)
  - [x] Struct `PlatformCloudEvent` equivalente
  - [x] Marshal/Unmarshal JSON
  - [x] Testes unitarios

### 1.2 - Apicurio Schema Registry (Setup Local)
- [x] Adicionar Apicurio Registry 3.x ao manifesto K8s (`infra/k8s-local/00-platform.yaml`)
- [x] Criar schemas iniciais agnosticos e de cliente:
  - [x] `schemas/renegotiation/event-received.json` (JSON Schema)
  - [x] `schemas/renegotiation/event-validated.json`
  - [x] `schemas/renegotiation/action-completed.json`
  - [x] `schemas/renegotiation/action-failed.json`
  - [x] `schemas/renegotiation/notification-sent.json`
- [x] Script de bootstrap: registrar schemas no Apicurio via API REST
- [x] Testar UI do Apicurio em `localhost:8081`

### 1.3 - Schema Validator (Go - Worker de Validacao)
- [x] Refatorar `platform/schema-validator/` para remover AWS SQS e usar RabbitMQ
  - [x] Refatorar Consumer: migrar de SQS para RabbitMQ generico (le eventos CloudEvents)
  - [x] Valida `data` contra schema cacheado do Apicurio
  - [x] Reject -> DLQ no RabbitMQ com motivo detalhado
  - [x] Accept -> re-publica no RabbitMQ de destino
  - [x] Cache local de schemas (TTL 5min)
  - [x] OTel setup
  - [x] Containerfile (distroless ~8MB)
  - [x] Atualizar testes unitarios para RabbitMQ

### 1.4 - Camada de Persistencia CQRS Hibrido
- [x] Criar interfaces agnosticas `CommandRepository` e `QueryRepository` no core da aplicacao.
- [x] Configurar provedores de injecao de dependencia segregados: Datasource Relacional (Postgres) para Comandos e Client NoSQL (Mongo) para Queries.

---

# FASE 2 - Plataforma: Servicos Java Genericos (Quarkus)

**Status:** DONE (100%)
**Objetivo:** Criar servicos de plataforma 100% agnosticos e vendaveis. Sem nenhuma referencia a dominios de negocio engessados.

### 2.1 - platform/event-api/ (API de Entrada Generica / Command Gateway - CQRS Fast Return)
- [x] Refatorar `platform/event-api/` para remover SQS/SNS e adotar Padrao CQRS Fast Return
- [x] `pom.xml`: groupId `br.com.platform`, pacote `br.com.platform.eventapi`
- [x] `POST /api/v1/events` - recebe qualquer payload JSON (Fast Dispatching para RabbitMQ via Command Gateway)
  - [x] Header `X-Cell-Id` identifica a celula (grupo no Apicurio)
  - [x] Header `X-Event-Type` identifica o tipo de evento
  - [x] Header `Idempotency-Key` (deduplicacao via Redis, TTL configuravel)
  - [x] Valida payload contra schema do Apicurio
  - [x] **REFATORACAO CRITICA:** Remover integracao SQS/SNS do endpoint.
  - [x] Implementar `CommandRepository` (Panache/Hibernate) para salvar a intencao de comando no Postgres.
  - [x] Disparar Fast Return (HTTP 202) imediatamente apos o commit no Postgres.
- [x] POJO `PlatformEvent` em memoria para serializacao
- [x] `@RunOnVirtualThread` nos endpoints
- [x] SmallRye Health + OTel
- [x] Limpar `application.properties` removendo chaves AWS e configurando DataSource Postgres
- [x] Containerfile nativo (ubi-micro + GraalVM runner)
- [x] Atualizar testes unitarios (remover mocks de SQS)

### 2.2 - platform/notification-service/ (Notificador Generico)
- [x] Refatorar `platform/notification-service/` para remover SQS e usar RabbitMQ
- [x] Refatorar Consumer: migrar leitura de SQS para RabbitMQ generico (tipo `notification.requested`)
- [x] Renderiza template HTML via Qute (template filename vem no payload do evento)
- [x] SMTP configuravel: Mailpit (dev) / SendGrid (prod) via env vars
- [x] `POST /api/v1/notifications/resend/{eventId}` - reenvia qualquer notificacao
- [x] `GET /api/v1/notifications/{eventId}/status`
- [x] Refatorar Tabela `notification_log` (Flyway) via Panache
- [x] OTel + Virtual Threads
- [x] Limpar `application.properties` removendo chaves AWS e configurando AMQP/RabbitMQ
- [x] Containerfile nativo
- [x] Atualizar testes unitarios (remover mocks de SQS)

---

# FASE 3 - Componentes Agnosticos de Integracao (Webhooks e CDC)

**Status:** ⬜ TODO
**Objetivo:** Criar servicos de plataforma genericos para integrar com APIs de negocio dos clientes via Webhooks, mantendo a plataforma 100% agnostica.

### 3.1 - platform/webhook-validator (Validacao de Negocio)
- [ ] Criar `platform/webhook-validator/` - Quarkus 3.37+, Java 25, Virtual Threads
- [ ] Consumer RabbitMQ `validation-queue`
- [ ] `application.properties`: URL do webhook configuravel por variavel de ambiente (`WEBHOOK_VALIDATOR_URL`)
- [ ] Despacha HTTP POST assincrono para o cliente contendo o CloudEvent
- [ ] **Tratamento HTTP 200:** Validacao passou, publica no topico `event-validated` no RabbitMQ
- [ ] **Tratamento HTTP 400/422:** Validacao de negocio falhou (ex: boleto vencido).
  - Extrai a mensagem de erro do payload do cliente.
  - Publica evento `event-validation-failed` no RabbitMQ para registrar a falha (trilha de auditoria / atualizacao de status).
  - Publica evento `notification.requested` no RabbitMQ para alertar o chamador.
- [ ] OTel + Metricas (taxa de erro do webhook, latencia)

### 3.2 - platform/webhook-action (Execucao de Acoes/Saga)
- [ ] Criar `platform/webhook-action/` - Quarkus 3.37+, Java 25, Virtual Threads
- [ ] Consumer RabbitMQ para fila de execucao (`action-queue`)
- [ ] `application.properties`: URL do webhook de acao (`WEBHOOK_ACTION_URL`)
- [ ] Tenta executar a acao no cliente (ex: efetivar pagamento/recibo)
- [ ] **Retry Pattern:** Backoff exponencial para timeouts/HTTP 500
- [ ] **Compensacao (Saga):** Apos N falhas, publica evento `action-failed` e notifica via `notification-service`
- [ ] Se sucesso, publica `action-completed`

### 3.3 - platform/cdc-sync-worker (CDC Sync)
- [ ] Implementar worker (Go) que consome o topico gerado pelo Debezium (Lendo o WAL do Postgres).
- [ ] Mapeia o payload relacional bruto para o formato JSON CloudEvent.
- [ ] Faz upsert no MongoDB (QueryRepository / Read Model), garantindo consistencia eventual.

---

# FASE 4 - Infraestrutura Local (Kubernetes + Podman Kube Play)

**Status:** ⬜ TODO
**Objetivo:** Subir toda a stack local com `podman kube play`.

### 4.1 - Manifestos de Plataforma (compartilhados)
- [ ] `infra/k8s-local/00-platform.yaml`:
  - [ ] Pod Apicurio Registry 3.x (porta 8081)
  - [ ] Pod OTel Collector (portas 4317, 4318)
  - [ ] Pod Mailpit (portas 8025, 1025)

### 4.2 - Manifestos de Bancos de Dados
- [ ] `infra/k8s-local/01-databases.yaml`:
  - [ ] Pod PostgreSQL 16 (porta 5432) + ConfigMap `init.sql` (com `wal_level=logical`)
  - [ ] Pod Redis 7 Alpine (porta 6379) + ConfigMap `redis.conf`
  - [ ] Pod MongoDB 7 (porta 27017) + ConfigMap `init.js`

### 4.3 - Manifestos de Mensageria e CDC
- [ ] `infra/k8s-local/02-messaging.yaml`:
  - [ ] Pod RabbitMQ (porta 5672, 15672) + ConfigMap `init-mq.sh`
  - [ ] Pod Debezium Server (porta 8083) escutando Postgres e publicando no RabbitMQ
  - [ ] Pod Redpanda (Kafka) (porta 9092) para stream CDC analitico

### 4.4 - Manifestos de Observabilidade
- [ ] `infra/k8s-local/03-observability.yaml`:
  - [ ] Pod Prometheus (porta 9090) + ConfigMap `prometheus.yml`
  - [ ] Pod Grafana Tempo (porta 3200) + ConfigMap `tempo.yaml`
  - [ ] Pod Grafana Loki (porta 3100) + ConfigMap `loki.yaml`
  - [ ] Pod Grafana Alloy + ConfigMap `alloy-config.river`
  - [ ] Pod Grafana (porta 3000) + ConfigMaps datasources + dashboards

### 4.5 - Manifestos dos Servicos
- [ ] `infra/k8s-local/04-services.yaml`:
  - [ ] Pod event-api (porta 8080)
  - [ ] Pod webhook-validator
  - [ ] Pod webhook-action
  - [ ] Pod cdc-sync-worker
  - [ ] Pod notification-service (porta 8083)
  - [ ] Pod schema-validator

### 4.6 - Validacao Completa
- [ ] `podman kube play infra/k8s-local/00-platform.yaml` - sucesso
- [ ] `podman kube play infra/k8s-local/01-databases.yaml` - sucesso
- [ ] `podman kube play infra/k8s-local/02-messaging.yaml` - sucesso
- [ ] Verificar RabbitMQ e Debezium conectados corretamente
- [ ] `podman kube play infra/k8s-local/03-observability.yaml` - sucesso
- [ ] `podman kube play infra/k8s-local/04-services.yaml` - sucesso
- [ ] Healthchecks OK em todos os servicos

---

# FASE 5 - Observabilidade LGTM + Dashboards

**Status:** ⬜ TODO
**Objetivo:** Configurar coleta de traces, logs, metricas e dashboards E2E.

### 5.1 - OTel Collector
- [ ] `infra/observability/otel-collector-config.yaml`
  - [ ] Receivers: OTLP gRPC (4317) + OTLP HTTP (4318)
  - [ ] Processors: batch, memory_limiter, resource
  - [ ] Exporters: prometheusremotewrite, otlp (Tempo), loki
- [ ] Validar: traces Java->RabbitMQ->Go chegam no Tempo com traceId correto

### 5.2 - Alloy (Log Collection)
- [ ] `infra/observability/alloy-config.river`
- [ ] Coleta stdout/stderr de todos os pods
- [ ] Labels: `service_name`, `buzid`, `cell_name`
- [ ] Forward para Loki

### 5.3 - Grafana Datasources
- [ ] `infra/observability/grafana/datasources/datasources.yaml`
  - [ ] Prometheus, Tempo, Loki configurados

### 5.4 - Dashboards Grafana (6 dashboards)
- [ ] Dashboard 1: `platform-e2e.json` - fluxo completo ponta a ponta
- [ ] Dashboard 2: `infrastructure-health.json` - saude dos containers/pods
- [ ] Dashboard 3: `jvm-virtual-threads.json` - pool de VTs, latencia p99
- [ ] Dashboard 4: `rabbitmq-debezium.json` - metricas do broker e lag do CDC
- [ ] Dashboard 5: `webhook-tracker.json` - sucesso/falha/compensacao por webhook
- [ ] Dashboard 6: `dlq-monitor.json` - mensagens em DLQs, taxa de erro

### 5.5 - Validacao E2E
- [ ] Enviar request - verificar trace completo no Tempo (Java->Debezium->RabbitMQ->Go->Webhook)
- [ ] Verificar logs correlacionados no Loki por traceId
- [ ] Verificar metricas customizadas no Prometheus
- [ ] Screenshot de cada dashboard funcionando

---

# FASE 6 - Lakehouse Medallion (Bronze -> Silver -> Gold)

**Status:** ⬜ TODO
**Objetivo:** Pipeline analitico agnostico particionado por celula/produto.

### 6.1 - Bronze Layer (Ingestao Bruta via CDC Kafka)
- [ ] Configurar captura de dados (CDC) no PostgreSQL via Debezium/Worker local como origem analitica unica.
- [ ] Configurar pipeline que le do topico bruto do Kafka (Debezium) e escreve CloudEvents formatados na Camada Bronze do Lakehouse (MinIO).
- [ ] MinIO bucket `MinIO://bronze/`
- [ ] Particionamento: `buzid/year/month/day/`
- [ ] Apache Iceberg table definition (append-only)

### 6.2 - Silver Layer (Limpeza e Conformidade)
- [ ] MinIO bucket `MinIO://silver/`
- [ ] Job Spark (container) ou script Python (PyIceberg)
  - [ ] Le Bronze
  - [ ] Valida contra schema do Apicurio
  - [ ] Deduplica (CDC)
  - [ ] Converte `data` em colunas Iceberg tipadas
- [ ] Schema evolution dinamica acompanhando Apicurio

### 6.3 - Gold Layer (Modelagem Dimensional)
- [ ] MinIO bucket `MinIO://gold/`
- [ ] Tabela: `cell_business_summary` (visao de negocio do produto)
- [ ] Tabela: `platform_events_daily` (visao agnostica por celula)
- [ ] Consultavel via PyIceberg / Spark

### 6.4 - Catalogo e Consultas
- [ ] Infra Glue simulado (Nessie/Hive Metastore local) como catalogo Iceberg
- [ ] Script de consulta exemplo com PyIceberg
- [ ] Documentar caminho de evolucao para Athena/EMR real

---

# FASE 7 - Testes (Unitario, Integracao, BDD, Carga)

**Status:** ⬜ TODO
**Objetivo:** Cobertura de testes em todas as camadas da Plataforma.

### 7.1 - Testes Unitarios
- [ ] Java (JUnit 5 + Mockito): event-api, webhook-validator, webhook-action, notification-service
- [ ] Go (`go test`): schema-validator, cdc-sync-worker

### 7.2 - Testes de Integracao
- [ ] Quarkus `@QuarkusTest` com RabbitMQ e Testcontainers Postgres/Mongo (event-api)
- [ ] Go integration tests com RabbitMQ e Mongo (cdc-sync-worker)
- [ ] Redis integration tests (idempotencia event-api)
- [ ] Schema Validator: validacao contra Apicurio Registry real (test container)

### 7.3 - BDD (Cucumber + Godog)
- [ ] Implementar step definitions Cucumber (Java) para Webhooks e API
- [ ] Implementar step definitions Godog (Go) para CDC e Validator
- [ ] Criar feature files novos:
  - [ ] `platform_cell_provisioning.feature`
  - [ ] `schema_registry_validation.feature`
- [ ] Escrever testes de integracao validando o "Sync Lag" (latencia do CQRS): Escrita Postgres -> Leitura Mongo.
- [ ] Adicionar cenarios em `docs/bdd/features/cqrs_eventual_consistency.feature` garantindo que os clientes consumam do Mongo sem lockar o Postgres.
- [ ] Integrar BDD no script de teste
- [ ] Gerar relatorio HTML dos testes BDD

### 7.4 - Testes E2E
- [ ] Postman/Newman collection para fluxo completo (POST -> CQRS/CDC -> Validator -> Action -> Notificacao)
- [ ] Script de smoke test automatizado

### 7.5 - Testes de Carga (k6)
- [ ] Script k6: stress test na API de ingestao (500 VUs)
- [ ] Script k6: validar throughput do RabbitMQ + workers Go
- [ ] Script k6: cenario multi-celula (envios simultaneos de produtos diferentes)
- [ ] Validar metricas SLI no Prometheus sob carga
- [ ] Validar alertas Grafana sob carga
- [ ] Documentar resultados e limites encontrados

---

# FASE 8 - IaC (Terraform Cell Modules)

**Status:** ⬜ TODO
**Objetivo:** Provisionar celulas automaticamente via Terraform + RabbitMQ.

### 8.1 - Modulo Cell
- [ ] `infra/terraform/modules/cell/main.tf`
  - [ ] Variaveis: `cell_name`, `buzid`, `rabbitmq_exchanges`, `rabbitmq_queues`, `webhooks_urls`
  - [ ] Cria RabbitMQ Exchanges para a celula
  - [ ] Cria RabbitMQ queues + binding/subscriptions
  - [ ] Cria DLQs

### 8.2 - Ambiente Local
- [ ] `infra/terraform/environments/local/main.tf`
  - [ ] Provider: Infra com RabbitMQ endpoint
  - [ ] Instancia modulo cell para `test-cell-a`
  - [ ] `terraform init` + `terraform apply` funciona contra o RabbitMQ local

### 8.3 - Documentacao
- [ ] README do Terraform com instrucoes de uso
- [ ] Documentar caminho para multi-celula (cell-b, cell-c)

---

# FASE 9 - Refinamento, Demo & Documentacao Final

**Status:** ⬜ TODO
**Objetivo:** Fechar o projeto com qualidade.

### 9.1 - Documentacao
- [ ] `README.md` completo com instrucoes de start local (passo a passo)
- [ ] Atualizar todos os documentos `docs/` com estado final
- [ ] Atualizar `PROJECT_CONTEXT.md` com todas as decisoes tomadas

### 9.2 - Demo
- [ ] Script de demo automatizado (`scripts/demo.sh`):
  - [ ] Sobe toda a infra (`podman kube play`)
  - [ ] Registra schemas no Apicurio
  - [ ] Envia request de evento
  - [ ] Mostra trace no Grafana
  - [ ] Mostra notificacao recebida
  - [ ] Mostra dados no Lakehouse Bronze
- [ ] Gravar/documentar o fluxo completo (screenshots ou script narrado)

### 9.3 - Revisao Final
- [ ] Smoke test completo do sistema
- [ ] Revisar todos os Containerfiles
- [ ] Revisar todos os schemas no Apicurio
- [ ] Verificar que nenhum secret/credential esta hardcoded
- [ ] Marcar este roadmap como 100% 

---

# Changelog (Registro de mudancas no Roadmap)

| Data | Revisao | Mudanca |
|------|---------|---------|
| 2026-07-23 | 01 | Criacao inicial (sistema de renegociacao) |
| 2026-07-23 | 01 | Evolucao para Plataforma Agnostica Multi-Celular |
| 2026-07-23 | 01 | Apicurio Registry confirmado |
| 2026-07-23 | 01 | `services/` -> `cells/renegotiation/` + `platform/` (nova estrutura) |
| 2026-07-23 | 01 | CloudEvents 1.0 como envelope obrigatorio |
| 2026-07-23 | 01 | Lakehouse Medallion com Apache Iceberg + MinIO |
| 2026-07-23 | 02 | Definido padrao de scripts operacionais sempre em Bash (.sh) |
| 2026-07-24 | 03 | Refatoracao completa p/ remocao de vies AWS/SQS/DynamoDB e adocao de RabbitMQ, Debezium, Mongo, Webhooks |

# PROJECT CONTEXT - Plataforma Agnostica Multi-Celular
> **Leia este arquivo + `ROADMAP.md` em toda nova sessao.**
> Ultima atualizacao: 2026-07-24 | Sessao: 01

---

## Objetivo do Projeto

**Plataforma agnostica de processamento de eventos financeiros**, baseada em Cell-Based Architecture.
Microsservicos poliglotas (Java 25+ e Go 1.22), CloudEvents (CNCF), Apicurio Schema Registry,
Lakehouse Medallion (Apache Iceberg), observabilidade LGTM completa.

O primeiro **produto-cliente** da plataforma e o sistema de **Renegociacao de Dividas (> 180 dias)**, atuando como Celula 01.

Infraestrutura local via **Kubernetes YAML (`podman kube play`)** - sem Docker.
Horizonte: ~30 dias de desenvolvimento incremental.

---

## Tracking de Progresso

> **O arquivo de tracking e `ROADMAP.md`** (na raiz do projeto).
> Ele contem 10 fases, sub-fases detalhadas e instrucoes de atualizacao.
> Nao use `task.md` - ele foi substituido pelo ROADMAP.

---

## Decisoes Tomadas (nao reverter sem discussao)

| # | Decisao | Justificativa | Data |
|---|---------|---------------|------|
| 1 | Java 25+ + Quarkus 3.37+ | Virtual Threads nativas e otimizacoes de startup | 2026-07-23 |
| 2 | Go 1.22 para workers | Goroutines, startup zero, imagens ultraleves | 2026-07-23 |
| 3 | Hexagonal Architecture no Quarkus | Testabilidade, isolamento de dependencias | 2026-07-23 |
| 4 | Clean Architecture no Go | Controle de deps, interfaces para test mocks | 2026-07-23 |
| 5 | Podman Kube Play (nao Docker) | K8s manifests nativos | 2026-07-23 |
| 6 | `Containerfile` (nao `Dockerfile`) | Podman usa Containerfile por padrao | 2026-07-23 |
| 7 | LGTM stack (Loki+Grafana+Tempo+Prom) | Padrao de observabilidade E2E | 2026-07-23 |
| 8 | OTel Collector como hub central | Desacopla servicos dos backends analiticos | 2026-07-23 |
| 9 | W3C TraceContext via headers AMQP | traceId end-to-end Java->Go via RabbitMQ | 2026-07-23 |
| 10 | Mailpit para email local | SMTP mock sem internet | 2026-07-23 |
| 11 | PostgreSQL (Write Store / Comandos) | Fonte da Verdade. Consistencia transacional ACID. | 2026-07-24 |
| 12 | Redis (Cache / Rate Limiting) | Idempotencia rapida nas APIs (TTL 24h) | 2026-07-23 |
| 13 | MongoDB (Read Store / Consultas) | CQRS Hibrido. JSON desnormalizado para as APIs. | 2026-07-24 |
| 14 | RabbitMQ (Fan-out) + Kafka (Lakehouse)| Zero vendor lock-in. Substitui SNS/SQS da AWS. | 2026-07-24 |
| 15 | Saga Coreografado (nao orquestrado) | Evita SPOF do orquestrador via Webhooks | 2026-07-23 |
| 16 | Correlacao de Entidade (`baseEntityId`) | Link do evento a entidade base original do negocio | 2026-07-23 |
| 17 | Debezium (Change Data Capture) | Padrao Outbox/CDC passivo lendo WAL do Postgres | 2026-07-24 |
| 18 | **Plataforma Multi-Celular** | Codigo unico, infra isolada por produto | 2026-07-23 |
| 19 | **CloudEvents 1.0 (CNCF)** | Envelope padronizado, agnostico de dominio | 2026-07-23 |
| 20 | **Apicurio Registry 3.x** | Schema Registry com UI, validacao dinamica | 2026-07-23 |
| 21 | **Lakehouse Medallion (Iceberg + MinIO)** | Pipeline analitico isolado. Sem carga na base transacional | 2026-07-24 |
| 22 | **Terraform para IaC de Celulas** | Provisionamento automatizado de celulas | 2026-07-23 |
| 23 | **k6 para testes de carga** | Stress test da API e validacao SLI | 2026-07-23 |
| 24 | **Scripts operacionais em Bash (.sh)** | Portabilidade para Linux/WSL (NAO usar `.ps1`) | 2026-07-23 |
| 25 | **Java 25 + GraalVM + Virtual Threads** | MANDATORIO e INEGOCIAVEL para servicos Java. | 2026-07-23 |
| 26 | **12-Factor App (Terraform-ready)** | Servicos 100% parametrizaveis (application.properties). | 2026-07-23 |
| 27 | **Plataforma agnostica e vendavel** | NENHUM servico de plataforma pode ter regras engessadas. Clientes customizam via schemas Apicurio e Webhooks. | 2026-07-24 |
| 28 | **Regra CQRS No Dual-Write** | A API Gateway (`event-api`) NAO publica mensagens nem salva no Mongo. Ela salva no Postgres (CommandRepository) e retorna 202 (Fast Return). O Debezium orquestra o resto. | 2026-07-24 |

---

## Estrutura de Diretorios (Target Final)

```
agnostic-platform/
├── ROADMAP.md                             # TRACKING MASTER (fases, status, %)
├── PROJECT_CONTEXT.md                     # este arquivo (decisoes, configs)
├── README.md
├── .agents/AGENTS.md                      # regras estritas para IAs (ex: CQRS, sem acento)
│
├── docs/
│   ├── arch/                              (diagramas originais)
│   ├── study/                             (estudo inicial)
│   ├── sdd/sdd.md                         # Software Design Document
│   ├── sda/sda.md                         # Software Design Architecture
│   ├── bdd/features/*.feature             # 83 cenarios BDD
│   ├── api-audit.md                       # 12 problemas da API base legada
│   ├── services-design.md                 # Detalhamento da Topologia Agnostica
│   ├── observability-design.md            # Stack LGTM
│   ├── platform/                          
│       ├── platform-design.md             # Design multi-celular
│       ├── cloudevents-envelope.md        # Spec do envelope
│       ├── cell-specification.md          # Template de celula
│       ├── schema-registry-guide.md       # Apicurio Registry
│       └── lakehouse-design.md            # Medallion (Bronze/Silver/Gold)
│
├── platform/                              # componentes compartilhados agnosticos
│   ├── event-api/                         # Java 25+ (Gateway/Ingestao CQRS Fast Return)
│   ├── cdc-sync-worker/                   # Go 1.22 ou Java (Persiste Read Model no Mongo via CDC)
│   ├── webhook-validator/                 # Java 25+ (Validacao de Negocio generica via Webhook)
│   ├── webhook-action/                    # Java 25+ (Execucao de acoes e sagas via Webhook)
│   ├── notification-service/              # Java 25+ (Notificacoes multicanal)
│   ├── schema-validator/                  # Go 1.22 (Validacao de schemas json via Apicurio)
│   └── cloudevents-sdk/                   # Lib Java (jar) e Go (module)
│
├── analytics/                             # Lakehouse Medallion
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── schemas/                               # JSON Schemas registrados no Apicurio
│   └── renegociation/
│       ├── event-received.json
│       ├── event-validated.json
│       ├── action-completed.json
│       └── notification-sent.json
│
└── infra/
    ├── k8s-local/
    │   ├── 00-platform.yaml              # Apicurio, OTel, Mailpit
    │   ├── 01-databases.yaml             # PG (wal_level=logical), Redis, MongoDB, Debezium Server
    │   ├── 02-messaging.yaml             # RabbitMQ, Kafka
    │   ├── 03-observability.yaml         # Prometheus, Tempo, Loki, Grafana
    │   └── 04-services.yaml              # Plataforma + Celulas
    ├── terraform/
    ├── postgres/init.sql                 # Setup do banco de dados (users/logical_repl)
    ├── redis/redis.conf
    ├── mongodb/init.js
    └── observability/
```

---

## Servicos - Resumo Rapido (Plataforma)

| ID | Servico | Lang | Tipo | Observacoes |
|----|---------|------|------|-------------|
| PLT-01 | `event-api` | Java 25+ | Gateway CQRS | Ingestao, salva no PG, HTTP 202 (Fast Return) |
| PLT-02 | `schema-validator` | Go 1.22 | Worker | Consome RMQ, valida formato no Apicurio |
| PLT-03 | `cdc-sync-worker` | Go 1.22 | Worker | Consome RMQ (Fanout), upsert no MongoDB |
| PLT-04 | `webhook-validator` | Java 25+ | Worker | Aciona API da Celula p/ validar negocio |
| PLT-05 | `webhook-action` | Java 25+ | Worker | Aciona API da Celula p/ efetivar e sagas |

*(Servicos de celula clientes (SVC-*) serao conteinerizados isoladamente conforme a contratacao da plataforma)*

---

## Envelope CloudEvents (Contrato Obrigatorio)

Todo evento na plataforma usa este formato:
```json
{
  "specversion":    "1.0",
  "id":             "<uuid>",
  "source":         "cells/<cell-name>/<service-name>",
  "type":           "br.com.platform.<product>.<event>.v<version>",
  "time":           "<ISO-8601 UTC>",
  "datacontenttype":"application/json",
  "schemaurl":      "http://apicurio:8080/apis/registry/v2/groups/<product>/artifacts/<event>",
  "buzid":          "<cell-id>",
  "correlationid":  "<saga-id>",
  "traceparent":    "<W3C trace context>",
  "data": { /* payload agnostico embutido */ }
}
```

---

## Como Iniciar uma Nova Sessao

1. Leia `ROADMAP.md` (encontre onde paramos: primeiro `[ ]` ou `[/]`)
2. Leia `PROJECT_CONTEXT.md` (este arquivo)
3. Verifique regras estritas em `.agents/AGENTS.md` (IMPORTANTE)
4. Se precisar de detalhes tecnicos, consulte `docs/sdd/sdd.md` e `docs/sda/sda.md`
5. Ao trabalhar: marque `[/]` no ROADMAP ao iniciar, `[x]` ao terminar. Respeite as regras globais de IA.

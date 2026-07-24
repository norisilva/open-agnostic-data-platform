# PROJECT CONTEXT — Plataforma Agnóstica Multi-Celular
> **Leia este arquivo + `ROADMAP.md` em toda nova sessão.**
> Última atualização: 2026-07-23 | Sessão: 01

---

## Objetivo do Projeto

**Plataforma agnóstica de processamento de eventos financeiros**, baseada em Cell-Based Architecture.
Microsserviços políglotas (Java 25+ e Go 1.22), CloudEvents (CNCF), Apicurio Schema Registry,
Lakehouse Medallion (Apache Iceberg), observabilidade LGTM completa.

O primeiro **produto-cliente** da plataforma é o sistema de **Renegociação de Dívidas (> 180 dias)**.

Infraestrutura local via **Kubernetes YAML (`podman kube play`)** — sem Docker.
Horizonte: ~30 dias de desenvolvimento incremental.

---

## Tracking de Progresso

> **O arquivo de tracking é `ROADMAP.md`** (na raiz do projeto).
> Ele contém 10 fases, sub-fases detalhadas e instruções de atualização.
> Não use `task.md` — ele foi substituído pelo ROADMAP.

---

## Decisões Tomadas (não reverter sem discussão)

| # | Decisão | Justificativa | Data |
|---|---------|---------------|------|
| 1 | Java 25+ + Quarkus 3.21 (LTS) | Virtual Threads, Leyden, últimas features JVM | 2026-07-23 |
| 2 | Go 1.22 para workers SQS | Goroutines, startup zero, imagem ~8MB | 2026-07-23 |
| 3 | Hexagonal Architecture no Quarkus | Testabilidade, isolamento de dependências | 2026-07-23 |
| 4 | Clean Architecture no Go | Controle de deps, interfaces para test mocks | 2026-07-23 |
| 5 | Podman Kube Play (não Docker) | K8s manifests nativos, máquina só tem Podman | 2026-07-23 |
| 6 | `Containerfile` (não `Dockerfile`) | Podman usa Containerfile por padrão | 2026-07-23 |
| 7 | LGTM stack (Loki+Grafana+Tempo+Prom) | Padrão mercado 2026, tudo local | 2026-07-23 |
| 8 | OTel Collector como hub central | Desacopla serviços dos backends | 2026-07-23 |
| 9 | W3C TraceContext via SQS headers | traceId end-to-end Java→Go | 2026-07-23 |
| 10 | Mailpit para email local | SMTP mock sem internet | 2026-07-23 |
| 11 | PostgreSQL write-store (CQRS) | Consistência transacional ACID | 2026-07-23 |
| 12 | Redis read-store + idempotência | Cache + prevenção de duplicatas (TTL 24h) | 2026-07-23 |
| 13 | MongoDB para audit + receipts | Flexibilidade de schema, append-only | 2026-07-23 |
| 14 | SNS fan-out para todos os eventos | Desacoplamento, múltiplos subscribers | 2026-07-23 |
| 15 | Saga coreografado (não orquestrado) | Evita SPOF do orquestrador | 2026-07-23 |
| 16 | Correlação de Entidade (`baseEntityId`) | Link do evento ↔ entidade base original do negócio | 2026-07-23 |
| 17 | MongoDB Change Streams | Reatividade CDC nativo para Go workers | 2026-07-23 |
| 18 | **Plataforma Multi-Celular (Cell-Based Arch)** | Código único, infra isolada por produto | 2026-07-23 |
| 19 | **CloudEvents 1.0 (CNCF)** | Envelope padronizado, agnóstico de domínio | 2026-07-23 |
| 20 | **Apicurio Registry 3.x (CNCF Sandbox)** | Schema Registry com UI, validação dinâmica | 2026-07-23 |
| 21 | **Lakehouse Medallion (Iceberg + S3)** | Pipeline analítico Bronze→Silver→Gold | 2026-07-23 |
| 22 | **Terraform para IaC de Células** | Provisionamento automatizado de células | 2026-07-23 |
| 23 | **k6 para testes de carga** | Stress test da API e validação SLI | 2026-07-23 |
| 24 | **Scripts operacionais em Bash (.sh)** | Portabilidade para Linux/ECS/EKS/WSL (NÃO usar `.ps1`) | 2026-07-23 |
| 25 | **Java 25 + GraalVM + Virtual Threads** | MANDATÓRIO e INEGOCIÁVEL para todos os serviços feitos em Java. | 2026-07-23 |
| 26 | **Design for IaC (Terraform-ready)** | Serviços devem ser 100% parametrizáveis (12-Factor App) para facilitar o futuro deploy automatizado via Terraform. | 2026-07-23 |
| 27 | **Plataforma agnóstica e vendavel** | NENHUM serviço de plataforma pode ter nomes de domínio de negócio (`payment`, `renegotiation`, `nori`, etc). O cliente customiza via schemas Apicurio + templates Qute + env vars. Pacotes: `br.com.platform.*`. Nomes de servico: `event-api`, `notification-service`, `cell-router`, `schema-validator`. | 2026-07-23 |
| 28 | **CQRS Fast Dispatching** | A API Gateway (`event-api`) NÃO pode ter acoplamento/acesso síncrono a bancos relacionais (SQL). Ela deve fazer apenas Fast Dispatching (validação, Redis para cache/idempotência e publish no SNS/Broker). A persistência é assíncrona feita pelo `platform/event-persister`. | 2026-07-24 |

---

## Estrutura de Diretórios (Target Final)

```
agnostic-platform/
├── ROADMAP.md                             ← TRACKING MASTER (fases, status, %)
├── PROJECT_CONTEXT.md                     ← este arquivo (decisões, configs)
├── README.md
├── .cursorrules                           ← instrução para IAs
│
├── docs/
│   ├── arch/                              (existente — diagramas originais)
│   ├── study/                             (existente — estudo inicial)
│   ├── sdd/sdd.md                         ← Software Design Document
│   ├── sda/sda.md                         ← Software Design Architecture
│   ├── bdd/features/*.feature             ← 83 cenários BDD
│   ├── api-audit.md                       ← 12 problemas API legada
│   ├── services-design.md                 ← Detalhamento dos 5 serviços
│   ├── observability-design.md            ← Stack LGTM
│   └── platform/                          ← NOVO
│       ├── platform-design.md             ← Design multi-celular
│       ├── cloudevents-envelope.md         ← Spec do envelope
│       ├── cell-specification.md          ← Template de célula
│       ├── schema-registry-guide.md       ← Apicurio Registry
│       └── lakehouse-design.md            ← Medallion (Bronze/Silver/Gold)
│
├── platform/                              ← NOVO: componentes compartilhados agnósticos
│   ├── event-api/                         ← Java 25+ (Gateway/Ingestão CQRS)
│   ├── event-persister/                   ← Java 25+ (Persiste no Mongo)
│   ├── event-cdc-publisher/               ← Java 25+ (Mongo CDC -> Kafka/Redis)
│   ├── webhook-validator/                 ← Java 25+ (Validação de Negócio genérica)
│   ├── webhook-action/                    ← Java 25+ (Execução de ações genérica)
│   ├── notification-service/              ← Java 25+ (Notificações genéricas)
│   ├── schema-validator/                  ← Go 1.22 (Validação de schemas)
│   └── cloudevents-sdk/                   ← Lib Java (jar)
│
├── analytics/                             ← NOVO: Lakehouse Medallion
│   ├── bronze/
│   ├── silver/
│   └── gold/
│
├── schemas/                               ← NOVO: JSON Schemas por produto
│   └── product-a/
│       ├── event-received.json
│       ├── event-validated.json
│       ├── action-completed.json
│       ├── action-failed.json
│       └── notification-sent.json
│
└── infra/
    ├── k8s-local/
    │   ├── 00-platform.yaml              ← Apicurio, OTel, Mailpit
    │   ├── 01-databases.yaml             ← PG, Redis, MongoDB
    │   ├── 02-messaging.yaml             ← LocalStack (SNS/SQS)
    │   ├── 03-observability.yaml         ← Prometheus, Tempo, Loki, Grafana
    │   └── 04-services.yaml              ← Todos os serviços da célula
    ├── terraform/
    │   ├── modules/cell/
    │   └── environments/local/
    ├── localstack/init-aws.sh
    ├── postgres/init.sql
    ├── redis/redis.conf
    ├── mongodb/init.js
    └── observability/
        ├── otel-collector-config.yaml
        ├── prometheus.yml
        ├── tempo.yaml
        ├── loki.yaml
        ├── alloy-config.river
        └── grafana/
            ├── datasources/datasources.yaml
            └── dashboards/*.json
```

---

## Serviços — Resumo Rápido

### Plataforma (Compartilhados)

| ID | Serviço | Lang | Tipo | Porta |
|----|---------|------|------|-------|
| PLT-01 | `cell-router` | Java 25+ | API Gateway | 8080 |
| PLT-02 | `schema-validator` | Go 1.22 | Worker | — |

### Célula Genérica (Instanciada por Produto)

| ID | Serviço | Lang | Tipo | Porta | Banco |
|----|---------|------|------|-------|-------|
| SVC-01 | `quarkus-cell-api` | Java 25+ | REST API | 8082 | PG + Redis |
| SVC-02 | `go-business-validator` | Go 1.22 | SQS Worker | — | PG |
| SVC-03 | `go-audit-logger` | Go 1.22 | SQS + Mongo Streams | — | MongoDB |
| SVC-04 | `go-action-worker` | Go 1.22 | SQS Worker | — | MongoDB + PG |
| SVC-05 | `quarkus-notification-worker`| Java 25+ | SQS Worker + API | 8083 | PG |

---

## Envelope CloudEvents (Contrato Obrigatório)

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
  "data": { /* payload específico do produto */ }
}
```

---

## Como Iniciar uma Nova Sessão

```
1. Leia ROADMAP.md (encontre onde paramos: primeiro [ ] ou [/])
2. Leia PROJECT_CONTEXT.md (decisões e configs)
3. Se precisar de detalhes de domínio → docs/sdd/sdd.md
4. Se precisar de detalhes de arquitetura → docs/sda/sda.md
5. Informe: "Sessão XX — continuando na Fase Y, Sub-fase Z"
6. Ao trabalhar: marque [/] no ROADMAP ao iniciar, [x] ao terminar
```

---

## Problemas Conhecidos da API Existente (a corrigir na Fase 2)

> Ver `docs/api-audit.md` para lista completa dos 12 problemas.

Top 4 críticos:
1. Interface `ProcessorPort` usa `double`, implementação usa `BigDecimal` — polimorfismo quebrado
2. Pagamento via HTTP GET com dados sensíveis na URL
3. `PayDomain` com 8 campos, 0 preenchidos — domínio morto
4. Configs hardcoded (`queueUrl`, `accessKey`) — `application.properties` vazio

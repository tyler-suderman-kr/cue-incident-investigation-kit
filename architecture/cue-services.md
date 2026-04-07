# Cue Services - Architecture Overview

> Repo paths are configured in `.env` (supports both original and renamed repos).

---

## Service Map

```
Cue Frontend (React App) — browser
  ↓ calls via @ax/arrivals-consumer-layer-sdk
cue-prod (Node.js server) — serves static app + proxies all API calls via serve.js
  ↓ proxies to
ACL (Arrivals Consumer Layer) - NestJS Backend
  ↓ calls backend services via ECSB proxy gateway
  ├─ CQS (Cue Query Service) - Azure Functions  [owned]
  ├─ PSL                                         [unknown — Azure-hosted, called by ACL]
  ├─ Reaping                                     [unknown — Azure-hosted, called by ACL]
  ├─ KCP Order Service
  ├─ Pick Order Service
  ├─ Pick Creation Service
  ├─ Staging Core Service
  ├─ Item Containers Service
  ├─ Store Properties Service
  ├─ DESP (Kafka → Azure Event Hub)
  └─ Ping (authentication)

CQS (Cue Query Service) - Azure Functions
  ├─ view-query-service
  ├─ event-processor
  ├─ kafka-consumer-func
  ├─ view-generator
  └─ mock-event-generator
```

---

## Services We Own

### Cue Frontend + Server Proxy (`cue-prod`)
- **Tech:** React, Redux, TypeScript (frontend) + Node.js / serve.js (server)
- **Repo:** `$CUE_REPO_PATH`
- **k8s workload:** `cue-prod`
- **Purpose:** Serves the React app to store associates and proxies all API calls through to ACL via http-proxy-middleware (HPM)
- **Key detail:** `cue-prod` is both a static file server and an API proxy. All data endpoints go through it before reaching ACL. If ACL is unreachable, `cue-prod` logs `[HPM] ECONNREFUSED` and all data fails to load — UI remains interactive but shows nothing.

### ACL (Arrivals Consumer Layer)
- **Tech:** NestJS, TypeScript
- **Repo:** `$ACL_REPO_PATH`
- **k8s workload:** `arrivals-consumer-layer-prod`
- **Purpose:** Backend API / BFF — aggregates data from all backend services
- **Key endpoints:** `/orders`, `/trolleys`, `/containers`, `/pick-app-router`, `/service-counter-items`, `/power-bi`
- **Internal modules:** Bulk, Orders, Containers, Service, HTTP Utils
- **Known issue:** Memory leak causes recurring pod crash/restart cycles. During restart windows, `cue-prod` receives ECONNREFUSED and all data fails. Self-heals but recurs. Not formally ticketed as of 2026-04-07.

### CQS (Cue Query Service)
- **Tech:** Azure Functions, TypeScript
- **Repo:** `$CQS_REPO_PATH`
- **URL:** `https://fn-cue-query-{env}.azurewebsites.net/api`
- **Purpose:** CQRS read model for orders/trolleys
- **Key functions:** `orderSummaryViewQuery`, `trolleySummaryViewQuery`

---

## External Dependencies

See `external-deps.md` for full details.

| Service | URL Pattern | Called By |
|---------|-------------|-----------|
| KCP Order | `ecsb-{env}.kroger.com/kcp-order` | ACL |
| Pick Order | `ecsb-{env}.kroger.com` | ACL |
| Pick Creation | `ecsb-{env}.kroger.com/pick-creation` | ACL |
| Staging Core | `ecsb-{env}.kroger.com/staging-core` | ACL |
| Item Containers | `ecsb-{env}.kroger.com` | ACL |
| Store Properties | `ecsb-{env}.kroger.com` | ACL |
| DESP (Kafka) | — Azure Event Hub | ACL |
| Ping | — | ACL (authentication) |
| PSL | — unknown | ACL (purpose unknown) |
| Reaping | — unknown | ACL (purpose unknown) |

---

## Namespace Context

Our services share the `aensys-prod` Kubernetes namespace with the **Excitebike/FullFill team**. Their services (`fullfill-prod`, `fullfill-consumer-layer-prod`) are unrelated to ours but appear in the same namespace log queries. Filter them out when doing health checks.

| Team | k8s workload names |
|---|---|
| Cue (us) | `cue-prod`, `arrivals-consumer-layer-prod` |
| Excitebike/FullFill | `fullfill-prod`, `fullfill-consumer-layer-prod` |

Excitebike Atlassian space: `FST` — see [Excitebike FullFill DevOps Troubleshooting Guide](https://kroger.atlassian.net/wiki/spaces/FST/pages/425517990/Excitebike+FullFill+DevOps+Troubleshooting+Guide)

---

## Infrastructure Notes

### ECSB Proxy
All ACL calls to backend services (KCP Order, Pick Order, etc.) route through the **ECSB proxy** (`ecsb-{env}.kroger.com`). If ECSB is degraded, all backend calls fail simultaneously. See `external-deps.md` for service-level details.

### Kubernetes Clusters
Production runs across two on-prem clusters:
- **HDC** (`rch-hdc-cxprod`) 
- **CDC** (`rch-cdc-cxprod`)

Cluster-specific issues (e.g. SSL cert problems on one cluster) can cause split behavior — one cluster healthy, one not. This explains why issues are sometimes not reproducible from a dev machine.

---

**Last Updated:** 2026-04-07
**Source:** Code audit of cue/acl/cqs repos + INC11638105 investigation + docs/client-architecture.png + docs/network-architecture.jpg

# Cue Services - Architecture Overview

> Repo paths are configured in `.env` (supports both original and renamed repos).

---

## Service Map

```
Cue Frontend (React App)
  ↓ calls via @ax/arrivals-consumer-layer-sdk
ACL (Arrivals Consumer Layer) - NestJS Backend
  ↓ calls these services:
  ├─ CQS (Cue Query Service) - Azure Functions  [owned]
  ├─ KCP Order Service
  ├─ Pick Order Service
  ├─ Pick Creation Service
  ├─ Staging Core Service
  ├─ Item Containers Service
  ├─ Store Properties Service
  ├─ DESP (Kafka topics for events)
  └─ LDAP (authentication)

CQS (Cue Query Service) - Azure Functions
  ├─ view-query-service
  ├─ event-processor
  ├─ kafka-consumer-func
  ├─ view-generator
  └─ mock-event-generator
```

---

## Services We Own

### Cue Frontend
- **Tech:** React, Redux, TypeScript
- **Repo:** `$CUE_REPO_PATH`
- **Purpose:** UI for store associates
- **Depends on:** ACL SDK only

### ACL (Arrivals Consumer Layer)
- **Tech:** NestJS, TypeScript
- **Repo:** `$ACL_REPO_PATH`
- **Purpose:** Backend API / BFF
- **Key endpoints:** `/orders`, `/trolleys`, `/containers`, `/pick-app-router`, `/service-counter-items`, `/power-bi`

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
| DESP (Kafka) | — | ACL |
| LDAP | — | ACL |

---

**Last Updated:** 2026-04-06
**Source:** Code audit of cue/acl/cqs repos

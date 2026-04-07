# External Service Dependencies

> Services we depend on but do not own. Update after each investigation.

---

## Infrastructure / Gateways

| Service | Purpose | Used By | Notes |
|---------|---------|---------|-------|
| ECSB Proxy | Gateway for all backend service calls | ACL | All services below route through `ecsb-{env}.kroger.com`. ECSB outage = all backend calls fail simultaneously. |
| DESP (Kafka) | Event streaming — topics: `kcp_order`, `fulfillment`, `fulfillment-cdc` | ACL | Backed by Azure Event Hub |
| Ping | Authentication | ACL | Replaced Okta |

## Backend Services (via ECSB Proxy)

All called by ACL through `ecsb-{env}.kroger.com`.

| Service | URL path | Owner |
|---------|----------|-------|
| KCP Order | `/kcp-order` | TBD |
| Pick Order | TBD | TBD |
| Pick Creation | `/pick-creation` | TBD |
| Staging Core | `/staging-core` | TBD |
| Item Containers | TBD | TBD |
| Store Properties | TBD | TBD |

## Unknown Dependencies (seen in architecture diagrams, purpose unclear)

| Service | Called By | Notes |
|---------|-----------|-------|
| PSL | ACL | Visible in client-architecture.png alongside CQS — likely Azure-hosted. Purpose unknown. |
| Reaping | ACL | Visible in client-architecture.png alongside CQS — likely Azure-hosted. Purpose unknown. |

---

## Investigation History

| Date | Service | Finding |
|------|---------|---------|
| — | — | — |

---

**Last Updated:** 2026-04-07
**Source:** docs/client-architecture.png + docs/network-architecture.jpg + INC11638105 investigation

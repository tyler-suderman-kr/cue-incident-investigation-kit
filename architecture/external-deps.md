# External Service Dependencies

> Services we depend on but do not own. Update after each investigation.

---

## Backend Services

| Service | URL | Called By | Owner |
|---------|-----|-----------|-------|
| KCP Order | `ecsb-{env}.kroger.com/kcp-order` | ACL | TBD |
| Pick Order | `ecsb-{env}.kroger.com` | ACL | TBD |
| Pick Creation | `ecsb-{env}.kroger.com/pick-creation` | ACL | TBD |
| Staging Core | `ecsb-{env}.kroger.com/staging-core` | ACL | TBD |
| Item Containers | `ecsb-{env}.kroger.com` | ACL | TBD |
| Store Properties | `ecsb-{env}.kroger.com` | ACL | TBD |

## Infrastructure

| Service | Purpose | Used By |
|---------|---------|---------|
| DESP (Kafka) | Event streaming — topics: `kcp_order`, `fulfillment`, `fulfillment-cdc` | ACL |
| LDAP | User authentication | ACL |

---

## Investigation History

| Date | Service | Finding |
|------|---------|---------|
| — | — | — |

---

**Last Updated:** 2026-04-06

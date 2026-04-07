---
incident: INC11638105
date: 2026-04-04
highest severity: P2
status: In Progress
services: cue, acl, cqs
---

# INC11638105 — Cue not loading / orders and trolleys not showing

**Affected:** Store 00737-018 (Kroger Marketplace, Michigan). Single store reported; broader scope unconfirmed.
**Duration:** 2026-04-03 13:44 PT – unresolved as of 2026-04-06

## Root Cause

Known ACL memory leak. ACL (`arrivals-consumer-layer-prod`) has a known memory leak that causes pods to become unhealthy and restart repeatedly in a cycle: leak → OOMKill/crash → k8s replaces pods → healthy briefly → leak resumes. During the restart windows, `cue-prod`'s frontend proxy receives `ECONNREFUSED` on all requests to `http://arrivals-consumer-layer-prod.aensys-prod.svc.cluster.local:8080`, because no healthy ACL pods are available to back the k8s service. Since every data endpoint (orders, trolleys, service-counter-items, store-properties) routes through ACL, nothing loads.

Evidence consistent with memory leak cycle:
- 20+ ACL pods across two replicasets active simultaneously — abnormally high pod count, consistent with k8s scaling up replacements
- Errors sustained over hours (not a brief blip), consistent with a repeating crash cycle
- 100% ECONNREFUSED, not timeouts or 5xx — pods are refusing connections, not processing slowly
- Jason couldn't reproduce — checked during a temporarily healthy window between cycles

## What We Checked

- Symptom clarified — UI is interactable but orders/trolleys not populating. Not a blank screen or frontend failure. Points to API calls failing, not rendering.
- SSL cert errors noted by Jason (`picking-order-gateway.piksvc`) — confirmed red herring, in `piksvc` namespace (Picking infra), not our call path
- `aensys-prod` namespace health check run via Dynatrace for April 3–4 window
- `fullfill-prod` (~135k errors) identified and ruled out — belongs to Excitebike/FullFill team, shares namespace
- `cue-prod` error logs confirmed: every error is `[HPM] ECONNREFUSED` to ACL's cluster-local address, across all endpoints
- ACL's own error count very low (~250 across 20+ pods) — ACL is not logging errors before going down, consistent with OOMKill (process killed externally, no graceful shutdown log)
- Timeseries for April 4 10:50–12:55 PT: 100% error rate, never clears, peaks at ~1,300 errors/5min at 11:30 AM PT

## Resolution

Not resolved within the analyzed window. Incident still open as of 2026-04-06. Self-healing behavior would eventually stabilize between cycles, but the underlying memory leak means this will recur. Permanent fix requires identifying and patching the memory leak in ACL.

## Architecture Updates

- [x] Updated `architecture/cue-services.md` — documented that `aensys-prod` namespace is shared with Excitebike/FullFill team (`fullfill-prod`, `fullfill-consumer-layer-prod`)
- [ ] Confirm whether ACL calls `picking-order-gateway.piksvc` — SSL cert issue there is unrelated to this incident but worth tracking

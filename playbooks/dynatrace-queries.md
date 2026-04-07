# Dynatrace Query Playbook

**Purpose:** Reusable DQL query patterns for incident investigation

---

## Setup

```bash
source .env
```

All queries below use `$DYNATRACE_ENVIRONMENT` and `$DYNATRACE_TOKEN` from `.env`.

---

## Our Services (Namespace: `aensys-prod`)

| Service | Dynatrace entity name | Notes |
|---|---|---|
| Cue (arrivals) | `arrivals-prod` | Main app — historically low error rate |
| ACL | `arrivals-consumer-layer-prod` | Higher 4xx volume, most external calls |

**All queries below filter on `k8s.namespace.name == "aensys-prod"` first.** This is essential — the shared Dynatrace environment indexes hundreds of millions of log lines across dozens of namespaces. Without this anchor, queries are slow and results are noise.

---

## Step 1: App Health Check (Run This First)

These queries establish whether anything in our namespace is abnormal. Run them at the start of every investigation before pulling incident-specific data.

### 1a. Error and Warning Rate by Service (Last 2 Hours)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-2h | filter k8s.namespace.name == \"aensys-prod\" | summarize total = count(), errors = countIf(loglevel == \"ERROR\"), warnings = countIf(loglevel == \"WARN\") by k8s.workload.name, bin(timestamp, 5m) | sort timestamp asc",
    "requestTimeoutMilliseconds": 30000
  }' | jq '.'
```

**What to look for:**
- A spike in `errors` or `warnings` that aligns with the incident window
- Which workload (`arrivals-prod` vs `arrivals-consumer-layer-prod`) is the source
- Whether the spike is isolated or affects both services simultaneously

---

### 1b. Request Volume and Response Time by Service (Last 2 Hours)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-2h | filter k8s.namespace.name == \"aensys-prod\" | filter isNotNull(duration) | summarize request_count = count(), avg_ms = avg(duration), p95_ms = percentile(duration, 95), max_ms = max(duration) by k8s.workload.name, bin(timestamp, 5m) | sort timestamp asc",
    "requestTimeoutMilliseconds": 30000
  }' | jq '.'
```

**What to look for:**
- Response time climbing before/during incident window
- Request count dropping (could indicate upstream caller gave up)
- Which service is slow — if ACL is slow but `arrivals-prod` is fine, look outward at ACL's dependencies

---

### 1c. Pod-Level Error Summary (Are Specific Pods Affected?)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-2h | filter k8s.namespace.name == \"aensys-prod\" | filter loglevel == \"ERROR\" | summarize error_count = count() by k8s.pod.name, k8s.workload.name | sort error_count desc",
    "requestTimeoutMilliseconds": 30000
  }' | jq '.'
```

**What to look for:**
- Errors concentrated on one or two pods (node issue, crash loop) vs spread evenly (service-wide problem)
- A pod with zero errors during the window (may have been restarted and recovered)

---

### 1d. Sanity Check: No Anomalies in Our Namespace

If all three queries above show normal volumes, flat response times, and no error spikes — **our code is not the cause**. Document this and move investigation outward toward dependencies.

---

## Step 2: Incident-Specific Investigation

Run these after the health check confirms something is actually wrong in our namespace, or to gather evidence for a specific time window.

### Get Error Logs for Specific Time Window

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs | filter k8s.namespace.name == \"aensys-prod\" | filter timestamp >= timestamp(\"YYYY-MM-DDTHH:MM:SSZ\") and timestamp <= timestamp(\"YYYY-MM-DDTHH:MM:SSZ\") | filter loglevel == \"ERROR\" | fields timestamp, k8s.workload.name, k8s.pod.name, content | sort timestamp asc | limit 500",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.' > error-logs.json
```

---

### Minute-by-Minute Performance Breakdown

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-2h | filter k8s.namespace.name == \"aensys-prod\" | filter isNotNull(duration) | summarize total_requests = count(), slow_requests = countIf(duration > 5000), very_slow = countIf(duration > 10000), avg_ms = avg(duration), max_ms = max(duration) by k8s.workload.name, bin(timestamp, 1m) | sort timestamp asc",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.' > minute-breakdown.json
```

---

### Compare Performance Before vs During Incident

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-3h | filter k8s.namespace.name == \"aensys-prod\" | filter isNotNull(duration) | summarize before_avg = avgIf(duration, timestamp < timestamp(\"INCIDENT_START_TIME\")), before_p95 = percentileIf(duration, 95, timestamp < timestamp(\"INCIDENT_START_TIME\")), during_avg = avgIf(duration, timestamp >= timestamp(\"INCIDENT_START_TIME\")), during_p95 = percentileIf(duration, 95, timestamp >= timestamp(\"INCIDENT_START_TIME\")) by k8s.workload.name",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.'
```

---

### Find Peak Time (Worst 10 Minutes)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-6h | filter k8s.namespace.name == \"aensys-prod\" | filter isNotNull(duration) and duration > 5000 | summarize slow_count = count(), avg_ms = avg(duration), max_ms = max(duration) by k8s.workload.name, bin(timestamp, 1m) | sort slow_count desc | limit 10",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.' > peak-minutes.json
```

---

## Step 3: Dependency and Correlation Queries

Run these when the health check shows our services are slow or erroring, and you need to identify whether it's our code or an upstream/downstream dependency.

### Find Requests by Correlation ID

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-24h | filter k8s.namespace.name == \"aensys-prod\" | filter contains(content, \"CORRELATION_ID_HERE\") | fields timestamp, k8s.workload.name, k8s.pod.name, content | sort timestamp asc | limit 100",
    "requestTimeoutMilliseconds": 30000
  }' | jq '.'
```

---

### Find Which External Services Are Being Called (JWT Audience)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-24h | filter k8s.namespace.name == \"aensys-prod\" | filter contains(content, \"YOUR_ENDPOINT\") | fields timestamp, content | limit 500",
    "requestTimeoutMilliseconds": 60000
  }' | jq -r '.result.records[] | .content | fromjson | select(.jwt_audience) | .jwt_audience' | sort | uniq -c | sort -rn
```

**What this shows:**
- JWT audiences (the external services we're calling)
- Helps verify whether a suspected dependency is actually in our call path

---

## Step 4: Baseline and Historical Queries

Run these when you need to establish whether current behavior is anomalous relative to normal.

### Performance Baseline (Last 7 Days)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-7d | filter k8s.namespace.name == \"aensys-prod\" | filter isNotNull(duration) | summarize p50 = percentile(duration, 50), p95 = percentile(duration, 95), p99 = percentile(duration, 99), avg = avg(duration) by k8s.workload.name",
    "requestTimeoutMilliseconds": 90000
  }' | jq '.'
```

**Note:** Run this during a known-good period first to establish your baseline numbers. Then compare to incident-window results.

---

### Find Hourly Incident Windows (Last 48 Hours)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-48h | filter k8s.namespace.name == \"aensys-prod\" | filter isNotNull(duration) and duration > 10000 | summarize incident_count = count(), avg_ms = avg(duration), max_ms = max(duration) by k8s.workload.name, bin(timestamp, 1h) | filter incident_count > 5 | sort timestamp asc",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.'
```

---

## Tips & Best Practices

### Always Filter Namespace First

```dql
fetch logs, from:-2h
| filter k8s.namespace.name == "aensys-prod"
| ...rest of query
```

The shared Dynatrace environment has 370M+ log lines across dozens of namespaces. Namespace filtering reduces scan volume dramatically and prevents false matches.

---

### Time Window Parameters

**Relative time (recommended):**
- Last 15 minutes: `from:-15m`
- Last 2 hours: `from:-2h`
- Last 24 hours: `from:-24h`
- Last 7 days: `from:-7d`
- **Default is only 2 hours — always specify explicitly**

**Absolute time:**
- `timestamp >= timestamp("2026-04-04T15:00:00Z")`
- `timestamp <= timestamp("2026-04-04T17:00:00Z")`

---

### Useful k8s Filter Fields

| Field | Example value | Use |
|---|---|---|
| `k8s.namespace.name` | `aensys-prod` | Always include |
| `k8s.workload.name` | `arrivals-prod`, `arrivals-consumer-layer-prod` | Filter to specific service |
| `k8s.pod.name` | `arrivals-prod-abc123` | Isolate to specific pod |
| `loglevel` | `ERROR`, `WARN`, `INFO` | Filter by severity |

---

### Avoid Scan Limit Errors

- Default scan limit: 500GB
- For large time windows, use `bin()` aggregation before `sort`/`limit`
- Add namespace filter **before** content filters
- Use smaller time ranges for exploratory queries

---

### Performance Thresholds (Adjust for Your Service)

- **Normal:** < 1,000ms
- **Slow:** > 5,000ms
- **Very slow:** > 10,000ms
- **Catastrophic:** > 60,000ms

---

### Useful DQL Functions

- `count()` — count records
- `countIf(condition)` — conditional count
- `avg(duration)` — average
- `percentile(duration, 95)` — p95
- `bin(timestamp, 1m)` — time bucketing
- `contains(content, "text")` — string search in log body

---

## Saving Results

Always save query results to your investigation folder:

```bash
mkdir -p .active-investigations/$(date +%Y-%m-%d)-INCIDENT_NAME/logs/
mv *.json .active-investigations/$(date +%Y-%m-%d)-INCIDENT_NAME/logs/
```

---

**Last Updated:** 2026-04-07
**Maintainer:** Cue Team

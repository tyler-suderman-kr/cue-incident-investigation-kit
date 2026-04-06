# Dynatrace Query Playbook

**Purpose:** Reusable DQL query patterns for incident investigation

---

## Setup

```bash
source .env
```

All queries below use `$DYNATRACE_ENVIRONMENT` and `$DYNATRACE_TOKEN` from `.env`.

---

## Quick Status Checks

### Check for Active Incident (Last 15 Minutes)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-15m | filter contains(content, \"YOUR_SERVICE\") and isNotNull(duration) and duration > 10000 | summarize count = count(), avg_duration = avg(duration), max_duration = max(duration)",
    "requestTimeoutMilliseconds": 30000
  }'
```

**Interpretation:**
- count > 10 → Incident likely active
- avg_duration > 10000ms → Performance degraded
- max_duration > 60000ms → Severe incident

---

## Incident Investigation Queries

### Get Slow Queries for Specific Time Window

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs | filter timestamp >= timestamp(\"YYYY-MM-DDTHH:MM:SSZ\") and timestamp <= timestamp(\"YYYY-MM-DDTHH:MM:SSZ\") | filter contains(content, \"YOUR_SERVICE\") and isNotNull(duration) and duration > 5000 | fields timestamp, duration, content | sort timestamp asc | limit 500",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.' > slow-queries.json
```

**Usage:**
- Replace timestamps with incident window
- Adjust duration threshold (5000 = 5 seconds)
- Increase limit for larger incidents

---

### Minute-by-Minute Performance Breakdown

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-2h | filter contains(content, \"YOUR_SERVICE\") and isNotNull(duration) | summarize total_queries = count(), slow_queries = countIf(duration > 5000), very_slow_queries = countIf(duration > 10000), avg_duration = avg(duration), max_duration = max(duration) by bin(timestamp, 1m) | sort timestamp asc",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.' > minute-breakdown.json
```

**What this shows:**
- Queries per minute
- Slow query counts (>5s, >10s)
- Average and max duration per minute
- Incident peak and recovery pattern

---

### Find Peak Time (Worst Minutes)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-2h | filter contains(content, \"YOUR_SERVICE\") and isNotNull(duration) and duration > 5000 | summarize slow_count = count(), avg_duration = avg(duration), max_duration = max(duration) by bin(timestamp, 1m) | sort slow_count desc | limit 10",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.' > peak-minutes.json
```

---

### Compare Performance Before/After Incident

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-3h | filter contains(content, \"YOUR_SERVICE\") and isNotNull(duration) | summarize before_avg = avgIf(duration, timestamp < timestamp(\"INCIDENT_START_TIME\")), before_max = maxIf(duration, timestamp < timestamp(\"INCIDENT_START_TIME\")), during_avg = avgIf(duration, timestamp >= timestamp(\"INCIDENT_START_TIME\")), during_max = maxIf(duration, timestamp >= timestamp(\"INCIDENT_START_TIME\"))",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.'
```

---

## Correlation ID Tracking

### Find Requests by Correlation ID

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-24h | filter contains(content, \"CORRELATION_ID_HERE\") | fields timestamp, content | sort timestamp asc | limit 100",
    "requestTimeoutMilliseconds": 30000
  }' | jq '.'
```

---

## Service Dependency Analysis

### Find Which Services Are Calling an Endpoint

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-24h | filter contains(content, \"YOUR_ENDPOINT\") | fields timestamp, content | limit 500",
    "requestTimeoutMilliseconds": 60000
  }' | jq -r '.result.records[] | .content | fromjson | select(.jwt_audience) | .jwt_audience' | sort | uniq -c | sort -rn
```

**What this shows:**
- JWT audiences (calling services)
- Request counts per service
- Helps identify who depends on this endpoint

---

## Historical Analysis

### Establish Performance Baseline (Last 7 Days)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-7d | filter contains(content, \"YOUR_SERVICE\") and isNotNull(duration) | summarize p50 = percentile(duration, 50), p95 = percentile(duration, 95), p99 = percentile(duration, 99), avg = avg(duration)",
    "requestTimeoutMilliseconds": 90000
  }' | jq '.'
```

**Expected baseline (adjust for your service):**
- p50: ~200-400ms
- p95: ~1,000-2,000ms
- p99: ~2,000-5,000ms

---

### Find All Incidents in Time Range

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-48h | filter contains(content, \"YOUR_SERVICE\") and isNotNull(duration) and duration > 10000 | summarize incident_count = count(), avg_duration = avg(duration), max_duration = max(duration) by bin(timestamp, 1h) | filter incident_count > 5 | sort timestamp asc",
    "requestTimeoutMilliseconds": 60000
  }' | jq '.'
```

**What this shows:**
- Hourly buckets with >5 slow queries
- Helps identify incident windows
- Shows recovery times

---

## Error Analysis

### Find HTTP Errors (4xx/5xx)

```bash
curl -X POST "${DYNATRACE_ENVIRONMENT}/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer ${DYNATRACE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-2h | filter contains(content, \"YOUR_SERVICE\") | summarize total = count(), client_errors = countIf(contains(content, \"4\")), server_errors = countIf(contains(content, \"5\")) by bin(timestamp, 5m)",
    "requestTimeoutMilliseconds": 30000
  }' | jq '.'
```

---

## Tips & Best Practices

### Time Window Parameters

**Relative time (recommended):**
- Last 15 minutes: `from:-15m`
- Last 2 hours: `from:-2h`
- Last 24 hours: `from:-24h`
- Last 7 days: `from:-7d`

**Absolute time:**
- `timestamp >= timestamp("2026-04-04T15:00:00Z")`
- `timestamp <= timestamp("2026-04-04T17:00:00Z")`

### Avoid Scan Limit Errors

- Default scan limit: 500GB
- For large time windows, use `bin()` aggregation
- Add specific filters early in the query
- Use smaller time ranges for exploratory queries

### Performance Thresholds

Adjust these for your service:
- **Normal:** < 1,000ms
- **Slow:** > 5,000ms (5s)
- **Very slow:** > 10,000ms (10s)
- **Catastrophic:** > 60,000ms (1 min)

### Useful DQL Functions

- `count()` - Count records
- `avg(duration)` - Average duration
- `max(duration)` - Maximum duration
- `percentile(duration, 95)` - 95th percentile
- `countIf(duration > 5000)` - Conditional count
- `contains(content, "text")` - String search
- `bin(timestamp, 1m)` - Time bucketing

---

## Saving Results

Always save query results to your investigation folder:

```bash
mkdir -p .active-investigations/$(date +%Y-%m-%d)-INCIDENT_NAME/logs/
mv *.json .active-investigations/$(date +%Y-%m-%d)-INCIDENT_NAME/logs/
```

---

**Last Updated:** 2026-04-06
**Maintainer:** Cue Team

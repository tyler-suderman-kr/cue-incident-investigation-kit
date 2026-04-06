# Incident Investigation Report

**Incident ID:** INC-XXXXXX
**Date:** YYYY-MM-DD
**Severity:** P1 / P2 / P3 / P4
**Status:** In Progress / Resolved / Monitoring

---

## Executive Summary

[2-3 sentence summary of the incident and findings]

---

## Incident Details

### Timeline

| Time (UTC) | Time (Pacific) | Event |
|------------|----------------|-------|
| HH:MM | HH:MM | Incident reported |
| HH:MM | HH:MM | Investigation started |
| HH:MM | HH:MM | Root cause identified |
| HH:MM | HH:MM | Incident resolved |

### Affected Services

**Our Services:**
- Service A: [Impact description]
- Service B: [Impact description]

**External Dependencies:**
- Service X: [Status/impact]
- Service Y: [Status/impact]

### User Impact

- **Affected Users:** [Number or scope]
- **Affected Stores/Divisions:** [List]
- **Symptoms Reported:** [User-facing issues]

---

## Investigation Process

### 1. Architecture Verification

**Result:** [We DO / DON'T call the reported service]

**Evidence:**
- Code search results: [Link to architecture-check.md]
- Log correlation: [Summary]

### 2. Log Analysis

**Query window:** YYYY-MM-DD HH:MM to YYYY-MM-DD HH:MM

**Findings:**
- Total requests: XXX
- Slow requests (>5s): XXX
- Failed requests: XXX
- Average latency: XXms

**Sample queries:**
```
[Link to .active-investigations/*/logs/]
```

### 3. Timeline Correlation

**Incident report says:** [User symptoms, timing]
**Logs show:** [Actual data, timing]
**Match:** ✅ Confirms / ❌ Contradicts / ⚠️ Partially matches

---

## Root Cause Analysis

### Confirmed Root Cause

[Description of the actual cause]

**Evidence:**
1. [Log evidence]
2. [Code evidence]
3. [Metric evidence]

### Alternative Hypotheses Ruled Out

- Hypothesis A: Ruled out because [reason]
- Hypothesis B: Ruled out because [reason]

---

## Impact Analysis

### Performance Metrics

**Normal State:**
- Average latency: XXms
- Error rate: X%
- Throughput: XXX req/min

**During Incident:**
- Average latency: XXms (Δ +XXX%)
- Error rate: X% (Δ +XX%)
- Throughput: XXX req/min (Δ -XX%)

### Blast Radius

- [ ] Single store
- [ ] Multiple stores in division
- [ ] Multiple divisions
- [ ] Company-wide

---

## Resolution

### Immediate Actions Taken

1. [Action]
2. [Action]
3. [Action]

### How Issue Resolved

- [ ] Self-healed
- [ ] Manual intervention (describe)
- [ ] Code deployment
- [ ] Configuration change
- [ ] Still unresolved

---

## Recommendations

### Immediate (< 24 hours)

1. [Action item - owner]
2. [Action item - owner]

### Short-term (< 1 week)

1. [Action item - owner]
2. [Action item - owner]

### Long-term (> 1 week)

1. [Action item - owner]
2. [Action item - owner]

### Architecture Updates Needed

- [ ] Update `architecture/cue-services.md`
- [ ] Update `architecture/external-deps.md`
- [ ] Document new dependency
- [ ] Remove incorrect assumption

---

## Lessons Learned

### What Went Well

- [Thing 1]
- [Thing 2]

### What Could Be Improved

- [Thing 1]
- [Thing 2]

### Preventive Measures

- [How to prevent this in future]

---

## Attachments

- Architecture verification: [Link]
- Log queries: [Link to .active-investigations/*/logs/]
- Related incidents: [INC-XXXX, INC-YYYY]
- Runbook updates: [Link if created]

---

**Investigated by:** [Team/Name]
**Reviewed by:** [Team/Name]
**Completed:** YYYY-MM-DD

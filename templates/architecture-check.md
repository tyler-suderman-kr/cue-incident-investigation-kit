# Architecture Verification Template

**Investigation:** [Incident ID or Description]
**Date:** YYYY-MM-DD
**Investigator:** [Name/Team]

---

## Service in Question

**Service Name:**
**Reported Issue:**
**Assumption:** Our services depend on this service

---

## Verification Checklist

### 1. Code Search

- [ ] Searched cue repo for service references
- [ ] Searched acl (arrivals-consumer-layer) repo for service references
- [ ] Searched cqs (cue-query-service) repo for service references
- [ ] Checked HTTP client configurations
- [ ] Checked environment variables/configs

**Search command:**
```bash
# Load repo paths from .env
source .env

# Search all repos
grep -r "SERVICE_NAME" "$CUE_REPO_PATH" "$ACL_REPO_PATH" "$CQS_REPO_PATH"
```

**Results:**
```
[Paste grep output or "No matches found"]
```

---

### 2. Dependency Analysis

**Services WE call directly:**
- [ ] Service A
- [ ] Service B
- [ ] Service C

**Services called by OUR dependencies:**
- [ ] Dependency X calls Service Y
- [ ] Dependency Z calls Service W

**Services we DON'T call:**
- [ ] Service in question (if verified)

---

### 3. Log Correlation

**Our logs show:**
- [ ] Requests to this service (correlation IDs: ___)
- [ ] No requests to this service
- [ ] Requests from this service to us

**External logs show:**
- [ ] Partner integrations calling it (Uber, DoorDash, etc.)
- [ ] Our service identifiers in requests
- [ ] No trace of our services

---

## Conclusion

### Does our stack call this service?

- [ ] **YES** - Direct dependency (we call it)
- [ ] **INDIRECT** - One of our dependencies calls it (which one: ___)
- [ ] **NO** - We don't use this service
- [ ] **UNKNOWN** - Need more investigation

### Evidence

[Summarize findings with links to code/logs]

---

### Next Steps

**If YES:**
- Investigate our calls to this service
- Check response times, error rates
- Review our error handling

**If INDIRECT:**
- Identify which dependency calls it
- Check if our calls to that dependency are slow
- May need to contact that team

**If NO:**
- Document this clearly
- Challenge incident report assumptions
- Look for alternative root causes
- Update incident ticket with findings

---

**Verified by:** [Name]
**Date:** [Date]
**Confidence:** High / Medium / Low

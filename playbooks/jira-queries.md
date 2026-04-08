# Jira/Atlassian Search - Quick Reference

**Use case:** Ad-hoc searches when you spot something suspicious in timeline analysis, or to identify who owns an unfamiliar namespace during incident triage.

**Namespace lookup:** If you encounter a namespace in Dynatrace logs that isn't in `architecture/namespace-inventory.md`, search Jira for the namespace name. Infra migration tickets (ICSART project) often name namespaces explicitly and identify the owning team/LOB. Update the inventory with whatever you find.

---

## Setup (Optional - only if you need Jira)

```bash
# Edit .env and uncomment these lines:
# ATLASSIAN_EMAIL=your.email@kroger.com
# ATLASSIAN_TOKEN=your-token-here
# ATLASSIAN_DOMAIN=kroger.atlassian.net

# Generate token: https://id.atlassian.com/manage-profile/security/api-tokens
```

---

## Basic Searches

### Search for anything (keyword, ticket number, error message)

```bash
source .env

# Simple text search across all Jira
SEARCH="your keyword here"

curl -s -X POST "https://${ATLASSIAN_DOMAIN}/rest/api/3/search/jql" \
  -u "${ATLASSIAN_EMAIL}:${ATLASSIAN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"jql\": \"text ~ \\\"${SEARCH}\\\" ORDER BY updated DESC\", \"maxResults\": 10, \"fields\": [\"summary\", \"status\", \"assignee\"]}" \
  | jq -r '.issues[] | "\(.key): \(.fields.summary)"'
```

### Search by date range (e.g., "what changed around the incident time?")

```bash
# Find tickets updated during incident window
START_DATE="2026-04-06"
END_DATE="2026-04-07"

curl -s -X POST "https://${ATLASSIAN_DOMAIN}/rest/api/3/search/jql" \
  -u "${ATLASSIAN_EMAIL}:${ATLASSIAN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"jql\": \"updated >= \\\"${START_DATE}\\\" AND updated <= \\\"${END_DATE}\\\" ORDER BY updated DESC\", \"maxResults\": 20, \"fields\": [\"summary\", \"status\", \"updated\"]}" \
  | jq -r '.issues[] | "\(.key): \(.fields.summary) (updated: \(.fields.updated))"'
```

### Get ticket details

```bash
TICKET="CUE-1234"

curl -s -X GET "https://${ATLASSIAN_DOMAIN}/rest/api/3/issue/${TICKET}" \
  -u "${ATLASSIAN_EMAIL}:${ATLASSIAN_TOKEN}" | jq '{
  summary: .fields.summary,
  status: .fields.status.name,
  description: .fields.description,
  updated: .fields.updated
}'
```

---

## Common Scenarios

**"Did someone deploy around this time?"**
→ Search by date range, look for deployment-related keywords

**"Was there a ticket about this error?"**
→ Search for error message text

**"Has this happened before?"**
→ Search for service name + symptom keywords

---

**That's it. Keep it simple. Jira is just for quick lookups, not structured workflows.**

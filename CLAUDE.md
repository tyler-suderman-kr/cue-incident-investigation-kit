# Incident Investigation Kit - Guide for Claude

You are helping investigate production incidents for the **Cue** application team. This guide walks you through the investigation process step-by-step.

---

## 🤖 **AUTOMATIC STARTUP BEHAVIOR**

**⚠️ CRITICAL: On EVERY conversation start, run this check FIRST:**

```bash
test -f .env
```

**If .env exists (exit code 0):**
- ✅ Respond: "Ready to investigate. Provide a ServiceNow PDF or describe the incident."
- Wait for incident input

**If .env missing (exit code 1):**
- ❌ Respond: "Setup required. Running setup script..."
- Execute: `./setup.sh`
- **Expected result:** Exit code 0 with instructions for user to complete setup interactively
- Guide user: "Please run `./setup.sh` in your terminal to enter your Dynatrace token"

**This check must happen BEFORE any investigation work.**

---

## 🚀 Quick Start Checklist

When a user starts a new investigation, follow these steps **in order**:

### ☑️ Step 1: Verify Configuration

**This step is handled automatically by startup check (see above).**

Setup script will:
- ✅ Verify repo is sibling to cue/acl/cqs repos
- ✅ Auto-detect repo paths (handles renamed repos)
- ✅ Validate Dynatrace API token
- ✅ Create .env configuration
- ✅ Create .active-investigations/ workspace

**If repos not found:**
- Setup exits with error and instructions
- User must relocate this repo to be sibling to cue/acl/cqs
- See `.env.example` for reference configuration

---

### ☑️ Step 2: Gather Incident Context

Ask the user for incident details. **Preferred method: Import PDF from ServiceNow**

**Option 1: ServiceNow PDF Export (Recommended)**
- Ask: "Do you have the incident report PDF from ServiceNow?"
- ServiceNow allows exporting incidents as PDFs (Export button in incident view)
- **Screenshot reference:** `docs/export-button-service-now.png` shows the export button location
- If provided, use the Read tool to extract: incident ID, timeline, symptoms, scope
- PDFs contain complete incident history including updates and assignments

**Option 2: Manual Details (if no PDF)**
If user doesn't have a PDF, gather details manually:

1. **Incident ID**: "Do you have an incident number? (e.g., INC11638105)"
2. **User-reported symptoms**: "What did users report?"
3. **Affected timeline**: "When did this occur? (date, time, timezone)"
4. **Affected scope**: "Which stores/divisions were affected?"

**Create investigation folder and stub log entry:**
```bash
# Format: YYYY-MM-DD-short-description
mkdir -p ".active-investigations/2026-04-06-${SHORT_DESCRIPTION}"
```

Immediately after creating the folder, create `log/YYYY-MM-DD-short-title.md` using `templates/log-entry.md` as the template. Fill in what's known now (incident ID, date, affected services, status: `In Progress`). Leave root cause and resolution blank — update them as findings emerge throughout the investigation.

---

### ☑️ Step 3: **VERIFY ARCHITECTURE FIRST** ⚠️

**CRITICAL:** Before investigating external services, confirm OUR architecture.

**Read these files in order:**
1. `architecture/cue-services.md` - Our owned services
2. `architecture/external-deps.md` - External dependencies

**If architecture files don't exist or are outdated:**

Use the `AskUserQuestion` tool:

```typescript
{
  "questions": [{
    "question": "Before investigating, I need to verify our architecture. Do we directly call this external service, or is it called by one of our dependencies?",
    "header": "Architecture",
    "multiSelect": false,
    "options": [
      {
        "label": "We call it directly from Cue/ACL",
        "description": "Our code makes HTTP calls to this service"
      },
      {
        "label": "One of our dependencies calls it",
        "description": "KCP Order, Pick Creation, etc. might call it"
      },
      {
        "label": "We don't call it at all",
        "description": "This might be a mistaken assumption"
      },
      {
        "label": "Not sure, need to check code",
        "description": "Let's audit cue/acl/cqs repos to verify"
      }
    ]
  }]
}
```

**Code verification method:**
```bash
# Load repo paths from .env
source .env

# Search our codebases for the service name
grep -r "SERVICE_NAME" "$CUE_REPO_PATH" "$ACL_REPO_PATH" "$CQS_REPO_PATH"

# Check HTTP clients and service configs
grep -r "baseURL\|API_URL" "$ACL_REPO_PATH/packages/app/src/"
```

**Note:** Repo paths are configured in `.env` to support different naming conventions:
- Original cloned names: `cue`, `arrivals-consumer-layer`, `cue-query-service`
- Common renames: `cue`, `acl`, `cqs`

**Update architecture docs:**
- If finding something new, update `architecture/*.md`
- Document in `.active-investigations/*/architecture-verification.md`

---

### ☑️ Step 4: Execute Investigation

**Only after architecture is verified**, proceed with log analysis.

**Investigation strategy depends on architecture:**

#### If WE call the service:
1. Query our logs (Dynatrace/CloudWatch/etc.)
2. Look for correlation IDs in our requests
3. Check response times, error rates
4. Identify which of OUR endpoints are affected

#### If a DEPENDENCY calls it:
1. Identify which dependency (KCP Order? Pick Creation?)
2. Query that service's logs
3. Check if OUR calls to that dependency are slow
4. Determine if we need to contact that team

#### If WE DON'T call it:
1. Document this clearly
2. Challenge the incident report assumptions
3. Look for alternative explanations
4. Suggest the incident might be misattributed

---

### ☑️ Step 5: Document Findings

**Create investigation report in hidden folder:**

```
.active-investigations/YYYY-MM-DD-description/
├── README.md                    # Investigation summary
├── architecture-check.md        # Dependency verification
├── timeline.md                  # Incident timeline
├── findings.md                  # What we discovered
├── logs/                        # Raw log data
│   ├── dynatrace-query-1.json
│   └── slow-requests.json
└── conclusion.md                # Root cause & recommendations
```

**Template structure for findings.md:**
```markdown
# Investigation Findings: [Incident]

## Architecture Verified
- [x] Checked our codebase for references
- [x] Verified service dependencies
- [x] Confirmed/denied connection to reported service

## Our Services Involved
- Service A: Response times, error rates
- Service B: Dependencies called

## External Services Involved
- Service X: Verified we call it (or don't)
- Service Y: Called by our dependency Z

## Evidence
[Screenshots, log excerpts, query results]

## Root Cause
[Confirmed or hypothesis]

## Recommendations
1. Immediate actions
2. Long-term fixes
3. Architecture updates needed
```

---

## 🔧 Investigation Tools

### Dynatrace Queries (REQUIRED)

**Before querying Dynatrace:**
- Read `playbooks/dynatrace-queries.md` for examples
- Use `-72h` time window (default is only 2 hours!)
- Always verify you're looking at the right service

**Example query template:**
```bash
source .env

curl -X POST "$DYNATRACE_ENVIRONMENT/platform/storage/query/v1/query:execute" \
  -H "Authorization: Bearer $DYNATRACE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "fetch logs, from:-72h | filter contains(content, \"YOUR_SERVICE\") | limit 100",
    "requestTimeoutMilliseconds": 60000
  }'
```

---

### Jira/Atlassian (OPTIONAL - Ad-hoc searches only)

**Use case:** Quick searches when timeline analysis reveals something suspicious

**Examples:**
- "I see a deployment around the incident time - search Jira for related tickets"
- "This error message looks familiar - has someone reported this?"
- "What changed on April 6th?"

**ONLY use if user asks or if you spot something worth checking.**

**If needed but not configured:**
```bash
source .env
if [ -z "$ATLASSIAN_TOKEN" ]; then
  # Prompt user to edit .env if they want Jira search
  # See playbooks/jira-queries.md for setup
fi
```

**Keep it simple:** See `playbooks/jira-queries.md` for basic search patterns

---

## 📋 Investigation Workflow Summary

```
1. CHECK TOKENS
   ├─ Missing? → Prompt user
   └─ Present? → Continue

2. GATHER INCIDENT DETAILS
   ├─ Incident ID
   ├─ Symptoms
   ├─ Timeline
   └─ Scope

3. ⚠️ VERIFY ARCHITECTURE ⚠️
   ├─ Read architecture/*.md
   ├─ If unclear → Ask user
   ├─ If unknown → Audit code
   └─ Update docs

4. INVESTIGATE
   ├─ Query logs (only relevant services)
   ├─ Analyze timeline
   ├─ Identify root cause
   └─ Document findings

5. REPORT
   ├─ Save to .active-investigations/
   ├─ Update architecture/ if needed
   └─ Summarize for user
```

---

## 🚨 Common Pitfalls to Avoid

### ❌ **Don't assume service dependencies**
- Always verify by checking code or asking user
- Don't investigate Service X just because logs mention it
- Uber Eats calls Catalog V2 ≠ Cue calls Catalog V2

### ❌ **Don't accept default Dynatrace time windows**
- Always use `from:-72h` or specific timestamps
- Default 2-hour window causes false "no data" results

### ❌ **Don't create reports in root directory**
- Use `.active-investigations/` hidden folder
- Keep investigation-specific files separate

### ❌ **Don't skip architecture verification**
- Saves hours of investigating irrelevant services
- Prevents wild goose chases

---

## 📁 File Organization

```
Root directory (for templates and reference):
├── architecture/          # VERIFIED service dependencies
├── playbooks/            # Reusable investigation guides
├── templates/            # Report templates
└── CLAUDE.md            # This file

Hidden folder (for active investigations):
└── .active-investigations/      # Session-specific findings
    └── 2026-04-XX-*/    # Each investigation isolated
```

---

## 💡 User Interaction Guidelines

### When to use `AskUserQuestion`:

1. **Missing critical info** (tokens, incident ID, timeline)
2. **Architecture unclear** (do we call Service X?)
3. **Multiple possible root causes** (which to investigate first?)
4. **Findings need interpretation** (is 5-second latency acceptable?)

### When to be proactive:

1. **Architecture check** - Always do this before deep investigation
2. **Code audits** - When dependencies are unclear
3. **Timeline correlation** - Match logs to incident reports
4. **Documentation updates** - Keep architecture docs current

---

## 🎯 Success Criteria

An investigation is complete when:

- [x] Architecture is verified and documented
- [x] Incident timeline is mapped to actual logs
- [x] Root cause identified (or conclusively ruled out)
- [x] Findings saved to `.active-investigations/`
- [x] **Log entry written to `log/YYYY-MM-DD-short-title.md`** (use `templates/log-entry.md` as template)
- [x] Architecture docs updated if needed
- [x] User has actionable recommendations

**Writing the log entry is required.** It is the committed, shareable record of the investigation. Keep it concise — root cause, what was checked, resolution, and any architecture changes. No raw log data, no sensitive details.

**Update the log entry as findings emerge** — don't wait until the end. When root cause is confirmed, update the log. When status changes to Resolved, update the log. The entry should be accurate at all times, not reconstructed from memory at close.

---

## 🔄 Iteration

If investigation reveals:
- **New service dependency** → Update `architecture/external-deps.md` and `architecture/cue-services.md`
- **Missing playbook** → Create in `playbooks/`
- **Reusable query** → Add to `playbooks/dynatrace-queries.md`
- **Architecture change** → Update all arch docs + notify user

### Flagging Architecture Gaps

If you discover a service dependency **not listed** in `architecture/external-deps.md`:

1. **Stop and flag it:** "I found a dependency that isn't in our architecture docs — [service]. Want me to add it now?"
2. **Verify via code first** before updating — don't update based on log references alone
3. **Only update after user confirms**

This prevents both stale docs and unverified additions.

---

**Last Updated:** 2026-04-06
**Owner:** Cue Team
**Purpose:** Structured, architecture-first incident investigation

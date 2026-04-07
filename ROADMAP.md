# Investigation Kit — Roadmap

Ideas for extending scope and reducing manual overhead in investigations.

---

## 1. Teams Integration — Live Incident Channel Monitoring

**Idea:** Hook into the major incident Teams channel in real-time so that context from other teams (error messages, status updates, workarounds) is available during an investigation without manually cross-referencing.

**Value:** During INC11638105, Jason's SSL cert finding was in a Teams work note — we only saw it because it was in the PDF. Real-time access would surface that kind of signal earlier and from channels we might not be watching.

**Open questions:**
- Which Teams channels carry incident traffic? (major incident bridge, team-specific channels?)
- Is there a webhook or Graph API integration available through AI enablement?
- Read-only monitoring vs. the ability to post findings back to the channel

---

## 2. ServiceNow Integration via AI Enablement

**Idea:** Use the AI enablement team's ServiceNow integration to pull live incident data directly, rather than relying on exported PDFs.

**Value:** PDFs are a snapshot — they miss updates that happen after export. Live SNOW data means the incident history, work notes, and assignment changes are always current. Would also allow proactive monitoring (e.g. alert when a P1/P2 is assigned to our CI).

**Open questions:**
- What does the AI enablement SNOW integration expose? (read incidents, query by CI, watch for new assignments?)
- Are there equivalent integrations for Atlassian and Dynatrace that are worth evaluating alongside it?
- Authentication model — service account or user-delegated?

---

## 3. GitHub + Atlassian Integration — Namespace Mapper and Repo Table

**Idea:** Build a lightweight namespace/repo mapping layer so that log signals can be automatically connected to source code and documentation. For example: seeing `piksvc` namespace in a Dynatrace error → look up which repo owns it → pull relevant Atlassian runbooks → surface the right team contact.

**Value:** The biggest time sink in investigations is figuring out who owns what. During INC11638105, the `fullfill-prod` service in our namespace took manual Teams searching to identify. A namespace → team → repo → runbook table would make that instant.

**Components this would need:**
- A namespace-to-team mapping table (e.g. `aensys-prod` → Cue + Excitebike, `piksvc` → Picking team)
- A repo table with ownership, primary Atlassian space, and on-call contact
- GitHub integration to pull recent commits/PRs for a repo around an incident timestamp (did something deploy right before this?)
- Atlassian lookup to fetch runbooks by namespace or service name

**Open questions:**
- Does Kroger have a service catalog or CMDB that already has some of this? (the SNOW impacted CIs list is close)
- GitHub integration scope — public repo listing only, or can we query commit history?
- How stable are namespace names? Renaming happens (we saw this with our own repos)

---

## Notes

- AI enablement integrations should be evaluated together — SNOW, Atlassian, and Dynatrace may all have options and it's worth understanding the full surface before building custom tooling
- The namespace mapper would be the highest-leverage single addition — it removes the "who owns this?" question that blocks almost every cross-team investigation

---

**Last Updated:** 2026-04-07

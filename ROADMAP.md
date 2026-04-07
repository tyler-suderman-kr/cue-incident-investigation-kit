# Investigation Kit — Roadmap

Ideas for extending scope and reducing manual overhead in investigations, roughly ordered by priority.

---

## 1. Namespace Mapper

**Idea:** A mapping layer that connects k8s namespace and workload names to owning teams, repos, and runbooks. For example: seeing `piksvc` in a Dynatrace error → Picking team → their Atlassian space → on-call contact.

**Value:** The single biggest time sink in cross-team investigations is "who owns this?" During INC11638105, identifying `fullfill-prod` as Excitebike's service (not ours) required manual Teams searching. A namespace → team → repo → runbook table makes that instant and prevents chasing the wrong service entirely.

**Open questions:**
- Does this already exist somewhere? Atlassian might have a service catalog, CMDB, or internal wiki page worth searching before building anything custom. The SNOW impacted CIs list (`FST-Cue`, `Arrivals Consumer Layer`, etc.) is a partial version of this.
- If it doesn't exist, would it live in this repo as a maintained YAML/markdown table, or in a shared internal system?
- How stable are namespace names? Renaming is common (we saw it with our own repos) — any map needs a maintenance story.

---

## 2. ServiceNow Integration via AI Enablement

**Idea:** Use the AI enablement team's ServiceNow integration to pull live incident data directly, rather than relying on exported PDFs.

**Value:** PDFs are a snapshot — they miss updates after export. Live SNOW data means incident history, work notes, and assignment changes are always current. Would also allow proactive monitoring (e.g. alert when a P1/P2 is assigned to our CI).

**Open questions:**
- What does the AI enablement SNOW integration expose? (read incidents, query by CI, watch for new assignments?)
- Are there equivalent integrations for Atlassian and Dynatrace worth evaluating at the same time?
- Authentication model — service account or user-delegated?

---

## 3. Teams Integration — Live Incident Channel Monitoring

**Idea:** Hook into the major incident Teams channel in real-time so that context from other teams is available during an investigation without manually cross-referencing.

**Value:** During INC11638105, Jason's SSL cert finding was in a Teams work note — we only saw it because it was in the PDF. Real-time access would surface that kind of signal earlier and from channels we might not be watching.

**Open questions:**
- Which Teams channels carry incident traffic? (major incident bridge, team-specific channels?)
- Is there a webhook or Graph API integration available through AI enablement?
- Read-only monitoring vs. the ability to post findings back to the channel?

---

## 4. GitHub + Atlassian — Deployment Context During Investigations

**Idea:** Given a repo and an incident timestamp, pull recent commits and open PRs to answer "did something deploy right before this?" Pair with Atlassian lookups to fetch relevant runbooks by service name.

**Value:** Complements the namespace mapper — once you know which repo owns a service, being able to see its recent deploy history without leaving the investigation context saves a context switch.

**Open questions:**
- GitHub integration scope — commit history and PR listing, or broader?
- This only makes sense after the namespace mapper exists to connect log signals to repos in the first place.

---

## Notes

- The namespace mapper is the highest-leverage starting point — it unblocks items 3 and 4 and reduces the most common manual step in any cross-team investigation.
- AI enablement integrations (SNOW, Atlassian, Dynatrace) should be evaluated together to understand the full surface before building custom tooling.

---

**Last Updated:** 2026-04-07

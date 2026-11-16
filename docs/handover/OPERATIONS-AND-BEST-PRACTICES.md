# Operations, Engineering Practices and Support Notes

**Audience:** Two junior integration/support engineers  
**Authority:** Proposed procedures; production execution requires named owners  
**Companion:** [Technical contracts and reference IDs](TECHNICAL-NOTES.md)

## 1. Safe environment and first setup

Keep local training, shared staging and production distinctly named. Local
training uses disposable synthetic databases, synthetic devices/accounts and
mock position/event/push receivers. Shared staging is not automatically
disposable and may contain sensitive data.

Before any startup/test/replay, confirm repository, target host/database,
provider destinations, notification audience, credentials and cleanup scope.
Do not dump the complete environment to prove isolation.

Do not run `start.sh`, `init-db.sh`, migration commands, seeders or integration
tests against production as onboarding exercises. The wrapper can create a
database and the backend can migrate a schema on startup.

Use the component's approved runtime and locked dependencies. Choose supported
versions that satisfy its manifest; do not upgrade frameworks as a setup fix
without understanding compatibility. Never copy production secrets into a
training `.env`.

### Local command reference

Only the startup command below is a no-database wrapper check. Run it from this
repository; it uses a POSIX shell, with Git Bash supported on Windows.

```powershell
node --test tests\startup.test.cjs
```

From the sibling backend repository, these selected suites use mocked ingestion
dependencies or a loopback fake Traccar service. Re-check their current setup
when code changes; their passing does not establish real decoder/database
correctness.

```powershell
npm test -- --runTestsByPath tests\trackerIngestion.test.js tests\traccarClient.test.js
```

`tests\tracker.test.js` is a real database integration suite, not a harmless
unit test. Existing integration setup recreates schema. Workflow/outbox suites
add explicit `carribu_workflow_*` database-name and `127.0.0.1` host guards,
but not every suite has those guards. Follow the backend README's isolated
database procedure and owner approval; never run broad tests using inherited
deployment environment values.

There is no `npm test` script in the inspected admin manifest. Consult its
existing React Scripts test invocation and client owner rather than inventing
a package script. Native builds/tests use that repository's Gradle wrapper and
approved local/test API configuration, not a production URL copied from examples.

## 2. Engineering habits for junior owners

| Practice | Required behavior |
|---|---|
| Small changes | One stated requirement, bounded diff, affected contracts identified |
| Read before editing | Trace the existing source/test boundary; preserve unrelated work |
| TDD for defects | Write the smallest regression that exposes the defect, make it pass, then refactor |
| Appropriate evidence | Unit logic, database semantics, protocol decode, forwarding and handset behavior need different checks |
| Domain authority | Use backend trip/source/recipient rules; do not create competing UI rules |
| Deterministic time | Test timestamps with a fixed clock where possible; distinguish fix time from receipt time |
| Controlled retries | Preserve stable event IDs and existing outbox semantics; no blind resend loops |
| Review | Peer review routine changes; experienced review for source, time, alerts, authorization, schema, protocols and releases |
| Documentation | Update the exact changed contract/runbook, not a second disconnected guide |
| Escalation | State what is known, unverified and blocked; do not hide failures behind retries |

Mock providers in unit/integration training; explicitly authorize any real
provider/client check. A fake receiver's success is not a Firebase/Expo delivery
result. Do not use an LLM judge for deterministic protocol/state assertions.

### Pull request checklist

- [ ] Requirement and non-goals are explicit; product semantics approved.
- [ ] Source, timestamp, units, active-trip and school/guardian rules preserved.
- [ ] Regression covers introduced behavior and its meaningful failure boundary.
- [ ] Required database/protocol/client evidence is identified, not replaced by mocks.
- [ ] No secrets, real payloads, identifiers or unnecessary location data included.
- [ ] Changed config/schema is versioned and compatibility/recovery reviewed.
- [ ] Documentation and observable errors match actual behavior.
- [ ] Appropriate reviewer approved; execution environment and evidence are recorded.

## 3. Reproducible configuration and access

Record image digest, Git commits, runtime, schema/migration state, non-secret
configuration hash, tracker protocol/firmware, supported clients and test
fixture version. Redact sensitive fields before hashing/sharing configuration;
a public manifest must not become a secret store.

Pin approved images and lock dependencies while scheduling controlled updates.
Use least-privilege accounts and private database connectivity where approved.
Do not expose a database publicly merely to make onboarding easier.

Store secrets only in approved secret/account systems. Backend webhook secrets,
Traccar account tokens, Firebase credentials, maps keys and signing keys are
different credentials with different owners. Do not log raw Axios error
configuration, authorization headers, cookies or provider token payloads.
Collect minimal diagnostic data; mask sensitive identifiers and sanitize
untrusted fields before including them in logs/support records [R13].

Coordinate secret rotation across sender/receiver settings. The current
machine middleware checks one configured token; overlapping old/new token
acceptance is not an existing feature. Use an approved coordinated procedure
with verification and a recovery plan rather than assuming seamless rotation.

## 4. Routine support workflow

| Stage | Action | Safe evidence |
|---|---|---|
| Intake | Confirm environment, symptom, affected role and approximate UTC time | Synthetic/redacted IDs and user-described symptom |
| Scope | Establish whether one device/trip/school or multiple are affected | Counts and service aliases, not student route dumps |
| Trace | Follow contact -> fix -> decode -> ingestion -> trip -> outbox -> client | Timestamps, ignored reasons, stable event IDs and sanitized status |
| Compare | Check last known-good behavior/version and recent approved changes | Commit/config identifiers and change record |
| Recover | Apply only the approved runbook action for the owning layer | Approver, action, time and verification |
| Close | State outcome, uncertainty, user communication and follow-up | Minimal incident record and regression/backlog link |

Do not infer vehicle/student safety from a map point or provider acceptance.
Use the school's existing emergency communication procedure for potential
safety incidents and notify the designated operations owner immediately.
Debugging should not delay that process.

### Diagnostic decision table

| Symptom | Check in order | Do not do |
|---|---|---|
| No tracker contact | Approved device/protocol; configured TCP destination; network/APN; Traccar intake | Change real tracker settings without device-owner approval |
| Online but no usable position | Actual decoded payload, `valid`, fix timestamp and usable network fields | Treat heartbeat/GPRS as GPS; deliberately obstruct an antenna |
| Traccar has a fix, Carribu does not | Forward receiver/auth; optional client health; mapping; active trip; `ignored` reason | Count every 2xx acknowledgment as a stored point |
| Old point appears | Original fix time, ordering, source and snapshot flags | Replace time with now or label a snapshot live |
| Raw offline event exists but parent has no push | Current event-to-notification policy and audience | Promise an offline alert that has not been implemented |
| Missing parent business alert | Transaction/outbox, recipient authorization, registration, provider outcome, client permissions | Blind resend; claim `accepted` proves handset display/read |
| Duplicate notification | Stable business ID, source-path replay, provider retry and client deduplication | Delete history or invent exactly-once guarantees |
| Location stops after relinking | Current unique ID/vehicle assignment and authoritative source | Enable unapproved phone fallback |
| Widespread outage | Dependencies, recent releases, database availability, ingestion/outbox lag and client impact | Restart every service simultaneously or run database undo |

Use an authorized bench tracker for interruption/reconfiguration exercises.
Do not disrupt an operating vehicle's tracker or send live emergency alarms
as a test.

## 5. Incident severity and escalation proposal

Have the operations owner approve the severity definitions and response windows.
These are proposed handling categories, not an existing SLA.

| Category | Examples | Handling |
|---|---|---|
| Immediate escalation | Possible safety impact, wrong-recipient information or broad tracking/alert failure | Notify designated operations owner; follow established emergency/privacy procedure |
| Urgent service issue | Active-trip tracking stale, sustained ingestion errors or important outbox backlog | Junior gathers minimal evidence; experienced owner directs recovery |
| Routine defect | Isolated reproducible issue without current operational impact | Reproduce safely, prioritize and add regression |
| Information/request | Configuration explanation or proposed behavior change | Document answer/decision; no production modification by default |

Before taking support ownership, fill in contacts, backup coverage, approved
working hours, communication channel and who can authorize changes. Outside
agreed coverage, use the established escalation route; two juniors are not an
implicit around-the-clock rotation.

## 6. Monitoring and measurements

Start with available evidence, not an assumed installed observability stack.
Any instrumentation below is proposed work until implemented and verified.

| Signal | Question it answers |
|---|---|
| Last contact and last usable fix, separately | Connected without a fresh position? |
| New/duplicate/ignored/rejected ingestion counts | Is acknowledged input becoming intended state? |
| Fix-to-persistence lag and authoritative location age | Is the pipeline timely, accounting for replay/skew? |
| Forwarding/client reconnect failures | Which ingress path is degraded? |
| Oldest eligible pending outbox item and failed/cancelled counts | Is business notification processing progressing? |
| Provider outcomes versus observed client behavior | Which delivery stage is actually evidenced? |
| Resource use, database latency and queue growth | Is bounded load approaching measured capacity? |
| Paid lookup/request usage and quota alarms | Is optional provider spending controlled? |

Do not label intentionally ignored/off-trip positions or cancelled stale
alerts as generic service failure. Stratify by reason and eligible audience.
Use UTC timestamps for incident correlation; show local time only as a clearly
labeled presentation. Approve thresholds after a baseline rather than tuning
freshness rules to hide an outage.

## 7. Supervised release checklist

1. Confirm the approved target environment, owner, maintenance/communication plan and supported client/tracker matrix.
2. Record immutable image/commit/config identifiers and schema compatibility for both Traccar and Carribu.
3. Review relevant regressions, untouched acceptance evidence and any required client/bench checks.
4. Confirm backup coverage and a restore-tested recovery route; identify which code/schema combinations can be rolled back.
5. Verify routing, credentials and provider destinations privately; check HTTP and tracker TCP paths separately.
6. Deploy in staging first. Check readiness, a synthetic decoded fix, persisted trip state, outbox and mock user outcome.
7. Obtain production approval separately. Observe the agreed window, define stop triggers and keep an experienced owner available.
8. Close with release evidence, residual risks and the next support owner.

Railway healthcheck gating and image rollback are tools, not proof of
full-path tracking readiness or restoration of database state [R8, R10].
Do not promise uninterrupted persistent tracker connections during deployment;
verify disconnect/reconnect behavior for the approved image and topology.

## 8. Backup, restore and rollback rehearsal

Inventory Traccar and Carribu data, schema versions, configuration, access
grants, required assets and provider/account recovery dependencies. Account
secrets need separate approved custody, not inclusion in a public backup
manifest.

Define recovery objectives with operations before promising an RPO/RTO.
For the exercise, restore synthetic backups to a **new disposable destination**,
check versions/permissions, verify representative records and replay an
authorized synthetic trip. Record observed recovery time and gaps. PostgreSQL
documents multiple backup approaches; choose one suitable for the owned
versions and objectives [R12].

An application rollback does not undo migrations or recover lost data.
Do not execute `db:migrate:undo`, drop tables or restore over a deployed
database as a junior's generic recovery step. Production recovery needs an
experienced owner, approved destination, communication and verified backups.

## 9. Reusable records

### Work item

```text
Problem and expected behavior:
Environment and affected contract:
Primary / backup / reviewer:
Acceptance cases and evidence level:
Non-goals and prohibited effects:
Dependencies and approval:
Verification / recovery implications:
Documentation affected:
```

### Incident

```text
UTC start / detection / resolution:
Environment and scope, with redacted identifiers:
Symptom and actual user impact:
Known-good version / recent approved changes:
Evidence by pipeline hop:
Actions, approvers and verification:
Operational communication:
Remaining uncertainty / regression / follow-up owner:
```

### Decision and monthly readiness

```text
Decision or readiness gate:
Date / accountable owner / reviewer:
Context and options:
Selected behavior and limits:
Evidence references:
Residual risks and supervision:
Next review date:
```

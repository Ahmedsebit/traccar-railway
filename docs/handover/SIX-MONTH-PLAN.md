# Six-Month Delivery, Learning and Ownership Plan

**Period:** November 1, 2026-April 30, 2027  
**Team:** Two junior engineers  
**Programme owner:** To be named before production responsibility

## 1. Outcomes and capacity assumptions

By April 30, the team should be able to explain the complete tracking path,
reproduce failures safely, deliver bounded reviewed changes, support routine
incidents and transfer knowledge to each other. Experienced approval remains
mandatory for high-risk changes.

The weekly packages below are sequencing guidance, not a commitment to deliver
all optional features. Work across mobile/web boundaries is coordinated with
those owners. Do not schedule a rewrite of Traccar, notification infrastructure
or the mobile apps within this two-person programme.

| Capacity assumption | Proposed arrangement |
|---|---|
| November | Emphasize foundations, safe setup and paired diagnosis rather than feature throughput |
| December-April | Start with 50% bounded delivery, 20% support, 20% learning/pairing and 10% documentation |
| Work in progress | One substantive item per engineer; one shared operational exercise at a time |
| Mentoring | Budget two 45-minute experienced pairing/review sessions weekly, plus release approval when needed |
| Interruptions | If support consumes over 30% of a fortnight, reduce planned delivery and review coverage |
| Leave/holidays | Re-plan actual availability; calendar weeks below do not imply seven-day staffing |
| Dependencies | No production ownership without a named approver, safe environment and usable recovery procedure |

The engineering owner must approve these assumptions. If mentoring or support
coverage is unavailable, narrow the scope instead of moving risk onto juniors.

## 2. Responsibility boundaries

| Work | Primary execution | Approval/coordination |
|---|---|---|
| Fixtures, documentation, bounded regression tests | A/B, peer-reviewed | Experienced reviewer for domain-sensitive assertions |
| Ingestion, timestamps, source selection and deduplication | Integration primary, backup pairing | Experienced engineering owner |
| Support triage and monitoring | Support primary, backup | Operational owner for incidents affecting service |
| Alert audience, offline policy and timing promises | Engineers prepare options | Product/school operations and engineering owners |
| Releases, secrets, database migrations/restores and tracker settings | Supervised engineer | Named operational owner |
| Parent/admin UI and mobile push behavior | Coordinated implementation | Existing mobile/web owners |
| Budget, retention and account access | Engineers supply inventory/evidence | Account/data owner |

Rotate A/B primary roles at each monthly review. Release approvers and external
owners do not rotate implicitly with the juniors.

## 3. Monthly milestones

| Month | Learning focus | Deliverables | Exit gate |
|---|---|---|---|
| November 2026 | Git, shell, HTTP/JSON, JavaScript async behavior, TCP/GPS concepts and product flow | System map, access ledger, safe setup, baseline inventory, first reviewed regression | Both engineers trace one fix and one failed update; no production data used |
| December 2026 | Payload contracts, timestamps/units, SQL, transactions, source policy and API authorization | Frozen development fixtures, ingestion regressions, freshness/deduplication evidence | Agreed contract cases pass; failure categories and alert-policy decisions are documented |
| January 2027 | Trip phases, transactional outbox, retries, client contracts and incident diagnosis | Alert lifecycle tests, provider-stub coverage, support decision tree, one approved bounded improvement | Demonstrate persisted event versus provider acceptance versus observed client behavior |
| February 2027 | Containers, Railway networking, versioned configuration, migrations and recovery | Supervised staging release, compatibility matrix, restore/rollback exercise, approval-ready dashboards | Backup engineer repeats the release/recovery procedure; production remains separately gated |
| March 2027 | Reliability, bounded load, latency measurement, capacity/cost review and failure drills | Representative synthetic load report, outage drills, alert-quality report, reviewed fixes | Targets approved against measured capacity; no critical controlled-scenario regressions |
| April 2027 | Cross-training, routine ownership and evidence-led acceptance | Untouched acceptance run, coordinated client/bench-device checks, final runbooks and sign-off | Both engineers pass teach-back; named owners accept residual risks and support arrangements |

If a gate fails, retain that month's ownership limits and re-plan. April does
not grant unrestricted production access automatically.

## 4. All 26 weekly work packages

Weeks are calendar blocks; the final block ends on April 30. Adjacent-month
dates are written explicitly to avoid hiding dependencies at month boundaries.
Learning should accompany actual reviewed work, not become a separate project.

| Week and dates | Integration primary's package | Support/testing primary's package | Learning and exit evidence |
|---|---|---|---|
| 1: November 1-7, 2026 | Trace tracker -> Traccar -> backend -> alert; inventory repositories and contracts | Inventory accounts, contacts, safe environments and support hours | Git/HTTP/JSON; both explain the map and record unknowns |
| 2: November 8-14, 2026 | Document configuration and identify actual deployed image/runtime | Reproduce startup checks; prepare mock receivers and redacted evidence conventions | Shell/env/TCP; another engineer follows setup without secrets in notes |
| 3: November 15-21, 2026 | Trace mapping, timestamps, speed conversion and source selection | Define positive/negative scenarios for no fix, stale fix and unknown device | Async JavaScript and GPS/GPRS/LBS; reviewed contract worksheet |
| 4: November 22-28, 2026 | Complete one small approved regression or diagnostic improvement | Reproduce it, review the PR and draft first incident decision tree | Red-green-refactor; first small contribution with clear evidence |
| 5: November 29-December 5, 2026 | Freeze development fixture schema and baseline identifiers | Separate acceptance fixtures; classify existing tests by evidence level | Test design; November gate and protected fixture inventory |
| 6: December 6-12, 2026 | Exercise mapping, active-trip eligibility and timestamp/coordinate rejection | Verify acknowledged-but-ignored updates are not counted as stored positions | SQL/API contracts; results distinguish 201, 200, 202 and errors |
| 7: December 13-19, 2026 | Exercise cross-path duplicates, ordering and assignment changes | Add boundary cases for future/stale timestamps and last-known display | Transactions/idempotency; no new duplicate business effects in controlled cases |
| 8: December 20-26, 2026 | Prepare offline/unknown policy options without changing production timeouts | Exercise heartbeat-only, silence and reconnect in an isolated environment | Network status versus GPS freshness; product/engineering policy review |
| 9: December 27, 2026-January 2, 2027 | Close December contract findings; choose one bounded January item | Update setup and support notes; account for holiday coverage | Teach-back; December gate, no unfinished high-risk release |
| 10: January 3-9, 2027 | Trace trip actions and GPS-triggered outbox creation | Verify morning/afternoon eligibility and stale-alert suppression | Domain state machines; clear event-to-audience map |
| 11: January 10-16, 2027 | Exercise worker leases, retries and stable event IDs | Stub missing tokens, provider errors and receipt outcomes | Retry/at-least-once semantics; persistence and delivery evidence separated |
| 12: January 17-23, 2027 | Coordinate one agreed API/client diagnostic change, if approved | Check admin/parent freshness, polling, permissions and error presentation with client owners | Contract compatibility; reviewed change or documented blocked dependency |
| 13: January 24-30, 2027 | Resolve prioritized alert defects with regression coverage | Run missing-alert and stale-position support rehearsals | Structured diagnosis; January gate and support playbook |
| 14: January 31-February 6, 2027 | Draft image/configuration change and dependency compatibility checklist | Confirm access, release approvers, backup scope and restoration destination | Docker/Railway basics; staging release plan reviewed before execution |
| 15: February 7-13, 2027 | Perform supervised staging deployment using approved immutable identifiers | Observe readiness, TCP intake, ingestion and mock alert outcomes | Deployment is not full-path readiness; evidence at every hop |
| 16: February 14-20, 2027 | Rehearse application rollback with schema compatibility checked | Restore synthetic backups into a separate disposable destination | PostgreSQL recovery; measured procedure, no automatic migration undo |
| 17: February 21-27, 2027 | Document version upgrade assessment and migration dependencies | Backup engineer repeats runbooks without undocumented help | Recovery teach-back; February gate and approval record |
| 18: February 28-March 6, 2027 | Define a measured, bounded synthetic load profile | Define denominators, latency clocks, stop conditions and evidence storage | Measurement basics; approved capacity/latency experiment specification |
| 19: March 7-13, 2027 | Run approved isolated load/reconnect scenarios; inspect bottlenecks | Record ingest lag, duplicate effects, missing events and resource use | Performance without speculative tuning; report includes failures |
| 20: March 14-20, 2027 | Exercise backend/provider interruptions and recovery paths | Conduct incident drills and check backlog recovery, not just HTTP health | Reliability diagnosis; owner-approved recovery actions |
| 21: March 21-27, 2027 | Implement the smallest justified reliability improvement | Repeat affected controls; review quota/cost and alert fatigue evidence | Controlled comparison; March gate and residual-risk register |
| 22: March 28-April 3, 2027 | Freeze acceptance candidate and prepare cross-owner release evidence | Arrange authorized bench-device/client checks and acceptance reviewers | No tuning on acceptance results; March closeout and April schedule |
| 23: April 4-10, 2027 | Run untouched acceptance fixtures against the frozen candidate | Independently record expected/observed results and failure classifications | Functional acceptance, not real-world accuracy claims; complete report |
| 24: April 11-17, 2027 | Coordinate approved bench tracker and client end-to-end checks | Verify parent/admin outcomes with permissions, reconnect and mock/test accounts | Hardware/client evidence recorded separately from synthetic replay |
| 25: April 18-24, 2027 | Teach backup owner integration/release diagnosis; close blocking issues | Teach backup owner support/recovery; check access/contact inventories | Both reproduce owned procedures; final checklist ready |
| 26: April 25-30, 2027 | Present maintenance backlog, release evidence and architecture decisions | Present support coverage, unresolved risks and recovery evidence | Explicit owner sign-off or documented limited handover; no silent acceptance |

Month-two onward work requires month-one setup and learning readiness. Do not
replace a failed gate with a larger feature to demonstrate apparent progress.

## 5. Working rhythm and technical learning

| Cadence | Practice |
|---|---|
| Start of week | Review incidents, choose bounded tasks, confirm dependencies and acceptance criteria |
| Daily | Brief blockers/support handoff; record actions without copying sensitive payloads |
| Twice weekly | Protected experienced pairing/review; practise explaining decisions and failures |
| End of week | Demonstrate evidence, update relevant docs and transfer one lesson to the backup |
| End of month | Review gate, capacity, support burden, owner assignments and open risks |

Study in this order: programming/async JavaScript and Git; HTTP/JSON and TCP;
SQL/transactions and domain state; deterministic tests; retry/outbox/client
contracts; deployments/recovery; bounded measurement. Framework or tool usage
does not substitute for understanding timestamps, transactions or ownership.

Use owned source modules listed in the technical notes as exercises. Consult
official vendor documentation matching the approved versions. Do not copy
unverified timeout snippets from old forum posts.

## 6. Priorities, scope control and risk register

| Priority/risk | Response | Owner |
|---|---|---|
| P0: Unknown production configuration or no recovery owner | Inventory and assign ownership before releases | Operational owner |
| P0: No experienced review capacity | Keep juniors in supervised/non-production scope | Engineering owner |
| P0: Test/provider paths can touch real data or recipients | Block execution until isolation is demonstrated | Engineering/data owners |
| P1: Wrong source, stale/future positions or duplicate business effects | Preserve invariants; add focused regressions before changes | Integration primary |
| P1: Raw offline events mistaken for configured parent alerts | Approve audience/debounce/recovery policy first | Product and engineering owners |
| P1: Approximate LBS coordinates used for precision-sensitive alerts | Decide quality handling with evidence before enabling/changing policy | Product and engineering owners |
| P1: Migration/deployment rollback assumed to restore data | Rehearse compatible rollback and separate restore | Operational owner |
| P2: Support overload or mobile/web dependency delays | Reduce delivery scope; retain evidence and safety gates | Programme owner |
| P2: Capacity/latency/cost targets not grounded | Measure a bounded baseline before promising targets | Engineering/account owners |

Initial backlog should prioritize inventory, repeatable fixtures, timestamp and
source regressions, diagnostics and recovery. New geolocation behavior,
parent-facing offline push, horizontal scaling and protocol changes are
optional, approval-dependent items rather than six-month promises.

## 7. Final handover decision

Approve routine ownership only when both engineers can reproduce setup, trace
a failure, explain source/freshness/alert semantics, complete a reviewed change,
follow support escalation and execute supervised release/recovery procedures.
Use the [acceptance checklist](TESTING-AND-ACCEPTANCE.md#7-acceptance-and-final-handover).

Possible outcomes are **accepted for agreed routine scope**, **accepted with
explicit limitations**, or **blocked pending named items**. Record the actual
outcome, approver, date, evidence and remaining supervision; do not equate six
months of attendance with operational readiness.

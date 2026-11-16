# Synthetic Evaluation and Acceptance Plan

**Status:** Specification for future team execution; no new tracking experiment results in this pack  
**Goal:** Establish controlled functional behavior across the tracker-to-user-alert path  
**Limits:** Synthetic replay does not establish field GPS/LBS accuracy, handset delivery or operational safety

## 1. Separate the evidence levels

| Level | What executes | What passing establishes |
|---|---|---|
| L0: Wrapper preflight | Shell/configuration validation before database initialization | Startup-input checks, not decoding or provider resolution |
| L1: Pure/mocked components | Contract, timestamp, mapping and adapter logic | Those decisions under controlled dependencies |
| L2: Real database integration | Disposable PostgreSQL plus owned transaction/persistence paths | Actual constraints, deduplication, outbox and concurrency effects |
| L3: Real Traccar replay | Pinned upstream server, synthetic protocol frames, isolated database and receivers | Decoding, status/events and forwarding for those fixtures |
| L4: Full synthetic platform | L3 plus Carribu, approved synthetic trips and mock delivery | Expected state and notification effects across owned components |
| L5: Authorized bench/client checks | Supported bench tracker and approved client/test-provider setup | Observed behavior for the tested hardware/client conditions |

A backend JSON test is not a GPS103 decoder test. A loopback fake Traccar
service is not a real upstream server. A mock push result is not handset
delivery. Keep these results separate in every report.

Use deterministic expected state/event assertions, not an LLM judge or the
email-study rubric. Product owners must approve ambiguous alert policy;
engineering then tests its explicit rules.

## 2. Prepare isolation before fixtures or replay

- [ ] Pin approved Traccar image/digest, owned commits and configuration.
- [ ] Use separate disposable Traccar and Carribu databases with synthetic identities.
- [ ] Check all receiver/poll/socket/provider destinations; disable real provider calls or replace them with controlled mocks.
- [ ] Prove actual notification recipients are synthetic/mock, not merely that the database has a test-like name.
- [ ] Keep optional paid geolocation disabled unless a separately approved provider test requires it.
- [ ] Use loopback or approved isolated staging interfaces; no production replay.
- [ ] Set resource/runtime/message-rate limits and stop conditions before execution.
- [ ] Define exact created resources and cleanup ownership; never broadly delete a workspace/database.

Test configuration must not inherit production `.env`, accounts, device tokens
or receiver settings. Remember that disabling backend polling does not disable
Traccar HTTP forwarding.

## 3. Frozen fixture specification

Each scenario should contain the following, with synthetic-only content:

```text
scenario_id, fixture_version, scenario_group
purpose and tested contract
level: L0-L5
approved image/commits/configuration reference
synthetic device/vehicle/trip/school/recipient mapping
initial database/trip/connection state
fixed time origin or documented real-clock schedule
ordered protocol inputs and/or JSON contract inputs
expected decoded positions, IDs, units and timestamps
expected persisted/live/reference-only state
expected raw events and eligible business notifications
expected ignored/rejected reasons and prohibited effects
timing tolerances, resource bound and stop conditions
```

Protocol frames must follow the approved protocol specification and pinned
decoder behavior. Preserve provenance/licensing of any upstream test fixture
used. Do not invent supposedly valid device packets with an LLM and then use
them as a decoder oracle.

Use fixed clocks for pure rules. For real status/reconnect tests, document
clock synchronization and timer configuration. Fast sandbox timeout settings
must be labeled scaled tests, not claimed as production timing evidence.

Separate development fixtures from untouched acceptance fixtures before
tuning. Acceptance should vary routes, identities, timing patterns and
failures rather than duplicate the same route with renamed IDs.

## 4. Required controlled scenarios

Start with one positive and one negative example for each supported behavior,
then add the boundary cases below. Unsupported/proposed policies remain
explicitly blocked, not silently marked passed.

| ID/group | Inputs or condition | Expected observation |
|---|---|---|
| P01: Position | Valid stationary fix, mapped active trip | Correct coordinates/source/time; no invented motion or duplicate business effect |
| P02: Position | Moving synthetic route with known speeds | Correct ordering and knots-to-km/h conversion; latest authoritative point correct |
| P03: Position | Explicit invalid GPS fix | Acknowledged/ignored; no new fresh trip fix or ETA effect |
| P04: Position | Missing/non-finite/out-of-range coordinates | Rejected according to the payload contract; no persisted side effects |
| P05: Time | Missing/invalid usable timestamp | Ignored; receipt time must not invent a fresh fix |
| P06: Time | Allowed future-skew boundary and just beyond it | Current 30-second rule preserved; rejected excess does not change live state |
| P07: Time | Freshness boundary and older fix | Current 120-second rule preserved; stale history/reference is not live ETA input |
| P08: Time | A delayed older point after a newer one | Historical retention may occur; no newer live-state replacement or new proximity alert |
| M01: Mapping | Unknown or inactive device/vehicle | Acknowledged with ignored reason; no unrelated trip effects |
| M02: Mapping | Mapped device, no active trip | No active-trip position created |
| M03: Mapping | Fix predates trip start | No new trip-history point; any reference snapshot remains explicitly reference-only |
| M04: Mapping | Relink while an update is being processed | Assignment/source guards prevent an update under the obsolete assignment |
| M05: Source | Linked tracker offline while phone sends GPS | No automatic phone fallback; documented rejection/source behavior |
| M06: Isolation | Two schools, trips and synthetic recipients | Only mapped/scoped records and permitted user outputs; no cross-school recipient effects |
| D01: Deduplication | Same position/event ID via webhook, poll and socket | No extra ID-based persisted/business effect |
| D02: Deduplication | Repeated payload with missing IDs | Observe current behavior; do not assume missing-ID deduplication |
| C01: Connectivity | Heartbeat/contact without usable coordinates | Connection status and GPS freshness remain separate |
| C02: Connectivity | Silence, explicit disconnect and reconnect | Observe status/raw-event transitions for the pinned protocol/timers; no invented universal offline rule |
| C03: Connectivity | Backend socket loss, expired session and recovery | Controlled reconnect/resnapshot; delayed snapshots do not replace newer queued live data |
| C04: Forwarding | Receiver rejects auth or temporarily fails | Failure visible; verify actual position/event retry behavior separately |
| A01: Business alerts | Morning versus afternoon boarding/travel | Eligible trip/near-stop/ETA effects match phase rules; boarding suppresses inappropriate ETA |
| A02: Business alerts | Out-of-order/stale fix or trip ends before delivery | No new inappropriate proximity effect; late ineligible queued alert cancelled |
| A03: Business alerts | Recipient access revoked/reassigned | Authorization rechecked; no alert to a newly unauthorized recipient |
| A04: Business alerts | Transaction fails before commit | No partially committed trip/GPS business mutation/message/outbox |
| A05: Delivery | Provider failure, missing registration, receipt wait | Accurate outcomes/retry/cancellation; no false handset-delivered/read label |
| A06: Delivery | Worker interruption, lease recovery and repeated realtime event | Recoverable work; stable event IDs; no assumption of exactly-once provider delivery |
| A07: Product policy | Raw offline/recovery event versus desired parent push | Current raw path observed separately; parent policy tested only after approval/implementation |
| U01: User view | Fresh/stale/reference-only/failed tracking request | Supported UI labels correct; no stale ETA presented as live |
| U02: User view | Trip selection changes, completion or delayed response | Old request/trip cannot replace current selection/state |
| U03: User delivery | Permission denied, foreground/background and reconnect | Record client/provider observations separately; no acceptance-by-server shortcut |
| O01: Operations | Staging restart/release and approved recovery exercise | Reconnect, data/state compatibility and recovery verified at the needed levels |
| O02: Optional LBS | Mock coarse location and quality metadata | Record current metadata limitations; precision-sensitive behavior needs approved quality policy |

School-boundary cases require real owned authorization/persistence paths at
L2/L4, not just a mocked `schoolId` argument. Protocol and physical behavior
need L3/L5. Use controlled supported alarm simulations only; no live emergency
messages or vehicle interference.

## 5. Development pilot and comparison

1. Approve expected outcomes and unresolved policies; classify each case by evidence level.
2. Run a small balanced baseline pilot with normal, ignored/rejected and failure/recovery cases.
3. Audit each mismatch by layer: fixture, decoder, timing, forwarding, mapping, database/domain, worker/provider or client.
4. Fix only confirmed bounded issues with regression evidence and required review.
5. Freeze a candidate, then replay the same development scenarios under identical conditions.
6. Execute untouched acceptance scenarios once the development gate passes. Do not silently tune and reuse failed acceptance cases as fresh confirmation.

Version any amended fixture/expectation with its rationale and approval. An
incorrect oracle is not repaired by relabeling it to match the implementation.
After acceptance-driven fixes, disclose exposure and arrange fresh or
explicitly regression-only cases for the affected requirement.

## 6. Measurements, denominators and reporting

| Measurement | Definition/caution |
|---|---|
| Scenario conformance | Report every required case as pass/fail/blocked, plus observed versus expected; do not hide blocks in a percentage |
| Position integrity | Correct IDs, timestamps, source and coordinate/unit tolerances for the known inputs |
| Missing/extra events | Compare eligible expected stable events with observed events; report duplicates separately |
| Alert precision/recall, if useful | TP/FP/FN against an approved eligible-audience/time-window oracle, separately for each alert type |
| Latency | Name start/end clocks: receipt-to-persistence, eligible-event-to-provider acceptance, or separately observed client presentation |
| Freshness | Fix-age distribution and freshness labels; replayed old fixes are not normal processing-latency samples |
| Recovery | Time from controlled failure to expected ingestion/outbox/client recovery, with the failure interval documented |
| Load/resources | Device/message profile, concurrency, duration, queue growth and CPU/memory/database observations |

For alert metrics define `precision = TP/(TP+FP)` and `recall = TP/(TP+FN)`.
Use "not applicable" for an empty denominator, not a fabricated perfect score.
Pair events by their agreed identity/audience/window; do not count each polling
read as an independent delivery.

Report repetitions and route/scenario groups. Repeated variants share inputs
and are not independent field replications. Report latency percentiles only
with the sample count and clock/error treatment. Do not use phone/provider
latency as evidence of physical GPS accuracy.

```text
Run ID / date / executor / approver:
Purpose, evidence levels and approved limits:
Image digest / Git commits / schema / redacted config / fixtures:
Initial state and clocks/timers:
Case -> expected -> observed -> pass/fail/blocked -> evidence:
TP/FP/FN and duplicate counts by approved alert type:
Latency endpoints, sample counts and summary:
Failures, retries, resource use and cleanup:
Limitations, residual risks and decision:
```

Store approved redacted artifacts in the organization's evidence location.
Do not commit raw customer/device traces or secret-bearing logs.

## 7. Acceptance and final handover

**Proposed controlled-test gate:** All mandatory approved cases pass at their
required evidence level, with no unexpected wrong-recipient alerts, stale data
promoted to live, duplicate business effects under supported IDs, or broken
source/transaction rules. Performance/recovery targets must be approved after
the baseline; no numeric production SLA is asserted here.

- [ ] Product/source/offline/LBS policy decisions are signed off or explicitly out of scope.
- [ ] Immutable versions, approved configurations and supported tracker/client matrix recorded.
- [ ] Untouched acceptance results cover the required levels and meaningful negative boundaries.
- [ ] Any handset/hardware claims have separate authorized observations.
- [ ] No real data/recipients used in routine synthetic replay; cleanup verified.
- [ ] Both engineers can follow setup, diagnose a failed hop and explain ignored versus persisted input.
- [ ] Both can explain raw tracker events versus parent business alerts and provider acceptance versus client evidence.
- [ ] Backup engineer reproduces the supervised release/rollback/restore procedure.
- [ ] Mentoring, support hours, escalation, account custody and release approval are assigned.
- [ ] Monitoring targets, residual risks, maintenance backlog and review date agreed.
- [ ] Named owners record accepted scope, limitations, evidence and date.

Blocked critical cases prevent full acceptance. A limited handover may still
cover documentation, local diagnosis or routine supervised support when
explicitly approved; it must not imply unverified production readiness.

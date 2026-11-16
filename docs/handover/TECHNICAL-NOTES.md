# Technical Notes: Current Tracking and Alert Path

**Inspection date:** November 1, 2026  
**Evidence:** Local source/README inspection; production configuration and delivery unverified  
**Purpose:** Explain existing behavior and identify decisions needed before changes

## 1. System map and ownership

```text
Synthetic or authorized physical GPS103 tracker
    -> TCP endpoint -> Traccar protocol decoding and event generation
    -> Traccar PostgreSQL database
         -> JSON position/event forwarding -> authenticated Carribu webhooks
         -> optional Carribu REST snapshot/polling + live WebSocket client
    -> shared tracker ingestion -> mapped active vehicle/trip
         -> trip position history and reference-only tracker snapshot
         -> raw TrackerEvent storage + school-room tracker-event diagnostics
    -> eligible trip/GPS business events -> Message + NotificationOutbox
    -> outbox worker -> user realtime events + Expo/FCM submission
    -> client polling/realtime/push handling -> observed user presentation
```

Raw tracker events and parent business notifications are separate branches.
Do not assume every Traccar alarm/status event creates a parent notification.
Traccar itself supports events and notifications; Carribu's user-facing behavior
depends on the owned ingestion/business paths, not just that capability [R2].

| Component | Current responsibility | Boundary |
|---|---|---|
| `traccar-railway` | Image wrapper, XML configuration, PostgreSQL initialization and startup | Upstream Java server comes from the base image |
| `carribu_backend` | Machine authentication, mapping, trip/source policy, persistence and notification work | Backend remains authority for trip and recipient rules |
| `carribu_admin_app` | School-scoped tracking and notification diagnostics | Diagnostic success is not proof of handset delivery |
| `carribu_parent_native_app` | Kotlin/Compose parent tracking, alerts and FCM handling | Native polling/push needs its own device-level verification |
| Driver, legacy parent and other client repositories | Phone-source input or user presentation, where still supported | Confirm supported apps with their owners; do not assume native and legacy clients behave identically |
| PostgreSQL/Railway/provider accounts | Data, deployment, network and external service operations | Privileged decisions require named owners |

Workspace repositories have separate manifests and dependency installations.
The companion general Carribu guide covers their broader learning/release plans.

## 2. Repository and startup reference

| This repository file | Inspected behavior |
|---|---|
| `Dockerfile` | Uses `traccar/traccar:latest`; installs PostgreSQL client tools; copies wrapper configuration/scripts; clears inherited entrypoint |
| `init-db.sh` | Checks/creates the named Traccar database through the PostgreSQL maintenance database; upstream Traccar owns `tc_*` schema migrations |
| `start.sh` | Validates PostgreSQL inputs and optional LBS inputs before initialization, waits for PostgreSQL, then starts the upstream server |
| `traccar.xml` | Configures PostgreSQL, GPS103 port 5001, web/API port 8082, position/event JSON forwarding and console logging |
| `tests\startup.test.cjs` | Tests shell syntax and pre-database configuration validation; does not exercise Traccar decoding, a database or Google |

The wrapper sets `CONFIG_USE_ENVIRONMENT_VARIABLES=true`. Use the configuration
reference for the pinned upstream version when resolving XML versus environment
settings [R3]. Environment inventory must contain names and ownership, not
credential values.

The current image tag is not an immutable deployment identity. Identify the
actual deployed image/version, then propose an approved tag/digest pin. Preserve
a controlled update process; pinning is not a reason to stop security updates
[R9]. This pack changes neither the image nor deployment settings.

The wrapper starts Java with a 256 MB initial heap and 512 MB maximum heap.
These are heap settings, not a measured total-container memory budget or a
capacity guarantee. Measure actual resources before tuning.

## 3. Configuration and networking

| Setting | Purpose | Handover caution |
|---|---|---|
| `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD` | PostgreSQL connection inputs required by the wrapper | Keep secrets private; database user needs initialization permissions |
| `TRACCAR_DATABASE_NAME` | Traccar database name; wrapper default is `traccar` | Do not confuse it with the Carribu application database |
| `PGMAINTENANCE_DB` | Database used by initialization; default is `postgres` | Verify maintenance connectivity without changing production data |
| `FORWARD_URL`, `FORWARD_HEADER` | Position receiver and machine-auth header | Override the XML's localhost placeholder; verify privately in the target environment |
| `EVENT_FORWARD_URL`, `EVENT_FORWARD_HEADER` | Event receiver and machine-auth header | Event forwarding is independently configured |
| `GEOLOCATION_ENABLE` | Optional LBS switch; default disabled | Enabling involves quality, carrier, provider and cost decisions |
| `GEOLOCATION_KEY`, `GEOLOCATION_MCC`, `GEOLOCATION_MNC` | Optional provider credential and explicit carrier fallback | Key is secret; codes are carrier identifiers, not phone/APN/country-calling codes |
| Backend `TRACKER_WEBHOOK_TOKEN` | Shared secret for Carribu machine endpoints | Coordinate both forward headers and backend rotation; do not print values |
| Backend `TRACCAR_ENABLED`, `TRACCAR_URL`, `TRACCAR_TOKEN` | Optional account-based REST/WebSocket ingestion | Account token and webhook secret have different purposes |
| Backend `FIREBASE_SERVICE_ACCOUNT_JSON` | Server-side native FCM credential | Never embed in clients, docs, container images or fixtures |

The backend machine middleware accepts a bearer authorization header or
`x-tracker-token`. It returns 503 when no shared secret is configured and 401
for a mismatch. Use HTTPS outside an approved private/local network; store and
rotate credentials through the account owner's process.

`TRACCAR_ENABLED=false` disables Carribu's polling/socket client. It does
**not** disable the separate HTTP webhook routes or Traccar's forwarding.
Do not use it as the sole isolation control in a training environment.

Keep three network concerns separate:

| Concern | Repository baseline | What must be verified |
|---|---|---|
| Tracker data | GPS103 listener 5001 | Approved model/protocol, TCP proxy hostname/public port, APN/network and reporting cadence |
| Traccar administration/API | Web port 8082 | HTTPS/access controls and correct Railway HTTP routing |
| Traccar -> Carribu | Position/event receivers | Private routing, backend port and matching machine authentication |

Railway TCP proxy exposes raw TCP services, not an HTTP replacement [R7].
Do not assume a generic `PORT` variable changes Traccar's configured web port.
Verify the effective port and healthcheck route before a release.

## 4. Backend source map

These are paths in the sibling `carribu_backend` repository.

| Read in order | File/module | Why it matters |
|---|---|---|
| 1 | `server.js`, `routes\tracker.js`, `controllers\trackerController.js` | Mounts `/tracker/position` and `/tracker/event`; controller response/error boundary |
| 2 | `middleware\trackerWebhook.js` | Machine-to-machine authentication, distinct from user JWTs |
| 3 | `services\trackerIngestion.js` | Payload validation, device/vehicle mapping, timestamp choice, units and result classification |
| 4 | `services\traccarClient.js` | Account session, REST snapshots, 60-second polling, queued live socket processing and reconnect |
| 5 | `services\trackerPositionSnapshot.js` | Assignment-bound latest reference snapshot without replacing it with older data |
| 6 | `services\locationTracking.js`, `services\tripPlan.js` | Authoritative source, trip history, freshness, ordering and proximity/ETA eligibility |
| 7 | `services\tripWorkflow.js` | Frozen trip plans, state transitions and business-event transactions |
| 8 | `services\notificationOutbox.js`, `services\push.js` | Durable notification work, leases/retries, recipient rechecks and provider outcomes |
| 9 | `migrations\0016-trip-workflow-and-notification-outbox.js` | Schema compatibility and rollback/recovery implications |

Relevant admin modules are `src\components\VehicleLocationCard.js` and
`src\components\TripNotificationDiagnostics.js`. Consult the native-parent
README and owned model/push/polling code with its owner for the client boundary.

## 5. Position, source and time contracts

| Contract | Inspected behavior | Required regression |
|---|---|---|
| Mapping | `device.uniqueId` matches an active vehicle's `trackerUniqueId` | Unknown, inactive, relinked and cross-school cases |
| Trip eligibility | Positions need that vehicle's active trip | No-active-trip and pre-trip fixes do not become active-trip points |
| Coordinate validation | Latitude/longitude must be present, finite and within geographical bounds | Missing, empty, non-finite and out-of-range values |
| GPS validity | Explicit `valid: false` is acknowledged but ignored | No fresh point/ETA effect from an invalid fix |
| Timestamp selection | `fixTime`, then `deviceTime`, then `serverTime`; invalid/missing usable time is ignored | Preserve the chosen timestamp; do not relabel old data with receipt time |
| Future skew | More than 30 seconds ahead is ignored | Exact allowed/rejected boundary |
| Freshness | Age from -30,000 through 120,000 ms is fresh in current backend policy | Exact boundaries and client alignment |
| Speed | Traccar speed in knots is multiplied by 1.852 for km/h | Zero, absent and known conversion examples |
| Source | Linked vehicle uses Traccar; unlinked vehicle can use phone GPS | No automatic phone fallback for a linked offline tracker |
| Ordering | Older trip points may be retained as history but do not move live state/trigger new ETA alerts | Delayed replay cannot overwrite newer live state |
| Deduplication | Supplied numeric position/event IDs are deduplication keys | Same ID through webhook/poll/socket paths creates no extra business effect |

Missing IDs do not gain the same ID-based deduplication guarantee. Independent
Traccar instances can have overlapping identifiers; approve instance identity
and namespacing before pointing multiple instances at one ingestion database.

A reference snapshot may predate the active trip. It retains its original
timestamp and is exposed with `isLastKnown` and, when applicable, `predatesTrip`.
The admin UI labels it reference-only, not a new trip-history point. Stale data
must not be made "live" by changing display text or replacing its timestamp.

### HTTP result interpretation

| Result | Meaning in the ingestion path |
|---|---|
| 201 | A new position/event was persisted |
| 200 with `duplicate: true` | An identified item was already present |
| 202 with `ignored` | Transport acknowledged; item deliberately not used, with a reason |
| 400 | Invalid payload |
| 401 / 503 | Machine authentication rejected / missing configuration |
| 500 | Processing failure; investigate the owning layer |

A successful HTTP acknowledgment is not necessarily a stored trip position.
Record response bodies and ignored-reason counts in controlled tests. Traccar
supports forwarding; retry and event-delivery behavior must be checked against
the pinned upstream version rather than inferred from one successful request
[R1]. Position retry is enabled in this XML; do not assume identical event
retry/durability semantics.

## 6. Connectivity, business alerts and user presentation

**Connectivity is not location quality.** An online connection/heartbeat does
not establish a recent usable GPS fix. Treat protocol connection status,
time since last contact, GPS timestamp and user-visible freshness separately.
Record timeout units/defaults from the approved Traccar version and protocol.
Do not prescribe a universal offline/unknown timer from historical forum posts.

The current raw-event path persists `TrackerEvent` and emits `tracker-event`
to the mapped school's realtime room. It does not enqueue the parent
notification outbox. Parent-facing offline/recovery push requires a separately
approved audience, active-trip policy, debounce, cooldown, recovery rule and
implementation. Test raw event receipt and product notification policy as
different requirements.

Business trip actions persist in-app messages and outbox work transactionally.
Fresh authoritative GPS may enqueue approximate ETA/near-stop warnings.
Afternoon school boarding, stale fixes and out-of-order live updates suppress
new proximity/ETA effects. Current near-stop eligibility uses 200 metres;
ETA warning eligibility uses the existing five-minute rule. Estimates use
straight-line distance and stop buffers, not a guaranteed road arrival time.

The outbox worker rechecks recipient/school access and proximity eligibility,
uses recoverable leases and retries failed submissions. Stable business event
IDs support client deduplication. Its statuses include `pending`, `processing`,
`pending_receipt`, `retrying`, `unregistered`, `accepted`, `failed` and
`cancelled`. Do not confuse these with tracker connection statuses.

Provider `accepted` is not handset receipt, notification display or parent
read. Keep those evidence levels distinct [R11]. Database transactions do not
guarantee exactly-once external provider/handset effects.

The inspected admin vehicle card polls every 10 seconds and notification
diagnostics every 15 seconds. Native-parent documentation describes
lifecycle-aware location/chat polling at 10 seconds and alerts at 20 seconds.
These intervals are not end-to-end latency SLAs; verify supported clients and
measure the full path in the approved environment.

## 7. Optional LBS and precision limitations

Traccar supports network-based location when usable Wi-Fi/cell information is
available [R4]. Google returns coordinates plus an accuracy radius [R5].
Heartbeat/IMEI alone is not sufficient carrier-location evidence.

The wrapper defaults LBS to disabled. It requires an explicit provider key and
valid MCC/MNC when enabled. Global carrier fallback must match the reported
network; it is not a safe guess for mixed-carrier devices omitting those fields.
Valid provider-resolved positions can enter the current backend, but the
inspected ingestion does not carry accuracy/approximate metadata into its
position values. Do not assume proximity alerts are accuracy-aware.

Before proposing LBS changes: approve quality requirements, identify payload
support, preserve/test quality metadata as an explicit change if required,
agree precision-sensitive alert behavior and verify costs/quotas. API billing
and limits need account-owner approval [R6]. Maps display, geocoding and
geolocation use different products/credentials. Keep provider calls mocked in
routine training; no promise of BAANOOL/vendor-equivalent accuracy.

## 8. Deployment and readiness cautions

Carribu startup runs application migrations before listening unless legacy
`DB_SYNC` is set. Do not use `DB_SYNC` as an operational recovery shortcut.
Traccar owns its separate upstream schema. Inventory compatibility for both
databases before changing versions.

The backend `/api/health` route returns a static application response. It does
not check a fresh tracker packet, current database operation, outbox processing
or handset display. Railway healthcheck gating is useful, but does not replace
these application-specific acceptance checks [R8].

Application image rollback and database restore are different operations.
Migration `0016` reversal removes snapshots/outbox/idempotency metadata; a
blind undo is not a safe generic rollback. Rehearse recovery with compatible
versions and an approved disposable destination [R10, R12].

## 9. Approval ledger and unknowns

| Decision or unknown | Proposed owner | Status/evidence required |
|---|---|---|
| Actual deployed Traccar version/digest and backend/client commits | Operational owner | Not verified; record immutable identifiers |
| Supported tracker models/protocols, firmware and reporting cadence | Device/operations owner | Inventory and authorized bench evidence |
| Production versus training boundaries and allowed recipients | Engineering/data owner | Written isolation and mock-provider proof |
| Offline/unknown/recovery policy and whether parents receive it | Product + engineering | Unapproved; no automatic push assumption |
| Supported native/legacy clients and cross-team ownership | Product/client owners | Confirm matrix and release responsibilities |
| Mentor, release approver and support coverage | Programme owner | Assign before production responsibility |
| Latency/capacity/load/cost targets | Engineering/account owners | Approve after bounded baseline |
| Location/diagnostic retention, access and support evidence handling | Data owner | Organization-specific policy review; jurisdiction not assumed |
| Backup scope, restore objective and compatible rollback versions | Operational owner | Rehearsal and approval required |
| LBS quality metadata and precision-sensitive alert policy | Product + engineering | Remain disabled/unmodified until approved evidence |

Record decisions with date, approver, context, options, selected behavior,
affected versions, regression evidence and recovery implications.

## 10. Primary references

Reviewed on November 1, 2026. These references provide general vendor guidance;
they are not evidence of this deployment's settings. Re-check version-specific
instructions before execution. URLs are written as copyable code.

| ID | Primary source | URL |
|---|---|---|
| R1 | Traccar forwarding | `https://www.traccar.org/forward/` |
| R2 | Traccar events and notifications | `https://www.traccar.org/events/` |
| R3 | Traccar configuration | `https://www.traccar.org/configuration-file/` |
| R4 | Traccar LBS | `https://www.traccar.org/lbs-geolocation/` |
| R5 | Google Geolocation request/response | `https://developers.google.com/maps/documentation/geolocation/requests-geolocation` |
| R6 | Google Geolocation usage/billing | `https://developers.google.com/maps/documentation/geolocation/usage-and-billing` |
| R7 | Railway TCP proxy | `https://docs.railway.com/networking/tcp-proxy` |
| R8 | Railway healthchecks | `https://docs.railway.com/deployments/healthchecks` |
| R9 | Docker image/build practices | `https://docs.docker.com/build/building/best-practices/` |
| R10 | Railway deployment rollback | `https://railway.com/guides/roll-back-bad-deploy` |
| R11 | Firebase delivery evidence | `https://firebase.google.com/docs/cloud-messaging/understand-delivery` |
| R12 | PostgreSQL backup and restore | `https://www.postgresql.org/docs/current/backup.html` |
| R13 | OWASP logging practices | `https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html` |
| R14 | Node.js release support | `https://nodejs.org/en/about/previous-releases` |

Use a supported Node release compatible with the owned manifests, dependencies
and tested builds [R14]. An old README minimum version is not a current support
recommendation; runtime upgrades are separately reviewed changes.

# Carribu Traccar service

## Team handover

See the [tracking-platform handover pack](docs/handover/README.md) for the
November 2026-April 2027 plan for two junior engineers, architecture and
integration notes, engineering practices, support runbooks and acceptance
testing. It covers the tracker-to-user-alert path across repository boundaries.
The programme is proposed work, not evidence of production readiness.

Deploy this repository as a separate Railway service. Leave **Root Directory**
blank so Railway detects the root `Dockerfile`.

## Railway variables

Replace `Postgres` and `backend` if your Railway services use different names:

```properties
PGHOST=${{Postgres.PGHOST}}
PGPORT=${{Postgres.PGPORT}}
PGUSER=${{Postgres.PGUSER}}
PGPASSWORD=${{Postgres.PGPASSWORD}}
TRACCAR_DATABASE_NAME=traccar
FORWARD_URL=http://${{backend.RAILWAY_PRIVATE_DOMAIN}}:5000/tracker/position
EVENT_FORWARD_URL=http://${{backend.RAILWAY_PRIVATE_DOMAIN}}:5000/tracker/event
FORWARD_HEADER=Authorization: Bearer ${{backend.TRACKER_WEBHOOK_TOKEN}}
EVENT_FORWARD_HEADER=Authorization: Bearer ${{backend.TRACKER_WEBHOOK_TOKEN}}
```

The startup script builds Traccar's `DATABASE_URL`, `DATABASE_USER`, and
`DATABASE_PASSWORD` from these `PG*` variables. Do not add public proxy
connection values or duplicate `DB_*` variables to the Traccar service.

The backend service must define a long random `TRACKER_WEBHOOK_TOKEN`. No secret
is stored in this repository.

## Database pre-deploy initialization

Set the Railway **Pre-deploy Command** to:

```sh
/opt/traccar/init-db.sh
```

The script connects to PostgreSQL's maintenance database, creates `traccar`
only when it does not already exist, and succeeds safely on later deployments.
The container also runs this initializer at startup as a fallback, so a missing
or skipped Railway pre-deploy command does not cause Traccar to crash.
Traccar creates and migrates all required `tc_*` tables when the application
starts. Do not maintain a separate table-creation script because the schema is
version-specific and owned by Traccar.

The PostgreSQL user referenced by `PGUSER` must have permission to create a
database. If database creation is denied, create `traccar` once through the
PostgreSQL Data tab instead.

## Networking

- TCP Proxy target port: `5001`
- HTTP generated domain target port: `8082`

Use the generated TCP proxy hostname and public port in the tracker's
`adminip` SMS command. Add the tracker IMEI in the Traccar dashboard, then assign
the same IMEI to the Carribu vehicle through `trackerUniqueId`.

## Google cell-tower positioning (LBS)

GPS provides satellite coordinates; GPRS transports the tracker's data. When
GPS is unavailable, Traccar can obtain an approximate position from cell-tower
identifiers using Google's Geolocation API. This is disabled by default.
It cannot locate a tracker that sends only heartbeat messages or no usable
cell-tower information.

### Enable in Railway

In Google Cloud, enable **Geolocation API** on a billing-enabled project.
A Maps JavaScript, Geocoding, or Traccar website key alone is not sufficient.
Keep the key server-side and restrict it to Geolocation API. Configure an
appropriate request quota and monitor usage; these lookups can incur charges.

Set these variables on the **Traccar service**, not on the Carribu backend:

```properties
GEOLOCATION_ENABLE=true
GEOLOCATION_KEY=<Google Geolocation API key stored as a Railway secret>
GEOLOCATION_MCC=<SIM network mobile country code>
GEOLOCATION_MNC=<SIM network mobile network code>
```

Replace all placeholders before deployment. Do not commit the key or paste it
into logs, screenshots, or support messages. MCC/MNC identify the mobile
network, not the tracker's phone number, country calling code, or APN.
Confirm them with the SIM carrier. If roaming, the codes must match the
reported cell tower's serving network.

Some GPS103 packets provide only LAC and cell ID, so Traccar uses the configured
MCC/MNC to complete those records. This deployment therefore requires both
codes when enabling LBS; it does not guess the carrier. This is a global
fallback for the server, not a per-device setting. Do not use one pair for
trackers on different networks if their packets omit MCC/MNC.

The startup script rejects an enabled configuration with no key or malformed
carrier codes before contacting the database. Redeploy after setting the
variables. The XML configuration selects Google, processes invalid GPS fixes,
and reuses the last resolved location when the reported network is unchanged.
Valid GPS fixes still take precedence. Set `GEOLOCATION_ENABLE=false` to disable
LBS without changing tracker DNS, APN, or TCP proxy settings.

### Check actual tracker data

1. Inspect the device's latest position using the Traccar API or dashboard
   network details. Look for `network.cellTowers` with usable
   `mobileCountryCode`, `mobileNetworkCode`, `locationAreaCode`, and `cellId`.
   Online/GPRS ON does not prove this information is being transmitted.
2. If there is no cell-tower data, inspect the incoming GPS103 messages in
   Railway's Traccar logs and compare them with the tracker manual. Google
   cannot supply a device location from an identifier or heartbeat alone.
   Share only redacted excerpts when diagnosing decoding issues.
3. After a new packet without a GPS fix, check for a position with `valid: true`,
   `attributes.approximate: true`, and an `accuracy` radius in meters. Do not
   deliberately obscure the tracker antenna; an existing no-fix packet can be
   used to check the fallback.
4. If no location is resolved, check for `Geolocation network error` in Railway
   logs. Verify API enablement, billing, key restrictions, quota, serving-network
   codes, and whether Google has coverage for the reported cell.

Successful LBS results are valid Traccar positions and the current Carribu
ingestion accepts them during an active trip. Carribu currently does not
persist the Traccar accuracy/approximate fields, so its coordinates and
existing ETA/proximity alerts must not be treated as GPS-precision evidence.
LBS coverage and accuracy depend on cell-tower data; this is not guaranteed to
match BAANOOL's positioning service. Enabling configuration alone does not
verify the deployed tracker-to-provider path.

References:

- [Traccar LBS geolocation](https://www.traccar.org/lbs-geolocation/)
- [Traccar configuration](https://www.traccar.org/configuration-file/)
- [Google Geolocation API setup](https://developers.google.com/maps/documentation/geolocation/get-api-key)

## Local validation

Run the startup-preflight checks without a database, container, or Google call:

```sh
node --test tests/startup.test.cjs
```

The checks require a POSIX shell. On Windows they use Git Bash at its standard
installation path; set `BASH_PATH` to override the executable.

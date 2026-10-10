# Carribu Traccar service

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

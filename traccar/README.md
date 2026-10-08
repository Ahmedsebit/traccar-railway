# Carribu Traccar service

Deploy this directory as a separate Railway service with **Root Directory**
set to `/traccar`.

## Railway variables

Replace `Postgres` and `backend` if your Railway services use different names:

```properties
CONFIG_USE_ENVIRONMENT_VARIABLES=true
DATABASE_URL=jdbc:postgresql://${{Postgres.PGHOST}}:${{Postgres.PGPORT}}/traccar
DATABASE_USER=${{Postgres.PGUSER}}
DATABASE_PASSWORD=${{Postgres.PGPASSWORD}}
FORWARD_URL=http://${{backend.RAILWAY_PRIVATE_DOMAIN}}:5000/tracker/position
EVENT_FORWARD_URL=http://${{backend.RAILWAY_PRIVATE_DOMAIN}}:5000/tracker/event
FORWARD_HEADER=Authorization: Bearer ${{backend.TRACKER_WEBHOOK_TOKEN}}
EVENT_FORWARD_HEADER=Authorization: Bearer ${{backend.TRACKER_WEBHOOK_TOKEN}}
```

The backend service must define a long random `TRACKER_WEBHOOK_TOKEN`. No secret
is stored in this repository.

Create a separate PostgreSQL database before deploying:

```sql
CREATE DATABASE traccar;
```

## Networking

- TCP Proxy target port: `5001`
- HTTP generated domain target port: `8082`

Use the generated TCP proxy hostname and public port in the tracker's
`adminip` SMS command. Add the tracker IMEI in the Traccar dashboard, then assign
the same IMEI to the Carribu vehicle through `trackerUniqueId`.

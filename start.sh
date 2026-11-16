#!/bin/sh
set -eu

DATABASE_NAME="${TRACCAR_DATABASE_NAME:-traccar}"

for variable in PGHOST PGPORT PGUSER PGPASSWORD; do
  eval "value=\${$variable:-}"
  if [ -z "$value" ]; then
    echo "$variable is required to start Traccar." >&2
    exit 1
  fi
done

case "${GEOLOCATION_ENABLE:-false}" in
  false) ;;
  true)
    case "${GEOLOCATION_KEY:-}" in
      *[![:space:]]*) ;;
      *)
        echo "GEOLOCATION_KEY is required when GEOLOCATION_ENABLE=true." >&2
        exit 1
        ;;
    esac
    case "${GEOLOCATION_MCC:-}" in
      [1-9][0-9][0-9]) ;;
      *)
        echo "GEOLOCATION_MCC must be the tracker's three-digit mobile country code." >&2
        exit 1
        ;;
    esac
    case "${GEOLOCATION_MNC:-}" in
      [0-9]|[0-9][0-9]|[0-9][0-9][0-9]) ;;
      *)
        echo "GEOLOCATION_MNC must be the tracker's one-to-three-digit mobile network code." >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "GEOLOCATION_ENABLE must be true or false." >&2
    exit 1
    ;;
esac

/opt/traccar/init-db.sh

export CONFIG_USE_ENVIRONMENT_VARIABLES=true
export DATABASE_URL="jdbc:postgresql://${PGHOST}:${PGPORT}/${DATABASE_NAME}"
export DATABASE_USER="$PGUSER"
export DATABASE_PASSWORD="$PGPASSWORD"

attempt=1
max_attempts=30
until pg_isready \
  --host="$PGHOST" \
  --port="$PGPORT" \
  --username="$PGUSER" \
  --dbname="$DATABASE_NAME" \
  --quiet; do
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "PostgreSQL did not become available after $max_attempts attempts." >&2
    exit 1
  fi

  echo "Waiting for PostgreSQL ($attempt/$max_attempts)..."
  attempt=$((attempt + 1))
  sleep 2
done

echo "PostgreSQL is available. Starting Traccar."

exec /opt/traccar/jre/bin/java \
  -XX:+ExitOnOutOfMemoryError \
  -Xms256m \
  -Xmx512m \
  -jar /opt/traccar/tracker-server.jar \
  /opt/traccar/conf/traccar.xml

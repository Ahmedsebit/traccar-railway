#!/bin/sh
set -eu

DATABASE_NAME="${TRACCAR_DATABASE_NAME:-traccar}"
MAINTENANCE_DATABASE="${PGMAINTENANCE_DB:-postgres}"

case "$DATABASE_NAME" in
  *[!A-Za-z0-9_-]*|'')
    echo "TRACCAR_DATABASE_NAME may contain only letters, numbers, underscores, and hyphens." >&2
    exit 1
    ;;
esac

for variable in PGHOST PGPORT PGUSER PGPASSWORD; do
  eval "value=\${$variable:-}"
  if [ -z "$value" ]; then
    echo "$variable is required to initialize the Traccar database." >&2
    exit 1
  fi
done

export PGPASSWORD

if psql \
  --host="$PGHOST" \
  --port="$PGPORT" \
  --username="$PGUSER" \
  --dbname="$MAINTENANCE_DATABASE" \
  --no-password \
  --tuples-only \
  --no-align \
  --command='SELECT datname FROM pg_database;' \
  | grep -Fqx "$DATABASE_NAME"; then
  echo "Database '$DATABASE_NAME' already exists."
  exit 0
fi

createdb \
  --host="$PGHOST" \
  --port="$PGPORT" \
  --username="$PGUSER" \
  --maintenance-db="$MAINTENANCE_DATABASE" \
  --no-password \
  "$DATABASE_NAME"

echo "Database '$DATABASE_NAME' created. Traccar will create and migrate its tables on startup."

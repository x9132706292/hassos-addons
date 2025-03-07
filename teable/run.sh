#!/usr/bin/env bash
set -e

CONFIG_PATH=/data/options.json

DATABASE_URL=$(jq --raw-output '.database_url // empty' $CONFIG_PATH)
PUBLIC_ORIGIN=$(jq --raw-output '.public_origin // empty' $CONFIG_PATH)

if [ -z $DATABASE_URL ]; then
  echo "Error: DATABASE_URL is not set. Please configure it in the addon options."
  exit 1
fi

if [ -z  $PUBLIC_ORIGIN ]; then
  echo "Error: PUBLIC_ORIGIN is not set. Please configure it in the addon options (e.g., http://your-ha-ip:3002)."
  exit 1
fi

echo "DATABASE_URL: $DATABASE_URL"
echo "PUBLIC_ORIGIN: $PUBLIC_ORIGIN"

until psql $DATABASE_URL -c '\q'; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "Starting Teable Community Edition..."
exec node dist/main.js

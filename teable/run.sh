#!/usr/bin/env bash
set -e

if [ -z $(bashio::config 'database_url') ]; then
  echo "Error: DATABASE_URL is not set. Please configure it in the addon options."
  exit 1
fi

if [ -z  $(bashio::config 'public_origin') ]; then
  echo "Error: PUBLIC_ORIGIN is not set. Please configure it in the addon options (e.g., http://your-ha-ip:3002)."
  exit 1
fi

echo "DATABASE_URL: $(bashio::config 'database_url')"
echo "PUBLIC_ORIGIN: $(bashio::config 'public_origin')"

until psql $(bashio::config 'database_url') -c '\q'; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "Starting Teable Community Edition..."
exec node dist/main.js

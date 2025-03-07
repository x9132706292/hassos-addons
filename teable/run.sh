#!/usr/bin/env bash
set -e

# Проверяем оба возможных пути
if [ -f "/data/options.yaml" ]; then
  CONFIG_PATH=/data/options.yaml
elif [ -f "/data/options.json" ]; then
  CONFIG_PATH=/data/options.json
else
  echo "Error: No config file found at /data/options.yaml or /data/options.json."
  ls -la /data 2>/dev/null || echo "Directory /data not mounted."
  exit 1
fi

# Извлекаем значения с помощью jq
DATABASE_URL=$(jq --raw-output '.database_url // empty' "$CONFIG_PATH")
PUBLIC_ORIGIN=$(jq --raw-output '.public_origin // empty' "$CONFIG_PATH")

# Проверка DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL is not set in $CONFIG_PATH."
  exit 1
fi

# Проверка PUBLIC_ORIGIN
if [ -z "$PUBLIC_ORIGIN" ]; then
  echo "Error: PUBLIC_ORIGIN is not set in $CONFIG_PATH (e.g., http://your-ha-ip:3002)."
  exit 1
fi

echo "DATABASE_URL: $DATABASE_URL"
echo "PUBLIC_ORIGIN: $PUBLIC_ORIGIN"

# Проверка доступности PostgreSQL
echo "Testing PostgreSQL connection..."
until psql "$DATABASE_URL" -c '\q' 2>/dev/null; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready!"
echo "Starting Teable Community Edition..."
export DATABASE_URL
export PUBLIC_ORIGIN

#!/usr/bin/env bash
set -e

CONFIG_PATH=/data/options.json

# Извлекаем переменные
PRISMA_DATABASE_URL=$(jq --raw-output '.prisma_database_url // empty' "$CONFIG_PATH")
PUBLIC_ORIGIN=$(jq --raw-output '.public_origin // empty' "$CONFIG_PATH")

if [ -z "$PRISMA_DATABASE_URL" ]; then
    echo "Error: PRISMA_DATABASE_URL is not set in $CONFIG_PATH."
    exit 1
fi

if [ -z "$PUBLIC_ORIGIN" ]; then
    echo "Error: PUBLIC_ORIGIN is not set in $CONFIG_PATH (e.g., http://your-ha-ip:3002)."
    exit 1
fi

echo "PRISMA_DATABASE_URL: $PRISMA_DATABASE_URL"
echo "PUBLIC_ORIGIN: $PUBLIC_ORIGIN"

# Ожидаем доступности PostgreSQL
echo "Testing PostgreSQL connection..."
until psql "$PRISMA_DATABASE_URL" -c '\q' 2>/dev/null; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done
echo "PostgreSQL is ready!"

# Запускаем Teable
echo "Starting Teable Community Edition..."

export PRISMA_DATABASE_URL
export PUBLIC_ORIGIN
export NODE_ENV=production
export PORT=3000

echo "Environment variables before launch:"
env | grep -E "PRISMA_DATABASE_URL|PUBLIC_ORIGIN|NODE_ENV|PORT"

exec node /app/apps/nestjs-backend/dist/index.js

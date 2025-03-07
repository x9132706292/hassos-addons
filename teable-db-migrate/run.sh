#!/usr/bin/env bash
set -e

# Проверяем наличие конфигурационного файла
if [ -f "/data/options.yaml" ]; then
    CONFIG_PATH=/data/options.yaml
elif [ -f "/data/options.json" ]; then
    CONFIG_PATH=/data/options.json
else
    echo "Error: No config file found at /data/options.yaml or /data/options.json."
    ls -la /data 2>/dev/null || echo "Directory /data not mounted."
    exit 1
fi

# Извлекаем PRISMA_DATABASE_URL
PRISMA_DATABASE_URL=$(jq --raw-output '.prisma_database_url // empty' "$CONFIG_PATH")

if [ -z "$PRISMA_DATABASE_URL" ]; then
    echo "Error: PRISMA_DATABASE_URL is not set in $CONFIG_PATH."
    exit 1
fi

echo "PRISMA_DATABASE_URL: $PRISMA_DATABASE_URL"

# Ожидаем доступности PostgreSQL
echo "Testing PostgreSQL connection..."
until psql "$PRISMA_DATABASE_URL" -c '\q' 2>/dev/null; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done
echo "PostgreSQL is ready!"

# Выполняем миграции через db-migrate.mjs
echo "Applying database migrations..."
export PRISMA_DATABASE_URL
node /prisma/scripts/db-migrate.mjs

if [ $? -eq 0 ]; then
    echo "Database migrations applied successfully!"
else
    echo "Error: Failed to apply database migrations."
    exit 1
fi

echo "Migration process completed."

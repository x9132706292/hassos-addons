#!/usr/bin/env bash
set -e

CONFIG_PATH=/data/options.json

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

# Экспортируем переменные
export DATABASE_URL
export PUBLIC_ORIGIN

# Отладка: проверяем переменные
echo "Environment variables before launch:"
env | grep -E "DATABASE_URL|PUBLIC_ORIGIN"

# Предполагаем, что Teable запускается через Next.js
# Пробуем запустить приложение
if [ -f "/app/apps/nestjs-backend/dist/index.js" ]; then
  exec node /app/apps/nestjs-backend/dist/index.js
else
  echo "Error: Cannot find main application file. Please check image structure."
  exit 1
fi

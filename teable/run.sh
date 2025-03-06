#!/usr/bin/env bash
set -e

# Проверка DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL is not set. Please configure it in the addon options."
  exit 1
fi

# Проверка PUBLIC_ORIGIN
if [ -z "$PUBLIC_ORIGIN" ]; then
  echo "Error: PUBLIC_ORIGIN is not set. Please configure it in the addon options (e.g., http://your-ha-ip:3000)."
  exit 1
fi

# Ожидание PostgreSQL
until psql "$DATABASE_URL" -c '\q'; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "Starting Teable Community Edition..."
# Предполагаем, что образ сам запускает приложение
# Если требуется конкретная команда, укажите её здесь, например:
# exec node dist/main.js

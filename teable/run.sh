#!/usr/bin/env bash
set -e

# Проверка переменной DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
  echo "Error: DATABASE_URL is not set. Please configure it in the addon options."
  exit 1
fi

# Проверка доступности PostgreSQL
until psql "$DATABASE_URL" -c '\q'; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

# Запуск Teable
echo "Starting Teable Community Edition..."
teable serve --port 3000

#!/bin/bash

# Читаем настройки из /data/options.json
ADMIN_USER=$(jq -r '.admin_user' /data/options.json)
ADMIN_PASSWORD=$(jq -r '.admin_password' /data/options.json)
DB_HOST=$(jq -r '.db_host' /data/options.json)
DB_NAME=$(jq -r '.db_name' /data/options.json)
DB_USER=$(jq -r '.db_user' /data/options.json)
DB_PASSWORD=$(jq -r '.db_password' /data/options.json)

# Проверяем, что обязательные параметры заданы
if [ -z "$ADMIN_PASSWORD" ] || [ -z "$DB_PASSWORD" ]; then
  echo "[ERROR] Admin password or database password is not set. Please configure them in the add-on options." >&2
  exit 1
fi

# Устанавливаем переменные окружения для Nextcloud
export NEXTCLOUD_ADMIN_USER="$ADMIN_USER"
export NEXTCLOUD_ADMIN_PASSWORD="$ADMIN_PASSWORD"
export NEXTCLOUD_DATA_DIR="/share/nextcloud"
export NEXTCLOUD_TRUSTED_DOMAINS="localhost $(hostname -i):8080"

# Отладочный вывод
echo "[DEBUG] NEXTCLOUD_ADMIN_USER=$NEXTCLOUD_ADMIN_USER"
echo "[DEBUG] NEXTCLOUD_ADMIN_PASSWORD=$NEXTCLOUD_ADMIN_PASSWORD" >&2
echo "[DEBUG] NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
echo "[DEBUG] NEXTCLOUD_TRUSTED_DOMAINS=$NEXTCLOUD_TRUSTED_DOMAINS" >&2
echo "[DEBUG] DB_HOST=$DB_HOST"
echo "[DEBUG] DB_NAME=$DB_NAME" >&2
echo "[DEBUG] DB_USER=$DB_USER"
echo "[DEBUG] DB_PASSWORD=$DB_PASSWORD" >&2

# Проверяем, новая ли это установка
if [ ! -f "$NEXTCLOUD_DATA_DIR/config/config.php" ]; then
  echo "[INFO] Performing automated installation with PostgreSQL..."

  # Ищем occ в контейнере
  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    echo "[ERROR] occ file not found anywhere in the container" >&2
    exit 1
  fi
  echo "[DEBUG] Found occ at: $OCC_PATH"

  # Устанавливаем рабочую директорию на основе пути к occ
  OCC_DIR=$(dirname "$OCC_PATH")
  cd "$OCC_DIR" || exit 1

  # Запускаем установку
  php occ maintenance:install \
    --admin-user="$NEXTCLOUD_ADMIN_USER" \
    --admin-pass="$NEXTCLOUD_ADMIN_PASSWORD" \
    --data-dir="$NEXTCLOUD_DATA_DIR" \
    --database="pgsql" \
    --database-host="$DB_HOST" \
    --database-name="$DB_NAME" \
    --database-user="$DB_USER" \
    --database-pass="$DB_PASSWORD" 2>&1
  if [ $? -eq 0 ]; then
    echo "[INFO] Installation completed successfully."
  else
    echo "[ERROR] Installation failed. Check logs for details." >&2
    exit 1
  fi
else
  echo "[INFO] Nextcloud already installed, skipping automated setup."
fi

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

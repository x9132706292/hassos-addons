#!/bin/bash

# Читаем настройки из /data/options.json
ADMIN_USER=$(jq -r '.admin_user' /data/options.json)
ADMIN_PASSWORD=$(jq -r '.admin_password' /data/options.json)

# Проверяем, что пароль задан
if [ -z "$ADMIN_PASSWORD" ]; then
  echo "[ERROR] Admin password is not set. Please configure it in the add-on options." >&2
  exit 1
fi

# Устанавливаем переменные окружения для Nextcloud
export NEXTCLOUD_ADMIN_USER="$ADMIN_USER"
export NEXTCLOUD_ADMIN_PASSWORD="$ADMIN_PASSWORD"
export NEXTCLOUD_DATA_DIR="/share/nextcloud"
export NEXTCLOUD_TRUSTED_DOMAINS="localhost $(hostname -i):8080"
export NEXTCLOUD_DB_TYPE="sqlite"  # Тип базы данных

# Отладочный вывод
echo "[DEBUG] NEXTCLOUD_ADMIN_USER=$NEXTCLOUD_ADMIN_USER"
echo "[DEBUG] NEXTCLOUD_ADMIN_PASSWORD=$NEXTCLOUD_ADMIN_PASSWORD" >&2
echo "[DEBUG] NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
echo "[DEBUG] NEXTCLOUD_TRUSTED_DOMAINS=$NEXTCLOUD_TRUSTED_DOMAINS" >&2
echo "[DEBUG] NEXTCLOUD_DB_TYPE=$NEXTCLOUD_DB_TYPE"

# Убеждаемся, что данные очищены перед запуском (для теста)
[ -d "$NEXTCLOUD_DATA_DIR" ] && rm -rf "$NEXTCLOUD_DATA_DIR/*"

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

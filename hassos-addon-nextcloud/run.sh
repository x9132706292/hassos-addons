#!/bin/bash

CONFIG_PATH=/data/options.json

# Читаем настройки из /data/options.json
ADMIN_USER=$(jq -r '.admin_user' "$CONFIG_PATH")
ADMIN_PASSWORD=$(jq -r '.admin_password' "$CONFIG_PATH")

# Проверяем, что пароль задан
if [ -z "$ADMIN_PASSWORD" ]; then
  echo "[ERROR] Admin password is not set. Please configure it in the add-on options."
  exit 1
fi

# Устанавливаем переменные окружения для Nextcloud
export NEXTCLOUD_ADMIN_USER="$ADMIN_USER"
export NEXTCLOUD_ADMIN_PASSWORD="$ADMIN_PASSWORD"
export NEXTCLOUD_DATA_DIR="/share/nextcloud"
export NEXTCLOUD_TRUSTED_DOMAINS="localhost $(hostname -i):8080"

# Логируем запуск
echo "[INFO] Starting Nextcloud with admin user: $ADMIN_USER"

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

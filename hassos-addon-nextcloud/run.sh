#!/bin/bash

# Читаем настройки из /data/options.json (оставим только для доверенных доменов и данных)
ADMIN_USER=$(jq -r '.admin_user' /data/options.json)
ADMIN_PASSWORD=$(jq -r '.admin_password' /data/options.json)
DB_HOST=$(jq -r '.db_host' /data/options.json)
DB_NAME=$(jq -r '.db_name' /data/options.json)
DB_USER=$(jq -r '.db_user' /data/options.json)
DB_PASSWORD=$(jq -r '.db_password' /data/options.json)

# Устанавливаем переменные окружения для Nextcloud
export NEXTCLOUD_DATA_DIR="/share/nextcloud"
export NEXTCLOUD_TRUSTED_DOMAINS="localhost $(hostname -i):8080"

# Отладочный вывод
echo "[DEBUG] NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
echo "[DEBUG] NEXTCLOUD_TRUSTED_DOMAINS=$NEXTCLOUD_TRUSTED_DOMAINS" >&2
echo "[DEBUG] DB_HOST=$DB_HOST"
echo "[DEBUG] DB_NAME=$DB_NAME" >&2
echo "[DEBUG] DB_USER=$DB_USER"
echo "[DEBUG] DB_PASSWORD=$DB_PASSWORD" >&2

# Исправляем права на NEXTCLOUD_DATA_DIR
echo "[INFO] Fixing permissions for $NEXTCLOUD_DATA_DIR..."
chown -R www-data:www-data "$NEXTCLOUD_DATA_DIR"
chmod -R 770 "$NEXTCLOUD_DATA_DIR"

# Проверяем, существует ли конфигурация
if [ ! -f "$NEXTCLOUD_DATA_DIR/config/config.php" ]; then
  echo "[INFO] No config found. Please complete the setup via the web interface at http://<ip>:8080"
else
  echo "[INFO] Nextcloud config found, starting the instance."
fi

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

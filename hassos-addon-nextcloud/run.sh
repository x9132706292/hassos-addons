#!/bin/bash

# Читаем настройки из /data/options.json
TRUSTED_DOMAINS=$(jq -r '.trusted_domains' /data/options.json)
ADMIN_USER=$(jq -r '.admin_user // "admin"' /data/options.json)
ADMIN_PASSWORD=$(jq -r '.admin_password // "nextcloud"' /data/options.json)
DB_HOST="77b2833f-timescaledb:5432"
DB_NAME="nextcloud"
DB_USER="nextcloud"
DB_PASSWORD="your_secure_password"  # Замени на свой пароль

# Устанавливаем путь к данным
DATA_DIR="/share/nextcloud"
export NEXTCLOUD_DATA_DIR="$DATA_DIR"

# Отладочный вывод
echo "[DEBUG] DATA_DIR=$DATA_DIR"
echo "[DEBUG] NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
echo "[DEBUG] TRUSTED_DOMAINS=$TRUSTED_DOMAINS $(hostname -i):8080" >&2
echo "[DEBUG] ADMIN_USER=$ADMIN_USER" >&2
echo "[DEBUG] DB_HOST=$DB_HOST" >&2

# Проверяем текущие права
echo "[INFO] Checking current permissions for $DATA_DIR..."
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

# Исправляем права
echo "[INFO] Fixing permissions for $DATA_DIR..."
chown -R www-data:www-data "$DATA_DIR" || echo "[WARNING] Failed to change ownership" >&2
chmod -R 770 "$DATA_DIR" || echo "[WARNING] Failed to change permissions" >&2

# Проверяем права после исправления
echo "[INFO] Permissions after fix:"
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

# Проверяем наличие конфигурации
CONFIG_FILE="$DATA_DIR/config/config.php"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[INFO] No config found at $CONFIG_FILE. Starting automated installation..."

  # Ищем occ
  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    echo "[ERROR] occ file not found" >&2
    exit 1
  fi
  echo "[DEBUG] Found occ at: $OCC_PATH"

  cd "$(dirname "$OCC_PATH")" || exit 1

  # Автоматическая установка
  php occ maintenance:install \
    --admin-user="$ADMIN_USER" \
    --admin-pass="$ADMIN_PASSWORD" \
    --data-dir="$DATA_DIR" \
    --database="pgsql" \
    --database-host="$DB_HOST" \
    --database-name="$DB_NAME" \
    --database-user="$DB_USER" \
    --database-pass="$DB_PASSWORD" >&2
  if [ $? -eq 0 ]; then
    echo "[INFO] Automated installation completed successfully."
  else
    echo "[ERROR] Automated installation failed." >&2
    exit 1
  fi

  # Обновляем trusted_domains
  php occ config:system:set trusted_domains 0 --value="localhost"
  php occ config:system:set trusted_domains 1 --value="$(hostname -i):8080"
else
  echo "[INFO] Config found at $CONFIG_FILE, checking contents..."
  ls -l "$CONFIG_FILE" >&2
  cat "$CONFIG_FILE" >&2

  # Ищем occ
  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    echo "[ERROR] occ file not found" >&2
    exit 1
  fi
  echo "[DEBUG] Found occ at: $OCC_PATH"

  cd "$(dirname "$OCC_PATH")" || exit 1
  php occ config:system:set trusted_domains 0 --value="localhost"
  php occ config:system:set trusted_domains 1 --value="$(hostname -i):8080"
  php occ status >&2
fi

# Даём время Apache запуститься
echo "[INFO] Starting Nextcloud, waiting for Apache to be ready..."
sleep 10

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

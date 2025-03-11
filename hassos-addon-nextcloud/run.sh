#!/bin/bash

# Читаем настройки из /data/options.json
TRUSTED_DOMAINS=$(jq -r '.trusted_domains' /data/options.json)

# Устанавливаем переменные окружения для Nextcloud
export NEXTCLOUD_DATA_DIR="/share/nextcloud"
export NEXTCLOUD_TRUSTED_DOMAINS="$TRUSTED_DOMAINS $(hostname -i):8080"

# Отладочный вывод
echo "[DEBUG] NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
echo "[DEBUG] NEXTCLOUD_TRUSTED_DOMAINS=$NEXTCLOUD_TRUSTED_DOMAINS" >&2

# Исправляем права на NEXTCLOUD_DATA_DIR
echo "[INFO] Fixing permissions for $NEXTCLOUD_DATA_DIR..."
chown -R www-data:www-data "$NEXTCLOUD_DATA_DIR"
chmod -R 770 "$NEXTCLOUD_DATA_DIR"

# Проверяем, существует ли конфигурация
CONFIG_FILE="$NEXTCLOUD_DATA_DIR/config/config.php"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[INFO] No config found. Please complete the setup via the web interface at http://<ip>:8080 or through Home Assistant Ingress"
else
  echo "[INFO] Nextcloud config found, updating trusted domains if necessary..."

  # Ищем occ в контейнере
  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    echo "[ERROR] occ file not found anywhere in the container" >&2
    exit 1
  fi
  echo "[DEBUG] Found occ at: $OCC_PATH"

  # Устанавливаем рабочую директорию
  OCC_DIR=$(dirname "$OCC_PATH")
  cd "$OCC_DIR" || exit 1

  # Обновляем trusted_domains через occ
  php occ config:system:set trusted_domains 0 --value="localhost"
  php occ config:system:set trusted_domains 1 --value="$(hostname -i):8080"
  if [ -n "$HASSIO_TOKEN" ]; then
    HA_DOMAIN=$(hostname -f)
    php occ config:system:set trusted_domains 2 --value="$HA_DOMAIN"
    echo "[INFO] Added Home Assistant domain ($HA_DOMAIN) to trusted domains for Ingress."
  fi
  if [ $? -eq 0 ]; then
    echo "[INFO] Trusted domains updated successfully."
  else
    echo "[ERROR] Failed to update trusted domains." >&2
  fi
fi

# Даём время Apache запуститься перед ответом Ingress
echo "[INFO] Starting Nextcloud, waiting for Apache to be ready..."
sleep 10

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

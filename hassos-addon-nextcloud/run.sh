#!/bin/bash

# Читаем настройки из /data/options.json
TRUSTED_DOMAINS=$(jq -r '.trusted_domains | join(" ")' /data/options.json)
ADMIN_USER=$(jq -r '.admin_user // "admin"' /data/options.json)
ADMIN_PASSWORD=$(jq -r '.admin_password // "nextcloud"' /data/options.json)
DB_TYPE=$(jq -r '.db_type // "pgsql"' /data/options.json)
DB_HOST=$(jq -r '.db_host // "77b2833f-timescaledb"' /data/options.json)
DB_PORT=$(jq -r '.db_port // "5432"' /data/options.json)
DB_NAME=$(jq -r '.db_name // "nextcloud"' /data/options.json)
DB_USER=$(jq -r '.db_user // "nextcloud"' /data/options.json)
DB_PASSWORD=$(jq -r '.db_password // "your_secure_password"' /data/options.json)
DATA_DIR=$(jq -r '.data_dir // "/share/nextcloud"' /data/options.json)

# Устанавливаем пути
CONFIG_DIR="$DATA_DIR/config"
export NEXTCLOUD_DATA_DIR="$DATA_DIR"
export NEXTCLOUD_CONFIG_DIR="$CONFIG_DIR"

# Отладочный вывод
echo "[DEBUG] DATA_DIR=$DATA_DIR"
echo "[DEBUG] CONFIG_DIR=$CONFIG_DIR"
echo "[DEBUG] NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
echo "[DEBUG] NEXTCLOUD_CONFIG_DIR=$NEXTCLOUD_CONFIG_DIR"
echo "[DEBUG] TRUSTED_DOMAINS=$TRUSTED_DOMAINS $(hostname -i):8080" >&2
echo "[DEBUG] ADMIN_USER=$ADMIN_USER" >&2
echo "[DEBUG] DB_TYPE=$DB_TYPE" >&2
echo "[DEBUG] DB_HOST=$DB_HOST" >&2
echo "[DEBUG] DB_PORT=$DB_PORT" >&2
echo "[DEBUG] DB_NAME=$DB_NAME" >&2
echo "[DEBUG] DB_USER=$DB_USER" >&2

# Проверяем и создаём директорию данных
if [ ! -d "$DATA_DIR" ]; then
  echo "[INFO] Creating data directory $DATA_DIR..."
  mkdir -p "$DATA_DIR"
  chown www-data:www-data "$DATA_DIR"
  chmod 770 "$DATA_DIR"
fi

# Проверяем текущие права
echo "[INFO] Checking current permissions for $DATA_DIR..."
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

# Исправляем права
echo "[INFO] Fixing permissions for $DATA_DIR..."
chown -R www-data:www-data "$DATA_DIR" || echo "[WARNING] Failed to change ownership" >&2
chmod -R 770 "$DATA_DIR" || echo "[WARNING] Failed to change permissions" >&2

# Создаём директорию config
mkdir -p "$CONFIG_DIR"
chown www-data:www-data "$CONFIG_DIR"
chmod 770 "$CONFIG_DIR"

# Проверяем права после исправления
echo "[INFO] Permissions after fix:"
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

# Проверяем наличие конфигурации
CONFIG_FILE="$CONFIG_DIR/config.php"
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

  # Проверяем подключение к базе (только для pgsql и mysql)
  if [ "$DB_TYPE" = "pgsql" ] || [ "$DB_TYPE" = "mysql" ]; then
    echo "[INFO] Testing database connection..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "[INFO] Database connection successful."
    else
      echo "[ERROR] Failed to connect to database. Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, or database availability." >&2
      exit 1
    fi
  fi

  # Проверяем права на /var/www/html
  echo "[DEBUG] Checking permissions for /var/www/html..." >&2
  ls -ld /var/www/html >&2

  # Временная директория для config.php
  TEMP_CONFIG_DIR="/var/www/html/config"
  echo "[DEBUG] Preparing temporary config directory: $TEMP_CONFIG_DIR" >&2
  mkdir -p "$TEMP_CONFIG_DIR"
  chown www-data:www-data "$TEMP_CONFIG_DIR"
  chmod 770 "$TEMP_CONFIG_DIR"
  echo "[DEBUG] Permissions for $TEMP_CONFIG_DIR:" >&2
  ls -ld "$TEMP_CONFIG_DIR" >&2

  # Тест записи от www-data
  echo "[DEBUG] Testing write access to $TEMP_CONFIG_DIR as www-data..." >&2
  sudo -u www-data touch "$TEMP_CONFIG_DIR/testfile" 2>&1
  if [ $? -eq 0 ]; then
    echo "[INFO] Write test successful, removing testfile..." >&2
    rm "$TEMP_CONFIG_DIR/testfile"
  else
    echo "[ERROR] Cannot write to $TEMP_CONFIG_DIR as www-data" >&2
    exit 1
  fi

  # Автоматическая установка с отладкой
  echo "[DEBUG] Running installation command as www-data..." >&2
  sudo -u www-data php occ maintenance:install \
    --admin-user="$ADMIN_USER" \
    --admin-pass="$ADMIN_PASSWORD" \
    --data-dir="$DATA_DIR" \
    --database="$DB_TYPE" \
    --database-host="$DB_HOST" \
    --database-port="$DB_PORT" \
    --database-name="$DB_NAME" \
    --database-user="$DB_USER" \
    --database-pass="$DB_PASSWORD" >&2
  if [ $? -eq 0 ]; then
    echo "[INFO] Automated installation completed successfully."
    echo "[DEBUG] Checking for config.php in $TEMP_CONFIG_DIR..." >&2
    ls -l "$TEMP_CONFIG_DIR" >&2
    if [ -f "$TEMP_CONFIG_DIR/config.php" ]; then
      mv "$TEMP_CONFIG_DIR/config.php" "$CONFIG_FILE"
      chown www-data:www-data "$CONFIG_FILE"
      chmod 660 "$CONFIG_FILE"
      echo "[INFO] Moved config.php to $CONFIG_FILE"
    else
      echo "[ERROR] config.php not found in $TEMP_CONFIG_DIR after installation" >&2
      echo "[DEBUG] Checking entire /var/www/html for config.php..." >&2
      find /var/www/html -name config.php >&2
      exit 1
    fi
    ls -l "$CONFIG_DIR" >&2
  else
    echo "[ERROR] Automated installation failed." >&2
    exit 1
  fi

  # Обновляем trusted_domains
  IFS=' ' read -r -a TRUSTED_ARRAY <<< "$TRUSTED_DOMAINS"
  for i in "${!TRUSTED_ARRAY[@]}"; do
    sudo -u www-data php occ config:system:set trusted_domains "$i" --value="${TRUSTED_ARRAY[$i]}"
  done
  sudo -u www-data php occ config:system:set trusted_domains "${#TRUSTED_ARRAY[@]}" --value="$(hostname -i):8080"
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
  IFS=' ' read -r -a TRUSTED_ARRAY <<< "$TRUSTED_DOMAINS"
  for i in "${!TRUSTED_ARRAY[@]}"; do
    sudo -u www-data php occ config:system:set trusted_domains "$i" --value="${TRUSTED_ARRAY[$i]}"
  done
  sudo -u www-data php occ config:system:set trusted_domains "${#TRUSTED_ARRAY[@]}" --value="$(hostname -i):8080"
  sudo -u www-data php occ status >&2
fi

# Даём время Apache запуститься
echo "[INFO] Starting Nextcloud, waiting for Apache to be ready..."
sleep 10

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

#!/bin/bash

echo "------------------------" >&2

# Функция для форматированного вывода в лог
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$level] $timestamp" >&2
  echo "$message" >&2
}

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
log "DEBUG" "DATA_DIR=$DATA_DIR"
log "DEBUG" "CONFIG_DIR=$CONFIG_DIR"
log "DEBUG" "NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
log "DEBUG" "NEXTCLOUD_CONFIG_DIR=$NEXTCLOUD_CONFIG_DIR"
log "DEBUG" "TRUSTED_DOMAINS=$TRUSTED_DOMAINS $(hostname -i):8080"
log "DEBUG" "ADMIN_USER=$ADMIN_USER"
log "DEBUG" "DB_TYPE=$DB_TYPE"
log "DEBUG" "DB_HOST=$DB_HOST"
log "DEBUG" "DB_PORT=$DB_PORT"
log "DEBUG" "DB_NAME=$DB_NAME"
log "DEBUG" "DB_USER=$DB_USER"

# Проверяем и создаём директорию данных
if [ ! -d "$DATA_DIR" ]; then
  log "INFO" "Creating data directory $DATA_DIR..."
  mkdir -p "$DATA_DIR"
  chown www-data:www-data "$DATA_DIR"
  chmod 770 "$DATA_DIR"
fi

# Проверяем текущие права
log "INFO" "Checking current permissions for $DATA_DIR..."
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

# Исправляем права
log "INFO" "Fixing permissions for $DATA_DIR..."
chown -R www-data:www-data "$DATA_DIR" || log "WARNING" "Failed to change ownership"
chmod -R 770 "$DATA_DIR" || log "WARNING" "Failed to change permissions"

# Создаём директорию config
mkdir -p "$CONFIG_DIR"
chown www-data:www-data "$CONFIG_DIR"
chmod 770 "$CONFIG_DIR"

# Проверяем права после исправления
log "INFO" "Permissions after fix:"
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

# Проверяем наличие конфигурации
CONFIG_FILE="$CONFIG_DIR/config.php"
if [ ! -f "$CONFIG_FILE" ]; then
  log "INFO" "No config found at $CONFIG_FILE. Starting automated installation..."

  # Ищем occ
  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    log "ERROR" "occ file not found"
    exit 1
  fi
  log "DEBUG" "Found occ at: $OCC_PATH"

  cd "$(dirname "$OCC_PATH")" || exit 1

  # Проверяем подключение к базе (только для pgsql и mysql)
  if [ "$DB_TYPE" = "pgsql" ] || [ "$DB_TYPE" = "mysql" ]; then
    log "INFO" "Testing database connection..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      log "INFO" "Database connection successful."
    else
      log "ERROR" "Failed to connect to database. Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, or database availability."
      exit 1
    fi
  fi

  # Проверяем права на /var/www/html
  log "DEBUG" "Checking permissions for /var/www/html..."
  ls -ld /var/www/html >&2

  # Временная директория для config.php
  TEMP_CONFIG_DIR="/var/www/html/config"
  log "DEBUG" "Preparing temporary config directory: $TEMP_CONFIG_DIR"
  mkdir -p "$TEMP_CONFIG_DIR"
  chown www-data:www-data "$TEMP_CONFIG_DIR"
  chmod 770 "$TEMP_CONFIG_DIR"
  log "DEBUG" "Permissions for $TEMP_CONFIG_DIR:"
  ls -ld "$TEMP_CONFIG_DIR" >&2

  # Тест записи от www-data
  log "DEBUG" "Testing write access to $TEMP_CONFIG_DIR as www-data..."
  sudo -u www-data touch "$TEMP_CONFIG_DIR/testfile" 2>&1
  if [ $? -eq 0 ]; then
    log "INFO" "Write test successful, removing testfile..."
    rm "$TEMP_CONFIG_DIR/testfile"
  else
    log "ERROR" "Cannot write to $TEMP_CONFIG_DIR as www-data"
    exit 1
  fi

  # Автоматическая установка с отладкой
  log "DEBUG" "Running installation command as www-data..."
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
    log "INFO" "Automated installation completed successfully."
    log "DEBUG" "Checking for config.php in $TEMP_CONFIG_DIR..."
    ls -l "$TEMP_CONFIG_DIR" >&2
    if [ -f "$TEMP_CONFIG_DIR/config.php" ]; then
      mv "$TEMP_CONFIG_DIR/config.php" "$CONFIG_FILE"
      chown www-data:www-data "$CONFIG_FILE"
      chmod 660 "$CONFIG_FILE"
      log "INFO" "Moved config.php to $CONFIG_FILE"
    else
      log "ERROR" "config.php not found in $TEMP_CONFIG_DIR after installation"
      log "DEBUG" "Checking entire /var/www/html for config.php..."
      find /var/www/html -name config.php >&2
      exit 1
    fi
    ls -l "$CONFIG_DIR" >&2
  else
    log "ERROR" "Automated installation failed."
    exit 1
  fi

  # Обновляем trusted_domains
  IFS=' ' read -r -a TRUSTED_ARRAY <<< "$TRUSTED_DOMAINS"
  for i in "${!TRUSTED_ARRAY[@]}"; do
    sudo -u www-data php occ config:system:set trusted_domains "$i" --value="${TRUSTED_ARRAY[$i]}"
  done
  sudo -u www-data php occ config:system:set trusted_domains "${#TRUSTED_ARRAY[@]}" --value="$(hostname -i):8080"
else
  log "INFO" "Config found at $CONFIG_FILE, checking contents..."
  ls -l "$CONFIG_FILE" >&2
  cat "$CONFIG_FILE" >&2

  # Ищем occ
  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    log "ERROR" "occ file not found"
    exit 1
  fi
  log "DEBUG" "Found occ at: $OCC_PATH"

  cd "$(dirname "$OCC_PATH")" || exit 1
  IFS=' ' read -r -a TRUSTED_ARRAY <<< "$TRUSTED_DOMAINS"
  for i in "${!TRUSTED_ARRAY[@]}"; do
    sudo -u www-data php occ config:system:set trusted_domains "$i" --value="${TRUSTED_ARRAY[$i]}"
  done
  sudo -u www-data php occ config:system:set trusted_domains "${#TRUSTED_ARRAY[@]}" --value="$(hostname -i):8080"
  sudo -u www-data php occ status >&2
fi

# Даём время Apache запуститься
log "INFO" "Starting Nextcloud, waiting for Apache to be ready..."
sleep 10

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

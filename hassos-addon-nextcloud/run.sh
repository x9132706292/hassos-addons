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

CONFIG_DIR="$DATA_DIR/config"
export NEXTCLOUD_DATA_DIR="$DATA_DIR"
export NEXTCLOUD_CONFIG_DIR="$CONFIG_DIR"

NOW=$(date '+%Y-%m-%d %H:%M:%S')

echo "$NOW [DEBUG] DATA_DIR=$DATA_DIR"
echo "$NOW [DEBUG] CONFIG_DIR=$CONFIG_DIR"
echo "$NOW [DEBUG] NEXTCLOUD_DATA_DIR=$NEXTCLOUD_DATA_DIR"
echo "$NOW [DEBUG] NEXTCLOUD_CONFIG_DIR=$NEXTCLOUD_CONFIG_DIR"
echo "$NOW [DEBUG] TRUSTED_DOMAINS=$TRUSTED_DOMAINS $(hostname -i):8080"
echo "$NOW [DEBUG] ADMIN_USER=$ADMIN_USER"
echo "$NOW [DEBUG] DB_TYPE=$DB_TYPE"
echo "$NOW [DEBUG] DB_HOST=$DB_HOST"
echo "$NOW [DEBUG] DB_PORT=$DB_PORT"
echo "$NOW [DEBUG] DB_NAME=$DB_NAME"
echo "$NOW [DEBUG] DB_USER=$DB_USER"

# Проверяем и создаём директорию данных
if [ ! -d "$DATA_DIR" ]; then
  echo "$NOW [INFO] Creating data directory $DATA_DIR..."
  mkdir -p "$DATA_DIR"
  chown www-data:www-data "$DATA_DIR"
  chmod 770 "$DATA_DIR"
fi

echo "$NOW [INFO] Checking current permissions for $DATA_DIR..."
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

echo "$NOW [INFO] Fixing permissions for $DATA_DIR..."
chown -R www-data:www-data "$DATA_DIR"
chmod -R 770 "$DATA_DIR"

mkdir -p "$CONFIG_DIR"
chown www-data:www-data "$CONFIG_DIR"
chmod 770 "$CONFIG_DIR"

echo "$NOW [INFO] Permissions after fix:"
ls -ld "$DATA_DIR" >&2
ls -l "$DATA_DIR" >&2

CONFIG_FILE="$CONFIG_DIR/config.php"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "$NOW [INFO] No config found at $CONFIG_FILE. Starting automated installation..."

  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    echo "$NOW [ERROR] occ file not found"
    exit 1
  fi
  echo "$NOW [DEBUG] Found occ at: $OCC_PATH"

  cd "$(dirname "$OCC_PATH")" || exit 1

  if [ "$DB_TYPE" = "pgsql" ] || [ "$DB_TYPE" = "mysql" ]; then
    echo "$NOW [INFO] Testing database connection..."
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "$NOW [INFO] Database connection successful."
    else
      echo "$NOW [ERROR] Failed to connect to database. Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, or database availability."
      exit 1
    fi
  fi

  # Проверяем права на /var/www/html
  echo "$NOW [DEBUG] Checking permissions for /var/www/html..."
  ls -ld /var/www/html >&2

  # Проверяем права на /usr/src/nextcloud/apps
  echo "$NOW [DEBUG] Checking permissions for /usr/src/nextcloud/apps..."
  ls -ld /usr/src/nextcloud/apps >&2

  # Исправляем права на apps
  echo "$NOW [INFO] Fixing permissions for /usr/src/nextcloud/apps..."
  chown -R www-data:www-data /usr/src/nextcloud/apps
  chmod -R 770 /usr/src/nextcloud/apps
  echo "$NOW [DEBUG] Permissions for /usr/src/nextcloud/apps after fix:"
  ls -ld /usr/src/nextcloud/apps >&2

  TEMP_CONFIG_DIR="/var/www/html/config"
  echo "$NOW [DEBUG] Preparing temporary config directory: $TEMP_CONFIG_DIR"
  mkdir -p "$TEMP_CONFIG_DIR"
  chown www-data:www-data "$TEMP_CONFIG_DIR"
  chmod 770 "$TEMP_CONFIG_DIR"
  echo "$NOW [DEBUG] Permissions for $TEMP_CONFIG_DIR:"
  ls -ld "$TEMP_CONFIG_DIR" >&2

  # Тест записи в /var/www/html/config
  echo "$NOW [DEBUG] Testing write access to $TEMP_CONFIG_DIR as www-data..."
  sudo -u www-data touch "$TEMP_CONFIG_DIR/testfile" 2>&1
  if [ $? -eq 0 ]; then
    echo "$NOW [INFO] Write test successful, removing testfile..."
    rm "$TEMP_CONFIG_DIR/testfile"
  else
    echo "$NOW [ERROR] Cannot write to $TEMP_CONFIG_DIR as www-data"
    exit 1
  fi

  # Тест записи в /usr/src/nextcloud/apps
  echo "$NOW [DEBUG] Testing write access to /usr/src/nextcloud/apps as www-data..."
  sudo -u www-data touch "/usr/src/nextcloud/apps/testfile" 2>&1
  if [ $? -eq 0 ]; then
    echo "$NOW [INFO] Write test successful in /usr/src/nextcloud/apps, removing testfile..."
    rm "/usr/src/nextcloud/apps/testfile"
  else
    echo "$NOW [ERROR] Cannot write to /usr/src/nextcloud/apps as www-data"
    exit 1
  fi

  # Установка с явным указанием NEXTCLOUD_CONFIG_DIR
  echo "$NOW [DEBUG] Running installation command as www-data with NEXTCLOUD_CONFIG_DIR=$TEMP_CONFIG_DIR..."
  sudo -u www-data NEXTCLOUD_CONFIG_DIR="$TEMP_CONFIG_DIR" php occ maintenance:install \
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
    echo "$NOW [INFO] Automated installation completed successfully."
    echo "$NOW [DEBUG] Checking for config.php in $TEMP_CONFIG_DIR..."
    ls -l "$TEMP_CONFIG_DIR" >&2
    if [ -f "$TEMP_CONFIG_DIR/config.php" ]; then
      mv "$TEMP_CONFIG_DIR/config.php" "$CONFIG_FILE"
      chown www-data:www-data "$CONFIG_FILE"
      chmod 660 "$CONFIG_FILE"
      echo "$NOW [INFO] Moved config.php to $CONFIG_FILE"
    else
      echo "$NOW [ERROR] config.php not found in $TEMP_CONFIG_DIR after installation"
      echo "$NOW [DEBUG] Checking entire /var/www/html for config.php..."
      find /var/www/html -name config.php >&2
      echo "$NOW [DEBUG] Checking /usr/src/nextcloud/config for config.php..."
      ls -l /usr/src/nextcloud/config >&2
      exit 1
    fi
    ls -l "$CONFIG_DIR" >&2
  else
    echo "$NOW [ERROR] Automated installation failed."
    exit 1
  fi

  IFS=' ' read -r -a TRUSTED_ARRAY <<< "$TRUSTED_DOMAINS"
  for i in "${!TRUSTED_ARRAY[@]}"; do
    sudo -u www-data php occ config:system:set trusted_domains "$i" --value="${TRUSTED_ARRAY[$i]}"
  done
  sudo -u www-data php occ config:system:set trusted_domains "${#TRUSTED_ARRAY[@]}" --value="$(hostname -i):8080"
else
  echo "$NOW [INFO] Config found at $CONFIG_FILE, checking contents..."
  ls -l "$CONFIG_FILE" >&2
  cat "$CONFIG_FILE" >&2

  OCC_PATH=$(find / -name occ 2>/dev/null | head -n 1)
  if [ -z "$OCC_PATH" ]; then
    echo "$NOW [ERROR] occ file not found"
    exit 1
  fi
  echo "$NOW [DEBUG] Found occ at: $OCC_PATH"

  cd "$(dirname "$OCC_PATH")" || exit 1
  IFS=' ' read -r -a TRUSTED_ARRAY <<< "$TRUSTED_DOMAINS"
  for i in "${!TRUSTED_ARRAY[@]}"; do
    sudo -u www-data php occ config:system:set trusted_domains "$i" --value="${TRUSTED_ARRAY[$i]}"
  done
  sudo -u www-data php occ config:system:set trusted_domains "${#TRUSTED_ARRAY[@]}" --value="$(hostname -i):8080"
  sudo -u www-data php occ status >&2
fi

echo "$NOW [INFO] Starting Nextcloud, waiting for Apache to be ready..."
sleep 10

exec /entrypoint.sh apache2-foreground

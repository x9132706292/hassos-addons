#!/bin/bash

# Используем bashio для взаимодействия с Home Assistant
source /usr/lib/bashio/bashio.sh

# Читаем настройки из конфигурации Home Assistant
ADMIN_USER=$(bashio::config 'admin_user')
ADMIN_PASSWORD=$(bashio::config 'admin_password')

# Проверяем, что пароль задан
if [ -z "$ADMIN_PASSWORD" ]; then
  bashio::log.error "Admin password is not set. Please configure it in the add-on options."
  exit 1
fi

# Устанавливаем переменные окружения для Nextcloud
export NEXTCLOUD_ADMIN_USER="$ADMIN_USER"
export NEXTCLOUD_ADMIN_PASSWORD="$ADMIN_PASSWORD"
export NEXTCLOUD_DATA_DIR="/share/nextcloud"

# Настройки базы данных (пример для SQLite, можно заменить на MySQL/PostgreSQL)
export NEXTCLOUD_TRUSTED_DOMAINS="localhost <ip-адрес-home-assistant>:8080"

bashio::log.info "Starting Nextcloud with admin user: $ADMIN_USER"

# Запускаем Nextcloud
exec /entrypoint.sh apache2-foreground

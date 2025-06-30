#!/bin/bash
CONFIG_PATH=/data/options.json

# Получение пароля из настроек
PASSWORD=$(jq --raw-output '.REDIS_PASSWORD // empty' $CONFIG_PATH)

# Формирование конфигурации Redis
if [ -n "$PASSWORD" ]; then
  echo "requirepass $PASSWORD" > /etc/redis.conf
else
  echo "" > /etc/redis.conf
fi

# Запуск Redis
exec redis-server /etc/redis.conf


#!/bin/sh
set -e

# 1. Убедимся, что постоянная директория данных Home Assistant существует
mkdir -p /data

# 2. Если файла конфигурации еще нет, копируем стандартный из образа Dashy
if [ ! -f /data/conf.yml ]; then
    cp /app/user-data/conf.yml /data/conf.yml
    chown -R 1000:1000 /data
fi

# 3. Подменяем стандартную папку на символическую ссылку на /data
# Это делается в runtime, чтобы обойти ограничения Docker VOLUME базового образа
rm -rf /app/user-data
ln -s /data /app/user-data

# 4. Запускаем сервер Dashy от имени пользователя node (UID 1000), как в оригинальном образе
exec su-exec node node server.js

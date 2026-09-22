#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

# Читаем tunnels из конфигурации аддона.
# Если значение null, заменяем на пустой список.
TUNNELS_JSON=$(bashio::config 'tunnels' | jq -c 'if . == null then [] else . end')

# Директория для приватных ключей, которые приходят через конфигурацию.
mkdir -p /data/ssh_keys
chmod 700 /data/ssh_keys

bashio::log.info "Запуск SSH Tunnel Manager..."

exec python3 /tunnels_manager.py "$TUNNELS_JSON"

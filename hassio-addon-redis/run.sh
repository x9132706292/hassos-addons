#!/bin/bash
set -e
# ==============================================================================
# Home Assistant Add-on: Redis
# Runs the Redis server
# ==============================================================================

CONFIG_PATH=/data/options.json

export REDIS_PASSWORD=$(jq --raw-output '.password // empty' $CONFIG_PATH)

exec redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}

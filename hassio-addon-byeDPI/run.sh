#!/bin/bash
set -e
# ==============================================================================
# Home Assistant Add-on: Redis
# Runs the Redis server
# ==============================================================================

CONFIG_PATH=/data/options.json

export PORT=$(jq --raw-output '.port // empty' $CONFIG_PATH)

/usr/local/bin/ciadpi-x86_64 -p $PORT

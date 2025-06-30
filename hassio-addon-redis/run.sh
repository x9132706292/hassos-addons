#!/usr/bin/with-contenv bash
# ==============================================================================
# Home Assistant Add-on: Redis
# Runs the Redis server
# ==============================================================================

CONFIG_PATH=/data/options.json
REDIS_CONF=/etc/redis.conf

# Get password from options (if set)
PASSWORD=$(jq --raw-output '.password // empty' $CONFIG_PATH)

# Generate Redis configuration
if [ -n "$PASSWORD" ]; then
  echo "requirepass $PASSWORD" > $REDIS_CONF
else
  echo "" > $REDIS_CONF
fi

# Start Redis server
exec redis-server $REDIS_CONF

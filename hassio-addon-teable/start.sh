#!/bin/bash

CONFIG_PATH=/data/options.json
echo 'Starting with the following configuration:';
jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "\t" + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH;
eval $(jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "export " + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH);

export PRISMA_DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
echo $PRISMA_DATABASE_URL
if (($REDIS=="true")) then
    export BACKEND_CACHE_PROVIDER=redis
    export BACKEND_CACHE_REDIS_URI=redis://default:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB}
    echo $BACKEND_CACHE_REDIS_URI
fi

run_migration() {
    echo "Running database migration..."
    cd /app && node scripts/db-migrate.mjs
    local migration_status=$?
    if [ $migration_status -ne 0 ]; then
        echo "Database migration failed"
        exit 1
    fi
    echo "Database migration completed successfully"
}

check_redis_available() {
    local host="$1" port="$2" password="$3"
    [[ -z "$host" || -z "$port" ]] && return 1

    local cmd="redis-cli -h $host -p $port"
    [[ -n "$password" ]] && cmd="$cmd -a $password --no-auth-warning"

    timeout 2 $cmd ping >/dev/null 2>&1
}

check_and_start_redis() {
    local internal_host="127.0.0.1"
    local port="6379"
    local password="teable"

    if [[ -n "$BACKEND_CACHE_REDIS_URI" ]]; then
        local host=$(echo "$BACKEND_CACHE_REDIS_URI" | cut -d'@' -f2 | cut -d':' -f1)
        echo "Using external Redis... $host"
        return 0
    fi

    echo "Starting internal Redis..."
    mkdir -p /var/log /redis-data
    local redis_cmd="redis-server --port $port --bind "$internal_host" --dir /redis-data --appendonly yes"
    if [[ -n "$password" ]]; then
        redis_cmd="$redis_cmd --requirepass $password"
    fi

    $redis_cmd &

    # Wait for Redis to start with timeout and retries(20 * 0.5s = 10 seconds)
    echo "Waiting for Redis to start..."
    local max_attempts=20
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if check_redis_available "$internal_host" "$port" "$password"; then
            echo "✓ Internal Redis started successfully (took ${attempt} attempts)"
            return 0
        fi

        sleep 0.5
        attempt=$((attempt + 1))
    done

    echo "❌ Failed to start Redis after $max_attempts attempts (10 seconds timeout)"
    exit 1
}

case "$1" in
    "skip-migrate")
        echo "Skipping database migration..."
        ;;
    "migrate-only")
        run_migration
        exit 0
        ;;
    *)
        run_migration
        ;;
esac

check_and_start_redis

should_start_sandbox() {
    if [[ -n "${SANDBOX_URL}" ]]; then
        echo "Using external sandbox service at: ${SANDBOX_URL}"
        return 1
    fi

    return 0
}

start_sandbox() {
    node ./enterprise/sandbox/dist/server.js &
}

start_main_app() {
    node ./enterprise/backend-ee/dist/index.js &
    node ./community/plugins/server.js &
}

if should_start_sandbox; then
    start_sandbox
else
    echo "Skipping integrated sandbox startup"
fi

start_main_app

wait -n

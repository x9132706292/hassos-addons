#!/bin/bash

CONFIG_PATH=/data/options.json
echo 'Starting with the following configuration:';
jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "\t" + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH;
eval $(jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "export " + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH);

export PRISMA_DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
echo $PRISMA_DATABASE_URL
if [$REDIS]; then
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

node ./apps/nestjs-backend/dist/index.js &
node ./plugins/server.js &
wait -n

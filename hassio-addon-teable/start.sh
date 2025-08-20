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

scripts/start.sh

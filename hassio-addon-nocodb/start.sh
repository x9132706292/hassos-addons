#!/bin/sh

CONFIG_PATH=/data/options.json
echo 'Starting with the following configuration:';
jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "\t" + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH;
eval $(jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "export " + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH);

export NC_DB="pg://${POSTGRES_HOST}:${POSTGRES_PORT}?u=${POSTGRES_USER}&p=${POSTGRES_PASSWORD}&d=${POSTGRES_DB}"
echo $NC_DB

if [[ -f /usr/src/appEntry/configure.sh ]]; then
  . /usr/src/appEntry/configure.sh
fi

#sleep 5

if [ ! -z "${NC_TOOL_DIR}"  ]; then
  mkdir -p $NC_TOOL_DIR
fi

# Keep WASM off TurboFan: tiering up the reflection SQL parser needs ~1 GB (V8 "Zone" OOM). NODE_OPTIONS rejects these flags.
node --no-wasm-dynamic-tiering --no-wasm-tier-up docker/index.js

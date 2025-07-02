#!/bin/bash
set -e

CONFIG_PATH=/data/options.json
echo 'Starting with the following configuration:';
jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "\t" + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH;
eval $(jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "export " + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH);

SHARE_DIR=/share/nextcloud
if [ ! -d "${SHARE_DIR}" ]; then
    mkdir -p "${SHARE_DIR}"
    chown -R www-data:root "${SHARE_DIR}"
    chmod -R g=u "${SHARE_DIR}"
fi
if [ ! -d "${SHARE_DIR}/html" ]; then
    mkdir -p "${SHARE_DIR}/html"
    chown -R www-data:root "${SHARE_DIR}/html"
    chmod -R g=u "${SHARE_DIR}/html"
fi

echo 'Starting with the following configuration:';

exec /start.sh

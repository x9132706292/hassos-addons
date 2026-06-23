#!/bin/sh

CONFIG_PATH=/data/options.json
echo 'Starting with the following configuration:';
jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "\t" + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH;
eval $(jq --raw-output 'keys[] as $k | select(.[$k] != "" and .[$k] != null) | "export " + ($k | ascii_upcase) + "=\"" + (.[$k]|tostring) + "\""' $CONFIG_PATH);

# Запускаем оригинальный entrypoint от MeTube
exec /usr/bin/tini -g -- ./docker-entrypoint.sh

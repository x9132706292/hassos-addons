#!/bin/sh
set -eu

mkdir -p /data/ssh_keys
chmod 700 /data/ssh_keys

exec python3 /tunnels_manager.py

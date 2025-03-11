#!/bin/bash

echo "Starting Nextcloud..."
exec /entrypoint.sh apache2-foreground

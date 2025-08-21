FROM ghcr.io/teableio/teable:latest

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /app/scripts/run.sh
RUN chmod +x /app/scripts/run.sh

# Health check
HEALTHCHECK CMD curl --fail http://127.0.0.1:3000 || exit 1

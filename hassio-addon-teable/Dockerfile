FROM ghcr.io/teableio/teable:0.2.0-alpha-1.8.0-build.263-amd64

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY start.sh /app/scripts/start.sh
RUN chmod +x /app/scripts/start.sh

# Health check
HEALTHCHECK CMD curl --fail http://127.0.0.1:3000 || exit 1

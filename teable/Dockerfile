FROM ghcr.io/teableio/teable:latest

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    postgresql-client \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Удаляем .env
RUN rm -f /app/apps/nextjs-app/.env 2>/dev/null || true

ENTRYPOINT ["/app/run.sh"]
CMD []

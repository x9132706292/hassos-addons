FROM ghcr.io/teableio/teable:latest

# Устанавливаем необходимые утилиты
RUN apt-get update && apt-get install -y \
    postgresql-client \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем run.sh в контейнер
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Удаляем .env, чтобы использовать только переменные окружения
RUN rm -f /app/apps/nextjs-app/.env 2>/dev/null || true

ENTRYPOINT ["/app/run.sh"]
CMD []

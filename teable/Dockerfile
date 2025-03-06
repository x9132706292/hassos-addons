ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Установка зависимостей
RUN apk add --no-cache \
    nodejs \
    npm \
    postgresql-client

# Копирование исходного кода Teable
WORKDIR /app
RUN npm install -g @teable/cli
COPY run.sh /app/run.sh

# Установка прав на выполнение
RUN chmod +x /app/run.sh

# Запуск
CMD ["/app/run.sh"]

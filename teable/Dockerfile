ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Установка только postgresql-client (для проверки базы данных в run.sh)
RUN apk add --no-cache \
    postgresql-client

# Копирование официального образа Teable
FROM ghcr.io/teableio/teable:latest

# Установка рабочей директории
WORKDIR /app

# Копирование run.sh
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Запуск
CMD ["/app/run.sh"]

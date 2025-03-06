ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Установка postgresql-client
RUN apk add --no-cache \
    postgresql-client

# Использование образа Teable
FROM ghcr.io/teableio/teable:latest

WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Явно указываем точку входа
ENTRYPOINT ["/app/run.sh"]

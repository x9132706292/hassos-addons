ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM AS builder

# Устанавливаем зависимости
RUN apk add --no-cache \
    bash \
    jq

# Копируем скрипт запуска


FROM nextcloud:latest

# Копируем зависимости из базового образа
COPY --from=builder /usr/bin/jq /usr/bin/jq
COPY --from=builder /bin/bash /bin/bash
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Указываем точку входа
ENTRYPOINT ["/run.sh"]

FROM nocodb/nocodb:latest

# Устанавливаем утилиты
RUN apk add --no-cache jq

COPY start.sh /usr/src/appEntry/start.sh
RUN chmod +x /usr/src/appEntry/start.sh

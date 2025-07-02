FROM nocodb/nocodb:latest

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/src/appEntry/start.sh
RUN chmod +x /usr/src/appEntry/start.sh

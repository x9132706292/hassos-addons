FROM nexcloud

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /entrypoint.sh
RUN chmod +x /healthcheck.sh

# Health check
HEALTHCHECK CMD /healthcheck.sh

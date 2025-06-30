FROM redis:7.2.4

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
CMD [ "redis-server", "/etc/redis.conf"]

# Health check
HEALTHCHECK CMD redis-cli --raw incr ping || exit 1

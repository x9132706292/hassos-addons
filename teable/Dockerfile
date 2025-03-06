FROM ghcr.io/teableio/teable:latest

# Обновление списка пакетов и установка postgresql-client
WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

CMD ["/app/run.sh"]

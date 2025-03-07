FROM ghcr.io/teableio/teable:latest

# Установка postgresql-client для Debian
RUN apt-get update && apt-get install -y \
    jq \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

ENTRYPOINT ["/app/run.sh"]

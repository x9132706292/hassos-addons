FROM ghcr.io/teableio/teable-db-migrate-ee:latest

# Устанавливаем jq для парсинга конфигурации
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /prisma

COPY run.sh /prisma/run.sh
RUN chmod +x /prisma/run.sh

ENTRYPOINT ["/prisma/run.sh"]
CMD []

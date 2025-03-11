FROM ghcr.io/teableio/teable-db-migrate-ee:latest

# Устанавливаем jq, postgresql-client, zx и prisma
RUN apt-get update && apt-get install -y \
    jq \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g zx prisma@6.2.1

WORKDIR /prisma

COPY run.sh /prisma/run.sh
RUN chmod +x /prisma/run.sh

ENTRYPOINT ["/prisma/run.sh"]
CMD []

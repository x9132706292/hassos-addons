FROM ghcr.io/teableio/teable:latest

RUN apt-get update && apt-get install -y \
    postgresql-client \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Перезаписываем .env, чтобы использовать переменные окружения
RUN echo "PRISMA_DATABASE_URL=\${DATABASE_URL}" > /app/apps/nextjs-app/.env && \
    echo "PUBLIC_ORIGIN=\${PUBLIC_ORIGIN}" >> /app/apps/nextjs-app/.env && \
    echo "NEXT_PUBLIC_BUILD_VERSION=1.6.0-alpha+build.814" >> /app/apps/nextjs-app/.env && \
    echo "PORT=3002" >> /app/apps/nextjs-app/.env && \
    echo "SOCKET_PORT=3002" >> /app/apps/nextjs-app/.env

ENTRYPOINT ["/app/run.sh"]
CMD []

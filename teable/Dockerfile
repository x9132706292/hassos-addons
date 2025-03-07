FROM ghcr.io/teableio/teable:latest

# Установка postgresql-client для Debian
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Временное задание переменных
ENV DATABASE_URL="postgres://teable:teable@77b2833f-timescaledb:5432/teable"
ENV PUBLIC_ORIGIN="http://localhost:3000"

ENTRYPOINT ["/app/run.sh"]

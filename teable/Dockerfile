FROM ghcr.io/teableio/teable:latest

WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

# Временное задание переменных
ENV DATABASE_URL="postgres://teable:teable@core_postgres:5432/teable"
ENV PUBLIC_ORIGIN="http://192.168.1.100:3002"

ENTRYPOINT ["/app/run.sh"]

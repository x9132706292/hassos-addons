FROM ghcr.io/teableio/teable:latest

RUN apk add --no-cache \
    postgresql-client

WORKDIR /app
COPY run.sh /app/run.sh
RUN chmod +x /app/run.sh

ENTRYPOINT ["/app/run.sh"]

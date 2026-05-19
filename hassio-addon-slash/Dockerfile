FROM yourselfhosted/slash:latest

RUN apk add --no-cache jq

WORKDIR /usr/local/slash

COPY docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["./docker-entrypoint.sh"]

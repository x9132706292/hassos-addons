FROM shlinkio/shlink:stable

USER 0

RUN apk add --no-cache jq

COPY docker-entrypoint.sh docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

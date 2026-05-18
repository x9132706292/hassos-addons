FROM shlinkio/shlink:stable

RUN apk add --no-cache jq

COPY docker-entrypoint.sh docker-entrypoint.sh

ENTRYPOINT ["/bin/sh", "./docker-entrypoint.sh"]

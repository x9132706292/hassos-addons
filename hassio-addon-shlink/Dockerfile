FROM shlinkio/shlink:stable

USER 0

RUN apk add --no-cache jq

COPY docker-entrypoint.sh docker-entrypoint.sh

USER 1001

ENTRYPOINT ["/bin/sh", "./docker-entrypoint.sh"]

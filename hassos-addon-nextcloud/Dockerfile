FROM ghcr.io/nextcloud-releases/all-in-one:latest

# Устанавливаем утилиты
RUN apk add --no-cache jq

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]

HEALTHCHECK CMD /healthcheck.sh

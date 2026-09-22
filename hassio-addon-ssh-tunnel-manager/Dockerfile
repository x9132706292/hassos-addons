ARG BUILD_FROM
FROM $BUILD_FROM

RUN apk add --no-cache \
    openssh-client \
    sshpass \
    bash \
    python3 \
    jq

COPY run.sh /
COPY tunnels_manager.py /

RUN chmod a+x /run.sh

CMD ["/run.sh"]

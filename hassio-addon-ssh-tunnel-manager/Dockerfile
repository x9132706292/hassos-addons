FROM alpine:3.20

RUN apk add --no-cache \
    openssh-client \
    sshpass \
    python3

COPY run.sh /run.sh
COPY tunnels_manager.py /tunnels_manager.py

RUN chmod +x /run.sh

CMD ["/run.sh"]

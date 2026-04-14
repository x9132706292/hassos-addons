FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY ciadpi-x86_64 /usr/local/bin/ciadpi-x86_64
RUN chmod +x /usr/local/bin/ciadpi-x86_64

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
#EXPOSE 999

#CMD ["/usr/local/bin/ciadpi-x86_64", "-p", "999"]

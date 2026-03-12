FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/certs/ /etc/nginx/certs/

RUN chmod 644 /etc/nginx/certs/server.crt && chmod 600 /etc/nginx/certs/server.key

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
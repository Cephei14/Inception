FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-xml \
    php-mbstring \
    php-zip \
    mariadb-client \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

RUN mkdir -p /var/run/php-fpm && \
    chown -R www-data:www-data /var/run/php-fpm

RUN cd /tmp && \
    wget https://wordpress.org/wordpress-6.4.tar.gz && \
    tar -xzvf wordpress-6.4.tar.gz && \
    mv wordpress/* /var/www/html/ && \
    rm -rf wordpress-6.4.tar.gz wordpress

COPY conf/www.conf /tmp/www.conf
RUN PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;') && \
    cp /tmp/www.conf /etc/php/${PHP_VER}/fpm/pool.d/www.conf && \
    rm /tmp/www.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
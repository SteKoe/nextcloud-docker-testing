FROM php:7.3-apache-buster

ENV NEXTCLOUD_VERSION "v23.0.3"
ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_LIMIT 512M
ENV ADMIN_USER admin
ENV ADMIN_PASS admin

RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libevent-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libxml2-utils \
        libmagickwand-dev \
        libzip-dev \
        libwebp-dev \
        libgmp-dev \
        gettext \
    ; \
    \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        pcntl \
        zip \
        gmp \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.20; \
    pecl install imagick-3.4.4; \
    pecl install xdebug; \
    \
    docker-php-ext-enable \
        apcu \
        imagick \
        xdebug \
    ; \
    rm -r /tmp/pear; \
    \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get install -y wget git rsync; \
# Install PHPUnit and translationtool
    wget -O /usr/local/bin/phpunit https://phar.phpunit.de/phpunit-9.phar && \
    chmod +x /usr/local/bin/phpunit; \
    wget -O /usr/local/bin/translationtool https://github.com/nextcloud/docker-ci/raw/master/translations/translationtool/translationtool.phar && \
    chmod +x /usr/local/bin/translationtool; \
    rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
RUN \
    echo 'apc.enable_cli=1' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini; \
    \
    { \
        echo 'zend_extension=xdebug.so'; \
        echo 'xdebug.profiler_enable=1'; \
        echo 'xdebug.remote_enable=1'; \
        echo 'xdebug.remote_handler=dbgp'; \
        echo 'xdebug.mode=debug'; \
        echo 'xdebug.remote_mode=req'; \
        echo 'xdebug.client_host=host.docker.internal'; \
        echo 'xdebug.client_port=9000'; \
        echo 'xdebug.remote_host=host.docker.internal'; \
        echo 'xdebug.remote_port=9000'; \
        echo 'xdebug.remote_autostart=1'; \
        echo 'xdebug.remote_connect_back=1'; \
        echo 'xdebug.idekey=PHPSTORM'; \
    } > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
    \
    { \
        echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
        echo 'upload_max_filesize=${PHP_UPLOAD_LIMIT}'; \
        echo 'post_max_size=${PHP_UPLOAD_LIMIT}'; \
    } > /usr/local/etc/php/conf.d/nextcloud.ini; \
    \
    mkdir /var/www/data; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html

RUN a2enmod headers rewrite remoteip ;\
    {\
     echo RemoteIPHeader X-Real-IP ;\
     echo RemoteIPTrustedProxy 10.0.0.0/8 ;\
     echo RemoteIPTrustedProxy 172.16.0.0/12 ;\
     echo RemoteIPTrustedProxy 192.168.0.0/16 ;\
    } > /etc/apache2/conf-available/remoteip.conf;\
    a2enconf remoteip

COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

ADD dummy.tar.gz /dummy-data

RUN git clone https://github.com/nextcloud/server.git --branch=$NEXTCLOUD_VERSION --depth=1 . && \
    git submodule update --init;

ENTRYPOINT ["/setup.sh"]

COPY cmd.sh /cmd.sh
RUN chmod +x /cmd.sh
CMD ["/cmd.sh"]

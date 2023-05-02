FROM nextcloud:26

ENV PHP_MEMORY_LIMIT 2048M

RUN apt update; \
    apt install -y --no-install-recommends git; \
    rm -rf /var/lib/apt/lists/*;

USER "www-data:www-data"

RUN git config --global --add safe.directory /var/www/html && \
    git clone -b v26.0.1 https://github.com/nextcloud/server.git --depth=1 . && \
    git submodule update --init;

ADD dummy.tar.gz /dummy-data

COPY setup.sh /var/www/html/setup.sh
COPY cmd.sh /var/www/html/cmd.sh

USER root
RUN chmod +x /var/www/html/setup.sh
RUN chmod +x /var/www/html/cmd.sh

USER "www-data:www-data"

ENTRYPOINT ["/var/www/html/setup.sh"]
CMD ["/var/www/html/cmd.sh"]
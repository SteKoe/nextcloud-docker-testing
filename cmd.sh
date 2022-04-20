#!/bin/sh

chown -R www-data:www-data data/ config/
chmod 777 apps/

/usr/sbin/apache2ctl -D FOREGROUND
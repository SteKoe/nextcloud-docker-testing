#!/bin/sh
set -eu

chown -R www-data:www-data .

if /var/www/html/occ status | grep "installed: false"; then
  rm -rf /var/www/html/data

  /var/www/html/occ maintenance:install \
    --database sqlite \
    --admin-user $ADMIN_USER \
    --admin-pass $ADMIN_PASS

  mv /dummy-data/* /var/www/html/data/$ADMIN_USER/files
  chmod -R 770 data/

  /var/www/html/occ files:scan $ADMIN_USER
fi

/var/www/html/occ app:enable customproperties

exec "$@"

#!/bin/sh
set -eu

if /var/www/html/occ status | grep "installed: false"; then
  rm -rf /var/www/html/data

  /var/www/html/occ maintenance:install \
    --database sqlite \
    --admin-user admin \
    --admin-pass admin

  cp -r /dummy-data/* /var/www/html/data/admin/files
  /var/www/html/occ files:scan admin

fi

/var/www/html/occ app:enable customproperties

echo "$@"
exec "$@"

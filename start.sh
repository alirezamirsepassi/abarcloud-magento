#!/bin/bash

if [ "$ENTRYPOINT" = "workers" ]; then
  echo Starting workers
  php artisan queue:work --tries=3

elif [ "$ENTRYPOINT" = "schedule_run" ]; then
  echo Starting schedule_run
  while [ 1 ]
  do
    php artisan schedule:run
    sleep 60
  done

elif [ -z "$ENTRYPOINT" ] || "$ENTRYPOINT" = "web" ]
then
  echo Starting web
  cp /tmp/config/local.xml /var/www/public/app/etc
  /usr/bin/supervisord -c /supervisord.conf

else
  echo Error, cannot find entrypoint $ENTRYPOINT to start
fi

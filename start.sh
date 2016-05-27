#!/bin/bash

/create_env.sh

if [ -z "${CRON_SCHEDULE}" ]; then
  echo 'no CRON_SCHEDULE given, aborting'
  exit 1
fi

echo "${CRON_SCHEDULE} /backup.sh >>/var/log/backup.log" | crontab


# Now launch cron in then foreground.
cron -f


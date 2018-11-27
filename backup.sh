#!/bin/bash

date

# built by start.sh
source /env.sh

CURRENT_DATE=`date +%Y-%m-%d`
CURRENT_TIME=`date +%H`
#MONTH=$(date +%B)
#YEAR=$(date +%Y)
S3CMD=/usr/local/bin/s3cmd

if [ -z "${BACKUP_BASE_DIR}" ]; then
  BACKUP_BASE_DIR=/backups
fi

if [ -z "${AWS_ACCESS_KEY}" ]; then
  echo 'ERROR: no AWS_ACCESS_KEY given'
  exit 1
fi

if [ -z "${AWS_SECRET_KEY}" ]; then
  echo 'ERROR: no AWS_SECRET_KEY given'
  exit 1
fi

if [ -z "${AWS_BACKUP_DIR}" ]; then
  echo 'ERROR: no AWS_BACKUP_DIR given'
  exit 1
fi

if [ -z "${AWS_SIGNURL_TIMEOUT}" ]; then
  AWS_SIGNURL_TIMEOUT=100000   # 86400 seconds is a 24h-day
fi

if [ -z "${SMTP_BACKUP_TO}" ]; then
  SMTP_BACKUP_TO=lev@headmade.pro
fi

BACKUP_DIR=${BACKUP_BASE_DIR} #/${YEAR}/${MONTH}
mkdir -p ${BACKUP_DIR}
cd ${BACKUP_DIR}

echo "Backup storing to $BACKUP_DIR"
set | grep PG

#
# Loop through each pg database backing it up
#

#DBLIST=`psql -l | awk '{print $1}' | grep -v "+" | grep -v "Name" | grep -v "List" | grep -v "(" | grep -v "template" | grep -v "postgres" | grep -v "|" | grep -v ":"`
# echo "Databases to backup: ${DBLIST}" >> /var/log/cron.log
#for DB in ${DBLIST}
#do
  #echo "Backing up $DB"  >> /var/log/cron.log
  #FILENAME=${BACKUP_DIR}/${DUMPPREFIX}_${DB}.${CURRENT_DATE}.dmp
  #pg_dump -cOx -i -Fc -f ${FILENAME} ${DB}
#done

BACKUP_EXT=sql.bz2
BACKUP_FILENAME=${PG_BACKUP_DB}.${CURRENT_DATE}.${CURRENT_TIME}.${BACKUP_EXT}

BACKUP_PATH=${BACKUP_DIR}/${BACKUP_FILENAME}

echo "Dumping and compressing ${PG_BACKUP_DB}..."
rm -f ${BACKUP_DIR}/*.${BACKUP_EXT}
(pg_dump -cOx --schema-only ${PG_BACKUP_DB} ; \
  pg_dump -Ox --data-only ${PG_BACKUP_DB} ${PG_BACKUP_TABLE_OPTIONS} ; \
  echo "select 'refresh materialized view ' || matviewname || ';' from pg_matviews;" | psql ${PG_BACKUP_DB} | egrep -v 'column|row' ) | nice pbzip2 >${BACKUP_PATH}

BACKUP_SIZE=`ls -l ${BACKUP_PATH} | cut -d\  -f5`
BACKUP_SIZE_HUMAN=`ls -lh ${BACKUP_PATH} | cut -d\  -f5`

echo "Uploading to ${AWS_BACKUP_DIR}..."
${S3CMD} --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} --no-progress put ${BACKUP_PATH} ${AWS_BACKUP_DIR}

echo "Sending email to ${SMTP_BACKUP_TO}..."
(echo ${BACKUP_SIZE_HUMAN}; ls -l ${BACKUP_PATH}; echo ''; ${S3CMD} signurl ${AWS_BACKUP_DIR}${BACKUP_FILENAME} +${AWS_SIGNURL_TIMEOUT}) | mailx -v -r ${SMTP_USER} -s "${SMTP_SUBJECT_PREFIX}${BACKUP_FILENAME} ${BACKUP_SIZE_HUMAN} ${BACKUP_SIZE}" -S smtp=${SMTP_URL} -S smtp-use-starttls -S smtp-auth=login -S ssl-verify=ignore -S smtp-auth-user=${SMTP_USER} -S smtp-auth-password="${SMTP_PASSWORD}" ${SMTP_BACKUP_TO}

date
sleep 10 # so email can get delivered
echo Done


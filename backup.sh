#!/bin/bash

date

# built by start.sh
source /env.sh

CURRENT_DATE=`date +%Y-%m-%d`
CURRENT_TIME=`date +%H`
#MONTH=$(date +%B)
#YEAR=$(date +%Y)

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

BACKUP_FILENAME=${BACKUP_DIR}/${PG_BACKUP_DB}.${CURRENT_DATE}.${CURRENT_TIME}.sql.bz2
echo "pg_dump -cOx ${PG_BACKUP_DB} ${PG_BACKUP_TABLE_OPTIONS} | nice pbzip2 >${BACKUP_FILENAME}"
pg_dump -cOx ${PG_BACKUP_DB} ${PG_BACKUP_TABLE_OPTIONS} | nice pbzip2 >${BACKUP_FILENAME}

echo "/usr/local/bin/s3cmd --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} put ${BACKUP_FILENAME} ${AWS_BACKUP_DIR}"
/usr/local/bin/s3cmd --progress --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} put ${BACKUP_FILENAME} ${AWS_BACKUP_DIR}
#/usr/local/bin/s3cmd --access_key=${AWS_ACCESS_KEY} --secret_key=${AWS_SECRET_KEY} --no-progress put ${BACKUP_FILENAME} ${AWS_BACKUP_DIR}

#!/bin/bash

if [ -z "${PGUSER}" ]; then
  PGUSER=dev
fi

if [ -z "${PGPASSWORD}" ]; then
  PGPASSWORD=dev
fi

if [ -z "${PGPORT}" ]; then
  PGPORT=5432
fi

if [ -z "${PGHOST}" ]; then
  PGHOST=postgres
fi

#if [ -z "${PGDATABASE}" ]; then
  #PGDATABASE=gis
#fi

#if [ -z "${DUMPPREFIX}" ]; then
  #DUMPPREFIX=PG
#fi

# Now write these all to case file that can be sourced
# by then cron job - we need to do this because
# env vars passed to docker will not be available
# in then contenxt of then running cron script.

echo "
export PGUSER=$PGUSER
export PGPASSWORD=$PGPASSWORD
export PGPORT=$PGPORT
export PGHOST=$PGHOST
export PG_BACKUP_DB=$PG_BACKUP_DB
export PG_BACKUP_TABLE_OPTIONS=$PG_BACKUP_TABLE_OPTIONS

export BACKUP_BASE_DIR=$BACKUP_BASE_DIR
export AWS_ACCESS_KEY=$AWS_ACCESS_KEY
export AWS_SECRET_KEY=$AWS_SECRET_KEY
export AWS_BACKUP_DIR=$AWS_BACKUP_DIR
" > /env.sh

#export PGDATABASE=$PGDATABASE
#export DUMPPREFIX=$DUMPPREFIX


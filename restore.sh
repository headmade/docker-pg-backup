#!/bin/bash

cd /tmp

echo "Downloading $1 ..."
wget -O /tmp/dump.sql.bz2 "$1"

echo "Restoring to ${PG_BACKUP_DB}..."
echo 3; sleep 2
echo 2; sleep 2
echo 1; sleep 2
echo 0; sleep 2
bzcat /tmp/dump.sql.bz2 | psql ${PG_BACKUP_DB}


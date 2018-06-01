#!/bin/sh

export KEYSTORE_ROOT=$AMBARI_HOME/keystore

# no longer need sudo -u postgres in these commands
echo 'Dropping old...'
psql -h localhost -U postgres -f $AMBARI_GIT/ambari-server/src/main/resources/Ambari-DDL-Postgres-EMBEDDED-DROP.sql -v dbname="ambari"

echo 'Create new database "ambari" with owner "ambari"'
psql -h localhost -U postgres -c "CREATE DATABASE ambari WITH ENCODING 'UTF8' OWNER=\"ambari\";"

echo Restoring $1.backup
pg_restore -U postgres -C -d ambari backup/$1.backup

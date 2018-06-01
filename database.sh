#!/bin/bash
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include.sh"

if [ "$1" != "go" ] && [ "$1" != "take" ]; then
    echo "Usage: database.sh take trunk-hdp22"
    echo "Usage: database.sh go trunk-hdp22"
    exit 1
fi

# store current directory
pushd .

cmd=$1
snapshot=$2

# now do the datbaase
if [ "$cmd" == "take" ] ; then
  $PSQL_BIN/pg_dump --host localhost \
    --port 5432 \
    --username "postgres" \
    --no-password \
    --format custom \
    --blobs \
    --section pre-data \
    --section data \
    --section post-data \
    --verbose \
    --file "/Users/$USERNAME/dev/ambari/backup/${snapshot}.backup" "ambari"
elif [ "$cmd" == "go" ] ; then
  file=/Users/$USERNAME/dev/ambari/backup/${snapshot}.backup
  if [ -f $file ] ; then
    $PSQL_BIN/dropdb \
      --username "postgres" \
      --no-password \
      "ambari"

    $PSQL_BIN/createdb \
      --username "postgres" \
      --no-password \
      --owner ambari \
      "ambari"

    $PSQL_BIN/pg_restore --host localhost \
      --port 5432 \
      --username "postgres" \
      --dbname "ambari" \
      --no-password  \
      --section pre-data \
      --section data \
      --section post-data \
      --verbose "$file"
  fi
elif [ "$cmd" == "delete" ] ; then
  rm /Users/$USERNAME/dev/ambari/backup/${snapshot}.backup
fi

# restore original directory
popd

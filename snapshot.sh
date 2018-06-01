#!/bin/bash
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include.sh"

if [ "$1" == "clean" ] && [ "$#" -ne 2 ]; then
    echo "Usage: snapshot.sh clean 3"
    exit 1
elif [ "$1" == "list" ] && [ "$#" -ne 2 ]; then
    echo "Usage: snapshot.sh list 3"
    exit 1
fi

# store current directory
pushd .

echo "Please select the Vagrant operating system: "
echo ""
echo "[1] CentOS 6.4"
echo "[2] CentOS 7.4"
echo ""
read -p 'Operating System (2): ' selection
if [[ -z "${selection// }" ]]; then
  selection="2"
fi

case "$selection" in
  1)
    vagrantPrefix="c64"
    directoryPrefix="6.4"
    ;;
  2)
    vagrantPrefix="c74"
    directoryPrefix="7.4"
    ;;
  *)
    echo "$selection is not a valid option"
    exit 1
esac
cmd=$1

if [ "$cmd" == "clean" ] ; then
  count=$2
  cd /Users/$USERNAME/dev/ambari-vagrant/centos$directoryPrefix
  for i in `seq -f '%02g' 1 $count`;
    do
      vagrant snapshot restore $vagrantPrefix$i clean
    done

  /Users/$USERNAME/dev/ambari/bin/server-init.sh
  popd
  exit 0
fi

if [ "$cmd" == "list" ] ; then
  count=$2
  cd /Users/$USERNAME/dev/ambari-vagrant/centos$directoryPrefix
  echo
  for i in `seq -f '%02g' 1 $count`;
    do
      # vagrant snapshot list $vagrantPrefix$i
      name=`VBoxManage list runningvms | grep -o '".*"' | sed 's/"//g' | grep $vagrantPrefix$i`
      echo "Listing snapshots for $name ..."
      VBoxManage snapshot $name list
      echo
    done

  echo "${MAGENTA}=-=-=-=-=-=-= PostgreSQL Backups =-=-=-=-=-=-=${NC}"
  ls -l /Users/$USERNAME/dev/ambari/backup

  popd
  exit 0
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: snapshot.sh clean 3"
    echo "Usage: snapshot.sh go trunk-hdp22 3"
    echo "Usage: snapshot.sh take trunk-hdp22 3"
    echo "Usage: snapshot.sh delete trunk-hdp22 3"
    exit 1
fi

snapshot=$2
count=$3

# first do the VMs
cd /Users/$USERNAME/dev/ambari-vagrant/centos$directoryPrefix
if [ "$cmd" == "take" ] ; then
  for i in `seq -f '%02g' 1 $count`;
    do
      vagrant snapshot save $vagrantPrefix$i $snapshot
    done
elif [ "$cmd" == "go" ] ; then
  for i in `seq -f '%02g' 1 $count`;
    do
      vagrant snapshot restore $vagrantPrefix$i $snapshot
    done
elif [ "$cmd" == "delete" ] ; then
  for i in `seq -f '%02g' 1 $count`;
    do
      vagrant snapshot delete $vagrantPrefix$i $snapshot
    done
fi

databaseBackupFilename=$vagrantPrefix-${snapshot}.backup

# now do the datbase (but only if not clean)
if [ "$1" != "clean" ] ; then
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
      --file "/Users/$USERNAME/dev/ambari/backup/$databaseBackupFilename" "ambari"
  elif [ "$cmd" == "go" ] ; then
    file=/Users/$USERNAME/dev/ambari/backup/$databaseBackupFilename
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
    rm /Users/$USERNAME/dev/ambari/backup/$databaseBackupFilename
  fi
fi

# restore original directory
popd

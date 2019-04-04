#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

ambariServerHost=$vagrantPrefix"01.ambari.apache.org"
if [ "$HOSTNAME" != $ambariServerHost ]; then
  printf "\n${BLUE}-*- All done on $HOSTNAME ${NC}\n"
  exit 0;
fi

# picked up on startup
export SERVER_CLASSPATH=/osx/src/github.com/apache/ambari/ambari-server/target/classes

# exit on any failure condition
set -e

update_ambari_web

printf "\n${BLUE}-*- All done on $HOSTNAME ${NC}\n"

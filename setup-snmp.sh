#!/bin/bash
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

printf "${BLUE}-*- Installing snmp...\n${NC}"

# exit on any failure condition
set -e

yum install net-snmp net-snmp-utils net-snmp-libs -y

cp  /osx/src/apache/ambari/ambari-server/src/main/resources/APACHE-AMBARI-MIB.txt /usr/share/snmp/mibs

echo "disableAuthorization yes" >> /etc/snmp/snmptrapd.conf

nohup snmptrapd -m ALL -A -n -Lf /tmp/traps.log &

printf "${GREEN}-*-You can now tail /tmp/traps.log\n${NC}"

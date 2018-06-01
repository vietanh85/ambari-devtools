#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

# exit on any failure condition
set -e

echo "192.168.64.1 $HOSTNAME" >> /etc/hosts
echo "192.168.64.1 $HOSTNAME.local" >> /etc/hosts
echo "192.168.64.1 $HOSTNAME.ix" >> /etc/hosts
echo "192.168.64.111 oracle.ambari.apache.org oracle" >> /etc/hosts
echo "192.168.64.112 mysql.ambari.apache.org mysql" >> /etc/hosts
echo "192.168.64.113 repo.ambari.apache.org repository.ambari.apache.org repo repository"  >> /etc/hosts
echo "172.22.71.94" release.eng.hortonworks.com >> /etc/hosts

cd /etc/zypp/repos.d
wget "http://release.eng.hortonworks.com/hwre-api/latestcompiledbuild?stack=AMBARI&release=3.0.0.0&platform=linux&os=suse11sp3&action=download"

zypper --non-interactive install ambari-agent

# setup some aliases
echo "alias agent-update='/osx/ambari-scripts/agent-update.sh'" >> ~/.bashrc
/osx/ambari-scripts/agent-update.sh

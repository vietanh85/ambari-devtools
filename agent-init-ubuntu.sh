#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

sudo ufw disable

# hosts
echo "$VAGRANT_HOST_IP $HOSTNAME" >> /etc/hosts
echo "$VAGRANT_HOST_IP $HOSTNAME.local" >> /etc/hosts
echo "$VAGRANT_HOST_IP $HOSTNAME.ix" >> /etc/hosts
echo "192.168.64.111 oracle.ambari.apache.org oracle" >> /etc/hosts
echo "192.168.64.112 mysql.ambari.apache.org mysql" >> /etc/hosts
echo "192.168.64.113 repo.ambari.apache.org repository.ambari.apache.org repo repository"  >> /etc/hosts

# agent install
cd /etc/apt/sources.list.d/
wget http://s3.amazonaws.com/dev.hortonworks.com/ambari/ubuntu12/1.x/latest/trunk/ambari.list

# HDP
# wget http://public-repo-1.hortonworks.com/HDP/ubuntu12/2.x/hdp.list -O /etc/apt/sources.list.d/hdp.list
apt-get update
apt-get install ambari-agent

# ambari-agent config
echo '${ambariVersion}' > /var/lib/ambari-agent/data/version
sed -i 's/hostname=localhost/hostname=192.168.64.1/g' /etc/ambari-agent/conf/ambari-agent.ini

# setup some aliases
echo "alias agent-update='/osx/ambari-scripts/agent-update.sh'" >> ~/.bashrc
/osx/ambari-scripts/agent-update.sh

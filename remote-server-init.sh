#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

echo "${MAGENTA}=-=-=-=-=-=-= Server Initialization =-=-=-=-=-=-="
echo "options"
echo "  [-s]: stock installation (no updates from local source)"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "${NC}"

stockInstall=false
while getopts ":s" opt; do
  case ${opt} in
    s)
      echo "${BLUE}Installating a stock version of Ambari!${NC}"
      stockInstall=true
      ;;
    \? )
      echo "${RED}Usage: remote-server-init [-s]"
      echo "  [-s]: stock installation (no updates from local source)"
      echo "${NC}"
      ;;
  esac
done

printf "${BLUE}-*- Updating agent.ini files to point to ${vagrantPrefix}01.ambari.apache.org${NC}\n\n"
sed -i "s/hostname=192.168.64.1/hostname=${vagrantPrefix}01.ambari.apache.org/g" /etc/ambari-agent/conf/ambari-agent.ini
ambari-agent restart

ambariServerHost=$vagrantPrefix"01.ambari.apache.org"
if [ "$HOSTNAME" != $ambariServerHost ]; then
  printf "\n${BLUE}-*- All done on $HOSTNAME ${NC}\n"
  exit 0;
fi

# install Ambari Server
yum install -y ambari-server

# if not a stock install
if [ "$stockInstall" = false ] ; then
  # use the developer version
  echo '${ambariVersion}' > /var/lib/ambari-server/resources/version

  # copy resources from OSX
  update_ambari_server_resources
fi

# work around weird postgres start issue with Ambari Server on Vagrant
attempt=0
until [ $attempt -ge 5 ]
do
   ambari-server setup --silent && break  # substitute your command here
   attempt=$[$attempt+1]
   sleep 1
done

printf "${BLUE}-*- Enabling remote debugging for ambari-server${NC}\n"
sed -i 's/$AMBARI_JVM_ARGS/$AMBARI_JVM_ARGS -agentlib:jdwp=transport=dt_socket,server=y,address=8000,suspend=n/g' /var/lib/ambari-server/ambari-env.sh

# picked up on startup
# older versions
# EDIT /usr/lib/$pythonDirectory/site-packages/ambari_server/serverClassPath.py
#  ambari_class_path = "/osx/src/apache/ambari/ambari-server/target/classes" + os.pathsep + "/osx/src/apache/ambari/ambari-server/target" + os.pathsep + ambari_class_path
if [ "$stockInstall" = false ] ; then
  printf "${BLUE}-*- Updating Ambari version in the database${NC}\n"

  export PGPASSWORD=bigdata
  psql -U ambari -d ambari -c "UPDATE metainfo SET metainfo_value = '\${ambariVersion}' WHERE metainfo_key = 'version'"

  echo "export SERVER_CLASSPATH=/osx/src/apache/ambari/ambari-server/target/classes" >> ~/$profileFile
  export SERVER_CLASSPATH=/osx/src/apache/ambari/ambari-server/target/classes

  printf "${BLUE}-*- Removing Views for faster startup${NC}\n"
  find /var/lib/ambari-server/resources/views ! -name 'ambari-admin*' -type f -exec rm -f {} +

  printf "${BLUE}-*- Copying software registry${NC}\n"
  cp /private/ambari-server/resources/hwx-software-registry.json /var/lib/ambari-server/resources/
fi

ambari-server start

printf "\n${BLUE}-*- All done on $HOSTNAME ${NC}\n"

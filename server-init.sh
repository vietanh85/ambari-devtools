#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include.sh"

# exit on any failure condition
set -e
echo "${MAGENTA}"
echo "=-=-=-=-=-=-= Server Reset =-=-=-=-=-=-=-"
echo "${NC}"

export KEYSTORE_ROOT=$AMBARI_HOME/keystore

echo "${CYAN}-*- Dropping old database...${NC}"
sudo -u postgresql psql password=password -f $AMBARI_GIT/ambari-server/src/main/resources/Ambari-DDL-Postgres-EMBEDDED-DROP.sql -v dbname="ambari"
echo ""

echo "${CYAN}-*- Creating new database...${NC}"
sudo -u postgres psql password=password -f $AMBARI_GIT/ambari-server/src/main/resources/Ambari-DDL-Postgres-EMBEDDED-CREATE.sql -v username="\"ambari\"" -v password=\'bigdata\' -v dbname=ambari
sudo -u postgres psql -U ambari password=bigdata -f $AMBARI_GIT/ambari-server/src/main/resources/Ambari-DDL-Postgres-CREATE.sql
echo ""

echo "${CYAN}-*- Resetting certificates...${NC}"
rm -rf $KEYSTORE_ROOT
mkdir -p $KEYSTORE_ROOT
cp -R $AMBARI_GIT/ambari-server/src/main/resources/db $KEYSTORE_ROOT
cp $AMBARI_GIT/ambari-server/conf/unix/ca.config $KEYSTORE_ROOT
sed -i s,/var/lib/ambari-server/keys/db,/Users/$USERNAME/dev/ambari/keystore/db,g $KEYSTORE_ROOT/ca.config

echo "${CYAN}-*- Cleaning up Mpacks...${NC}"
rm -rf /private/ambari-server/resources/mpacks-v2
mkdir /private/ambari-server/resources/mpacks-v2
rm -rf /private/ambari-server/resources/stacks/HDPCORE

echo
printf "${YELLOW}Do you want to link the HDP Stack from Gerrit to Ambari Server? [Y/N] (Y):${NC} "
read -r LINK_HDP_STACK
if [[ -z "${LINK_HDP_STACK// }" ]]; then
  LINK_HDP_STACK="Y"
fi

rm -f /private/ambari-server/resources/stacks/HDP/3.0
case "$LINK_HDP_STACK" in
  [yY])
    echo "${CYAN}-*- Linking HDP Stack from Gerrit...${NC}"
    ln -s /Users/$USERNAME/src/hwx/hdp_ambari_definitions/src/main/resources/stacks/HDP/3.0 /private/ambari-server/resources/stacks/HDP/3.0
    cp -R /Users/$USERNAME/src/hwx/hdp_ambari_definitions/src/main/resources/stacks/HDP/2.6/upgrades /private/ambari-server/resources/stacks/HDP/2.6
    ;;
  [nN])
    ;;
  *)
    echo "$LINK_HDP_STACK is not a valid selection"
    exit 1
esac

echo

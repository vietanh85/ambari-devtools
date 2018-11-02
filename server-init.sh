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

# invoke a function to clear mpack stuff
clearMpackV2Artifacts

echo
printf "${YELLOW}Do you want to link the HDP Stack from Gerrit to Ambari Server (Ambari 2.7)? [Y/N] (N):${NC} "
read -r LINK_HDP_STACK
if [[ -z "${LINK_HDP_STACK// }" ]]; then
  LINK_HDP_STACK="N"
fi

rm -f /private/ambari-server/resources/stacks/HDP/3.0
case "$LINK_HDP_STACK" in
  [yY])
    echo "${CYAN}-*- Linking HDP Stack from Gerrit...${NC}"
    HDP_DIR=/private/ambari-server/resources/stacks/HDP
    if [[ ! -d "${HDP_DIR}" ]]; then
      mkdir -p $HDP_DIR
    fi

    ln -s /Users/$USERNAME/src/hwx/hdp_ambari_definitions/src/main/resources/stacks/HDP/3.0 $HDP_DIR/3.0

    # only copy HDP 2.6 upgrade packs if the 2.6 stack is checked out
    GERRIT_HDP26_DIR=/Users/$USERNAME/src/hwx/hdp_ambari_definitions/src/main/resources/stacks/HDP/2.6
    if [[ -d "${GERRIT_HDP26_DIR}" && -d "${HDP_DIR}/2.6" ]]; then
      cp -R ${GERRIT_HDP26_DIR}/upgrades $HDP_DIR/2.6
    fi
    ;;
  [nN])
    ;;
  *)
    echo "$LINK_HDP_STACK is not a valid selection"
    exit 1
esac

echo

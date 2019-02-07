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
psql password=password -f $AMBARI_GIT/ambari-server/src/main/resources/Ambari-DDL-Postgres-EMBEDDED-DROP.sql -v dbname="ambari"
echo ""

echo "${CYAN}-*- Creating new database...${NC}"
psql password=password -f $AMBARI_GIT/ambari-server/src/main/resources/Ambari-DDL-Postgres-EMBEDDED-CREATE.sql -v username="\"ambari\"" -v password=\'bigdata\' -v dbname=ambari
psql -U ambari password=bigdata -f $AMBARI_GIT/ambari-server/src/main/resources/Ambari-DDL-Postgres-CREATE.sql
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
printf "${YELLOW}Do you want to link the HDP Stack from Gerrit to Ambari Server? [Y/N] (Y):${NC} "
read -r LINK_HDP_STACK
if [[ -z "${LINK_HDP_STACK// }" ]]; then
  LINK_HDP_STACK="Y"
fi

# remove the stacks symlink or directory
PRIVATE_RESOURCES_STACKS=/private/ambari-server/resources/stacks
AMBARI_SRC_STACKS=$AMBARI_GIT/ambari-server/src/main/resources/stacks
PRIVATE_RESOURCES_STACKS_HDP=${PRIVATE_RESOURCES_STACKS}/HDP
if [[ -d "${PRIVATE_RESOURCES_STACKS}" ]]; then
  echo "${CYAN}-*- Removing the ${RED}directory${CYAN} ${PRIVATE_RESOURCES_STACKS} ${NC}"
  rm -rf ${PRIVATE_RESOURCES_STACKS}
elif [[ -L "${PRIVATE_RESOURCES_STACKS}" ]]; then
  echo "${CYAN}-*- Removing the ${RED}symlink${CYAN} ${PRIVATE_RESOURCES_STACKS} ${NC}"
  rm -f ${PRIVATE_RESOURCES_STACKS}
fi

case "$LINK_HDP_STACK" in
  [yY])
    echo "${CYAN}-*- Linking HDP Stack from Gerrit...${NC}"

    # iterate over all known HDP versions
    HDP_VERSIONS=(2.4 2.5 2.6 2.7 2.8 3.0 3.1,3.2)

    # make the stacks directory only if it doesn't exist
    mkdir -p ${PRIVATE_RESOURCES_STACKS_HDP}

    # link everything in source to private so that Python files are found
    for ENTRY in $AMBARI_SRC_STACKS/*; do
      FILENAME=${ENTRY##*/}
      echo "      $PRIVATE_RESOURCES_STACKS/$FILENAME ${GREEN}->${NC} $AMBARI_SRC_STACKS/$FILENAME"
      ln -s $AMBARI_SRC_STACKS/$FILENAME $PRIVATE_RESOURCES_STACKS/$FILENAME
    done

    # find any HDP versions in Ambari's source tree (normally for older versions)
    AMBARI_HDP_DIRECTORY=$AMBARI_SRC_STACKS/HDP
    if [[ -d "${AMBARI_HDP_DIRECTORY}" ]]; then
      for HDP_VERSION in "${HDP_VERSIONS[@]}"
      do
        if [[ -d "${AMBARI_HDP_DIRECTORY}/${HDP_VERSION}" ]]; then
          ln -s ${AMBARI_HDP_DIRECTORY}/${HDP_VERSION} ${PRIVATE_RESOURCES_STACKS_HDP}/${HDP_VERSION}
        fi
      done
    fi

    # some repositories have a different structure for the HDP stacks, so see which is checked out
    GERRIT_HDP_BASE_DIRS=(/Users/$USERNAME/src/hwx/hdp_ambari_definitions /Users/$USERNAME/src/hwx/hdp_ambari_definitions/stack)
    for BASE_DIR in "${GERRIT_HDP_BASE_DIRS[@]}"
    do
      if [[ -d "${BASE_DIR}/src/main/resources/stacks/HDP" ]]; then
        GERRIT_HDP_BASE_DIR=${BASE_DIR}/src/main/resources/stacks/HDP
        break
      fi
    done

    for HDP_VERSION in "${HDP_VERSIONS[@]}"
    do
      if [[ -d "${GERRIT_HDP_BASE_DIR}/${HDP_VERSION}" ]]; then
        ln -s ${GERRIT_HDP_BASE_DIR}/${HDP_VERSION} ${PRIVATE_RESOURCES_STACKS_HDP}/${HDP_VERSION}
      fi
    done
    ;;
  [nN])
    echo "${CYAN}-*- Linking HDP Stack from Ambari source...${NC}"
    ln -s $AMBARI_GIT/ambari-server/src/main/resources/stacks ${PRIVATE_RESOURCES_STACKS}
    ;;
  *)
    echo "${RED}$LINK_HDP_STACK is not a valid selection ${NC}"
    exit 1
esac

echo

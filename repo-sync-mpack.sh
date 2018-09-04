#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash-colors.sh"

set -e

echo
read -p "Mpack [HDPCORE]: " MPACK_NAME
if [[ -z "${MPACK_NAME// }" ]]; then
  MPACK_NAME="HDPCORE"
fi

read -p "Mpack Version [1.0.0]: " MPACK_VERSION
if [[ -z "${MPACK_VERSION// }" ]]; then
  MPACK_VERSION="1.0.0"
fi

read -p "Build Number: " BUILD
if [[ -z "${BUILD// }" ]]; then
  echo "${RED}A build number is required!${NC}"
  exit 1
fi

read -p "Mpack Repo URL Version [1.x]: " MPACK_REPO_URL_VERSION
if [[ -z "${MPACK_REPO_URL_VERSION// }" ]]; then
  MPACK_REPO_URL_VERSION="1.x"
fi

MPACK_NAME_LOWERCASE="${MPACK_NAME,,}"

# define variables to use
MPACK_REPO_FILE="/etc/yum.repos.d/$MPACK_NAME_LOWERCASE.repo"
MPACK_URL="http://s3.amazonaws.com/dev.hortonworks.com/$MPACK_NAME/centos7/1.x/BUILDS/$MPACK_VERSION-$BUILD"
MPACK_SYNC_LOCATION="/var/www/html/$MPACK_NAME_LOWERCASE/centos7"
MPACK_SYNC_LOCATION_WILDCARD="$MPACK_SYNC_LOCATION/$MPACK_NAME-$MPACK_VERSION*"
MPACK_DEFINITION_NAME="$MPACK_NAME_LOWERCASE-$MPACK_VERSION-$BUILD-definition"
MPACK_TARBALL_NAME="$MPACK_DEFINITION_NAME.tar.gz"
MPACK_TARBALL_URL="http://dev.hortonworks.com.s3.amazonaws.com/$MPACK_NAME/centos7/$MPACK_REPO_URL_VERSION/BUILDS/$MPACK_VERSION-$BUILD/$MPACK_TARBALL_NAME"

echo "${CYAN}Syncing $MPACK_NAME-$MPACK_VERSION-$BUILD..."
echo "${MAGENTA}  [Repo File]:${CYAN} $MPACK_REPO_FILE"
echo "${MAGENTA}  [URL]:${CYAN} $MPACK_URL"
echo "${MAGENTA}  [Removing]:${CYAN} $MPACK_SYNC_LOCATION_WILDCARD"
echo "${MAGENTA}  [Definition Name]:${CYAN} $MPACK_DEFINITION_NAME"
echo "${MAGENTA}  [Tarball]:${CYAN} $MPACK_TARBALL_NAME"
echo "${MAGENTA}  [Tarball URL]:${CYAN} $MPACK_TARBALL_URL"
echo "${NC}"

echo "
[$MPACK_NAME-$MPACK_VERSION-$BUILD]
name=$MPACK_NAME Version - $MPACK_NAME-$MPACK_VERSION-$BUILD
baseurl=$MPACK_URL
gpgcheck=0
enabled=1
priority=1
" > $MPACK_REPO_FILE

pushd $MPACK_SYNC_LOCATION > /dev/null

printf "${YELLOW}Do you want to remove ${CYAN} $MPACK_SYNC_LOCATION_WILDCARD ${YELLOW}? [Y/N] (N):${NC} "
read -r REMOVE_WILDCARD_MPACK
if [[ -z "${REMOVE_WILDCARD_MPACK// }" ]]; then
  REMOVE_WILDCARD_MPACK="N"
fi

case "$REMOVE_WILDCARD_MPACK" in
  [yY])
    \rm -r $MPACK_SYNC_LOCATION_WILDCARD || true
    ;;
  [nN])
    ;;
  *)
    echo "$REMOVE_WILDCARD_MPACK is not a valid selection"
    exit 1
esac

reposync -r $MPACK_NAME-$MPACK_VERSION-$BUILD
createrepo $MPACK_NAME-$MPACK_VERSION-$BUILD

cd $MPACK_SYNC_LOCATION/$MPACK_NAME-$MPACK_VERSION-$BUILD
wget $MPACK_TARBALL_URL
tar -xvzf $MPACK_TARBALL_NAME
rm $MPACK_TARBALL_NAME
cp $MPACK_DEFINITION_NAME/mpack.json .

sed -i "s,http://dev.hortonworks.com.s3.amazonaws.com/$MPACK_NAME/centos7/1.x/BUILDS/$MPACK_VERSION-$BUILD,http://repo.ambari.apache.org/$MPACK_NAME_LOWERCASE/centos7/$MPACK_NAME-$MPACK_VERSION-$BUILD,g" $MPACK_DEFINITION_NAME/repos/repoinfo.xml
sed -i "s,http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.21/repos/centos7,http://repo.ambari.apache.org/$MPACK_NAME_LOWERCASE/centos7/HDP-UTILS-1.1.0.21,g" $MPACK_DEFINITION_NAME/repos/repoinfo.xml
sed -i "s,http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.22/repos/centos7,http://repo.ambari.apache.org/$MPACK_NAME_LOWERCASE/centos7/HDP-UTILS-1.1.0.22,g" $MPACK_DEFINITION_NAME/repos/repoinfo.xml

tar -zcvf $MPACK_TARBALL_NAME $MPACK_DEFINITION_NAME
\rm -r  $MPACK_DEFINITION_NAME
popd > /dev/null

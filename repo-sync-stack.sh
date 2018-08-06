#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash-colors.sh"

set -e

echo

read -p "Operating System [centos7]: " OS
if [[ -z "${OS// }" ]]; then
  OS="centos7"
fi

read -p "Stack [HDP]: " STACK_NAME
if [[ -z "${STACK_NAME// }" ]]; then
  STACK_NAME="HDP"
fi

read -p "Stack Version [3.0.0.0]: " STACK_VERSION
if [[ -z "${STACK_VERSION// }" ]]; then
  STACK_VERSION="3.0.0.0"
fi

STACK_NAME_LOWERCASE="${STACK_NAME,,}"

read -p "Build Number: " BUILD
if [[ -z "${BUILD// }" ]]; then
  echo "${RED}A build number is required!${NC}"
  exit 1
fi

read -p "Repo URL Version [3.x]: " REPO_URL_VERSION
if [[ -z "${REPO_URL_VERSION// }" ]]; then
  REPO_URL_VERSION="3.x"
fi

read -p "Supports GPL Repo [Y]: " SUPPORTS_GPL
if [[ -z "${SUPPORTS_GPL// }" ]]; then
  SUPPORTS_GPL=true
fi

# define variables to use
REPO_FILE="/etc/yum.repos.d/$STACK_NAME_LOWERCASE.repo"
REPO_URL="http://s3.amazonaws.com/dev.hortonworks.com/$STACK_NAME/$OS/$REPO_URL_VERSION/BUILDS/$STACK_VERSION-$BUILD"
SYNC_LOCATION="/var/www/html/$STACK_NAME_LOWERCASE/$OS"
SYNC_LOCATION_WILDCARD="$SYNC_LOCATION/$STACK_NAME-$STACK_VERSION*"

echo "${CYAN}Syncing $STACK_NAME-$STACK_VERSION-$BUILD..."
echo "${MAGENTA}  [Repo File]:${CYAN} $REPO_FILE"
echo "${MAGENTA}  [URL]:${CYAN} $REPO_URL"
echo "${MAGENTA}  [Removing]:${CYAN} $SYNC_LOCATION_WILDCARD"
echo "${NC}"

echo "
[$STACK_NAME-$STACK_VERSION-$BUILD]
name=$STACK_NAME $STACK_VERSION-$BUILD
baseurl=$REPO_URL
gpgcheck=0
enabled=1
priority=1

" > $REPO_FILE

if $SUPPORTS_GPL ; then
echo "
[$STACK_NAME-GPL-$STACK_VERSION-$BUILD]
name=$STACK_NAME-GPL $STACK_VERSION-$BUILD
baseurl=http://s3.amazonaws.com/dev.hortonworks.com/$STACK_NAME-GPL/$OS/$REPO_URL_VERSION/BUILDS/$STACK_VERSION-$BUILD
gpgcheck=0
enabled=1
" >> $REPO_FILE
fi

pushd $SYNC_LOCATION > /dev/null

\rm -r $SYNC_LOCATION_WILDCARD || true
reposync -r $STACK_NAME-$STACK_VERSION-$BUILD
createrepo $STACK_NAME-$STACK_VERSION-$BUILD

if $SUPPORTS_GPL ; then
  \rm -r $SYNC_LOCATION/$STACK_NAME-GPL-$STACK_VERSION* || true
  reposync -r $STACK_NAME-GPL-$STACK_VERSION-$BUILD
  createrepo $STACK_NAME-GPL-$STACK_VERSION-$BUILD
fi

rm $REPO_FILE
popd > /dev/null

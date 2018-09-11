#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash-colors.sh"

set -e

HTTPD_ROOT="/repos"

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

read -p "Supports GPL Repo [Y]: " SUPPORTS_GPL_YN
if [[ -z "${SUPPORTS_GPL_YN// }" ]]; then
  SUPPORTS_GPL_YN="Y"
fi

case "$SUPPORTS_GPL_YN" in
  [yY])
    SUPPORTS_GPL=true
    ;;
  [nN])
  SUPPORTS_GPL=false
    ;;
  *)
  SUPPORTS_GPL=false
esac

# define variables to use
REPO_FILE="/etc/yum.repos.d/$STACK_NAME_LOWERCASE-$STACK_VERSION.repo"
REPO_URL="http://s3.amazonaws.com/dev.hortonworks.com/$STACK_NAME/$OS/$REPO_URL_VERSION/BUILDS/$STACK_VERSION-$BUILD"
SYNC_LOCATION="$HTTPD_ROOT/$STACK_NAME_LOWERCASE/$OS"
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

printf "${YELLOW}Do you want to remove ${CYAN} $SYNC_LOCATION_WILDCARD ${YELLOW}? [Y/N] (N):${NC} "
read -r REMOVE_WILDCARD_STACK
if [[ -z "${REMOVE_WILDCARD_STACK// }" ]]; then
  REMOVE_WILDCARD_STACK="N"
fi

case "$REMOVE_WILDCARD_STACK" in
  [yY])
    \rm -r $SYNC_LOCATION_WILDCARD || true
    if $SUPPORTS_GPL ; then
      \rm -r $SYNC_LOCATION/$STACK_NAME-GPL-$STACK_VERSION* || true
    fi
    ;;
  [nN])
    ;;
  *)
    echo "$REMOVE_WILDCARD_STACK is not a valid selection"
    exit 1
esac

reposync -r $STACK_NAME-$STACK_VERSION-$BUILD
createrepo $STACK_NAME-$STACK_VERSION-$BUILD

if $SUPPORTS_GPL ; then
  reposync -r $STACK_NAME-GPL-$STACK_VERSION-$BUILD
  createrepo $STACK_NAME-GPL-$STACK_VERSION-$BUILD
fi

rm $REPO_FILE
popd > /dev/null

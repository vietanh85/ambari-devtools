#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash-colors.sh"

# exit on any failure condition
set -e

# http://home.apache.org/~jhurley/apache-ambari-2.7.1-rc0/
printf "Source tarball location: "
read -r SOURCE_TARBALL_LOCATION
if [[ -z "${SOURCE_TARBALL_LOCATION// }" ]]; then
  exit 1
fi

# apache-ambari-2.7.1-src.tar.gz
printf "Source tarball Name: "
read -r SOURCE_TARBALL
if [[ -z "${SOURCE_TARBALL// }" ]]; then
  exit 1
fi

printf "Git tag name (release-2.7.1-rc0): "
read -r GIT_TAG
if [[ -z "${GIT_TAG// }" ]]; then
  GIT_TAG="release-2.7.1-rc0"
fi

printf "Release Version (2.7.1): "
read -r AMBARI_RELEASE_VERSION
if [[ -z "${AMBARI_RELEASE_VERSION// }" ]]; then
  AMBARI_RELEASE_VERSION="2.7.1"
fi

cd /tmp

wget $SOURCE_TARBALL_LOCATION/$SOURCE_TARBALL
openssl sha512 $SOURCE_TARBALL > $SOURCE_TARBALL.sha512
tar -zxvf $SOURCE_TARBALL

git clone --branch $GIT_TAG git@github.com:apache/ambari.git apache-ambari-$AMBARI_RELEASE_VERSION-git
cd apache-ambari-$AMBARI_RELEASE_VERSION-git
git clean -xdf

mvn clean package -DskipTests

# cd ambari-web
# npm install
# ulimit -n 2048
# brunch build  # (will need to gzip app.js and vendor.js)
# rm -rf node_modules
# cp -R public/ public-static/
# rm -rf public/
# cd ../..
# tar --exclude=.git --exclude=.gitignore --exclude=.gitattributes -zcvf apache-ambari-$AMBARI_RELEASE_VERSION-git.tar.gz apache-ambari-$AMBARI_RELEASE_VERSION-git/
# openssl sha512 apache-ambari-$AMBARI_RELEASE_VERSION-git.tar.gz > apache-ambari-$AMBARI_RELEASE_VERSION-git.tar.gz.sha512

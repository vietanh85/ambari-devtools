#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash-colors.sh"

AMBARI=/osx/src/apache/ambari
AMBARI_VERSION_MARKER=~/ambari-version
HDP_MPACK=/osx/src/hwx/hdp_ambari_definitions
HOSTNAME=`hostname`

centOSVersion=`cat /etc/redhat-release | grep -o '[0-9]\.[0-9]'`
pythonVersion=`python -c 'import platform; print(platform.python_version())'`

AMBARI_VERSION=""
if [ -f $AMBARI_VERSION_MARKER ]; then
    AMBARI_VERSION=`cat $AMBARI_VERSION_MARKER`
fi

case $pythonVersion in
    2.6*) pythonDirectory="python2.6";;
    2.7*) pythonDirectory="python2.7";;
    *)
      echo "Python $pythonVersion is not recognized"
      exit 1
esac

printf "${GREEN}Detected CentOS/Redhat ${centOSVersion}${NC}\n"
printf "${GREEN}Detected Python ${pythonVersion}${NC}\n\n"

case "$centOSVersion" in
  6.4)
    operatingSystem="centos6"
    vagrantPrefix="c64"
    directoryPrefix="6.4"
    ;;
  7*)
    operatingSystem="centos7"
    vagrantPrefix="c74"
    directoryPrefix="7.4"
    ;;
  *)
    echo "CentOS $centOSVersion is not recognized!"
    exit 1
esac

# figure out which file to edit for profile additions
profileFile=.profile
if [ -f "$HOME/.bash_profile" ]; then
  profileFile=.bash_profile
fi

# does simple copying, skipping missing source directories
function copy_from_osx {
  # strip out trailing slash to prevent double slashes
  SOURCE=$(echo "$1"|sed 's/\/$//g')
  TARGET=$2

  if [ ! -d $SOURCE ]; then
    printf "    ├──${RED} Missing copy-from location %s${NC}\n" $SOURCE
    return 0
  fi

  if [ ! -d $TARGET ]; then
    printf "    ├──${RED} Missing copy-to location %s${NC}\n" $TARGET
    return 0
  fi

 printf "    ├──${GREEN} Copying %s to %s${NC}\n" $SOURCE $TARGET
 rsync -rt --safe-links --exclude '*.pyc' $SOURCE/ $TARGET
}

function update_ambari_server_resources {
  printf "${BLUE}├── Copying Ambari Server resources from OSX to Vagrant${NC}\n"
  rm -f /usr/lib/ambari-server/ambari-server*.jar
  rm -f /usr/lib/ambari-server/ambari-views*.jar
  cp $AMBARI/ambari-views/target/ambari-views-*.jar /usr/lib/ambari-server/

  rm -rf /usr/lib/ambari-server/web/*
  cp -ar $AMBARI/ambari-web/public/* /usr/lib/ambari-server/web

  # ambari-server python resource copy (for both older and newer versions of ambari)
  copy_from_osx $AMBARI/ambari-server/src/main/resources /var/lib/ambari-server/resources

  # only copy HDP Mpack if the ambari version is low enough
  if [[ $AMBARI_VERSION == 2* ]] ; then
    copy_from_osx $HDP_MPACK/src/main/resources/stacks /var/lib/ambari-server/resources/stacks
  fi

  copy_from_osx $AMBARI/ambari-server/src/main/python/ambari_server /usr/lib/$pythonDirectory/site-packages/ambari_server
  copy_from_osx $AMBARI/ambari-server/src/main/python/ambari_server /usr/lib/ambari-server/lib/ambari_server

  # copy over bin stuff
  cp -R $AMBARI/ambari-server/src/main/python/*.py /usr/sbin
}

function update_agent {
  case "$1" in
    delete-target)
      deleteTarget=true
      ;;
    preserve-target)
      deleteTarget=false
      ;;
    *)
      echo "The first argument must be either delete-target or preserve-target"
      exit 1
  esac

  # strip out trailing slash to prevent double slashes
  SOURCE=$(echo "$2"|sed 's/\/$//g')
  TARGET=$3

  printf "    ├──$SOURCE -> $TARGET\n"

  if [ ! -d $SOURCE ]; then
    printf "      ├──${RED} Missing copy-from location %s${NC}\n" $SOURCE
    return 0
  fi

 if [[ -d $TARGET && "$deleteTarget" = true ]]; then
   printf "      ├── Removing %s\n" $TARGET
   rm -rf $TARGET
   # mv $3 "$3.`date +%s`"
 fi

 printf "      ├──${GREEN} Copying %s to %s${NC}\n" $SOURCE $TARGET
 mkdir -p $TARGET

 rsync -rt --safe-links --exclude '*.pyc' $SOURCE/ $TARGET

 find $TARGET -name "*.py?" -delete
}

function ambariServerReset() {
  ambari-server stop
  rm -rf /var/lib/ambari-server/resources/mpacks-v2/staging/*
  rm -rf /var/lib/ambari-server/resources/mpacks-v2/HDPCORE/
  rm -rf /var/lib/ambari-server/resources/stacks/HDPCORE/
  ambari-server reset
}

function update_ambari_web {
  printf "${BLUE}├── Copying Ambari Web from OSX to Vagrant${NC}\n"
  rm -rf /usr/lib/ambari-server/web/*
  cp -ar $AMBARI/ambari-web/public/* /usr/lib/ambari-server/web
}

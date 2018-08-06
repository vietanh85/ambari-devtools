#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash-colors.sh"

requiredVariables=( USERNAME AMBARI_GIT AMBARI_HOME AMBARI_BIN AMBARI_PYTHON_WRAPPER )
for var in "${requiredVariables[@]}"
do
  if [[ ! -n "${!var}" ]]; then
    echo "${RED}The environment variable $var must be set for these scripts to work${NC}"
    exit 1
  fi
done

function clearMpackV2Artifacts() {
  knownMpacks=( HDPCORE EDW )

  echo "${CYAN}-*- Cleaning up Mpacks & HDPCore...${NC}"
  rm -rf /private/ambari-server/resources/mpacks-v2
  mkdir /private/ambari-server/resources/mpacks-v2

  for mpack in "${knownMpacks[@]}"
  do
    if [[ -e "/private/ambari-server/resources/stacks/$mpack" ]]; then
      echo "${RED}    - Removing /private/ambari-server/resources/stacks/$mpack ${NC}"
      rm -r /private/ambari-server/resources/stacks/$mpack
    fi
  done
}

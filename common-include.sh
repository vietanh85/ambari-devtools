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

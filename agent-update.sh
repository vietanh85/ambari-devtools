#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

# exit on any failure condition
set -e

pythonVersion=`python -c 'import platform; print(platform.python_version())'`
case $pythonVersion in
    2.6*) pythonDirectory="python2.6";;
    2.7*) pythonDirectory="python2.7";;
    *)
      echo "Python $pythonVersion is not recognized"
      exit 1
esac

ambari-agent stop

# Ambari 3.0+ does not use site-packages
echo "-*- ${BLUE}Agent Python${NC}"
if [ -d "/usr/lib/$pythonDirectory/site-packages/ambari_agent" ]; then
  update_agent delete-target $AMBARI/ambari-agent/src/main/python/ambari_agent /usr/lib/$pythonDirectory/site-packages/ambari_agent
fi

# /usr/lib/ambari-agent/lib
update_agent delete-target $AMBARI/ambari-agent/src/main/python/ambari_agent /usr/lib/ambari-agent/lib/ambari_agent
update_agent delete-target $AMBARI/ambari-common/src/main/python/ambari_commons /usr/lib/ambari-agent/lib/ambari_commons
update_agent delete-target $AMBARI/ambari-common/src/main/python/ambari_stomp /usr/lib/ambari-agent/lib/ambari_stomp
update_agent delete-target $AMBARI/ambari-common/src/main/python/ambari_ws4py /usr/lib/ambari-agent/lib/ambari_ws4py
update_agent delete-target $AMBARI/ambari-common/src/main/python/ambari_jinja2/ambari_jinja2 /usr/lib/ambari-agent/lib/ambari_jinja2
update_agent delete-target $AMBARI/ambari-common/src/main/python/ambari_simplejson /usr/lib/ambari-agent/lib/ambari_simplejson
update_agent delete-target $AMBARI/ambari-common/src/main/python/resource_management /usr/lib/ambari-agent/lib/resource_management
echo

# /var/lib/ambari-agent/cache
echo "-*- ${BLUE}Stacks${NC}"
update_agent delete-target $AMBARI/ambari-server/src/main/resources/common-services /var/lib/ambari-agent/cache/common-services
update_agent delete-target $AMBARI/ambari-server/src/main/resources/custom_actions /var/lib/ambari-agent/cache/custom_actions
update_agent delete-target $AMBARI/ambari-server/src/main/resources/host_scripts /var/lib/ambari-agent/cache/host_scripts
update_agent delete-target $AMBARI/ambari-server/src/main/resources/stack-hooks /var/lib/ambari-agent/cache/stack-hooks
update_agent preserve-target $AMBARI/ambari-server/src/main/resources/stacks /var/lib/ambari-agent/cache/stacks

echo "    ├──${MAGENTA} Removing the following bad symlinks:"
find /var/lib/ambari-agent/cache/stacks/HDP -lname '*' -exec echo "      └── " {} \;
find /var/lib/ambari-agent/cache/stacks/HDP -lname '*' -exec rm -rf {} \;
echo "${NC}"

# only copy HDP Mpack if the ambari version is low enough
if [[ $AMBARI_VERSION == 2* ]] ; then
  echo "-*- ${BLUE}Stacks (Mpacks)${NC}"
  update_agent preserve-target $HDP_MPACK/src/main/resources/stacks /var/lib/ambari-agent/cache/stacks
  echo
fi

\cp $AMBARI/ambari-common/src/main/unix/ambari-python-wrap /var/lib/ambari-agent/

if [ -d /usr/lib/mpack-instance-manager ]; then
  echo "-*- ${BLUE}Mpack Instance Manager${NC}"
  update_agent delete-target $AMBARI/mpack-instance-manager/src/main/python/instance_manager /usr/lib/mpack-instance-manager
  find /usr/lib/mpack-instance-manager -name "*.py?" -delete
fi

echo ""

if [ ! -d /var/lib/ambari-agent/tmp ]; then
  mkdir -p /var/lib/ambari-agent/tmp
fi

rm -f /var/lib/ambari-agent/*.sh
cp $AMBARI/ambari-agent/conf/unix/*.sh /var/lib/ambari-agent
chmod a+x /var/lib/ambari-agent/*.sh

# remove all pyc/pyo files to ensure new code is used
find /var/lib/ambari-agent -name "*.py?" -delete
find /usr/lib/ambari-agent -name "*.py?" -delete
find /usr/lib/$pythonDirectory/site-packages -name "*.py?" -delete

cat $AMBARI/version > /var/lib/ambari-agent/data/version
ambari-agent start

# for cases where a-s is installed on the cluster and will push its resources
if [ -d "/var/lib/ambari-server/resources" ]; then
  # remove all pyc files to ensure new code is used
  find /var/lib/ambari-server -name "*.py?" -delete

  echo "-*- ${BLUE}Server Stack${NC}"
  update_agent delete-target $AMBARI/ambari-server/src/main/resources/common-services /var/lib/ambari-server/resources/common-services
  update_agent delete-target $AMBARI/ambari-server/src/main/resources/custom_actions /var/lib/ambari-server/resources/custom_actions
  update_agent delete-target $AMBARI/ambari-server/src/main/resources/stack-hooks /var/lib/ambari-server/resources/stack-hooks
  update_agent preserve-target $AMBARI/ambari-server/src/main/resources/stacks /var/lib/ambari-server/resources/stacks

  if [[ $AMBARI_VERSION == 2* ]] ; then
    update_agent preserve-target $HDP_MPACK/src/main/resources/stacks /var/lib/ambari-server/resources/stacks
  fi

  echo
fi

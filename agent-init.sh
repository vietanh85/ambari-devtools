#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

# exit on any failure condition
set -e

echo "${MAGENTA}=-=-=-=-=-=-= Agent Initialization =-=-=-=-=-=-="
echo "[-s]: stock installation (no updates from local source)"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=${NC}"

stockInstall=false
while getopts ":s" opt; do
  case ${opt} in
    s)
      echo "${BLUE}Installating a stock version of Ambari!${NC}"
      stockInstall=true
      ;;
    \?)
      echo "${RED}Usage: agent-init [-s]"
      echo "  [-s]: stock installation (no updates from local source)"
      echo "${NC}"
      exit 1
      ;;
  esac
done

centOSVersion=`cat /etc/redhat-release | grep -o '[0-9]\.[0-9]'`
echo "Detected CentOS/Redhat $centOSVersion"

# turn off firewall
case "$centOSVersion" in
  6.4)
    operatingSystem="centos6"
    service iptables stop
    chkconfig iptables off
    ;;
  7*)
    operatingSystem="centos7"
    systemctl stop firewalld
    ;;
  *)
    echo "CentOS $centOSVersion is not recognized!"
    exit 1
esac

service ntpd restart

# hosts
echo "$VAGRANT_HOST_IP $HOSTNAME" >> /etc/hosts
echo "$VAGRANT_HOST_IP $HOSTNAME.local" >> /etc/hosts
echo "$VAGRANT_HOST_IP $HOSTNAME.ix" >> /etc/hosts
echo "192.168.64.111 oracle.ambari.apache.org oracle" >> /etc/hosts
echo "192.168.64.112 mysql.ambari.apache.org mysql" >> /etc/hosts
echo "192.168.64.113 repo.ambari.apache.org repository.ambari.apache.org repo repository"  >> /etc/hosts
echo "172.22.71.94" release.eng.hortonworks.com >> /etc/hosts

echo "Please select the version of Ambari you want to install:"
echo ""
echo "[1] Ambari 2.5.2.0"
echo "[2] Ambari 2.6.0.0"
echo "[3] Ambari 2.6.2.0 (CentOS 6/7)"
echo "[4] Ambari 2.7.0.0 (CentOS 7)"
echo "[5] Ambari 3.0.0.0 (CentOS 7)"
printf "Option (5): "

read -r AMBARI_INSTALL_CHOICE
if [[ -z "${AMBARI_INSTALL_CHOICE// }" ]]; then
  AMBARI_INSTALL_CHOICE="5"
fi

# agent install
cd /etc/yum.repos.d/

case "$AMBARI_INSTALL_CHOICE" in
  1)
  wget -O /etc/yum.repos.d/ambari.repo "http://repo.ambari.apache.org/ambari/$operatingSystem/Ambari-2.5.2.0/ambari.repo"
  echo "2.5.2.0" >> $AMBARI_VERSION_MARKER
  ;;
  2)
  wget -O /etc/yum.repos.d/ambari.repo "http://repo.ambari.apache.org/ambari/$operatingSystem/Ambari-2.6.0.0/ambari.repo"
  echo "2.6.0.0" >> $AMBARI_VERSION_MARKER
  ;;
  3)
  wget -O /etc/yum.repos.d/ambari.repo "http://repo.ambari.apache.org/ambari/$operatingSystem/Ambari-2.6.2.0/ambari.repo"
  echo "2.6.2.0" >> $AMBARI_VERSION_MARKER
  ;;
  4)
  wget -O /etc/yum.repos.d/ambari.repo "http://repo.ambari.apache.org/ambari/$operatingSystem/Ambari-2.7.0.0/ambari.repo"
  echo "2.7.0.0" >> $AMBARI_VERSION_MARKER
  ;;
  5)
  wget -O /etc/yum.repos.d/ambari.repo "http://repo.ambari.apache.org/ambari/$operatingSystem/Ambari-3.0.0.0-1645/ambari.repo"
  echo "3.0.0.0" >> $AMBARI_VERSION_MARKER
  ;;
  *)
    echo "$AMBARI_INSTALL_CHOICE is not a valid option"
    exit 1
esac

yum install -y ambari-agent

# ambari-agent config
sed -i 's/hostname=localhost/hostname=192.168.64.1/g' /etc/ambari-agent/conf/ambari-agent.ini

# MySQL Connector is GPL - make sure it's ready for the agents
mkdir -p /usr/share/java
cp /private/ambari-server/resources/mysql-connector-java.jar /usr/share/java/

# setup some aliases
echo "alias agent-update='/osx/ambari-scripts/agent-update.sh'" >> ~/.bashrc
echo "alias server-init='/osx/ambari-scripts/remote-server-init.sh'" >> ~/.bashrc
echo "alias server-update='/osx/ambari-scripts/remote-server-update.sh'" >> ~/.bashrc
echo "alias web-update='/osx/ambari-scripts/remote-web-update.sh'" >> ~/.bashrc
echo "alias tail-agent='tail -100f /var/log/ambari-agent/ambari-agent.log'" >> ~/.bashrc
echo "alias tail-server='tail -100f /var/log/ambari-server/ambari-server.log'" >> ~/.bashrc
echo "AMBARI=/osx/src/apache/ambari" >> ~/.bashrc

if [ "$stockInstall" = true ] ; then
  exit 0
fi

echo '${ambariVersion}' > /var/lib/ambari-agent/data/version

echo "-*- ${BLUE}Removing installed stacks which came with the agents...${NC}"
rm -rf /var/lib/ambari-agent/cache/stacks

/osx/ambari-scripts/agent-update.sh

# clean yum in prep for cluster install
yum clean all

# setup python debugging using gdb-heap
setupPythonDebugging() {
  cd
  sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Debuginfo.repo
  yum clean all
  yum install -y gdb python-debuginfo
  yum install -y yum-utils

  debuginfo-install -y yu
  debuginfo-install -y keyutils-libs-1.4-4.el6.x86_64 krb5-libs-1.10.3-10.el6_4.2.x86_64 libcom_err-1.41.12-14.el6.x86_64 libffi-3.0.5-3.2.el6.x86_64 libselinux-2.0.94-5.3.el6.x86_64 libuuid-2.17.2-12.9.el6.x86_64 ncurses-libs-5.7-3.20090208.el6.x86_64
  debuginfo-install -y expat-2.0.1-11.el6_2.x86_64 libffi-3.0.5-3.2.el6.x86_64 openssl-1.0.1e-48.el6_8.1.x86_64 readline-6.0-4.el6.x86_64 zlib-1.2.3-29.el6.x86_64

  yum install -y ncurses*
  yum install -y pygtk2
  wget ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/openttdcoop/CentOS_CentOS-6/x86_64/python-ply-3.4-53.1.x86_64.rpm
  yum install -y python-ply-3.4-53.1.x86_64.rpm

  yum install -y python-devel
  yum install -y dbus-python*
  yum install -y dbus-glib*

  # gdb-heap
  yum install -y git
  git config --global user.name vagrant
  git config --global http.sslverify false
  git clone git://git.fedorahosted.org/git/gdb-heap.git
  export PYTHONPATH=$PYTHONPATH:~/gdb-heap

  # gdb python <pid>
  # python import gdb-heap
  # heap
}

source ~/.bashrc

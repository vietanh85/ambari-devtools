#!/bin/sh
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/common-include-vagrant.sh"

ambariServerHost=$vagrantPrefix"01.ambari.apache.org"
if [ "$HOSTNAME" != $ambariServerHost ]; then
  printf "\n${BLUE}-*- Nothing to do on $HOSTNAME ${NC}\n"
  exit 0;
fi

# Install packages
printf "\n${BLUE}-*- Installing Kerberos Packages... ${NC}\n"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y krb5-kdc krb5-admin-server krb5-user krb5-config rng-tools

service krb5-kdc start
service krb5-admin-server start

# #################################
# Assming default configuration!!!!
# #################################

# Create krb5.conf file
HOSTNAME=`hostname`
REALM="EXAMPLE.COM"
printf "\n${BLUE}-*- Creating krb5.conf file, assuming KDC host is ${HOSTNAME} and realm is ${REALM} ${NC}\n"
cat >/etc/krb5.conf <<EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 default_realm = ${REALM}
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true

[realms]
 ${REALM} = {
  kdc = ${HOSTNAME}
  admin_server = ${HOSTNAME}
 }

[domain_realm]
 .${HOSTNAME} = ${REALM}
 ${HOSTNAME} = ${REALM}
EOF

printf "\n${BLUE}-*- Creating kdc.conf file, assuming realm is ${REALM} ${NC}\n"
cat >/etc/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}	*
EOF

# Create KDC database
printf "\n${BLUE}-*- Created KDC database, this could take some time ${NC}\n"
echo "HRNGDEVICE=/dev/uransom" > /etc/default/rng-tools
/etc/init.d/rng-tools start
mkdir -p /etc/krb5kdc
kdb5_util create -s -P hadoop

# Create admistrative user
printf "\n${BLUE}-*- Creating administriative account: ${NC}\n"
printf "  principal:  admin/admin"
printf "  password:   hadoop"
kadmin.local -q 'addprinc -pw hadoop admin/admin'

update-rc.d krb5-kdc defaults
update-rc.d krb5-admin-server defaults

# Starting services
printf "\n${BLUE}-*- Starting Services... ${NC}\n"
service krb5-kdc start
service krb5-admin-server start

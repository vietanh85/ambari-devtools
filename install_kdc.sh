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

yum install -y krb5-server krb5-libs krb5-workstation

# #################################
# Assming default configuration!!!!
# #################################
REALM="EXAMPLE.COM"

# Create krb5.conf file
HOSTNAME=`hostname`
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

# Create kdam5.aclfile
printf "\n${BLUE}-*- Creating kadm5.acl file, realm is ${REALM} ${NC}\n"
cat >/var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@${REALM}    *
EOF

# Create KDC database
printf "\n${BLUE}-*- Created KDC database, this could take some time ${NC}\n"
kdb5_util create -s -P hadoop

# Create admistrative user
printf "\n${BLUE}-*- Creating administriative account: ${NC}\n"
printf "  principal:  admin/admin\n"
printf "  password:   hadoop\n"
kadmin.local -q 'addprinc -pw hadoop admin/admin'

# Starting services
printf "\n${BLUE}-*- Starting Services... ${NC}\n"
service krb5kdc start
service kadmin start

chkconfig krb5kdc on
chkconfig kadmin on

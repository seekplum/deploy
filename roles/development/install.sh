#!/usr/bin/env bash

set -x

docker stop ldap ldapadmin gerrit > /dev/null 2>&1 || echo "stop container"
docker rm ldap ldapadmin gerrit > /dev/null 2>&1 || echo "delete container"

set -e

export LDAP_SERVER_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | grep -v "172." | grep -v "10.244" | awk '{print $2}' | cut -d":" -f 2)
export VOLUMES_ROOT="/tmp/data"

rm -rf ${VOLUMES_ROOT}


docker run -d  \
    -p 389:389  \
    -p 636:636  \
    --network bridge  \
    --hostname openldap-host  \
    -v ${VOLUMES_ROOT}/slapd/database:/var/lib/ldap  \
    -v ${VOLUMES_ROOT}/slapd/config:/etc/ldap/slapd.d  \
    -e LDAP_ORGANISATION='seekplum.io'  \
    -e LDAP_DOMAIN='seekplum.io'  \
    -e LDAP_ADMIN_PASSWORD='seekplum'  \
    -e LDAP_TLS='false'  \
    -e LDAP_READONLY_USER='true'  \
    -e LDAP_READONLY_USER_USERNAME='guest'  \
    -e LDAP_READONLY_USER_PASSWORD='123456'  \
    --name ldap  \
    osixia/openldap:1.1.9

sleep 2

# 创建用户组
ldapadd -c -h ${LDAP_SERVER_IP} -p 389 -w seekplum -D 'cn=admin,dc=seekplum,dc=io' -f conf/ldap/users.ldif

# 创建用户
bash bin/ldap.sh create zhangsan 123456 张三
bash bin/ldap.sh create lisi 123456 李四

# 检查用户名密码是否正确
ldapwhoami -h ${LDAP_SERVER_IP} -p 389 -D 'cn=admin,dc=seekplum,dc=io' -w seekplum
ldapwhoami -h ${LDAP_SERVER_IP} -p 389 -D 'cn=guest,dc=seekplum,dc=io' -w 123456
ldapwhoami -h ${LDAP_SERVER_IP} -p 389 -D 'cn=hjd,ou=users,dc=seekplum,dc=io' -w 123456
ldapwhoami -h ${LDAP_SERVER_IP} -p 389 -D 'cn=zhangsan,ou=users,dc=seekplum,dc=io' -w 123456
ldapwhoami -h ${LDAP_SERVER_IP} -p 389 -D 'cn=lisi,ou=users,dc=seekplum,dc=io' -w 123456

docker run -d  \
    --privileged  \
    -p 8089:80  \
    --link ldap:ldap  \
    -e PHPLDAPADMIN_LDAP_HOSTS=ldap  \
    -e PHPLDAPADMIN_HTTPS=false  \
    --name ldapadmin  \
    osixia/phpldapadmin
    
docker run -d \
    --name gerrit \
    -p 8088:8080 \
    -p 29418:29418 \
    -v ${VOLUMES_ROOT}/gerrit:/var/gerrit/review_site \
    -e WEBURL=http://${LDAP_SERVER_IP}:8088 \
    -e GITWEB_TYPE=gitiles \
    -e AUTH_TYPE=LDAP \
    -e  LDAP_SERVER=ldap://${LDAP_SERVER_IP} \
    -e LDAP_ACCOUNTBASE='dc=seekplum,dc=io' \
    -e LDAP_ACCOUNTPATTERN='(cn=${username})' \
    -e LDAP_ACCOUNTSSHUSERNAME='${cn}' \
    -e LDAP_ACCOUNTFULLNAME='${sn}' \
    -e LDAP_USERNAME='cn=guest,dc=seekplum,dc=io' \
    -e LDAP_PASSWORD='123456' \
    -e GERRIT_INIT_ARGS='--install-plugin=download-commands' \
    openfrontier/gerrit

set +e

gerrit_code=0
count=0
while [ ${gerrit_code} -ne 200 ]
    do
        let "gerrit_code=$(curl -I -m 10 -o /dev/null -s -w %{http_code} http://${LDAP_SERVER_IP}:8088)"
        sleep 1
        let "count++"
    done

echo -e "\nhttp://${LDAP_SERVER_IP}:8088"

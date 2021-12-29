#!/usr/bin/env bash

set -x

docker-compose down --remove-orphans -v

docker stop ldap ldapadmin gerrit > /dev/null 2>&1 || echo "stop container"
docker rm -v ldap ldapadmin gerrit > /dev/null 2>&1 || echo "delete container"

set -e

file_path="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
num="$(python -c 'import random;print(random.randint(11, 99))')"

# export LDAP_SERVER_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | grep -v "172." | grep -v "10.244" | awk '{print $2}' | cut -d":" -f 2 | head -n 1)
[[ -z ${LDAP_SERVER_IP} ]] && export LDAP_SERVER_IP="127.0.0.1"

export VOLUMES_ROOT="${file_path}/dev-data${num}"

sudo rm -rf ${file_path}/dev-data*


docker run -d  \
    -p 389:389  \
    -p 636:636  \
    -v ${VOLUMES_ROOT}/slapd/database:/var/lib/ldap  \
    -v ${VOLUMES_ROOT}/slapd/config:/etc/ldap/slapd.d  \
    -e LDAP_ORGANISATION='seekplum.io'  \
    -e LDAP_DOMAIN='seekplum.io'  \
    -e LDAP_ADMIN_PASSWORD='admin@123!'  \
    -e LDAP_TLS='false'  \
    -e LDAP_READONLY_USER='true'  \
    -e LDAP_READONLY_USER_USERNAME='guest'  \
    -e LDAP_READONLY_USER_PASSWORD='guest@123!'  \
    --name ldap  \
    osixia/openldap:1.3.0 \
    --copy-service

sleep 5

# 创建用户组, -c 选项是忽略所有错误，继续执行
ldapadd -c -h localhost -p 389 -w admin@123! -D 'cn=admin,dc=seekplum,dc=io' -f conf/ldap/users.ldif || echo "goups exists"

# 创建用户
bash bin/ldap.sh create zhangsan zhangsan@123! 张三
bash bin/ldap.sh create lisi lisi@123! 李四

# 检查用户名密码是否正确
ldapwhoami -h localhost -p 389 -D 'cn=admin,dc=seekplum,dc=io' -w admin@123!
ldapwhoami -h localhost -p 389 -D 'cn=guest,dc=seekplum,dc=io' -w guest@123!
ldapwhoami -h localhost -p 389 -D 'cn=hjd,ou=users,dc=seekplum,dc=io' -w hjd@123!
ldapwhoami -h localhost -p 389 -D 'cn=zhangsan,ou=users,dc=seekplum,dc=io' -w zhangsan@123!
ldapwhoami -h localhost -p 389 -D 'cn=lisi,ou=users,dc=seekplum,dc=io' -w lisi@123!

docker run -d  \
    --privileged  \
    -p 8089:80  \
    --link ldap:ldap  \
    -e PHPLDAPADMIN_LDAP_HOSTS=ldap  \
    -e PHPLDAPADMIN_HTTPS=false  \
    --name ldapadmin  \
    osixia/phpldapadmin:0.9.0

# 查看h2数据库
# java -cp h2-1.3.176.jar org.h2.tools.Server -web -webAllowOthers -tcp -tcpAllowOthers -browser
# LDAP_USERNAME 必须是 LDAP_READONLY_USER_USERNAME (guest)
docker run -d \
    --name gerrit \
    -p 8088:8080 \
    -p 8087:8082 \
    -p 29418:29418 \
    -v ${VOLUMES_ROOT}/gerrit:/var/gerrit/review_site \
    --link ldap:ldap \
    -e WEBURL=http://${LDAP_SERVER_IP}:8088 \
    -e GITWEB_TYPE=gitiles \
    -e AUTH_TYPE=LDAP \
    -e LDAP_SERVER=ldap://ldap \
    -e LDAP_ACCOUNTBASE='dc=seekplum,dc=io' \
    -e LDAP_ACCOUNTPATTERN='(cn=${username})' \
    -e LDAP_ACCOUNTSSHUSERNAME='${cn}' \
    -e LDAP_ACCOUNTFULLNAME='${sn}' \
    -e LDAP_USERNAME='cn=guest,dc=seekplum,dc=io' \
    -e LDAP_PASSWORD='guest@123!' \
    -e GERRIT_INIT_ARGS='--install-plugin=download-commands' \
    -e INITIAL_ADMIN_USER=admin \
    -e INITIAL_ADMIN_PASSWORD=admin \
    openfrontier/gerrit:3.0.0

set +e

gerrit_code=0
count=0
while [ ${gerrit_code} -ne 200 ]
    do
        let "gerrit_code=$(curl -I -m 10 -o /dev/null -s -w %{http_code} http://localhost:8088)"
        sleep 1
        let "count++"
    done

echo "count: ${count}"
echo -e "\nhttp://${LDAP_SERVER_IP}:8088"

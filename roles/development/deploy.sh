#!/usr/bin/env bash

set -xe

source ./.env

docker-compose down

# 删除数据
test -d ${VOLUMES_ROOT} && rm -rf ${VOLUMES_ROOT} || echo "${VOLUMES_ROOT} not exists"

docker-compose up -d

# 创建用户
docker-compose exec ldap ldapadd -c -H ldap://ldap-host -w seekplum -D 'cn=admin,dc=seekplum,dc=io' -f /tmp/users.ldif
docker-compose exec ldap bash /tmp/ldap.sh create zhangsan 123456 张三
docker-compose exec ldap bash /tmp/ldap.sh create lisi 123456 李四

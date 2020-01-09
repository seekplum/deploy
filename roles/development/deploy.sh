#!/usr/bin/env bash

set -xe

source ./.env

docker-compose down

if [[ "$1" == "clear_volumes" ]]; then
    # 删除数据
    test -d ${VOLUMES_ROOT} && rm -rf ${VOLUMES_ROOT} || echo "${VOLUMES_ROOT} not exists"
fi


docker-compose up -d
#docker-compose up -d ldap ldapadmin gerrit gitea2 gitea nginx

if [[ "$1" == "clear_volumes" ]]; then
    # 创建用户
    docker-compose exec ldap ldapadd -c -H ldap://ldap-host -w seekplum -D 'cn=admin,dc=seekplum,dc=io' -f /tmp/users.ldif
    docker-compose exec ldap bash /tmp/ldap.sh create zhangsan 123456 张三
    docker-compose exec ldap bash /tmp/ldap.sh create lisi 123456 李四

    # 停止drone
    docker-compose stop drone-agent drone-server
    docker-compose rm -f -v drone-agent drone-server

    echo "1.在 gitea 的 hjd 用户的 设置 -> 应用 中创建 OAuth2 应用程序, 重定向URI为 http://drone.seekplum.com/login"
    echo "2.修改 .env 中的 DRONE_GITEA_CLIENT_ID、DRONE_GITEA_CLIENT_SECRET 变量"
    echo "3.执行 docker-compose up -d drone-server drone-agent"
fi

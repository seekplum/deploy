#!/usr/bin/env bash

set -e

file_path="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

ENV_FILE='.env'
# 从 .env 中获取变量，需要和 .env 中保持一致
# VOLUMES_ROOT=`grep "VOLUMES_ROOT" ${ENV_FILE} | cut -d"=" -f2`
VOLUMES_ROOT=~/data/develop
CLEAR_VOLUMES="clear_volumes"

MIN_DOCKER_VERSION='17.05.0'
MIN_COMPOSE_VERSION='1.17.0'
MIN_RAM=3072 # MB

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
COMPOSE_VERSION=$(docker-compose --version | sed 's/docker-compose version \(.\{1,\}\),.*/\1/')
RAM_AVAILABLE_IN_DOCKER=$(docker run --rm busybox free -m 2>/dev/null | awk '/Mem/ {print $2}');

# Compare dot-separated strings - function below is inspired by https://stackoverflow.com/a/37939589/808368
function ver () { echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'; }

function pre_check() {
    if [[ $(ver ${DOCKER_VERSION}) -lt $(ver ${MIN_DOCKER_VERSION}) ]]; then
        echo "FAIL: Expected minimum Docker version to be $MIN_DOCKER_VERSION but found $DOCKER_VERSION"
        exit -1
    fi

    if [[ $(ver ${COMPOSE_VERSION}) -lt $(ver ${MIN_COMPOSE_VERSION}) ]]; then
        echo "FAIL: Expected minimum docker-compose version to be $MIN_COMPOSE_VERSION but found $COMPOSE_VERSION"
        exit -1
    fi

    if [[ "$RAM_AVAILABLE_IN_DOCKER" -lt "$MIN_RAM" ]]; then
        echo "FAIL: Expected minimum RAM available to Docker to be $MIN_RAM MB but found $RAM_AVAILABLE_IN_DOCKER MB"
        exit -1
    fi
}

function replace_secret() {
    if [[ "`uname`" = "Darwin" ]]; then
        sed -i "" -e 's/^SENTRY_SECRET_KEY=.*$/SENTRY_SECRET_KEY='"$1"'/' ${ENV_FILE}
    else
        sed -i -e 's/^SENTRY_SECRET_KEY=.*$/SENTRY_SECRET_KEY='"$1"'/' ${ENV_FILE}
    fi;
}

function compose_up() {
    for name in "$@"
    do
        scp ${file_path}/conf/nginx/.conf.d/${name}.conf ${file_path}/conf/nginx/conf.d
        docker-compose up -d ${name}
    done
}

function deploy_sentry() {
    # sentry 目录的内容来自 https://github.com/getsentry/onpremise
    # 构建镜像
    docker-compose build

    # 生成密钥
    # 注意！！！这一步操作后，需要把输出的密钥字符串写入到 .env `SENTRY_SECRET_KEY` 配置项中
    SECRET_KEY=$(docker-compose run --rm sentry-web config generate-secret-key 2> /dev/null | tail -n1 | sed -e 's/[\/&]/\\&/g')
    echo "SENTRY_SECRET_KEY: ${SECRET_KEY}"
    replace_secret ${SECRET_KEY}

    # 等待 postgres 服务启动完成
    sleep 10

    # 安装 sentry 并执行数据库迁移
    docker-compose run --rm sentry-web upgrade --noinput

    # 启动Sentry服务
    compose_up sentry-web
    docker-compose up -d cron worker
    docker-compose exec nginx nginx -s reload

    # 创建管理员用户
    docker-compose run --rm sentry-web createuser --email admin@qq.com --password seekplum --superuser
}

function uninstall() {
    find ${file_path}/conf/nginx/conf.d/* | grep -v -E "0-ws-prepare.conf|default.conf" | xargs sudo rm -f

    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        docker-compose down --remove-orphans -v
        # 删除数据
        if [[ -d "${VOLUMES_ROOT}" ]]; then
            sudo rm -rf "${VOLUMES_ROOT}"
        fi
    else
        docker-compose down
    fi
}

function create_user() {
    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        # 创建用户
        docker-compose exec ldap ldapadd -c -H ldap://ldap -w seekplum -D 'cn=admin,dc=seekplum,dc=io' -f /tmp/users.ldif
        docker-compose exec ldap bash /tmp/ldap.sh create zhangsan 123456 张三
        docker-compose exec ldap bash /tmp/ldap.sh create lisi 123456 李四
    fi
}

function drone_server() {
    compose_up drone-server
    docker-compose up -d drone-agent
    docker-compose exec nginx nginx -s reload
}

function deploy_api() {
    compose_up api
    docker-compose exec nginx nginx -s reload
    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        docker-compose run --rm init_blog
    fi
}

function deploy_blog() {
    compose_up blog
    docker-compose exec nginx nginx -s reload
}

function post_deploy() {
    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        echo "0.执行 bash -x $0 create_user 创建用户"
    fi
    echo "1.在 gitea 的 hjd 用户的 设置 -> 应用 中创建 OAuth2 应用程序, 重定向URI为 http://drone.seekplum.top/login"
    echo "2.修改 ${ENV_FILE} 中的 DRONE_GITEA_CLIENT_ID、DRONE_GITEA_CLIENT_SECRET 变量"
    echo "3.执行 bash -x $0 drone_server 部署 Drone"
    echo "4.按照说明文档更新 Jenkins 配置"
}

function install() {
    mkdir -p ${VOLUMES_ROOT}

    compose_up ldapadmin gerrit gitea jenkins
    # jenkins的运行用户是 1000:1000, 但默认目录权限是 root:root
    sudo chown -R $(whoami):$(groups | awk '{print $1}') ${VOLUMES_ROOT}/jenkins
    docker-compose up -d ldap nginx
    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        docker-compose run --rm gitea2
    fi
}

function print_help() {
    echo "Usage: bash $0 {pre_check|install|uninstall|create_user|deploy_sentry|deploy_blog|deploy_api|deploy}"
    echo "e.g: $0 uninstall ${CLEAR_VOLUMES}"
    echo "e.g: $0 pre_check"
    echo "e.g: $0 install ${CLEAR_VOLUMES}"
    echo "e.g: $0 crate_user"
    echo "e.g: $0 deploy_sentry"
    echo "e.g: $0 deploy_blog"
    echo "e.g: $0 deploy_api"
    echo "e.g: $0 deploy"
}

start_time=$(date +%s)

case "$1" in
  pre_check)
        pre_check
        ;;
  uninstall)
        uninstall ${@:2}
        ;;
  install)
        install ${@:2}
        post_deploy ${@:2}
        ;;
  create_user)
        create_user ${@:2}
        ;;
  drone_server)
        drone_server
        ;;
  deploy_sentry)
        pre_check
        deploy_sentry
        ;;
  deploy_blog)
        deploy_blog
        ;;
  deploy_api)
        deploy_api ${@:2}
        ;;
  deploy)
        uninstall ${@:2}
        install ${@:2}
        create_user ${@:2}
        # sentry 需要的配置比较高，暂时不部署
        # deploy_sentry
        deploy_api ${@:2}
        deploy_blog
        post_deploy
        ;;
  "")
  # -h|--help)
        print_help  # 参数为空时执行
        ;;
  *)  # 匹配都失败执行
        print_help
esac

end_time=$(date +%s)
use_time=$((end_time - start_time))
echo "*******************************************************************************"
echo "Use time: ${use_time}s"
echo "*******************************************************************************"

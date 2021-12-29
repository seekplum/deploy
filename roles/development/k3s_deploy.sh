#!/usr/bin/env bash

set -e

ROOT_DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

CLEAR_VOLUMES="clear_volumes"
NAMESPACE="seekplum"
ROOT_K3S="${ROOT_DIR}/k3s"
ROOT_K3S_ENV="${ROOT_K3S}/env"
ROOT_K3S_YAML="${ROOT_K3S}/yaml"
DEFAULT_SERVERS=(ldap ldapadmin gerrit)

function print_error () {
    echo -e "\033[31m$1\033[0m"
}

function print_warning () {
    echo -e "\033[33m$1\033[0m"
}

function create_namespace() {
    cd "${ROOT_K3S}"
    kubectl apply -f namespace.json || print_warning "namespace already exists"
}

function gen_ca() {
    DH_PARAM_PATH="${ROOT_DIR}/data/acme/.lego/certificates/dhparam.pem"

    test -f "${DH_PARAM_PATH}" || openssl dhparam -dsaparam -out ${DH_PARAM_PATH} 4096

    kubectl delete -f "${ROOT_K3S_YAML}"/acme.yml "${ROOT_K3S_ENV}"/acme.yml || print_warning "delete acme.yml"
    kubectl -n ${NAMESPACE} delete job acme || print_warning "delete acme job"

    kubectl apply -f "${ROOT_K3S_ENV}"/acme.yml
    kubectl apply -f "${ROOT_K3S_YAML}"/acme.yml
    # kubectl replace --force -f "${ROOT_K3S_YAML}"/acme.yml

    acme_pod_name=$(kubectl get pods -n ${NAMESPACE} -l job-name=acme -o custom-columns=NAME:.metadata.name --no-headers | head -n 1)

    kubectl -n ${NAMESPACE} describe pod ${acme_pod_name}
    kubectl -n ${NAMESPACE} logs -f ${acme_pod_name}
}

function uninstall() {

    cd "${ROOT_K3S_YAML}"
    kubectl delete --force -f . > /dev/null 2>&1 || print_warning "delete configmap"

    cd "${ROOT_K3S_ENV}"
    kubectl delete --force -f  > /dev/null 2>&1 || print_warning "delete pod"

    cd "${ROOT_K3S}"
    kubectl delete -f namespace.json > /dev/null 2>&1 || print_warning "delete namespanme"

    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        sudo rm -rf /root/data/develop
    fi

    find ${ROOT_DIR}/conf/nginx/conf.d/* | grep -v -E "0-ws-prepare.conf|default.conf" | xargs sudo rm -f
}

function create_user() {
    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        ldap_pod_name=$(kubectl get pods -n ${NAMESPACE} -l app=ldap -o custom-columns=NAME:.metadata.name --no-headers | head -n 1)
        # 创建用户
        kubectl -n ${NAMESPACE} exec ${ldap_pod_name} -- ldapadd -c -H ldap://localhost -w seekplum -D 'cn=admin,dc=seekplum,dc=io' -f /tmp/users.ldif
        kubectl -n ${NAMESPACE} exec ${ldap_pod_name} -- bash /tmp/ldap.sh create zhangsan 123456 张三
        kubectl -n ${NAMESPACE} exec ${ldap_pod_name} -- bash /tmp/ldap.sh create lisi 123456 李四
    fi
}

function whoami() {
    kubectl delete -f "${ROOT_K3S_YAML}"/whoami.yml > /dev/null 2>&1 || print_warning "delete whoami"
    if [[ "$1" != "remove" ]]; then
        kubectl apply -f "${ROOT_K3S_YAML}"/whoami.yml
        kubectl get pods -o wide --show-labels
    fi
}

function post_deploy() {
    if [[ "$1" == "${CLEAR_VOLUMES}" ]]; then
        echo "0.执行 bash -x $0 create_user 创建用户"
    fi
    echo "1.按照说明文档更新 Jenkins 配置"
}

function install() {
    mkdir -p /root/data/develop

    SERVERS=$*
    for name in ${SERVERS}; do
        CONF_PATH="${ROOT_DIR}/conf/nginx/.conf.d/${name}.conf"
        test -f ${CONF_PATH} && scp ${CONF_PATH} ${ROOT_DIR}/conf/nginx/conf.d || print_warning "${name}.conf not exists"
        test -f "${ROOT_K3S_ENV}/${name}".yml && kubectl apply -f "${ROOT_K3S_ENV}/${name}".yml
        if [[ "${name}" == "jenkins" ]]; then
            mkdir -p /root/data/develop/jenkins
            sudo chown -R 1000:1000 /root/data/develop/jenkins
        fi
        kubectl apply -f "${ROOT_K3S_YAML}/${name}".yml
    done
    kubectl rollout restart deployments -n ${NAMESPACE}
    for name in ${SERVERS}; do
        kubectl rollout status deployment/"${name}" -n ${NAMESPACE}
    done
    kubectl -n ${NAMESPACE} get pods -o wide --show-labels
}
}

function print_help() {
    echo "Usage: bash $0 {install|deploy|uninstall|create_user}"
    echo "e.g: $0 uninstall ${CLEAR_VOLUMES}"
    echo "e.g: $0 install ${CLEAR_VOLUMES}"
    echo "e.g: $0 crate_user"
    echo "e.g: $0 deploy"
}


start_time=$(date +%s)

case "$1" in
  uninstall)
        uninstall ${@:2}
        ;;
  install)
        create_namespace
        install ${DEFAULT_SERVERS[@]}
        post_deploy ${@:2}
        ;;
  create_namespace)
        create_namespace ${@:2}
        ;;
  gen_ca)
        gen_ca ${@:2}
        ;;
  create_user)
        create_user ${@:2}
        ;;
  whoami)
        whoami ${@:2}
        ;;
  reinstall)
        install ${@:2}
        ;;
  deploy)
        uninstall ${@:2}
        create_namespace
        install ${DEFAULT_SERVERS[@]}
        create_user ${@:2}
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
print_warning "Use time: ${use_time}s"
echo "*******************************************************************************"

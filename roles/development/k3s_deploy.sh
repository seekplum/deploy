#!/usr/bin/env bash

set -e

ROOT_DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

CLEAR_VOLUMES="clear_volumes"
NAMESPACE="seekplum"
ROOT_K3S="${ROOT_DIR}/k3s"
ROOT_K3S_ENV="${ROOT_K3S}/env"
ROOT_K3S_YAML="${ROOT_K3S}/yaml"
ROOT_K3S_SYSTEM="${ROOT_K3S}/system"
DEFAULT_SERVERS=(whoami ldap ldapadmin gerrit jenkins)
DATA_DIR="/root/data/develop"

services=()
is_clear_volumes=0

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
    if [[ ${#services[@]} -eq 0 ]]; then
        cd "${ROOT_K3S_YAML}"
        kubectl delete --force -f . > /dev/null 2>&1 || print_warning "delete configmap"

        cd "${ROOT_K3S_ENV}"
        kubectl delete --force -f  > /dev/null 2>&1 || print_warning "delete pod"

        cd "${ROOT_K3S}"
        kubectl delete -f namespace.json > /dev/null 2>&1 || print_warning "delete namespanme"

        if [[ "${is_clear_volumes}" == "1" ]]; then
            [ -d ${DATA_DIR} ] && sudo rm -rf ${DATA_DIR} || print_warning "delete data"
        fi

        find ${ROOT_DIR}/conf/nginx/conf.d/* | grep -v -E "0-ws-prepare.conf|default.conf" | xargs sudo rm -f
    else
        for name in ${services[@]}; do
            test -f "${ROOT_K3S_ENV}/${name}".yml && kubectl delete --force -f "${ROOT_K3S_ENV}/${name}".yml || print_warning "delete configmap"
            kubectl delete --force -f "${ROOT_K3S_YAML}/${name}".yml > /dev/null 2>&1 || print_warning "delete pod"
        done
    fi
}

function create_user() {
    if [[ "${is_clear_volumes}" == "1" ]]; then
        ldap_pod_name=$(kubectl get pods -n ${NAMESPACE} -l app=ldap -o custom-columns=NAME:.metadata.name --no-headers | head -n 1)
        # 创建用户
        kubectl -n ${NAMESPACE} exec ${ldap_pod_name} -- ldapadd -c -H ldap://localhost -w admin@123! -D 'cn=admin,dc=seekplum,dc=io' -f /tmp/users.ldif || print_warning "goups exists"
        kubectl -n ${NAMESPACE} exec ${ldap_pod_name} -- bash /tmp/ldap.sh create zhangsan zhangsan@123! 张三
        kubectl -n ${NAMESPACE} exec ${ldap_pod_name} -- bash /tmp/ldap.sh create lisi lisi@123! 李四
    fi
}

function post_deploy() {
    if [[ "${is_clear_volumes}" != "1" ]]; then
        echo "0.执行 bash -x $0 create_user 创建用户"
    fi
    echo "1.按照说明文档更新 Jenkins 配置"
}

function install() {
    mkdir -p ${DATA_DIR}
    for name in ${services[@]}; do
        test -f "${ROOT_K3S_ENV}/${name}".yml && kubectl apply -f "${ROOT_K3S_ENV}/${name}".yml
        if [[ "${name}" == "jenkins" ]]; then
            mkdir -p ${DATA_DIR}/jenkins
            sudo chown -R 1000:1000 ${DATA_DIR}/jenkins
        fi
        if [[ "${name}" == "gerrit" ]]; then
            mkdir -p ${DATA_DIR}/gerrit/plugins
            scp ${ROOT_DIR}/data/gerrit/plugins/login-redirect.jar ${DATA_DIR}/gerrit/plugins
        fi
        kubectl apply -f "${ROOT_K3S_YAML}/${name}".yml
    done
    for name in ${services[@]}; do
        kubectl rollout restart deployment/"${name}" -n ${NAMESPACE}
        kubectl rollout status deployment/"${name}" -n ${NAMESPACE}
    done
    kubectl -n ${NAMESPACE} get pods -o wide --show-labels
}

function dashboard() {
    kubectl delete -f "${ROOT_K3S_SYSTEM}"/ingress.yml > /dev/null 2>&1 || print_warning "delete ingress"
    kubectl delete -f "${ROOT_K3S_SYSTEM}"/traefik-dashboard.yaml > /dev/null 2>&1 || print_warning "delete traefik-dashboard"
    # kubectl -n kube-system delete IngressRoute traefik-dashboard || print_warning "delete IngressRoute"
    sudo rm -f /var/lib/rancher/k3s/server/manifests/traefik-config.yaml

    if [[ "${!#}" != "remove" ]]; then
        scp ${ROOT_K3S_SYSTEM}/traefik-config.yaml /var/lib/rancher/k3s/server/manifests/traefik-config.yaml

        kubectl apply -f "${ROOT_K3S_SYSTEM}"/ingress.yml
        kubectl apply -f "${ROOT_K3S_SYSTEM}"/traefik-dashboard.yaml
        kubectl get ingress -A && kubectl get IngressRoute -A
        # kubectl -n kube-system logs -f $(kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik -o custom-columns=NAME:.metadata.name --no-headers | head -n 1)
        # helm -n kube-system get values traefik
    fi
}

function print_help() {
    echo "Usage: bash $0 {install|deploy|uninstall|create_user}"
    echo "e.g: $0 uninstall ${CLEAR_VOLUMES}"
    echo "e.g: $0 install ${CLEAR_VOLUMES}"
    echo "e.g: $0 crate_user"
    echo "e.g: $0 deploy"
}

function parse_params() {
    if [ $# -eq 0 ]; then
        services=${DEFAULT_SERVERS[@]}
    else
        for param in $*; do
            if [[ "${param}" == "${CLEAR_VOLUMES}" ]]; then
                is_clear_volumes=1
            else
                services+=("${param}")
            fi
        done
    fi
}

parse_params ${@:2}

start_time=$(date +%s)

case "$1" in
  uninstall)
        uninstall
        ;;
  install)
        create_namespace
        install
        post_deploy
        ;;
  create_namespace)
        create_namespace
        ;;
  gen_ca)
        create_namespace
        gen_ca
        ;;
  create_user)
        create_user
        ;;
  reinstall)
        install
        ;;
  deploy)
        uninstall
        create_namespace
        install
        create_user
        post_deploy
        ;;
  dashboard)
        dashboard ${@:2}
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

#!/usr/bin/env bash

set -e

ROOT_DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

ROOT_K3S="${ROOT_DIR}/k3s"
ROOT_K3S_YAML="${ROOT_K3S}/yaml"
ROOT_K3S_SYSTEM="${ROOT_K3S}/system"

if [[ -n "$2" ]]; then
    namespace=$2
else
    namespace="seekplum"
fi
if [[ -n "$3" ]]; then
    cert_name=$3
else
    cert_name="cert-seekplum-top"
fi

function print_error () {
    echo -e "\033[31m$1\033[0m"
}

function print_warning () {
    echo -e "\033[33m$1\033[0m"
}


function uninstall_tls() {
    kubectl delete -f "${ROOT_K3S_SYSTEM}/cert-manager.yaml" || print_warning "delete cert-manager"
    kubectl delete -f "${ROOT_K3S_SYSTEM}"/letsencrypt-issuer-production.yaml || print_warning "delete letsencrypt production"
    kubectl delete -f "${ROOT_K3S_SYSTEM}"/letsencrypt-issuer-staging.yaml || print_warning "delete letsencrypt staging"
    kubectl delete -f "${ROOT_K3S_SYSTEM}"/le-test-certificate.yaml || print_warning "delete le-test-certificate"
    kubectl delete -f "${ROOT_K3S_YAML}"/ingress.yml || print_warning "delete ingress"

    kubectl -n ${namespace} delete certificates ${cert_name} || print_warning "delete certificates"
    kubectl -n ${namespace} delete secrets "${cert_name}-tls" || print_warning "delete secrets"
}

function logs_tls () {
    echo "namespace: ${namespace}, cert_name: ${cert_name}"
    request_id=$(kubectl -n ${namespace} describe certificates ${cert_name} | grep "${cert_name}-" | grep "CertificateRequest" | awk '{print $9}')
    request_id=${request_id:1:-1}
    [[ -z "${request_id}" ]] && echo "request_id not exists" && exit 1 || echo "request_id: ${request_id}"

    origin_order=$(kubectl -n ${namespace} describe certificaterequest  | grep "order" | grep "${namespace}/${cert_name}-" | head -n 1 | awk '{print $8}')
    [[ -z "${origin_order}" ]] && echo "origin_order not exists" && exit 1 || echo "origin_order: ${origin_order}"

    orders_name=${origin_order:0:-1}
    orders_name=${orders_name##*/}
    [[ -z "${orders_name}" ]] && echo "orders_name not exists" && exit 1 || echo "orders_name: ${orders_name}"

    resource_name=$(kubectl -n ${namespace} describe orders ${orders_name##*/} | grep "${cert_name}-" | grep resource | awk '{print $8}')
    resource_name=${resource_name:1:-1}
    [[ -z "${resource_name}" ]] && echo "resource_name not exists" && exit 1 || echo "resource_name: ${resource_name}"

    kubectl -n ${namespace} describe challenges ${resource_name}
}

function gen_tls() {

    CERT_MANAGER_PATH="${ROOT_K3S_SYSTEM}/cert-manager.yaml"
    test -f "${CERT_MANAGER_PATH}" || curl -fSL --connect-timeout 5 --retry 100 --retry-connrefused --retry-delay 1 --retry-max-time 100 https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml -o ${CERT_MANAGER_PATH}
    kubectl apply -f ${CERT_MANAGER_PATH} > /dev/null 2>&1

    set +e
    num=0
    while [ ${num} -lt 6 ]
        do
            let "num=$(kubectl get all -n cert-manager | grep '1/1' | wc -l)"
            sleep 1
        done
    set -e

    kubectl apply -f "${ROOT_K3S_SYSTEM}"/letsencrypt-issuer-production.yaml
    kubectl apply -f "${ROOT_K3S_SYSTEM}"/letsencrypt-issuer-staging.yaml
    # kubectl apply -f "${ROOT_K3S_SYSTEM}"/le-test-certificate.yaml

    kubectl get clusterissuers && kubectl get certificates -A

    kubectl apply -f "${ROOT_K3S_SYSTEM}"/ingress.yml
    kubectl get ingress -A && kubectl get IngressRoute -A

    kubectl -n ${namespace} get cm,pods,svc,ingress,IngressRoute,certificaterequests.cert-manager.io,clusterissuers,certificates,secrets -o wide

    logs_tls $*
}

start_time=$(date +%s)

case "$1" in
  gen_tls)
        gen_tls ${@:2}
        ;;
  logs_tls)
        logs_tls ${@:2}
        ;;
  uninstall_tls)
        uninstall_tls ${@:2}
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

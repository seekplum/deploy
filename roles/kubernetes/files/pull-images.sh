#!/bin/bash

function print_error() {
    echo -e "\033[31m$1\033[0m"
}

function pull_image() {
    image_name=$1
    result=$(docker pull ${image_name} >/dev/null 2>&1 && echo -n 0 || echo -n 1)
    echo -n "${result}"
}

function main() {
    # aliyun_registry="registry.cn-hangzhou.aliyuncs.com/google_containers"
    aliyun_registry="registry.cn-hangzhou.aliyuncs.com/seekplum"
    k8s_registry="k8s.gcr.io"
    for imageName in $(kubeadm config images list 2> /dev/null); do
        name=${imageName#*/}
        source_name="${name}"
        aliyun_name=${aliyun_registry}/${name}

        result=`pull_image ${aliyun_name}`
        # 拉取失败，尝试修改名称
        if [[ "$result" == "1" && "${name}" != "${name##*/}" ]]; then
            print_error "pull2 ${name} failed, retrying ${name##*/}"
            name="${name##*/}"
            aliyun_name=${aliyun_registry}/${name}

            result=`pull_image ${aliyun_name}`
        fi
        # 还是拉取失败，尝试取消tag，拉取 latest
        if [[ "$result" == "1" && "${name}" != "${name%:*}" ]]; then
            print_error "pull3 ${name} failed, retrying ${name%:*}"
            name="${name%:*}"
            aliyun_name=${aliyun_registry}/${name}
            pull_image ${aliyun_name}
        fi

        if [ "${name}" == "${source_name}" ]; then
            docker tag ${aliyun_name} ${k8s_registry}/${name}
        else
            docker tag ${aliyun_name} ${k8s_registry}/${source_name}
            docker tag ${aliyun_name} ${aliyun_registry}/${source_name}
        fi
        # docker rmi ${aliyun_name}
    done
}

main

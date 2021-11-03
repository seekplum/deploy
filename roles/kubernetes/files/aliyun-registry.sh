#!/bin/bash

set -e

function git_push () {
    imageName=$1
    project=$2
    project_path="/tmp/aliyun-code/${project}"
    rm -rf ${project_path}
    git clone git@code.aliyun.com:1131909224/${project} ${project_path} >/dev/null 2>&1 && cd ${project_path}
    version=${imageName##*:}
    if [[ ${version} != v* ]]; then
        version="v${version}"
    fi
    tag_name="release-${version}"
    echo "${imageName} ${project} ${tag_name}"
    git tag -f ${tag_name} >/dev/null 2>&1 && git checkout ${tag_name} >/dev/null 2>&1
    echo -e "FROM ${imageName}\n" > ${project_path}/Dockerfile
    if [[ $(git status -s | wc -l) != "0" ]]; then
        git config user.email "1131909224@qq.com"
        git config user.name "seekplum"
        git add Dockerfile
        git commit -m "`date +'%Y-%m-%d %H:%M:%S'` Auto Commit" >/dev/null 2>&1
        git push origin ${tag_name}
    else
        echo "There is no change"
    fi
    cd - >/dev/null 2>&1
}

function main() {

    for imageName in $(kubeadm config images list 2> /dev/null); do
        registry=${imageName#*/}
        name="${registry%:*}"
        project="${name%/*}"
        git_push ${imageName} ${project}
    done
}

main

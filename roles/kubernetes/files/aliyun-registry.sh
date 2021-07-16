#!/bin/bash

set -e

function git_push () {
    imageName=$1
    project=$2
    project_path="/tmp/aliyun-code/${project}"
    rm -rf ${project_path}
    echo "${imageName} ${project}"
    git clone git@code.aliyun.com:1131909224/${project} ${project_path}
    cat > ${project_path}/Dockerfile <<EOF
FROM ${imageName}

EOF
    cd ${project_path}
    if [[ $(git status -s | wc -l) != "0" ]]; then
        git config user.email "1131909224@qq.com"
        git config user.name "seekplum"
        git add Dockerfile
        git commit -m "`date +'%Y-%m-%d %H:%M:%S'` Auto Commit"
        git push origin master
    fi
    cd -
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

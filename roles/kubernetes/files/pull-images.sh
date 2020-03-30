#/usr/bin/env bash

for imageName in $(kubeadm config images list 2> /dev/null); do
    # name=$(echo ${imageName} | cut -d"/" -f2)
    name=${imageName#*/}
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/${name}
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/${name} k8s.gcr.io/${name}
    docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/${name}
done

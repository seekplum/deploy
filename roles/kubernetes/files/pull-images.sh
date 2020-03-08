#/usr/bin/env bash

# kubeadm config images list 

images=(
    kube-apiserver:v1.16.7
    kube-controller-manager:v1.16.7
    kube-scheduler:v1.16.7
    kube-proxy:v1.16.7
    pause:3.1
    etcd:3.3.15-0
    coredns:1.6.2
)
for imageName in ${images[@]} ; do
    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
    docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
    docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
done

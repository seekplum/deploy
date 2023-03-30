# 快速搭建开发环境

## 准备环境

* 安装ansible

```bash
sudo pip install ansible -i https://pypi.douban.com/simple/
```

## 适用系统

* `Red Hat` / `CentOS` 7.4
* Ubuntu 16.04.5 LTS
* macOS 10.13+

**注意: 如果是在mac下安装，运行的用户必须是管理员用户，普通用户即使加了 `sudo` 权限也会有问题.**

## 安装软件

* `initialize`: 安装基础软，pip,gcc,rsync,git,wget,screen,tree 等
* `zsh`: 安装zsh终端，并配置oh-my-zsh主题，命令历史提示
* `docker`: 安装docker
* `golang`: 安装golang和govendor
* `nodejs`: 安装npm和nodejs
* `ansible`: 安装ansible
* `install`: 运行所有安装任务
* `uninstall`: 运行所有卸载任务

## 编写 `inventory` 文件

```bash
cat >hosts<<EOF
[common]
192.168.1.5 ansible_ssh_user=root ansible_connection=ssh
127.0.0.1  ansible_ssh_user=seekplum ansible_connection=local

[masters]
192.168.1.5 ansible_ssh_user=root ansible_connection=ssh


[slaves]
192.168.1.6 ansible_ssh_user=root ansible_connection=ssh
192.168.1.7 ansible_ssh_user=root ansible_connection=ssh

EOF
```

## 免密登录

```bash
ssh-copy-id -i ~/.ssh/mykey.pub root@x.x.x.x
```

## 运行playbook

* 执行卸载操作

```bash
ansible-playbook site.yml -i hosts -t uninstall --skip-tags "remove_zsh,remove_docker,remove_nodejs,remove_golang,remove_java,remove_brew,remove_k3s,remove_helm"

ansible-playbook site.yml -i hosts -l common -t common,remove_docker
```

* 执行安装操作

```bash
ansible-playbook site.yml -i hosts -t install --skip-tags "configure,initialize,zsh,python,virtualenv,pyenv,rbenv,docker,golang,java,nodejs,helm,k3s,ansible"

ansible-playbook site.yml -i hosts -l common -t common,docker
```

* kubeadm安装kubernets

```bash
ansible-playbook site.yml -i hosts -t kubernetes --skip-tags "remove_kubeadm,remove_kubeadm_force,kubeadm,join_kubeadm"

ansible-playbook site.yml -i hosts -l masters,slaves -t common,remove_kubeadm
```

* -i: 指定运行的主机, 如 `-i hosts`
* --user: 指定SSH登录的用户名, 如 `--user=seekplum`
* --vault_password_file: ansible-vault 用于加解密SSH登录密码的密码, 如 `--vault_password_file=vault_password`
* --private-key: 指定SSH登录的私钥路径, 如 `--private-key ~/.ssh/id_rsa`
* -t: 指定要运行的tag,多个的话以 `,` 进行分隔, 如 `-t uninstall,install`

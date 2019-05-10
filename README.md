# 快速搭建开发环境

## 适用系统

* `Red Hat` / `CentOS` 7.4

## 安装软件

* `initialize`: 安装基础软，pip,gcc,rsync,git,wget,screen,tree 等
* `zsh`: 安装zsh终端，并配置oh-my-zsh主题，命令历史提示
* `docker`: 安装docker
* `golang`: 安装golang和govendor
* `nodejs`: 安装npm和nodejs
* `ansible`: 安装ansible

## 编写 `inventory` 文件

```bash
cat >hosts<<EOF
[common]
x.x.x.x
EOF
```

## 打通私钥

```bash
ssh-copy-id -i ~/.ssh/seekplum.pub root@x.x.x.x
```

## 运行playbook

* 只运行 `initialize` 相关任务

```bash
ansible-playbook -i hosts site.yml --private-key ~/.ssh/seekplum -t initialize
```

* 运行所有安装任务

```bash
ansible-playbook -i hosts site.yml --private-key ~/.ssh/seekplum -t install
```

* 运行所有卸载任务

```bash
ansible-playbook -i hosts site.yml --private-key ~/.ssh/seekplum -t uninstall
```

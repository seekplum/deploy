# 快速搭建开发环境

## 脚本安装软件

* zsh
* docker
* pip
* ansible
* go

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

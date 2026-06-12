# Ansible Role 维护手册

本文记录本项目 Ansible role 的维护约定和常见故障处理方式。目标是让后续修改 role 时保持可 lint、可重复执行，并避免因为变量作用域、远端环境或 shell 行为导致线上运行失败。

## 维护原则

1. 任务名使用中文

   `roles/*/tasks/` 中所有 `name` 应使用中文说明，方便运行 playbook 时直接读懂进度和失败点。工具名和专有名词可以保留英文，例如 `Docker`、`k3s`、`helm`。

2. 变量按 role 加前缀

   role 内定义或注册的变量必须带 role 前缀，满足 `ansible-lint` 的 `var-naming` 规则。

   | role | 前缀示例 |
   | --- | --- |
   | `common` | `common_home_root`, `common_is_linux_os` |
   | `install` | `install_packages_root`, `install_node_version` |
   | `uninstall` | `uninstall_existing_of_etc_bashrc` |
   | `k3s` | `k3s_helm_version`, `k3s_server_token` |
   | `kubernetes` | `kubernetes_cni_plugins_version`, `kubernetes_kubeadm_token` |

3. 不跨 role 依赖私有变量

   一个 role 不应直接引用另一个业务 role 的私有变量。例如 `k3s` 需要安装 `helm` 和 `stern`，变量应定义在 `roles/k3s/vars/main.yml`，而不是复用 `roles/install/vars/main.yml` 中的 `install_*` 变量。

4. 优先使用模块，谨慎使用 shell

   能用 Ansible 模块时优先用模块，例如：

   - 创建目录用 `ansible.builtin.file`
   - 写固定配置文件用 `ansible.builtin.copy`
   - 管理包用 `ansible.builtin.apt` / `ansible.builtin.dnf`
   - 下载文件用 `ansible.builtin.get_url`

   只有需要管道、重定向、命令替换或 shell 语法时才使用 `ansible.builtin.shell`。

5. shell 管道必须处理 `pipefail`

   带管道的 shell 任务应使用：

   ```yaml
   ansible.builtin.shell: |
     set -o pipefail
     command_a | command_b
   args:
     executable: /bin/bash
   ```

   如果“没有匹配结果”是正常状态，不要用 `grep | awk` 这类会因为 `grep rc=1` 失败的写法。可以改用 `awk` 单命令，例如：

   ```yaml
   ansible.builtin.command: awk '$3 == "swap" {print $1}' /etc/fstab
   ```

6. 所有命令任务都要声明变更语义

   `ansible.builtin.command` 和 `ansible.builtin.shell` 必须设置 `changed_when`，除非任务天然由模块处理幂等。

   - 只读检查：`changed_when: false`
   - 确认会修改系统：`changed_when: true`
   - 允许失败但不中断：使用 `failed_when: false`，不要用 `ignore_errors`

## 目标机器环境变量

不要在 playbook 中使用控制机环境：

```yaml
lookup('env', 'PATH')
lookup('env', 'HOME')
```

这些值来自运行 Ansible 的机器，不一定是目标机器。目标机器的 home 和 PATH 应来自 facts：

```yaml
HOME: "{{ ansible_user_dir | default('') }}"
PATH: "{{ ansible_env.PATH | default('/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin') }}:{{ ansible_user_dir | default('') }}/.local/bin"
```

注意 play 级别的 `environment` 会先作用到 `Gathering Facts`。如果引用 `ansible_user_dir` 或 `ansible_env.PATH`，必须提供 `default(...)`，否则 facts 采集前变量未定义会导致 play 直接失败。

本项目统一由 `roles/common/tasks/common.yml` 获取 facts，`site.yml` 中保持 `gather_facts: false`，避免重复采集。

## Role 边界

### common

`common` 负责收集目标机器 facts，并生成跨 role 使用的公共变量：

- `common_home_root`
- `common_login_user`
- `common_is_linux_os`
- `common_is_centos_os`
- `common_is_ubuntu_os`
- `common_is_mac_os`
- `common_is_master_node`
- `common_is_slaves_node`

其他 role 可以读取这些 `common_*` 变量。

### install

`install` 只维护通用开发环境安装变量，例如 Go、Java、Maven、Node.js、rbenv、virtualenv、Docker。

`install` 不维护 `helm`、`stern`、`k3s` 相关变量。这些变量属于 `k3s` role。

### k3s

`k3s` 自己维护 Kubernetes 辅助工具变量：

- `k3s_helm_version`
- `k3s_helm_package_path_on_linux`
- `k3s_helm_download_url_on_linux`
- `k3s_stern_version`
- `k3s_stern_package_path_on_linux`
- `k3s_stern_download_url_on_linux`

安装 k3s server/agent 的命令包含管道和环境变量赋值，必须使用 `ansible.builtin.shell`，不能使用 `ansible.builtin.command`。

### kubernetes

`kubernetes` 维护 kubeadm 和 CNI 相关变量，例如：

- `kubernetes_cni_plugins_version`
- `kubernetes_cni_plugins_path_on_linux`
- `kubernetes_kubeadm_token`
- `kubernetes_kubeadm_join_token_cmd`

不要使用大写变量名或无 role 前缀的 register/set_fact 变量。

## 常见故障

### 已安装 uv 但任务仍然很慢

原因通常是 Ansible 非登录 shell 没加载用户 shell 配置，导致 `command -v uv` 找不到 `~/.local/bin/uv`，于是重新执行远程安装脚本。

处理方式：

- 使用目标用户 home：`{{ common_home_root }}/.local/bin/uv`
- 在任务内显式补 PATH
- 同时检查 `/usr/local/bin/uv` 和 `/opt/homebrew/bin/uv`

### macOS 已有 App 但 brew cask 报错

`brew install --cask` 在 `/Applications/*.app` 已存在但 brew 未登记时会失败。

处理方式：

- 安装前查询 cask 是否已安装
- 对 `already an App at` 这类错误做明确 `failed_when` 判断
- 不要用笼统的 `ignore_errors`

### 自定义 docker 已存在但仍安装 Docker Desktop

`docker --version` 可能来自 Lima 或 nerdctl 包装器，例如：

```bash
~/.lima/.bin/docker
```

处理方式：

- Docker 检查任务同时判断 `command -v docker` 和 `{{ common_home_root }}/.lima/.bin/docker`
- Docker Desktop 专属配置和重启任务必须先检查 `/Applications/Docker.app`
- 没有 Docker Desktop 时不要执行 `osascript -e 'quit app "Docker"'`

### Maven 解压时报 `${HOME}` 目录不存在

`unarchive.dest` 不会展开 shell 变量。下面这种写法是错误的：

```yaml
MVN_HOME: "${HOME}/packages/apache-maven-3.8.8"
```

应改成目标机器 home：

```yaml
common_mvn_home: "{{ common_home_root }}/packages/apache-maven-3.8.8"
```

并在解压前创建目录，因为 `unarchive.dest` 必须是已存在目录。

### 没有 swap 行导致任务失败

如果使用：

```bash
grep " swap " /etc/fstab | awk '{print $1}'
```

当没有 swap 行时，`grep` 返回 1，配合 `pipefail` 会让任务失败。

应改为：

```yaml
ansible.builtin.command: awk '$3 == "swap" {print $1}' /etc/fstab
changed_when: false
```

stdout 为空时，后续 `replace` 任务通过 `when` 跳过即可。

### shell 语法被 command 当成参数

包含管道、`||`、环境变量赋值的命令不能用 `ansible.builtin.command`。

错误示例：

```yaml
ansible.builtin.command: "{{ k3s_server_cmd }}"
```

如果 `k3s_server_cmd` 内容是：

```bash
curl ... | INSTALL_K3S_VERSION=... sh -s -
```

`|` 会被当成普通参数传给 `curl`，导致 `curl: option - is unknown`。

正确写法：

```yaml
ansible.builtin.shell: |
  set -o pipefail
  {{ k3s_server_cmd }}
args:
  executable: /bin/bash
```

### helm repo remove/list 阻断安装

`helm repo remove stable || true` 需要 shell 执行，不能用 `command`。另外 `helm list --all-namespaces` 在 kubeconfig 不可用时可能失败，不应阻断仓库配置。

建议拆成两个任务：

```yaml
- name: 添加 helm 仓库
  ansible.builtin.shell: |
    set -o pipefail
    helm repo remove stable || true
    helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
    helm repo update
  args:
    executable: /bin/bash

- name: 查询 helm 发布列表
  ansible.builtin.command: helm list --all-namespaces
  changed_when: false
  failed_when: false
```

## 验证命令

本地执行 lint 时，如果沙箱或权限不允许写 `~/.ansible/tmp`，可以显式指定临时目录：

```bash
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local-tmp \
ANSIBLE_REMOTE_TEMP=/tmp/ansible-remote-tmp \
ansible-lint roles/install roles/common roles/uninstall roles/k3s roles/kubernetes
```

语法检查：

```bash
ANSIBLE_LOCAL_TEMP=/tmp/ansible-local-tmp \
ANSIBLE_REMOTE_TEMP=/tmp/ansible-remote-tmp \
ansible-playbook -i hosts site.yml --syntax-check
```

单 role 验证：

```bash
ansible-lint roles/install
ansible-lint roles/common
ansible-lint roles/uninstall
ansible-lint roles/k3s
ansible-lint roles/kubernetes
```

## 修改检查清单

提交 role 修改前检查：

- [ ] 所有 task `name` 是中文说明
- [ ] 新变量带 role 前缀
- [ ] 没有跨 role 引用私有变量
- [ ] 没有 `ignore_errors`
- [ ] `command` / `shell` 有 `changed_when`
- [ ] shell 管道有 `set -o pipefail`
- [ ] 需要 shell 语法的任务没有误用 `command`
- [ ] 目标机器路径使用 `common_home_root` 或 `ansible_user_dir`
- [ ] `ansible-lint` 通过
- [ ] `ansible-playbook --syntax-check` 通过

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

7. 先检查、输出结果、再操作

   安装、卸载、配置修改这类可重复执行任务，应拆成三段：

   - 检查任务：只判断状态，注册 role 前缀变量，`changed_when: false`
   - 输出任务：用中文 `debug` 输出检查结果，便于从 playbook 日志判断为什么跳过或执行
   - 操作任务：只在检查结果需要变更时执行

   示例：

   ```yaml
   - name: 检查 Node.js 是否已安装
     ansible.builtin.shell: "node -v >/dev/null 2>&1 && echo 0 || echo 1"
     register: install_installed_of_node
     changed_when: false

   - name: 输出 Node.js 检查结果
     ansible.builtin.debug:
       msg: "Node.js {{ '已安装' if install_installed_of_node.stdout == '0' else '未安装' }}"

   - name: 安装 Node.js 版本
     ansible.builtin.command: "/usr/local/n/bin/n {{ install_node_version }}"
     changed_when: true
     when: install_installed_of_node.stdout == "1"
   ```

   检查返回值约定：`0` 表示已存在或已安装，`1` 表示不存在或未安装。输出文本按语义使用“已安装/未安装”“已存在/不存在”“已设置/未设置”。

8. 已存在的 Git 仓库默认不更新

   通过 `ansible.builtin.git` 下载 rbenv、插件或类似工具时，如果需求是“已存在则不更新”，必须显式设置：

   ```yaml
   update: false
   ```

   不要再额外写“已安装则拉取仓库更新”的 block。需要升级时单独增加明确的 update tag 或专门任务，避免常规安装每次联网拉取。

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

虚拟环境任务需要按同样的三段式处理：

- 检查虚拟环境目录或 `bin/python`
- 输出虚拟环境检查结果
- 不存在时创建虚拟环境
- 检查依赖安装标记，例如 `.requirements_installed`
- 未安装依赖时执行 `uv pip install` 并写入标记文件

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

### uninstall

`uninstall` 应按功能拆分任务文件，`tasks/main.yml` 只负责 include，不直接堆叠具体卸载逻辑。

推荐结构：

- `zsh.yml`
- `docker.yml`
- `initialize.yml`
- `nodejs.yml`
- `golang.yml`
- `java.yml`
- `virtualenv.yml`

每个 include 任务应带 `always` tag，保证通过 `-t remove_virtualenv`、`-t remove_nodejs` 等单独标签执行时可以进入对应任务文件。

安装 role 新增工具时，应同步检查是否需要在 `uninstall` 中增加对应卸载逻辑。例如 `initialize.yml` 安装 `chezmoi`、`uv`、`devbox`、`nix`、`direnv`、`atuin`、`sing-box`、`cargo`，`roles/uninstall/tasks/initialize.yml` 也应维护对应清理任务。

卸载 Python Virtualenv 使用 `uninstall_virtual_root`，默认与安装路径保持一致：

```yaml
uninstall_virtual_root: "{{ common_home_root }}/packages/pythonenv"
```

不要在 `uninstall` 中直接引用 `install_virtual_root`。跨 role 路径要么使用 `common_*` 公共变量，要么在当前 role 定义自己的 `uninstall_*` 变量。

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
  environment:
    KUBECONFIG: /etc/rancher/k3s/k3s.yaml
  changed_when: false
  failed_when: false
```

### 检查任务没有输出导致跳过原因不清楚

只写检查任务和 `when` 条件时，playbook 日志只能看到“skipping”，不容易判断是已安装、安装包已存在，还是检查条件没有命中。

处理方式：每个检查任务后面都补一个中文 `debug` 输出。例如：

```yaml
- name: 输出 helm 检查结果
  ansible.builtin.debug:
    msg: "helm {{ '已安装' if k3s_installed_of_helm.stdout == '0' else '未安装' }}"
```

对于 `stat` 检查，用 `stat.exists` 输出：

```yaml
- name: 输出 k3s server 卸载脚本检查结果
  ansible.builtin.debug:
    msg: "k3s server 卸载脚本 {{ '已存在' if k3s_server_scripts.stat.exists else '不存在' }}"
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
- [ ] 需要变更的任务按“检查、输出结果、操作”拆分
- [ ] 每个检查任务后面都有中文检查结果输出
- [ ] 没有 `ignore_errors`
- [ ] `command` / `shell` 有 `changed_when`
- [ ] shell 管道有 `set -o pipefail`
- [ ] 需要 shell 语法的任务没有误用 `command`
- [ ] 目标机器路径使用 `common_home_root` 或 `ansible_user_dir`
- [ ] 已安装则不更新的 Git 仓库设置了 `update: false`
- [ ] 新增安装逻辑时同步补充对应卸载任务
- [ ] `uninstall/tasks/main.yml` 只 include 子任务文件，不堆叠具体卸载逻辑
- [ ] `ansible-lint` 通过
- [ ] `ansible-playbook --syntax-check` 通过

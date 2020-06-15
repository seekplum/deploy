# -*- coding: utf-8 -*-

from __future__ import print_function

import os
import sys

import textwrap

from fabric.api import env, settings
from fabric.api import run, cd
from fabric.api import local, lcd
from fabric.colors import red

env.hosts = [host for host in os.environ.get("OPEN_STACK_IP", "").split(",") if host]
# 配置SSH信息
env.user = os.environ.get("OPEN_STACK_USE", "root")
# 密钥对生成方式为  ssh-keygen -t rsa -b 4096 -C "email@email.com" -m PEM -f "/tmp/test_key"
env.key_filename = os.environ.get("OPEN_STACK_KEY_FILE", "%s/.ssh/id_rsa" % os.environ["HOME"])
env.password = os.environ.get("OPEN_STACK_PASS", "")
env.port = os.environ.get("OPEN_STACK_PORT", 22)


class _Singleton(object):
    """单例模式
    """
    _instance = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(_Singleton, cls).__new__(cls, *args, **kwargs)
            print("hosts: %s, user: %s, port: %s, password: %s, key filename: %s" % (
                env.hosts, env.user, env.port, env.password, env.key_filename))
        return cls._instance


class _OpenStackDeploy(_Singleton):
    """部署单机版OpenStack
    """

    def __init__(self, run_command, run_cd):
        self._run_command = run_command  # 执行系统命令函数
        self._run_cd = run_cd  # 进入系统目录函数

        self._os_type = "Ubuntu"
        self._stack_user = "stack"
        self._stack_home = "/opt/stack"
        self._stack_branch = "stable/ocata"
        self._stack_origin = "http://git.trystack.cn/openstack-dev/devstack.git"
        self._stack_root = os.path.join(self._stack_home, "devstack")

    @classmethod
    def get_deploy(cls):
        """获取当前类对象
        """
        # 通过hosts判断是在本机还是远程部署
        if env.hosts:
            run_command, run_cd = run, cd
        else:
            run_command, run_cd = local, lcd
        return cls(run_command, run_cd)

    def _run_stack_command(self, cmd):
        """进入stack用户执行命令
        """
        stack_cmd = 'su - %s -c "%s"' % (self._stack_user, cmd)
        return self._run_command(stack_cmd)

    def _check_os_type(self):
        return self._run_command("uname -v")

    def _check_os_version(self):
        return self._run_command("cat /etc/issue")

    def _check_os_memory(self):
        return self._run_command("free -g")

    def _check_os_disk(self):
        return self._run_command("df -Th")

    def check(self):
        os_type = self._check_os_type()
        if self._os_type not in os_type:
            print(red("The operating system must be %s" % self._os_type))
            sys.exit(1)
        self._check_os_version()
        self._check_os_memory()
        self._check_os_disk()

    def _backup_source(self):
        cmd = textwrap.dedent("""\
        test -f /etc/apt/sources.list && mv /etc/apt/sources.list /etc/apt/sources.list.$(date +%s).bak
        cat >/etc/apt/sources.list <<EOF
        deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial main restricted universe multiverse
        deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial main restricted universe multiverse
        deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
        deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
        deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
        deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
        deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
        deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
        EOF
        """)
        self._run_command(cmd)

    def _update_soft(self):
        self._run_command("sudo apt -y autoremove")
        self._run_command("sudo apt-get -y update")

    def _sync_time(self):
        cmd_list = [
            'sudo apt-get install -y ntpdate',
            'sudo ntpdate cn.pool.ntp.org',
            'date +"%F %T"',
        ]
        for cmd in cmd_list:
            self._run_command(cmd)

    def _create_user(self):
        with settings(warn_only=True):
            cmd = 'id %s >/dev/null 2&> 1 || sudo useradd -s /bin/bash -d %s -m %s' % (
                self._stack_user, self._stack_home, self._stack_user)
            self._run_command(cmd)

        self._run_command('echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack')

    def _upgrade_pip(self):
        cmd = "pip install --upgrade pip"
        self._run_command(cmd)

    def _clone_devstack(self):
        cmd = "test -f %s || git clone -b %s --depth=1 %s %s" % (
            self._stack_root, self._stack_branch, self._stack_origin, self._stack_root)
        self._run_stack_command(cmd)

    def _update_local_conf(self):
        sample_conf = os.path.join(self._stack_root, "samples/local.conf")
        local_conf = os.path.join(self._stack_root, "local.conf")
        cmd = "scp %s %s" % (sample_conf, local_conf)
        self._run_stack_command(cmd)

        cmd = textwrap.dedent("""\
        cat >>/opt/stack/devstack/local.conf<<EOF

        HOST_IP=127.0.0.1

        # GIT mirror
        GIT_BASE=http://git.trystack.cn
        NOVNC_REPO=http://git.trystack.cn/kanaka/noVNC.git
        SPICE_REPO=http://git.trystack.cn/git/spice/spice-html5.git
        EOF
        """)
        self._run_stack_command(cmd)

    def _update_package_version(self):
        cmd = 'sudo sed -i "s/^oslo.i18n==.*/oslo.i18n>=3.15.3/g" `grep ^oslo.i18n.* -rl %s`' % self._stack_home
        self._run_command(cmd)

        cmd = 'sudo sed -i "s/^oslo.utils==.*/oslo.utils>=3.33.0/g" `grep ^oslo.utils.* -rl %s`' % self._stack_home
        self._run_command(cmd)

        cmd = 'sudo sed -i "s/^pbr==.*/pbr!=2.1.0,>=2.0.0/g" `grep ^pbr.*.* -rl %s`' % self._stack_home
        self._run_command(cmd)

    def install(self):
        cmd = "cd %s && ./stack.sh" % self._stack_root
        self._run_stack_command(cmd)

    def uninstall(self):
        """卸载操作

        1.调用unstack.sh、clean.sh 脚本进行卸载、清理
        2.删除stack用户
        3.卸载相关Python三方包
        """
        with settings(warn_only=True):
            self._run_stack_command("cd %s && ./unstack.sh" % self._stack_root)
            self._run_stack_command("cd %s && ./clean.sh" % self._stack_root)

            cmd = "userdel -rf %(user)s" % dict(user=self._stack_user)
            self._run_command(cmd)

            ignore_set = {
                "python-apt",
                "dnspython",
                "pycrypto",
            }
            cmd = 'pip freeze | grep -E -v "%s" | xargs pip uninstall -y' % "|".join(ignore_set)
            self._run_command(cmd)

    def _update_pip_conf(self):
        cmd = "mkdir -p ~/.pip/"
        self._run_command(cmd)

        cmd = textwrap.dedent("""\
        cat >~/.pip/pip.conf<<EOF
        [global]
        index-url = https://mirrors.aliyun.com/pypi/simple
        extra-index-url = https://pypi.org/simple
        timeout = 300
        trusted-host =
            mirrors.aliyun.com.edu.cn
            pypi.org
        EOF
        """)
        self._run_command(cmd)

    def _disable_upgrade_pip(self):
        cmd = 'sed -in "s/^install_get_pip/#install_get_pip/g" %s' % os.path.join(self._stack_root,
                                                                                  "tools/install_pip.sh")
        self._run_command(cmd)

    def update(self):
        self._backup_source()
        self._sync_time()
        self._update_soft()
        self._update_pip_conf()
        self._upgrade_pip()

    def prepare(self):
        self._create_user()
        self._clone_devstack()
        self._disable_upgrade_pip()
        self._update_local_conf()

    def deploy(self):
        self.check()
        self.uninstall()
        self.update()
        self.prepare()
        self.install()


def check():
    """检查系统内存、磁盘空间等
    """
    d = _OpenStackDeploy.get_deploy()
    d.check()


def update():
    """更新配置和软件
    """
    d = _OpenStackDeploy.get_deploy()
    d.check()
    d.update()


def prepare():
    """准备安装环境
    """
    d = _OpenStackDeploy.get_deploy()
    d.check()
    d.prepare()


def deploy():
    """执行部署操作(部署前会进行清理环境、更新配置等操作)
    """
    d = _OpenStackDeploy.get_deploy()
    d.deploy()


def install():
    """执行安装操作(不进行卸载清理环境、更新配置等操作)
    """
    d = _OpenStackDeploy.get_deploy()
    d.check()
    d.install()


def uninstall():
    """卸载OpenStack
    """
    d = _OpenStackDeploy.get_deploy()
    d.check()
    d.uninstall()

# if __name__ == '__main__':
#     # Debug模式
#
#     import sys
#     from fabric.main import main
#
#     sys.argv = [os.path.abspath(__file__), "deploy"]
#     main([os.path.abspath(__file__)])

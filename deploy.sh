#/bin/bash

RETVAL=0

install_zsh() {
    echo -e '\033[32mInstall zsh\033[0m'
	yum install zsh -y

	# 安装 oh-my-zsh主题
	sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)" <<EOF
exit
EOF

    # 设置命令行补齐
	git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	cp config/.zshrc ~/
    chsh -s /bin/zsh
    zsh_bash=~/.zshrc
    echo "source ~/.bash_profile" >> ${zsh_bash}
    echo "source ~/.bashrc" >> ${zsh_bash}
}

remove_zsh() {
    echo -e '\033[31mRemove zsh\033[0m'
    chsh -s /bin/bash
    yum remove -y zsh >/dev/null 2>&1
    rm -f ~/.zsh*
    rm -rf ~/.oh-my-zsh
}

remove_docker() {
    echo -e '\033[31mRemove Docker\033[0m'
    systemctl stop docker >/dev/null 2>&1
    yum remove -y docker-engine >/dev/null 2>&1
    find / -name "*docker*" | grep -v "oh-my-zsh" | xargs rm -rf
}

init() {
	yum install wget -y
	yum install screen -y
	yum install -y python-setuptools
    easy_install pip
    pip install supervisor
	cp config/.bashrc ~/

	mkdir -p ~/.ssh
	cp config/config ~/.ssh/
	cp config/authorized_keys ~/.ssh/
}

install_ansible() {
    pip install ansible
}

install_docker() {
    echo -e '\033[32mInstall Docker\033[0m'
    # 添加repo源
    cat > /etc/yum.repos.d/docker.repo <<EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
    yum -y install docker-engine
    systemctl start docker
}

install_govendor(){
    go get -u github.com/kardianos/govendor
    cd $GOPATH/src/github.com/kardianos/govendor
    go build
}

install_go() {
    tar zxvf packages/go1.10.3.linux-amd64.tar.gz -C /usr/local
}

# 打印帮助信息
print_help() {
	echo "Usage: bash $0 { init | docker | zsh | ansible | go | govendor | remove_docker | remove_zsh }"
    echo "e.g: bash $0 docker"
}

case "$1" in
  init)
	init
	;;
  docker)
	install_docker
	;;
  zsh)
	install_zsh
	;;
  go)
	install_go
	;;
  ansible)
	install_ansible
	;;
  govendor)
	install_govendor
	;;
  remove_zsh)
	remove_zsh
	;;
  remove_docker)
	remove_docker
	;;
  *)  # 匹配都失败执行
	print_help
	exit 1
esac

exit $RETVAL

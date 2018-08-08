#/bin/bash

RETVAL=0
current_path=`pwd`
file_path=$(dirname $0)

install_zsh() {
    echo -e '\033[32mInstall zsh\033[0m'
	yum install zsh -y

	# 安装 oh-my-zsh主题
	sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)" <<EOF
exit
EOF

    # 设置命令行补齐
	git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
	scp ${file_path}/config/.zshrc ~/
    chsh -s /bin/zsh
    zsh_bash=~/.zshrc
    echo "source ~/.bash_profile" >> ${zsh_bash}
    echo "source ~/.bashrc" >> ${zsh_bash}

    sed -i '10,12d' ~/.bashrc

    echo -e "\n\033[33m please run 'source ${zsh_bash}' \033[0m"
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
	yum install -y bzip2 python-setuptools wget screen
    easy_install --index-url=http://pypi.douban.com/simple  pip trash-cli
    pip install supervisor
	scp ${file_path}/config/.bashrc ~/

	mkdir -p ~/.ssh
	scp ${file_path}/config/config ~/.ssh/
	scp ${file_path}/config/authorized_keys ~/.ssh/

    echo -e "\n\033[33m please run 'source ~/.bashrc' \033[0m"
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
    systemctl enable docker
    systemctl start docker
}

install_govendor(){
    go get -u github.com/kardianos/govendor
    cd $GOPATH/src/github.com/kardianos/govendor
    go build
}

install_python3() {
    yum -y install gcc gcc-c++
    yum -y install zlib zlib-devel
    yum -y install libffi-devel

    echo -e "\n\033[33m please download 'https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz' \033[0m"
}

install_go() {
	mkdir -p ~/GolangProjects
	mkdir -p ~/GolangProjects/bin
	mkdir -p ~/GolangProjects/src
    tar zxvf packages/go1.10.3.linux-amd64.tar.gz -C /usr/local
}

# 打印帮助信息
print_help() {
	echo "Usage: bash $0 { init | python3 | docker | zsh | ansible | go | govendor | remove_docker | remove_zsh }"
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
  python3)
	install_python3
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

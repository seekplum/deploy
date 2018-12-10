#/usr/bin/env bash
# 在7.4操作系统上生效, 6.x没有测试过

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

    sed -i '9,11d' ~/.bashrc

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
    echo -e '\033[32mInit\033[0m'
    yum install -y git bzip2 python-setuptools wget screen
    easy_install --index-url=http://pypi.douban.com/simple  pip trash-cli
    pip install supervisor
    scp ${file_path}/config/.bashrc ~/

    mkdir -p ~/.ssh
    mkdir -p ~/GolangProjects
    mkdir -p ~/PythonProjects
    mkdir -p ~/WebProjects
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
    echo -e '\033[32mInstall govendor\033[0m'
    go get -u github.com/kardianos/govendor
    cd $GOPATH/src/github.com/kardianos/govendor
    go build
}

install_python3() {
    echo -e '\033[32mInstall Python3\033[0m'
    yum -y install gcc gcc-c++
    yum -y install zlib zlib-devel
    yum -y install libffi-devel

    echo -e "\n\033[33m please download 'https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz' \033[0m"
}

install_go() {
    echo -e '\033[32mInstall Go\033[0m'
    mkdir -p ~/GolangProjects/bin
    mkdir -p ~/GolangProjects/src
    if [ ! -f "${file_path}/packages/go1.10.3.linux-amd64.tar.gz" ];then
        wget -O ${file_path}/packages/go1.10.3.linux-amd64.tar.gz https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz
    fi
    tar zxvf ${file_path}/packages/go1.10.3.linux-amd64.tar.gz  -C /usr/local
}

install_node() {
    # sed -i 's#\"\$NVM_DIR/bash_completion\"#\"$NVM_DIR/xxx\"#g' ~/.bashrc
    # 删除时只能使用 / , 不能使用 #
    echo -e '\033[32mInstall node\033[0m'
    sed -ie "/export NVM_DIR=\"\$HOME\/\.nvm\"/d" ~/.bashrc
    sed -ie "/\"\$NVM_DIR\/nvm\.sh\"/d" ~/.bashrc
    sed -ie "/\"\$NVM_DIR\/bash_completion\"/d" ~/.bashrc
    mkdir -p $HOME/.nvm
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
    source ~/.bashrc
    nvm install v11.4.0
}

# 打印帮助信息
print_help() {
    echo "Usage: bash $0 { init | python3 | node | docker | zsh | ansible | go | govendor | remove_docker | remove_zsh }"
    echo "e.g: bash $0 docker"
}

install_packages() {
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
        node)
            install_node
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
}

main() {
    for func_name in $*
    do
        install_packages $func_name
    done
}

main $*
exit $RETVAL

# .bash_profile

# if [[ -f /etc/bashrc ]]; then
#     . /etc/bashrc
# fi

export MYSQL_HOME="${HOME}/packages/mysql"
export ORACLE_HOME="${HOME}/packages/oracle"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${ORACLE_HOME}"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:${ORACLE_HOME}:${MYSQL_HOME}/lib"
{% if is_mac_os %}
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_162.jdk/Contents/Home"
{% else %}
export JAVA_HOME="{{JAVA_HOME}}"
{% endif %}
export MVN_HOME="{{MVN_HOME}}"
export CLASSPATH=".:${JAVA_HOME}/lib:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/lib/dt.jar"

export M2_HOME="${HOME}/packages/apache-maven-3.5.4"

export GOROOT="{{GOROOT}}"
export GOPATH="{{GOPATH}}"
export GOPROXY=https://mirrors.aliyun.com/goproxy/

export PYTHON_BUILD_MIRROR_URL="https://registry.npmmirror.com/-/binary/python/"
export PYTHON_BUILD_MIRROR_URL_SKIP_CHECKSUM=1
export PYTHONSTARTUP="${HOME}/.pythonrc"
export PYTHONPROJECTSPATH="{{PythonProjects}}"
export WEBPROJECTSPATH="{{WebProjects}}"
export JAVAPROJECTSPATH="{{JavaProjects}}"

export LDFLAGS="-L/usr/local/opt/zlib/lib"
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/sqlite/lib"
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/openssl/lib"
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/mysql-client/lib"
{% if is_mac_os %}
export LDFLAGS="${LDFLAGS} -L$(brew --prefix openssl)/lib"
{% endif %}
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/sqlite/include"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/mysql-client/include"
export CFLAGS="${CFLAGS} -I/usr/local/opt/openssl/include"
# pkg-config --cflags openssl11、pkg-config --libs openssl11
export CFLAGS="${CFLAGS} -I/usr/include/openssl11"
export LDFLAGS="${LDFLAGS} -L/usr/lib64/openssl11 -lssl -lcrypto"
{% if is_mac_os %}
CFLAGS="${CFLAGS} -I$(brew --prefix openssl)/include"
{% endif %}
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/sqlite/lib/pkgconfig"
export NODE_HOME=/usr/local
export N_PREFIX=/usr/local
export NODE_PATH="${PATH}:${NODE_HOME}/lib/node_modules"
export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node # 配置 nvm 源

{% if is_mac_os %}
export PS1="\h@\u: \W \$ " # 终端提示符
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles
{% else %}
export PS1="\[\e[0;33m\]\u\[\e[0m\]@\[\e[0;37m\]\h\[\e[0m\]:\[\e[0;31m\] \w \[\e[0m\]\$ " # 终端提示符
{% endif %}
export LS_OPTIONS='--color=auto' # 如果没有指定，则自动选择颜色
export CLICOLOR='Yes' # 是否输出颜色
export LSCOLORS='Gxfxcxdxbxegedabagacad' # 指定颜色
# 自定义使用Python版本
export PYENV_ROOT="{{PYENV_ROOT}}"
export RBENV_ROOT="{{RBENV_ROOT}}"
export PYTHON_VERSION="{{PYTHON3_VERSION}}"
export PYTHON_VIRTUEL_ROOT="{{VIRTUEL_ROOT}}/${PYTHON_VERSION}"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin"
export PATH="${PATH}:/usr/local/opt/ncurses/bin"
export PATH="${PATH}:/usr/local/n/bin"
export PATH="${PATH}:${GOPATH}/src/github.com/golang/dep/cmd/dep/dep"
export PATH="${PATH}:${GOPATH}/src/github.com/jteeuwen/go-bindata/go-bindata"
export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"
export PATH="${PATH}:${PYTHON_VIRTUEL_ROOT}/bin"
export PATH="${PATH}:${MYSQL_HOME}/bin:${JAVA_HOME}/bin"
export PATH="${PATH}:${M2_HOME}/bin"
export PATH="${PATH}:${HOME}/istio-0.8.0/bin"
export PATH="${PATH}:${HOME}/packages/redis/src"
export PATH="${PATH}:${HOME}/packages/mongodb/bin"
export PATH="${PATH}:/usr/local/Cellar/rabbitmq/3.7.14/sbin"
export PATH="${PATH}:${MVN_HOME}/bin"
export PATH="${PATH}:${HOME}/.poetry/bin"
export PATH="${PATH}:${PYENV_ROOT}/bin"
export PATH="${PATH}:${RBENV_ROOT}/bin"
export PATH="${PATH}:{{ RUBY_BUILD_ROOT }}/bin"
export PATH="${PATH}:${NODE_HOME}/bin"
export PATH="${PATH}:/usr/local/opt/sqlite/bin"
export PATH="${PATH}:${HOME}/.yarn/bin:${HOME}/.config/yarn/global/node_modules/.bin"
export PATH="${PATH}:/snap/bin"
export PATH="${PATH}:/mnt/d/Microsoft VS Code/bin"

alias senv3="source ${PYTHON_VIRTUEL_ROOT}/bin/activate"
alias senv="senv3"

alias mystart="${PYTHON_VIRTUEL_ROOT}/bin/supervisord -c ${HOME}/packages/supervisor/supervisord.conf"
alias mysuper="${PYTHON_VIRTUEL_ROOT}/bin/supervisorctl -c ${HOME}/packages/supervisor/supervisord.conf"
alias mymysql='${HOME}/packages/mysql/bin/mysql -uroot -proot -S ${HOME}/packages/mysql/data/sock/mysql.sock'
alias mysqlserver='${HOME}/packages/mysql/support-files/mysql.server'
alias myredis='redis-cli -h 127.0.0.1 -a xxxx --no-auth-warning'
alias mymongoro='mongosh --authenticationDatabase admin -u da_ro -p xxxx'
alias mymongorw='mongosh --authenticationDatabase admin -u da_rw -p xxxx'
alias mymongouseradmin='mongosh --authenticationDatabase admin -u user_admin -p xxxx'
alias mymongoadmin='mongosh --authenticationDatabase admin -u mongo_admin -p xxxx'
alias mymongoroot='mongosh --authenticationDatabase admin -u root -p xxxx'

alias ll='ls -l'
alias cp='cp -i'
alias mv='mv -i'
alias rm='echo -e "\033[33mThis is not the command you are looking for.\033[0m"; false'

alias cdg='cd ${GOPATH}/src'
alias cdp="cd ${PYTHONPROJECTSPATH}"
alias cdw="cd ${WEBPROJECTSPATH}"
alias cdj="cd ${JAVAPROJECTSPATH}"

alias cds="cd ${PYTHONPROJECTSPATH}/github.com/seekplum/seekplum"
alias cdi="cd ${PYTHONPROJECTSPATH}/github.com/seekplum/seekplum.github.io"
alias cdd="cd ${PYTHONPROJECTSPATH}/github.com/seekplum/deploy"

# virtualenvwrappe 配置
export WORKON_HOME=${HOME}/.virtualenvs
# export VIRTUALENVWRAPPER_SCRIPT={{PYENV_ROOT}}/versions/${PYTHON_VERSION}/bin/virtualenvwrapper.sh
export VIRTUALENVWRAPPER_PYTHON={{PYENV_ROOT}}/versions/${PYTHON_VERSION}/bin/python
export VIRTUALENVWRAPPER_VIRTUALENV={{PYENV_ROOT}}/versions/${PYTHON_VERSION}/bin/virtualenv
# export VIRTUALENVWRAPPER_VIRTUALENV_ARGS='--no-site-packages'
# source ${VIRTUALENVWRAPPER_SCRIPT}
# export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

if which pyenv > /dev/null 2>&1;
  then eval "$(pyenv init -)";
fi
if which rbenv > /dev/null 2>&1;
  then eval "$(rbenv init -)";
fi

# pnpm
export PNPM_HOME="${HOME}/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

function proxy_on() {
  export ALL_PROXY=socks5://127.0.0.1:7890
  export http_proxy=http://127.0.0.1:7890
  export https_proxy=${http_proxy}
  echo -e "终端代理已开启。"
}

function proxy_off(){
  unset http_proxy https_proxy
  echo -e "终端代理已关闭。"
}

. "${HOME}/.local/bin/env"

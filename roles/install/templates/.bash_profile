# .bash_profile

if [[ -f /etc/bashrc ]]; then
    . /etc/bashrc
fi

export MYSQL_HOME="${HOME}/packages/mysql"
export ORACLE_HOME="${HOME}/packages/oracle"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${ORACLE_HOME}"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:${ORACLE_HOME}:${MYSQL_HOME}/lib"
{% if ansible_os_family == "Darwin" %}
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_162.jdk/Contents/Home"
{% else %}
export JAVA_HOME="{{JAVA_HOME}}"
{% endif %}
export CLASS_PATH="${JAVA_HOME}/lib"

export M2_HOME="${HOME}/packages/apache-maven-3.5.4"

export GOROOT="{{GOROOT}}"
export GOPATH="{{GOPATH}}"
export GOPROXY=https://mirrors.aliyun.com/goproxy/

export PYTHONSTARTUP="${HOME}/.pythonrc"
export PYTHONPROJECTSPATH="{{PythonProjects}}"
export WEBPROJECTSPATH="{{WebProjects}}"

export LDFLAGS="-L/usr/local/opt/zlib/lib"
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/sqlite/lib"
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/sqlite/include"
export CFLAGS="${CFLAGS} -I/usr/local/opt/openssl/include"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/sqlite/lib/pkgconfig"

export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node # 配置 nvm 源

{% if ansible_os_family == "Darwin" %}
export PS1="\h@\u: \W \$ " # 终端提示符
{% else %}
export PS1="\[\e[0;33m\]\u\[\e[0m\]@\[\e[0;37m\]\h\[\e[0m\]:\[\e[0;31m\] \w \[\e[0m\]\$ " # 终端提示符
{% endif %}
export LS_OPTIONS='--color=auto' # 如果没有指定，则自动选择颜色
export CLICOLOR='Yes' # 是否输出颜色
export LSCOLORS='Gxfxcxdxbxegedabagacad' # 指定颜色
# 自定义使用Python版本
export PYENV_ROOT="${HOME}/.pyenv"
export PYTHON_VERSION=3.7.5
export PYTHON_VIRTUEL_ROOT={{VIRTUEL_ROOT}}/${PYTHON_VERSION}
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin"
export PATH="${PATH}:/usr/local/opt/ncurses/bin"
export PATH="${PATH}:{{HOME_ROOT}}/.nvm/:{{HOME_ROOT}}/.nvm/versions/node/{{NODE_VERSION}}/bin"
export PATH="${PATH}:${GOPATH}/src/github.com/kardianos/govendor"
export PATH="${PATH}:${GOPATH}/src/github.com/golang/dep/cmd/dep/dep"
export PATH="${PATH}:${GOPATH}/src/github.com/jteeuwen/go-bindata/go-bindata"
export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"
export PATH="${PATH}:${PYTHON_VIRTUEL_ROOT}/bin"
export PATH="${PATH}:${MYSQL_HOME}/bin:${JAVA_HOME}/bin"
export PATH="${PATH}:${M2_HOME}/bin"
export PATH="${PATH}:${HOME}/istio-0.8.0/bin"
export PATH="${PATH}:${HOME}/packages/redis/src/"
export PATH="${PATH}:${HOME}/packages/mongodb/bin/"
export PATH="${PATH}:/usr/local/Cellar/rabbitmq/3.7.14/sbin/"
export PATH="${PATH}:${HOME}/packages/apache-maven-3.5.4/bin"
export PATH="${PYENV_ROOT}/bin:${PATH}"
export PATH="${HOME}/.poetry/bin:${PATH}"

alias senv3="source ${PYTHON_VIRTUEL_ROOT}/bin/activate"
alias senv="senv3"

alias mystart="${PYTHON_VIRTUEL_ROOT}/bin/supervisord -c ${HOME}/packages/supervisor/supervisord.conf"
alias mysuper="${PYTHON_VIRTUEL_ROOT}/bin/supervisorctl -c ${HOME}/packages/supervisor/supervisord.conf"
alias mymysql='${HOME}/packages/mysql/bin/mysql -uroot -proot -S ${HOME}/packages/mysql/data/sock/mysql.sock'
alias mysqlserver='${HOME}/packages/mysql/support-files/mysql.server'
alias myredis='${HOME}/packages/redis/src/redis-cli'

alias ll='ls -l'
alias cp='cp -i'
alias mv='mv -i'
alias rm='echo -e "\033[33mThis is not the command you are looking for.\033[0m"; false'

alias cdg='cd ${GOPATH}/src'
alias cdp="cd ${PYTHONPROJECTSPATH}"
alias cdw="cd ${WEBPROJECTSPATH}"

alias cds="cd ${PYTHONPROJECTSPATH}/github.com/seekplum/seekplum"
alias cdi="cd ${PYTHONPROJECTSPATH}/github.com/seekplum/seekplum.github.io"
alias cdm="cd ${PYTHONPROJECTSPATH}/meideng.net/meideng/meizhe2012"
alias cdd="cd ${PYTHONPROJECTSPATH}/meideng.net/meideng/meizhe-docs"

# pyenv 配置
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"

# virtualenvwrappe 配置
export WORKON_HOME=${HOME}/.virtualenvs
export VIRTUALENVWRAPPER_SCRIPT=${HOME}/.pyenv/versions/3.7.5/bin/virtualenvwrapper.sh
export VIRTUALENVWRAPPER_PYTHON=${HOME}/.pyenv/versions/3.7.5/bin/python
export VIRTUALENVWRAPPER_VIRTUALENV=${HOME}/.pyenv/versions/3.7.5/bin/virtualenv
# export VIRTUALENVWRAPPER_VIRTUALENV_ARGS='--no-site-packages'
source ${VIRTUALENVWRAPPER_SCRIPT}

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"  # This loads nvm
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

if which pyenv > /dev/null;
  then eval "$(pyenv init -)";
fi

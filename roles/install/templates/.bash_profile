# .bash_profile

if [[ -f /etc/bashrc ]]; then
    . /etc/bashrc
fi

export MYSQL_HOME="${HOME}/packages/mysql"
export ORACLE_HOME="${HOME}/packages/oracle"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${ORACLE_HOME}"
export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:${ORACLE_HOME}:${MYSQL_HOME}/lib"

export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_162.jdk/Contents/Home"
export CLASS_PATH="${JAVA_HOME}/lib"

export M2_HOME="${HOME}/packages/apache-maven-3.5.4"

export GOROOT="{{GOROOT}}"
export GOPATH="{{GOPATH}}"

export PYTHONSTARTUP="${HOME}/.pythonrc"
export PYTHONPROJECTSPATH="{{PythonProjects}}"
export WEBPROJECTSPATH="{{WebProjects}}"

export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/sqlite/lib"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/sqlite/include"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/sqlite/lib/pkgconfig"

export PIP_INDEX_URL={{PIP_INDEX_URL}}
export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node # 配置 nvm 源

{% if ansible_os_family == "Darwin" %}
export PS1="\h@\u: \W \$ " # 终端提示符
{% else %}
export PS1="\[\e[0;33m\]\u\[\e[0m\]@\[\e[0;37m\]\h\[\e[0m\]:\[\e[0;31m\] \w \[\e[0m\]\$ " # 终端提示符
{% endif %}
export LS_OPTIONS='--color=auto' # 如果没有指定，则自动选择颜色
export CLICOLOR='Yes' # 是否输出颜色
export LSCOLORS='Gxfxcxdxbxegedabagacad' # 指定颜色

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin"
export PATH="${PATH}:/usr/local/opt/ncurses/bin"
export PATH="${PATH}:{{HOME_ROOT}}/.nvm/:{{HOME_ROOT}}/.nvm/versions/node/v10.0.0/bin"
export PATH="${PATH}:${GOPATH}/src/github.com/kardianos/govendor"
export PATH="${PATH}:${GOPATH}/src/github.com/golang/dep/cmd/dep/dep"
export PATH="${PATH}:${GOPATH}/src/github.com/jteeuwen/go-bindata/go-bindata"
export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"
{% for item in VIRTUAL_ENVS %}
export PATH="${PATH}:{{VIRTUEL_ROOT}}/{{item.directory}}/bin"
{% endfor %}
export PATH="${PATH}:${MYSQL_HOME}/bin:${JAVA_HOME}/bin"
export PATH="${PATH}:${M2_HOME}/bin"
export PATH="${PATH}:${HOME}/istio-0.8.0/bin"
export PATH="${PATH}:${HOME}/packages/redis/src/"
export PATH="${PATH}:${HOME}/packages/mongodb/bin/"
export PATH="${PATH}:/usr/local/Cellar/rabbitmq/3.7.14/sbin/"
export PATH="${PATH}:${HOME}/packages/apache-maven-3.5.4/bin"

# User specific aliases and functions
{% for item in VIRTUAL_ENVS %}
alias senv{{loop.index+1}}='source {{VIRTUEL_ROOT}}/{{item.directory}}/bin/activate'
{% endfor %}
alias senv="senv2"

alias mystart="{{VIRTUEL_ROOT}}/{{VIRTUAL_ENVS[0].directory}}/bin/supervisord -c ${HOME}/packages/supervisor/supervisord.conf"
alias mysuper="{{VIRTUEL_ROOT}}/{{VIRTUAL_ENVS[0].directory}}/bin/supervisorctl -c ${HOME}/packages/supervisor/supervisord.conf"
alias mymysql='${HOME}/packages/mysql/bin/mysql -uroot -proot -S ${HOME}/packages/mysql/data/sock/mysql.sock'
alias myredis='/Users/seekplum/packages/redis/src/redis-cli'

alias ll='ls -l'
alias cp='cp -i'
alias mv='mv -i'
alias rm='echo -e "\033[33mThis is not the command you are looking for.\033[0m"; false'

alias cdg='cd ${GOPATH}/src'
alias cdp="cd ${PYTHONPROJECTSPATH}"
alias cdw="cd ${WEBPROJECTSPATH}"

alias cds="cd ${PYTHONPROJECTSPATH}/github.com/seekplum/seekplum"
alias cdi="cd ${PYTHONPROJECTSPATH}/github.com/seekplum/seekplum.github.io"
alias cdm="cd ${PYTHONPROJECTSPATH}/meideng.net/meizhe2012"

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"  # This loads nvm
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

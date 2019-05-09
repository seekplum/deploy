# .bashrc

# User specific aliases and functions

alias cp='cp -i'
alias mv='mv -i'

if [[ -f /etc/bashrc ]]; then
	. /etc/bashrc
fi

export ORACLE_HOME=$HOME/packages/oracle
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ORACLE_HOME}
export DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${ORACLE_HOME}

export GOROOT={{GOROOT}}
export GOPATH={{GOPATH}}

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin
export PATH=$PATH:${GOROOT}/bin:${GOPATH}/bin
export PATH=$PATH:${GOPATH}/src/github.com/kardianos/govendor
export PATH=$PATH:${GOPATH}/src/github.com/jteeuwen/go-bindata/go-bindata

alias rm='echo -e "\033[33mThis is not the command you are looking for.\033[0m"; false'
alias cdg="cd ${GOPATH}/src"
alias cdp="cd {{PythonProjects}}"
alias cdh="cd {{WebProjects}}"

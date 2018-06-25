# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
#if [ -f /etc/bashrc ]; then
#	. /etc/bashrc
#fi

export ORACLE_HOME=$HOME/packages/oracle
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$ORACLE_HOME:$MYSQL_HOME/lib

export GOROOT=/usr/local/go
export GOPATH=$HOME/GolangProjects

export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=$PATH:$GOPATH/src/github.com/kardianos/govendor

alias cdg="cd $GOPATH/src"

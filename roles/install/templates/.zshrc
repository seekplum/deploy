# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
# 目前使用的版本commit id为 1343ab67edd8a81b75aceca77ddb526be87a20c1
export ZSH="{{HOME_ROOT}}/.oh-my-zsh"

# 立即将命令写入历史文件，而不是等待 shell 退出
setopt INC_APPEND_HISTORY
# 允许在不同的 zsh 会话之间共享历史（即时读取其他窗口执行的命令）
setopt SHARE_HISTORY
# 记录命令执行的时间戳，方便回溯
setopt EXTENDED_HISTORY
# 忽略重复命令
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
# 减少多余空格
setopt HIST_REDUCE_BLANKS

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

plugins=(
    zsh-autosuggestions
    git
)

source $ZSH/oh-my-zsh.sh

bindkey \^U backward-kill-line # 取消zsh中 `ctrl + u` 清除整行

# 安装docker后可以配置 $(__docker_machine_ps1),同时soure docker-machine-prompt.bash
# source '/usr/local/etc/bash_completion.d/docker-machine-prompt.bash'

# kubectl命令补全
# source <(kubectl completion zsh)

# helm 命令补全
# export PATH="/usr/local/opt/helm@2/bin:$PATH"
# source <(helm completion zsh)

if [[ -f ~/.bash_profile ]]; then
    . ~/.bash_profile
fi

# if [[ -f ~/.bashrc ]]; then
# 	. ~/.bashrc
# fi

# 可以查看当前Shell配置 cat ~/.oh-my-zsh/themes/${ZSH_THEME}.zsh-theme
# export PS1='[%M] %n %{$fg[cyan]%}%c%{$reset_color%}$(__docker_machine_ps1) $(git_prompt_info)%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )%{$reset_color%}'
export PS1='%n %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )%{$reset_color%}'

# zsh支持 :* 等匹配
unsetopt nomatch

# 检查是否在 WSL 环境下
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    keep_current_path() {
        # 确保 wslpath 命令存在，防止最小化安装的 WSL 出错
        if command -v wslpath >/dev/null 2>&1; then
            printf "\e]9;9;%s\e\\" "$(wslpath -w "${PWD}")"
        fi
    }
    precmd_functions+=(keep_current_path)
fi

if which pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
fi
if which rbenv >/dev/null 2>&1; then
    eval "$(rbenv init -)"
fi

{% if is_linux_os %}
eval $(keychain --eval --agents ssh huangliuliang)
# /usr/bin/keychain ${HOME}/.ssh/huangliuliang
[ -f ${HOME}/.keychain/${HOST}-sh ] && source ${HOME}/.keychain/${HOST}-sh || true
{% endif %}

command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh --disable-up-arrow)" || true
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)" || true

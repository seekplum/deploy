#!/bin/bash
# 替换 Homebrew 源为清华镜像，支持重复执行

set -ex

BREW_REPO="$(brew --repo)"
BREW_CORE_REPO="$(brew --repo homebrew/core)"
BREW_CASK_REPO="$(brew --repo homebrew/cask)"


git_cmd() {
    sudo git "${@}"
}

replace_origin() {
    local repo_path="$1"
    local remote_url="$2"

    if [ -d "$repo_path" ]; then
        echo "$repo_path"
        cd "$repo_path"
        git_cmd remote -v && git_cmd branch
        if git_cmd remote get-url origin >/dev/null 2>&1; then
            git_cmd remote set-url origin "$remote_url"
        else
            git_cmd remote add origin "$remote_url"
        fi
        git_cmd clean --quiet -fdxq
        git_cmd remote prune origin >/dev/null 2>&1 || true
        git_cmd pull origin `git rev-parse --abbrev-ref HEAD` --rebase
    else
        git_cmd clone --depth 1 "$remote_url" "$repo_path"
        git_cmd -C "$repo_path" fetch --unshallow
    fi
}

function replace_tsinghua() {
    replace_origin "$BREW_REPO" "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
    replace_origin "$BREW_CORE_REPO" "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
    replace_origin "$BREW_CASK_REPO" "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git"

    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
}

function replace_ustc() {
    replace_origin "$BREW_REPO" "https://mirrors.ustc.edu.cn/brew.git"
    replace_origin "$BREW_CORE_REPO" "https://mirrors.ustc.edu.cn/homebrew-core.git"
    replace_origin "$BREW_CASK_REPO" "https://mirrors.ustc.edu.cn/homebrew-cask.git"

    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
    export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
}

function replace_official() {
    replace_origin "$BREW_REPO" "https://github.com/Homebrew/brew.git"
    replace_origin "$BREW_CORE_REPO" "https://github.com/Homebrew/homebrew-core.git"
    replace_origin "$BREW_CASK_REPO" "https://github.com/Homebrew/homebrew-cask.git"
}

function print_help() {
    echo "Usage: bash $0 {official|tsinghua|ustc}"
    echo "e.g: bash $0 ustc"
}

case "$1" in
    official)
        replace_official
        ;;
    tsinghua)
        replace_tsinghua
        ;;
    "" | ustc)
        replace_ustc
        ;;
    -h | --help)
        print_help
        ;;
    *) # 匹配都失败执行
        print_help
        ;;
esac


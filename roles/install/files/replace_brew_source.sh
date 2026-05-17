#!/bin/bash
# 替换 Homebrew 源为清华镜像，支持重复执行

set -e

BREW_REPO="$(brew --repo)"
BREW_CORE_REPO="$(brew --repo homebrew/core)"
BREW_CASK_REPO="$(brew --repo homebrew/cask)"

TSINGHUA_BREW="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
TSINGHUA_CORE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
TSINGHUA_CASK="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git"
TSINGHUA_BOTTLE="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

git_cmd() {
    sudo git "${@}"
}

replace_origin() {
    local repo_path="$1"
    local remote_url="$2"

    if [ -d "$repo_path" ]; then
        echo "$repo_path"
        git_cmd remote -v && git_cmd branch
        cd "$repo_path"
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

replace_origin "$BREW_REPO" "$TSINGHUA_BREW"
replace_origin "$BREW_CORE_REPO" "$TSINGHUA_CORE"
replace_origin "$BREW_CASK_REPO" "$TSINGHUA_CASK"

brew update

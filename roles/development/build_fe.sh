#!/bin/sh
set -xe

function print_error () {
    echo -e "\033[31m$1\033[0m"
}

ROOT_DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$ROOT_DIR"

name="avatar_app"
REPO_VAR="${name^^}_REPO"
REFSPEC_VAR="${name^^}_REFSPEC"

[[ -z ${!REPO_VAR} ]] && print_error "Miss ${name^^}_REPO" && exit 1
[[ -z ${!REFSPEC_VAR} ]] && print_error "Miss ${name^^}_REFSPEC" && exit 1

CODE="$ROOT_DIR/fe/code/$name"
mkdir -p "$CODE"
cd "$CODE"
git clone --depth=1 "${!REPO_VAR}" . ||
	([[ -d ".git" ]] && git remote set-url origin "${!REPO_VAR}") ||
	(echo "Error: Clone repo failed." && false)
git reset --hard
git clean -fdxq
git fetch origin --depth=1 "${!REFSPEC_VAR}"
git checkout FETCH_HEAD

cd "$ROOT_DIR"
cp run_static.sh "$CODE/"

FE_OUTPUT="$ROOT_DIR/fe/dist/avatar-app"
mkdir -p "$FE_OUTPUT"

docker volume create --name avatar_app_yarn_cache
docker volume create --name avatar_app_node_modules
docker run --rm \
	-v avatar_app_yarn_cache:/root/.yarn_cache \
	-v avatar_app_node_modules:/code/node_modules \
	-v "$CODE:/code" \
	-v "$FE_OUTPUT:/dist" \
	node:16-alpine /bin/sh -xe /code/run_static.sh

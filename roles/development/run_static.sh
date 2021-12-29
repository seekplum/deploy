#!/bin/sh
set -xe

DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

pwd
rm -rf dist/*

yarn config set cache-folder /root/.yarn_cache
yarn install --ignore-optional --no-emoji --no-progress --non-interactive
yarn build:h5

cp -r dist/* /dist

#!/bin/bash

set -xe

# 增加 ssh key 到可信列表
ssh-add -K ~/.ssh/seekplum

echo "$(date +'%Y-%m-%d %H:%M:%S') ${HOME}/packages/pythonenv/{{PYTHON3_VERSION}}/bin/supervisord -c ${HOME}/packages/supervisor/supervisord.conf" >> ~/packages/mystart.log

# 启动相关服务
${HOME}/packages/pythonenv/{{PYTHON3_VERSION}}/bin/supervisord -c ${HOME}/packages/supervisor/supervisord.conf

# 开启第二个微信页面
# screen -S weixin /Applications/WeChat.app/Contents/MacOS/WeChat
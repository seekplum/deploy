#!/bin/bash

set -xe

# 增加 ssh key 到可信列表
# ssh-add -K ~/.ssh/seekplum >/dev/null 2&> 1

# 启动相关服务
${HOME}/packages/pythonenv/{{PYTHON3_VERSION}}/bin/supervisord -c ${HOME}/packages/supervisor/supervisord.conf

# 开启第二个微信页面
# screen -S weixin /Applications/WeChat.app/Contents/MacOS/WeChat

# mount -o remount,rw /
# systemctl daemon-reload && systemctl restart systemd-resolved

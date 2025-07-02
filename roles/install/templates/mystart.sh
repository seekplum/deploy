#!/bin/bash

set -e

PACKAGES_ROOT="{{ HOME_ROOT }}/packages"
SUPERVISORD="${PACKAGES_ROOT}/pythonenv/{{ PYTHON3_VERSION }}/bin/supervisord"
SUPERVISORCTL="${PACKAGES_ROOT}/pythonenv/{{ PYTHON3_VERSION }}/bin/supervisorctl"
SUPERVISOR_CONF="${PACKAGES_ROOT}/supervisor/supervisord.conf"

function start() {
    # 增加 ssh key 到可信列表
    # ssh-add -K ~/.ssh/seekplum >/dev/null 2&> 1

    # 启动相关服务
    ${SUPERVISORD} -c ${SUPERVISOR_CONF}

    # 开启第二个微信页面
    # screen -S weixin /Applications/WeChat.app/Contents/MacOS/WeChat

    # mount -o remount,rw /
    # sudo systemctl daemon-reload && sudo systemctl restart systemd-resolved
}

function stop() {
    ${SUPERVISORCTL} -c ${SUPERVISOR_CONF} shutdown
}

function print_help() {
    echo "Usage: bash $0 {start|stop|restart}"
    echo "e.g: $0 start"
}


case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 3
        start
        ;;
  ""|-h|--help)
        print_help  # 参数为空时执行
        ;;
  *)  # 匹配都失败执行
        print_help
esac

exit 0

#!/bin/bash

# 定义输出文件
OUT="server_software_inventory.txt"
DATETIME=$(date "+%Y-%m-%d %H:%M:%S")

echo "==========================================" >$OUT
echo "   Ubuntu 22.04 软件安装渠道排查报告" >>$OUT
echo "   生成时间: $DATETIME" >>$OUT
echo "==========================================" >>$OUT

# 1. APT 渠道 - 用户手动安装的包 (排除系统预装和依赖)
echo -e "\n[1. APT/DPKG 手动安装列表]" >>$OUT
echo "说明: 这些是通过 'apt install' 明确安装的主程序" >>$OUT
apt-mark showmanual >>$OUT

# 2. APT 软件源 - 第三方仓库 (PPA & External Repo)
echo -e "\n[2. 外部软件源渠道 (Sources.list.d)]" >>$OUT
ls /etc/apt/sources.list.d/ >>$OUT

# 3. Snap 渠道 - 容器化应用
echo -e "\n[3. Snap 容器化应用列表]" >>$OUT
if command -v snap &>/dev/null; then
    snap list | awk 'NR>1 {print $1, "\t", $2}' >>$OUT
else
    echo "未安装 Snap" >>$OUT
fi

# 4. 语言级包管理 (Python, Node.js)
echo -e "\n[4. 开发语言全局包]" >>$OUT
if command -v pip &>/dev/null; then
    echo "--- Python (pip) ---" >>$OUT
    pip list --format=columns | head -n 20 >>$OUT
    echo "... (仅显示前20项)" >>$OUT
fi

if command -v npm &>/dev/null; then
    echo -e "\n--- Node.js (npm global) ---" >>$OUT
    npm list -g --depth=0 >>$OUT
fi

# 5. 正在运行的服务 (反向推测已安装的软件)
echo -e "\n[5. 活跃系统服务 (Systemd)]" >>$OUT
systemctl list-units --type=service --state=running --no-pager | awk '{print $1}' | grep ".service" >>$OUT

# 6. 自定义安装路径 (手动编译或二进制存放)
echo -e "\n[6. 自定义安装路径扫描]" >>$OUT
echo "--- /opt 目录 ---" >>$OUT
ls /opt >>$OUT
echo "--- /usr/local/bin 目录 ---" >>$OUT
ls /usr/local/bin >>$OUT

echo "------------------------------------------" >>$OUT
echo "报告生成完毕: $OUT"

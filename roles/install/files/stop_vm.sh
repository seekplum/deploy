#!/bin/bash

if [ $# -eq 0 ]; then
   stophosts=$(VBoxManage list runningvms | awk '{print $1}' | awk '{gsub(/^"|"$/, "");print}')
else
   stophosts=$*
fi

# poweroff 类似直接拔电源
for host in ${stophosts}; do VBoxManage controlvm ${host} acpipowerbutton; done


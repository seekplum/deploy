#!/bin/bash

if [ $# -eq 0 ]; then
   stophosts=$(VBoxManage list runningvms | awk '{print $1}' | awk '{gsub(/^"|"$/, "");print}')
else
   stophosts=$*
fi

for host in ${stophosts}; do VBoxManage controlvm ${host} poweroff; done


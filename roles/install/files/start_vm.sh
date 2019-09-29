#!/usr/bin/env bash

vms_txt='/tmp/.vms_temp.txt'
runningvms_txt='/tmp/.runningvms_temp.txt'

VBoxManage list vms | grep "ubuntu" | awk '{print $1}' | sed 's/.$//' | sed 's/^.//' > ${vms_txt}
VBoxManage list runningvms | awk '{print $1}' | awk '{gsub(/^"|"$/, "");print}' > ${runningvms_txt}

stophosts=$(sort -m <(sort ${vms_txt} | uniq) <(sort ${runningvms_txt} | uniq) <(sort ${runningvms_txt} | uniq) | uniq -u)
for host in ${stophosts}; do VBoxManage startvm ${host} --type headless; done

rm -f ${vms_txt}
rm -f ${runningvms_txt}


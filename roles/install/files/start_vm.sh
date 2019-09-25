#!/bin/bash

for host in $(VBoxManage list vms | grep -E "ubuntu|centos" | awk '{print $1}' | sed 's/.$//' | sed 's/^.//'); do VBoxManage startvm ${host} --type headless; done

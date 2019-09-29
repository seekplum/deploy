#!/usr/bin/env bash

for host in $(VBoxManage list runningvms | awk '{print $1}' | awk '{gsub(/^"|"$/, "");print}'); do VBoxManage controlvm ${host} poweroff; done

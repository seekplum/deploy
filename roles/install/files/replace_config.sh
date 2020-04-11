#!/bin/sh

ip_prefixs=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d"." -f1-3)

for prefix in ${ip_prefixs}
do 
    for ip in $(pping -p ${prefix})
    do
        hostname=$(sshpass -p seekplum ssh -o ConnectTimeout=1 -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa root@${ip} hostname 2>/dev/null)
        if [ $? = 0 ]; then 
            echo "${hostname} ${ip}"
            if [[ "`uname`" = "Darwin" ]]; then
                sed -i "" "/Host ${hostname}/{n;s/    HostName.*/    HostName ${ip}/;}" ~/.ssh/config
            else
                sed -i -e '/Host ${hostname}/!b;n;    HostName ${ip}' ~/.ssh/config
            fi
        fi
    done
done

#!/bin/sh

function print_error () {
    echo -e "\033[31m$1\033[0m"
}

[[ -z ${FULL_DOMAIN} ]] && print_error "Miss FULL_DOMAIN" && exit 1

/usr/bin/lego -a --dns ${DNS_PROVIDER:-alidns} --domains ${FULL_DOMAIN} --domains "*.${FULL_DOMAIN}" --email 1131909224@qq.com renew || /usr/bin/lego --dns  ${DNS_PROVIDER:-alidns} --domains ${FULL_DOMAIN} --domains "*.${FULL_DOMAIN}" --email 1131909224@qq.com -a run

#!/usr/bin/env bash

ETVAL=0

# const
# LDAP_SERVER_IP="127.0.0.1"
LDAP_SERVER_PORT="389"
LDAP_ADMIN_USER="cn=admin,dc=seekplum,dc=io"
LDAP_ADMIN_PASS="admin@123!"


function print_error () {
    echo -e "\033[31m$1\033[0m"
}

[[ -z ${LDAP_SERVER_IP} ]] && print_error "Miss LDAP_SERVER_IP" && exit 1

create_user () {
    if [ x"$#" != x"3" ];then
        echo "Usage: bash $0 create <username> <password> <realname>"
        exit -1
    fi

    # param
    USERNAME="$1"
    PASSWORD="$2"
    ENCRYPT_PASSWORD=$(slappasswd -h {ssha} -s "$PASSWORD")
    REALNAME="$3"
    REALNAME_BASE64=$(echo -n $REALNAME | base64)

    # add count & group
    cat <<EOF | ldapmodify -c -h $LDAP_SERVER_IP -p $LDAP_SERVER_PORT -w $LDAP_ADMIN_PASS -D $LDAP_ADMIN_USER
dn: cn=$USERNAME,ou=users,dc=seekplum,dc=io
changetype: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
cn: $USERNAME
sn:: $REALNAME_BASE64
mail: $USERNAME@qq.com
userPassword: $ENCRYPT_PASSWORD

dn: cn=Users,ou=groups,dc=seekplum,dc=io
changetype: modify
add: uniqueMember
uniqueMember: cn=$USERNAME,ou=users,dc=seekplum,dc=io
EOF
}

modify_password () {
    if [ x"$#" != x"2" ];then
        echo "Usage: bash $0 modify <username> <newPassword>"
        exit -1
    fi

    # param
    USERNAME="$1"
    PASSWORD="$2"
    ENCRYPT_PASSWORD=$(slappasswd -h {ssha} -s "$PASSWORD")

    # modify
    cat <<EOF | ldapmodify -c -h $LDAP_SERVER_IP -p $LDAP_SERVER_PORT -w $LDAP_ADMIN_PASS -D $LDAP_ADMIN_USER
dn: cn=$USERNAME,ou=users,dc=seekplum,dc=io
changetype: modify
replace: userPassword
userPassword: $ENCRYPT_PASSWORD
EOF
}

delete_user () {
    if [ x"$#" != x"1" ];then
        echo "Usage: bash $0 delete <username>"
        exit -1
    fi

    # param
    USERNAME="$1"

    # delete user
    ldapdelete -c -h $LDAP_SERVER_IP -p $LDAP_SERVER_PORT -w $LDAP_ADMIN_PASS -D $LDAP_ADMIN_USER "cn=$USERNAME,ou=users,dc=seekplum,dc=io"
}

print_help() {
        echo "Usage: bash $0 {create|modify|delete}"
    echo "e.g: $0 create"
}

# 命令行参数小于 1 时打印提示信息后退出
if [ $# -lt 1 ] ; then
    print_help
    exit 1;
fi

case "$1" in
  create)
        create_user ${@:2}
        ;;
  delete)
        delete_user ${@:2}
        ;;
  modify)
        modify_password ${@:2}
        ;;
  "")
  # -h|--help)
        print_help  # 参数为空时执行
        ETVAL=1
        ;;
  *)  # 匹配都失败执行
        print_help
        ETVAL=1
esac

exit ${ETVAL}

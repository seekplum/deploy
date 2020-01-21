#!/bin/sh

set -xe

curl 'http://gitea:3000/install' -H 'Content-Type: application/x-www-form-urlencoded' --data 'db_type=SQLite3&db_host=localhost:3306&db_user=root&db_passwd=&db_name=gitea&ssl_mode=disable&charset=utf8&db_path=/data/gitea/gitea.db&app_name=Gitea: Git with a cup of tea&repo_root_path=/data/git/repositories&lfs_root_path=/data/git/lfs&run_user=git&domain=gitea.seekplum.top&ssh_port=22&http_port=3000&app_url=https://gitea.seekplum.top&log_root_path=/data/gitea/log&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_federated_avatar=on&disable_registration=on&default_allow_create_organization=on&default_enable_timetracking=on&no_reply_address=noreply.localhost&admin_name=admin2&admin_passwd=seekplum&admin_confirm_passwd=seekplum&admin_email=admin@qq.com' --compressed

gitea admin auth add-ldap --name ldap --security-protocol unencrypted --host ldap --port 389 --user-search-base "ou=users,dc=seekplum,dc=io" --user-filter "(&(cn=%s)(|(memberOf=cn=admin,ou=groups,dc=seekplum,dc=io)(memberOf=cn=users,ou=groups,dc=seekplum,dc=io)))" --email-attribute mail --bind-dn cn=guest,dc=seekplum,dc=io --bind-password 123456 --admin-filter "(memberOf=cn=admin,ou=groups,dc=seekplum,dc=io)"

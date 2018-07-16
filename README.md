## 使用方法
---

## 运行playbook
* 只运行 `virtualenv` 相关任务
> ansible-playbook -i hosts site.yml -t virtualenv

* 只运行 `common` 相关任务
> ansible-playbook -i hosts site.yml -t common

* 运行所有任务(即 `common` 、 `virtualenv` 都运行)
> ansible-playbook -i hosts site.yml

## 注意
* 主机和组的关系定义在 `hosts` 文件中，`site.yml` 记录了`组`和角色之间的联系
* roles中使用group_vars目录中文件的变量，需要和组名相同

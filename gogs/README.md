# docker gogs git私服
```shell
# 所有文件将会创建到 /docker/gogs 目录中
# 复制 init.sh 到 /docker/gogs 目录
# 赋予 init.sh 执行权限
chmod 755 init.sh

# 运行初始化脚本 即可自动完成 对应文件/目录创建 docker-compose.yml  data log start.sh
sh init.sh

# 启动 gogs
sh start.sh
```

PS： 忽略文件已被提交到远程的解放方法
```shell
# 清理已经被提交到远程的文件夹
# 先将要忽略的文件添加到git 项目根目录的 `.gitignore`文件中, 如果无此文件可以先创建再添加 如.idea 目录

# 1.切换到需要执行清理的分支, 如 `master`分支 中的 .idea 
git checkout master

# 2. 然后执行命令来删除指定的文件或文件夹的历史记录
git filter-branch --index-filter 'git rm -r --cached --ignore-unmatch .idea' --prune-empty --tag-name-filter cat -- --all

# 3. 清理.git目录中的 refs/original 文件夹
rm -rf .git/refs/original/

# 4. 使用 git gc 命令进行 Git 垃圾回收以清理不再需要的历史记录和对象
git gc --prune=now

# 5. 强制推送当前版本的分支到远程
git push -f origin master

```
---
title: MySQL备份工具mysqldump以及Xtrabackup详解
date: 2017-07-14 09:52:41
tags: [mysql,linux,backup,mysqldump,xtrabackup]
categories: [linux进阶,MySQL]
copyright: true
---

![](https://ws4.sinaimg.cn/large/006tKfTcly1fhgv8l75tkj308204u745.jpg)

<blockquote class="blockquote-center">对于公司来说，数据库本身可能并不重要，重要的是数据库中存储的数据。
对于备份来说，备份不是我们最终的目的，而是使备份能够实现还原的目的，才是我们最终的追求。
所以，一个可恢复的数据库备份是非常重要的。
</blockquote>

`为什么备份?`

```
实现灾难恢复：硬件故障(冗余)、软件故障(BUG)、自然灾害、黑客攻击、误操作、...
测试恢复备份时，可能出现将数据库测试崩溃掉的情况

这里最可能出现的情况是：误操作
所以说，在操作数据库时，一定要慎之又慎
```

### <font szie=4 color="#32CD99"> 备份时需要注意的事项</font>

* 注意事项

```
能容忍最多丢失多少数据；
恢复数据需要在多长时间内完成；
需要恢复哪些数据；

做恢复演练：
    测试备份的可用性；
    增强恢复操作效率；
```

<br>

* 备份需要考虑的因素

```
锁定资源多长时间？
备份过程的时长？
备份时的服务器负载？
恢复过程的时长？
```

<br>

* 备份什么?

```
数据
二进制日志、InnoDB的事务日志；
代码（存储过程、存储函数、触发器、事件调度器）
服务器的配置文件 --> 配置系统中的配置文件 --> 存放在 Git 、svn 上
```

*注意：二进制日志、InnoDB事务日志 与数据要分别存放在不同的硬盘中*

<br>


* 备份策略

```
全量+差异 + binlogs
全量+增量 + binlogs 

备份手段：物理、逻辑
```


-------

<!-- more -->

{% note primary %}### 备份类型
{% endnote %}

#### <font szie=4 color="#007FFF"> 备份的数据的范围</font>


```
完全备份和部分备份
	完全备份：整个数据集；
	部分备份：数据集的一部分，比如部分表；
```

#### <font szie=4 color="#007FFF"> 全量备份、增量备份、差异备份</font>

* 全量备份

```
备份整个数据库的所有数据
```

<br>

* 增量备份

```
仅备份自上一次完全备份或 增量备份以来变量的那部数据
```

<br>

* 差异备份

```
仅备份自上一次完全备份以来变量的那部数据；(浪费空间，还原效果比增量快)
```

* 通过备份恢复数据库

```
完全+增量： 完全+每一次增量 		+ 二进制日志(根据时间点恢复)
完全+差异： 完全+最后一次差异备份 + 二进制日志(根据时间点恢复)
```


#### <font szie=4 color="#007FFF"> 物理备份、逻辑备份</font>

* 物理备份

```
直接复制数据文件进行的备份
```

<br>

* 逻辑备份(mysqldump)

```
通过mysql，从数据库导出数据另存在一个或多个文件中
通过一个大的SELECT 语句，转成一个 INSERT 语句 进行备份
```


#### <font szie=4 color="#007FFF"> 热备、温备、冷备</font>

* 热备

```
读写操作均可进行的状态下所做的备份 --> 导致备份的数据时间点可能不一致，恢复后的数据时间点不一致 -->  导致MySQL拒绝恢复
```

<br>

* 温备

```
可读但不可写状态下进行的备份
```

<br>

* 冷备

```
读写操作均不可进行的状态下所做的备份
```


-------


{% note success %}### mysqldump备份工具使用详解
{% endnote %}

`备份策略`：

```
全量备份 + binlogs
```

#### <font size=4 color="#32CD99">命令详解</font>

* 语法格式：

```
mysqldump [OPTIONS] database [tables]
OR     mysqldump [OPTIONS] --databases [OPTIONS] DB1 [DB2 DB3...]
OR     mysqldump [OPTIONS] --all-databases [OPTIONS]
```

实例详解：

```bash
# 表级别备份；不会自动创建数据库
$ mysqldump mydb

# 库级别备份，自动创建数据库 
$ mysqldump --databases mydb
```

<br>

* 选项详解

```bash
-x, --lock-all-tables       锁定'所有库的所有表'，读锁；
-l, --lock-tables           锁定'指定库所有表'；
-R, --routines              备份存储过程和存储函数；
-E, --events                备份事件调度器
-F，--flush-logs             锁定表完成后，即进行日志刷新操作，让日志滚动；
--triggers                  备份触发器

--master-data[=#] ：记录备份开始时 binlog中
 1：记录为CHANGE MASTER TO语句，此语句不被注释；
 2：记录为CHANGE MASTER TO语句，此语句被注释；
 
'InnoDB存储引擎：支持温备和热备；'
	--single-transaction：'创建一个事务，基于此快照执行备份'；
```


<br>



#### <font size=4 color="#32CD99">全量备份一次整个数据库</font>

* 开启二进制日志

```
$ vim /etc/my.cnf.d/server.conf
[server]
log_bin=mysql-bin
$ systemctl restart mariadb.service
```

* 开始备份数据库

```bash
# 使用mysqldump备份整个mysql数据库
$ mysqldump -E -R --triggers --master-data=2 -F -l --single-transaction --all-databases > /tmp/all-fullback-$(date +%F).sql

# 登陆至MySQL修改一些数据
$ mysql 
> SHOW MASTER LOGS;
+------------------+-----------+
| Log_name         | File_size |
+------------------+-----------+
| mysql-bin.000001 |     30352 |
| mysql-bin.000002 |   1038814 |
| mysql-bin.000003 |      9235 |
| mysql-bin.000004 |       696 |
| mysql-bin.000005 |       245 |
+------------------+-----------+
> use hellodb;
> DELETE FROM students WHERE StuID=1;
> DELETE FROM students WHERE StuID=5;
> DELETE FROM students WHERE StuID=10;
> DELETE FROM students WHERE StuID=15;
> DELETE FROM students WHERE StuID=20;

# 拷贝全量备份后，未备份的二进制日志至/tmp目录中
$ cp /var/lib/mysql/mysql-bin.000005 /tmp/

# 模拟数据库崩溃情况，删除数据库数据目录下的所有文件
$ rm -rf /var/lib/mysql/*
```

<br>

#### <font size=4 color="#32CD99">使用备份恢复数据库</font>

* 重启数据库

```bash
$ systemctl stop mariadb.service
$ systemctl start mariadb.service
```

* 登陆数据库进行恢复

```bash
$ mysql
# 关闭会话级别的二进制日志，因为我们需要执行恢复sql脚本，不希望二进制记录此信息
> SET @@session.sql_log_bin=OFF;
 
# 在MySQL中执行SQL脚本
> \. /tmp/alldb_fullbackup-2017-06-20.sql
```

* 使用二进制日志恢复未备份的信息

```bash
$ cd /tmp
$ mysqlbinlog mysql-bin.000005 | mysql
```

* 开启二进制日志记录

```bash
> SET @@session.sql_log_bin=ON;
```

**至此，一次删库到恢复就完成了**，不过要注意的是，在恢复完成后，如果业务不是很着急需要上线，这时还要做一次全量备份。如果业务必须立即上线，我们也可以在当天晚上进行备份数据库。


#### <font size=4 color="#32CD99">使用备份脚本备份数据库</font>


```bash
$ vim mysql-backup.sh
#!/bin/bash
# MYSQLDBUSERNAME是MySQL数据库的用户名，可自定义
MYSQLDBUSERNAME=root

# MYSQLDBPASSWORD是MySQL数据库的密码，可自定义
MYSQLDBPASSWORD="root@123"

# MYSQBASEDIR是MySQL数据库的安装目录，--prefix=$MYSQBASEDIR，可自定义
MYSQBASEDIR=/usr

# MYSQL是mysql命令的绝对路径，可自定义
MYSQL=$MYSQBASEDIR/bin/mysql

# MYSQLDUMP是mysqldump命令的绝对路径，可自定义
MYSQLDUMP=$MYSQBASEDIR/bin/mysqldump

# BACKDIR是数据库备份的存放地址，可以自定义修改成远程地址
BACKDIR=/var/backup/mysqldb

# 获取当前时间，格式为：年-月-日，用于生成以这种时间格式的目录名称
DATEFORMATTYPE1=$(date +%Y-%m-%d)

# 获取当前时间，格式为：年月日时分秒，用于生成以这种时间格式的文件名称
DATEFORMATTYPE2=$(date +%Y%m%d%H%M%S)

# 数据库数据目录
MYSQDATADIR=/var/lib/mysql

# 如果mysql命令存在并可执行，则继续，否则将MYSQL设定为mysql，默认路径下的mysql
[ -x $MYSQL ] || MYSQL=mysql

# 如果mysqldump命令存在并可执行，则继续，否则将MYSQLDUMP设定为mysqldump，默认路径下的mysqldump
[ -x $MYSQLDUMP ] || MYSQLDUMP=mysqldump

# 如果不存在备份目录则创建这个目录
[ -d ${BACKDIR} ] || mkdir -p ${BACKDIR}
[ -d ${BACKDIR}/${DATEFORMATTYPE1} ] || mkdir ${BACKDIR}/${DATEFORMATTYPE1}

# 获取MySQL中有哪些数据库，根据mysqldatadir下的目录名字来确认，此处可以自定义，TODO
DBLIST=`ls -p $MYSQDATADIR | grep / |tr -d /`

# 从数据库列表中循环取出数据库名称，执行备份操作
for DBNAME in $DBLIST
    # mysqldump skip one table
    # -- Warning: Skipping the data of table mysql.event. Specify the --events option explicitly.
    # mysqldump --ignore-table=mysql.event
    # http://serverfault.com/questions/376904/mysqldump-skip-one-table
    # --routines，备份存储过程和函数
    # --events，跳过mysql.event表
    # --triggers，备份触发器
    # --single-transaction，针对InnoDB，在单次事务中通过转储所有数据库表创建一个一致性的快照，此选项会导致自动锁表，因此不需要--lock-all-tables
    # --flush-logs，在dump转储前刷新日志
    # --ignore-table，忽略某个表，--ignore-table=database.table
    # --master-data=2 ，如果启用MySQL复制功能，则可以添加这个选项
    # 将dump出的sql语句用gzip压缩到一个以时间命名的文件
    do ${MYSQLDUMP} --user=${MYSQLDBUSERNAME} --password=${MYSQLDBPASSWORD} --routines --events --triggers --single-transaction --flush-logs --ignore-table=mysql.event --databases ${DBNAME} | gzip > ${BACKDIR}/${DATEFORMATTYPE1}/${DBNAME}-backup-${DATEFORMATTYPE2}.sql.gz

    # 检查执行结果，如果错误代码为0则输出成功，否则输出失败
    [ $? -eq 0 ] && echo "${DBNAME} has been backuped successful" || echo "${DBNAME} has been backuped failed"

    # 等待5s，可自定义
    /bin/sleep 5
done
```

-------

{% note info %}### xtrabackupex备份工具使用详解
{% endnote %}


#### <font size=4 color="#007FFF">安装xtrabackupex</font>

官方下载地址：[XtraBackup](https://www.percona.com/downloads/XtraBackup/LATEST/)

安装`XtraBackup`

```
$ ntpdate 172.16.0.1
$ wget ftp://172.16.0.1/pub/Sources/7.x86_64/percona/percona-xtrabackup-24-2.4.7-2.el7.x86_64.rpm
$ yum install -y ./percona-xtrabackup-24-2.4.7-2.el7.x86_64.rpm
```

#### <font size=4 color="#007FFF">进行一次全库备份</font>

```bash
$ vim /etc/my.cnf.d/server.conf
[server]
skip_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin

$ systemctl start mariadb.service

# 全库备份时，无需指定数据库即可备份。指定库备份使用 --databases DATABASE_NAME
$ innobackupex --user root /data/backup/
$ ll /data/backup/2017-07-13_20-05-42/
```

#### <font size=4 color="#007FFF">通过备份恢复数据库</font>

* 恢复之前的准备

```bash
# 默认数据库损坏，被删库
$ cp /var/lib/mysql/mysql_bin.00000* /data/backup
$ rm -rf /var/lib/mysql/*
```

* 执行Preparing操作

```bash
$ innobackupex --apply-log /data/backup/2017-07-13_20-05-42/
```

* 恢复数据库

```bash
$ innobackupex --copy-back 2017-07-13_20-05-42/
$ cd /var/lib/mysql
$ chown -R mysql.mysql ./*
```

![](https://ws3.sinaimg.cn/large/006tNc79ly1fhje4qhtw8j31kw0u4kjn.jpg)

<br>

* 启动数据库

```bash
$ systemctl start mariadb.service
$ mysql 
```

* 备份后生成的一些文件

![](https://ws1.sinaimg.cn/large/006tNc79ly1fhje6hs102j31kw0f64nv.jpg)

![](https://ws2.sinaimg.cn/large/006tNc79ly1fhje6h4a43j31kw0f6kdx.jpg)

![](https://ws1.sinaimg.cn/large/006tNc79ly1fhje5oqw16j31dk08sdpy.jpg)

![](https://ws4.sinaimg.cn/large/006tNc79ly1fhje5ohh5ij31kw0f64ou.jpg)



#### <font size=4 color="#007FFF">增量备份 数据库(全库)</font>

增量备份：仅备份自上一次`完全备份`或`增量备份`以来变量的那些数据

* 先做一次全量备份

```bash
$ innobackupex --user root /data/backup
```

* 连接到数据库中，删除/增加一些数据，为一会做增量备份打下基础

```bash
$ mysql
> use hellodb;
> DELETE FROM students WHERE StuID=21;
> INSERT INTO students (Name,Age,Gender,ClassID,TeacherID) VALUES('Zhu Ba Jie',120,'M',2,3);
> exit;
```

* 第一次增量备份

```bash
$ innobackupex --incremental -u root /data/backup --incremental-basedir=/data/backup/2017-07-13_20-38-20/
```

![](https://ws1.sinaimg.cn/large/006tNc79ly1fhje42cakwj31kw0u84qr.jpg)

![](https://ws3.sinaimg.cn/large/006tNc79ly1fhje7gtxwpj31kw0f6b29.jpg)

<br>

* 再次连接到数据库，删除修改一些数据，再做`第二次增量备份`

```bash
$ mysql 
> use hellodb;
> DELETE FROM students WHERE StuID=1;
> EXIT;
```


* `第二次`增量备份

```bash
# 这里--incremental-basedir 为上一次增量备份的目录，而非全量备份的目录
$ innobackupex -u root --incremental /data/backup --incremental-basedir=/data/backup/2017-07-13_20-47-49
# 第二次增量的checkpoints
$ cat 2017-07-13_20-56-20/xtrabackup_checkpoints
backup_type = incremental
from_lsn = 1638999
to_lsn = 1640148
last_lsn = 1640148
compact = 0
recover_binlog_info = 0

# 第一次增量的checkpoints
$ cat 2017-07-13_20-47-49/xtrabackup_checkpoints
backup_type = incremental
from_lsn = 1636913
to_lsn = 1638999
last_lsn = 1638999
compact = 0
recover_binlog_info = 0
```

<br>

* 通过两次增量备份 + 全量备份 进行恢复数据库的操作

```bash
# 删库
$ cp /var/lib/mysql/mysql_bin.* /data/backup/binlogs
$ rm -rf /var/lib/mysql/*


1.合并增量备份(只提交不回滚)
# 只提交不回滚 全量备份
$ innobackupex --apply-log --redo-only 2017-07-13_20-38-20/
# 只提交不回滚 第一次增量+全量
$ innobackupex --apply-log --redo-only 2017-07-13_20-38-20 --incremental-dir=2017-07-13_20-47-49
# 只提交不回滚 第二增量+全量(第一次增量+全量)
$ innobackupex --apply-log --redo-only 2017-07-13_20-38-20 --incremental-dir=2017-07-13_20-56-20


2.开始提交并回滚
$ innobackupex --apply-log 2017-07-13_20-38-20/


3.拿着提交并回滚后的全量，进行恢复
$ innobackupex --copy-back 2017-07-13_20-38-20/


4.查看恢复后的数据目录
$ ll /var/lib/mysql 
total 40988
drwxr-x--- 2 root root     4096 Jul 13 21:17 2017-07-13_20-27-08
drwxr-x--- 2 root root     4096 Jul 13 21:17 hellodb
-rw-r----- 1 root root 18874368 Jul 13 21:17 ibdata1
-rw-r----- 1 root root  5242880 Jul 13 21:17 ib_logfile0
-rw-r----- 1 root root  5242880 Jul 13 21:17 ib_logfile1
-rw-r----- 1 root root 12582912 Jul 13 21:17 ibtmp1
drwxr-x--- 2 root root     4096 Jul 13 21:17 mysql
drwxr-x--- 2 root root     4096 Jul 13 21:17 performance_schema
drwxr-x--- 2 root root     4096 Jul 13 21:17 test
-rw-r----- 1 root root       23 Jul 13 21:17 xtrabackup_binlog_pos_innodb
-rw-r----- 1 root root      532 Jul 13 21:17 xtrabackup_info


5.修改目录权限
$ chown -R mysql.mysql /var/lib/mysql/*
```




-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=1285604&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)




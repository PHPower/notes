---
title: MHA配置与应用
date: 2017-07-14 16:24:04
tags: [mysql,linux,replication,MHA]
categories: [linux进阶,MySQL,MHA]
copyright: true
---

![](https://ws2.sinaimg.cn/large/006tNc79ly1fhji1oe9loj30xc0go7t0.jpg)

<blockquote class="blockquote-center">MHA（Master HA）是一款开源的 MySQL 的高可用程序，它为 MySQL 主从复制架构提供了 automating master failover 功能。
MHA在监控到 master 节点故障时，会提升其中拥有最新数据的 slave 节点成为新的 master 节点，
在此期间，MHA 会通过于其它从节点获取额外信息来避免一致性方面的问题。
MHA还提供了 master 节点的在线切换功能，即按需切换 master/slave 节点。
</blockquote>


### <font size=4 color="#38B0DE"> MHA组件</font>

#### Manager 节点

```bash
- masterha_check_ssh        MHA 依赖的 SSH 环境检测工具
- masterha_check_repl       MySQL 复制环境检测工具
- masterha_manager          MHA 服务主程序
- masterha_check_status     MHA 运行状态探测工具
- masterha_master_monitor   MySQL master 节点可用性监测工具
- masterha_master_switch    master 节点切换工具
- masterha_conf_host        添加或删除配置的节点
- masterha_stop             关闭 MHA 服务的工具
```

#### Node 节点

```bash
- save_binary_logs          保存和复制 master 的二进制日志
- apply_diff_relay_logs     识别差异的中继日志事件并应用于其它 slave
- filter_mysqlbinlog        去除不必要的 ROLLBACK 事件(MHA 已不再使用这个工具)
- purge_relay_logs          清除中继日志(不会阻塞 SQL 线程)
```

#### 自定义扩展


```bash
- secondary_check_script            通过多条网络路由检测 master 的可用性
- master_ip_failover_script         更新 application 使用的 masterip
- shutdown_script                   强制关闭 master 节点
- report_script                     发送报告
- init_conf_load_script             加载初始配置参数
- master_ip_online_change_script    更新 master 节点 ip 地址
```


需要购买VPS搭建ss的朋友可以点一下这个链接来购买：[HostDare](https://manage.hostdare.com/aff.php?aff=416)

速度测试在文章最后哦~

-------

<!-- more -->

### 拓扑结构

```bash
MHA Manager         IP: 172.16.1.40
MySQL Master        IP: 172.16.1.100
MySQL Slave1        IP: 172.16.1.70
MySQL Slave2        IP: 172.16.1.21
```

{% note primary %}### 配置安装MHA
{% endnote %}

#### <font szie=4 color="#007FFF">在主从复制基础上执行如下操作：修改主从节点的配置文件</font>


```bash
'主节点：'
	$ vim /etc/my.cnf.d/server.cnf
	[server]
	skip_name_resolve=ON
	innodb_file_per_table=ON
	log-bin=mysql_bin

	server_id=1
	relay_log=relay-log


'从节点：1'
	[server]
	skip_name_resolve=ON
	innodb_file_per_table=ON
	log-bin=mysql_bin

	server_id=10
	relay_log=relay-log
	# 关闭中继日志清除功能
	relay_log_purge=0
	# 开启只读
	read-only=1


'从节点：2'
	[server]
	skip_name_resolve=ON
	innodb_file_per_table=ON
	log_bin=mysql-bin

	server_id=20
	relay_log=relay-log
	relay_log_purge=0
	read-only=1


'重启服务'
$ systemctl restart mariadb.serivce 
```


#### <font szie=4 color="#007FFF">MySQL主节点生成密钥对，并复制给其他节点</font>

```bash
$ ssh-keygen -t rsa -P ''
$ ssh-copy-id -i .ssh/id_rsa.pub root@172.16.1.100
$ scp -p .ssh/authorized_keys .ssh/id_rsa{,.pub} .ssh/known_hosts root@172.16.1.70:/root/.ssh/
$ scp -p .ssh/authorized_keys .ssh/id_rsa{,.pub} .ssh/known_hosts root@172.16.1.21:/root/.ssh/
$ scp -p .ssh/authorized_keys .ssh/id_rsa{,.pub} .ssh/known_hosts root@172.16.1.40:/root/.ssh/
```

#### <font szie=4 color="#007FFF">下载MHA</font>

官方下载：[MHA](https://github.com/yoshinorim/mha4mysql-manager)


```bash
'管理节点(这里使用之前ProxySQL的主机作为管理节点)'
$ wget ftp://172.16.0.1/pub/Sources/6.x86_64/mha/mha4mysql-manager-0.56-0.el6.noarch.rpm
$ wget ftp://172.16.0.1/pub/Sources/6.x86_64/mha/mha4mysql-node-0.56-0.el6.noarch.rpm


'主从节点下载node包'
$ wget ftp://172.16.0.1/pub/Sources/6.x86_64/mha/mha4mysql-node-0.56-0.el6.noarch.rpm
```

#### <font szie=4 color="#007FFF">安装MHA</font>


```bash
'管理节点：' 两个包都需要安装 manager、node
$ yum install -y ./mha4mysql-manager-0.56-0.el6.noarch.rpm
$ yum install -y ./mha4mysql-node-0.56-0.el6.noarch.rpm


'主从节点'
$ yum install -y ./mha4mysql-node-0.56-0.el6.noarch.rpm
```


#### <font szie=4 color="#007FFF">主节点创建MHA远程连接管理的用户</font>

```bash
> GRANT ALL PRIVILEGES ON *.* TO 'mhaadmin'@'172.16.1.%' IDENTIFIED BY 'mhapass';
> FLUSH PRIVILEGES;
```

#### <font szie=4 color="#007FFF">配置MHA Manager 管理节点</font>


```bash
$ vim /etc/masterha/app1.cnf
# 通用配置
[server default] 
# 管理员账号
user=mhaadmin # MySQL Administrator 
# 管理员密码
password=mhapass # MySQL Administrator's password 
# 管理工作路径，会自动创建
manager_workdir=/data/masterha/app1 
# 管理日志路径
manager_log=/data/masterha/app1/manager.log 
# 远程节点的工作路径(node节点)
remote_workdir=/data/masterha/app1 
# ssh用户账号
ssh_user=root 
# 复制时用的账号
repl_user=copyuser 
# 复制时用的密码
repl_password=root@123
# ping探测间隔，1s
ping_interval=1


# 各server节点的专用配置，server1、2、3为固定格式
[server1] 
# 主机地址配置，可以是主机名，也可以是IP地址。
hostname=172.16.1.100
#ssh_port=22022 
# master候选主机，当主节点宕机，这些主机可以成为master
candidate_master=1

[server2] 
hostname=172.16.1.70
#ssh_port=22022 
candidate_master=1

[server3] 
hostname=172.16.1.21
#ssh_port=22022 
#no_master=1
```

#### <font szie=4 color="#007FFF">检查通信：使用 masterha_check_ssh命令，指定配置文件路径</font>


```bash
'检查SSH通信'
$ masterha_check_ssh --conf=/etc/masterha/app1.cnf
Fri Jul 14 11:13:47 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Fri Jul 14 11:13:47 2017 - [info] Reading application default configuration from /etc/masterha/app1.cnf..
Fri Jul 14 11:13:47 2017 - [info] Reading server configuration from /etc/masterha/app1.cnf..
Fri Jul 14 11:13:47 2017 - [info] Starting SSH connection tests..
Fri Jul 14 11:13:47 2017 - [debug]
Fri Jul 14 11:13:47 2017 - [debug]  Connecting via SSH from root@172.16.1.100(172.16.1.100:22) to root@172.16.1.70(172.16.1.70:22)..
Fri Jul 14 11:13:47 2017 - [debug]   ok.
Fri Jul 14 11:13:47 2017 - [debug]  Connecting via SSH from root@172.16.1.100(172.16.1.100:22) to root@172.16.1.21(172.16.1.21:22)..
Fri Jul 14 11:13:47 2017 - [debug]   ok.
Fri Jul 14 11:13:48 2017 - [debug]
Fri Jul 14 11:13:47 2017 - [debug]  Connecting via SSH from root@172.16.1.70(172.16.1.70:22) to root@172.16.1.100(172.16.1.100:22)..
Fri Jul 14 11:13:47 2017 - [debug]   ok.
Fri Jul 14 11:13:47 2017 - [debug]  Connecting via SSH from root@172.16.1.70(172.16.1.70:22) to root@172.16.1.21(172.16.1.21:22)..
Fri Jul 14 11:13:47 2017 - [debug]   ok.
Fri Jul 14 11:13:48 2017 - [debug]
Fri Jul 14 11:13:48 2017 - [debug]  Connecting via SSH from root@172.16.1.21(172.16.1.21:22) to root@172.16.1.100(172.16.1.100:22)..
Fri Jul 14 11:13:48 2017 - [debug]   ok.
Fri Jul 14 11:13:48 2017 - [debug]  Connecting via SSH from root@172.16.1.21(172.16.1.21:22) to root@172.16.1.70(172.16.1.70:22)..
Fri Jul 14 11:13:48 2017 - [debug]   ok.
Fri Jul 14 11:13:48 2017 - [info] All SSH connection tests passed successfully.



'检查复制集群'
$ masterha_check_repl --conf=/etc/masterha/app1.cnf
Fri Jul 14 11:15:16 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Fri Jul 14 11:15:16 2017 - [info] Reading application default configuration from /etc/masterha/app1.cnf..
Fri Jul 14 11:15:16 2017 - [info] Reading server configuration from /etc/masterha/app1.cnf..
Fri Jul 14 11:15:16 2017 - [info] MHA::MasterMonitor version 0.56.
Creating directory /data/masterha/app1.. done.
Fri Jul 14 11:15:16 2017 - [info] GTID failover mode = 0
Fri Jul 14 11:15:16 2017 - [info] Dead Servers:
Fri Jul 14 11:15:16 2017 - [info] Alive Servers:
Fri Jul 14 11:15:16 2017 - [info]   172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:15:16 2017 - [info]   172.16.1.70(172.16.1.70:3306)
Fri Jul 14 11:15:16 2017 - [info]   172.16.1.21(172.16.1.21:3306)
Fri Jul 14 11:15:16 2017 - [info] Alive Slaves:
Fri Jul 14 11:15:16 2017 - [info]   172.16.1.70(172.16.1.70:3306)  Version=5.5.44-MariaDB-log (oldest major version between slaves) log-bin:enabled
Fri Jul 14 11:15:16 2017 - [info]     Replicating from 172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:15:16 2017 - [info]     Primary candidate for the new Master (candidate_master is set)
Fri Jul 14 11:15:16 2017 - [info]   172.16.1.21(172.16.1.21:3306)  Version=5.5.44-MariaDB-log (oldest major version between slaves) log-bin:enabled
Fri Jul 14 11:15:16 2017 - [info]     Replicating from 172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:15:16 2017 - [info] Current Alive Master: 172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:15:16 2017 - [info] Checking slave configurations..
Fri Jul 14 11:15:16 2017 - [info] Checking replication filtering settings..
Fri Jul 14 11:15:16 2017 - [info]  binlog_do_db= , binlog_ignore_db=
Fri Jul 14 11:15:16 2017 - [info]  Replication filtering check ok.
Fri Jul 14 11:15:16 2017 - [error][/usr/share/perl5/vendor_perl/MHA/Server.pm, ln393] 172.16.1.70(172.16.1.70:3306): User copyuser does not exist or does not have REPLICATION SLAVE privilege! Other slaves can not start replication from this host.
Fri Jul 14 11:15:16 2017 - [error][/usr/share/perl5/vendor_perl/MHA/MasterMonitor.pm, ln424] Error happened on checking configurations.  at /usr/share/perl5/vendor_perl/MHA/ServerManager.pm line 1403.
Fri Jul 14 11:15:16 2017 - [error][/usr/share/perl5/vendor_perl/MHA/MasterMonitor.pm, ln523] Error happened on monitoring servers.
Fri Jul 14 11:15:16 2017 - [info] Got exit code 1 (Not master dead).

MySQL Replication Health is NOT OK!



这里错误是因为，从节点没有copyuser这个用户。
这时，我们再建一个用户，用于复制即可：
'主节点'
	> GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'copy'@'172.16.1.%' IDENTIFIED BY 'root@123';
	> FLUSH PRIVILEGES;
	
	
	
'修改配置文件：'
		$ vim /etc/masterha/app1.cnf
		repl_user=copy
		
		
		
'重新检查：'
$ masterha_check_repl --conf=/etc/masterha/app1.cnf
Fri Jul 14 11:20:38 2017 - [warning] Global configuration file /etc/masterha_default.cnf not found. Skipping.
Fri Jul 14 11:20:38 2017 - [info] Reading application default configuration from /etc/masterha/app1.cnf..
Fri Jul 14 11:20:38 2017 - [info] Reading server configuration from /etc/masterha/app1.cnf..
Fri Jul 14 11:20:38 2017 - [info] MHA::MasterMonitor version 0.56.
Fri Jul 14 11:20:39 2017 - [info] GTID failover mode = 0
Fri Jul 14 11:20:39 2017 - [info] Dead Servers:
Fri Jul 14 11:20:39 2017 - [info] Alive Servers:
Fri Jul 14 11:20:39 2017 - [info]   172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:20:39 2017 - [info]   172.16.1.70(172.16.1.70:3306)
Fri Jul 14 11:20:39 2017 - [info]   172.16.1.21(172.16.1.21:3306)
Fri Jul 14 11:20:39 2017 - [info] Alive Slaves:
Fri Jul 14 11:20:39 2017 - [info]   172.16.1.70(172.16.1.70:3306)  Version=5.5.44-MariaDB-log (oldest major version between slaves) log-bin:enabled
Fri Jul 14 11:20:39 2017 - [info]     Replicating from 172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:20:39 2017 - [info]     Primary candidate for the new Master (candidate_master is set)
Fri Jul 14 11:20:39 2017 - [info]   172.16.1.21(172.16.1.21:3306)  Version=5.5.44-MariaDB-log (oldest major version between slaves) log-bin:enabled
Fri Jul 14 11:20:39 2017 - [info]     Replicating from 172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:20:39 2017 - [info] Current Alive Master: 172.16.1.100(172.16.1.100:3306)
Fri Jul 14 11:20:39 2017 - [info] Checking slave configurations..
Fri Jul 14 11:20:39 2017 - [info] Checking replication filtering settings..
Fri Jul 14 11:20:39 2017 - [info]  binlog_do_db= , binlog_ignore_db=
Fri Jul 14 11:20:39 2017 - [info]  Replication filtering check ok.
Fri Jul 14 11:20:41 2017 - [info] Checking replication health on 172.16.1.70..
Fri Jul 14 11:20:41 2017 - [info]  ok.
Fri Jul 14 11:20:41 2017 - [info] Checking replication health on 172.16.1.21..
Fri Jul 14 11:20:41 2017 - [info]  ok.
Fri Jul 14 11:20:41 2017 - [warning] master_ip_failover_script is not defined.
Fri Jul 14 11:20:41 2017 - [warning] shutdown_script is not defined.
Fri Jul 14 11:20:41 2017 - [info] Got exit code 0 (Not master dead).

MySQL Replication Health is OK.
```


#### <font szie=4 color="#007FFF">检查通过后，开始启动MHA</font>

```bash
$ nohup masterha_manager --conf=/etc/masterha/app1.cnf &> /data/masterha/app1/manager.log  &
$ ps aux 
root      2453  4.6  2.1 298668 21504 pts/0    S    11:32   0:00 perl /usr/bin/masterha_manager --conf=/etc/masterha/app1.cnf
```

#### <font szie=4 color="#007FFF">检查master状态</font>

```bash
$ masterha_check_status --conf=/etc/masterha/app1.cnf
app1 (pid:2453) is running(0:PING_OK), master:172.16.1.100

上面的信息中"app1 (pid:4978) is running(0:PING_OK)"表示 MHA 服务运行 OK，否则，则会显示为类似"app1 is stopped(1:NOT_RUNNING)."
```

-------

{% note success %}### 测试故障转移
{% endnote %}

#### <font size=4 color="#32CD99">在master节点，关闭mariadb服务，测试故障转移是否成功</font>


```bash
$ killall -9 mysqld mysqld_safe
$ ss -tnl | grep 3306
```

#### <font size=4 color="#32CD99">MHA manager节点</font>

```bash
$ ps aux 
[1]+  Done                    nohup masterha_manager --conf=/etc/masterha/app1.cnf &>/data/masterha/app1/manager.log
在完成故障切换之后，manager会自动停止

$ masterha_check_status --conf=/etc/masterha/app1.cnf
app1 is stopped(2:NOT_RUNNING).
```


#### <font size=4 color="#32CD99">查看从节点是否升级为主节点</font>

```bash
$ less /data/masterha/app1/manager.log
----- Failover Report -----

app1: MySQL Master failover 172.16.1.100(172.16.1.100:3306) to 172.16.1.70(172.16.1.70:3306) succeeded

Master 172.16.1.100(172.16.1.100:3306) is down!

Check MHA Manager logs at localhost.localdomain:/data/masterha/app1/manager.log for details.

Started automated(non-interactive) failover.
The latest slave 172.16.1.70(172.16.1.70:3306) has all relay logs for recovery.
Selected 172.16.1.70(172.16.1.70:3306) as a new master.
172.16.1.70(172.16.1.70:3306): OK: Applying all logs succeeded.
172.16.1.21(172.16.1.21:3306): This host has the latest relay log events.
Generating relay diff files from the latest slave succeeded.
172.16.1.21(172.16.1.21:3306): OK: Applying all logs succeeded. Slave started, replicating from 172.16.1.70(172.16.1.70:3306)
172.16.1.70(172.16.1.70:3306): Resetting slave info succeeded.
Master failover to 172.16.1.70(172.16.1.70:3306) completed successfully.


'从节点：172.16.1.70' -> 已经提升为主节点
	> SHOW SLAVE HOSTS;
	+-----------+------+------+-----------+
	| Server_id | Host | Port | Master_id |
	+-----------+------+------+-----------+
	|        20 |      | 3306 |        10 |
	+-----------+------+------+-----------+
	1 row in set (0.00 sec)

	> CREATE DATABASE mhatest;
	Query OK, 1 row affected (0.00 sec)

	成功创建数据库


'从节点：172.16.1.21'
	查看是否成功创建数据库
	> SHOW DATABASES;
	+--------------------+
	| Database           |
	+--------------------+
	| information_schema |
	| hellodb            |
	| mhatest            |
	| my_db              |
	| mydb               |
	| mysql              |
	| performance_schema |
	| test               |
	+--------------------+
	8 rows in set (0.00 sec)

'现在已经成功实现故障转移'
```




#### <font size=4 color="#32CD99">修复之前的master为slave</font>


```bash
现Master节点：1.70
	$ mysqldump -uroot -x -R -E --triggers --master-data=2 --all-databases > alldb.sql
	$ scp alldb.sql root@172.16.1.100:/root

1.100：
	$ vim /etc/my.cnf.d/server.cnf
	[server]
	skip_name_resolve=ON
	innodb_file_per_table=ON
	log-bin=mysql_bin

	server_id=1
	relay_log=relay-log
	relay_log_purge=0
	read_only=1

	$ systemctl start mariadb 
	$ mysql < alldb.sql  
	$ mysql 
	> SHOW DATABASES;
	+--------------------+
	| Database           |
	+--------------------+
	| information_schema |
	| hellodb            |
	| mhatest            |
	| my_db              |
	| mydb               |
	| mysql              |
	| performance_schema |
	| test               |
	+--------------------+
	8 rows in set (0.00 sec)

	> CHANGE MASTER TO MASTER_HOST='172.16.1.70',MASTER_USER='copy',MASTER_PASSWORD='root@123',MASTER_LOG_FILE='mysql_bin.000005',MASTER_LOG_POS=334,MASTER_PORT=3306;
	> START SLAVE;
	# 查看是否正常运行
	> SHOW SLAVE STATUS\G
	# 刷新授权，否则manager无法连接
	> FLUSH PRIVILEGES;


'主节点'
	> SHOW SLAVE HOSTS;
	+-----------+------+------+-----------+
	| Server_id | Host | Port | Master_id |
	+-----------+------+------+-----------+
	|         1 |      | 3306 |        10 |
	|        20 |      | 3306 |        10 |
	+-----------+------+------+-----------+
	2 rows in set (0.00 sec)



'MHA节点检测：'
	$ masterha_check_repl --conf=/etc/masterha/app1.cnf
	Fri Jul 14 12:01:17 2017 - [info] Checking replication health on 172.16.1.100..
	Fri Jul 14 12:01:17 2017 - [info]  ok.
	Fri Jul 14 12:01:17 2017 - [info] Checking replication health on 172.16.1.21..
	Fri Jul 14 12:01:17 2017 - [info]  ok.
	Fri Jul 14 12:01:17 2017 - [warning] master_ip_failover_script is not defined.
	Fri Jul 14 12:01:17 2017 - [warning] shutdown_script is not defined.
	Fri Jul 14 12:01:17 2017 - [info] Got exit code 0 (Not master dead).

	MySQL Replication Health is OK.

	# 再次启动MHA manager，防止主节点宕机。开始监控
	$ nohup masterha_manager --conf=/etc/masterha/app1.cnf &> /data/masterha/app1/manager.log  &


'恢复完成'
```

#### <font size=4 color="#32CD99">停止MHA</font>

```bash
$ masterha_stop --conf=/etc/masterha/app1.cnf
```


-------

### VPS测速

![](https://ws2.sinaimg.cn/large/006tNc79ly1fhltd2hclwj31dg0use4j.jpg)

-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=452986458&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



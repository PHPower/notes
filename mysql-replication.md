---
title: MySQL Replication 主从复制
date: 2017-07-14 14:38:37
tags: [mysql,linux,replication]
categories: [linux进阶,MySQL]
copyright: ture
---

![](https://ws2.sinaimg.cn/large/006tNc79ly1fhjeqyspvwj30ap03nq2r.jpg)

<blockquote class="blockquote-center">MySQL Replication实现了Master节点可读可写，Slave节点只读
这样的逻辑结构，大大降低了主节点的压力。
因为MySQL的主要压力都是读操作，而非写操作。
通过增加Slave节点的数量，负载均衡读操作，大大提高用户体验，提升产品竞争力。
</blockquote>

<font size=4 color="#38B0DE">**主节点(Master)：**</font> 可读可写

<font size=4 color="#32CD99">**从节点(Slave)：**</font> read only 只读


 
```
主节点故障：
    立即提升从节点为主节点 --> 使用IP地址漂移 --> keepalived实现

 主从同步机制：
    通过从节点连接到主节点，同步主节点的二进制日志，来实现主从同步
    将主节点的二进制内容 同步至从节点的中继日志中
    从节点通过将中继日志 写入到本机的二进制日志中，实现主从同步
```


<font size=4 color="#FF7F00">**双主模式：**</font> 每个节点都读对方的二进制日志，都使用二进制日志





<!-- more -->

{% note primary %}### 主从复制
{% endnote %}

 <font szie=4 color="#007FFF">**编辑各节点的MySQL配置文件**</font>

* 编辑主节点配置文件

```bash
$ vim /etc/my.cnf.d/server.cnf
[server]
skip_name_resolve=ON
innodb_file_per_table=ON
# 开启二进制日志
log-bin=mysql_bin
# 设置服务器ID
server_id=1

$ systemctl restart mariadb.service 
```

* 编辑从节点配置文件

```bash
$ vim /etc/my.cnf.d/server.cnf
[server]
skip_name_resolve=ON
innodb_file_per_table=ON
# 开启二进制日志
log-bin=mysql_bin
# 设置服务器ID
server_id=10
# 启动中继日志
relay_log=relay-log
# 设置只读，对普通用户有效
read_only=ON

$ systemctl restart mariadb.service
```


#### <font szie=4 color="#007FFF">创建复制时使用的数据库用户</font>


```bash
$ mysql 
> GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'copyuser'@'172.16.1.%' IDENTIFIED BY 'root@123';
> FLUSH PRIVILEGES;
> SHOW MASTER STATUS;
+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+------------------+----------+--------------+------------------+
| mysql_bin.000001 |      497 |              |                  |
+------------------+----------+--------------+------------------+
1 row in set (0.00 sec)

这里的Position的497是之后在SLAVE节点时使用MASTER_LOG_POS= 这里填写的位置，也就是MASTER_LOG_POS=497
```

#### <font szie=4 color="#007FFF">配置从节点连接主节点</font>

```bash
$ mysql 
> CHANGE MASTER TO MASTER_USER='copyuser',MASTER_PASSWORD='root@123',MASTER_HOST='172.16.1.100',MASTER_PORT=3306,MASTER_LOG_FILE='mysql_bin.000001',MASTER_LOG_POS=497;
> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State:
               	  # 连接的主机IP地址
                  Master_Host: 172.16.1.100
                  # 连接主节点的用户
                  Master_User: copyuser
                  # 主节点的端口
                  Master_Port: 3306
                # 连接重试时间 60s
                Connect_Retry: 60
              # 主节点的二进制日志文件
              Master_Log_File: mysql_bin.000001
          # 从主节点二进制日志哪个位置开始读
          Read_Master_Log_Pos: 497
          	   # 中继日志
               Relay_Log_File: relay-log.000001
                # 在本机中继日志哪个位置开始记录
                Relay_Log_Pos: 4
        Relay_Master_Log_File: mysql_bin.000001
             # IO Thread 是否运行
             Slave_IO_Running: No
            # SQL Thread 是否运行
            Slave_SQL_Running: No
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          # 从主节点复制到从节点的二进制日志位置，如果与Read_Master_Log_Pos的值相同，则从节点没有落后于主节点
          Exec_Master_Log_Pos: 497
              Relay_Log_Space: 245
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        # 落后于主节点多少秒
        Seconds_Behind_Master: NULL
Master_SSL_Verify_Server_Cert: No
				# 前一次IO线程错误码
                Last_IO_Errno: 0
                # 错误信息
                Last_IO_Error:
               # 前一次SQL线程错误码
               Last_SQL_Errno: 0
               # 错误信息
               Last_SQL_Error:
  # 忽略哪个SERVER ID
  Replicate_Ignore_Server_Ids:
  			 # 主节点Server_ID号
             Master_Server_Id: 0
1 row in set (0.00 sec)
```

#### <font szie=4 color="#007FFF">启动复制线程，并查看错误日志</font>

```bash
> START SLAVE;
Query OK, 0 rows affected (0.00 sec)

# 查看错误日志中对于复制线程记录的信息：
$ cat /var/log/mysql/
170713 21:55:20 [Note] 'CHANGE MASTER TO executed'. Previous state master_host='', master_port='3306', master_log_file='', master_log_pos='4'. New state master_host='172.16.1.100', master_port='3306', master_log_file='mysql_bin.000001', master_log_pos='497'.
170713 22:05:25 [Note] Slave SQL thread initialized, starting replication in log 'mysql_bin.000001' at position 497, relay log './relay-log.000001' position: 4
170713 22:05:25 [Note] Slave I/O thread: connected to master 'copyuser@172.16.1.100:3306',replication started in log 'mysql_bin.000001' at position 497
```


#### <font szie=4 color="#007FFF">测试主从复制是否能够正常运行</font>


```bash
# 主节点
> CREATE DATABASE mydb;

# 从节点
> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mydb               |
| mysql              |
| performance_schema |
| test               |
+--------------------+
5 rows in set (0.00 sec)
```

#### <font szie=4 color="#007FFF">如果从节点出现错误，数据不一致，该如何解决？</font>

* 停止复制线程

```bash
> STOP SLAVE;
```

* 重新设置MASTER_LOG_POS

```bash
# 这里的POS位置，需要在主节点上查看SHOW MASTER STATUS;
> CHANGE MASTER TO MASTER_USER='copyuser',MASTER_PASSWORD='root@123',MASTER_HOST='172.16.1.100',MASTER_PORT=3306,MASTER_LOG_FILE='mysql_bin.000002',MASTER_LOG_POS=245;
```

* 启动复制线程

```
> START SLAVE;
```


-------

{% note success %}### 主主复制
{% endnote %}



#### <font size=4 color="#32CD99">编辑两个节点的MySQL配置文件</font>

* server_id=1的节点

```bash
$ vim /etc/my.cnf.d/server.cnf
[server]
skip_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin
# server id标识符
server_id=1
relay_log=relay-log
# 起始偏移值
auto_increment_offset=1
# 步进值
auto_increment_increment=2
```

* server_id=10的节点

```
$ vim /etc/my.cnf.d/server.cnf
[server]
skip_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin
server_id=10
relay_log=relay-log
# 起始偏移值
auto_increment_offset=2
# 步进值
auto_increment_increment=2
```

#### <font size=4 color="#32CD99">两个主节点创建复制时使用的用户 (两台节点都要执行下面的步骤)</font>


```bash
$ systemctl start mariadb.service 
$ mysql 
> GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'copyuser'@'172.16.1.%' IDENTIFIED BY 'root@123';
> FLUSH PRIVILEGES;
```

#### <font size=4 color="#32CD99">两个节点相互配置对方为主节点的信息</font>


```bash
> SHOW MASTER STATUS;

# server_id=1的节点：
> CHANGE MASTER TO MASTER_USER='copyuser',MASTER_PASSWORD='root@123',MASTER_HOST='172.16.1.70',MASTER_PORT=3306,MASTER_LOG_FILE='mysql_bin.000003',MASTER_LOG_POS=507;

# server_id=10的节点：
> CHANGE MASTER TO MASTER_USER='copyuser',MASTER_PASSWORD='root@123',MASTER_HOST='172.16.1.100',MASTER_PORT=3306,MASTER_LOG_FILE='mysql_bin.000003',MASTER_LOG_POS=507;

# 查看是否正常
> SHOW SLAVE STATUS\G
 

# 开启从节点复制线程(两台都执行)
> START SLAVE;
> SHOW SLAVE STATUS\G
```

#### <font size=4 color="#32CD99">测试</font>


* id=1的节点创建数据库mydb,并创建表tb1

```bash
> CREATE DATABASE mydb;
Query OK, 1 row affected (0.00 sec)
> CREATE TABLE tb1 (id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,Name CHAR(30));
Query OK, 0 rows affected (0.02 sec)
```

* id=10的节点use mydb,查看表结构

```bash
> use mydb;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

> DESC tb1;
+-------+------------------+------+-----+---------+----------------+
| Field | Type             | Null | Key | Default | Extra          |
+-------+------------------+------+-----+---------+----------------+
| id    | int(10) unsigned | NO   | PRI | NULL    | auto_increment |
| Name  | char(30)         | YES  |     | NULL    |                |
+-------+------------------+------+-----+---------+----------------+
```

* id=1的节点插入tb1中数据

```bash
> INSERT INTO tb1 (Name) VALUES ('stu1'),('stu2');
Query OK, 2 rows affected (0.01 sec)
Records: 2  Duplicates: 0  Warnings: 0

> SELECT * FROM tb1;
+----+------+
| id | Name |
+----+------+
|  1 | stu1 |
|  3 | stu2 |
+----+------+
2 rows in set (0.00 sec)
```

* id=10节点插入数据

```bash
> INSERT INTO tb1 (Name) VALUES ('stu3'),('stu4');
Query OK, 2 rows affected (0.02 sec)
Records: 2  Duplicates: 0  Warnings: 0

> SELECT * FROM tb1;
+----+------+
| id | Name |
+----+------+
|  1 | stu1 |
|  3 | stu2 |
|  4 | stu3 |
|  6 | stu4 |
+----+------+
4 rows in set (0.00 sec)
```


#### <font size=4 color="#32CD99">主主模式下生成的文件</font>

```bash
 cat /var/lib/mysql/master.info  --> 此文件也是记录在内存缓冲区中，需要在MySQL配置文件中添加 'sync_master_info=ON'
18
# 从主节点的哪个二进制日志复制
mysql_bin.000003
# 复制到二进制日志的哪个位置
838
# 主节点IP
172.16.1.100
# 连接的用户
copyuser
# 密码
root@123
# 端口
3306
# 超时时间
60
0

$ cat /var/lib/mysql/relay-log.info --> 配置文件中开启 -->  sync_relay_log_info=ON
./relay-log.000002
860
mysql_bin.000003
838
```




-------

{% note info %}### 半同步复制
{% endnote %}

#### <font size=4 color="#38B0DE">配置两台数据库主机为主从复制</font>


```bash
# 主节点：
	$ vim /etc/my.cnf.d/server.cnf
	[server]
	skip_name_resolve=ON
	innodb_file_per_table=ON
	log-bin=mysql_bin
	server_id=1


# 从节点：
	$ vim /etc/my.cnf.d/server.cnf
	[server]
	skip_name_resolve=ON
	innodb_file_per_table=ON
	log-bin=mysql_bin
	server_id=10
	relay_log=relay-log
```

#### <font size=4 color="#38B0DE">主节点创建复制时使用的用户</font>


```bash
> GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'copyuser'@'172.16.1.%' IDENTIFIED BY 'root@123';
> FLUSH PRIVILEGES;
> SHOW MASTER STATUS;
+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+------------------+----------+--------------+------------------+
| mysql_bin.000003 |      497 |              |                  |
+------------------+----------+--------------+------------------+
1 row in set (0.00 sec)
```

#### <font size=4 color="#38B0DE">从节点配置主节点配置信息</font>


```bash
> CHANGE MASTER TO MASTER_USER='copyuser',MASTER_PASSWORD='root@123',MASTER_HOST='172.16.1.100',MASTER_PORT=3306,MASTER_LOG_FILE='mysql_bin.000003',MASTER_LOG_POS=497;
Query OK, 0 rows affected (0.01 sec)

MariaDB [(none)]> START SLAVE;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> SHOW SLAVE STATUS\G
```

#### <font size=4 color="#38B0DE">安装半同步的插件</font>


```bash
'主节点：'
	> INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
	> SHOW PLUGINS;
	| rpl_semi_sync_master           | ACTIVE   | REPLICATION        | semisync_master.so | GPL     |


'从节点：'
	> INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
	> SHOW PLUGINS;
	| rpl_semi_sync_slave            | ACTIVE   | REPLICATION        | semisync_slave.so | GPL     |
```



#### <font size=4 color="#38B0DE">启用半同步的插件</font>


```bash
'查看是否启用插件：'
	> SHOW GLOBAL VARIABLES LIKE '%semi%';
	+------------------------------------+-------+
	| Variable_name                      | Value |
	+------------------------------------+-------+
	| rpl_semi_sync_master_enabled       | OFF   | 			# 关闭状态，未开启
	| rpl_semi_sync_master_timeout       | 10000 | 			# 等待从节点的超时时间10000毫秒 --> 10s
	| rpl_semi_sync_master_trace_level   | 32    | 			# 内部信息的追踪级别
	| rpl_semi_sync_master_wait_no_slave | ON    | 			# 如果没有半同步节点，是否等待。默认为等待，不过超过超时时间，则不等待
	+------------------------------------+-------+
	4 rows in set (0.00 sec)


'主节点'
	> SET @@global.rpl_semi_sync_master_enabled=ON;


'从节点'
	> SET @@global.rpl_semi_sync_slave_enabled=ON;
```


#### <font size=4 color="#38B0DE">从节点开启半同步复制</font>

```bash
> STOP SLAVE IO_THREAD;
> START SLAVE IO_THREAD;
```

#### <font size=4 color="#38B0DE">主节点测试半同步</font>

```bash
$ mysql < hellodb.sql 
$ mysql 
# 查看统计数据
> SHOW GLOBAL STATUS  LIKE "rpl%";
+--------------------------------------------+-------------+
| Variable_name                              | Value       |
+--------------------------------------------+-------------+
| Rpl_semi_sync_master_clients               | 1           |
| Rpl_semi_sync_master_net_avg_wait_time     | 167         |
| Rpl_semi_sync_master_net_wait_time         | 5849        |
| Rpl_semi_sync_master_net_waits             | 35          |
| Rpl_semi_sync_master_no_times              | 0           |
| Rpl_semi_sync_master_no_tx                 | 0           |
| Rpl_semi_sync_master_status                | ON          |
| Rpl_semi_sync_master_timefunc_failures     | 0           |
| Rpl_semi_sync_master_tx_avg_wait_time      | 170         |
| Rpl_semi_sync_master_tx_wait_time          | 5634        |
| Rpl_semi_sync_master_tx_waits              | 33          |
| Rpl_semi_sync_master_wait_pos_backtraverse | 0           |
| Rpl_semi_sync_master_wait_sessions         | 0           |
| Rpl_semi_sync_master_yes_tx                | 35          |
| Rpl_status                                 | AUTH_MASTER |
+--------------------------------------------+-------------+
15 rows in set (0.00 sec)
```

#### <font size=4 color="#38B0DE">设置从节点只复制指定数据库</font>

```bash
> SHOW GLOBAL VARIABLES LIKE '%do_db%';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| replicate_do_db |       |
+-----------------+-------+
1 row in set (0.00 sec)

> STOP SLAVE;
> SET @@global.replicate_do_db=mydb;
> START SLAVE;
> SHOW GLOBAL VARIABLES LIKE '%do_db%';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| replicate_do_db | mydb  |
+-----------------+-------+
1 row in set (0.00 sec)

> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.16.1.100
                  Master_User: copyuser
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql_bin.000003
          Read_Master_Log_Pos: 7907
               Relay_Log_File: relay-log.000004
                Relay_Log_Pos: 529
        Relay_Master_Log_File: mysql_bin.000003
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: mydb
```


#### <font size=4 color="#38B0DE">测试</font>


* 测试是否可以正常复制

```bash
'主节点'
> DROP TABLE hellodb.teachers;

'从节点'
> use hellodb;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

> SHOW TABLES;
+-------------------+
| Tables_in_hellodb |
+-------------------+
| classes           |
| coc               |
| courses           |
| scores            |
| students          |
| toc               |
+-------------------+
6 rows in set (0.00 sec)
```

* 测试mydb是否可以正常复制

```bash
'主节点'
	> CREATE DATABASE mydb;
	> use mydb;
	> CREATE TABLE tb1 (id INT(10),Name CHAR(20));


'从节点'
	> use mydb;
	> SHOW TABLES;
	+----------------+
	| Tables_in_mydb |
	+----------------+
	| tb1            |
	+----------------+
	1 row in set (0.00 sec)
```

-------

{% note warning %}### 主从复制的读写分离{% endnote %}

#### <font size=4 color="#FF7F00">在上一个实验的基础上，也就是一个主从的基础上，再做一台从节点</font>


```bash
# 不过之前的从节点配置了只同步一个数据库，我们需要将其配置修改一下：
	> STOP SLAVE;
	> SET @@global.replicate_do_db='';
	> START SLAVE;


'主节点'：备份全库
$ mysqldump -uroot --all-databases -R -E --triggers -x --master-data=2 > /root/alldb.sql 
$ scp alldb.sql 172.16.1.21:/root


'新增的从节点' IP: 172.16.1.21
$ less alldb.sql 
...
-- CHANGE MASTER TO MASTER_LOG_FILE='mysql_bin.000004', MASTER_LOG_POS=245;
...

$ vim /etc/my.cnf.d/server.cnf
[server]
skip_name_resolve=ON
innodb_file_per_table=ON

server_id=20
relay_log=relay-log
read-only=ON

$ systemctl start mariadb.service
$ mysql < alldb.sql 
$ mysql 
> CHANGE MASTER TO MASTER_HOST='172.16.1.100',MASTER_USER='copyuser',MASTER_PASSWORD='root@123',MASTER_LOG_FILE='mysql_bin.000004',MASTER_LOG_POS=245,MASTER_PORT=3306;
Query OK, 0 rows affected (0.03 sec)
> SHOW SLAVE STATUS\G
> START SLAVE;
```


* 测试

```bash
1.'主节点创建一个数据库，测试一下两个从节点是否可以正常复制：'
	> CREATE DATABASE testdb;
	> use testdb;
	> CREATE TABLE tb1 (id INT(10));
	> CREATE DATABASE testdb;
	Query OK, 1 row affected (10.00 sec)

	MariaDB [(none)]> SHOW DATABASES;
	+--------------------+
	| Database           |
	+--------------------+
	| information_schema |
	| hellodb            |
	| my_db              |
	| mydb               |
	| mysql              |
	| performance_schema |
	| test               |
	| testdb             |
	+--------------------+
	8 rows in set (0.00 sec)


2.'从节点查看：'
	SLAVE1：
		> SHOW DATABASES;
		+--------------------+
		| Database           |
		+--------------------+
		| information_schema |
		| hellodb            |
		| my_db              |
		| mydb               |
		| mysql              |
		| performance_schema |
		| test               |
		| testdb             |
		+--------------------+
		8 rows in set (0.00 sec)

	SLAVE2：
		> SHOW DATABASES;
		+--------------------+
		| Database           |
		+--------------------+
		| information_schema |
		| hellodb            |
		| my_db              |
		| mydb               |
		| mysql              |
		| performance_schema |
		| test               |
		| testdb             |
		+--------------------+
		8 rows in set (0.00 sec)
```




#### <font size=4 color="#FF7F00">在主节点创建一个给ProxySQL进行远程登录MySQL数据库的账号(从节点自动同步)</font>


```bash
'主节点'
> GRANT ALL ON *.* TO 'myadmin'@'172.16.1.%' IDENTIFIED BY 'root@123';
> SELECT user,host,password FROM mysql.user;
+---------+------------+-------------------------------------------+
| user    | host       | password                                  |
+---------+------------+-------------------------------------------+
| root    | localhost  |                                           |
| root    | test-2     |                                           |
| root    | 127.0.0.1  |                                           |
| root    | ::1        |                                           |
|         | localhost  |                                           |
|         | test-2     |                                           |
| myadmin | 172.16.1.% | *A00C34073A26B40AB4307650BFB9309D6BFA6999 |
+---------+------------+-------------------------------------------+
7 rows in set (0.00 sec)
```



#### <font size=4 color="#FF7F00">在新的一台虚拟机上安装proxySQL</font>

```bash
$ wget ftp://172.16.0.1/pub/Sources/7.x86_64/proxysql/proxysql-1.3.6-1-centos7.x86_64.rpm
$ yum install ./proxysql-1.3.6-1-centos7.x86_64.rpm
# 备份配置文件
$ cp /etc/proxysql.cnf{,.bak}

# 自定义proxysql的配置文件
$ vim /etc/proxysql.cnf
datadir="/var/lib/proxysql"

# 登陆proxysql管理接口，进行管理时使用的配置
admin_variables=
{
		# 用户名和密码
        admin_credentials="admin:admin"
        # 监听的端口或者本地连接sock
        mysql_ifaces="127.0.0.1:6032;/tmp/proxysql_admin.sock"
#       refresh_interval=2000
#       debug=true
}


mysql_variables=
{
		# 并发线程，单线程响应多个请求。建议为CPU核心数	
        threads=4
        # 最大连接数
        max_connections=2048
        # 默认查询延迟时间
        default_query_delay=0
        # 默认查询超时时间
        default_query_timeout=36000000
        # 是否压缩
        have_compress=true
        # 轮询时超时时间
        poll_timeout=2000
        # MySQL监听端口
        interfaces="0.0.0.0:3306;/tmp/proxysql.sock"
        # 用户连接后默认使用的数据库
        default_schema="my_db"
        # 栈大小
        stacksize=1048576
        # 服务器版本
        server_version="5.5.30"
        # 连接超时时间
        connect_timeout_server=3000
        monitor_history=600000
        monitor_connect_interval=60000
        monitor_ping_interval=10000
        monitor_read_only_interval=1500
        monitor_read_only_timeout=500
        ping_interval_server=120000
        ping_timeout_server=500
        commands_stats=true
        sessions_sort=true
        connect_retries_on_failure=10
}


# defines all the MySQL servers
# MySQL服务器组
mysql_servers =
(
       {
       		   # 数据库服务器IP地址
       		   # 主节点
               address = "172.16.1.100" # no default, required . If port is 0 , address is interpred as a Unix Socket Domain
               port = 3306           # no default, required . If port is 0 , address is interpred as a Unix Socket Domain
               # 主机组
               hostgroup = 0           # no default, required
               # 在线还是离线
               status = "ONLINE"     # default: ONLINE
               # 权重
               weight = 1            # default: 1
               # 是否压缩
               compression = 0       # default: 0
               # 最大并发连接数
               max_connections=200
   # 如果是读服务器，是否启用延迟。尽量不要开启
   # max_replication_lag = 10  # default 0 . If greater than 0 and replication lag passes such threshold, the server is shunned
       }
       {
       			# 从节点1
                address = "172.16.1.70" # no default, required . If port is 0 , address is interpred as a Unix Socket Domain
                port = 3306           # no default, required . If port is 0 , address is interpred as a Unix Socket Domain
                # 从节点主机组为 1
                hostgroup = 1           # no default, required
                status = "ONLINE"     # default: ONLINE
                weight = 1            # default: 1
                compression = 0       # default: 0
                max_connections=500
        },
        {
        		# 从节点2
                address = "172.16.1.21" # no default, required . If port is 0 , address is interpred as a Unix Socket Domain
                port = 3306           # no default, required . If port is 0 , address is interpred as a Unix Socket Domain
                # 从节点主机组为 1
                hostgroup = 1           # no default, required
                status = "ONLINE"     # default: ONLINE
                weight = 1            # default: 1
                compression = 0       # default: 0
                max_connections=500
        }
        # 注意最后一个括号，这个后面没有逗号


# 登录后端MySQL主机的账号和密码
mysql_users:
(
       {
               # 用户名
               username = "myadmin" # no default , required
               # 密码
               password = "root@123" # default: ''
               # 默认连接到哪个组中，默认连接到主服务组
               default_hostgroup = 0 # default: 0
               # 是否激活
               active = 1            # default: 1
               # 连接后默认使用的数据库
               default_schema="my_db"
       }
#       {
#               username = "root"
#               password = ""
#               default_hostgroup = 0
#               max_connections=1000
#               default_schema="test"
#               active = 1
#       },
#       { username = "user1" , password = "password" , default_hostgroup = 0 , active = 0 }
)



#defines MySQL Query Rules
# 语句路由，将指定的SQL语句，路由到指定的服务器上
mysql_query_rules:
(
#       {
#               rule_id=1
#               active=1
#               match_pattern="^SELECT .* FOR UPDATE$"
#               destination_hostgroup=0
#               apply=1
#       },
#       {
#               rule_id=2
#               active=1
#               match_pattern="^SELECT"
#               destination_hostgroup=1
#               apply=1
#       }
)


# MySQL复制集群的定义：指定读组、写组
# 这里组号是之前在mysql_servers段中设置的hostgroup的ID
mysql_replication_hostgroups=
(
        {
        		# 写组
                writer_hostgroup=30
                # 读组
                reader_hostgroup=40
                # 注释信息
                comment="test repl 1"
        }
#       {
#                writer_hostgroup=50
#                reader_hostgroup=60
#                comment="test repl 2"
#        }
)
```

#### <font size=4 color="#FF7F00">启动ProxySQL并连接数据库</font>


```bash
$ systemctl start proxysql 
# 这里的用户和密码是MySQL的密码，而非proxySQL的管理账号密码
$ mysql -h 172.16.1.40 -umyadmin -proot@123
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.5.30 (ProxySQL)

Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| hellodb            |
| my_db              |
| mydb               |
| mysql              |
| performance_schema |
| test               |
+--------------------+
7 rows in set (0.00 sec)
```

#### <font size=4 color="#FF7F00">通过ProxySQL连接的数据库进行创建表，进行测试(默认连接的是主服务器，具有读写功能)</font>


```bash
> use my_db;
> CREATE TABLE tb1 (id int(10));
> SHOW TABLES;
+-----------------+
| Tables_in_my_db |
+-----------------+
| tb1             |
+-----------------+
1 row in set (0.00 sec)

在主服务器和两台从节点查看是否创建了tb1这张表，如果有，则成功
```

#### <font size=4 color="#FF7F00">ProxySQL节点查看主从节点信息</font>

```bash
$ mysql -uadmin -padmin -h127.0.0.1 -P6032
> SELECT hostgroup_id,hostname,port,status FROM mysql_servers;
+--------------+--------------+------+--------+
| hostgroup_id | hostname     | port | status |
+--------------+--------------+------+--------+
| 0            | 172.16.1.100 | 3306 | ONLINE |
| 1            | 172.16.1.70  | 3306 | ONLINE |
| 1            | 172.16.1.21  | 3306 | ONLINE |
+--------------+--------------+------+--------+
3 rows in set (0.00 sec)

# 查看backend MySQL
> SELECT * FROM mysql_servers;
+--------------+--------------+------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| hostgroup_id | hostname     | port | status | weight | compression | max_connections | max_replication_lag | use_ssl | max_latency_ms | comment |
+--------------+--------------+------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
| 0            | 172.16.1.100 | 3306 | ONLINE | 1      | 0           | 200             | 0                   | 0       | 0              |         |
| 1            | 172.16.1.70  | 3306 | ONLINE | 1      | 0           | 500             | 0                   | 0       | 0              |         |
| 1            | 172.16.1.21  | 3306 | ONLINE | 1      | 0           | 500             | 0                   | 0       | 0              |         |
+--------------+--------------+------+--------+--------+-------------+-----------------+---------------------+---------+----------------+---------+
3 rows in set (0.00 sec)

# 查看组信息
> SELECT * FROM runtime_mysql_replication_hostgroups;
+------------------+------------------+-----------+
| writer_hostgroup | reader_hostgroup | comment   |
+------------------+------------------+-----------+
| 0                | 1                | my repl 1 |
+------------------+------------------+-----------+
1 row in set (0.00 sec)
```



-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=468517666&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



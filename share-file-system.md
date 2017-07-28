---
title: NFS、Samba从入门到进阶
date: 2017-06-06 21:18:32
tags: [linux,samba,nfs,filesystem,share]
categories: linux进阶
copyright: true
---

![](https://ws2.sinaimg.cn/large/006tNbRwly1fgbt54fxxuj30xc0go49h.jpg)

<blockquote class="blockquote-center">在本章我们将介绍nfs与samba的进阶实验与配置
nfs: Network File System,是由著名的 Sun 公司在1984年发布，其功能旨在允许客户端主机可以像访问本地存储一样通过访问服务器端文件。
samba：samba是种用来让UNIX系列的操作系统与微软Windows操作系统的SMB/CIFS（Server Message Block/Common Internet File System）
</blockquote>

<font size=4 color="#97694F"> NFS： </font> 

* 监听的端口：`2049/tcp`
* 辅助类的服务：`rpc(远程过程调用)`,`portmapper`
* 必备工具包：`nfs-utils`
* 配置文件：`/etc/exports`
* 其他命令程序：`showmount`,`exportfs`


-------

<font size=4 color="#97694F"> Samba： </font> 

* 监听的端口：`137/udp`,`138/udp` ; `139/tcp`,`445/tcp`
* 服务端程序包：`samba`,`samba-common`,`samba-libs`
* 主程序：`nmbd`,`smbd`
* Unit File：`smb.service`,`nmb.service `
* 主配置文件：`/etc/samba/smb.conf`

-------


<!-- more -->




<font size=5 color="#FF6EC7" > 实验环境： </font>

```
虚拟机操作系统（OS）：CentOS Linux release 7.2.1511 (Core)
内核版本（Kernel）：3.10.0-327.el7.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

**客户端环境：**
![](https://ws4.sinaimg.cn/large/006tNc79ly1fg5rfg0cjsj30ga0a8dj6.jpg)

-------


### NFS进阶实验：

<font size=4 color="#38B0DE" > **此次实验的目标如下：** </font>


**第一题：**

```
(1) nfs server导出/data/mywp，在目录中提供wordpress; 
(2) nfs client挂载nfs server导出的文件系统至/nfs/wordpress；
(3) 客户端（lamp）部署wordpress，并让其正常访问；要确保能正常发文章，上传图片；
(4) 客户端2(lamp)，挂载nfs server导出的文件系统至/nfs/wordpress；验正其wordpress是否可被访问； 要确保能正常发文章，上传图片；
```

**第二题：**

```
(1) nfs server导出/data/目录；
(2) nfs client挂载/data/至本地的/mydata目录；本地的mysqld或mariadb服务的数据目录设置为/mydata, 要求服务能正常启动，且可正常 存储数据；
```


-------

{% note primary %}### NFS实验步骤
{% endnote %}

LAMP Server 1：172.16.1.70   www.mywp1.com
LAMP Server 2：172.16.1.20   www.mywp2.com

NFS Server：172.16.1.100


<font size=5 color="#70DBDB" >第一题步骤：</font>



#### 1、安装配置第一台LAMP服务器

**安装httpd并配置虚拟主机**
（注意这里为了方便，不再测试httpd服务，直接配置）


```
$ yum install httpd php php-mysql php-mbstring
$ vim /etc/httpd/conf.d/lamp.conf
<VirtualHost *:80>
        ServerName 172.16.1.70
        DocumentRoot "/nfs/wordpress/"
        <Directory "/nfs/wordpress/">
                Options None
                AllowOverride None
                Require all granted
        </Directory>
        CustomLog "/nfs/wordpress/log/access_log" combined
        ErrorLog "/nfs/wordpress/log/error_log"
</VirtualHost>

$ mkdir -pv /nfs/wordpress/log
```

#### 2、配置NFS Server

**安装nfs、nfs-utils、php、php-mysql、php-mbstring**

```
$ yum install nfs nfs-utils php php-mysql php-mbstring
```

**安装MariaDB以及修改配置文件**

```
$ yum install mariadb-server
$ vim /etc/my.cnf.d/server.conf
[mysqld]
skip_name_resolve=ON            #开启跳过名称解析功能
innodb_file_per_table=ON        #将共享表空间改为独立表空间
log_bin=mysql-bin               #开启二进制日志
```

**启动数据库**

```
$ systemctl start mariadb.service
```

**编辑nfs配置文件**

```
$ vim /etc/exports 
/data/mywp	172.16.1.70(rw,no_root_squash) 172.16.1.20(rw,no_root_squash)

创建共享目录：
$ mkdir -pv /data/mywp
```

**启动NFS服务**

```
$ systemctl start nfs.service
```

#### 3、在LAMP1 上挂载NFS共享的目录

**查看并挂载**

```
$ showmount -e 172.16.1.100
Export list for 172.16.1.100:
/data/mywp   172.16.1.20,172.16.1.70

$ mount -t nfs 172.16.1.100:/data/mywp /nfs/wordpress
```

**测试挂载点读写权限**

```
$ cd /nfs/wordpress
$ mkdir testdir
$ touch 1.txt 
$ rm 1.txt
$ rm -f testdir 
```

#### 4、在NFS服务器上的共享目录解压wordpress并配置，为其创建数据库，以及远程连接的权限

**解压WordPress并修改其配置文件**

```
$ scp wordpress-4.7.4-zh_CN.tar.gz root@172.16.1.100:/data/mywp         #这步操作在个人客户端操作

$ cd /root 
$ tar xf wordpress-4.7.4-zh_CN.tar.gz
$ mv wordpress /data/mywp/
$ cd /data/mywp/wordpress
$ mv config.sample.inc.php config.inc.php
$ vim config.inc.php
修改如下：

// ** MySQL 设置 - 具体信息来自您正在使用的主机 ** //
/** WordPress数据库的名称 */
define('DB_NAME', 'wordpress');

/** MySQL数据库用户名 */
define('DB_USER', 'wordpress');

/** MySQL数据库密码 */
define('DB_PASSWORD', 'root@123');

/** MySQL主机 */
define('DB_HOST', '172.16.1.100');

/** 创建数据表时默认的文字编码 */
define('DB_CHARSET', 'utf8');

/** 数据库整理类型。如不确定请勿更改 */
define('DB_COLLATE', '');
```

**创建WordPress数据库，并授权远程连接的权限**

```
$ mysql 
mysql> CREATE DATEBASE wordpress;
mysql> GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'172.16.1.100' IDENTIFIED BY 'root@123';
mysql> GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'172.16.1.70' IDENTIFIED BY 'root@123';
mysql> GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'172.16.1.20' IDENTIFIED BY 'root@123';
mysql> FLUSH PRIVILEGES;
```

**重启数据库服务**

```
$ systemctl restart mariadb.service 
```

**修改/data/mywp目录权限**

```
$ chmod a+w /data/mywp/wordpress/wp-contet
$ chown -R apache.apache /data/mywp/wordpress
```

#### 5、在LAMP1上执行如下操作

**重启httpd服务**

```
$ systemctl restart httpd
```

#### 6、创建另一台LAMP2：


```
$ yum install httpd php php-mysql php-mbstring
$ vim /etc/httpd/conf.d/lamp.conf
	<VirtualHost *:80>
	        ServerName 172.16.1.20
	        DocumentRoot "/nfs/wordpress/"
	        <Directory "/nfs/wordpress/">
	                Options None
	                AllowOverride None
	                Require all granted
	        </Directory>
	        CustomLog "/nfs/wordpress/log/access_log" combined
	        ErrorLog "/nfs/wordpress/log/error_log"
	</VirtualHost>

$ mkdir -pv /nfs/wordpress/log

$ mount -t nfs 172.16.1.100:/data/mywp /nfs/wordpress

$ systemctl start httpd
```

#### 7、在客户端(Mac)打开浏览器验证

**添加解析：**

```
$ sudo vim /etc/hosts
Password:
172.16.1.70 www.mywp1.com
172.16.1.70 www.mywp2.com
```

**浏览器验证：**

www.mywp1.com
![](https://ws3.sinaimg.cn/large/006tNc79ly1fgbubw51l0g30qo0v61l9.gif)


www.mywp2.com
![](https://ws4.sinaimg.cn/large/006tNc79ly1fgbue5lbvpg30qo0v67wt.gif)



-------


<font size=5 color="#70DBDB" >第二题步骤：</font>

#### 1、NFS Server步骤如下

```
$ ! rpm -q nfs-utils >/dev/null  && yum install -y nfs-utils  #安装nfs 

$ systemctl  start nfs.service

$ mkdir /data/mydata                                          #创建共享目录

$ vim /etc/exports
/data/mydata    172.16.1.70(rw,anonuid=27,anongid=27,async)

$ exportfs  -avr

$ setfacl -m o:rwx  /data/mydata
```

#### 2、NFS Client步骤如下：

这里我们就使用之前的LAMP1作为我们的NFS Client


```
1、 安装nfs工具包
$ yum install -y  nfs-utils

2、 安装数据库服务端
$ yum install -y mariadb-server

3、 创建挂载点
$ mkdir /mydata

4、 挂载nfs文件系统
$ mount  -t nfs  172.18.9.119:/data   /mydata

5、 编辑mariadb配置文件：
$ vim  /etc/my.cnf
datadir=/mydata

6、 启动数据库服务
$ systemctl start mariadb.service 
```


-------

### Samba进阶实验

<font size=4 color="#38B0DE" > **此次实验的目标如下：** </font>


**第一题：**

```
(1) samba server导出/data/application/web，在目录中提供wordpress; 
(2) samba  client挂载nfs server导出的文件系统至/var/www/html；
(3) 客户端（lamp）部署wordpress，并让其正常访问；要确保能正常发文章，上传图片；
(4) 客户端2(lamp)，挂载samba  server导出的文件系统至/var/www/html；验正其wordpress是否可被访问； 要确保能正常发文章，上传图片；
```

**第二题：**

```
(1) samba  server导出/data/目录；
(2) samba  client挂载/data/至本地的/mydata目录；本地的mysqld或mariadb服务的数据目录设置为/mydata, 要求服务能正常启动，且可正常 存储数据；
```

-------

{% note info %}### Samba实验步骤
{% endnote %}

<font size=5 color="#70DBDB" >第一题步骤：</font>


#### 1、在samba服务器上创建共享目录，安装samba并添加共享目录配置


```
$ mkdir -pv /samba/mywp 
$ yum install samba 
$ vim /etc/samba/smb.conf 
在文件尾部添加如下信息：
[wordpress]
comment = My samba share WordPress          #配置说明
path = /samba/mywp                          #共享目录位置
writable = yes                              #是否可写 
write list = apache 			    #拥有写权限的用户列表
guest ok = no 				    #来宾账号是否可读
```

#### 2、检查配置文件语法

```
$ testparm
Load smb config files from /etc/samba/smb.conf
rlimit_max: increasing rlimit_max (1024) to minimum Windows limit (16384)
Processing section "[homes]"
Processing section "[printers]"


Processing section "[wordpress]"
Loaded services file OK.
Server role: ROLE_STANDALONE

Press enter to see a dump of your service definitions
...
...
...
[wordpress]
	comment = My samba share WordPress
	path = /samba/mywp
	write list = apache
	read only = No 
```

#### 3、拷贝wordpress文件到共享目录，并设置apache用户对其拥有rwx权限

```
$ tar xf wordpress-4.7.4-zh_CN.tar.gz 
$ mv wordpress /samba/mywp/
$ cp /samba/mywp/wp-config-sample.php  /samba/mywp/wp-config.php
$ vim /samba/mywp/wp-config.php
// ** MySQL 设置 - 具体信息来自您正在使用的主机 ** //
/** WordPress数据库的名称 */
define('DB_NAME', 'smb_wordpress');

/** MySQL数据库用户名 */
define('DB_USER', 'smb_wordpress');

/** MySQL数据库密码 */
define('DB_PASSWORD', 'root@123');

/** MySQL主机 */
define('DB_HOST', '172.16.1.100');

/** 创建数据表时默认的文字编码 */
define('DB_CHARSET', 'utf8');

/** 数据库整理类型。如不确定请勿更改 */
define('DB_COLLATE', '');

$ chown -R apache.apache /samba/mywp/wordpress
$ chmod 777 /samba/mywp/wordpress/wp-content
```

#### 4、添加apache用户到smb，并重载smb.service


```
$ smbpasswd -a apache 
$ systemctl reload smb.service
```

#### 5、在LAMP服务器上挂载samba共享目录以及配置httpd虚拟主机：


```
$ mkdir /samba/wordpress/ -pv
$ mount.cifs //172.16.1.100/wordpress /samba/wordpress/ -o username=apache
$ mount
$ cd /samba/wordpress/
$ ll 
$ cp /etc/httpd/conf.d/lamp.conf /etc/httpd/conf.d/wp2.conf
$ vim /etc/httpd/conf.d/wp2.conf
<VirtualHost 172.16.1.70:80>
        ServerName www.mywp2.com
        DocumentRoot "/samba/wordpress/"
        <Directory "/samba/wordpress/">
                Options None
                AllowOverride None
                Require all granted
        </Directory>
</VirtualHost>

$ vim /etc/httpd/conf.d/lamp.conf           #修改之前配置nfs的虚拟主机配置
<VirtualHost 172.16.1.70:80>
        ServerName www.mywp1.com
        DocumentRoot "/nfs/wordpress/"
        <Directory "/nfs/wordpress/">
                Options None
                AllowOverride None
                Require all granted
        </Directory>
        CustomLog "/nfs/wordpress/log/access_log" combined
        ErrorLog "/nfs/wordpress/log/error_log"
</VirtualHost>

$ systemctl restart httpd                   #重启httpd服务
```

#### 6、在客户端上的操作：

```
$ vim /etc/hosts
172.16.1.70 www.mywp1.com
172.16.1.70 www.mywp2.com
```

打开浏览器访问，并创建wordpress站点，创建文章，测试上传图片的功能




-------

<font size=5 color="#70DBDB" >第二题步骤：</font>

#### 1、在Samba服务器上创建共享目录，修改配置文件，添加mysql用户对共享目录的rwx权限，把mysql添加到smb中，重载smb服务


```
$ mkdir /samba/mysql 
$ chown mysql.mysql /samba/mysql/
$ vim /etc/samba/smb.conf
[mysqldata]
comment = My samba share MySQL Data
path = /samba/mysql
writable = yes
write list = mysql
guest ok = no

$ smbpasswd -a mysql

$ systemctl reload smb.service
```

#### 2、在LAMP2上的操作

```
$ mkdir /samba/mydata -pv
$ mount.cifs //172.16.1.100/mysqldata /samba/mydata/ -o username=mysql 
$ mount
$ vim /etc/my.cnf.d/server.conf
[mysqld]
skip_name_resolve=ON
innodb_file_per_table=ON
log_bin=mysql-bin

$ vim /etc/my.cnf
[mysqld]
datadir=/samba/mydata

$ systemctl start mariadb.service

登入数据库创建数据库，表，进行读写测试：
$ mysql 
MariaDB [(none)]> CREATE DATABASE test_db;
MariaDB [(none)]> user test_db;
MariaDB [(none)]> CREATE TABLE test_tb (id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,name VARCHAR(30),gender ENUM('M','F'));
MariaDB [(none)]> DESC test_db.test_tb;
+--------+------------------+------+-----+---------+----------------+
| Field  | Type             | Null | Key | Default | Extra          |
+--------+------------------+------+-----+---------+----------------+
| id     | int(10) unsigned | NO   | PRI | NULL    | auto_increment |
| name   | varchar(30)      | YES  |     | NULL    |                |
| gender | enum('M','F')    | YES  |     | NULL    |                |
+--------+------------------+------+-----+---------+----------------+
3 rows in set (0.00 sec)
```


-------

### 实验步骤视频：

#### NFS+MariaDB(使用NFS存储数据库数据)

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=11101728&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>

#### NFS+LAMP+WordPress

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=11106147&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>

#### Samba+LAMP+WordPress/Samba+MariaDB

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=11107261&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>


-------


上述实验文档：[dropbox共享](https://www.dropbox.com/s/dhl5zfnfd0s6rxl/6.5%E8%AF%BE%E5%90%8E%E5%8D%9A%E5%AE%A2%E4%BD%9C%E4%B8%9A.txt?dl=0)

需科学上网

-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=400 height=86 src="//music.163.com/outchain/player?type=2&id=417250673&auto=0&height=66"></iframe>

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)





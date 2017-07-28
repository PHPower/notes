---
title: CentOS7配置LAMP (fastcgi版本)
date: 2017-06-03 22:29:58
tags: [linux,php-fpm,lamp,mysql,php,httpd]
categories: linux进阶
copyright: true
---

<blockquote class="blockquote-center">在大多数的情况下，我们搭建的LAMP都是基于：
Liunx、Apache、MySQL、PHP
其中PHP使用的CGI，这样对系统负载压力会比使用fastCGI更大一些；
为了极致的性能，我们这次的实验是基于php-fpm，也就是fastCGI。
</blockquote>

`LAMP`所有服务的配置文件：


<font size=5 color="#FF0000" > Apache：</font> 也就是我们之前安装过的httpd服务

```
主配置文件：/etc/httpd/conf/httpd.conf
其他配置文件目录：/etc/httpd/conf.d/*.conf
默认的网站主页目录：/var/www/html
```

<font size=5 color="#FF0000" >MySQL：</font>这次我们使用的是MySQL衍生的开源版本，`MariaDB`。因为MySQL被Oracle收购了，因此我们不建议再使用MySQL。

```
主配置文件：/etc/my.cnf
其他配置文件：/etc/my.cnf.d/*.cnf
```

<font size=5 color="#FF0000"> PHP：</font> `php-fpm`，fastCGI版本。

```
主配置文件：/etc/php-fpm.conf
其他配置文件：/etc/php-fpm.d/*.conf
```

![](https://ws3.sinaimg.cn/large/006tKfTcly1fg8ejxbzrkj30xc0go1kx.jpg)

<!-- more -->



<font size=6 color="#EE7700" > **此次搭建LAMP的目标如下：** </font>


在三台服务器上分别配置 <font size=5 color="#00BBFF" > httpd，php-fpm，mariadb </font>



-------

<font size=6 color="#855E42" > 实验环境： </font>

```
三台服务器都是CentOS7：
操作系统（OS）：CentOS Linux release 7.2.1511 (Core)
内核版本（Kernel）：3.10.0-327.el7.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

客户端环境：
![](https://ws4.sinaimg.cn/large/006tNc79ly1fg5rfg0cjsj30ga0a8dj6.jpg)

-------

{% note primary %}### 安装配置MariaDB   (IP:172.16.1.110)
{% endnote %}

#### 1、安装MariaDB以及修改数据库配置文件：

**安装MariaDB**

```
$ yum install mariadb-server
```

**修改配置文件**

```
$ vim /etc/my.cnf.d/server.conf 
在[server]一项的下面添加如下信息：
skip_name_resolve=ON            --跳过名字解析
innodb_file_per_table=ON        --将共享表空间改为独立表空间
```

#### 2、启动服务


```
$ systemctl start mariadb.service
```

#### 3、创建测试数据库


```
$ mysql
mysql> CREATE DATABASE mydb;
```

#### 4、重启MariaDB

```
$ systemctl restart mariadb.service
```


-------

{% note success %}### 安装配置php-fpm   (IP:172.16.1.130)
{% endnote %}

#### 1、安装php-fpm以及php-mysql

```
$ yum install php-fpm php-mysql
```

#### 2、修改php-fpm的配置文件

```
$ vim /etc/php-fpm.d/www.conf 
#这里的监听地址改为本机的对外IP地址
listen = 172.16.1.130:9000

#这里允许请求的客户端地址为我们的HTTPD服务器IP地址：
listen.allowed_clients = 172.16.1.120

#取消这项的注释；状态信息查看
pm.status_path = /status

#取消这项的注释；网络状态信息查看
ping.path = /ping
ping.response = pong

#这里的地址为默认；一般会没有这个目录，需要我们编辑完配置文件然后创建
chdir = /var/www

#这里的目录需要我们创建，并修改目录的属主属组
php_value[session.save_path] = /var/lib/php/session
```

#### 3、创建之前配置文件内缺少的目录，并更改其属主属组

```
$ mkdir -pv /var/lib/php/session 
$ chown -R apache.apache /var/lib/php/session 

$ mkdir -pv /var/www/html           #这里的地址其实是我们在httpd一会配置的反向代理的地址
$ chown -R apache.apache /var/www/
```

#### 4、启动php-fpm

```
$ systemctl start php-fpm
```


-------

{% note info %}### 安装配置httpd   (IP:172.16.1.120)
{% endnote %}

#### 1、安装httpd，并编辑其配置文件


```
$ yum install httpd 

编辑httpd的配置文件，并创建虚拟主机配置文件：
$ vim /etc/httpd/conf/httpd.conf
#取消这里的注释，并修改为我们httpd的IP地址：
ServerName 172.16.1.120:80
```

#### 2、编辑虚拟主机配置文件

```
$ vim /etc/httpd/conf.d/virual.conf
DirectoryIndex index.php

<VirtualHost *:80>
    ServerName 172.16.1.120
    DocumentRoot "/var/www/html/"  
    ProxyRequests Off
    ProxyPassMatch ^/(.*\.php)$ fcgi://172.16.1.130:9000/var/www/html/$1 timeout=1800           #这里的IP地址是我们的php-fpm主机地址，路径也必须在php主机上存在，如果不存在则无法查找到资源
    ProxyPassMatch ^/(ping|status).*$ fcgi://172.16.1.130:9000/                                 #反向代理php自带的ping(网络测试）以及status(php-fpm状态页)
    <Directory "/var/www/html/">   
        Options None
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
```

#### 3、在php-fpm主机上创建php测试页面

```
$ vim /var/www/html/index.php 
php-fpm
<?php 
	phpinfo();
?>

$ systemctl restart php-fpm 
```

#### 4、回到httpd服务器上，重启服务。并打开浏览器测试

```
$ systemctl restart httpd
```

**在MacBookPro上的操作：**

![](https://ws1.sinaimg.cn/large/006tKfTcly1fg8xxyclrbg30qo0v6b2g.gif)


验证成功，可以解析php页面了。

下面我们开始配置`phpMyAdmin`



-------

{% note warning %}### 配置 phpMyAdmin
{% endnote %}

部署前的准备工作：

下载phpMyAdmin:
    如果php-fpm版本是高于5.5的，则下载phpMyAdmin-4.7.1-all-languages.zip
    如果php-fpm版本是低于5.5的，则下载phpMyAdmin-4.0.10.20-all-languages.zip
    
** [下载地址在这里](https://www.phpmyadmin.net/downloads/)**

#### 1、注意如下的操作在 php-fpm主机 与 httpd主机 上都需要操作

为了方便，以下所有关于php-fpm的配置都以php说明

```
$ unzip phpMyAdmin-4.0.10.20-all-languages.zip 
$ mv phpMyAdmin-4.0.10.20-all-languages pma
$ mv pma /var/www/html/
$ cd /var/www/html 
$ chown -R apache.apache pma
```

**<font size=4 color="#7093DB">仅在php主机上的操作：</font>**

```
$ yum install php-mbstring 
$ yum install php-mcrypt
```

**<font size=4 color="#5F9F9F">两台主机：</font>**


```
$ vim  /var/www/html/pma/config.inc.php                 #编辑第一个配置文件：修改mysql的地址
$cfg['Servers'][$i]['host'] = '172.16.1.110';

$ vim /var/www/html/pma/libraries/config.defalut.php    #编辑phpMyAdmin的配置文件；修改mysql数据库的地址；默认为localhost
#修改localhost为我们的mysql数据库地址:172.16.1.110
$cfg['Servers'][$i]['host'] = '172.16.1.110';

#编辑phpmyadmin默认的配置文件
$ cp /var/www/html/pma/config.sample.inc.php /var/www/html/pma/config.inc.php 
$ vim /var/www/html/pma/config.inc.php 

#在''中填入一段随机字符串即可
$cfg['blowfish_secret'] = 'adawdad32k2rjf2f2hh8b7c6d'; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */
```

配置完成之后保存退出文件

#### 2、在MariaDB上对远程连接数据库的用户授权


```
> GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.1.110' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.1.120' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.1.130' IDENTIFIED BY 'root@123';
> FLUSH PRIVILEGES;
```

*注意：上述授权极为不安全，不建议在生产环境中执行*

#### 3、授权完毕之后依次重启服务

<font size=4 color="#D98719">MariaDB：</font>

```
$ systemctl restart mariadb.service
```

<font size=4 color="#7093DB">php-fpm：</font>

```
$ systemctl restart php-fpm
```

<font size=4 color="#23238E">httpd：</font>

```
$ systemctl restart httpd
```


#### 4、打开FireFox浏览器输入地址，进行测试

**注意：由于phpMyAdmin有基于cookie的认证缓存机制，我们之前测试的时候，可能留下了缓存；所以在做之前，建议清理缓存。**

![](https://ws1.sinaimg.cn/large/006tKfTcly1fg8yi368nsg30qo0v6npp.gif)

-------


{% note danger %}### 上述实验的实操过程视频
{% endnote %}

Bilibili视频源：

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=11051187&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>


-------

上述实验文档：[dropbox共享](https://www.dropbox.com/s/3zrvymi6dovpmmm/6.2%E8%AF%BE%E5%90%8E%E4%BD%9C%E4%B8%9A%E4%B8%89%E5%8F%B0%E6%9C%8D%E5%8A%A1%E5%99%A8%E6%90%AD%E5%BB%BALAMP%28php-fpm%2Chttpd%2Cmariadb%29.txt?dl=0)

-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=5039560&auto=1&height=66"></iframe>



![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



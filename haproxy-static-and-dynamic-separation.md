---
title: HAProxy+Varnish动静分离部署WordPress
date: 2017-07-03 10:53:15
tags: [HAProxy,linux,httpd,varnish,wordpress]
categories: [linux进阶,HAProxy,Varnish]
copyright: true
---

<blockquote class="blockquote-center">这章节，我们继续介绍HAProxy
不过这次我们将介绍如何使用HAProxy+Varnish实现WordPress的动静分离
</blockquote>

![](https://ws4.sinaimg.cn/large/006tKfTcly1fh6icrq0f1j30ra0zn77t.jpg)

**由于实验的宿主机内存有限，这里我们就不按照拓扑图上的双varnish和图片服务器**



-------

<!-- more -->

### <font szie=4 color="#5F9F9F">实验目标</font>



```
(1) 动静分离部署wordpress，动静都要能实现负载均衡，要注意会话的问题
(2) 在haproxy和后端主机之间添加varnish进行缓存
(3) haproxy的设定要求：
	(a) stats page，要求仅能通过本地访问使用管理接口；
	(b) 动静分离
	(c) 分别考虑不同的服务器组的调度算法
(4) haproxy高可用(Keepalived)
```

{% note primary %}### HAProxy对后端动静服务实现负载均衡调度
{% endnote %}

*注意：如果没有特别说明，以下操作都是需要在另一台对应的静态/动态服务器操作*

#### <font size=4 color="#38B0DE">配置安装 静态与动态服务器 </font>

* 静态WEB

```
$ yum install httpd
$ echo "First Static Server PAGE" > /var/www/html/index.html
$ echo "Second Static Server PAGE" > /var/www/html/index.html
$ systemctl start httpd
```

* 动态AP站点

```
$ yum install httpd php php-mysql php-mbstring php-mcrypt
$ vim /var/www/html/index.php 
Dynamic Server 1         # 另一台：Dynamic Server 2
<?php 
	phpinfo();
?>
$ systemctl start httpd
```

<br>

#### <font size=4 color="#38B0DE">配置安装 HAProxy </font>


```
$ yum install -y haproxy 
$ cd /etc/haproxy/
$ vim haproxy.cfg
#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend websrvs
    bind            *:80
    rspadd          X-Via:\ HAProxy-1
    rspidel         Server.*
    acl static      path_end -i .html .css .js
    acl static      path_beg -i /images /static
    use_backend     websrvs if static
    default_backend appsrvs
    acl badgay      hdr_sub(User-Agent) -i curl
    block           if badgay

#---------------------------------------------------------------------
# Admin Stats
#---------------------------------------------------------------------
listen status
    bind *:9909
    acl auth_admin  src 172.16.250.15 172.16.1.11
    stats           enable
    stats uri       /myha?stats
    stats realm     HAProxy\ Admin\ Area
    stats auth      root:root@123
    stats admin     if auth_admin

#---------------------------------------------------------------------
# WEB static backend
#---------------------------------------------------------------------
backend websrvs
    option      httpchk /index.html
    option      forwardfor header X-Client
    balance     roundrobin
    server      web1    192.168.1.50:80 check weight 2
    server      web2    192.168.1.60:80 check weight 1
    hash-type   consistent
    #option      httpchk /index.html

#---------------------------------------------------------------------
# ap backend
#---------------------------------------------------------------------

backend appsrvs
    option      httpchk /index.php
    option      forwardfor header X-Client
    balance     roundrobin
    server      app1    192.168.1.70:80 check weight 1
    server      app2    192.168.1.80:80 check weight 1
    hash-type   consistent

$ systemctl restart haproxy 
```


**到这步，已经实现了通过HAProxy负载均衡调度后端动态和静态资源**



-------


{% note success %}### HAProxy+Varnish对后端WordPress实现负载均衡调度以及缓存加速功能
{% endnote %}



#### <font size=4 color="#32CD99">配置NFS以及MySQL</font>

* 配置MySQL

```
$ vim /etc/my.cnf.d/server.conf 
[mysqld]
skip_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin

$ systemctl start mariadb.service 
$ mysql
> CREATE DATABASE wordpress_db;
> CREATE DATABASE discuzx;
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'192.168.1.50' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'192.168.1.60' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'192.168.1.70' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'192.168.1.80' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'192.168.1.90' IDENTIFIED BY 'root@123';

> GRANT ALL PRIVILEGES ON discuzx.* TO 'discuzx'@'192.168.1.50' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON discuzx.* TO 'discuzx'@'192.168.1.60' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON discuzx.* TO 'discuzx'@'192.168.1.70' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON discuzx.* TO 'discuzx'@'192.168.1.80' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON discuzx.* TO 'discuzx'@'192.168.1.90' IDENTIFIED BY 'root@123';

> FLUSH PRIVILEGES;
```

<br>

* 配置NFS

```
$ vim /etc/exports
/data/my_wordpress      192.168.1.50(rw,no_root_squash) 192.168.1.60(rw,no_root_squash) 192.168.1.70(rw,no_root_squash) 192.168.1.80(rw,no_root_squash)
/data/my_discuzx        192.168.1.50(rw,no_root_squash) 192.168.1.60(rw,no_root_squash) 192.168.1.70(rw,no_root_squash) 192.168.1.80(rw,no_root_squash)
$ mkdir -pv /data/my_wordpress
$ mkdir -pv /data/my_discuzx
$ tar -xf wordpress-4.7.4-zh_CN.tar.gz -C /data/
$ mv /data/wordpress/* /data/my_wordpress

$ unzip Discuz_X3.3_SC_UTF8.zip -C /data/
$ mv /data/upload/* /data/my_discuzx

$ useradd -u 48 -r apache 
$ chown -R apache.apache /data/

$ systemctl start nfs.service 
```

<br>

#### <font size=4 color="#32CD99">动静的4台服务器同时挂载wordpress以及discuzx</font>


```
$ mkdir -pv /var/www/html/wordpress
$ mkdir -pv /var/www/html/wordpress
$ cd /var/www/html
$ mount -t nfs 192.168.1.90:/data/my_wordpress /wordpress
$ mount -t nfs 192.168.1.90:/data/my_discuzx /discuzx
```

<br>

#### <font size=4 color="#32CD99">测试WordPress</font>

在客户端本机的hosts文件添加：

```
$ sudo vim /etc/hosts
172.16.3.10 www.maxie.com           # 调度器地址
172.16.3.20 www.maxie.com           # 备用调度器
172.16.3.200 www.maxie.com          # VIP地址
```

在浏览器输入： http://www.maxie.com/wordpress 即可



-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=31704059&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)









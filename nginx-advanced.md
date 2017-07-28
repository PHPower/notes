---
title: nginx从入门到进阶【二】
date: 2017-06-17 08:53:34
tags: [linux,nginx,web,http,server]
categories: Nginx
copyright: true
---

{% fullimage /images/LEMP.png, nginx_LEMP, %}


<blockquote class="blockquote-center">在学习了之前的一些关于Nginx相关的基础配置以及功能，下面我们就开始学习如何搭建LEMP以及Load-Balacning
</blockquote>

<font size=4 color="#32CD99">LEMP</font>

`L`：Linux
`E`：Engine X --> Nginx
`M`：MariaDB
`P`：PHP-FPM

在做`LEMP`之前，我们先要学习一下`proxy`模块的使用，方便我们对`fastcgi`的理解


-------


<!-- more -->

<font size=4 color="#FF7F00"> 注意：在做这次的实验之前，确保你的机器能够同时运行5台以上的虚拟机，否则后面的实验可能会做不了</font>


### 实验拓扑图

![](https://ws1.sinaimg.cn/large/006tNc79ly1fgnykattu5j30gx0rqgmd.jpg)

#### 虚拟机配置

```
虚拟机操作系统（OS）：CentOS Linux release 7.2.1511 (Core)
内核版本（Kernel）：3.10.0-327.el7.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

#### 物理机配置

![](https://ws4.sinaimg.cn/large/006tNc79ly1fg5rfg0cjsj30ga0a8dj6.jpg)

-------

{% note primary %}### Nginx Proxy代理详解
{% endnote %}

#### <font szie=4 color="#236B8E">Proxy模块各参数详解 </font>


1、proxy_pass URL;

```
该指令用来设置被代理服务器的地址，可以是主机名、IP地址加端口号等形式
```
<br>

2、proxy_set_header filed value;

```
该指令可以更改Nginx服务器接收到的客户端请求的请求头信息，然后将新的请求头发送给被代理的服务器。

field   要更改的信息所在的头域
value   要更改的值，支持使用文本、变量或者变量的组合
```

3、proxy_hide_header field;

```
该指令用于设置Nginx服务器在发送HTTP响应时，隐藏的一些头域信息

filed   需要隐藏的头域
```

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgo0j8mbuwg30qk0fcu15.gif)

4、proxy_pass_header filed;

```
默认情况下，Nginx服务器在发送响应报文时，报文头中不包含Date、Server等来自被代理服务器的头域信息。
该指令可以设置这些头域信息以被发送

field   需要发送的头域
```

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgo0ms0vcfg30qk0fcu17.gif)


5、proxy_cache_path  path [levels=levels] keys_zone=name:size [max_size=size];

```
该指令用于设置Nginx服务器存储数据缓存的路径以及缓存索引相关的内容（只能定义在http中或者server之外）

path        设置缓存数据存放的根路径，该路径应该是预先存在与磁盘上的
levels      设置在相对于path指定目录的第几级hash目录中缓存数据。levels=1，表示一级hash目录；levels=1:2，表示两级，以此类推
name:size   用来设置存放缓存索引的内存区域的名称和大小
max_size    设置硬盘中缓存数据的大小限制
```

6、proxy_cache zone | off;

```
该指令用于配置一块公用的内存区域的名称，该区域可以存放缓存的索引区域

zone    设置的用于存放缓存索引的内存区域的名称
off     关闭proxy_cache功能
```

7、proxy_cache_key string;

```
该指令用于设置Nginx服务器在内存中为缓存数据建立索引时使用的关键字

string  为设置的关键字，支持变量
可以设置多个变量为关键字：
proxy_cache_key $scheme$proxy_host$uri$is_args$args;
```


8、proxy_cache_valid [code ...] time;

```
该指令可以针对不同的HTTP响应状态设置不同的缓存时间

code    设置HTTP响应的状态代码   any表示缓存所有该指令中未设置的其他响应数据
time    设置缓存时间
```

9、proxy_cache_use_stale error | timeout | invalid_header | updating | http_500 | http_502 | http_503 | http_504 | http_403 | http_404 | off ...;

```
如果Nginx在访问被代理服务器过程中出现被代理的服务器无法访问或者访问错误等现象时，Nginx服务器可以使用历史缓存响应客户端的请求，这些数据不一定和被代理服务器上最新的数据一致，但对于更新频率不高的后端服务器来说，该功能在一定程度上，能够为客户端提供不间断访问。

该指令用来设置一些状态，当后端被代理的服务器处于这些状态时，Nginx服务器启用该功能
```

10、proxy_cache_methods GET | HEAD | POST ...;

```
该指令用来设置仅缓存指定的methods的数据
```

11、proxy_connect_timeout time;

```
该指令配置Nginx服务器与后端被代理服务器尝试建立连接的超时时间

time    设置的超时时间 默认为60s
```

12、proxy_send_timeout time;

```
该指令配置Nginx服务器向后端被代理服务器发出 write请求后，等待响应的超时时间

time    设置的超时时间 默认为60s
```


#### 实例

```
$ vim /etc/nginx/conf.d/maxie.conf
proxy_cache_path		/web/cache/   levels=2:1:1    keys_zone=my_cache:10mmax_size=1g;

server {
	listen             80;
	server_name        www1.maxie.com;
	root               /web/www1;
	index              index.html index.htm;
	add_header         X-Via	$server_addr;
	add_header         X-Accel	$server_name;

	location / {
		access_log        /web/www1/access.log my_log flush=4m buffer=1m;
	}


	location ~* \.(jpg|png|gif|jpeg)$ {
		proxy_pass            http://172.16.1.20:80;
		proxy_redirect        default;
		proxy_set_header      X-Real-IP    $remote_addr;
		proxy_cache           my_cache;
		proxy_cache_key       $request_uri;
		proxy_cache_valid     200 301 302 10m;
		proxy_cache_valid     any 1m;

		proxy_cache_methods   GET HEAD;
		proxy_connect_timeout 10s;

		#proxy_hide_header    ETag;
		#proxy_hide_header    Content-Type;

		#proxy_pass_header    Server;
		#proxy_pass_header    Date;
	}

	error_page             404	    http://www1.maxie.com/404.html;

	location = /404.html {
	}
}
```

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgo1in6knog30qk0fcnpm.gif)


-------

{% note success %}### Nginx fastcgi详解
{% endnote %}


#### <font color="#D19275"> fastcgi各参数详解</font>

1、fastcgi_pass address;

```
该指令配置被代理的php-fpm的地址，一般地址后要跟监听的端口，默认为9000
```

2、fastcgi_index name;

```
该指令配置fastcgi默认的主页资源
```

3、fastcgi_param parameter value [if_not_empty];

```
该指令配置fastcgi指定的参数和参数的值

一般这里要配置 SCRIPT_FILENAME 的值为php-fpm主机上php的资源路径

value：php或者php-fpm主机上的 php资源路径的地址
parameter：一般为 SCRIPT_FILENAME 这个变量

fastcgi_param   SCRIPT_FILENAME /web/www1/fcgi$fastcgi_script_name;
```

4、fastcgi_cache_path path [levels=levels] keys_zone=name:size [max_size=size];

```
该指令用于设置Nginx服务器存储数据缓存的路径以及缓存索引相关的内容（只能定义在http中或者server之外）

levels=levels           缓存目录的层级数量，以及每一级的目录数量；levels=ONE:TWO:THREE
keys_zone=name:size     k/v映射的内存空间的名称及大小
inactive=time           非活动时长
max_size=size           磁盘上用于缓存数据的缓存空间上限
```

5、fastcgi_cache zone | off;

```
该指令调用指定的缓存空间来缓存数据
```

6、fastcgi_cache_key string;

```
定义用作缓存项的key的字符串；
```

7、fastcgi_cache_min_uses number;

```
缓存空间中的缓存项在inactive定义的非活动时间内至少要被访问到此处所指定的次数方可被认作活动项；
```

8、fastcgi_cache_valid [code ...] time;

```
不同的响应码各自的缓存时长；
```

9、fastcgi_keep_conn on | off;

```
是否开启fastcgi的保持连接

因为Nginx作为代理，是以客户端的身份与后端的php服务器进行传输，所以每有1个新的请求，就需要一个新的随机端口与php进行交互
这样在并发请求数非常大的情况下，会造成端口可能不够用。
这时，就需要开启这个功能，提供一个类似于管道的连接，使用一个端口传输多个请求，提高性能
```

#### <font color="#D19275">配置文件预览</font>


```
$ vim /etc/nginx/conf.d/maxie.conf
proxy_cache_path		/web/cache/   levels=2:1:1    keys_zone=my_cache:10mmax_size=1g;

server {
    listen             80;
    server_name        www1.maxie.com;
    root               /web/www1;
    index              index.html index.htm;
    add_header         X-Via	$server_addr;
    add_header         X-Accel	$server_name;
    
    location / {
    access_log        /web/www1/access.log my_log flush=4m buffer=1m;
    }
        
    location ~* \.php$ {
    	root               /web/www1/fcgi;
    	fastcgi_pass       172.16.1.120:9000;
    	fastcgi_index      index.php;
    	fastcgi_param      SCRIPT_FILENAME /web/www1/fcgi$fastcgi_script_name;
    	include            fastcgi_params;
    
    	fastcgi_cache      fcgi_cache;
    	fastcgi_cache_key  $request_uri;
    	fastcgi_cache_methods  GET HEAD;
    	fastcgi_cache_min_uses 2;
    	fastcgi_cache_valid    200 301 302 5m;
    	fastcgi_cache_valid    any 1m;
    	fastcgi_keep_conn      on;
    }
    
    location ~* ^/pm_(ping|status)$ {
    	include            fastcgi_params;
    	fastcgi_pass       172.16.1.120:9000;
    	fastcgi_param      SCRIPT_FILENAME $fastcgi_script_name;
    }
    
    location ~* ^/pma$ {
    	root               /web/www1/;
    	include            fastcgi_params;
    	fastcgi_pass       172.16.1.120:9000;
    	fastcgi_param      SCRIPT_FILENAME /web/www/fcgi$fastcgi_script_name;
    
    	#^表示从匹配的开始就替换为后面的URL
    	if ($request_filename ~ /pma ) {
    		rewrite	^	http://www1.maxie.com/pma/index.php permanent;
    	}
    }   
    
    location ~* \.(jpg|png|gif|jpeg)$ {
    	proxy_pass            http://172.16.1.20:80;
    	proxy_redirect        default;
    	proxy_set_header      X-Real-IP    $remote_addr;
    	proxy_cache           my_cache;
    	proxy_cache_key       $request_uri;
    	proxy_cache_valid     200 301 302 10m;
    	proxy_cache_valid     any 1m;
    
    	proxy_cache_methods   GET HEAD;
    	proxy_connect_timeout 10s;
    
    	#proxy_hide_header    ETag;
    	#proxy_hide_header    Content-Type;
    
    	#proxy_pass_header    Server;
    	#proxy_pass_header    Date;
    }
    
    error_page             404	    http://www1.maxie.com/404.html;
    
    location = /404.html {
	}
}
```

#### <font color="#D19275">效果演示</font>


**1.访问php页面自动代理至php-fpm处理：**

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgo5v6vbxog30qk0fc7wr.gif)

**2.访问php自带的测试页：**

![](https://ws2.sinaimg.cn/large/006tNc79ly1fgo5x7ggqwg30qk0fc4r1.gif)

**3.测试fastcgi缓存功能**

* 未开启缓存功能 压测index.php：(5000访问，200并发，总耗时374.381ms）

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgo648k19zg30qk0fckju.gif)

* 开启缓存功能 压测index.php：（5000访问，200并发，总耗时45.795ms）

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgo65wjx7og30qk0fc7wr.gif)

由此测试可见缓存的重要性

-------

{% note info %}### Nginx upstream详解
{% endnote %}

#### 什么是负载均衡

网络负载均衡技术的大致原理是利用一定的`分配策略`将网络负载平衡地分摊到网络集群的`各个工作单元`上，使得单个重负负载任务能够分担到多个单元上`并行处理`，或者使得大量并发访问或者数据流量分担到多个单元上`分别处理`，从而减少用户的等待响应时间。

在实际应用中，负载均衡会根据网络的不同层次（一般按照OSI的七层参考模型）进行划分。现代的负载均衡技术主要实现和作用域网络的第四层（传输层）或第七层（应用层），完全独立于网络基础硬件设备，成为单独的技术设备。

`Nginx`服务器实现的负载均衡一般认为是`七层负载均衡`。


![OSI模型](https://ws4.sinaimg.cn/large/006tNc79ly1fgo6iv2gi1j30sm1a81kx.jpg)

<br>

#### Nginx服务器负载均衡配置

理解了“负载均衡”的概念，就可以利用Nginx服务器实现负载均衡的配置了。Nginx服务器实现了静态的基于`优先级`的`加权轮询(weighted round robin)`算法，主要使用的配置是`proxy_pass`指令和`upstream`指令，这些内容实际上很容易理解，关键点在于Nginx服务器的配置灵活多样，<font coloro="#FF0000">如何在配置均衡负载的同时合理的融合其他功能，形成一套可以满足实际需求的配置方案。</font>

<br>

#### upstream模块详解

1、upstream name { ... }

```
定义后端服务器组，会引入一个新的上下文
需要定义在http中，server之外
```
<br>
2、server address [parameters];

```
在upstream上下文中server成员
```

address的表示格式

```
unix:/PATH/TO/SOME_SOCK_FILE
IP[:PORT]
HOSTNAME[:PORT]
```

parameters的可用参数：


```
weight=number           权重，默认为1
max_fails=number        失败尝试最大次数；超出此处指定的次数时，server将被标记为不可用
fail_timeout=time       设置将服务器标记为不可用状态的超时时长
max_conns               当前的服务器的最大并发连接数
backup                  将服务器标记为“备用”，即所有服务器均不可用时此服务器才启用(可以用来做sorry server)
down                    标记为“不可用”
```
<br>
3、least_conn;

```
最少连接调度算法，当server拥有不同的权重时其为wlc
```
<br>
4、ip_hash;

```
源地址hash调度方法；
```
<br>
5、hash key [consistent];

```
基于指定的key的hash表来实现对请求的调度，此处的key可以直接文本、变量或二者的组合

作用：将请求分类，同一类请求将发往同一个upstream server
```
<br>
6、keepalive connections;

```
为每个worker进程保留的空闲的长连接数量
```

#### upstream配置实例

##### <font size=3 color="#D19275">配置文件预览</font>


```
$ vim /etc/nginx/conf.d/balancing.conf
#Load Balancing
upstream websrvs {
        #ip_hash;
        server 172.16.1.20      weight=1 max_fails=2 fail_timeout=10;
        server 172.16.1.130     weight=1 max_fails=2 fail_timeout=10;
        server localhost:10080  weight=1 backup;
}

server {
        listen                          10080;
        server_name                     localhost;
        root                            /web/backup;
}

server {
        listen                          8080;
        server_name                     www.balancing.com;

        location / {
                proxy_pass              http://websrvs;
                proxy_set_header        X-Real-IP $remote_addr;
        }
}
```

##### <font size=3 color="#D19275">效果演示</font>

![](https://ws2.sinaimg.cn/large/006tNc79ly1fgo77e1z5ug30qk0fcb2j.gif)


##### <font size=3 color="#D19275">配置文件详解</font>

![](https://ws1.sinaimg.cn/large/006tNc79ly1fgwc66reuuj31kw1ll4qp.jpg)

-------

{% note warning %}### Re:配置LEMP
{% endnote %}

#### Engine X (Nginx) 配置


##### <font size=3 color="#32CD99">1、安装Nginx </font>

```
$ yum info nginx
$ yum install nginx
```

如果yum仓库中没有 `nginx`，需要到官方站点下载，并使用如下命令安装；或者[编译安装](http://maxiecloud.com/2017/06/14/nginx-1/)，在之前的一章已经讲过了。

```
$ wget http://nginx.org/packages/centos/7/x86_64/RPMS/nginx-1.10.2-1.el7.ngx.x86_64.rpm
$ yum install ./nginx-1.10.2-1.el7.ngx.x86_64.rpm
```

<br>

##### <font size=3 color="#32CD99">2、修改主配置文件，添加自定义日志格式 </font>


```
$ cd /etc/nginx 
$ vim nginx.conf
http {
	log_format	my_log	'$remote_addr - - $remote_user [$time_local] "$request"'
						'$status $body_bytes_sent "$http_referer"'
						'$http_user_agent';
}
```

<br>

##### <font size=3 color="#32CD99">3、添加虚拟主机配置文件 </font>


```
$ vim conf.d/maxie.conf
fastcgi_cache 					/web/cache/fcgi levels=2:1:1 keys_zone=fcgi_cache:20m inactive=1m max_size=1g;

server {
	listen 					80;
	server_name				www1.maxie.com;
	root					/web/www1/;
	index 					index.php index.html index.htm;
	add_header				X-Via   $server_addr;
	add_header				X-Accel $server_name;

	location / {
		try_files			$uri $uri/ /index.html;
		access_log			/web/www1/access.log my_log flush=4m buffer=1m;
	}

	location ~* \.php$ {
		root				/web/www1/fcgi;
		fastcgi_pass			172.16.1.120:9000;
		fastcgi_index			index.php;
		fastcgi_param 			SCRIPT_FILENAME /web/www1/fcgi$fastcgi_script_name;

		fastcgi_cache 			fcgi_cache;
		fastcgi_cache_key		$request_uri;
		fastcgi_cache_methods	        GET HEAD;
		fastcgi_cache_min_uses	        2;
		fastcgi_cache_valid		200 301 302 10m;
		fastcgi_cache_valid		any 1m;
		fastcgi_keep_conn		on;

		include				fastcgi_params;
	}

	location ~* ^/pm_(ping|status)$ {
		include				fastcgi_params;
		fastcgi_pass			172.16.1.120:9000;
		fastcgi_param 			SCRIPT_FILENAME /web/www1/fcgi$fastcgi_script_name;

	}

	location ~* ^/pma$ {
		include				fastcgi_params;
		fastcgi_pass			172.16.1.120:9000;
		fastcgi_param 			SCRIPT_FILENAME /web/www1/fcgi$fastcgi_script_name;

		if ($request_filename ~ /pma ) {
            rewrite ^       	http://www1.maxie.com/pma/index.php permanent;
    	}
	}
}
```

<br>

##### <font size=3 color="#32CD99">4、创建配置文件中的目录以及主站html </font>

```
$ mkdir -pv /web/www1/
$ mkdir -pv /web/cache/
$ vim /web/www1/index.html 
<h1> Nginx Server </h1>
<h2> =_= </h2>
```

![](https://ws3.sinaimg.cn/large/006tNc79ly1fgo8z39mo1j30qo0fgjsr.jpg)

<br>


#### php-fpm配置

##### <font size=3 color="#007FFF">1、安装php-fpm以及其他所需组件</font>

```
$ yum -y install php-fpm php-mysql php-mbstring
```


<br>

##### <font size=3 color="#007FFF">2、编辑配置文件</font>

```
$ vim /etc/php-fpm.d/www.conf
将如下选项修改默认值的为这里的值：
listen = 172.16.1.120:9000
listen.allowed_clients = 172.16.1.70
user = nginx
group = nginx
pm.status_path = /pm_status
ping.path = /pm_ping
ping.response = pong
并创建/var/lib/php/session目录 修改属主属组为nginx
```

<br>

##### <font size=3 color="#007FFF">3、创建用户以及所需目录以及主站index.php</font>

```
$ useradd -r nginx 
$ mkdir -pv /var/lib/php/session 
$ chown -R nginx.nginx /var/lib/php/session

$ mkdir -pv /web/www1/fcgi 
$ chown -R nginx.nginx /web/www1/fcgi

$ vim /web/www1/fcgi/index.php
<?php 
	phpinfo();
?>
```

<br>

##### <font size=3 color="#007FFF">4、启动php-fpm</font>

```
$ systemctl start php-fpm
```

<br>

#### MariaDB配置


##### <font size=3 color="#32CD99">1、安装maridb</font>


```
$ yum -y install mariadb-server
```
<br>

##### <font size=3 color="#32CD99">2、编辑配置文件</font>

```
$ vim /etc/my.conf
[mysqld]
skil_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin
```

<br>
##### <font size=3 color="#32CD99">3、启动mariadb</font>

```
$ systemctl start mariadb.service
```
<br>

##### <font size=3 color="#32CD99">4、授权远程用户登陆数据库</font>

```
$ mysql 
> GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.1.120' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.1.70' IDENTIFIED BY 'root@123';
> FLUSH PRIVILEGES;
```

<br>

#### 配置phpMyAdmin 

##### <font size=3 color="#FF7F00">1、拷贝rpm包</font>

```
$ scp Downloads/LinuxPackages/phpMyAdmin-4.0.10.20-all-languages.zip root@172.16.1.120:/web/www1/fcgi/
```

<br>
##### <font size=3 color="#FF7F00">2、解压缩并修改配置文件</font>

**php主机上进行的操作：**

```
$ tar -xf /web/www1/fcgi/phpMyAdmin-4.0.10.20-all-languages.zip
$ cd /web/www1/fcgi/
$ ln -sv phpMyAdmin-4.0.10.20-all-languages pma
$ cd pma 
$ cp config.sample.inc.php config.inc.php
$ vim config.inc.php
修改下面一行中的localhost改为 mariadb主机的IP地址
$cfg['Servers'][$i]['host'] = '172.16.1.110';

$ vim libraries/config.default.php
修改下面一行中的localhost改为 mariadb主机的IP地址
$cfg['Servers'][$i]['host'] = '172.16.1.110';

$ chown -R nginx.nginx /web/www1/fcgi
```

**nginx主机上进行的操作：**

```
$ scp root@172.16.1.120:/web/www1/fcgi/phpMyAdmin-4.0.10.20-all-languages /web/www1/pma
$ chown -R nginx.nginx /web/www1/
```

##### <font size=3 color="#FF7F00">3、开启nginx服务、打开网页进行测试即可，LEMP搭建完成/font>


```
$ nginx -t
$ systemctl start nginx 
```


#### 配置文件预览


```
$ vim /etc/nginx/conf.d/maxie.conf
fastcgi_cache_path              /web/cache/fcgi levels=2:1:1 keys_zone=fcgi_cache:20m inactive=1m max_size=1g;

server {
        listen                  80;
        server_name             www1.maxie.com;
        root                    /web/www1;
        index                   index.php index.html index.htm;
        add_header              X-Via   $server_addr;
        add_header              X-Accel $server_name;

        location / {
                access_log              /web/www1/access.log my_log flush=4m buffer=1m;
        }

        location ~* \.php$ {
                root                    /web/www1/fcgi;
                fastcgi_pass            172.16.1.120:9000;
                fastcgi_index           index.php;
                fastcgi_param           SCRIPT_FILENAME /web/www1/fcgi$fastcgi_script_name;
                include                 fastcgi_params;

                fastcgi_cache           fcgi_cache;
                fastcgi_cache_key       $request_uri;
                fastcgi_cache_methods   GET HEAD;
                fastcgi_cache_min_uses  2;
                fastcgi_cache_valid     200 301 302 5m;
                fastcgi_cache_valid     any 1m;
                fastcgi_keep_conn       on;
        }

        location ~* ^/pm_(ping|status)$ {
                include                 fastcgi_params;
                fastcgi_pass            172.16.1.120:9000;
                fastcgi_param           SCRIPT_FILENAME $fastcgi_script_name;
        }

        location ~* ^/pma$ {
                root                    /web/www1/;
                include                 fastcgi_params;
                fastcgi_pass            172.16.1.120:9000;
                fastcgi_param           SCRIPT_FILENAME /web/www/fcgi$fastcgi_script_name;

                #^表示从匹配的开始就替换为后面的URL
                if ($request_filename ~ /pma ) {
                        rewrite ^       http://www1.maxie.com/pma/index.php permanent;
                }
        }
        
        error_page                      404     http://www1.maxie.com/404.html;

        location = /404.html {
        }
}
```

#### 实例演示

![](https://ws3.sinaimg.cn/large/006tNc79ly1fgo9g2f8fdg30qk0fc1la.gif)



-------

{% note danger %}### Re:配置LNAMP
{% endnote %}


**目标：**


```
实现lnamp、并实现如下功能
1、http，提供WordPress
2、https，提供phpMyAdmin
```

**实验拓扑结构：**

```
nginx               172.16.1.100/16 
ap(httpd+php)       172.16.1.70/16
mariadb             172.16.1.20/16
```

#### Engine X (Nginx) 

#### <font size=3 color="#38B0DE">安装与配置 </font>

* 安装nginx

```
$ yum install -y nginx
```

* 修改配置文件

```
$ vim /etc/nginx/nginx.conf
在server块进行如下操作：

1、修改root目录
    root    /data/www1;

2、添加location将以php结尾的资源代理到ap上
#添加缓存目录
proxy_cache_path        /web/cache/    levels=2:1:1    keys_zone=pcache:10m    max_size=1g;

server {
    listen       80 default_server;
    listen       [::]:80 default_server;
    server_name  _;
    root         /data/www1/;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;

    location / {
    }

    #添加如下location
    location ~* \.php$ {
            proxy_pass                      http://172.16.1.70:80;
            proxy_set_header                X-Real-IP       $remote_addr;
            proxy_cache                     pcache;
            proxy_cache_key                 $request_uri;
            proxy_cache_valid               200 301 302 10m;
            proxy_cache_valid               any 1m;

            proxy_cache_methods             GET HEAD;
            proxy_connect_timeout           10s;
    }
```

* 创建所需目录以及主站文件

```
$ mkdir -pv /web/cache
$ mkdir -pv /data/www1
$ vim /data/www1/index.html
<h1> NgInX Server </h1>
```

* 启动nginx服务，打开浏览器验证

```
$ nginx -t
$ systemctl start nginx
$ curl http://172.16.1.100/
<h1> NgInX Server </h1>
```


-------

#### AP --> apache + php

#### <font size=3 color="#32CD99"> 安装与配置 </font>

* 安装

```
$ yum install -y httpd php php-mysql php-mbstring php-mcrypt
```

* 创建index.html和index.php

```
$ cd /var/www/html/
$ vim index.html
	<h1>HTTP Server 172.16.1.70 </h1>

	<h2> AP Server </h2>
$ vim index.php 
<?php 
		phpinfo();
?>
```

#### <font size=3 color="#32CD99"> 拷贝WordPress以及phpMyAdmin </font>

* 拷贝wordpress以及pma到http服务器的DocumentRoot目录下
 
```
$ scp wordpress-4.7.4-zh_CN.tar.gz phpMyAdmin-4.0.10.20-all-languages.zip root@172.16.1.70:/var/www/html
wordpress-4.7.4-zh_CN.tar.gz                                 100% 8308KB   4.4MB/s   00:01
phpMyAdmin-4.0.10.20-all-languages.zip                       100% 7282KB   4.4MB/s   00:01		
```

* 解压缩wordpress以及pma

```
$ tar -xf wordpress-4.7.4-zh_CN.tar.gz
$ unzip phpMyAdmin-4.0.10.20-all-languages.zip
$ ln -sv phpMyAdmin-4.0.10.20-all-languages pma
```

* 启动http服务并测试


```
$ systemctl start httpd
$ curl http://172.16.1.70/index.html
$ curl http://172.16.1.70/index.php
```

-------

#### MariaDB

#### <font size=3 color="#70DBDB"> 安装与配置 </font>

* 安装

```
$ yum install -y mariadb-server
```

* 配置

```
$ vim /etc/my.cnf.d/server.conf
[mysqld]
skip_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin
```

* 创建WordPress所需的数据库及用户，并授权远程连接权限

```
$ mysql
> CREATE DATABASE wordpress_db;
Query OK, 1 row affected (0.00 sec)

> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'172.16.1.70' IDENTIFIED BY 'root@123';
Query OK, 0 rows affected (0.00 sec)

> GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.1.70' IDENTIFIED BY 'root@123';
Query OK, 0 rows affected (0.00 sec)

> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

> exit
```

* 在ap服务器上修改pma以及wordpress的数据库配置

```
phpMyAdmin：

$ cp pma/config.sample.inc.php pma/config.inc.php
$ pwd
/var/www/html
$ vim pma/config.inc.php
修改其下信息：
$cfg['Servers'][$i]['host'] = '172.16.1.20';

$ vim pma/libraries/config.default.php
修改其下信息：
$cfg['Servers'][$i]['host'] = '172.16.1.20';


WordPress：

$ cp wordpress/wp-config-sample.php wordpress/wp-config.php
$ vim wordpress/wp-config.php
修改为如下信息：

// ** MySQL 设置 - 具体信息来自您正在使用的主机 ** //
/** WordPress数据库的名称 */
define('DB_NAME', 'wordpress_db');

/** MySQL数据库用户名 */
define('DB_USER', 'wordpress');

/** MySQL数据库密码 */
define('DB_PASSWORD', 'root@123');

/** MySQL主机 */
define('DB_HOST', '172.16.1.20');
```

#### <font size=3 color="#70DBDB"> 拷贝ap上pma和wordpress到nginx的网站root目录下 </font>

* ap操作：

```
$ scp -r phpMyAdmin-4.0.10.20-all-languages root@172.16.1.100:/data/www1/
$ scp -r  wordpress  root@172.16.1.100:/data/www1
$ chown -R apache.apache wordpress *
$ chmod +x wordpress/wp-content
```

* nginx操作：

```
$ cd /data/www1/
$ chown -R nginx.nginx *
$ ln -sv phpMyAdmin-4.0.10.20-all-languages/ pma
```

-------

#### 测试

打开网页输入网址即可测试


-------

#### 增加https功能


#### <font size=3 color="#236B8E"> 自建CA并自签nginx证书 </font>

* 自建CA

```
$ cd /etc/pki/CA/
$ (umask 077;openssl genrsa -out /etc/pki/CA/private/cakey.pem 4096)
$ openssl req -new -x509 -key /etc/pki/CA/private/cakey.pem -out /etc/pki/CA/cacert.pem -days 3650
$ touch {serial,index.txt}
$ echo 01 > serial
```

* 生成ssl签署请求，并让CA签署

```
$ mkdir -pv /etc/nginx/ssl 
$ cd /etc/nginx/ssl 
$ (umask 077;openssl genrsa -out /etc/nginx/ssl/nginx.key 4096)
$ openssl req -new -key /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.csr -days 550
$ openssl ca -in /etc/nginx/ssl/nginx.csr -out /etc/nginx/ssl/nginx.crt
```

#### <font size=3 color="#236B8E"> 编辑nginx配置文件，开启ssl功能 </font>


```
$ vim /etc/nginx/nginx.conf
添加一个server对80进行转发：
server {
	listen 80;
	server_name www1.maxie.com;
	rewrite ^	https://$server_name$1 permanent;
}

修改默认server：
server {
listen       443 ssl;
server_name  www1.maxie.com;
root         /data/www1/;

# Load configuration files for the default server block.
include /etc/nginx/default.d/*.conf;

#SSL
ssl                                     on;
ssl_certificate                         /etc/nginx/ssl/nginx.crt;
ssl_certificate_key                     /etc/nginx/ssl/nginx.key;
ssl_session_timeout                     5m;
ssl_protocols                           SSLv2 TLSv1 SSLv3;
ssl_ciphers                             HIGH:!aNULL:!MD5;

ssl_session_cache                       shared:sslcache:20m;

其余配置不变

$ nginx -t 
$ nginx -s reload
```

#### <font size=3 color="#236B8E"> 拷贝CA公钥到MBP，导入浏览器中，验证 </font>


```
$ scp root@172.16.1.100:/etc/pki/CA/cacert.pem ./
cacert.pem   100% 1992   422.8KB/s   00:00
```



### 到此Nginx的相关知识与实践实验就结束啦


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=21968164&auto=1&height=66"></iframe>
				

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


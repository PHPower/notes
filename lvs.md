---
title: LVS从入门到进阶
date: 2017-06-22 14:05:27
tags: [linux,lvs,cluster,nginx,server]
categories: LVS
copyright: true
---

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgtydyz1tbj30xc0go4qp.jpg)

<blockquote class="blockquote-center">一组服务器通过高速的局域网或者地理分布的广域网相互连接，在它们的前端有一个负载调度器（Load Balancer）。
负载调度器能无缝地将网络请求调度到真实服务器上，从而使得服务器集群的结构对客户是透明的，
客户访问集群系统提供的网络服务就像访问一台高性能、高可用的服务器一样。

客户程序不受服务器集群的影响不需作任何修改。
系统的伸缩性通过在服务机群中透明地加入和删除一个节点来达到，通过检测节点或服务进程故障和正确地重置系统达到高可用性。
由于我们的负载调度技术是在Linux内核中实现的，我们称之为Linux虚拟服务器（Linux Virtual Server）。
</blockquote>

在1998年5月，章博士成立了Linux Virtual Server的自由软件项目，进行Linux服务器集群的开发工作。同时，Linux Virtual Server项目是国内最早出现的自由软件项目之一。

`Linux Virtual Server项目的目标` ：使用集群技术和Linux操作系统实现一个高性能、高可用的服务器，它具有很好的可伸缩性（Scalability）、可靠性（Reliability）和可管理性（Manageability）。


-------

<!-- more -->

<font size=4 color="#FF7F00">LVS术语：</font>


```
VS：Virtual Server
RS：Real Server

CIP：Client IP
VIP：Virtual Server IP
RIP：Real Server IP
DIP：Director IP

CIP <--> VIP == DIP <--> RIP
```

**注意：**这里的RIP，可不是`R.I.P` --> 安息吧的意思哦~


-------


{% note primary %}### IP虚拟机服务器软件IPVS
{% endnote %}

在调度器的实现技术中，IP负载均衡技术是效率最高的。

其中关于IP负载均衡技术有三种最关键的技术：`VS/NAT`，`VS/DR`，`VS/TUN`

-------

#### <font color="#D19275"> VS/NAT详解 </font>

**概念：**通过网络地址转化的功能，调度器(Director)重写请求报文的目标地址，根据预设的`调度算法`，将请求分派给后端的真实服务器(Real Server)；真实服务器的响应报文通过调度器时，报文的源地址又被重写，再通过调度器返回给用户，完成整个负载调度过程。
其中`Real Server`在发送响应报文之前，需要将`Director`的IP地址作为自己的网关，否则可能会出现能接收请求报文，而无法返回响应报文；

**拓扑图：**

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgtzl2ljr4j30xd0irdhl.jpg)


**总结：**

```
1、RIP和DIP必须在同一个网段内，且应该使用私网IP地址；RS的网关要指向DIP --> route add default gw DIP
2、请求报文和响应报文都必须经由调度器(DIRECTOR)转发；这样会让调度器的负载大大增加，成为系统瓶颈
3、支持端口映射，可修改请求报文的目标端口
4、VS必须是Linux系统，RS可以是任意系统
```

<br>

#### <font size=4 color="#32CD99">配置VS/NAT</font>

**准备工作**

```
3台虚拟机、同步时间

VS主机：
VIP 172.16.3.100/16
DIP 192.168.1.254/24

RS1主机：
RIP 192.168.1.10/24 gateway 192.168.1.254

RS2主机：
RIP 192.168.1.20/24 gateway 192.168.1.254

客户端主机：
CIP 172.16.1.11/16 
```


1、VS主机操作如下：

[1] 安装ipvsadm管理工具

```
$ yum install ipvsadm
```

[2] 开启核心转发功能(永久生效)

```
$ vim /etc/sysctl.conf
net.ipv4.ip_forward = 1
$ sysctl -p
```

<br>

2、RS两台主机操作如下：(除网页内容不同，其余操作均相同)

[1] 安装nginx

```
$ yum install nginx
```

[2] 添加测试页内容

```
RS1：
$ echo "RS1 192.168.1.10" > /usr/share/nginx/html/index.html
$ systemctl start nginx

RS2：
$ echo "RS2 192.168.1.20" > /usr/share/nginx/html/index.html
$ systemctl start nginx
```

[3] 通过VS主机对测试页进行测试检查

```
$ curl http://192.168.1.10
RS1 192.168.1.10

$ curl http://192.168.1.20
RS2 192.168.1.20
```

<br>

3、VS主机上添加负载均衡集群规则

```
$ ipvsadm -A -t 172.16.3.100:80 -s rr      #这里我们使用round robin调度算法，之后我们会对调度算法进行详解
$ ipvsadm -a -t 172.16.3.100:80 -r 192.168.1.10 -m  #这里-m表示我们使用的负载均衡技术是VS/NAT类型的
$ ipvsadm -a -t 172.16.3.100:80 -r 192.168.1.20 -m
$ ipvsadm -ln 
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.16.3.100:80 rr 
  -> 172.16.3.20:80               Masq   1      0          0
  -> 172.16.3.30:80               Masq   1      2          0
```

<br>

4、客户端进行测试

```
$ for i in {1..10}; do curl http://172.16.3.100/index.html ;done
RS1 192.168.1.10
RS2 192.168.1.20
RS1 192.168.1.10
RS2 192.168.1.20
RS1 192.168.1.10
RS2 192.168.1.20
RS1 192.168.1.10
RS2 192.168.1.20
RS1 192.168.1.10
RS2 192.168.1.20
```

**测试成功，VS/NAT配置完成**


-------

#### <font color="#D19275"> VS/DR详解 </font>

**概念：**VS/DR通过改写请求报文的MAC地址，将请求发送到真实服务器，而真实服务器直接响应返回给客户端。这样大大提高了集群系统的伸缩性，这种方法要求调度器和真实服务器都有一块网卡连在同一物理网段上。

**拓扑图：**

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgu1rnjufuj30z30nogne.jpg)

**总结：**

```
1、确保前端路由器将目标IP为VIP的请求报文发往Director
    (a) 在前端网关做静态绑定；
    (b) 在RS上使用arptables；
    (c) 在RS上修改内核参数以限制arp通告及应答级别；
    	arp_announce
    	arp_ignore
2、 RS的RIP可以使用私网地址，也可以是公网地址；RIP与DIP在同一IP网络；RIP的网关不能指向DIP，以确保响应报文不会经由Director
3、RS跟Director要在同一个物理网络；
4、请求报文要经由Director，但响应不能经由Director，而是由RS直接发往Client；
5、不支持端口映射；
6、各RS必须有VIP地址(拒绝ARP广播)，绑定在lo的别名上即可
```

<br>

#### <font size=4 color="#32CD99">配置VS/DR</font>

**实验目标：**

```
负载均衡两个php应用（wordpress，discuzx）
并为其配置NFS以及会话保持功能
```

**实验准备：**

```
VS主机：
VIP 172.16.3.100/32 
DIP 172.16.3.10/16

RS1主机：
RIP 172.16.3.20/16 
VIP 172.16.3.100/32

RS2主机：
RIP 172.16.3.30/16
VIP 172.16.3.100/32

MySQL主机：
MIP 172.16.3.40/16

NFS主机：
NIP 172.16.3.50/16
```

<br>

1、在VS、RS主机上配置网卡别名

[1] VS配置网卡别名：

```
$ ifconfig eno16777736 172.16.3.100 netmask 255.255.255.255 broadcast 172.16.3.100 up
```

[2] 编写脚本、配置RS的网卡别名并不接受arp广播

```
$ vim set-rs.sh
#!/bin/bash
#
vip=172.16.3.100
mask=255.255.255.255

case $1 in
start)
    echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
    echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore
    echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
    echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce

    ifconfig lo:0 $vip netmask $mask broadcast $vip up
    route add -host $vip dev lo:0
    ;;
stop)
    ifconfig lo:0 down

    echo 0 > /proc/sys/net/ipv4/conf/all/arp_ignore
    echo 0 > /proc/sys/net/ipv4/conf/lo/arp_ignore
    echo 0 > /proc/sys/net/ipv4/conf/all/arp_announce
    echo 0 > /proc/sys/net/ipv4/conf/lo/arp_announce

    ;;
*)
    echo "Usage $(basename $0) start|stop"
    exit 1
    ;;
esac

RS1：
$ bash -x set-rs.sh start 

RS2：
$ bash -x set-rs.sh start 
```

<br>

2、RS1、2安装nginx以及php-fpm、在VS上配置ipvsadm的dr负载均衡技术，使用rr调度算法

[1] RS操作如下：

```
$ yum install -y nginx php-fpm php-mbstring php-mcrypt
```

[2] VS操作如下：

```
$ ipvsadm -A -t 172.16.3.100:80 -s rr
$ ipvsadm -a -t 172.16.3.100:80 -r 172.16.3.20:80 -g
$ ipvsadm -a -t 172.16.3.100:80 -r 172.16.3.30:80 -g
```

<br>

3、RS1与RS2配置nginx对于php-fpm的代理：(两台同样的步骤)

[1] 编辑php-fpm的配置文件：

```
$ vim /etc/php-fpm.d/www.conf
user = nginx
group = nginx
pm.status_path = /status
ping.path = /ping
ping.response = pong

$ mkdir -pv /var/lib/php/session 
$ chown -R nginx.nginx /var/lib/php/session
$ systemctl start php-fpm 
```

[2] 编辑nginx配置文件:
这里最好删除主配置文件内的`server`块的配置信息，防止干扰

`RS1配置`：

```
$ vim /etc/nginx/conf.d/www1.conf
server {
        listen 80;
        server_name     172.16.3.20;
        root            /data/www1;
        index           index.html index.htm index.php;

        location ~* \.php$ {
                fastcgi_pass    127.0.0.1:9000;
                fastcgi_index   index.php;
                fastcgi_param   SCRIPT_FILENAME /nfs$fastcgi_script_name;

                include         fastcgi_params;
        }
}
```

`RS2配置`：

```
$ vim /etc/nginx/conf.d/www1.conf
server {
        listen 80;
        server_name     172.16.3.30;
        root            /data/www1;
        index           index.html index.htm index.php;

        location ~* \.php$ {
                fastcgi_pass    127.0.0.1:9000;
                fastcgi_index   index.php;
                fastcgi_param   SCRIPT_FILENAME /nfs$fastcgi_script_name;

                include         fastcgi_params;
        }
}
```

[3] 创建目录以及php测试页：

```
$ mkdir -pv /data/www1
$ mkdir -pv /data/cache 
$ vim /data/index.php
NODE 1 / NODE2          #这里根据RS1、2的分别来选择定义，便于区分
<?php 
	phpinfo();
?>
```

[4] 重启服务，测试Php的测试页是否正常访问：

```
$ nginx -t 
$ nginx -s reload

$ curl http://172.16.3.20/index.php
NODE 1
...
...
$ curl http://172.16.3.30/index.php
NODE 2
...
...
```

<br>

4、拷贝wordpress以及discuzx到`NFS`的共享目录下并开启`NFS`共享

[1] 拷贝程序包到NFS

```
$ scp wordpress-4.7.4-zh_CN.tar.gz root@172.16.3.50:/nfs
wordpress-4.7.4-zh_CN.tar.gz                                100% 8308KB   2.9MB/s   00:02
$ scp Discuz_X3.3_SC_UTF8.zip root@172.16.3.50:/nfs/
Discuz_X3.3_SC_UTF8.zip                                     100%   10MB   2.2MB/s   00:04
```

[2] 创建单独目录、解压、修改权限：

```
$ mkdir -pv /nfs/{wp,pma,discuzx}
$ useradd -r nginx
$ tar -xf wordpress-4.7.4-zh_CN.tar.gz -C /nfs/wp
$ unzip Discuz_X3.3_SC_UTF8.zip -C /nfs/discuzx
$ chown -R nginx.nginx /nfs
$ cd /nfs/discuzx/
$ mv upload/* ./
```

[3] 创建共享目录，并启动`NFS`服务：

```
$ vim /etc/exports
/nfs/wp         172.16.3.20(rw,no_root_squash) 172.16.3.30(rw,no_root_squash)
/nfs/discuzx    172.16.3.20(rw,no_root_squash) 172.16.3.30(rw,no_root_squash)
$ systemctl start nfs.service
```

<br>

5、回到RS上`挂载NFS`共享的目录(两台RS都要做)

```
$ mkdir -pv /nfs/{wp,pma,discuzx}
$ mount -t 172.16.3.50:/nfs/wp /nfs/wp
$ mount -t 172.16.3.50:/nfs/wp /nfs/discuzx
```

<br>

6、修改RS上nginx虚拟主机配置文件

```
$ vim /etc/nginx/conf.d/www1.conf 
添加三条location：
location / {
    root /data/www1;
}

location /wp/wordpress {
    root    /nfs;
}

location /discuzx {
    root    /nfs;
}
```

<br>

7、打开各RS的wordpress以及discuzx的访问网址测试

```
http://172.16.3.20/wp/wordpress
http://172.16.3.30/wp/wordpress

http://172.16.3.20/discuzx
http://172.16.3.30/discuzx
```

<br>

8、在任意一台RS上进行对`wordpress`配置文件进行修改

```
$ vim /data/wordpress/wp-config.inc.php
// ** MySQL 设置 - 具体信息来自您正在使用的主机 ** //
/** WordPress数据库的名称 */
define('DB_NAME', 'wordpress_db');

/** MySQL数据库用户名 */
define('DB_USER', 'wordpress');

/** MySQL数据库密码 */
define('DB_PASSWORD', 'root@123');

/** MySQL主机 */
define('DB_HOST', '172.16.3.40');
```

<br>

9、在`MySQL`主机上创建WordPress和Discuzx的数据库以及用户

[1] 修改MySQL配置文件

```
$ vim /etc/my.cnf.d/server.conf 
[mysqld]
skip_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin

$ systemctl start mariadb.service
```

[2] 创建数据库以及用户信息

```
$ mysql
> CREATE DATABASE wordpress_db;
> CREATE DATABASE discuzx_db;
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'172.16.3.20' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'172.16.3.30' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress'@'172.16.3.50' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON discuzx_db.* TO 'discuzx'@'172.16.3.20' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON discuzx_db.* TO 'discuzx'@'172.16.3.30' IDENTIFIED BY 'root@123';
> GRANT ALL PRIVILEGES ON discuzx_db.* TO 'discuzx'@'172.16.3.50' IDENTIFIED BY 'root@123';
> FLUSH PRIVILEGES;
> exit;
```

<br>

现在打开`WordPress`和`Discuzx`就可以进行设置了

![](https://ws4.sinaimg.cn/large/006tKfTcly1fgu3rtfkn9j31hc1pskf0.jpg)

<br>

10、配置完成之后，我们对各`RS`主机上的`php-fpm`的配置文件要进行一下修改

```
$ vim /etc/php-fpm.d/www.conf
;listen.allowed_clients = 127.0.0.1         #将这条配置注释掉即可

$ systemctl restart php-fpm
$ systemctl restart nginx
```

11、测试

[1] 对于`wordpress`上传图片的问题，其实在之前我们修改wordpress和discuzx目录的属主属组就已经实现了，如果还是上传不到的话，执行如下指令：

```
$ chmod +x /nfs/wp/wordpress/wp-content
```

[2] 输入网址打开测试：

![](https://ws2.sinaimg.cn/large/006tKfTcly1fgu3yxlxjhj31hc1psqv5.jpg)

![](https://ws3.sinaimg.cn/large/006tKfTcly1fgu3z2g8vuj31hc1psnpd.jpg)



-------


{% note success %}### LVS实现健康状态检查以及会话持久连接
{% endnote %}

为了节约时间，实现此次目标就在上一个`VS/DR`的实验的基础之上进行操作

#### <font size=4 color="#32CD99">实现会话持久连接</font>

1、重新定义负载均衡规则

```
$ ipvsadm -C
$ ipvsadm -A -t 172.16.3.100:80 -s rr -p 600            #-p 600持久连接超时时长
$ ipvsadm -a -t 172.16.3.20:80 -r 172.16.3.20 -g
$ ipvsadm -a -t 172.16.3.20:80 -r 172.16.3.30 -g
```

2、也可以使用`ldirectord`实现，下面我们演示如何配置


#### <font size=4 color="#32CD99">使用 ldirectord 实现健康状态检查</font>

1、下载`ldirectord`的rpm包并安装

```
$ wget ftp://172.16.0.1/pub/Sources/6.x86_64/corosync/ldirectord-3.9.5-5.1.x86_64.rpm
$ yum install ./ldirectord-3.9.5-5.1.x86_64.rpm
$ rpm -ql ldirectord
/etc/ha.d                                               #配置文件存放路径
/etc/ha.d/resource.d
/etc/ha.d/resource.d/ldirectord
/etc/init.d/ldirectord
/etc/logrotate.d/ldirectord
/usr/lib/ocf/resource.d/heartbeat/ldirectord
/usr/sbin/ldirectord
/usr/share/doc/ldirectord-3.9.5
/usr/share/doc/ldirectord-3.9.5/COPYING
/usr/share/doc/ldirectord-3.9.5/ldirectord.cf           #配置文件模板
/usr/share/man/man8/ldirectord.8.gz
```

<br>

2、使lvs本机作为sorry server并配置

```
$ yum install nginx 
$ echo "Sorry Server" > /usr/share/nginx/html/index.html
```

<br>

3、拷贝ldriectord配置文件模板并修改配置

```
$ cp /usr/share/doc/ldirectord-3.9.5/ldirectord.cf /etc/ha.d/
$ vim /etc/ha.d/ldirectord.cf
# Global Directives                         #全局配置段
checktimeout=3                              #检查超时时间
checkinterval=1                             #检查间隔，单位为秒
#fallback=127.0.0.1:80                      #全局的sorry server
#fallback6=[::1]:80                         #ipv6的sorry server
autoreload=yes                              #自动加载配置
logfile="/var/log/ldirectord.log"           #日志文件
#logfile="local0"                           #rsyslog
#emailalert="admin@x.y.z"                   #邮件
#emailalertfreq=3600                        #
#emailalertstatus=all                       #出现任何状态都发送邮件
quiescent=no                                #静默模式

# Sample for an http virtual service        #虚拟主机配置段
virtual=172.16.3.100:80                     #定义的lvs的VIP地址
        real=172.16.3.20:80 gate            #RS的IP地址以及负载均衡技术是哪种
        real=172.16.3.30:80 gate
        fallback=127.0.0.1:80 gate          #sorry server
        service=http                        #应用层使用的协议
        scheduler=rr                        #调度算法
        persistent=600                      #持久连接超时时长 
        #netmask=255.255.255.255            #子网掩码
        protocol=tcp                        #传输层协议
        checktype=negotiate                 #检测方式
        checkport=80                        #检查端口为80
        request="index.html"                #请求的哪个页面
        #receive="NODE"                     #请求页面中应包含有的内容
```

<br>

4、启动`ldirectord`服务，会自动生成`ipvsadm`规则

```
$ ipvsadm -C 
$ systemctl start ldirectord.service 
$ ipvsadm -ln 
[root@master ha.d]# ipvsadm -ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.16.3.100:80 rr persistent 600
  -> 172.16.3.20:80               Route   1      0          0
  -> 172.16.3.30:80               Route   1      0          0
```

<br>

5、RS1、RS2进行关闭或者启动Nginx服务，在VS上查看ipvsadm -ln 查看状态检查是否应用

```
RS1：
$ systemctl stop nginx

VS：
$ ipvsadm -ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.16.3.100:80 rr persistent 600
  -> 172.16.3.30:80               Route   1      0          11
  

两台RS都停止服务之后：
$ ipvsadm -ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.16.3.100:80 rr persistent 600
  -> 127.0.0.1:80                 Route   1      0          0
  
  
两台RS启动，自动加载到规则中：
$ ipvsadm -ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  172.16.3.100:80 rr persistent 600
  -> 172.16.3.20:80               Route   1      0          0
  -> 172.16.3.30:80               Route   1      0          0
```


-------


{% note info %}### LVS调度算法详解
{% endnote %}


根据其调度时是否考虑各RS当前的负载状态，可分为静态方法和动态方法两种

长连接(开启会话保持)应该考虑负载不均衡的情况，短连接无需考虑

#### <font size=3 color="#007FFF">静态方法</font>

* 轮叫（Round Robin）

```
调度器通过"轮叫"调度算法将外部请求按顺序轮流分配到集群中的真实服务器上，它均等地对待每一台服务器，而不管服务器上实际的连接数和系统负载。

当服务器的权重为0时，表示该服务器不可用。
```

* 加权轮叫（Weighted Round Robin）

```
调度器通过"加权轮叫"调度算法根据真实服务器的不同处理能力来调度访问请求。这样可以保证处理能力强的服务器处理更多的访问流量。调度器可以自动问询真实服务器的负载情况，并动态地调整其权值。
```

* 源地址散列（Source Hashing）

```
"源地址散列"调度算法根据请求的源IP地址，作为散列键（Hash Key）从静态分配的散列表找出对应的服务器，若该服务器是可用的且未超载，将请求发送到该服务器，否则返回空。

简单的来说，就是将来自于同一个IP地址的请求始终发往第一次挑中的RS，从而实现会话绑定；
```

* 目标地址散列（Destination Hashing）

```
"目标地址散列"调度算法根据请求的目标IP地址，作为散列键（Hash Key）从静态分配的散列表找出对应的服务器，若该服务器是可用的且未超载，将请求发送到该服务器，否则返回空。

简单的来说，就是将发往同一个目标地址的请求始终转发至第一次挑中的RS，典型使用场景是正向代理缓存场景中的负载均衡
```

<br>

#### <font size=3 color="#007FFF">动态方法</font>


* 最少链接（Least Connections）

```
调度器通过"最少连接"调度算法动态地将网络请求调度到已建立的链接数最少的服务器上。如果集群系统的真实服务器具有相近的系统性能，采用"最小连接"调度算法可以较好地均衡负载。

当各个服务器有相同的处理性能时，最小连接调度算法能把负载变化大的请求分布平滑到各个 服务器上，所有处理时间比较长的请求不可能被发送到同一台服务器上。
但是，当各个服务器 的处理能力不同时，该算法并不理想
```

* 加权最少链接（Weighted Least Connections）

```
在集群系统中的服务器性能差异较大的情况下，调度器采用"加权最少链接"调度算法优化负载均衡性能，具有较高权值的服务器将承受较大比例的活动连接负载。调度器可以自动问询真实服务器的负载情况，并动态地调整其权值。
```

* 最短预期延时调度（Shortest Expection Delay）

```
Overhead=(activeconns+1)*256/weight
谁的权重越大，调度时就选谁
```

* 不排队调度（Never Queue）

```
在请求没有的时候，分别平均分给每个RS，等每个RS都有了请求之后；再根据SED(Shortest Expection Delay)的算法进行分配
```


**注意：SED、NQ会增加调度器的负载**

**经常使用的调度算法：**`rr`、`wlc`、`wrr`




-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=35779145&auto=0&height=66"></iframe>


本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)






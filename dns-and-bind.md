---
title: DNS 和 Bind 配置指南 (+httpd服务组合实验)
date: 2017-05-23 19:30:02
tags: [linux,bind,dns,config]
categories: linux进阶
copyright: true
---

<blockquote class="blockquote-center">网域名称系统（英文：Domain Name System，缩写：DNS）是互联网的一项服务。
它作为将域名和IP地址相互映射的一个分布式数据库，能够使人更方便地访问互联网。
DNS使用TCP和UDP端口53。当前，对于每一级域名长度的限制是63个字符，域名总长度则不能超过253个字符。
</blockquote>

DNS最早于1983年由保罗·莫卡派乔斯（Paul Mockapetris）发明；原始的技术规范在882号因特网标准草案（RFC 882）中发布。1987年发布的第1034和1035号草案修正了DNS技术规范，并废除了之前的第882和883号草案。在此之后对因特网标准草案的修改基本上没有涉及到DNS技术规范部分的改动。

早期的域名必须以英文句号“.”结尾，当用户访问`www.maxiecloud.com`的HTTP服务时必须在地址栏中输入：`http://www.maxiecloud.com.`，这样DNS才能够进行域名解析。如今DNS服务器已经可以自动补上结尾的句号。

![](http://www.neustar.biz/blog/dns-cloud.jpg)

<!-- more -->

{% note primary %}### DNS基础知识
{% endnote %}

#### DNS:Domain Name Service 域名解析服务

DNS服务是一个基于C/S架构的协议，在传输层的TCP和UDP协议的53号端口上运行。

**TCP协议：** Transmission Control Protocol
    TCP是面向连接的协议：双方通信之前需要事先建立虚拟连接；
    
**UDP协议：** User Datagram Protocol
	UDP是无连接的协议：双方通信之前无需建立虚拟连接；


**简单的来说：**

```
DNS就像是一个通讯录，Maxie的电话是11503496****，有了通讯录，我们只需通过输入Maxie这个名字就能够自动拨打其电话。
DNS主要是用来定义IP地址和域名的关系。
```

-------

#### 域名空间

域名系统作为一个层次结构和分布式数据库，包含各种类型的数据，包括主机名和域名。DNS数据库中的名称形成一个分层树状结构称为域命名空间。域名包含单个标签分隔点，例如：blog.maxiecloud.com

对于Internet来说，域名层次结构的顶级由ICANN（互联网名称与数字地址分配机构）负责管理。目前，已经有超过250个顶级域名，每个顶级域名可以进一步划为一些子域（二级域名），这些子域可被再次划分（三级域名），依此类推。所有这些域名可以组织成一棵树，如下图所示：

![](https://ws3.sinaimg.cn/large/006tNc79ly1ffwayyiokhj31e00l8jsb.jpg)


-------

#### 域名资源记录

DNS设计之初是用来建立域名到IP地址的映射，理论上对于每一个域名我们只需要在域名服务器上保存一条记录即可。这里的记录一般叫作域名资源记录，它是一个五元组，可以用以下格式表示：


```bash
Domain_name Time_to_live Class Type Value 

Domain_name     指出这条记录对应的域名
Time_to_live    表明记录的生存周期，即缓存时长
Class           一般总是IN
Type            记录的类型
Value           记录值，如果是A记录，则value是一个IPv4地址
```

其中，常见的记录类型TYPE包括：


| 记录类型 | 含义 |
| --- | --- |
| SOA：（StartOf Authority,起始授权记录） | 一个区域解析库有且只能有一个SOA记录，而且必须放在第一条  |
| A记录（Address，主机记录） | 用于名称解析的重要记录，将特定的主机名映射到对应主机的IP地址上 |
| CNAME记录（Canonical Name，别名记录） | 用于 返回另一个域名，即当前查询的域名是另一个域名的跳转，主要用于域名的内部跳转，为服务器配置提供灵活性  |
| NS记录（Name Service，域名服务器记录）  | 用于返回保存下一级域名信息的服务器地址。该记录只能设置为域名，不能设置为IP地址 |
| PTR记录（Pointer，指针记录）  | PTR记录是A记录的逆向记录，又称做IP反查记录或指针记录，负责将IP反向解析为域名   |
| MX（Mall eXchanger，邮件记录） | 用于返回接收电子邮件的服务器地址 |
| IPv6主机记录（AAAA记录）  | 与A记录对应，用于将特定的主机名映射到一个主机的IPv6地址。    |


-------

#### 域名服务器


域名服务器用于响应DNS查询，由不同层级的域名服务器协同完成。下面讲解下如何将所有的域名资源记录存储到不同的域名服务器上。前面说过域名空间可以组织为一棵树，这里我们可以进一步将其划分为不重叠的区域（DNS zone），针对上图的域名空间，一种可能的域名划分如下图：

![](https://ws3.sinaimg.cn/large/006tNc79ly1ffweybz1snj31cu0lg0ug.jpg)


然后将每个区域的域名服务器（当然每个DNS zone内应该是由集群组成，包括master，和slave服务器用来提供数据备份、加快解析速度、保证服务可用性）关联起来，称这些域名服务器为该区域的**权威域名服务器(Authoritative Name Servers )**，它保存两类域名资源记录：

1. 该区域内所有域名的域名资源记录。
2. 父区域和子区域的域名服务器对应的域名资源记录（主要是NS记录）。

这样，所有的域名资源记录都保存在多个域名服务器中，并且所有的域名服务器也组成了一个层次的索引结构，便于域名解析。下面以一个简化的域名空间为例子，说明域名资源记录是如何保存在域名服务器中的，如下图：

![](https://ws4.sinaimg.cn/large/006tNc79ly1ffwf0iskulj30r80iqdh8.jpg)

图中域名空间划分为A, B, C, D, E, F, G七个DNS区域，每个DNS区域都有多个权威域名服务器（作为一个集群），这些域名服务器里面保存了许多域名解析记录。对于上图的DNS区域E来说，它的权威域名服务器里面保存的记录如图中表格所示。

仔细观察上图会发现区域A、B并没有父区域，他们之间并没有一条路径连在一起。这将导致一个很麻烦的问题，那就是区域A的权威域名服务器可能根本不知道区域B的存在。认识到这一点后，可能会想到的一个很自然的解决方案，就是在A中记录B域名服务器的地址，同时在B中记录A的，这样它们两个就联系起来了。但是考虑到有超过250个顶级域名，这样做并不是很恰当。

域名系统则采用了一种更加聪明的方法，那就是引入根域名服务器，它保存了所有顶级区域的权威域名服务器记录。现在通过根域名服务器，我们可以找到所有的顶级区域的权威域名服务器，然后就可以往下一级一级找下去了。根域名服务器（root   name  server）是DNS中最高级别的域名服务器，负责返回顶级域名的权威域名服务器的地址，全球13组根域名服务器以英文字母A到M依序命名，网域名称格式为“字母.root-servers.net”。其中有11个是以任播技术在全球多个地点设立镜像站。。更多关于根域名服务器的内容，可以参考：[根域名服务器-维基百科](https://zh.wikipedia.org/wiki/%E6%A0%B9%E5%9F%9F%E5%90%8D%E6%9C%8D%E5%8B%99%E5%99%A8)

现在为止，域名服务器和根域名服务器其实组成了一个树，树根为根域名服务器，下面每个节点都是一个区域的权威域名服务器，对于上图中各个DNS区域的权威域名服务器，它们组成了下面这棵树（事实上，一个权威域名服务器可能保存有多个DNS区域的记录，因此权威域名服务器之间的联系并不构成一棵树。为了容易理解，将其简化为一棵树）：

![](https://ws1.sinaimg.cn/large/006tNc79ly1ffwf456xoxj30d60g3dg6.jpg)


-------

#### 域名解析

Local DNS（本地域名服务器）：本地由网络服务提供商（ISP）分配的DNS（一般为两个），或自行设置的公共DNS。

当需要查询一个域名对应的IP地址时，在检查完本地hosts文件、操作系统DNS缓存后，会向本地域名服务器(LDNS)发起请求，如果该域名恰好在Local  DNS所辖属的域名区域（DNS zone）内，那么可以直接返回记录。

如果LDNS没有发现该域名的资源记录，就需要在整个域名空间搜索该域名。而整个域名空间的资源记录存储在一个分层的、树状联系的一系列域名服务器上，所以本地域名服务器首先要从根域名服务器开始往下搜索。这里有一个问题就是本地域名服务器如何找到根域名服务器在哪里呢？其实域名服务器启动的时候，就会加载一个配置文件，里面保存了根域名服务器的NS记录（因为根域名服务器地址一般非常稳定，不会轻易改变，并且数量很少，所以这样配置文件会很小）。找到根域名服务器之后，就可以一级一级地往下查找。

**假设访问www.google.com ，则请求过程大致如下：**

![](https://ws4.sinaimg.cn/large/006tNc79ly1ffwf5z5eykj30n20csab6.jpg)

1. 在浏览器中输入www.google.com域名，操作系统会先检查自己本地的hosts文件是否有这个网址映射关系，如果有，就先调用这个IP地址映射，完成域名解析。

2. 如果hosts里没有这个域名的映射，则查找本地DNS解析器缓存，是否有这个网址映射关系，如果有，直接返回，完成域名解析。

3. 如果hosts与本地操作系统缓存都没有相应的网址映射关系，则向本地设置的Local DNS服务器发起域名解析请求。LDNS收到查询后，如果要查询的域名，包含在本地配置区域资源中，则返回解析结果给客户机，完成域名解析，此解析具有权威性。

4. 如果要查询的域名，不由Local DNS服务器区域解析，但该服务器已缓存了此网址映射关系，且缓存未过期，则调用这个IP地址映射，完成域名解析，此解析不具有权威性。

5. 如果该域名不在Local DNS所辖属的域名区域（DNS zone）内，且没有有效缓存，则根据Local   DNS的设置（是否设置转发器）进行查询，如果未用转发模式，本地DNS就把请求发至根DNS，根DNS服务器收到请求后会判断这个域名(.com)是谁来授权管理，并会返回一个负责该顶级域名服务器的NS地址及其对应IP。本地DNS服务器收到IP信息后，将会请求.com域的这台服务器。这台负责.com域的服务器收到请求后，如果自己无法解析，便将.com域的下一级DNS服务器地址(qq.com)给的NS地址及其IP响应给Local   DNS。当Local DNS收到这个地址后，再向qq.com域服务器，重复上面查询，直至找到www.qq.com主机对应的记录。

6. 如果用的是转发模式，此DNS服务器就会把请求转发至上一级DNS服务器，由上一级服务器进行解析，上一级服务器如果不能解析，则请求根DNS或把转请求转至上上级，以此循环。不管是Local   DNS用的是转发，还是向根DNS请求，最终都能获得查询结果，然后再返回给最初查询的客户端。



-------

#### 缓存

由于绝大部分的DNS请求都集中在少部分的域名。因此可以将已经访问过域名的解析结果缓存在本地，下次访问的时候可以直接读取结果，不用再次重复DNS查询过程，客户端和域名服务器都节省了麻烦。

当然，这样做的一个前提是要缓存的解析结果不能频繁更改。绝大多数的域名解析确实是这样基本固定不变的。但是难免有一些“善变”的域名，他们可能会频繁更改自己的解析结果。为了使缓存机制适应这两类情况，在域名资源记录里面添加一个Time_to_live字段，表明这条记录最多可以缓存多久。对于那些解析基本不变的域名，给一个比较大的值，而那些需要经常变动解析的域名，则可以给定一个小的值。

同样，域名服务器会将那些查询过的域名资源记录缓存下来，再次收到来自客户端的请求时，只要缓存不过期，就可以直接返回缓存结果，不用再次向上查询。


-------

#### 端口号

 DNS协议使用udp/tcp的53端口提供服务，客户端向DNS服务发起请求时，使用udp的53端口；DNS服务器间（包括主从之间）进行区域传送的时候使用TCP的53端口。


-------

#### DNS服务器类型

1. 主DNS服务器：为客户端提供域名解析的主要区域，主DNS服务器宕机，会启用从DNS服务器提供服务。

2. 从DNS服务器：主服务器DNS长期无应答，从服务器也会停止提供服务。主从区域之间的同步采用周期性检查+通知的机制，从服务器周期性的检查主服务器上的记录情况，一旦发现修改就会同步，另外主服务器上如果有数据被修改了，会立即通知从服务器更新记录。

3. 缓存服务器：服务器本身不提供解析区域，只提供非权威应答。
4. 转发服务器：当DNS服务器的解析区域（包括缓存）中无法为当前的请求提供权威应答时，将请求转发至其它的DNS服务器，此时本地DNS服务器就是转发服务器。



-------


{% note success %}### DNS进阶原理
{% endnote %}

#### 区域数据库 记录类型详解

资源记录的定义格式：

```bash
name [TTL] IN RR_TYPE  value 
```

##### SOA：一个区域的第一条资源记录：

```bash
name: 当前区域的名字；例如”maxiecloud.com.”，或者“2.3.4.in-addr.arpa.”
value：有多部分组成
		(1) 当前区域的区域名称（也可以使用主DNS服务器名称）；
		(2) 当前区域管理员的邮箱地址；但地址中不能使用@符号，一般使用点号来替代；
		(3) (主从服务协调属性的定义以及否定答案的TTL)
```

实例：

```bash
maxiecloud.com. 	86400 	IN 	SOA	maxiecloud.com. 	admin.maxiecloudcom.  (
			2017010801; serial
			2H ; refresh
			10M ; retry
			1W	; expire
			1D	; negative answer ttl )
```

##### NS：域名服务记录，一个区域解析库可以有多个NS记录


```bash
name: 当前区域的区域名称
value：当前区域的某DNS服务器的名字，例如dns.maxiecloud.com.
```

实例：

```bash
name: 当前区域的区域名称
value：当前区域某邮件交换器的主机名；

注意：MX记录可以有多个；但每个记录的value之前应该有一个数字表示其优先级；
```

##### A：地址记录，FQDN --> IPv4


```bash
name：某FQDN，例如www.maxiecloud.com.
value：某个IPv4地址，例如1.2.3.4
```

实例：

```bash
www.maxiecloud.com.		IN 	A  1.1.1.1
www.maxiecloud.com.		IN 	A  1.1.1.2
bbs.maxiecloud.com.		IN 	A  1.1.1.1
```

##### AAAA：IPv6地址记录，FQDN --> IPv6


```bash
name：FQDN
value：IPv6
```

##### PTR：指针记录，反向解析，IP --> FQDN


```bash
name：IP地址，有特定格式，IP反过来写，而且加特定后缀；例如1.2.3.4的记录应该写为4.3.2.1.in-addr.arpa.
value：FQDN
```

实例：

```bash
4.3.2.1.in-addr.arpa.  	IN  PTR  www.maxiecloud.com.
```

##### CNAME：别名记录


```bash
name：FQDN格式的别名；
value：FQDN格式的正式名字；
```

实例：

```bash
web.maxiecloud.com.  	IN  	CNAME  www.maxiecloud.com.
```

**注意：**
(1) TTL可以从全局继承
(2) @可以表示当前区域的名称 --> maxiecloud.com 
(3) 相邻的两条记录其name相同时，后面的可省略
(4) 对于正向区域来说，各MX，NS等类型的记录的value为FQDN，此FQDN应该有一个A记录


-------

{% note info %}### Bind的安装和基础配置
{% endnote %}

前面我们介绍了DNS的一些基础概念和进阶的知识，但是`DNS`是一种模型，需要使用软件去实现。

Bind(Berkeley Internet Name Domain)就是伴随`DNS`出生的软件。

#### Bind程序包


```bash
bind.x86_64             Bind程序的主程序包，提供的dns server程序、以及几个常用的测试程序
bind-libs.x86_64        被bind和bind-utils包中的程序共同用到的库文件
bind-utils.x86_64       bind客户端程序集，例如dig，host，nslookup
bind-chroot.x86_64      选装，让named运行于jail模式下（'更安全'）
```

#### Bind配置文件

主配置文件： `/etc/named.conf`

其他配置文件
```bash
/etc/named.iscdlv.key 
/etc/named.rfc1912.zones #定义区域的文件
/etc/named.root.key 
```

解析库文件：`/var/named/`目录下；一般名字为：`ZONE_NAME.zone`

**注意：**
(1) 一台DNS服务器可同时为多个区域提供解析；
(2) 必须要有根区域解析库文件：named.ca 
(3) 还应该有两个区域解析库文件：localhost和127.0.0.1的正反向解析库


#### 配置一个正向解析区域

##### 修改主配置文件 /etc/named.conf

把主配置文件中 `options` 中的监听端口和dnssec功能修改了：

```bash
options {
        listen-on port 53 { 127.0.0.1;172.16.1.51; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { any; };
    
        recursion yes;
        
        dnssec-enable no;
        dnssec-validation no;
```

主要修改的是：
1. listen-on port 53 { 127.0.0.1;172.16.1.51; };  在127.0.0.1后添加一条监听本机网卡IP地址的信息
2. allow-query     { any; };   把这里的允许查询的范围改为`any`
3.  dnssec-enable no;   dnssec-validation no;  这两个防火墙功能设置为 `no`，也就是关闭其功能


##### 定义一个zone


```
~]# vim /etc/named.rfs1912.conf     #在此文件的最后一行添加如下信息
	zone "maxiecloud.com" IN {
		type master;
		file "maxiecloud.zone";
	}
```

##### 创建区域解析库文件

```
[root@localhost named]# cat named.maxie
$TTL 600M
maxiecloud.com. IN	SOA	maxiecloud.com	nsadim.maxiecloud.com. (
				2017052301	; serial
					1H	; refresh
					5M	; retry
					1W	; expire
					6H )	; minimum
        IN	NS	dns1.maxie.com.
        IN	NS	dns2.maxie.com.
dns1.maxiecloud.com. IN	A	172.16.1.51
dns2.maxiecloud.com. IN	A	172.16.1.52
www.maxiecloud.com.  IN A       172.16.1.12
web	IN	CNAME	www
[root@localhost named]# chgrp named /var/named/maxiecloud.zone
[root@localhost named]# chmod o= /var/named/maxiecloud.zone
```

##### 检查、启动并测试DNS服务


```
[root@localhost named]# named-checkcon          #检查主配置文件语法
[root@localhost named]# named-checkzone "maxiecloud.com" /var/named/maxiecloud.zone         #检查maxiecloud.com zone所对应的解析库文件
```

##### 解析域名


```
[root@localhost ~]# host -t A www.maxiecloud.com  172.16.1.51
Using domain server:
Name: 172.16.1.51
Address: 172.16.1.51#53
Aliases:

www.maxiecloud.com has address 172.16.1.12

[root@localhost ~]# host -t NS maxiecloud.com  172.16.1.51
Using domain server:
Name: 172.16.1.51
Address: 172.16.1.51#53
Aliases:

maxiecloud.com name server dns1.maxiecloud.com.
maxiecloud.com name server dns2.maxiecloud.com.
```

#### 配置一个反向解析区域

##### 定义一个zone


```
[root@localhost ~]# vim /etc/named.rfs1912.zones 
zone "16.172.in-addr.arpa" IN {
	type master
	file "172.16.zone"
}
```

##### 创建区域反向解析库文件


```
[root@localhost ~]# cd /var/named 
[root@localhost ~]# vim 172.16.zone   #这个文件中的@：表示/etc/named.rfs1912.zones中 zone的名字，也就是"16.172.in-addr.arpa"这个名字
$TTL 9527
$ORIGIN 16.172.in-addr.arpa.	       #这一步，在出现transfer failed的时候可以尝试设置，这可能是因为同一个网内出现了两个一样的反向解析服务器
@	IN	SOA	maxiecloud.com.	nsadmin.maxiecloud.com. (
		2017052301
		3H
		20M
		1W
		1D )
	IN	NS	dns1.maxiecloud.com.
	IN	NS	dns2.maxiecloud.com.
51.1	IN	PTR	dns1.maxiecloud.com.
52.1	IN	PTR	dns2.maxiecloud.com.
12.1	IN	PTR	www.maxiecloud.com.

这里如果后面自己补上了全部的地址，就必须在最后加上"."
如果不补全，则无需加"."
```

##### 检查、启动并测试DNS服务


```
[root@localhost named]# named-checkcon          #检查主配置文件语法
[root@localhost named]# named-checkzone "16.172.in-addr.arpa" /var/named/maxiecloud.zone         #检查maxiecloud.com zone所对应的解析库文件
```

##### 测试


```
[root@localhost named]# rndc reload 
server reload successful

[root@localhost named]# dig -t axfr 16.172.in-addr.arpa @172.16.1.51

; <<>> DiG 9.9.4-RedHat-9.9.4-29.el7 <<>> -t axfr 16.172.in-addr.arpa @172.16.1.51
;; global options: +cmd
16.172.in-addr.arpa.	9527	IN	SOA	maxiecloud.com. nsadmin.maxiecloud.com. 2017052301 10800 1200 604800 86400
16.172.in-addr.arpa.	9527	IN	NS	dns1.maxiecloud.com.
16.172.in-addr.arpa.	9527	IN	NS	dns2.maxiecloud.com.
12.1.16.172.in-addr.arpa. 9527	IN	PTR	www.maxiecloud.com.
51.1.16.172.in-addr.arpa. 9527	IN	PTR	dns1.maxiecloud.com.
52.1.16.172.in-addr.arpa. 9527	IN	PTR	dns2.maxiecloud.com.
16.172.in-addr.arpa.	9527	IN	SOA	maxiecloud.com. nsadmin.maxiecloud.com. 2017052301 10800 1200 604800 86400
;; Query time: 0 msec
;; SERVER: 172.16.1.51#53(172.16.1.51)
;; WHEN: 三 5月 24 05:42:04 CST 2017
;; XFR size: 7 records (messages 1, bytes 226)


[root@localhost named]# dig -x 172.16.1.12 @172.16.1.51

; <<>> DiG 9.9.4-RedHat-9.9.4-29.el7 <<>> -x 172.16.1.12 @172.16.1.51
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 59255
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;12.1.16.172.in-addr.arpa.	IN	PTR

;; ANSWER SECTION:
12.1.16.172.in-addr.arpa. 9527	IN	PTR	www.maxiecloud.com.

;; AUTHORITY SECTION:
16.172.in-addr.arpa.	9527	IN	NS	dns2.maxiecloud.com.
16.172.in-addr.arpa.	9527	IN	NS	dns1.maxiecloud.com.

;; ADDITIONAL SECTION:
dns1.maxiecloud.com.	600	IN	A	172.16.1.51
dns2.maxiecloud.com.	600	IN	A	172.16.1.52

;; Query time: 0 msec
;; SERVER: 172.16.1.51#53(172.16.1.51)
;; WHEN: 三 5月 24 05:42:33 CST 2017
;; MSG SIZE  rcvd: 155
```
-------

{% note warning %}### 主从配置和子域授权
{% endnote %}

#### 主从配置

在两台或多台Linux主机上进行实验或操作时，最先要做的是时间同步

```bash
$ ntpdate NTP_SERVER
```

如果时间不同步，后面出现的问题就不是几分钟能解决的了。

在上面的实验中，我们已经配置好了一台具有DNS解析功能的服务器了，我们就把那一台当做主服务器，下面我们开始配置从服务器：

##### 从节点的配置：安装bind以及修改配置文件


```bash
$ yum install -y bind
$ vim /etc/named.conf
options {
	//listen-on port 53 { 127.0.0.1; }     #注释掉这段信息或者添加本地IP地址也可以
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { any; };	     #修改为any

	dnssec-enable no;	             #设置为no
	dnssec-validation no;                #设置为no
```

##### 定义一个从区域


```
[root@localhost ~]# vim /etc/named.rfc1912.zones
zone "maxiecloud.com" IN {
        type slave;
        file "slaves/maxiecloud.zone";
        masters { 172.16.1.51; };
};

zone "16.172.in-addr.arpa" IN {
        type slave;
        file "slaves/172.16.zone";
        masters { 172.16.1.51; };
};
[root@localhost ~]# named-checkconf
```

##### 开启服务并测试


```
[root@localhost ~]# systemctl start named.service
[root@localhost ~]# dig -t A www.maxiecloud.com @172.16.1.52

; <<>> DiG 9.9.4-RedHat-9.9.4-29.el7 <<>> -t A www.maxiecloud.com @172.16.1.52
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 50052
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.maxiecloud.com.		IN	A

;; ANSWER SECTION:
www.maxiecloud.com.	600	IN	A	172.16.1.12

;; AUTHORITY SECTION:
maxiecloud.com.		600	IN	NS	dns1.maxiecloud.com.
maxiecloud.com.		600	IN	NS	dns2.maxiecloud.com.

;; ADDITIONAL SECTION:
dns1.maxiecloud.com.	600	IN	A	172.16.1.51
dns2.maxiecloud.com.	600	IN	A	172.16.1.52

;; Query time: 0 msec
;; SERVER: 172.16.1.52#53(172.16.1.52)
;; WHEN: 三 5月 24 05:56:29 CST 2017
;; MSG SIZE  rcvd: 133

[root@localhost ~]# dig -t NS maxiecloud.com @172.16.1.52

; <<>> DiG 9.9.4-RedHat-9.9.4-29.el7 <<>> -t NS maxiecloud.com @172.16.1.52
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41932
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;maxiecloud.com.			IN	NS

;; ANSWER SECTION:
maxiecloud.com.		600	IN	NS	dns2.maxiecloud.com.
maxiecloud.com.		600	IN	NS	dns1.maxiecloud.com.

;; ADDITIONAL SECTION:
dns1.maxiecloud.com.	600	IN	A	172.16.1.51
dns2.maxiecloud.com.	600	IN	A	172.16.1.52

;; Query time: 0 msec
;; SERVER: 172.16.1.52#53(172.16.1.52)
;; WHEN: 三 5月 24 05:56:37 CST 2017
;; MSG SIZE  rcvd: 113
```


-------


#### 子域授权

现在我们开始配置子域授权，我们在主DNS服务器上进行授权

在`maxiecloud.zone`中添加如下信息：


```bash
ops.maxiecloud.com. IN          NS dns1.ops.maxiecloud.com. 
ops.maxiecloud.com. IN          NS dns2.ops.maxiecloud.com.
dns1.ops.maxiecloud.com. IN          A  172.16.1.53         #子域DNS服务器的IP地址
dns2.ops.maxiecloud.com. IN          A  172.16.1.54         #子域DNS服务器的IP地址
```

##### 在子域DNS服务器上配置

安装bind并修改配置文件信息：

```bash
$ yum install -y bind
$ vim /etc/named.conf
options {
	//listen-on port 53 { 127.0.0.1; }     #注释掉这段信息或者添加本地IP地址也可以
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { any; };	     #修改为any

	dnssec-enable no;	             #设置为no
	dnssec-validation no;                #设置为no
```

在/etc/named.rfs1912.zones中添加子域的信息：

```bash
$ vim /etc/named.rfs1912.zones
zone "ops.maxiecloud.com" IN {
    type master;
    file "ops.maxiecloud.zone";
};
```

定义子域解析库：

```bash
$ vim /var/named/ops.maxiecloud.zone
$TTL 600
@   IN  SOA     maxiecloud.com.     nsadmin.maxiecloud.com. (
        2017052301
        1H
        2M
        3D
        1D )
        IN  NS  dns1.ops.maxiecloud.com.
        IN  NS  dns2.ops.maxiecloud.com.
dns1    IN  A   172.16.1.53
dns2    IN  A   172.16.1.54
www     IN  A   172.16.1.12
```

测试：

```
[root@localhost named]# service named start
Starting named:                                            [  OK  ]
 
通过本机解析本域主机名
[root@localhost named]# host -t A www.ops.maxiecloud.com 172.16.1.53
Using domain server:
Name: 172.16.1.53
Address: 172.16.1.53#53
Aliases: 
www.ops.maxiecloud.com has address 172.16.1.53
 
通过父域DNS解析本域下的主机名
 
[root@localhost named]# host -t A www.ops.maxiecloud.com 172.16.1.54
Using domain server:
Name: 172.16.1.54
Address: 172.16.1.54#53
Aliases: 
 
www.ops.maxiecloud.com has address 172.16.1.54
 
通过本机DNS解析父域中的主机名
[root@localhost named]# host -t A www.maxiecloud.com 172.16.1.53
;; connection timed out; trying next origin
Using domain server:
Name: 172.16.1.53
Address: 172.16.1.53#53
Aliases: 
 
Host www.maxiecloud.com not found: 3(NXDOMAIN)
```

但是我们可能会发现一个问题，如果我需要解析父域中的主机名，只能通过递归到根域去解析，这是非常不便的，所以我们要设置转发器。

##### 设置区域转发

区域转发：仅转发对特定区域的解析请求


```
[root@localhost named]# vim /etc/named.rfc1912.zones
zone "maxiecloud.com" IN {	         #这里的ZONE_NAME是区域的名称，而非子域名称；所以这里应该是maxiecloud.com
				type forward;
				forward { only; };
				forwarders { 172.16.1.51; };
			};
```

重载、测试：

```bash
[root@localhost named]# rndc reload
[root@localhost named]# dig -t A www.maxiecloud.com @172.16.1.53
```


-------

{% note danger %}### BIND视图实现smart DNS
{% endnote %}

由于中国的运营商之间的带宽是非常低，但是无论我们是哪个运营商的宽带，访问那些大型电商站点都是非常的快，那是因为在dns服务器中定义了来自哪些IP的请求解析成哪些地址，这就是视图的功能。

#### 配置视图

初始化设置与上面的实验操作无异：
1. 安装bind
2. 修改主配置文件的监听IP和allow-query、dnssec的配置


初始化完毕之后，我们开始配置视图：

##### 定义acl

```
[root@localhost named]# vim /etc/named.conf     #在此文件中 options的选项之前添加如下信息
acl localnet {
	192.168.10.0/24;
};

acl mynet {
	172.16.0.0/16;
	127.0.0.0/8
};
```

这里需要注意的是，因为主配置文件中有一段 zone的配置信息，我们需要把其剪切出来，粘贴到/etc/named.rfc1912.zones的view local视图中：

![](https://ws1.sinaimg.cn/large/006tNbRwly1ffwja1t1i3g30jg0eihe6.gif)

配置/etc/named.rfc1912.zones文件：


```
[root@localhost named]# vim /etc/named.rfc1912.zones
view local {
	match-clients { localnet; };

zone "." IN {
        type hint;
        file "named.ca";
};

zone "localhost.localdomain" IN {
	type master;
	file "named.localhost";
	allow-update { none; };
};

zone "localhost" IN {
	type master;
	file "named.localhost";
	allow-update { none; };
};

zone "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa" IN {
	type master;
	file "named.loopback";
	allow-update { none; };
};

zone "1.0.0.127.in-addr.arpa" IN {
	type master;
	file "named.loopback";
	allow-update { none; };
};

zone "0.in-addr.arpa" IN {
	type master;
	file "named.empty";
	allow-update { none; };
};

zone "maxiecloud.com" IN {
	type master;
	file "maxiecloud.zone/localnet";
};
};

view my {
	match-clients { mynet; };

zone "maxiecloud.com" IN {
	type master;
	file "maxiecloud.zone/mynet";
};
};

view ex {
	match-clients { any; };

zone "maxiecloud.com" IN {
	type master;
	file "maxiecloud.zone/ex";
};
};
```

创建maxiecloud.zone目录以及文件：

```
[root@localhost named]# mkdir /var/named/maxiecloud.zone
[root@localhost named]# vim localnet
$TTL 610
@	IN 		SOA  	maxiecloud.com.		nsadmin.maxiecloud.com. (
			2017052301
			1H
			2M
			1D
			2D )
@	IN 		NS 		dns1.maxiecloud.com.
dns1 	IN 	A 		172.16.1.53
www 	IN 	A 		1.1.1.1


[root@localhost named]# vim mynet 
$TTL 620
@	IN 		SOA  	maxiecloud.com.		nsadmin.maxiecloud.com. (
			2017052301
			1H
			2M
			1D
			2D )
@	IN 		NS 		dns1.maxiecloud.com.
dns1 	IN 	A 		172.16.1.53
www 	IN 	A 		2.1.1.1

[root@localhost named]# vim ex 
$TTL 630
@	IN 		SOA  	maxiecloud.com.		nsadmin.maxiecloud.com. (
			2017052301
			1H
			2M
			1D
			2D )
@	IN 		NS 		dns1.maxiecloud.com.
dns1 	IN 	A 		172.16.1.53
www 	IN 	A 		3.1.1.1
```

测试验证：

![view1](https://ws3.sinaimg.cn/large/006tNc79ly1ffwjgtpxtlj30ma0hpn48.jpg)

![view2](https://ws3.sinaimg.cn/large/006tNc79ly1ffwjgtg8yqj30ma0hpgsn.jpg)

![view3](https://ws4.sinaimg.cn/large/006tNc79ly1ffwjgt59yoj30iy0ezdlv.jpg)
    


-------

{% note primary %}### 自建根域 + HTTPD服务 访问
{% endnote %}

自建根域+HTTPD服务教程：

**bilibili(视频源)：**

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=10907767&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>


**Youtube(视频源)： 请科学上网后观看**

<iframe width="560" height="315" src="https://www.youtube.com/embed/K-kFhmsoSIA" frameborder="0" allowfullscreen></iframe>

-------

{% note success %}### CentOS6编译安装httpd-2.4
{% endnote %}

**bilibili(视频源)：**


<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=10908178&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>

-------

{% note success %}### 自建CA+https配置
{% endnote %}

**bilibili(视频源)：**

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=10916246&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>

-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=758649&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)






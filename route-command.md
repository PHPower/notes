---
title: route命令详解
date: 2017-05-04 19:47:48
tags: [linux,command,route]
categories: linux网络配置
---

<blockquote class="blockquote-center">Linux系统的route命令用于显示和操作IP路由表

要实现两个不同的子网之间的通信，需要一台连接两个网络的路由器，或者同时位于两个网络的网关来实现。
</blockquote>

**在Linux系统中，设置路由通常是为了解决以下问题：**

该Linux系统在一个局域网中，局域网中有一个网关，能够让机器访问Internet，那么就需要将这台机器的IP地址设置为Linux机器的默认路由。

要注意的是，直接在命令行执行route命令来添加路由，不会永久保存，当网卡重启或者机器重启之后，该路由就失效了。

可以在`/etc/sysconfig/network-scripts/`目录下创建`route-IFACE`类似的配置文件。

其中`IFACE`的名字不是很重要，起一个能够辨识其功能的名字即可。

<!-- more -->

{% note primary %}### 路由的分类
{% endnote %}

**主机路由**

```bash
针对特定的地址，非常精细

route add -host 2.2.2.2 gw 1.1.1.1 dev eth0
这条路由只指向2.2.2.2这个主机，不包括在其网络内的其他主机
```

**网络路由**

```bash
指明网段的路由，网络路由针对的是一个网段的路由，比主机路由精细度要低一些

route add -net 2.2.2.0/24 gw 1.1.1.1 dev eth0
这条路由指向的是2.2.2.0/24这个网络内的所有IP。
```

**默认路由**

```bash
默认路由就是0.0.0.0/0，意思是实在没有其他路由了，就走这个路由了。
```

在路由表中的优先级：
**精度越高，优先级越高**


-------

{% note success %}### 路由表构成
{% endnote %}

1. 目标网络:
    网络ID和子网掩码组成（网络路由）
    `192.168.0.0/24`
    或者
    目标是一个IP地址，`192,168,1.100`（主机路由）
    
2. 接口
    数据包到达目标网络从路由器的哪个接口出来，就是这个接口。
    
3. 网关
    下一个路由器的临近接口的IP地址（下一跳的地址），与出口IP地址在同一个网段。


-------

{% note info %}### route命令详解
{% endnote %}

#### 命令语法格式

`route [-f] [-p] [Command [Destination] [mask Netmask] [Gateway] [metric Metric]] [if Interface]]`

#### 命令功能

`route`命令是用于操作基于内核IP路由表，它的主要作用是创建一个静态路由由让指定一个主机或者一个网络通过一个网络接口，如`eth0`。

当使用`add`或者`del`参数时，路由表被修改，如果没有参数，则显示路由表当前的内容。

#### 命令参数


```bash
-A          设置地址类型
-C          打印将Linux核心的路由缓存 
-v          详细信息模式
-n          不执行DNS反向查找，直接显示数字形式的IP地址
-e          netstat格式显示路由表
-net        到一个网络的路由表 
-host       到一个主机的路由表

Add：增加指定的路由记录
Del：删除指定的路由记录
Target：目的网络或目的主机
gw：设置默认网关
mss：设置TCP的最大区块长度（MSS），单位MB
window：指定通过路由表的TCP连接的TCP窗口大小
dev：路由记录所表示的网络接口
```

#### 设置永久生效路由表

在`/etc/sysconfig/network-scripts/`目录下创建`route-IFACE`配置文件


```bash
[root@maxie ~]# vim /etc/sysconfig/network-scripts/route-eth0
10.0.0.0/8 via 10.170.191.247 dev eth0
100.64.0.0/10 via 10.170.191.247 dev eth0
172.16.0.0/12 via 10.170.191.247 dev eth0
```

#### 实例

**1、显示当前路由**


```bash
[root@maxie ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         123.56.103.247  0.0.0.0         UG    0      0        0 eth1
10.0.0.0        10.170.191.247  255.0.0.0       UG    0      0        0 eth0
10.170.184.0    0.0.0.0         255.255.248.0   U     0      0        0 eth0
100.64.0.0      10.170.191.247  255.192.0.0     UG    0      0        0 eth0
123.56.100.0    0.0.0.0         255.255.252.0   U     0      0        0 eth1
169.254.0.0     0.0.0.0         255.255.0.0     U     1002   0        0 eth0
169.254.0.0     0.0.0.0         255.255.0.0     U     1003   0        0 eth1
172.16.0.0      10.170.191.247  255.240.0.0     UG    0      0        0 eth0
```

其中：

Destination：目标网络

Gateway：下一跳地址

Genmask：子网掩码

Flags：路由标志

```bahs
U：表示此路由为启动状态
H：表示此网关为一主机
G：表示此网关为一路由器
R：使用动态路由重新初始化的路由
!：表示此路由当前为关闭状态
```

2、添加一条路由

```bash
[root@maxie ~]# route add -net 192.168.1.0/24 gw 123.56.100.148
```

3、屏蔽一条路由

```bash
[root@maxie ~]# route add -net 192.168.1.0/24 reject
[root@maxie ~]# route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         gateway         0.0.0.0         UG    0      0        0 eth1
10.0.0.0        10.170.191.247  255.0.0.0       UG    0      0        0 eth0
10.170.184.0    0.0.0.0         255.255.248.0   U     0      0        0 eth0
100.64.0.0      10.170.191.247  255.192.0.0     UG    0      0        0 eth0
123.56.100.0    0.0.0.0         255.255.252.0   U     0      0        0 eth1
link-local      0.0.0.0         255.255.0.0     U     1002   0        0 eth0
link-local      0.0.0.0         255.255.0.0     U     1003   0        0 eth1
172.16.0.0      10.170.191.247  255.240.0.0     UG    0      0        0 eth0
192.168.1.0     -               255.255.255.0   !     0      -        0 -
192.168.1.0     maxie           255.255.255.0   UG    0      0        0 eth1
```

4、删除一条路由记录

```bash
[root@maxie ~]# route del -net 192.168.1.0/24
[root@maxie ~]# route del -net 192.168.1.0/24 reject
```


-------

{% note danger %}### 实验：2台Linux主机通过3台路由器相同通信
{% endnote %}

现有2台Linux主机，以及3台路由器，要实现让两台Linux主机经过3台路由器后可以互相通信的功能。

#### 第一步，根据需求制作网络拓扑图

![](http://ww2.sinaimg.cn/large/006tNc79ly1ff9msnpcm0j315k0kc3zi.jpg)

#### 第二步，配置两台Linux主机的IP以及关闭防火墙和其他环境配置


这里Linux1和Linux2作为客户端（client）
Route1、2、3作为路由
	
**Linux1的配置：**

```	
1、配置网卡信息
$ vim /etc/sysconfig/network-scripts/ifcfg-ens33
	IPADDR=172.16.0.2
	PREFIX=16
	GATEWAY=172.16.0.3
	
2、清空并关闭防火墙，设置开机不自启
$ iptables -F
$ service iptables stop 或者 systemctl stop firewalld.service
$ chkconfig iptables off 或者 systemctl disable firewalld.service
	
3、route -n 查看路由表信息
	
4、重启网络
$ service network restart 或者 systemctl restart network 
```

Linux2因为硬件软件配置与1相同，所以除IP地址不同外，其他设置都相同1的网卡信息

所以Linux2的IP地址配置如下

```
$ vim /etc/sysconfig/network-scripts/ifcfg-eth0
	IPADDR=10.0.0.2
	PREFIX=8
	GATEWAY=10.0.0.3
```

#### 第四步，配置router的信息以及环境

**route1：与Linux1机器、route2直连**

eth0网卡连接Linux1
eth1网卡连接route2

配置信息如下：

```bash
1、配置网卡信息
vim /etc/sysconfig/network-scripts/ifcfg-eth0
	IPADDR=172.16.0.3
	PREFIX=16
	GATEWAY=172.16.0.3
	
vim /etc/sysconfig/network-scripts/ifcfg-eth1
	IPADDR=192.168.1.3
	PREFIX=24
	
	
2、关闭防火墙
iptables -F
service iptables stop
chkconfig iptables off
	
	
3、重启网卡
service network restart
```

**route2：与route1和route3直连**

eth0连接Route1
eth1连接Route3

配置信息如下：

```bash
1、配置网卡信息
vim /etc/sysconfig/network-scripts/ifcfg-eth0
	IPADDR=192.168.1.4
	PREFIX=24
	
vim /etc/sysconfig/network-scripts/ifcfg-eth1
	IPADDR=192.168.2.4
	PREFIX=24
	
2、关闭防火墙
iptables -F
service iptables stop
chkconfig iptables off
	
3、重启网卡
service network restart
```

**route3：与linux2机器、route3直连**

eth0连接Route3
eth1连接Linux2

配置信息如下：

```bash
1、配置网卡信息
vim /etc/sysconfig/network-scripts/ifcfg-eth0
	IPADDR=192.168.2.2
	PREFIX=24
	
vim /etc/sysconfig/network-scripts/ifcfg-eth1
	IPADDR=10.0.0.3
	PREFIX=8
	GATEWAY=10.0.0.3	
	
2、关闭防火墙
iptables -F
service iptables stop
chkconfig iptables off
	
	
3、重启网卡
service network restart
```

#### 配置各router的路由表信息


```bash
Route1：
	
不做路由的情况下可以访问172.16.0.0/16以及192.168.1.0/24这两个网络内的IP地址
	
所以我们需要做两个网络的路由，也就是192.168.2.0/24和10.0.0.0/8这两个网络的路由
	
所以Route1的路由表就是：
	
	192.168.2.0/24 gw 192.168.1.4 dev eth1
	10.0.0.0/8 gw 192.168.1.4 dev eth1
	
配置之前需要开启路由转发功能：
	cat /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_forward
	
使用route命令进行配置路由表：
	route add -net 192.168.2.0/24 gw 192.168.1.4 dev eth1
	route add -net 10.0.0.0/8 gw 192.168.1.4 dev eth1
	
查看是否配置成功：
	route -n
	
测试ping：由于route2没有配置路由转发功能，目前我们只能ping通route2的192.168.2.4这张网卡的地址
	
	ping 192.168.2.4
	
	
---------------------------------------
	
Route2：
	
不做路由的情况下可以访问192.168.2.0/24以及192.168.1.0/24这两个网络内的IP地址
	
所以我们需要做两个网络的路由，也就是172.16.0.0/16和10.0.0.0/8这两个网络的路由
	
所以Route2的路由表就是：
	
	172.16.0.0/16 gw 192.168.1.4 dev eth0
	10.0.0.0/8 gw 192.168.2.4 dev eth1
	
配置之前需要开启路由转发功能：
	cat /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_forward
	
使用route命令进行配置路由表：
	route add -net 172.16.0.0/16 gw 192.168.1.3 dev eth0
	route add -net 10.0.0.0/8 gw 192.168.2.2 dev eth1
	
查看是否配置成功：
	route -n
	
测试ping：由于route3没有配置路由转发功能，目前我们只能ping通route3的10.0.0.3这张网卡的地址和route1的两张网卡地址以及Linux1的地址
	
	ping 10.0.0.3
	ping 172.16.0.3
	ping 172.16.0.2
	
	
-----------------------------------------------
	
	
	
Route3：
	
不做路由的情况下可以访问10.0.0.0/8以及192.168.2.0/24这两个网络内的IP地址
	
所以我们需要做两个网络的路由，也就是192.168.1.0/24和172.16.0.0/16这两个网络的路由
	

所以Route3的路由表就是：
	
	192.168.1.0/24 gw 192.168.2.4 dev eth0
	172.16.0.0/16 gw 192.168.2.4 dev eth0
	
配置之前需要开启路由转发功能：
	cat /proc/sys/net/ipv4/ip_forward
	echo 1 > /proc/sys/net/ipv4/ip_forward
	
使用route命令进行配置路由表：
	route add -net 192.168.1.0/24 gw 192.168.2.4 dev eth0
	route add -net 172.16.0.0/16 gw 192.168.2.4 dev eth0
	
查看是否配置成功：
    route -n
	
测试ping：现在，Linux1到Linux2的所有路由都已配置完毕，所以我们可以ping通拓扑图内的所有IP地址
```

		
-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=29550185&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



---
title: Linux网络接口配置-"Bonding"
date: 2017-05-06 11:05:57
tags: [linux,network,bonding]
categories: linux网络配置
---

<blockquote class="blockquote-center">"Bonding"就是将多块网卡绑定同一IP地址对外提供服务，可以实现高可用/负载均衡。

在企业以及电信Linux服务器环境上，网络配置都会使用Bonding技术做网口硬件层面的冗余，防止单个网络应用的单点故障。
</blockquote>

本文将介绍Linux下的`Bonding`技术，利用这种技术可以将多块网卡接口通过绑定虚拟成一块网卡，在用户看来这个聚合起来的设备好像是一个单独的以太网接口设备，通俗点讲就是多块网卡具有相同的IP地址而并行连接聚合成一个逻辑链路工作。

<!-- more -->

{% note primary %}### Bond的几种工作模式
{% endnote %}

#### 模式1：mode=0，（balance-rr）Round-robin（轮循策略）

**特点：**
传输数据包顺序是依次传输（即：第一个包走eth0，下一包就走eth1...，一直这样循环下去，直到最后一个传输完毕），此模式提供负载平衡和容错能力；但是我们知道如果一个连接或者会话的数据包从不同的接口发出的话，中途再经过不同的链路，在客户端很有可能会出现数据包无序到达的问题，而无序到达的数据包需要重新要求被发送，这样网络的吞吐量就会下降。

#### 模式2：mode=1，即：（active-backup）Active-backup（主备策略）

**特点：**
只有一个设备（slave）处于活动状态，当一个宕掉另一个马上由备份转为主设备。mac地址是外部可见的，从外面看来，`bond`的MAC地址是唯一的，以避免交换机（switch）发生混乱。
此模式只提供了容错能力；
由此可见此模式的优点是可以提供高可用的网络连接，但是它的资源利用率较低，只有一个接口处于工作状态，在有N个网络接口的情况下，资源利用率仅为1/N。

#### 模式3：mode=2，即：（balance-xor）XOR（平衡策略）

**特点：**
基于指定的传输HASH策略传输数据包。缺省的策略是：（源MAC地址 XOR 目标MAC地址） % slave数量，其他的传输策略可以通过`xmit_hash_policy`选项指定，此模式提供负载平衡和容错能力。

#### 模式4：mode=3，即：broadcast 广播策略

**特点：**
在每个slave接口上传输每个数据包，此模式提供了容错能力

#### 模式5：mode=4，即：（802.3ad）IEEE 802.3adDynamic link aggregation（IEEE 802.3ad 动态链接聚合）

**特点：**
创建一个聚合组，它们共享同样的速率和双工设定。
根据`802.3ad`规范将多个slave工作在同一个激活的聚合体下。

外出流量的slave选举是基于传输hash策略，该策略可以通过`xmit_hash_policy`选项从缺省的XOR策略改变到其他策略。需要注意的是，并不是所有的传输策略都是`802.3ad`适应的，尤其考虑到在`802.3ad`标准提及的包乱序问题，不同的实现可能会有不同的适应性。

**必要条件：**

条件1：`ethtool`支持获取每个slave的速率和双工设定 

条件2：switch(交换机)支持`IEEE 802.3ad Dynamic link aggregation` 

条件3：大多数switch(交换机)需要经过特定配置才能支持`802.3ad`模式


#### 模式6：mode=5，即：（balance-tlb）Adaptive transmit load balancing（适配器传输负载均衡）

**特点：**
不需要任何的特别交换机（switch）支持的通道bonding。在每个slave上根据当前的负载（根据速度计算）分配外出流量。如果正在接受数据的slave出故障了，另一个slave接管失败的slave的MAC地址。

该模式的必要条件：ethtool支持获取每个slave的速率。

#### 模式7：mode=6，即：（balance-alb）Adaptive load balancing（适配器适应性负载均衡）

**特点：**
该模式包含了balance-tlb模式，同时加上针对IPV4流量的接收负载均衡(receive load balance, rlb)，而且不需要任何switch(交换机)的支持。接收负载均衡是通过ARP协商实现的。bonding驱动截获本机发送的ARP应答，并把源硬件地址改写为bond中某个slave的唯一硬件地址，从而使得不同的对端使用不同的硬件地址进行通信。


-------


{% note success %}### 常用模式详解
{% endnote %}

Linux Bond有两种经典的模式：主备（mode=1）、负载均衡（mode=0）


下面，我们将对这两个模式进行详细的介绍以及在CentOS6和7上进行试验。

#### 原理图

**主备模式：**

![](http://ww4.sinaimg.cn/large/006tNc79ly1ffbj1odk5bj30f20dvglz.jpg)

**负载均衡模式：**

![](http://ww3.sinaimg.cn/large/006tNc79ly1ffbj1oj6s4j30f20dvwev.jpg)

-------

#### 主备模式、负载均衡模式详解

**1. 我们先看主备模式**

主备模式下，Linux Bonding实现会将Bond的两个slave网口的MAC地址改为Bond的MAC地址，而Bond的MAC地址是Bond创建启动后，主用slave网口的MAC地址。

当住用网口故障后，Bond会切换到备用网口，切换过程中，上层的应用是无感知不受影响的，因为Bond在驱动层，会接管上层应用的数据包，缓存起来等备用网卡起来后再通过备用网卡发送出去。当然，前提是切换时间很短，否则缓冲区是会溢出的，溢出后就开始丢包了。具体的时间值本人还没有验证过。


**2. 再看负载均衡模式**

负载均衡模式下，Linux Bonding实现可以保持两个slave网口的MAC地址不变，Bond的MAC地址是其中一个网卡的，Bond MAC地址的选择是根据Bond自己实现的一个算法来的，具体如何选择还没有研究。

当然，这里要重点说明的是，Bond负载均衡模式下，要求交换机做配置，是的两个slave网口能够互通，否则的话，丢包会很厉害，基本没法使用。这个是因为Bond的负载均衡模式算法，会将包在两个网口之间传输以达到负载均衡。
由于负载均衡模式下，两个slave有独立的MAC地址，你可能会想，我能否给slave网口再绑定一个IP地址，用作其他用途。
这种方法是实现不了的。

负载均衡模式下，两个slave网口在操作性系统上看到是两个独立的MAC地址，但是当你指定一个MAC地址发送包的时候，实际上发生的现象，不是你期望的。你指定MAC地址1发包，这个数据包可能到MAC地址2出去了。
这个是因为Bond对这两个网口做了手脚，改了网口的驱动。看起来他们有独立的MAC地址，实际上他们的MAC地址不是独立的，只能给Bond使用。

#### 不足之处

**从上面的介绍中，很容易看到Bond的一点不足：**

Bond更改了网口的驱动，其网口不能被用作其他用途。

Bond还有一点不足就是其故障监测上面：
Bond默认只能做网口MII监测不能做链路监测（链路是指本机到网关的路径），也就是只能监测网口是否连接（网口是否亮）；当然Bond也支持ARP协议的链路监测，但是ARP链路监测在一些场景下，太消耗资源，得不偿失。我们曾经在实际应用中使用过，效果确实不好。



-------

{% note info %}### 主备模式的实施（CentOS6 and CentOS7）
{% endnote %}

**实验环境：**


CentOS6：

```bash
操作系统（OS）：CentOS release 6.8 (Final)
内核版本（Kernel）：2.6.32-642.el6.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

CentOS7：

```bash
操作系统（OS）：CentOS Linux release 7.2.1511 (Core)
内核版本（Kernel）：3.10.0-514.el7.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

#### Centos6实验步骤

##### 第一步，在VMware的控制台把需要绑定的网卡都设置在一个网段内（都设置成主机模式或者桥接，自定义都可以）

##### 第二步，在`Terminal`关闭`NetworkManager`服务，在`/etc/sysconfig/network-scripts/`目录下创建`ifcfg-bond0`配置文件

```bash
$ service NetworkManager stop 
$ cd /etc/sysconfig/network-scripts
$ vim ifcfg-bond0
	DEVICE=bond0
	BONDING_OPTS="miiimon=100 mode=1"
	IPADDR=172.16.23.150
	NETMASK=255.255.255.0
	GATEWAY=172.16.23.1
```

##### 第三步，修改两张物理网卡的配置信息

```bash
$ vim ifcfg-eth0
	DEVICE="eth0"
	MASTER=bond0
	SLAVE=yes

$ vim ifcfg-eth1
	DEVICE="eth1"
	MASTER=bond0
	SLAVE=yes
```

##### 第四步，重启网络服务

```bash
$ service network restart
```

##### 第五步，查看`bond0`配置信息


```bash
$ cat /proc/net/bonding/bond0 
	Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)
	Bonding Mode: fault-tolerance (active-backup)
	Primary Slave: None
	Currently Active Slave: eth0
	MII Status: up
	MII Polling Interval (ms): 100
	Up Delay (ms): 0
	Down Delay (ms): 0

	Slave Interface: eth0
	MII Status: up
	Speed: 1000 Mbps
	Duplex: full
	Link Failure Count: 0
	Permanent HW addr: 00:0c:29:26:8e:b1
	Slave queue ID: 0

	Slave Interface: eth1
	MII Status: up
	Speed: 1000 Mbps
	Duplex: full
	Link Failure Count: 0
	Permanent HW addr: 00:0c:29:26:8e:bb
	Slave queue ID: 0
```

##### 第六步，手动在VM控制端，模拟网卡故障， 断掉eth0的连接，使用另一台在一个网段的主机一直`ping bond0` 的IP地址，查看是否会自动切换网卡

```bash
$ ping 172.16.23.150
	64 bytes from 172.16.23.150: icmp_seq=10 ttl=64 time=0.197 ms
	Request timeout for icmp_seq 11
	Request timeout for icmp_seq 12
	64 bytes from 172.16.23.150: icmp_seq=13 ttl=64 time=0.223 ms
	64 bytes from 172.16.23.150: icmp_seq=14 ttl=64 time=0.214 ms

已经自动切换，并丢了2个包
	
查看bond0的信息，是否已经切换到eth1

$ cat /proc/net/bonding/bond0 
	Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

	Bonding Mode: fault-tolerance (active-backup)
	Primary Slave: None
	Currently Active Slave: eth1
	MII Status: up
	MII Polling Interval (ms): 100
	Up Delay (ms): 0
	Down Delay (ms): 0

	Slave Interface: eth0
	MII Status: down
	Speed: Unknown
	Duplex: Unknown
	Link Failure Count: 1
	Permanent HW addr: 00:0c:29:26:8e:b1
	Slave queue ID: 0

	Slave Interface: eth1
	MII Status: up
	Speed: 1000 Mbps
	Duplex: full
	Link Failure Count: 0
	Permanent HW addr: 00:0c:29:26:8e:bb
```


##### 第七步，删除bond0

```bash
$ ifconfig bond0 down  #down掉网卡

$ rmmod bonding    #卸载模块

$ rm -rf /etc/sysconfig/network-scripts/ifcfg-bond0  #删除配置文件

$ vim ifcfg-eth0
	BOOTPROTO=static
	IPADDR=172.16.1.130
	PREFIX=16
	GATEWAY=172.16.0.1

$ vim ifcfg-eth1
	BOOTPROTO=dhcp 

$ service network restart #重启网络
```



#### Centos7实验步骤

* 因为使用的是`CentOS7.2`所以，网卡名非常的长，不便于实验，先修改网卡名

```bash
$ vim /boot/grub2/grub.cfg
	修改此文件中的linux16一行的行尾添加 net.ifnames=0
	
$ vim /etc/sysconfig/network-scripts/ifcfg-eno.....
	修改原配置文件中的DEVICE名字和NAME名字，以及配置文件的名字为更改后的名字eth0/1之类的

$ reboot 
    即可生效
```

* 第一步，修改两张网卡都为仅主机模式

* 第二步，创建`bond0`设备以及其配置文件


```bash
$ nmcli connection add con-name bond0 type bond ifname bond0 mode active-backup

$ nmcli connection modift bond0 ipv4.method manual ipv4.addresses 172.16.23.200 gw 172.16.23.1 
```

* 第三步，将物理网卡添加到`bond0`中

```bash
$ nmcli connection add type bond-slave ifname eth0 master bond0 

$ nmcli connection add type bond-slave ifname eth1 master bond0
```

* 第四步，启动`bond-slave`

```bash
$ nmcli connection up bond-slave-eth1

$ nmcli connection up bond-slave-eth0
```

* 第五步，启动`bond0`

```bash
$ nmcli connection up bond0 
```

* 第六步，容错测试，与CentOS6步骤相同

* 第七步，删除`bond0`


```bash
$ nmcli connection down bond0 

$ nmcli connection delete bond0 

$ nmcli connection delete bond-slave-eth0

$ nmcli connection delete bond-slave-eth1

$ systemctl restart network
```


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=35283291&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


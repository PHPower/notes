---
title: layer7实现禁止登陆QQ,迅雷
date: 2017-06-12 20:03:57
tags: [linux,iptables,layer7,QQ,xunlei]
categories: iptables
copyright: true
---

![](https://ws1.sinaimg.cn/large/006tNbRwly1fgioztll76j31hc0s7wm7.jpg)

<blockquote class="blockquote-center">作为网络管理员，对p2p，QQ，迅雷等软件是又爱又恨
大多数公司，为了提高工作效率禁止公司员工上QQ，用迅雷下载高清无码视频，在市场上买专门的上网行为管理设备，动辄就是上万。
但是，如果使用Linux来做网关，一样可以禁止这些软件，成本才不到万把块钱。
</blockquote>

在使用 `layer7` 之前，我们需要知道，`layer7`是第三方的软件，而非 `Liunx`内核或者其他发行版自带的功能。所以我们要想使用其提供的功能，就要先把它编译到`kernel`中。

一听到<font size=3 color="#FF0000">编译内核 </font>，大多数人都会有`好麻烦`，`会不会出错`，`还是算了吧`这样的心态或者想法；但是，对于`Linux`来说，只有**<font color="#7093DB">永无止境的折腾</font>**才能学好并精通`Linux`。

废话不多说，下面让我们开始第一步：`编译Linux内核`


-------


<!-- more -->

<font size=5 color="#FF6EC7" > 实验环境： </font>

```
虚拟机操作系统（OS）：CentOS Linux release 7.2.1511 (Core)
内核版本（Kernel）：3.10.0-327.el7.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

这里因为要编译内核，所以尽可能增加一下虚拟机的配置

<font szie=5 color="#FF0000"> /usr目录如果是单独分区，分区大小必须大于20G，以免编译时空间不足</font>

**客户端环境：**
![](https://ws4.sinaimg.cn/large/006tNc79ly1fg5rfg0cjsj30ga0a8dj6.jpg)

-------


{% note primary %}### 编译Linux内核并打layer7补丁
{% endnote %}

#### 1、安装基本开发库及相关依赖软件


```
$ yum -y groupinstall "Development Libraries" "Development Tools"  "Server Platform Development" 
```

#### 2、下载内核源码以及layer7补丁

```
$ wget ftp://172.16.0.1/pub/Sources/sources/iptables/* ./
$ wget ftp://172.16.0.1/pub/Sources/sources/kernel/linux-2.6.32.61.tar.xz ./
```

##### 下载好了之后将其复制到`/usr/src`

```
$ cp /root/linux-2.6.32.61.tar.xz /usr/src
$ cp /root/netfilter-layer7-v2.23.tar.bz2 /usr/src
$ cd /usr/src
$ tar xf linux-2.6.32.61.tar.xz  
$ tar xf netfilter-layer7-v2.23.tar.bz2 
$ ln -s linux-2.6.32.61 linux 
$ cd /usr/src/linux 
$ patch -p1 < ../netfilter-layer7-v2.23/kernel-2.6.32-layer7-2.23.patch 
$ cp /root/config-2.6.32-el6 /usr/src/linux/.config 
$ make menuconfig  #执行之后会出现一个让用户选择内核模块的界面,进入相应的菜单,将下面的模块选上 
```




##### Networking support → Networking Options →Network packet filtering framework →Core Netfilter Configuration

```
	<M>  Netfilter connection tracking support 
	<M>  “layer7” match support
	<M>  “string” match support
	<M>  “time”  match support
	<M>  “iprange”  match support
	<M>  “connlimit”  match support
	<M>  “state”  match support
	<M>  “conntrack”  connection  match support
	<M>  “mac”  address  match support
	<M>   "multiport" Multiple port match support
```

##### Networking support → Networking Options →Network packet filtering framework → IP: Netfilter Configuration


```
<M> IPv4 connection tracking support (required for NAT)
<M>   Full NAT
	<M>     MASQUERADE target support                                                                                   
	<M>     NETMAP target support                                                                               
	<M>     REDIRECT target support 
```

##### 编译内核

```
$ yum install screen
$ screen
$ make 
$ make modules_install
$ make install
```

编译完成后记得要重启服务器，启动时选择新的内核

-------

{% note success %}### 编译安装iptables
{% endnote %}

#### 1、卸载系统上自带的iptables

卸载之前要先把`iptables`的启动脚本以及配置文件备份

```
$ cp /etc/init.d/iptables /root
$ cp /etc/sysconfig/iptables-config /root
```

卸载iptables：

```
$ rpm -e --nodeps iptables iptables-ipv6 iptstate
```

#### 2、编译安装iptables

先下载`iptables-1.4.20.tar.bz2`包到系统的 `/usr/src`目录下，然后开始编译安装

```
$ wget ftp://172.16.0.1/pub/Sources/sources/iptables/iptables-1.4.20.tar.bz2 /usr/src
$ cd /usr/src
$ tar xf iptables-1.4.20.tar.bz2 
$ cd iptables-1.4.20 
$ cp ../netfilter-layer7-v2.23/iptables-1.4.3forward-for-kernel-2.6.20forward/libxt_layer7.* ./extensions/ 
$ ./configure --prefix=/usr --with-ksource=/usr/src/linux
$ make 
$ make install 
```


-------

{% note info %}### 安装l7-protocols
{% endnote %}

`l7protocols` 是layer7所能够支持的协议包

下载`l7-protocols-2009-05-28.tar.gz`到/usr/src目录,然后开始编译安装

```
$ wget ftp://172.16.0.1/pub/Sources/sources/iptables/l7-protocols-2009-05-28.tar.gz /usr/src
$ cd /usr/src 
$ tar xf l7-protocols-2009-05-28.tar.gz 
$ cd l7-protocols-2009-05-28 
$ make install 
```

-------

{% note warning %}### 修改iptables启动脚本
{% endnote %}

就是之前我们做的关于`iptables`的启动脚本与配置文件的备份

#### 修改iptables启动脚本


```
$ cp /root/iptables-config /etc/sysconfig/
$ cp /root/iptables /etc/init.d/
$ chmod +x /etc/init.d/iptables
$ vim /etc/init.d/iptables      #注意，这里要把所有 /sbin/$IPTABLES 替换为 /usr/sbin/$IPTABLES
在vim的命令模式下输入：
%s@/sbin/$IPTABLES@/usr/sbin/$IPTABLES@g   回车执行后，保存退出
```

#### 启动iptables


```
$ service iptables restar
```


-------

{% note danger %}### 封QQ，迅雷
{% endnote %}

使本机作为一个局域网的网关，并具有上网功能的情况下：

#### 封QQ

```
$ iptables -A FORWARD -s 192.168.1.0/24 -m layer7 --l7proto qq -j REJECT
```

![](https://ws4.sinaimg.cn/large/006tKfTcly1fgird94hz3j30bp08zacc.jpg)

#### 封迅雷

```
$ iptables -A FORWARD -s 192.168.1.0/24 -m layer7 --l7proto xunlei -j REJECT
```

#### layer7支持百种协议

如果你想封其他程序，只需要查看程序是否在 `/etc/l7-protocols/protocols/` 目录下，如果有则`照猫画虎`似的按照上面的例子进行封杀即可。


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=189895&auto=0&height=66"></iframe>


本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)







---
title: iptables进阶
date: 2017-06-10 14:38:14
tags: [linux,iptables,nat,DNAT,SNAT]
categories: iptables
copyright: true
---

![](https://ws2.sinaimg.cn/large/006tNbRwly1fgg5yvq7kzj30xc0go7wh.jpg)


<blockquote class="blockquote-center">在这章我们会介绍iptables中如何配置NAT(Network Address Translation)，
也就是网络地址转换的功能。
</blockquote>

在iptables中，定义NAT时，需要在自带的`五表`之中的`nat表`中定义：

```
SNAT        源地址转换       -->     POSTROUTING链
DNAT        目标地址转换     -->     PREROUTING链 
PAT         端口转换        -->     端口映射
```

-------

<!-- more -->

{% note primary %}### SNAT
{% endnote %}

SNAT：Source NAT；请求来自内网，隐藏客户端IP地址

```
-j SNAT --to-source [ipaddr[-ipaddr]]
```


#### <font size=4  color="#7093DB"> SNAT实例</font>

实验拓扑图：

![](https://ws3.sinaimg.cn/large/006tNbRwly1fgg76jvc82j312y0mvqdi.jpg)

`NAT IP`: 172.16.1.70 ; 192.168.1.254
`Client IP`: 172.16.1.100
`http IP`: 192.168.1.10

实验目标：

```
1、实现三台机器之间互通，开启NAT服务器的核心转发功能
2、通过iptables的SNAT的功能，对http服务器隐藏客户端的IP地址
```

##### <font size=3  color="#3299CC"> 开启核心转发功能</font>

在NAT服务器上进行操作:

```
$ sysctl -w net.ipv4.ip_forward=1
$ cat /proc/sys/net/ipv4/ip_forward/
1
```

在外网客户端上进行操作：

```
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.16.0.1      0.0.0.0         UG    0      0        0 eth0
172.16.0.0      0.0.0.0         255.255.0.0     U     100    0        0 eth0

$ route del -net 0.0.0.0
$ route add defalut gw 172.16.1.70
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.16.1.70     0.0.0.0         UG    0      0        0 eth0
172.16.0.0      0.0.0.0         255.255.0.0     U     100    0        0 eth0
```

在http服务器上的操作：

配置好网关为NAT服务器的内网网卡地址

```
$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.254   0.0.0.0         UG    100    0        0 eth0
192.168.1.0     0.0.0.0         255.255.255.0   U     100    0        0 eth0
```


##### <font size=3  color="#3299CC"> 配置SNAT</font>

在NAT服务器上进行操作：

```
$ iptables -t nat -F
$ iptables -F
$ iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -p tcp --dport 80 -j SNAT --to-source 192.168.1.254
```

##### <font size=3  color="#3299CC"> 测试SNAT</font>

在外网客户端上进行操作：

```
$ curl http://192.168.1.10
<h1> hello world</h1>

<font size=4 color="#3299CC" > IP: 192.168.1.10 HTTP </font>
```

在http服务器上查看http访问日志：

```
$ cat /var/log/httpd/access_log
192.168.1.254 - - [10/Jun/2017:13:33:54 +0800] "GET / HTTP/1.1" 200 84 "-" "curl/7.29.0"
```


-------


{% note success %}### DNAT
{% endnote %}

DNAT：Destination NAT；请求来自外网，隐藏服务器

```
-j DNAT --to-destination [ipaddr[-ipaddr]][:port[-port]]
```


#### <font size=4  color="#7093DB"> DNAT实例</font>

实验拓扑图：

![](https://ws3.sinaimg.cn/large/006tNbRwly1fgg76jvc82j312y0mvqdi.jpg)

`NAT IP`: 172.16.1.70 ; 192.168.1.254
`Client IP`: 172.16.1.100
`http IP`: 192.168.1.10

实验目标：

```
1、实现三台机器之间互通，开启NAT服务器的核心转发功能
2、通过iptables的DNAT的功能，对客户端隐藏http服务器的IP地址
```


##### <font size=3  color="#3299CC"> 配置DNAT</font>

在NAT服务器上进行操作：

```
$ iptables -t nat -F
$ iptables -F
$ iptables -t nat -A PREROUTING -d 172.16.1.70 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.10
```

##### <font size=3  color="#3299CC"> 测试DNAT</font>

在外网客户端上进行操作：

```
$ curl http://172.16.1.70
<h1> hello world</h1>

<font size=4 color="#3299CC" > IP: 192.168.1.10 HTTP </font>
```

在http服务器上查看http访问日志：

```
$ cat /var/log/httpd/access_log
192.168.1.254 - - [10/Jun/2017:13:33:54 +0800] "GET / HTTP/1.1" 200 84 "-" "curl/7.29.0"
172.16.1.100 - - [10/Jun/2017:13:40:24 +0800] "GET / HTTP/1.1" 200 84 "-" "curl/7.29.0"
```

-------

{% note info %}### iptables NAT转换实操视频
{% endnote %}

哔哩哔哩视频源：

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=11219192&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>


-------

{% note warning %}### iptables放行ftp服务并使远程可以正常访问
{% endnote %}

哔哩哔哩视频源：

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=11216926&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>

-------

{% note primary %}### 创建iptables配置文件开机自动导入的Unit File文件
{% endnote %}

#### 1、先复制一份别的程序的Unit File： 

```
$ cp /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/iptables.service
```

#### 2、编辑复制好的配置文件

```
$ vim /usr/lib/systemd/system/iptables.service
[Unit]
Description=iptables rules constructor	#描述
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=notify
ExecStart=/usr/sbin/iptables-restore /root/iptables-rules/rules1		#启动时执行
ExecReload=/usr/sbin/iptables-restore /root/iptables-rules/rules1		#重载时执行
ExecStop=/usr/sbin/iptables -F          #停止时执行

[Install]
WantedBy=multi-user.target		#多用户模式下运行
```

#### 3、装载配置文件

```
$ systemctl daemon-reload
```

#### 4、启动自定义配置

```
$ systemctl enable iptables
$ systemctl start iptables
```

-------

<font size=5 color="#70DBDB"> 呃。。。这篇博客可能写的有点不太完善，有点草草应付了事的样子，最近为了学习Nginx，练习iptables，实在是无暇完善博客内容了。该做的都录屏了，以后再完善吧</font>

-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=32272267&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)
















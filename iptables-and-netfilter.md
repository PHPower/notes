---
title: iptables从入门到"放弃"
date: 2017-06-09 19:24:50
tags: [linux,iptables,firewall,netfilter]
categories: iptables
copyright: true
---

![](https://ws1.sinaimg.cn/large/006tKfTcly1fgf6igu3zwj30xc0go7wh.jpg)

<blockquote class="blockquote-center">iptables是一个配置 Linux内核 防火墙的命令行工具，是 netfilter 项目的一部分。
术语 iptables 也经常代指该内核级防火墙。
iptables可以直接配置，也可以通过 CentOS7中的新特性--firewalld 和图形界面配置。
iptables 适用于ipv4, ip6tables 适用于ipv6。
</blockquote>

在介绍如何在 Linux中使用与配置`iptables`之前，让我们先对<font color="#FF000">防火墙</font>有一个简单的理解：

```
它是一种位于内部网络与外部网络之间的网络安全系统。
一项信息安全的防护系统，依照特定的规则，允许或是限制传输的数据通过。
内部网络和外部网络之间的所有网络数据流都必须经过防火墙，这是防火墙所处网络位置特性，同时也是一个前提。
因为只有当防火墙是内、外部网络之间通信的唯一通道，才可以全面、有效地保护企业网内部网络不受侵害，所以防火墙一般部署在内网的最外层。
```

<!-- more -->

## iptables发展历史简介

### ipfirewall

ipfirewall，简称`ipfw`，在[FreeBSD](https://zh.wikipedia.org/wiki/FreeBSD)上开发的IP封包过滤程式，具备防火墙功能，由FreeBSD开发团队负责维护。它曾被移植到多个平台上，Mac OS X曾经采用它作为预设防火墙，直到Mac OS X 10.7 Lion 采用另一个FreeBSD程式[PF](https://www.freebsd.org/doc/handbook/firewalls-pf.html)。在1994年，[艾伦·考克斯](https://zh.wikipedia.org/wiki/%E8%89%BE%E5%80%AB%C2%B7%E8%80%83%E5%85%8B%E6%96%AF)曾经将它移植到Linux 1.1上，作为Linux的预设防火墙，直到Linux2.4 采用iptable来取代

### ipchains

Linux IP Firewalling Chains，一般称为ipchains，一种自由软件，在Linux内核2.2系列中运作，可用来作为封包过滤与防火墙功能之用。它被设计来取代旧有的ipfwadm，在Linux内核2.4系列中被iptables取代。

### iptables

iptables，一个运行在用户空间的应用软件，通过控制Linux内核netfilter模块，来管理网络数据包的流动与转送。在大部分的Linux系统上面，iptables是使用/usr/sbin/iptables来操作，文件则放置在手册页（Man page）底下，可以通过 man iptables 指令获取。通常iptables都需要内核层级的模块来配合运作，Xtables是主要在内核层级里面iptables API运作功能的模块。因相关动作上的需要，iptables的操作需要用到超级用户的权限。

目前iptables系在2.4、2.6及3.0的内核底下运作，旧版的Linux内核（2.2）使用ipchains及<font color="#FF000">ipwadm（Linux 2.0)</font>来达成类似的功能，2014年1月19日起发行的新版Linux内核（3.13后）则使用<font color="#FF000">nftables</font>取而代之。



-------

{% note primary %}## iptables简介
{% endnote %}

iptables其实应该叫`netfilter/iptables`它实际上由两个组件`netfilter` 和 `iptables` 组成。

`netfilter` 组件也称为内核空间（kernelspace），是内核的一部分，由一些信息包过滤表组成，这些表包含内核用来控制信息包过滤处理的规则集。
`iptables` 组件是一种规则编写工具，也称为用户空间（userspace），它使插入、修改和除去信息包过滤表中的规则变得容易。

### iptables是定义规则的工具

iptables本身并不算是防火墙。它定义的规则，可以让内核空间当中的 netfilter 来读取，并且实现让防火墙工作。而放入内核的地方必须要是特定的位置，必须是 `tcp/ip`的协议栈经过的地方。
而这个`tcp/ip`协议栈必须经过的地方，可以实现读取规则的地方就叫做 `netfilter`(网络过滤器)


### Hook functions

在Linux的内核空间中有五个位置可以对数据包进行过滤：

![](https://ws1.sinaimg.cn/large/006tKfTcly1fgf8vso1paj31kw0x8azk.jpg)

由上图可以看出：
一个数据包经过时，必须经过这五个关卡中的其一个或多个，而每个关卡都可以做相关的`规则`来进行限制，而这个关卡就叫做`Chain(链)`，每个关卡都会通过数据包的特征来进行判断（IP、port等）

iptables的表有四种，顾名思义，每个表的名字都已经高度概括了其功能，即`filter表`、`nat表`、`mangle`表和`raw表`，分别用于实现包过滤（防火墙），网络地址转换、包重构(修改)和数据跟踪处理，而每个表又定义了不同的链组合：


```
raw: INPUT,FORWARD,OUTPUT
nat: PREROUTING,INPUT,OUTPUT,POSTROUTING
mangle: PREROUTING,INPUT,OUTPUT,POSTROUTING
filter: INPUT,FORWARD,OUTPUT
```

其中表与表之间的优先级也就是：`raw` > `mangle` > `nat` > `filter`

**由图可以分析得出，其中的报文流向也就是：**

```
流入本机：PREROUTING --> INPUT
由本机流出：OUTPUT --> POSTROUTING
转发： PREROUTING --> FORWARD --> POSTROUTING
```


-------


{% note success %}## iptables规则的组成部分
{% endnote %}

根据规则匹配条件来尝试匹配报文，一旦匹配成功，就由规则定义的处理动作做出处理。

### 匹配条件

基本匹配条件：源地址，目标地址，传输层协议
扩展匹配条件：由扩展模块定义

隐式扩展：无需知名扩展模块的扩展机制
显式扩展：必须指明要调用的扩展模块的扩展机制

### 处理动作(跳转目标)

基本处理动作：ACCEPT、DROP
扩展处理动作：REJECT、RETURN、LOG、REDIRECT

### iptables的链：内置链和自定义链

内置链：对应于hook functions
自定义链接：用于内置链的扩展和补充，可实现更灵活的规则管理机制；自定义链可以设置完之后，添加到内置链中，方便管理

### 添加规则时需要考量的因素

(1) 实现的功能：用于判定将规则添加至哪个表；
(2) 报文的流经位置：用于判断将规则添加至哪个链；
(3) 报文的流向：判定规则中何为”源“，何为”目标“；
(4) 匹配条件：用于编写正确的匹配规则；

```
专用于某种应用的同类规则，匹配范围小的放前面；
专用于某些应用的不同类规则，匹配到的可能性较多的放前面；同一类别的规则可使用自定义链单独存放；访问量大的放前面，访问量小的放后面
用于通用目的的规则放前面；
```


**链：	链上的规则次序，即为检查的次序；因此，隐含一定的应用法则：**

```	
(1)同类规则（访问统一应用），匹配范围小的放上面；
(2)不同类的规则(访问不同应用)，匹配到报文频率较大的放在上面
(3)将那些可由一条规则描述的多个规则合并起来；
(4)设置默认策略
```



-------


{% note info %}## iptables命令详解
{% endnote %}

### 安装

`netfilter`：位于内核中的tcp/ip协议栈报文处理框架
`iptables`：

CentOS5/6：iptables命令生成规则，可保存于文件中以反复装载生效

```
$ iptables -t filter -F     #清空filter表的规则
$ service iptables save     #保存iptables规则
```

CentOS 7：firewalld, firewall-cmd, firewall-config

```
$ systemctl start firewalld.service     #开启防火墙，自动生成规则
```


### iptables命令

iptables是高度模块化的，由诸多扩展模块实现其检查条件或处理动作的

模块文件：

```
/usr/lib64/xtables/

IPv4使用范围的模块文件：libip6t_*
IPv6使用范围的模块文件：libipt_*,libxt_*
```

#### 命令格式

`iptables [-t table] COMMAND chain [-m matchname [per-match-options]] -j targetname [per-target-options]`

![](https://ws1.sinaimg.cn/large/006tKfTcly1fgf9zcpfsmj30s30kttag.jpg)

#### <font size=5  color="#7093DB">-t table</font>

`raw表`：
Chain：

```
PREROUTING
OUTPUT
```

<br>
`mangle表：`
Chain：

```
PREROUTING
INPUT
FORWARD
OUTPUT
POSTROUTING
```

<br>
`nat表：`
Chain

```
PREROUTING
INPUT
OUTPUT
POSTROUTING
```

<br>
`filter表：`
Chain：

```
INPUT
OUTPUT
FORWARD
```

#### <font size=5 color="#FF2400">COMMAND</font>

**链管理：**

```
-N，--new-chain CHAIN                    新建一个自定义的规则链
-X，--delete-chain CHAIN                 删除用户自定义的且引用计数为0的空链
-F，--flush [CHAIN]                      清空指定的规则链上的规则
-E，--rename-chain old-CHAIN new-CHAIN   重命名链
-Z，--zero [CHAIN [rulenum]]             置零计数器
-P，--policy CHAIN target                设置默认策略(ACCEPT/DROP/REJECT)
```

**规则管理**

```
-A, --append chain rule-specification               追加新规则于指定链的尾部； 
-I, --insert chain [rulenum] rule-specification     插入新规则于指定链的指定位置，默认为首部；
-R, --replace chain rulenum rule-specification      替换指定的规则为新的规则；
-D, --delete chain rulenum                          根据规则编号删除规则；
-D, --delete chain rule-specification               根据规则本身删除规则；
```

**规则显示**

```
-L, --list [chain]：列出规则
子命令：	
	-v, --verbose      详细信息； 
		-vv        更详细信息；
	-n, --numeric      数字格式显示主机地址和端口号；
	-x, --exact        显示计数器的精确值，而非圆整后的数据；
	--line-numbers     列出规则时，显示其在链上的相应的编号；

查看单个链：
$ iptables -vnL INPUT  

-S, --list-rules [chain]：显示指定链的所有规则
```

#### <font size=5 color="#9932CD">PARAMETER AND MATCH EXTENSIONS</font>

##### **通用匹配**

```
[!] -s, --source address[/mask][,...]           检查报文的'源IP地址'是否符合此处指定的范围，或是否等于此处给定的地址；
[!] -d, --destination address[/mask][,...]      检查报文的'目标IP地址'是否符合此处指定的范围，或是否等于此处给定的地址；
[!] -p, --protocol protocol                     匹配报文中的协议，可用值tcp,udp,udplite,icmp,icmpv6,esp,ah,sctp,mh 或者 "all", 亦可以数字格式指明协议； 
[!] -i, --in-interface name                     限定报文仅能够从指定的接口流入
[!] -o, --out-interface name                    限定报文仅能够从指定的接口流出
```

##### **扩展匹配**

可以出现多次，使用多个扩展模块

```
-m MODE [per-match-options]
```

##### **隐式扩展**

`-p tcp`：可直接使用tcp扩展模块的专用选项

```
[!] --source-port,--sport port[:port]               匹配报文源端口；可以给出多个端口，但只能是连续的端口范围 ；
[!] --destination-port,--dport port[:port]          匹配报文目标端口；可以给出多个端口，但只能是连续的端口范围 ；
[!] --tcp-flags mask comp                           匹配报文中的tcp协议的标志位；Flags are: SYN ACK FIN RST URG PSH ALL NONE；
	mask：要检查的FLAGS list，以逗号分隔；
	comp：在mask给定的诸多的FLAGS中，其值必须为1的FLAGS列表，余下的其值必须为0；
[!] --syn                                           匹配第一次握手，等于--tcp-flags SYN,ACK,FIN,RST  SYN
```
<br>
`-p udp`：可直接使用udp协议扩展模块的专用选项

```
[!] --source-port,--sport port[:port]
[!] --destination-port,--dport port[:port]
```
<br>
`-p icmp`：可直接使用icmp协议扩展模块的专用选项

```
[!] --icmp-type {type[/code]|typename}
    0/0： echo reply（请求的回显）
    8/0：echo request（发出去的请求）
```
<br>

##### <font size=4 color="#3299CC" >显式扩展</font>

必须使用`-m`选项指明要调用的扩展模块的扩展机制

`man iptables-extensions` 查看扩展帮助


<font size=3 color="#5F9F9F" >1、multiport</font>

以离散或连续的 方式定义多端口匹配条件，最多15个；	
支持tcp、udp、udplite、dccp、sctp
	
	
```
[!] --source-ports,--sports port[,port|,port:port]...
[!] --destination-ports,--dports port[,port|,port:port]...
	
$ iptables -I INPUT  -d 172.16.0.7 -p tcp -m multiport --dports 22,80,139,445,3306 -j ACCEPT
```

<br>
<font size=3 color="#5F9F9F" >2、iprange</font>
	以连续地址块的方式来指明多IP地址匹配条件；
	
```
[!] --src-range from[-to]
[!] --dst-range from[-to]
	
$ iptables -I INPUT -d 172.16.0.7 -p tcp -m multiport --dports 22,80,139,445,3306 -m iprange --src-range 172.16.0.61-172.16.0.70 -j REJECT
	
```
<br>
<font size=3 color="#5F9F9F" >3、time</font>
This  matches  if the packet arrival time/date is within a given range.
```
--timestart hh:mm[:ss]
--timestop hh:mm[:ss]
	 
[!] --weekdays day[,day...]
[!] --monthdays day[,day...]
	 
--datestart YYYY[-MM[-DD[Thh[:mm[:ss]]]]]
--datestop YYYY[-MM[-DD[Thh[:mm[:ss]]]]]
	
--kerneltz：使用内核配置的时区而非默认的UTC；CentOS6无需使用，默认就使用
```

<br>
<font size=3 color="#5F9F9F" >4、string(可以检查7层协议) '只能对明文编码的协议有效'</font>

This modules matches a given string by using some pattern matching strategy. 
```
--algo {bm|kmp}：bm和kmp算法处理的速度其实无太大的差别

[!] --string pattern
[!] --hex-string pattern
	
--from offset：从哪个位置开始
--to offset：从哪个位置结束
	
$ iptables -I OUTPUT -m string --algo bm --string "gay" -j REJECT
```

<br>
<font size=3 color="#5F9F9F" >5、connlimit ：连接限制；单个客户端最多并发数量的限制</font>

Allows  you  to  restrict  the  number  of parallel connections to a server per client IP address (or client address block).
```
--connlimit-upto n：上限，小于等于
--connlimit-above n：大于
	
$ iptables -I INPUT -d 172.16.0.7 -p tcp --syn --dport 22 -m connlimit --connlimit-above 2 -j REJECT
```
<br>
<font size=3 color="#5F9F9F" >6、limit ：速率限制</font>
This  module  matches  at  a limited rate using a token bucket filter. 
	
```
--limit rate[/second|/minute|/hour|/day]：限制令牌发放的速率
--limit-burst number：令牌桶最大收多少个令牌
	
$ iptables -I INPUT -d 172.16.1.70 -p icpmp --icmp-type 8 -m limit --limit-burst 5 --limit 4/minute -j ACCEPT
$ iptables -I OUTPUT -s 172.16.1.70 -p icmp --icmp-type 0 -j ACCEPT
```

<br>
<font size=3 color="#5F9F9F" >7、state：连接追踪(开启后，大大增强服务器安全性)</font>
The "state" extension is a subset of the "conntrack" module.  "state" allows access to the connection tracking state for this packet.
					
**连接追踪机制：**

```
连接过的，存在内存中的一个缓存表中。
	但是内存空间是有限的，记录具有超时时间
	对于访问量大的服务器：(不建议开启)
解决办法：
    (1)关闭连接追踪
    (2)扩大内存空间
```

```
[!] --state STATE
	INVALID, ESTABLISHED, NEW, RELATED or UNTRACKED.
	
STATE：
	NEW: 新连接请求；
	ESTABLISHED：已建立的连接；(一旦接受新请求之后，NEW --> ESTABLISHED)
	INVALID：无法识别的连接；不合法的连接
	RELATED：相关联的连接；当前连接是一个新请求，但附属于某个已存在的连接；(与某个ESTABLISHED具有关系的)
	UNTRACKED：未追踪的连接；
```
<font></font>


##### <font size=5 color="#007FFF" >Target</font>

`-j targetname [per-target-options]`

**简单target：**
	ACCEPT， DROP
	
**扩展target：**
	REJECT


```
--reject-with type：'表示以什么理由去拒绝；
拒绝理由：
icmp-net-unreachable            网络不可达
icmp-host-unreachable           主机不可达
icmp-port-unreachable           端口不可达(默认拒绝理由)
icmp-proto-unreach‐able         协议不可达
icmp-net-prohibited             网络被禁止        
icmp-host-prohibited            主机被禁止
icmp-admin-prohibited           管理员被禁止
```

**LOG：记录日志**

默认日志信息保存于：/var/log/message

<font color="#FF0000" >*注意：日志规则要放在REJECT和ACCEPT之前*</font>


```
--log-level：日志级别
--log-prefix：日志前缀(加一些自定义字符在记录日志之前，用于区别)
```

<br>
#### <font size=5 color="#8F8FBD" >保存和载入规则</font>

保存：iptables-save > /PATH/TO/SOME_RULE_FILE
重载：iptabls-restore < /PATH/FROM/SOME_RULE_FILE
	-n, --noflush：不清除原有规则
	-t, --test：仅分析生成规则集，但不提交(测试规则是否正常，正常后再重载)

<font color="#FF0000" >*注意：重载时，不会自动装载 nf_conntrack_ftp模块；可以使用脚本实现*</font>

<br>
`CentOS6使用方法：`

```
保存规则：
$ service iptables save
	保存规则于/etc/sysconfig/iptables文件，覆盖保存；
重载规则：(直接重载)
$ service iptables restart
	默认重载/etc/sysconfig/iptables文件中的规则 
	
配置文件：/etc/sysconfig/iptables-config
```

<br>
`CentOS7使用方法：`

```
(1) 自定义Unit File，进行iptables-restore；
(2) firewalld服务；
(3) 自定义脚本；
```

<br>
### 规则优化的思路


使用自定义链管理特定应用的相关规则，模块化管理规则；
		

```
(1) 优先放行双方向状态为ESTABLISHED的报文；
(2) 服务于不同类别的功能的规则，匹配到报文可能性更大的放前面；
(3) 服务于同一类别的功能的规则，匹配条件较严格的放在前面；
(4) 设置默认策略：白名单机制
	(a) iptables -P，不建议；
	(b) 建议在规则的最后定义规则做为默认策略；
```


-------

## Netfilter-packet-flow详解图(网络配图)

![](https://ws2.sinaimg.cn/large/006tNbRwly1fgfcasgobvj314a0d7n0j.jpg)

-------

到此为止，iptables的简介和用法已经介绍完毕，下一章，我们会介绍 <font color="#3299CC">**iptables的进阶用法--NAT地址转换**</font>


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=1591910&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



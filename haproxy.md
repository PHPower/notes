---
title: HAProxy用法详解
date: 2017-07-01 14:05:41
tags: [HAProxy,linux,nginx,apache,php,mysql,nfs]
categories: [linux进阶,HAProxy]
copyright: true
---

![](https://ws2.sinaimg.cn/large/006tNc79gy1fh4doappj2j30g703vmxj.jpg)

<blockquote class="blockquote-center">HAProxy是一款高可用性、负载均衡基于TCP(四层)和HTTP(七层)应用的代理软件，支持虚拟主机。
HAProxy特别适用于那些负载特大的web站点，这些站点通常又需要会话保持或七层处理。
HAProxy运行在时下的硬件上，完全可以支持数以万计的 并发连接。
并且它的运行模式使得它可以很简单安全的整合进您当前的架构中，同时可以保护你的web服务器不被暴露到网络上。
</blockquote>

### <font szie=4 color="#32CD99">**HAProxy性能**</font>

* 单进程、事件驱动模型显著降低了上下文切换的开销及内存占用
* O(1)事件检查器(event checker)允许其在高并发连接中对任何连接的任何事件实现即时探测
* 在任何可用的情况下，单缓冲(single buffering)机制能以不复制任何数据的方式完成读写操作，这会节约大量的CPU时钟周期及内存带宽


### <font szie=4 color="#5F9F9F">**相比其他负载均衡调度器，优点有：**</font>

1. HAProxy是支持虚拟主机的，通过frontend指令来实现
2. 能够补充Nginx的一些缺点比如Session的保持，Cookie的引导等工作
3. 支持url检测后端的服务器
4. 它跟LVS一样，本身仅仅就只是一款负载均衡软件；单纯从效率上来讲HAProxy更会比Nginx有更出色的负载均衡速度，在并发处理上也是优于Nginx的。
5. HAProxy可以对Mysql读进行负载均衡，对后端的MySQL节点进行检测和负载均衡，不过在后端的MySQL slaves数量超过10台时性能不如LVS。
6. 能对请求的url和header中的信息做匹配，有比lvs有更好的7层实现

### <font szie=4 color="#007FFF">**配置中两大配置段、五部分配置**</font>

#### 两大配置段

```bash
global      全局配置段，进程级安全配置相关的参数，性能调整相关参数，Debug参数
proxies     代理配置段，如"defaults"，"frontend"，"backend"
```

#### proxie配置段中的五部分配置


```bash
defaults        为frontend、listen、backend提供默认配置
frontend        前端配置，相当于nginx中的 server段
backend         后端配置，相当于nginx中的 upstream段
listen          frontend和backend的组合体
```

### <font szie=4 color="#8F8FBD">**时间格式**</font>

```
us: 微秒(microseconds)，即1/1000000秒；
ms: 毫秒(milliseconds)，即1/1000秒；
s: 秒(seconds)；
m: 分钟(minutes)；
h：小时(hours)；
d: 天(days)；
```

-------

<!-- more -->


{% note primary %}### HAProxy配置文件详解
{% endnote %}

### <font szie=4 color="#236B8E">Global配置参数</font>


```bash
log                 定义全局的syslog服务器；最多可以定义两个
    log <address> [len <length>] <facility> [max level [min level]]
    facility：帮助用户分类存储日志(将日志归类)
        后端存储日志的位置，都由facility定义
        需要在'rsyslog'中配置
nbproc <number>     要启动的haproxy的进程数量；('建议工作在单进程模型下'，1个进程处理所有请求)
ulimit-n <number>   每个haproxy进程可打开的最大文件数
chroot              切根，以安全模式运行
daemon              以守护进程运行
stats socket        套接字文件
pidfile             pid文件路径

性能调优参数：
maxconn <number>                    设定每个haproxy进程所能接受的最大并发连接数
maxconnrate <number>                每个进程每秒种所能创建的最大连接数量
maxsslconn <number>                 每进程能够处理最大的SSL会话数
spread-checks <0..50, in percent>   后端主机健康状态检查

超时时长配置：
timeout http request                在客户端建立连接但不请求数据时，关闭客户端连接
timeout queue                       等待最大时长
timeout connect                     定义haproxy将客户端请求转发至后端服务器所等待的超时时长
timeout client                      客户端非活动状态的超时时长
timeout server                      客户端与服务器端建立连接后，等待服务器端的超时时长，
timeout http-keep-alive             定义保持连接的超时时长
timeout check                       健康状态监测时的超时时间，过短会误判，过长资源消耗
 
http-server-close                   在使用长连接时，为了避免客户端超时没有关闭长连接，此功能可以使服务器端关闭长连接
redispatch                          在使用基于cookie定向时，一旦后端某一server宕机时，会将会话重新定向至某一上游服务器，必须使用的选项
```

<br>

### <font szie=4 color="#236B8E">Proxie配置参数</font>

- defaults <name>：默认配置
- frontend <name>：以服务端的身份对客户请求时使用
- backend  <name>：以客户端的身份对后端服务器请求时使用
- listen   <name>：一一对应时、或者只需监听前端，不用处理后端时(类似status页的工作原理)


**配置参数：**

* bind

```
bind [<address>]:<port_range> [, ...] [param*]
```

此指令仅能用于`frontend`和`listen`区段，用于定义一个或几个监听的套接字

`<address>`：可选选项，其可以为主机名、IPv4地址、IPv6地址或`*`；省略此选项、将其指定为`*`或0.0.0.0时，将监听当前系统的所有IPv4地址
`<port_range>`：可以是一个特定的TCP端口，也可是一个端口范围(如5005-5010)，指定多个端口时，用逗号分割。代理服务器将通过指定的端口来接收客户端请求；需要注意的是，每组监听的套接字<address:port>在同一个实例上只能使用一次
`<interface>`：指定物理接口的名称，其不能使用接口别名，而仅能使用物理接口名称，而且只有管理有权限指定绑定的物理接口

示例：

```
listen http_proxy
	bind :80,:443
	bind 10.0.0.1:10080,10.0.0.1:10443
	bind /var/run/ssl-frontend.sock user root mode 600 accept-proxy
```

<br>

* balance：后端服务器组内的服务器调度算法(不能用在frontend)


```
balance <algorithm> [ <arguments> ]
balance url_param <param> [check_post]
```

定义负载均衡算法，用于在负载均衡场景中挑选一个server，其仅应用于持久信息不可用的条件下或需要将一个连接重新派发至另一个服务器时。

支持的算法有：

```bash
roundrobin          动态轮询算法，支持权重的运行时调整，支持慢启动；每个后端中最多支持4095个后端服务器(server)-->相当于无上限
static-rr           静态轮询算法，不支持权重的运行时调整及慢启动；后端主机数量无上限
leastconn           最少连接，推荐使用在具有较长会话的场景中，例如MySQL、LDAP等
first               先到先得(只有当 当前服务器资源用完/上限之后，才会调度)，根据服务器在列表中的位置，自上而下进行调度；前面服务器的连接数达到上限，新请求才会分配给下一台服务
source              源地址hash；除权取余法和一致性哈希
uri                 类似于nginx的hash_uri，对URI的左半部分做hash计算，并由服务器总权重相除以后派发至某挑出的服务器
    当使用缓存服务器在后端时，使用此调度算法；对uri进行调度，根据请求的uri --> 提高缓存命中率

url_param           通过<argument>为URL指定的参数在每个HTTP GET请求中将会被检索；如果找到了指定的参数且其通过等于号“=”被赋予了一个值，那么此值将被执行hash运算并被服务器的总权重相除后派发至某匹配的服务器；
    此算法可以通过追踪请求中的用户标识进而确保同一个用户ID的请求将被送往同一个特定的服务器，除非服务器的总权重发生了变化；
    如果某请求中没有出现指定的参数或其没有有效值，则使用轮叫算法对相应请求进行调度；此算法默认为静态的，不过其也可以使用hash-type修改此特性

hdr(<name>)：对于每个http请求，此处由<name>指定的http首部将会被取出做hash计算； 并由服务器总权重相除以后派发至某挑出的服务器；没有有效值的会被轮询调度；
    name：请求的方法
```

<br>

* hash-type

```
hash-type <method> <function> <modifier>
```

定义用于将hash码映射至后端服务器的方法；其不能用于frontend区段；可用方法有map-based和consistent，在大多数场景下推荐使用默认的map-based方法。

**method：**

```
map-based           除权取余法(取模)，哈希数据结构是静态的数组；(静态映射hash)
consistent          一致性哈希。hash表是一个由各服务器填充而成的树状结构，将服务器散列在hash环上；基于hash键在hash树中查找相应的服务器时，最近的服务器将被选中。
```


<br>

* default_backend

```
default_backend <backend>
```

在没有匹配的”use_backend”规则时为实例指定使用的默认后端，因此，其不可应用于backend区段。在”frontend”和”backend”之间进行内容交换时，通常使用”use-backend”定义其匹配规则；而没有被规则匹配到的请求将由此参数指定的后端接收。

<br>

* default-server

```
default-server [param*]
```

为backend中的各server设定默认选项

<br>

* server

```
server <name> <address>[:[port]] [param*]
```

为后端声明一个server，因此，不能用于defaults和frontend区段。

`<name>`：为此服务器指定的内部名称，其将出现在日志及警告信息中；如果设定了"http-send-server-name"，它还将被添加至发往此服务器的请求首部中
`<address>`：此服务器的的IPv4地址，也支持使用可解析的主机名，只不过在启动时需要解析主机名至相应的IPv4地址
`[:port]`：指定将连接请求所发往的此服务器时的目标端口，其为可选项；未设定时，将使用客户端请求时的同一相端口
`[param*]`：为此服务器设定的一系参数；其可用的参数非常多，具体请参考官方文档中的说明，下面仅说明几个常用的参数

```
maxconn <maxconn>       当前server的最大并发连接数(压测完后，上线之前要设置)
backlog <backlog>       当前server的连接数达到上限后的'后援队列长度'；超过则拒绝响应
backup                  设定为备用服务器，仅在负载均衡场景中的其它server均不可用于启用此servr
check                   启动对此server执行健康状态检查，其可以借助于额外的其它参数完成更精细的设定
    addr ：检测时使用的'IP地址'；(当后端服务器有多个IP地址时，避免检查后端服务器的业务IP地址，对后端服务器增加压力)
    port ：针对此'端口'进行检测；
    inter <delay>：连续两次检测之间的时间间隔，默认为2000ms; 
    rise <count>：连续多少次检测结果为“成功”才标记服务器为可用；默认为2；
    fall <count>：连续多少次检测结果为“失败”才标记服务器为不可用；默认为3；

cookie <value>          为当前server指定其cookie值，用于实现基于cookie的会话黏性;为后端服务器指定静态cookie
disabled                标记为不可用；(人工设置服务器为down状态)
redir <prefix>          将发往此server的所有GET和HEAD类的请求重定向至指定的URL
weight <weight>         权重，默认为1
```

<br>

* stats enable

启用基于程序编译时默认设置的统计报告，不能用于“frontend”区段。只要没有另外的其它设定，它们就会使用如下的配置

```
stats uri               /haproxy?stats
stats realm             "HAProxy Statistics"
stats auth              no authentication
stats scope             no restriction
```

尽管"stats enable"一条就能够启用统计报告，但还是建议设定其它所有的参数，以免其依赖于默认设定而带来非期后果。下面是一个配置案例:

```
listen status
    bind *:9909
    acl auth_admin  src 172.16.250.15 172.16.1.11
    stats           enable
    stats uri       /myha?stats
    stats realm     HAProxy\ Admin\ Area
    stats auth      root:root@123
    stats admin     if auth_admin
    stats hide-version
```

<br>

* stats hide-version

启用统计报告并隐藏HAProxy版本报告，不能用于“frontend”区段。默认情况下，统计页面会显示一些有用信息，包括HAProxy的版本号，然而，向所有人公开HAProxy的精确版本号是非常有风险的，因为它能帮助恶意用户快速定位版本的缺陷和漏洞。尽管“stats hide-version”一条就能够启用统计报告，但还是建议设定其它所有的参数，以免其依赖于默认设定而带来非期后果。

<br>

* stats realm

```
stats realm <realm>
```

启用统计报告并高精认证领域，不能用于"frontend"区段。haproxy在读取realm时会将其视作一个单词，因此，中间的任何空白字符都必须使用反斜线进行转义。此参数仅在与"stats auth"配置使用时有意义。

<br>

* stats auth

```
stats auth <user>:<passwd>
```

启用带认证的统计报告功能并授权一个用户帐号，其不能用于"frontend"区段。
`<user>`：授权进行访问的用户名
`<passwd>`：此用户的访问密码，明文格式

<br>

* stats admin

```
stats admin { if | unless } <cond>
```

在指定的条件满足时启用统计报告页面的管理级别功能，它允许通过web接口启用或禁用服务器，不过，基于安全的角度考虑，统计报告页面应该尽可能为只读的。此外，如果启用了HAProxy的多进程模式，启用此管理级别将有可能导致异常行为。

<br>

* option httplog

```
option httplog [ clf ]
```

启用记录HTTP请求、会话状态和计时器的功能。
`clf`：使用CLF格式来代替HAProxy默认的HTTP格式，通常在使用仅支持CLF格式的特定日志分析器时才需要使用此格式。

<br>

* errorfile

```
errorfile <code> <file>
```

在用户请求不存在的页面时，返回一个页面文件给客户端而非由haproxy生成的错误代码；可用于所有段中。

`<code>`：指定对HTTP的哪些状态码返回指定的页面；这里可用的状态码有200、400、403、408、500、502、503和504
`<file>`：指定用于响应的页面文件

<br>

* option forwardfor

```
option forwardfor [ except <network> ] [ header <name> ] [ if-none ]
```

允许在发往服务器的请求首部中插入"X-Forwarded-For"首部。用于向后端主发送真实的客户端IP

`<network>`：可选参数，当指定时，源地址为匹配至此网络中的请求都禁用此功能。
`<name>`：可选参数，可使用一个自定义的首部，如“X-Client”来替代“X-Forwarded-For”。有些独特的web服务器的确需要用于一个独特的首部。
`if-none`：仅在此首部不存在时才将其添加至请求报文问道中。
HAProxy工作于反向代理模式，其发往服务器的请求中的客户端IP均为HAProxy主机的地址而非真正客户端的地址，这会使得服务器端的日志信息记录不了真正的请求来源，“X-Forwarded-For”首部则可用于解决此问题。HAProxy可以向每个发往服务器的请求上添加此首部，并以客户端IP为其value。



示例：

```
errorfile 400 /etc/haproxy/errorpages/400badreq.http
errorfile 403 /etc/haproxy/errorpages/403forbid.http
errorfile 503 /etc/haproxy/errorpages/503sorry.http
```

<br>

* reqadd

```
reqadd  <string> [{if | unless} <cond>]
```

在请求报文中添加首部

<br>

* rspadd

```
rspadd <string> [{if | unless} <cond>]
```

在响应给客户端的报文中添加首部；上下文，除了default都可以

<br>

* reqdel

```
reqdel  <search> [{if | unless} <cond>]
reqidel <search> [{if | unless} <cond>]  (ignore case)      
```

删除请求报文的某个首部、依据正则表达式进行删除

<br>

* rspdel

```
rspdel  <search> [{if | unless} <cond>]
rspidel <search> [{if | unless} <cond>]  (ignore case)
```

删除响应报文的首部

**配置示例**

```
frontend  main
    bind *:80
    default_backend             websrv
    maxconn 5000
    rspadd X-Via:\ HAPorxy
    rspidel Server.*
```


<br>

### <font szie=4 color="#236B8E">日志配置</font>


**默认格式**

```
Field   Format                                Extract from the example above
  1   process_name '[' pid ']:'                            haproxy[14385]:
  2   'Connect from'                                          Connect from
  3   source_ip ':' source_port                             10.0.1.2:33312
  4   'to'                                                              to
  5   destination_ip ':' destination_port                   10.0.3.31:8012
  6   '(' frontend_name '/' mode ')'                            (www/HTTP)
```

<br>

**tcp日志格式**

option tcplog：指定日志格式为tcplog



```
Field   Format                                Extract from the example above
 1   process_name '[' pid ']:'                            haproxy[14387]:
 2   client_ip ':' client_port                             10.0.1.2:33313
 3   '[' accept_date ']'                       [06/Feb/2009:12:12:51.443]
 4   frontend_name                                                    fnt
 5   backend_name '/' server_name                                bck/srv1
 6   Tw '/' Tc '/' Tt*                                           0/0/5007
 7   bytes_read*                                                      212
 8   termination_state                                                 --
 9   actconn '/' feconn '/' beconn '/' srv_conn '/' retries*    0/0/0/0/3
10   srv_queue '/' backend_queue                                      0/0
```

<br>

**http日志格式**

option httplog：指定日志格式为 httplog

```
Field   Format                                Extract from the example above
 1   process_name '[' pid ']:'                            haproxy[14389]:
 2   client_ip ':' client_port                             10.0.1.2:33317
 3   '[' request_date ']'                      [06/Feb/2009:12:14:14.655]
 4   frontend_name                                                http-in
 5   backend_name '/' server_name                             static/srv1
 6   TR '/' Tw '/' Tc '/' Tr '/' Ta*                       10/0/30/69/109
 7   status_code                                                      200
 8   bytes_read*                                                     2750
 9   captured_request_cookie                                            -
10   captured_response_cookie                                           -
11   termination_state                                               ----
12   actconn '/' feconn '/' beconn '/' srv_conn '/' retries*    1/1/1/1/0
13   srv_queue '/' backend_queue                                      0/0
14   '{' captured_request_headers* '}'                   {haproxy.1wt.eu}
15   '{' captured_response_headers* '}'                                {}
16   '"' http_request '"'                      "GET /index.html HTTP/1.1"
```

<br>


* capture cookie 

```
capture cookie <name> len <length>
```

记录指定cookie的日志

`name`：cookie的名字
`length`：记录日志的长度

<br>

* capture request header

```
capture request header <name> len <length>
```

捕获请求报文的指定首部的值并记录下来

<br>

* capture response header

```
capture response header <name> len <length>
```

捕获响应报文的指定首部的值并记录


<br>

### <font szie=4 color="#236B8E">健康状态检查</font>

对后端服务器做http协议的健康状态检测(除frontend段，都可以使用)


```
option httpchk
option httpchk <uri> 			
option httpchk <method> <uri>
option httpchk <method> <uri> <version>
```

定义基于http协议的7层健康状态检测机制


* http-check

```
http-check expect [!] <match> <pattern>
```

检查，指定返回的内容/响应码

`rstatus`：匹配响应码
`rstring`：匹配内容



<br>

### <font szie=4 color="#236B8E">连接超时时长配置</font>


```
timeout client <timeout>
	Set the maximum inactivity time on the client side. 
	默认单位是毫秒; 
	
timeout server <timeout>
	Set the maximum inactivity time on the server side.
	
timeout http-keep-alive <timeout>
	持久连接的持久时长；
	作为代理服务器，面向客户端开启持久连接，尽量要小 --> 1s  2s 
	
timeout http-request <timeout>
	Set the maximum allowed time to wait for a complete HTTP request
	'等待客户端发送请求报文的超时时长'

timeout connect <timeout>
	Set the maximum time to wait for a connection attempt to a server to succeed.
	'HAProxy与后端服务器 连接建立的超时时间'

timeout client-fin <timeout>
	Set the inactivity timeout on the client side for half-closed connections.
	半关闭连接超时时间；'提高会话复用性'
		客户端

timeout server-fin <timeout>
	Set the inactivity timeout on the server side for half-closed connections.
	半关闭连接超时时间；'提高会话复用性'
```



<br>

### <font szie=4 color="#236B8E">其他配置</font>

* use_backend

```
use_backend <backend> [{if | unless} <condition>]
```

当符合指定的条件时使用特定的backend

<br>

* block

```
block { if | unless } <condition>
```

阻塞请求

<br>

* http-request

```
http-request { allow | deny } [ { if | unless } <condition> ]
```

http访问控制


**配置示例**

```
listen ssh
	bind :22022
	balance leastconn
	acl invalid_src src 172.16.200.2
	tcp-request connection reject if invalid_src
	mode tcp
	server sshsrv1 172.16.100.6:22 check
	server sshsrv2 172.16.100.7:22 check backup
```


<br>

### <font szie=4 color="#236B8E">ACL</font>

aproxy的ACL用于实现基于请求报文的首部、响应报文的内容或其它的环境状态信息来做出转发决策，这大大增强了其配置弹性。其配置法则通常分为两步，首先去定义ACL，即定义一个测试条件，而后在条件得到满足时执行某特定的动作，如阻止请求或转发至某特定的后端。


语法格式：

```
acl <aclname> <criterion> [flags] [operator] <value> ...
```

#### `<aclname>`：acl的名称(标识符)
#### `<criterion>`：匹配标准 

```
dst : ip  -->目标IP
dst_port : integer
src : ip  -->源IP
src_port : integer
```

**path: string**

提取请求url的地址信息，从第一个"/"开始，不包含host，不包含参数

```
path     : exact string match
path_beg : prefix match
path_dir : subdir match
path_dom : domain match 
path_end : suffix match
path_len : length match
path_reg : regex match
path_sub : substring match	
```

**url : string**

提取URL的全部内容，包含host和参数ACL

```
url     : exact string match
url_beg : prefix match
url_dir : subdir match
url_dom : domain match
url_end : suffix match
url_len : length match
url_reg : regex match
url_sub : substring match
```

**req请求报文：hdr([<name>[,<occ>]]) : string**

请求报文首部访问控制

```
hdr([<name>[,<occ>]])     : exact string match
hdr_beg([<name>[,<occ>]]) : prefix match
hdr_dir([<name>[,<occ>]]) : subdir match
hdr_dom([<name>[,<occ>]]) : domain match
hdr_end([<name>[,<occ>]]) : suffix match
hdr_len([<name>[,<occ>]]) : length match
hdr_reg([<name>[,<occ>]]) : regex match
hdr_sub([<name>[,<occ>]]) : substring match
```



#### `<value>`类型：

```
- boolean：真假
- integer or integer range：整数值
- IP address / network：IP地址、网络地址
- string (exact, substring, suffix, prefix, subdir, domain)
	匹配指定的首部的值
	exact：精确匹配
	substring：
	suffix：后缀匹配
	prefix：前缀匹配
	subdir：子路径匹配
	domain：域名子串匹配

- regular expression：正则表达式匹配
- hex block：16进制数字块
```

#### `<flags>`标识位

```
-i : ignore case during matching of all subsequent patterns.
    忽略字符大小写

-m : use a specific pattern matching method
    特殊匹配

-n : forbid the DNS resolutions
    DNS解析

-u : force the unique id of the ACL
    ACL id必须唯一

-- : force end of flags. Useful when a string looks like one of the flags
    强制结束 flags

```


#### `[operator]`

* 匹配整数值：

```
eq、ge、gt、le、lt
```

* 匹配字符串:

```
-m method : 指定模式匹配方法

	其中flag中的 -m 选项可使用的模式匹配方法如下，需要说明的是有些方法已被默认指定无需声明，例如int，ip

	"found" : 只是用来探测数据流中是否存在指定数据，不进行任何比较
	"bool" : 检查结果返回布尔值。匹配没有模式，可以匹配布尔值或整数，不匹配0和false，其他值可以匹配
	"int" : 匹配整数类型数据；可以处理整数和布尔值类型样本，0代表false，1代表true
	"ip" : 匹配IPv4，IPv6地址类型数据。该模式仅被IP地址兼容，不需要特别指定
	"bin" : 匹配二进制数据
	"len" : 匹配样本的长度的整数值
	"str" : 精确匹配，根据字符串匹配文本
	"sub" : 子串匹配，匹配文本是否包含子串
	"reg" : 正则匹配，根据正则表达式列表匹配文本
	"beg" : 前缀匹配，检查文本是否以指定字符串开头
	"end" : 后缀匹配，检查文本是否以指定字符串结尾
	"dir" : 子目录匹配，检查部分文本中以" / "作为分隔符的内容是否含有指定字符串
	"dom" : 域匹配。检查部分文本中以" . "作为分隔符的内容是否含有指定字符串
```


#### acl作为条件时的逻辑关系


```
- AND (implicit)

- OR  (explicit with the "or" keyword or the "||" operator)
	或的关系

- Negation with the exclamation mark ("!")
	取反

	if invalid_src invalid_port
	if invalid_src || invalid_port
	if ! invalid_src invalid_port
```



#### 配置示例


```bash
#禁止使用curl请求
acl bad_curl hdr_sub(User-Agent) -i curl
block if bad_curl	

#阻断火狐浏览器发送的请求
acl firefox hdr_reg(User-Agent)     -i      .*firefox.*
block if firefox	

#拒绝GET HEAD 方式之外的HTTP请求
http-request deny if ! METH_GET
```


<br>

### <font szie=4 color="#236B8E">配置HAProxy支持https协议</font>

* 配置支持ssl会话

```
bind *:443 ssl crt /PATH/TO/SOME_PEM_FILE
```

`ssl`：要求必须使用 ssl会话
`crt`：指明证书文件路径 --> 证书和私钥都在这个文件内

<br>

* 把80端口的请求重向定443

```
bind *:80
	redirect scheme https if !{ ssl_fc }
```

`scheme`：协议
`ssl_fc`：如果请求的是非ssl前端的，则重定向(无需定义，因为是內建的，直接调用 ssl_fc)

* 向后端传递用户请求的协议和端口

```
http_request set-header X-Forwarded-Port %[dst_port]
http_request add-header X-Forwared-Proto https if { ssl_fc }
```



-------


在下一章节，我们会讲解如何使用`HAProxy`对网站的动静分离实现负载均衡调度，搭配上我们前一节所学`varnish`，加快对动静资源的访问速度。


-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=28838894&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)








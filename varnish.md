---
title: 高性能缓存服务器Varnish详解
date: 2017-06-27 07:39:00
tags: [varnish,linux,nginx]
categories: [linux进阶,Varnish]
copyright: true
---

![](https://ws4.sinaimg.cn/large/006tNc79ly1fgzgguy09lj30lf06y0tv.jpg)

<blockquote class="blockquote-center">Varnish是反向HTTP代理，也是HTTP加速器或者Web加速器。
Varnish不仅仅是缓存内容以加速器服务器的反向HTTP代理。根据实际情况，Varnish也可以用作：

* Web应用程序防火墙 *
* DDoS攻击防御器 *
* 负载均衡器 *
* HTTP路由器 *
</blockquote>

`Varnish`的优势：
> Varnish的稳定性很高，与Squid相比，在运行在相同负荷的情况下，Squid服务器发生故障的几率要高于Varnish。
> Varnish的访问速度更快，因为所有缓存数据都可以直接从内存读取，也可以从硬盘读取；比Squid更为灵活、
> Varnish支持更多的并发连接。只需要调整thread_pools与thread_pool_max的值即可，不过要根据实际情况的CPU核心数以及服务器要被用来做什么而定。

<br>

`Varnish`的劣势：
> 一旦Varnish遇到Crash或者重启进程，所有的缓存数据都会从内存中完全释放，此时所有的访问都不会被缓存命中，而请求都会被发送到后端服务器，在高并发的情况下，后端服务器很可能因此崩溃掉。

<br>

解决方案：
> 在访问量很大的情况下，我们可以使用Varnish的内存缓存方式，而且后端要配置多台Squid服务器。防止前端Varnish服务重启、服务器重启或者不可预知的误操作情况下，大量请求穿透Varnish，这样Squid可以充当第二层缓存。
> 也可以通过Keepalived+varnish+rsync+inotify达到高可用的状态，这样在主节点不繁忙的时候，将缓存的信息同步到另一台备用缓存服务器上。为了尽可能的利用资源，我们可以将两台varnish配置成"双主模式"


-------

<!-- more -->


{% note primary %}### Varnish架构以及WorkFlow
{% endnote %}

### <font szie=4 color="#236B8E">架构图</font>

![](https://ws2.sinaimg.cn/large/006tNc79ly1fgzj0riyr4j31cg0oste4.jpg)
 
* Varnish分为 Master进程和 Child进程；也就是主控进程和子进程，概念相当于nginx中worker进程

* Master进程读入配置文件，根据配置文件中指定的缓存类型，选择存储类型，然后创建缓存文件；接着master初始化管理该存储空间的结构体，然后监控 child进程

* 对外管理接口有三种：CLI命令行接口、Telnet接口、Web接口(商业版)

* 同时在运行过程中修改的配置，可以由VCL编译器编译成C语言，并组织成共享对象(Shared Object)交由Child进程加载使用

<br>

### <font szie=4 color="#236B8E">Child进程</font>

`Child进程`分配若干线程进行工作，主要包括一些管理线程和很多worker线程

```
Accept线程            接收请求，将请求挂在overflow队列上
Work线程              有多个，负责从overflow队列上摘除请求，并对请求进行处理，直到完成，然后处理下一个请求
Epoll线程             一个请求处理称为一个session，在session周期内，处理完请求后，会交给Epoll处理，监听是否还有事件发生
Expire线程            对于缓存的object，根据过期时间，组成成二叉堆，该线程周期检查该堆的根，处理过期的文件，对过期的数据进行删除或重取操作
```

<br>

#### <font szie=4 color="#236B8E">HTTP请求处理基本流程</font>

![](https://ws3.sinaimg.cn/large/006tNc79ly1fgzjd6arfxj30j10qwgrm.jpg)

**Varnish处理HTTP请求的过程如下：**

1. Receive(vcl_recv)状态：也就是请求处理的入口状态，根据VCL规则判断该请求是应该进入 `pass(vcl_pass)`或者是 `pipe(vcl_pipe)`或者是`lookup(缓存本地查询)`，还是`purge(vcl_purge)`。<br>

2. Lookup 状态：进入该状态后，会在hash表中查找数据。若找到，则进入`hit`(vcl_hit)状态，否则进入`miss`(vcl_miss)状态。<br>

3. Pass(vcl_pass)状态：在此状态下，对于请求会直接发往后端主机，进入到`backend_fetch`(vcl_backend_fetch)状态。

4. Backend_Fetch(vcl_backend_fetch)状态：在此状态下，对请求会向后端服务器进行获取，发送请求，获得数据，并根据配置文件中对此类数据的缓存设置进行缓存或者其他操作。

5. Deliver(vcl_deliver)状态：将获取到的数据发送给客户端，完成本次请求。

<br>

#### <font szie=4 color="#236B8E">子例程(内置函数)</font>

* vcl_recv：用于接收和处理请求；当请求到达varnish，通过判断请求的数据来决定如何处理请求
* vcl_pipe：用于将请求直接传递至后端主机，并将后端响应原封不动返回给客户端
* vcl_pass：用于将请求直接传递给后端主机，但后端主机的响应并不缓存，而是直接返回给客户端
* vcl_hit：在缓存中找到请求的内容后自动调用
* vcl_miss：在缓存中没有找到请求的内容后自动调用。用于判断是否需要从后端服务器获取内容
* vcl_hash：在vcl_recv调用后为请求创建一个hash值时，调用。此hash值将作为varnish中hash表的key
* vcl_pruge：在收到 purge请求时，执行此函数，清空特定页面/资源的缓存。
* vcl_deliver：将在缓存中找到的请求的内容发送给客户端前调用。
* vcl_backend_fetch：向后端主机发送请求前，调用。可修改发往后端的请求
* vcl_backend_response：获得后端主机的响应后，调用。
* vcl_backend_error：当从后端主机获取资源时失败时，调用。
* vcl_init：VCL加载时调用此函数，用于初始化varnish模块(类似于awk中的BEGIN)
* vcl_fini：当所有请求都离开当前VCL，且当前VCL被弃用时，调用。用于清理varnish模块(类似于awk中的END)

<br>

#### <font szie=4 color="#236B8E">VCL内建变量</font>

![](https://ws2.sinaimg.cn/large/006tNc79ly1fgzk9cjwyxj31kw0nvamp.jpg)


**变量类型详解：**

![](https://ws2.sinaimg.cn/large/006tNc79ly1fgzkau2b7uj30qe0cg41q.jpg)

```
req         The request object              请求到达时使用的变量
bereq       The backend request object      向后端主机请求时使用的变量
beresp      The backend response object     向后端主机获取内容时使用的变量
resp        The HTTP response object        对客户端响应时使用的变量
obj                                         存储在内存中时对象属性相关的使用的变量
```


* bereq以及req的子变量详解：

```
bereq.http.HEADERS          各种各样的头部信息
bereq.request               请求方法
bereq.url                   请求的url
bereq.proto                 请求的协议版本
bereq.backend               指明要调用的后端主机

req.http.Cookie             客户端的请求报文中Cookie首部的值
req.http.User-Agent ~ "chrome"
```

* beresp以及resp的子变量详解：

```
beresp.http.HEADERS
beresp.status               响应的状态码
reresp.proto                协议版本
beresp.backend.name         BE主机的主机名
beresp.ttl                  BE主机响应的内容的余下的可缓存时长
```

* obj子变量：

```
obj.hits        此对象从缓存中命中的次数
obj.ttl         缓存时长
obj.grace       缓存宽限期
```

* server子变量：

```
server.ip           服务端IP
server.hostname     服务端主机名
```

* client子变量：

```
client.ip           客户端IP地址
```

-------

{% note success %}### Varnish配置文件详解
{% endnote %}

#### <font size=4 color="#32CD99"> varnish.params配置文件</font>


```
VARNISH_VCL_CONF=/etc/varnish/default.vcl           指定vcl文件的地址

VARNISH_LISTEN_PORT=80                              指定监听的服务端口

VARNISH_ADMIN_LISTEN_ADDRESS=127.0.0.1              指定管理IP地址
VARNISH_ADMIN_LISTEN_PORT=6082                      指定管理监听的端口

VARNISH_SECRET_FILE=/etc/varnish/secret             指定SECRET文件的位置

VARNISH_STORAGE="malloc,256M"                       设置存储类型以及大小;Varnish 4中默认使用malloc(即内存)作为缓存对象存储方式

VARNISH_USER=varnish                                运行varnish进程的属主
VARNISH_GROUP=varnish                               运行varnish进程的属组

DAEMON_OPTS="-p thread_pool_min=5 -p thread_pool_max=500 -p thread_pool_timeout=300"                进程池配置，开启varnish自动加载
```

<br>

#### <font size=4 color="#32CD99"> default.vcl配置文件</font>


```bash
# 使用varnish版本4的格式.
vcl 4.0;

# 加载后端负载均衡模块
import directors;


#######################健康检查策略区域###########################
# 名为www_probe的健康检查策略
probe www_probe {
.request =
    "GET /html/test.html HTTP/1.1"      # 健康检查url为/html/test.html 协议为http1.1
    "Host: www.maxie.com"               # 访问的域名为www.maxie.com
    "Connection: close";                # 检查完关闭连接
#其他参数 如 超时时间 检查间隔 等均使用默认
.window                                 # 基于最近的多少次检查来判断其健康状态
.threshold                              # 最近.window中定义的这么次检查中至有.threshhold定义的次数是成功的
.interval                               # 检测频度
.timeout                                # 超时时长
}


#名为 backend_healthcheck的健康检查策略
probe backend_healthcheck { 
    .url = /health.html;
    .window = 5;
    .threshold = 2;
    .interval = 3s;
}


#########################################################
#######################配置后端区域########################

backend backend_20 {
.host = "172.16.3.20";
.port = "80";
.probe = www_probe;                 # 使用名为www_probe的健康检查策略
}
backend backend_30 {
.host = "172.16.3.30";
.port = "80";
.probe = www_probe;                 # 使用名为www_probe的健康检查策略
}

#默认后端
backend default {
.host = "172.16.3.40";
.port = "81";
}

###########################################################
#######################配置后端集群事件#######################

sub vcl_init {
# 后端集群有4种模式 random, round-robin, fallback, hash
# random                随机
# round-robin           轮询
# fallback              后备
# hash                  固定后端 根据url(req.http.url) 或 用户cookie(req.http.cookie) 或 用户session(req.http.sticky)(这个还有其他要配合)


# 把backend_20 和 backend_30 配置为轮询集群 取名为www_round_robin
new www_round_robin = directors.round_robin();
www_round_robin.add_backend(backend_16);
www_round_robin.add_backend(backend_17);


# 把backend_16 和 backend_17配置为随机选择集群 取名为www_random
new www_random = directors.random();
www_random.add_backend(backend_16,10);  # 设置backend_16后端的权重为10
www_random.add_backend(backend_17,5);   # 设置backend_17后端的权重为5


# 把backend_16 和 backend_17配置为固定后端集群 取名为www_hash 在recv调用时还需要添加东西 看recv例子
new www_hash = directors.hash();
www_hash.add_backend(backend_16,1);        # 设置backend_16后端的权重为1
www_hash.add_backend(backend_17,1);        # 设置backend_17后端的权重为1
}


#定义允许清理缓存的IP
acl purge {
# For now, I'll only allow purges coming from localhost
"127.0.0.1";
"localhost";
}

# 请求入口 这里一般用作路由处理 判断是否读取缓存 和 指定该请求使用哪个后端
sub vcl_recv {
##############################指定后端区域###########################
# 域名为 www.xxxxx.com 的请求 指定使用名为www_round_robin的后端集群  在集群名后加上 .backend() 如只使用单独后端 直接写后端名字即可 如 = backend_16;


if (req.http.host ~ "www.xxxxx.com") {
set req.backend_hint = www_round_robin.backend();
}


# 使用固定后端集群例子 使用名为www_hash的集群
if (req.http.host ~ "3g.xxxxx.com") {
set req.backend_hint = www_hash.backend(req.http.cookie);           # 根据用户的cookie来分配固定后端 可以指定其他分配规则
}


# 其他将使用default默认后端
#####################################################################
# 把真实客户端IP传递给后端服务器 后端服务器日志使用X-Forwarded-For来接收
if (req.restarts == 0) {
if (req.http.X-Forwarded-For) {
set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
} else {
set req.http.X-Forwarded-For = client.ip;
}
}


# 匹配清理缓存的请求
if (req.method == "PURGE") {

# 如果发起请求的客户端IP 不是在acl purge里面定义的 就拒绝
if (!client.ip ~ purge) {
return (synth(405, "This IP is not allowed to send PURGE requests."));
}

# 是的话就执行清理
return (purge);
}


# 如果不是正常请求 就直接穿透没商量
if (req.method != "GET" &&
req.method != "HEAD" &&
req.method != "PUT" &&
req.method != "POST" &&
req.method != "TRACE" &&
req.method != "OPTIONS" &&
req.method != "PATCH" &&
req.method != "DELETE") {
/* Non-RFC2616 or CONNECT which is weird. */
return (pipe);
}


# 如果不是GET和HEAD就跳到pass 再确定是缓存还是穿透
if (req.method != "GET" && req.method != "HEAD") {
return (pass);
}

# 缓存通过上面所有判断的请求 (只剩下GET和HEAD了)
return (hash);
}


# pass事件
sub vcl_pass {
# 有fetch,synth or restart 3种模式. fetch模式下 全部都不会缓存
return (fetch);
}


# hash事件(缓存事件)
sub vcl_hash {
# 根据以下特征来判断请求的唯一性 并根据此特征来缓存请求的内容 特征为&关系
# 1. 请求的url
# 2. 请求的servername 如没有 就记录请求的服务器IP地址
# 3. 请求的cookie
hash_data(req.url);
if (req.http.host) {
hash_data(req.http.host);
} else {
hash_data(server.ip);
}

# 返回lookup , lookup不是一个事件(就是 并非指跳去sub vcl_lookup) 他是一个操作 他会检查有没有缓存 如没有 就会创建缓存
return (lookup);
}


# 缓存命中事件 在lookup操作后自动调用 官网文档说 如没必要 一般不需要修改
sub vcl_hit {
# 可以在这里添加判断事件(if) 可以返回 deliver restart synth 3个事件
# deliver  表示把缓存内容直接返回给用户
# restart  重新启动请求 不建议使用 超过重试次数会报错
# synth    返回状态码 和原因 语法:return(synth(status code,reason))
# 这里没有判断 所有缓存命中直接返回给用户
return (deliver);
}


# 缓存不命中事件 在lookup操作后自动调用 官网文档说 如没必要 一般不需要修改
sub vcl_miss {
# 此事件中 会默认给http请求加一个 X-Varnish 的header头 提示: nginx可以根据此header来判断是否来自varnish的请求(就不用起2个端口了)
# 要取消此header头 只需要在这里添加 unset bereq.http.x-varnish; 即可
# 这里所有不命中的缓存都去后端拿 没有其他操作 fetch表示从后端服务器拿取请求内容
return (fetch);
}


# 返回给用户的前一个事件 通常用于添加或删除header头
sub vcl_deliver {
# 例子
# set resp.http.*    用来添加header头 如 set resp.http.xxxxx = "haha"; unset为删除
# set resp.status     用来设置返回状态 如 set resp.status = 404;
# obj.hits        会返回缓存命中次数 用于判断或赋值给header头
# req.restarts    会返回该请求经历restart事件次数 用户判断或赋值给header头
# 根据判断缓存时间来设置xxxxx-Cache header头
if (obj.hits > 0) {
set resp.http.xxxxx_Cache = "cached";
} else {
set resp.http.xxxxx_Cache = "uncached";
}

#取消显示php框架版本的header头
unset resp.http.X-Powered-By;

#取消显示nginx版本、Via(来自varnish)等header头 为了安全
unset resp.http.Server;
unset resp.http.X-Drupal-Cache;
unset resp.http.Via;
unset resp.http.Link;
unset resp.http.X-Varnish;

#显示请求经历restarts事件的次数
set resp.http.xxxxx_restarts_count = req.restarts;

#显示该资源缓存的时间 单位秒
set resp.http.xxxxx_Age = resp.http.Age;

#显示该资源命中的次数
set resp.http.xxxxx_hit_count = obj.hits;

#取消显示Age 为了不和CDN冲突
unset resp.http.Age;

#返回给用户
return (deliver);
}


#处理对后端返回结果的事件(设置缓存、移除cookie信息、设置header头等) 在fetch事件后自动调用
sub vcl_backend_response {
#后端返回如下错误状态码 则不缓存
if (beresp.status == 499 || beresp.status == 404 || beresp.status == 502) {
set beresp.uncacheable = true;
}

#如请求php或jsp 则不缓存
if (bereq.url ~ "\.(php|jsp)(\?|$)") {
set beresp.uncacheable = true;

#php和jsp以外的请求
}else{

#如请求html 则缓存5分钟
if (bereq.url ~ "\.html(\?|$)") {
set beresp.ttl = 300s;
unset beresp.http.Set-Cookie;

#其他缓存1小时 如css js等
}else{
set beresp.ttl = 1h;
unset beresp.http.Set-Cookie;
}
}


#开启grace模式 表示当后端全挂掉后 即使缓存资源已过期(超过缓存时间) 也会把该资源返回给用户 资源最大有效时间为6小时
set beresp.grace = 6h;

#返回给用户
return (deliver);
}


#返回给用户前的事件 可以在这里自定义输出给用户的内容
sub vcl_deliver {
}
```


<br>

#### <font size=4 color="#32CD99"> 使用varnishadm命令查看配置信息</font>


```bash
$ varnishadm -S /etc/varnish/secret -T 127.0.0.1:6082 # 登录管理命令行
varnish> vcl.list                 # 列出所有的配置
varnish> vcl.load test1 default.vcl  # 加载编译新配置，test1是配置名，default.vcl是配置文件
varnish> vcl.use test1            # 使用配置，需指定配置名，当前使用的配置以最后一次vcl.use为准
varnish> vcl.show test1           # 显示配置内容，需指定配置
```

<br>

#### <font size=4 color="#32CD99"> 配置样本 </font>

```
#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.
# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;
import directors;
probe backend_healthcheck {                 # 创建健康监测
    .url = /health.html;
    .window = 5;
    .threshold = 2;
    .interval = 3s;
}
backend web1 {                              # 创建后端主机
    .host = "web1.maxie.com";
    .port = "80";
    .probe = backend_healthcheck;
}
backend web2 {
    .host = "web2.maxie.com";
    .port = "80";
    .probe = backend_healthcheck;
}
backend img1 {
    .host = "img1.maxie.com";
    .port = "80";
    .probe = backend_healthcheck;
}
backend img2 {
    .host = "img2.maxie.com";
    .port = "80";
    .probe = backend_healthcheck;
}

vcl_init {                                  # 创建后端主机组，即directors
    new web_cluster = directors.random();
    web_cluster.add_backend(web1);
    web_cluster.add_backend(web2);
    new img_cluster = directors.random();
    img_cluster.add_backend(img1);
    img_cluster.add_backend(img2);
}

acl purgers {                               # 定义可使用pruger方法的来源IP
        "127.0.0.1";
        "172.16.0.0"/16;
}

sub vcl_recv {
    if (req.request == "GET" && req.http.cookie) {      # 带cookie首部的GET请求也缓存
        return(hash);
}
    if (req.url ~ "test.html") {                        # test.html文件禁止缓存
        return(pass);
    }
    if (req.request == "PURGE") {                       # PURGE请求的处理
        if (!client.ip ~ purgers) {
            return(synth(405,"Method not allowed"));
        }
        return(hash);
    }
    if (req.http.X-Forward-For) {                       # 为发往后端主机的请求添加X-Forward-For首部
        set req.http.X-Forward-For = req.http.X-Forward-For + "," + client.ip;
    } else {
        set req.http.X-Forward-For = client.ip;
    }
    if (req.http.host ~ "(?i)^(www.)?maxie.com$") {     # 根据不同的访问域名，分发至不同的后端主机组
        set req.http.host = "www.maxie.com";
        set req.backend_hint = web_cluster.backend();
      } elsif (req.http.host ~ "(?i)^images.maxie.com$") {
            set req.backend_hint = img_cluster.backend();
      }
        return(hash);
    }
sub vcl_hit {                                           # PURGE请求的处理
    if (req.request == "PURGE") {  
        purge;
        return(synth(200,"Purged"));
    }
}
sub vcl_miss {                                          # PURGE请求的处理
    if (req.request == "PURGE") {
        purge;
        return(synth(404,"Not in cache"));
    }
}
sub vcl_pass {                                          # PURGE请求的处理
    if (req.request == "PURGE") {
        return(synth(502,"PURGE on a passed object"));
    }
}
sub vcl_backend_response {                              # 自定义缓存文件的缓存时长，即TTL值
    if (req.url ~ "\.(jpg|jpeg|gif|png)$") {
        set beresp.ttl = 7200s;
    }
    if (req.url ~ "\.(html|css|js)$") {
        set beresp.ttl = 1200s;
    }
    if (beresp.http.Set-Cookie) {                       # 定义带Set-Cookie首部的后端响应不缓存，直接返回给客户端
        return(deliver);
    }
}
sub vcl_deliver {
    if (obj.hits > 0) {                                 # 为响应添加X-Cache首部，显示缓存是否命中
        set resp.http.X-Cache = "HIT from " + server.ip;
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
```


-------

{% note info %}### Varnish日志区域
{% endnote %}

####  <font size=3 color="#38B0DE"> varnishstat命令 </font>

 Varnish Cache statistics 查看统计数据
 
命令选项： 

```
-1                      显示一次的统计数据信息
-1 -f FILED_NAME        指定只显示指定段的信息，可以查看多个段，用空格分割，再加 -f FILED_NAME 即可
-l：可用于-f选项指定的字段名称列表；查看每个段的意义
```

实例：

```
$ varnishstat -1 -f MAIN.cache_hit -f MAIN.cache_miss
MAIN.cache_hit             110         0.00 Cache hits
MAIN.cache_miss             49         0.00 Cache misses
```

<br> 

####  <font size=3 color="#38B0DE"> varnishtop命令 </font>

Varnish log entry ranking 日志排序

命令选项：

```
-1                      仅显示一次日志(显示详细信息)
-i taglist              可以同时使用多个-i选项，也可以一个选项跟上多个标签
-I <[taglist:]regex>    正则表达式过滤日志
-x taglist              排除列表(黑名单)
-X  <[taglist:]regex>   排除列表 -- 基于正则表达式
-a file                 追加到指定文件中
-w filename             写到哪个文件中(覆盖)
```

<br> 

####  <font size=3 color="#38B0DE">varnishncsa命令</font>

以NCSA的格式输出日志

使用方法：

```
$ systemctl start varnishncsa.service
$ tail /var/log/varnish/varnishncsa.log
172.16.250.15 - - [27/Jun/2017:04:31:56 +0800] "GET http://172.16.3.10/index.php?=PHPE9568F35-D428-11d2-A769-00AA001ACF42 HTTP/1.1" 200 2146 "http://172.16.3.10/index.php" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:54.0) Gecko/20100101 Firefox/54.0"
```


-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=33913866&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)







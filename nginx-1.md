---
title: nginx从入门到进阶【一】
date: 2017-06-14 19:26:37
tags: [linux,nginx,web,http,server]
categories: Nginx
copyright: true
---

{% fullimage /images/nginx.jpg, nginx, %}

<blockquote class="blockquote-center">近几年来，Nginx逐步进入高速发展的时期，从各类主流的IT媒体到各大著名的IT论坛，我们不时能够看到它的身影。
经过逐步的改进，Nginx已成为一款高性能、功能完善、性能稳定的服务器产品。
</blockquote>

**<font size=3 color="#7093DB"> Nginx服务器以其功能丰富著称于世。</font>**

它既可以作为`http服务器`，也可以作为`反向代理服务器`；能够快速响应静态页面(HTML)的请求；支持FastCGI、SSL、Virtual Host、URL Rewirte、HTTP Basic Auth、Gzip等大量功能；并且`支持第三方`模块扩展。

在这篇博客中，我们主要对 `Nginx` 提供的 `HTTP`服务来讲解。

<!-- more -->

`Nginx`提供基本的`HTTP`服务，可以作为`HTTP`代理服务器和反向代理服务器，支持通过缓存加速访问，可以完成简单的负载均衡和容错，支持包过滤功能，支持SSL等。

![Nginx架构图](https://ws3.sinaimg.cn/large/006tNbRwly1fgkz0jup0mj30q80gbt9r.jpg)

上图是`Nginx`的整体架构图，下面我们就围绕着这张图，来讲解`Nginx`

-------

{% note primary %}### 安装Nginx
{% endnote %}

关于`Nginx`的安装，有两种方法，一种是编译安装，另一种则是使用官方提供的yum仓库进行安装。

为了更深入的了解`Nginx`，我们当然是选择编译安装了。不过在安装完成之后，我们还是会使用yum安装的`Nginx`来演示和讲解各种功能。

#### <font szie=4 color="#5F9F9F"> 下载源码包并解压 </font>

1、到`Nginx`的官方站点下载源码包：[下载地址](http://nginx.org/download/nginx-1.12.0.tar.gz)

2、拷贝到我们的虚拟机上并解压缩：

```
$ scp maxie@172.16.1.11:/Users/maxie/Downloads/nginx-1.12.0.tar ./
$ tar -xvf nginx-1.12.0.tar
```

#### <font szie=4 color="#5F9F9F"> 编译安装Nginx </font>

1、安装编译安装所需的开发组包：

```
$ cd nginx-1.12.0
$ yum -y groupinstall "Development Tools" "Server Platform Development"
$ yum -y install pcre-devel openssl-devel zlib-devel
```

2、开始生成Makefile文件：

```
$ ./configure --prefix=/usr/local/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--user=nginx --group=nginx \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_dav_module \
--with-http_stub_status_module \
--with-threads --with-file-aio
```
<br>
<font szie=3 color="#007FFF">**其中的各个选项的意义如下：**</font>

| 选项 | 说明 |
| --- | --- |
| —-prefix=PATH | 指定Nginx软件的安装路径。此项如果未指定，默认为/usr/local/nginx/目录 |
| —-conf-path=PATH | 在未给定 -c 选项下，指定默认的 nginx.conf 路径。如果未指定，默认为 prefix/conf/ |
| —-error-log-path=PATH | 在nginx.conf中未指定error_log指令的情况下，指定默认的错误日志路径。如果未指定，默认为 prefix/logs/error.log |
| —-http-log-path=PATH | 在nginx.conf中未指定access_log指令的情况下，指定默认的错误日志路径。如果未指定，默认为 prefix/logs/access.log |
| —-pid-path=PATH | 在nginx.conf中未指定pid指令的情况下，指定默认的 nginx.pid路径。nginx.pid保存了当前运行的Nginx服务的进程号 |
| —-lock-path=PATH | 指定nginx.lock文件的路径。nginx.lock是Nginx服务器的锁文件。如果未指定，默认为/var/lock目录 |
| -—user=USER | 在nginx.conf中未指定user指令的情况下，指定默认的Nginx服务器进程的属主用户，即Nginx进程运行的用户。如果未指定，默认为nobody。  |
| —-group=GROUP | 在nginx.conf中未指定group指令的情况下，指定默认的Nginx服务器进程的属主用户组，即Nginx进程运行的用户组。如果未指定，默认为nobody |
| —-with-http_ssl_module | 声明启用HTTP的ssl模块，这样Nginx服务器就可以支持HTTPS请求了。这个模块的正常运行需要安装 openssl库 |
| —-with-http_v2_module | 声明启用HTTPv2版本模块。 |
| —-with-http_dav_module | 声明启用HTTP的dav模块。默认不启用 |
| —-with-http_stub_status_module | 声明启用Server Status页。默认不启用 |
| —-with-threads | 声明启用线程池(1.7版本以上) |
| —-with-file-aio | 声明启用异步IO(0.8版本以上) |

<br>
#### [更多编译选项点击这里](#编译选项)
<br>

3、开始编译并安装

```
$ make              #编译
$ make install      #安装
```

-------


{% note success %}### Nginx配置文件详解
{% endnote %}

安装完成之后，让我们看一看`Nginx`生成了哪些配置文件

```
$ cd /etc/nginx/
$ ls
conf.d                  koi-utf             scgi_params
default.d               koi-win             scgi_params.default
fastcgi.conf            mime.types          uwsgi_params
fastcgi.conf.default    mime.types.default  uwsgi_params.default
fastcgi_params          nginx.conf          win-utf
fastcgi_params.default  nginx.conf.default
```

其中`nginx.conf`是主配置文件，`conf.d/`目录下是其他配置文件


#### <font szie=4 color="#5F9F9F"> 主配置文件介绍 </font>

让我们使用`vim`命令查看一下主配置文件：

```
$ vim /etc/nginx/nginx.conf
```

![](https://ws1.sinaimg.cn/large/006tNbRwly1fgl0lxboblj31h42zc4qr.jpg)

看了上面的图，想必不用我多解释了，各个配置段的内容以及生效范围，已经画出来了。

下面我们就对上面的各个配置段进行详细的介绍


#### <font szie=2 color="#D98719"> 全局块[Main] </font>

全局块是默认配置文件从开始到`events`块之间的一部分内容，主要设置一些影响Nginx服务器整体运行的配置命令，因此，这些指令的作用域是Nginx服务器全局。

**Main配置段常见的配置指令：**
        
        通过查看官方帮助文档中的 Core Functionnality 即可获得详细帮助
        
##### 正常运行必备的配置如下


1、user/group：用于配置运行`Nginx`服务器用户(组)的指令是user
```
user user [group];
默认为:
user nobody nobody;
```

2、pid：指定存储`Nginx`主进程进程号码的文件路径

```
pid /PATH/TO/PID_FILE;
```

3、include file | mask：指定包含进来的其他配置文件片段

4、load_module file：指明要装载的动态模块

5、sendfile on | off：直接在内核中发送响应报文，不经由用户空间

6、keepalive_timeout NUM：是否开启长连接模式，0为关闭

7、include /PATH/TO/SOME/DIR：包含哪些配置文件的目录

8、server_name：虚拟主机名; 

```
_;      表示匹配所有主机名
```

<br>
##### 性能优化相关的配置：

1、worker_processes number | auto;

```
worker进程的数量；通常应该为当前主机的cpu的物理核心数；应该小于等于当前主机的CPU的物理核心数;
auto：当前主机物理CPU核心数;
```

2、worker_cpu_affinity auto [cpumask];

```
绑定worker进程与CPU核心

CPU MASK：CPU掩码
00000001：0号CPU
00000010：1号CPU
... ...
```

3、worker_priority number;

```
指定worker进程的nice值，设定worker进程优先级；[-20,20]
```

4、worker_rlimit_nofile number;

```
worker进程所能够打开的文件数量上限；
```
<br>
##### 测试、定位选项配置

1、daemon on|off;	(在CentOS6上要开启)

```
是否以守护进程方式运行Nginx
```

2、master_process on|off; (调试使用，输出错误信息到屏幕)

```
是否以master/worker模型运行nginx；默认为on；
```

3、error_log file [level]; 错误日志级别



-------

#### <font szie=2 color="#D98719"> 事件驱动[events] </font>

1、worker_connections number;

```
每个worker进程所能够打开的最大并发连接数数量；
number = worker_processes * worker_connections
```

2、use method;

```
指明并发连接请求的处理方法；
默认使用:
use epoll;
```

3、accept_mutex on | off;	(互斥锁)


```
处理新的连接请求的方法；on意味着由各worker轮流处理新请求，Off意味着每个新请求的到达都会通知所有的worker进程；
		on：起点公平
		off：结果公平(更合理)
```

-------

{% note info %}### HTTP协议的相关配置
{% endnote %}

#### <font szie=3 color="#32CD99"> 与套接字相关的配置 </font>

1、server { ... }：配置一个虚拟主机

```
server {
    listen address[:PORT]|PORT;
    server_name SERVER_NAME;
    root /PATH/TO/DOCUMENT_ROOT;
    }
```



2、listen PORT|address[:port]|unix:/PATH/TO/SOCKET_FILE

```
default_server：设定为默认虚拟主机；
ssl：限制仅能够通过ssl连接提供服务；强制使用443
http2 | spdy：强制使用http协议
backlog=number：后援队列长度；
rcvbuf=size：接收缓冲区大小；
sndbuf=size：发送缓冲区大小；
```

3、server_name name ...;

```
指明虚拟主机的主机名称；后可跟多个由空白字符分隔的字符串；
支持*通配任意长度的任意字符；server_name *.magedu.com  www.magedu.*
支持~起始的字符做正则表达式模式匹配；server_name ~^www\d+\.magedu\.com$
	
匹配机制：
(1) 首先是字符串精确匹配;
(2) 左侧*通配符；
(3) 右侧*通配符；
(4) 正则表达式；
```


![](https://ws4.sinaimg.cn/large/006tNbRwly1fgl1lqps0pg30qk0fc7wo.gif)

配置文件如下：

```
server {
   listen          8080;
   server_name     www1.maxie.com;
   root            /web/www1/;
}
```

4、tcp_nodelay on | off;

```
在keepalived模式下的连接是否启用TCP_NODELAY选项；
当请求资源过小时，如果开启nodelay，则不管请求资源多小，都立即发送;
如果off，并开启keepalived，则等待请求好几个资源
```

5、tcp_nopush on | off;

```
在sendfile模式下，是否启用TCP_CORK选项;
在sendfile发送响应报文之前，等待用户空间把首部发过来之后，和响应报文+首部一起发给用户;
```



6、sendfile on | off;(默认开启on)
					
```
是否启用sendfile功能；
直接在内核中发送响应报文，不经由用户空间
```

<br>
#### <font szie=3 color="#32CD99"> 定义路径相关的配置 </font>

1、root path; (适用以下上下文 : http、server、location、if in location)

```
设置web资源路径映射；用于指明用户请求的url所对应的本地文件系统上的文档所在目录路径；
可用的位置：http, server, location, if
```

2、location [ = | ~ | ~* | ^~ ] uri { ... } 

```
其中的root可以继承于server，也可以自己创建，生效的最后是location自己定义的
	
在一个server中location配置段可存在多个，用于实现从uri到文件系统的路径映射；
ngnix会根据用户请求的URI来检查定义的所有location，并找出一个最佳匹配，而后应用其配置；
	
=：对URI做精确匹配；
~：对URI做正则表达式模式匹配，区分字符大小写；
~*：对URI做正则表达式模式匹配，不区分字符大小写；
^~：对URI的左半部分做匹配检查，不区分字符大小写；
不带符号：匹配起始于此uri的所有的url；
	
匹配优先级：=, ^~, ～/～*，不带符号；
```

3、alias path;

```
定义路径别名，文档映射的另一种机制；仅能用于location上下文；
注意：location中使用root指令和alias指令的意义不同；
	(a) root，给定的路径对应于location中的/uri/左侧的/；
	(b) alias，给定的路径对应于location中的/uri/右侧的
```

4、index file ...;

```
使用于http、server、location
```

5、error_page code ... [=[response]] uri;
 
```
自定义错误页
code：要处理的HTTP错误代码
response：可选项，将 code 指定的错误代码转化为新的错误代码 response
uri：错误页面的路径或者网站地址。如果设置为路径，则是以Nginx服务器安装路径下的html目录为根路径的相对路径; 如果设置为网址，则Nginx服务器会直接访问该网址获取错误页面，并返回给用户端
```

**实例：**

```
$ cd /etc/nginx
$ vim conf.d/maxie.conf
server {
        listen          8080;
        server_name     www1.maxie.com;

        location / {
                index   index.html index.htm;
                root /web/www1/;
        }

        location /images {
                alias /web/pic/;
        }

        location ~* /source {
                root /web/Source/;
        }

        error_page 404 http://www1.maxie.com:8080/404.html;
}
$ nginx -t
$ nginx -s reload
```

打开网页进行测试：

![](https://ws1.sinaimg.cn/large/006tKfTcly1fgl3m1s2r4g30qk0fc1l4.gif)

<br>
#### <font szie=3 color="#32CD99"> 定义客户端请求相关的配置 </font>

1、keepalive_timeout timeout [header_timeout];(时间维度)

```
设定保持连接的超时时长，0表示禁止长连接；默认为75s；
```

2、keepalive_requests number;(数量维度)

```
在一次长连接上所允许请求的资源的最大数量，默认为100; 
```

3、keepalive_disable none | browser ...;

```
对哪种浏览器禁用长连接；
```

4、send_timeout time;

```
向客户端发送响应报文的超时时长，此处，是指两次写操作之间的间隔时长；
```

5、client_body_buffer_size size;

```
用于接收客户端请求报文的'body部分的缓冲区大小'；默认为16k；超出此大小时，其将被暂存到磁盘上的由client_body_temp_path指令所定义的位置；
	如果是博客或者论坛站点,可以提高缓冲区大小;如果是电商站点,则使用默认即可.
```

6、client_body_temp_path path [level1 [level2 [level3]]];

```
设定用于存储客户端请求报文的body部分的临时存储路径及子目录结构和数量

分级缓存： 	通过hash(md5sum)进行生成校验码，取校验码的第一位作为一级子目录，以此类推；也可以取2位作为一级子目录
	client_body_temp_path /var/tmp/client_body  2 1 1 
		1：表示用一位16进制数字表示一级子目录；0-f：16个
		2：表示用2位16进程数字表示二级子目录：00-ff：16 * 256 个
		2：表示用2位16进程数字表示三级子目录：00-ff：16 * 256 * 256个
```

注意：启用此项会影响性能


实例：

```
$ vim conf.d/maxie.conf
server {
        listen          8080;
        server_name     www1.maxie.com;
        keepalive_timeout 30s;
        keepalive_requests 4;
        send_timeout 3s;

        client_body_buffer_size 8k;
        client_body_temp_path /web/cache 1 1 1;

        location / {
                index   index.html index.htm;
                root /web/www1/;
        }

        location /images {
                alias /web/pic/;
        }



        error_page 404 http://www1.maxie.com:8080/404.html;
}
```


<br>
#### <font szie=3 color="#32CD99"> 对客户端进行限制的相关配置 </font>

1、limit_rate rate;  (一般不开启)

```
限制响应给客户端的传输速率，单位是bytes/second，0表示无限制；
```

2、limit_except method ... { ... }


```
限制除这里定义的method以外的所有method对此location的动作
					
limit_except GET {
    deny 172.16.1.20;
    allow 172.16.0.0/16;
    deny  all;
}
```

实例：

```
$ vim conf.d/maxie.conf
server {
        listen          8080;
        server_name     www1.maxie.com;
        keepalive_timeout 30s;
        keepalive_requests 4;
        send_timeout 3s;

        client_body_buffer_size 8k;
        client_body_temp_path /web/cache 1 1 1;

        limit_rate 100;

        location  / {
                index   index.html index.htm;
                root /web/www1/;
                limit_except PUT {
                        deny 172.16.1.20;
                        allow 172.16.0.0/16;
                        deny all;
                }
        }

        location /images {
                alias /web/pic/;
        }
         error_page 404 http://www1.maxie.com:8080/404.html;
}
```

![](https://ws1.sinaimg.cn/large/006tNbRwly1fglmatxa6yg30qk0fcb2m.gif)


<font szie=4 color="#FF0000">总结</font>

```
1、开启 limit_rate 之后，客户端访问网站资源明显变慢，对用户体验极差，不建议开启;
2、开启 limit_except 之后，可以对用户访问网站的请求方法进行限制，可以设置成只允许用户有 GET、HEAD、POST等方法的权限;
3、limit_except METHOD:表示此方法所有人都可以方法，但是除了此方法以外的其他方法，只允许在其中设置的 allow 的用户IP使用。
```




<br>
#### <font szie=3 color="#32CD99"> 文件操作优化的相关配置 </font>


1、aio on | off | threads[=pool];  (一般都要启用)

```
是否启用aio功能(异步IO)
```

2、directio size | off;

```
在Linux主机启用O_DIRECT标记，此处意味文件大于等于给定的大小时使用，例如directio 4m;
```

3、open_file_cache off; | open_file_cache max=N [inactive=time];

```
nginx可以缓存以下三种信息：
(1) 文件的描述符、文件大小和最近一次的修改时间；
(2) 打开的目录结构；
(3) 没有找到的或者没有权限访问的文件的相关信息；
	
max=N：可缓存的缓存项上限；达到上限后会使用LRU算法实现缓存管理；
缓存多少个文件
'LRU：最近最少使用算法'

inactive=time：缓存项的非活动时长，在此处指定的时长内未被命中的或命中的次数少于open_file_cache_min_uses指令所指定的次数的缓存项即为非活动项
```

4、open_file_cache_valid time;

```
缓存项有效性的检查频率；默认为60s;
检查非活动时长频率 
```

5、open_file_cache_min_uses number;

```
在open_file_cache指令的inactive参数指定的时长内，至少应该被命中多少次方可被归类为活动项；
```

6、open_file_cache_errors on | off;

```
是否缓存查找时发生错误的文件一类的信息；
```

实例：

```
$ vim conf.d/maxie.conf
server {
        listen          8080;
        server_name     www1.maxie.com;
        keepalive_timeout 30s;
        keepalive_requests 4;
        send_timeout 3s;

        client_body_buffer_size 8k;
        client_body_temp_path /web/cache 1 1 1;

        limit_rate 100;
        
        aio on;
        directio 5m;
                        
        location / {
                index   index.html index.htm;
                root /web/www1/;
        }

        location /images {
                alias /web/pic/;
                open_file_cache max=10 inactive=20s;
                open_file_cache_valid 50s;
                open_file_cache_min_uses 2;
                open_file_cache_errors on;
                }
         error_page 404 http://www1.maxie.com:8080/404.html;
}
```



<br>
#### <font szie=3 color="#32CD99"> 其他配置 </font>

1、实现基于用户的访问控制，使用basic机制进行用户认证

auth_basic string | off;
auth_basic_user_file file;

```
安装http-tools工具包：
$ yum install -y httpd-tools

使用htpasswd生成认证用户文件：
$ htpasswd -c -m /etc/nginx/.ngxpasswd tom
$ htpasswd -m /etc/nginx/.ngxpasswd jerry

编辑虚拟主机配置文件：
$ vim conf.d/maxie.conf
$ vim conf.d/maxie.conf
server {
        listen          8080;
        server_name     www1.maxie.com;
        keepalive_timeout 30s;
        keepalive_requests 4;
        send_timeout 3s;

        client_body_buffer_size 8k;
        client_body_temp_path /web/cache 1 1 1;

        limit_rate 100;
        
        aio on;
        directio 5m;
                        
        location / {
                index   index.html index.htm;
                root /web/www1/;
        }

        location /images {
                alias /web/pic/;
                open_file_cache max=10 inactive=20s;
                open_file_cache_valid 50s;
                open_file_cache_min_uses 2;
                open_file_cache_errors on;
                
                auth_basic "Admin Area";
                auth_basic_user_file /etc/nginx/.ngxpasswd;
                }
         error_page 404 http://www1.maxie.com:8080/404.html;
}
```

![](https://ws4.sinaimg.cn/large/006tNbRwly1fgl61r850lg30qk0fcqvc.gif)


<br>

2、使用ngx_http_stub_status_module模块输出nginx的基本状态信息

```
$ vim conf.d/maxie.conf
在最后一个location的后面添加下面这条
location /ngx_status {
                stub_status;
        }
    
$ nginx -t
$ nginx -s reload
```

![](https://ws2.sinaimg.cn/large/006tNbRwly1fgl66b164xg30qk0fc1l0.gif)

其中的各个信息的详细解释：

| Active connections  | 活动状态的连接数 |
| --- | --- |
| accepts | 已经接受的客户端请求的总 |
| handled | 已经处理完成的客户端请求的总数 |
| requests | 客户端发来的总的请求数 |
| Reading | 处于读取客户端请求报文首部的连接的连接数 |
| Writing | 处于向客户端发送响应报文过程中的连接数 |
| Waiting | 处于等待客户端发出请求的空闲连接数 |


3、使用ngx_http_log_module模块自定义`Nginx`日志

* log_format name string ...; 只能定义在http段中，不能在server段中配置

```
string可以使用nginx核心模块及其他模块内嵌的变量
```

日志格式变量：

| 变量 | 意义 |
| --- | --- |
| $remote | 记录客户端的IP地址 |
| $remote_user | 记录客户端用户名  |
| $request | 记录请求的URL和HTTP协议 |
| $status | 记录请求状态 |
| $body_bytes_sent | 发送给客户端的字节数，不包括响应头的大小  |
| $connection | 连接的序列号 |
| $connection_requests | 当前通过一个连接获得的请求数量 |
| $msec | 日志写入时间。单位为秒，精度是毫秒 |
| $pipe | 如果请求是通过HTTP流水线(pipelined)发送，pipe值为”p”，否则为”." |
| $http_referer | 记录从哪个页面链接访问过来的 |
| $http_user_agent | 记录客户端浏览器相关信息 |
| $request_length | 请求的长度(包括请求行，头部、正文) |
| $request_time | 请求处理时间，单位为秒，精度毫秒 |
| $time_iso8601 | ISO8601标准格式下的本地时间 |
| $time_local | 通用格式下的本地时间 |


* access_log path [format [buffer=size] [gzip[=level]] [flush=time] [if=condition]];


```
可以在单独的location中关闭日志功能;
访问日志文件路径，格式及相关的缓冲的配置；
buffer=size：接收缓冲区大小，防止磁盘IO过大导致性能降低;
flush=time ：刷新时间
```

使用`Nginx`日志格式变量定义类似于httpd的combined格式的访问日志：

```
$ vim /etc/nginx/nginx.conf
在http段添加如下信息：
log_format  mylog   '$remote_addr - $remote_user [$time_local] "$request"'
                    '$status - "$http_server" "$http_user_agent"';

$ vim /etc/nginx/conf.d/maxie.conf
在server段添加：
access_log              /var/log/nginx/www1/access.log  mylog;
在status段添加：(关闭状态信息的记录日志)
location /ngx_status {
                stub_status;
                access_log off;
        }
```

* open_log_file_cache max=N [inactive=time] [min_uses=N] [valid=time];

```
缓存各日志文件相关的元数据信息（加速读操作)

max：缓存的最大文件描述符数量；
min_uses：在inactive指定的时长内访问大于等于此值方可被当作活动项；
inactive：非活动时长；
valid：验正缓存中各缓存项是否为活动项的时间间隔；
```


**实例：**

```
$ vim /etc/nginx/conf.d/maxie.conf
server {
        listen                  8080;
        server_name             www1.maxie.com;
        keepalive_timeout       30s;
        keepalive_requests      4;
        send_timeout            3s;

        client_body_buffer_size 8k;
        client_body_temp_path   /web/cache 1 1 1;

        #limit_rate 100;

        aio                     on;
        directio                5m;

        access_log              /var/log/nginx/www1/access.log  mylog buffer=16k flush=30s;
        open_log_file_cache     max=1000 inactive=20s min_uses=2 valid=60s;

        location / {
                index   index.html index.htm;
                root /web/www1/;
        }


        location /images/ {
                alias /web/pic/;
                open_file_cache max=10 inactive=20s;
                open_file_cache_valid 50s;
                open_file_cache_min_uses 2;
                open_file_cache_errors on;

                auth_basic "Admin Area";
                auth_basic_user_file /etc/nginx/.ngxpasswd;
        }


        location /ngx_status {
                stub_status;
                access_log off;
        }

        error_page 404 http://www1.maxie.com:8080/404.html;

}
```


-------

<br>
#### <font szie=3 color="#32CD99"> gzip相关的配置 </font>

如果要查看`Nginx`支持的压缩格式有哪些：

```
$ cat /etc/nginx/mime.types

types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    application/javascript                js;
    application/atom+xml                  atom;
    application/rss+xml                   rss;

    text/mathml                           mml;
    text/plain                            txt;
    text/vnd.sun.j2me.app-descriptor      jad;
    text/vnd.wap.wml                      wml;
    text/x-component                      htc;

    image/png                             png;
    image/tiff                            tif tiff;
    image/vnd.wap.wbmp                    wbmp;
    image/x-icon                          ico;
    image/x-jng                           jng;
    image/x-ms-bmp                        bmp;
    image/svg+xml                         svg svgz;
    image/webp                            webp;

    application/font-woff                 woff;
    application/java-archive              jar war ear;
    application/json                      json;
    application/mac-binhex40              hqx;
    application/msword                    doc;
    application/pdf                       pdf;
    application/postscript                ps eps ai;
    application/rtf                       rtf;
    application/vnd.apple.mpegurl         m3u8;
    application/vnd.ms-excel              xls;
    application/vnd.ms-fontobject         eot;
    application/vnd.ms-powerpoint         ppt;
    application/vnd.wap.wmlc              wmlc;
    application/vnd.google-earth.kml+xml  kml;
    application/vnd.google-earth.kmz      kmz;
    application/x-7z-compressed           7z;
    application/x-cocoa                   cco;
    application/x-java-archive-diff       jardiff;
    application/x-java-jnlp-file          jnlp;
    application/x-makeself                run;
    application/x-perl                    pl pm;
    application/x-pilot                   prc pdb;
    application/x-rar-compressed          rar;
    application/x-redhat-package-manager  rpm;
    application/x-sea                     sea;
    application/x-shockwave-flash         swf;
    application/x-stuffit                 sit;
    application/x-tcl                     tcl tk;
    application/x-x509-ca-cert            der pem crt;
    application/x-xpinstall               xpi;
    application/xhtml+xml                 xhtml;
    application/xspf+xml                  xspf;
    application/zip                       zip;

    application/octet-stream              bin exe dll;
    application/octet-stream              deb;
    application/octet-stream              dmg;
    application/octet-stream              iso img;
    application/octet-stream              msi msp msm;

    application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
    application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;

    audio/midi                            mid midi kar;
    audio/mpeg                            mp3;
    audio/ogg                             ogg;
    audio/x-m4a                           m4a;
    audio/x-realaudio                     ra;

    video/3gpp                            3gpp 3gp;
    video/mp2t                            ts;
    video/mp4                             mp4;
    video/mpeg                            mpeg mpg;
    video/quicktime                       mov;
    video/webm                            webm;
    video/x-flv                           flv;
    video/x-m4v                           m4v;
    video/x-mng                           mng;
    video/x-ms-asf                        asx asf;
    video/x-ms-wmv                        wmv;
    video/x-msvideo                       avi;
}
```


1、gzip on | off; 是否开启gzip压缩功能

2、gzip_comp_level LEVEL; 压缩比

```
默认为1,可以设置1-9之间
```

3、gzip_disable regex ...;

```
针对不同种类客户端发起的请求，可以选择性的开启和关闭gzip功能。(0.6.23版本以上)
其中 regex 根据客户端的浏览器标志(User-Agent,UA)进行设置，支持使用正则表达式
```

##### 以下是常见的PC以及手机浏览器的UA字符串

```
桌面

============================================

IE
  而IE各个版本典型的userAgent如下：
  Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)
  Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2)
  Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)
  Mozilla/4.0 (compatible; MSIE 5.0; Windows NT)
  其中，版本号是MSIE之后的数字。

注：MSIE后面跟的数字为IE的版本号，如MSIE 8.0代表IE8, Windows NT 6.1 对应操作系统 windows 7

Windows NT 6.0 对应操作系统 windows vista 　
Windows NT 5.2 对应操作系统 windows 2003 　　
Windows NT 5.1 对应操作系统 windows xp 　　
Windows NT 5.0 对应操作系统 windows 2000   

UNIX/LINUX下的为X11代替，具体可以从网上找下，百度百科上也有的。

Firefox
  Firefox几个版本的userAgent大致如下：
  Mozilla/5.0 (Windows; U; Windows NT 5.2) Gecko/2008070208 Firefox/3.0.1
  Mozilla/5.0 (Windows; U; Windows NT 5.1) Gecko/20070309 Firefox/2.0.0.3
  Mozilla/5.0 (Windows; U; Windows NT 5.1) Gecko/20070803 Firefox/1.5.0.12  其中，版本号是Firefox之后的数字。
注：N: 表示无安全加密 　　I: 表示弱安全加密 　　U: 表示强安全加密     上面的U代表加密等级

Opera
  Opera典型的userAgent如下：
  Opera/9.27 (Windows NT 5.2; U; zh-cn)
  Opera/8.0 (Macintosh; PPC Mac OS X; U; en)
  Mozilla/5.0 (Macintosh; PPC Mac OS X; U; en) Opera 8.0 
  其中，版本号是靠近Opera的数字。

Safari
  Safari典型的userAgent如下：
  Mozilla/5.0 (Windows; U; Windows NT 5.2) AppleWebKit/525.13 (KHTML, like Gecko) Version/3.1 Safari/525.13
  Mozilla/5.0 (iPhone; U; CPU like Mac OS X) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A93 Safari/419.3
  其版本号是Version之后的数字。

Chrome
  目前，Chrome的userAgent是：
Mozilla/5.0 (Windows; U; Windows NT 5.2) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.2.149.27 Safari/525.13 
  其中，版本号在Chrome之后的数字。

Navigator
目前，Navigator的userAgent是：
Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.12) Gecko/20080219 Firefox/2.0.0.12 Navigator/9.0.0.6
其中，版本号在Navigator之后的数字。

360SE                                                                                                                                                                  Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727; 360SE)


360

[USER_AGENT] => Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; 360SE)

360极速浏览器

[USER_AGENT] => Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ;  QIHU 360EE)

傲游浏览器

[USER_AGENT] => Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; Maxthon/3.0)

TT

[USER_AGENT] => Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; TencentTraveler 4.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) )

safari

[USER_AGENT] => Mozilla/5.0 (Windows NT 5.1) AppleWebKit/534.55.3 (KHTML, like Gecko) Version/5.1.5 Safari/534.55.3

==============================

移动

==============================

安卓 QQ浏览器

Mozilla/5.0 (Linux; U; Android 4.0.3; zh-cn; M032 Build/IML74K) AppleWebKit/533.1 (KHTML, like Gecko)Version/4.0 MQQBrowser/4.1 Mobile Safari/533.1

安卓 原生浏览器

Mozilla/5.0 (Linux; U; Android 4.0.3; zh-cn; M032 Build/IML74K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30

安卓 UC

Mozilla/5.0 (Linux; U; Android 4.0.3; zh-cn; M032 Build/IML74K) UC AppleWebKit/534.31 (KHTML, like Gecko) Mobile Safari/534.31

安卓 Opera

Opera/9.80 (Android 4.0.3; Linux; Opera Mobi/ADR-1210241554) Presto/2.11.355 Version/12.10

三星手机

SAMSUNG-SGH-G508E/G508EZCIG2 SHP/VPP/R5 NetFront/3.4 Qtv5.3 SMM-MMS/1.2.0 profile/MIDP-2.0 configuration/CLDC-1.1

iphone safria

Mozilla/5.0 (iPhone; CPU iPhone OS 5_1_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B206 Safari/7534.48.3

iphone QQ

MQQBrowser/38 (iOS 4; U; CPU like Mac OS X; zh-cn)

iphone UC

IUC(U;iOS 5.1.1;Zh-cn;320*480;)/UCWEB8.9.1.271/42/800

塞班 自带浏览器

Nokia5320/04.13 (SymbianOS/9.3; U; Series60/3.2 Mozilla/5.0; Profile/MIDP-2.1 Configuration/CLDC-1.1 ) AppleWebKit/413 (KHTML, like Gecko) Safari/413

塞班 QQ浏览器

Nokia5320(19.01)/SymbianOS/9.1 Series60/3.0
```

4、gzip_min_length LENGTH;

```
Gzip压缩功能能对大数据的压缩效果明显，但是如果压缩很小的数据，可能会出现越压缩数据量越大的情况(参考本站之前关于压缩的文章)。
因此应该根据响应页面的大小，选择性的开启或关闭Gzip功能。

该指令设置页面的字节数，当响应页面的大小小于该值时，不启用Gzip功能。
默认值为20，0为不管响应页面的大小如何一律压缩。
```

[本站--压缩解压缩详解](http://maxiecloud.com/2017/04/08/compression-tool/)

5、gzip_buffers NUMBER SIZE;

```
该指令用于设置Gzip压缩文件使用缓存空间的大小
number：指定Nginx服务器需要向系统申请缓存空间的个数
size：指定每个缓存空间的大小

默认情况下：number * size = 128k
所以设置为：
gzip_buffers 32 4k | 16 8k;
```

6、gzip_proxied off | expired | no-cache | no-store | private | no_last_modified | no_etag | auth | any ...;


```
当Nginx作为反向代理服务器时有效;
主要用于设置Nginx服务器是否对后端服务器返回的结果进行Gzip压缩。
```

**各参数详解：**

| 指令 | 意义 |
| --- | --- |
| off | 关闭Nginx服务器对后端服务器返回结果的Gzip压缩(默认设置) |
| expired | 当后端服务器相应页头部包含用于指示响应数据过期时间的expired 头域时，启用对响应数据的Gzip压缩 |
| no-cache | 当后端.......包含用于通知所有缓存机制是否缓存的Cache-Control头域、且指令值为no-cache时，启用对响应数据的Gzip压缩 |
| no-store | 当后端.......包含用于通知所有缓存机制是否缓存的Cache-Control头域、且指令值为no-store时，启用对响应数据的Gzip压缩  |
| private | 当后端.......包含用于通知所有缓存机制是否缓存的Cache-Control头域、且指令值为private时，启用对响应数据的Gzip压缩 |
| no_last_modified | 当后端服务器响应页头部不包含用于指明需要获取数据最后修改时间的Last-Modified头域时，启用对响应数据的Gzip压缩  |
| no_etag | 当后端服务器响应页头部不包含用于标示被请求变量的实体值得ETag头域时，启用对响应数据的Gzip压缩 |
| auth | 当后端服务器响应页头部包含用于标示HTTP授权证书的Authorization头域时，启用对响应数据的Gzip压缩 |
| any | 无条件启用对后端服务器响应数据的Gzip压缩 |


7、gzip_types mime-type ...;

```
压缩过滤器，仅对此处设定的MIME类型的内容启用压缩功能(默认对text/html开启功能)
mime-type我们在开篇就介绍了，请自行查找
```


8、gzip_vary on | off;

```
该指令用于设置在使用Gzip功能时，是否发送带有"Vary: Accept-Encoding"头域的响应头部。
该头域的主要功能是告诉接收方发送的数据经过了压缩处理
默认设置为 off。

我们也可以通过Nginx配置的add_header指令强制达到这种效果
add_header Vary Accept-Encoding gzip;
```

*注意：该指令在使用过程中存在bug，会导致IE4及以上浏览器的数据缓存功能失效。*


实例：

```
$ vim /etc/nginx/conf.d/maxie.conf
添加一条location：
location /log {
                root /web/www1/;
                gzip on;
                gzip_comp_level 6;
                gzip_min_length 1024;
                gzip_proxied any;
                gzip_types text/xml text/css application/javascript;
                gzip_vary on;
        }
$ cp /var/log/nginx/access.log /web/www1/log/index.html
$ nginx -t
$ nginx -s reload
```

![](https://ws2.sinaimg.cn/large/006tNbRwly1fglnrggdh8g30qk0fche5.gif)



-------

<br>
#### <font szie=3 color="#32CD99"> HTTP + SSL 相关的配置 </font>

HTTPS建立连接的过程：

```
TCP三次握手 --> Clinet hello --> 服务器回复 (Server Hello) --> 服务端发送公钥 --> Certificate Status --> 客户端验证证书 --> 密钥交换 --> 传输数据
```

<font color="#FF0000"> **注意：ssl的所有设置只能在http、server中设置**</font>

1、ssl on | off;

```
是否开启SSL功能
为了强制开启此功能，需要在监听端口设置443以后，在443 之后加上 ssl --> listen 443 ssl;
```

2、ssl_certificate file;

```
当前虚拟主机使用PEM格式的证书文件路径
```

3、ssl_certificate file;

```
当前虚拟主机上与其证书匹配的私钥文件路径
```

4、ssl_protocols [SSLv2] [SSLv3] [TLSv1] [TLSv1.1] [TLSv1.2];

```
支持ssl协议的版本
```

5、ssl_session_cache off | none | [builtin[:size]] [shared:name:size];

```
ssl缓存设置
builtin[:size]：使用OpenSSL內建的缓存，此缓存为每个worker进程私有
shared:name:size：在各个worker之间使用一个共享的缓存

shared的目的是为了使缓存更加有效
```

6、ssl_session_timeout time;

```
客户端一侧的连接可以复用ssl session cache中缓存 的ssl参数的有效时长；
```

7、ssl_ciphers;

```
ssl的加密算法 --> 使用 openssl cipheres命令可以获得最全的加密算法表

ssl_ciphers ALL:!aNULL:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
```

默认我们使用如下配置即可：

```
ssl_ciphers HIGH:!aNULL:!MD5;
```

-------

<br>

##### <font size=2 color="#A67D3D"> 在Nginx上配置一个https</font>


1、自建CA

```
$ cd /etc/pki/CA/
$ (umask 077;openssl genrsa -out /etc/pki/CA/private/cakey.pem 4096)
$ openssl req -new -x509 -key /etc/pki/CA/private/cakey.pem -out /etc/pki/CA/cacert.pem -days 3650
$ touch {serial,index.txt}
$ echo 01 > serial
```

2、生成ssl签署请求，并让CA签署

```
$ mkdir -pv /etc/nginx/ssl 
$ cd /etc/nginx/ssl 
$ (umask 077;openssl genrsa -out /etc/nginx/ssl/nginx.key 4096)
$ openssl req -new -key /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.csr -day 550
$ openssl ca -in /etc/nginx/ssl/nginx.csr -out /etc/nginx/ssl/nginx.crt
```

3、编辑虚拟主机配置文件：使其开启 SSL功能

```
$ cd /etc/nginx
$ vim conf.d/maxie.conf
添加如下信息在server段内：
ssl                     on;
        ssl_certificate         /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key     /etc/nginx/ssl/nginx.key;
        ssl_session_timeout     1m;
        ssl_protocols           SSLv2 SSLv3 tlsv1 tlsv1.2;
        ssl_session_cache       shared:ssl_cache:10m;
        ssl_ciphers             HIGH:!aNULL:!MD5;
        
并修改listen：
listen 443 ssl;

$ nginx -t
$ nginx -s reload
```

4、将CA公钥拷贝至客户端，并导入浏览器，测试


```
$ scp /etc/pki/CA/cacert.pem maxie@172.16.1.11:/Users/maxie/
```

![](https://ws2.sinaimg.cn/large/006tNbRwly1fglos1uabbg30qk0fce8a.gif)

**配置文件：**

```
$ vim conf.d/maxie.conf
server {
	listen 			443 ssl;
	server_name		www1.maxie.com;
	keepalive_timeout 	30s;
	keepalive_requests 	4;
	send_timeout		3s;

	ssl			on;
	ssl_certificate		/etc/nginx/ssl/nginx.crt;
	ssl_certificate_key	/etc/nginx/ssl/nginx.key;
	ssl_session_timeout	1m;
	ssl_protocols		SSLv2 SSLv3 tlsv1 tlsv1.2;
	ssl_session_cache	shared:ssl_cache:10m;
	ssl_ciphers		HIGH:!aNULL:!MD5;


	client_body_buffer_size 8k;
	client_body_temp_path 	/web/cache 1 1 1;

	#limit_rate 100;

	aio			on;
	directio		5m;



	access_log		/var/log/nginx/www1/access.log	mylog buffer=16k flush=30s;
	open_log_file_cache	max=1000 inactive=20s min_uses=2 valid=60s;



	location  / {
		index	index.html index.htm;
		root /web/www1/;
		limit_except PUT {
			deny 172.16.1.20;
			allow 172.16.0.0/16;
			deny all;
		}
	}


	location /images/ {
		alias /web/pic/;
		open_file_cache max=10 inactive=20s;
		open_file_cache_valid 50s;
		open_file_cache_min_uses 2;
		open_file_cache_errors on;

		auth_basic "Admin Area";
		auth_basic_user_file /etc/nginx/.ngxpasswd;

	}


	location /ngx_status {
		stub_status;
		access_log off;

	}

	location /log {
		root /web/www1/;
		gzip on;
		gzip_comp_level 6;
		gzip_min_length 1024;
		gzip_proxied any;
		gzip_types text/xml text/css application/javascript;
		gzip_vary on;
	}

	error_page 404 http://www1.maxie.com:8080/404.html;

}
```




-------

{% note warning %}### Nginx服务器的Rewrite功能
{% endnote %}

Nginx中关于Rewirte功能非常多，这里我们只介绍其中的`rewrite指令`、`return指令`、`if (conndition){...}指令`

#### <font size=4 color="#7093DB"> rewirte指令 </font>

该指令通过正则表达式的使用来改变URL。可以同时存在一个或者多个指令。按照顺序依次对URL进行匹配和处理。

<font color="#FF0000">提示：URL和URI的区别和联系</font>

```
URI（Universal Resource Identifier，通用资源标识符），用于对网络中的各种资源进行标识，由存放资源的主机名、片段标志和相对URI三部分组成。存放资源的主机名一般由传输协议(Scheme),主机和资源路径三部分组成；片段标志符指向资源内容的具体元素；相对URI表示资源在主机上的相对路径。一般格式为：Scheme:[//][用户名[:密码]]@主机名[:端口号][/资源路径]

URL（Uniform Resource Location，统一资源定位符），是用于Internet中描述资源的字符串，是URI的子集，主要包括传输协议(Scheme)，主机(IP,端口或者域名)和资源具体地址(目录和文件名)等三部分。一般格式为：Scheme://主机名[:端口号][/资源路径]
```
<br>
指令的语法结构：

```
rewrite regex replacement [flag]
```

将用户请求的URI基于regex所描述的模式进行检查，匹配到时将其替换为replacement指定的新的URI；
					
<font color="#FF0000">*注意：如果在同一级配置块中存在多个rewrite规则，那么会自下而下逐个检查；被某条件规则替换完成后，会重新一轮的替换检查，因此，隐含有循环机制；[flag]所表示的标志位用于控制此循环机制；*		</font>	

<br>		

1、regex：用于匹配URI的正则表达式，使用括号"( )"标记要截取的内容

2、replacement：匹配成功后用于替换URI中被截取内容的字符。默认情况下，如果该字符是由`http://`或者`https://`开头的，则不会继续向下对URI进行其他处理，而直接将重写后的URI返回给客户端。

3、flag：用来设置rewrite对URI的处理行为，可以为以下标志中的一个：

```
last：重写完成后停止对当前URI在当前location中后续的其它重写操作，而后对新的URI启动新一轮重写检查；提前重启新一轮循环； 
break：重写完成后停止对当前URI在当前location中后续的其它重写操作，而后直接跳转至重写规则配置块之后的其它配置；结束循环；
redirect：重写完成后以临时重定向方式直接返回重写后生成的新URI给客户端，由客户端重新发起请求；不能以http://或https://开头；
permanent:重写完成后以永久重定向方式直接返回重写后生成的新URI给客户端，由客户端重新发起请求；
```

<br>
**实例1：**

如果要实现全站https则使用如下配置：

```
先把nginx.conf主配置文件内的server注释掉或者删除

编辑虚拟主机配置文件
$ vim conf.d/maxie.conf
在https的server段之前再添加一个80的server段：
server {
    listen 80;
    server_name www1.maxie.com;
    rewrite ^(.*)$ https://${server_name}$1 permanent;
}
```

<font color="#FF0000"> 这里注意不要在https的server块之中配置rewrite，需要在用户只要访问默认80端口时，直接重写URL即可</font>

<br>
**实例2：**

只要访问本站的任何`.jpg文件`都重写至`.png文件`

```
$ vim conf.d/maxie.conf
添加如下location：
location /png {
                root /web/pic/;
                rewrite /(.*)\.jpg /$1.png;
        }

拷贝png文件至/web/pic/png目录
$ scp maxie@172.16.1.11:/Users/maxie/Download/Netfilter-packet-flow.svg.png /web/pic/png/net.jpg

$ nginx -t
$ nginx -s reload
```

![](https://ws3.sinaimg.cn/large/006tNbRwly1fgluffcb6vg30qk0fce8b.gif)


<br>

#### <font size=4 color="#7093DB"> return指令 </font>

该指令用于完成对请求的处理，直接向客户端返回响应状态代码。`处于该指令后`的所有Nginx配合都是`无效的`。
该指令可以在server块和location块以及if块中使用

**语法结构如下：**

```
return code [ text ];
return code URL;
return URL;
```

<br>
1、code：为返回给客户端的HTTP状态代码。可以返回的状态代码为`0 ~ 999`的任意HTTP状态代码。非标准的444代码可以强制关闭服务器与客户端的连接而不返回任何响应信息给客户端。

2、text：为返回给客户端的响应体内容，支持变量的使用

3、URL：为返回给客户端的URL地址

其中当`code`使用 301（表示被请求资源永久移动到新的位置）， 302（表示请求的资源限制临时从不同的URL响应，要求使用GET方式请求）。

<br>
##### 实例

```
$ vim conf.d/maxie.conf
添加以下信息：
error_page 404 https://www1.maxie.com/404.html;
        location ~* 404.html {
                return 505;
        }
$ nginx -t 
$ nginx -s reload
```

![](https://ws3.sinaimg.cn/large/006tNbRwly1fglvsur411g30qk0fcx71.gif)




<br>

#### <font size=4 color="#7093DB"> if (conndition) 指令 </font>

该指令用来支持条件判断，并根据条件判断结果选择不同的Nginx配置，可以在server块或者location块中配置该指令。

**语法格式：**

```
if (conndition) { ... }
```

其中花括号代表一个作用域，形成一个`if`配置块，是条件为真时的Nginx配置。

`condition`：为判断条件(true/false)，它可以支持以下几种设置方法：

##### 变量名

```
如果变量的值为空字符串或者以"0"开头的任意字符串，if指令认为条件为false，其他情况认为条件为true。

if ($slow) {        #这里slow变量是一个布尔值的变量，如果为1则执行如下的Nginx配置；反之，不执行
    ...             #Nginx配置
}
```

##### 比较操作符

使用比较操作符，比较变量和字符串是否相等；相等时`if`条件为true；反之为false

```
==      是否相等
!=      是否不相等
~       模式匹配，区分字符大小写；
~*      模式匹配，不区分字符大小写；
!~      模式不匹配，区分字符大小写；
!~*     模式不匹配，不区分字符大小写；
```

**例子：**

<font color="#23238E"> 如果请求方法是POST，返回405代码 </font>
```
if ($request_method = POST) {       
    return 405;
}
```

<font color="#23238E"> 如果用户agent内包含curl字符串，返回404代码 </font>
```
if ($http_user_agent ~ curl) {
                return 404;
        }
```

##### 文件及目录存在性判断

**各判断符详解**

| -f | 如果请求的文件存在，if指令认为条件为true;反之，为false |
| --- | --- |
| !-f   | 如果请求的文件不存在，但是文件所在的目录存在，if指令认为条件为true；如果两者都不存在，或者请求的文件存在，则为false |
| -e | 如果请求的目录或者文件存在时，if指令认为条件为true，否则为false |
| !-e | 如果请求的文件和该文件所在路径上的目录都不存在，为true，否则为false |
| -d | 如果请求的目录存在，if指令认为条件为true；反之，为false |
| !-d   | 如果请求的目录不存在，但该目录的上级目录存在，if指令认为条件为true；如果该目录和他的上级目录都不存在，或者请求的目录存在，则为false； |
| -x     | 如果请求的文件可执行，if指令认为条件为true，否则为false |
| !-x | 如果请求的文件不可执行，为true；反之，为false |



**实例**


<font color="#23238E"> 如果请求的文件不存在，则返回404响应码 </font>

```
if (!-f $request_filename) {
    return 404;
   }
```



<br>

#### <font size=4 color="#7093DB"> referer模块 </font>

该模块经常被我们用来做网站的`防盗链`，是很有效的。

**语法格式**

```
valid_referers none | blocked | server_names | string ...;
```

各个参数详解：

```
none                请求报文首部没有referer首部
blocked             请求报文的referer首部没有值
server_names        服务器主机名
arbitrary_string    直接字符串，但可使用*作通配符
regular expression  被指定的正则表达式模式匹配到的字符串；要使用~打头，例如 ~.*\.maxie\.com;
```

**实例：**

```
$ vim conf.d/maxie.conf
location ~* \.(jpg|png|gif|bmp)$ {
                valid_referers          none block server_names *.maxie.com maxie.*;
                if ($invalid_referer) {
                        return http://www1.maxie.com/403.png;
                }
        }

location = /403.png {           #单独定义403.png，防止循环过多
      root /web/www1;
}

新建一个虚拟主机引用maxie.com的图片
$ vim conf.d/www2.conf
server {
        listen          80;
        server_name     www2.ilinux.com;
        root /web/www2/;
        location / {
                try_files $uri $uri/ index.html;
        }

}
$ mkdir -p /web/www2
$ vim /web/www2/index.html
<h2> www2.maxiecloud.com </h2>

<img src="https://www1.maxie.com/png/java.png"/>        #引用maxie.com上的java.png这个图片资源


$ nginx -t
$ nginx -s reload

配置完成之后打开浏览器检测
```

![](https://ws2.sinaimg.cn/large/006tNbRwly1fglz57ua3jg30qk0fcx73.gif)



-------

{% note danger %}### 到此我们的 Nginx 从入门到进阶【一】就算讲完了
{% endnote %}


#### 以上所有配置完成后的配置文件

##### 代码版

```
[root@test-2 nginx]# cat conf.d/maxie.conf
server {
    listen 80;
    server_name www1.maxie.com;
    return 301 https://www1.maxie.com$request_uri;
}

server {
	listen 			443 ssl;
	server_name		www1.maxie.com;
	keepalive_timeout 	30s;
	keepalive_requests 	4;
	send_timeout		3s;


	ssl			on;
	ssl_certificate		/etc/nginx/ssl/nginx.crt;
	ssl_certificate_key	/etc/nginx/ssl/nginx.key;
	ssl_session_timeout	1m;
	ssl_protocols		SSLv2 SSLv3 tlsv1 tlsv1.2;
	ssl_session_cache	shared:ssl_cache:10m;
	ssl_ciphers		HIGH:!aNULL:!MD5;


	client_body_buffer_size 8k;
	client_body_temp_path 	/web/cache 1 1 1;

	#limit_rate 100;

	aio			on;
	directio		5m;

	access_log		/var/log/nginx/www1/access.log	mylog buffer=16k flush=30s;
	open_log_file_cache	max=1000 inactive=20s min_uses=2 valid=60s;



	location  / {
		try_files $uri $uri/ /index.html;
		root /web/www1/;
		limit_except PUT {
			deny 172.16.1.20;
			allow 172.16.0.0/16;
			deny all;
		}

	}

	location /images {
		alias /web/pic;
		open_file_cache max=10 inactive=20s;
		open_file_cache_valid 50s;
		open_file_cache_min_uses 2;
		open_file_cache_errors on;

		auth_basic "Admin Area";
		auth_basic_user_file /etc/nginx/.ngxpasswd;

	}


	location ~* \.(jpg|png|gif|bmp)$ {
		valid_referers		none block server_names *.maxie.com maxie.*;
		if ($invalid_referer) {
			return http://www1.maxie.com/403.png;
		}
	}

	location = /403.png {
		root /web/www1;
	}

	location /ngx_status {
		stub_status;
		access_log off;

	}

	location /log {
		root /web/www1/;
		gzip on;
		gzip_comp_level 6;
		gzip_min_length 1024;
		gzip_proxied any;
		gzip_types text/xml text/css application/javascript;
		gzip_vary on;
	}

	location /png {
		root /web/pic/;
		rewrite /(.*)\.jpg /$1.png;
	}


	if ($http_user_agent ~ curl) {
		return 404;
	}

	error_page 404 https://www1.maxie.com/404.html;
}
```

资源路径：

```
[root@test-2 nginx]# tree /web
/web
├── cache
├── pic
│   ├── 2.jpg
│   ├── 3.jpg
│   ├── images
│   │   └── index.html
│   └── png
│       ├── java.png
│       └── net.png
├── Source
│   └── source
│       ├── nginx-1.10.2-1.el7.ngx.x86_64.rpm
│       ├── nginx-1.12.0-1.el7.ngx.x86_64.rpm
│       ├── nginx-1.12.0.tar
│       ├── nginx-1.12.0.tar.gz
│       ├── nginx-module-geoip-1.10.2-1.el7.ngx.x86_64.rpm
│       └── nginx.vim
├── www1
│   ├── 403.png
│   ├── 404-file
│   │   └── 404.jpeg
│   ├── 404.html
│   ├── hello.jpg
│   ├── index.html
│   └── log
│       └── index.html
└── www2
    └── index.html

10 directories, 18 files
```

##### 图片详解版

<font size=3 color="#FF0000">图片可能分辨率过大，为了您的用户体验：请右键在新标签页中打开，或者下载之后查看</font> 

![](https://ws2.sinaimg.cn/large/006tNbRwly1fgm14s79yhj31kw2rsu0y.jpg)


-------

### 编译选项


| 选项 | 说明 |
| --- | --- |
| --sbin-path=path | 设置nginx的可执行文件的路径，默认为  prefix/sbin/nginx. |
| --with-select_module | 启用一个模块来允许服务器使用select()方法 |
| --without-select_module | 禁用一个模块来允许服务器使用select()方法 |
| --with-poll_module | 启用一个模块来允许服务器使用poll()方法 |
| --without-poll_module | 禁用一个模块来允许服务器使用poll()方法 |
| --without-http_gzip_module | 不编译压缩的HTTP服务器的响应模块。编译并运行此模块需要zlib库。 |
| --without-http_rewrite_module | 不编译重写模块。编译并运行此模块需要PCRE库支持。 |
| --without-http_proxy_module | 不编译http_proxy模块。 |
| --with-pcre=path | 设置PCRE库的源码路径。 |
| --with-cc-opt=parameters | 设置额外的参数将被添加到CFLAGS变量 |
| --with-ld-opt=parameters | 设置附加的参数，将用于在链接期间 |
| --with-http_sub_module | 启用sub模块。支持URL重定向功能 |
| --with-http_memcached_module | 启用memcache缓存 |


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=28798452&auto=0&height=66"></iframe>


本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)














---
title: Tomcat实现会话保持功能
date: 2017-07-03 08:48:12
tags: [tomcat,java,session,cluster]
categories: [linux进阶,tomcat,session]
copyright: true
---

![](https://ws3.sinaimg.cn/large/006tKfTcly1fh6f3kqbjcj30xc0m8q4w.jpg)

> 上一节我们简单的介绍了如何使用Tomcat作为动态Web服务器
> 以及使用nginx/httpd服务器反向代理Tomcat和负载均衡Tomcat
> 
> 在这一章节，我们将介绍如何使用Tomcat自带的Clustering/Session Replication实现会话保持功能
> 以及使用memcached对Tomcat实现session server功能


### 实验之前的准备

#### 准备虚拟机

为了能正常的实现我们这里准备的3个实验，计划准备五台虚拟机

```
Director        172.16.3.10/16
Tomcat-1        172.16.3.20/16
Tomcat-2        172.16.3.50/16
Memcached-1     172.16.3.60/16
Memcached-2     172.16.3.70/16
```

建议每台Tomcat的内存分配的尽可能大一些，建议4GB

#### 同步时间

在操作多台机器实现一个功能/目标时，需要将其时间同步

```
$ ntpdate 172.16.0.1
```

#### 制作网络拓扑图











-------


<!-- more -->

{% note info %}### 使用nginx/httpd负载均衡Tomcat并实现会话保持
{% endnote %}


#### <font size=4 color="#38B0DE">配置nginx+Tomcat集群以实现会话保持</font>

* 安装nginx并配置虚拟主机

```bash
$ yum -y install nginx 
$ cd /etc/nginx/
$ vim conf.d/maxie.conf
upstream tomcatsrv {
    ip_hash;                        #这里还可以设置成： hash $requset_uri consistent; 或者 hash $cookie_name consistent;
    server  172.16.3.20:80;
    server  172.16.3.50:80;
}
server {
    listen 80;
    server_name www1.maxie.com;
    location / {
        proxy_pass  http://www1.maxie.com;
    }
}
```

<br>

* 配置Tomcat主机

```bash
$ yum install -y java-1.8.0-openjdk-devel tomcat tomcat-webapps tomcat-admin-webapps tomcat-docs-webapp
$ vim /etc/tomcat/tomcat.users.xml
<role rolename="admin-gui"/>
<user username="tomcat" password="tomcat" roles="admin-gui"/>
<role rolename="manager-gui"/>
<user username="maxie" password="maxie" roles="manager-gui"/>

# 创建测试页
$ mkdir /usr/share/tomcat/webapps/test/{classes,META-INF,WEB-INF}
$ vim /usr/share/tomcat/webapps/test/index.jsp
<%@ page language="java" %>
<%@ page import="java.util.*" %>
<html>
    <head>
        <title>Server One</title>
    </head>
    <body>
        <font size=10 color="#38B0DE" > Tomcat First Server  </font>
        <table align="centre" border="1">
        <tr>
                <td>Session ID</td>
                <% session.setAttribute("maxie.com","maxie.com"); %>
                <td><%= session.getId() %></td>
        </tr>
        <tr>
                <td>Created on</td>
                        <td><%= session.getCreationTime() %></td>
                </tr>
        </table>
        <br>
        <% out.println("hello world");
        %>
    </body>
</html>

# 将/etc/tomcat/tomcat.users.xml与/usr/share/tomcat/webapps/test发送至另一台Tomcat主机
$ scp /etc/tomcat/tomcat.users.xml root@172.16.3.50:/etc/tomcat/
$ scp -rp /usr/share/tomcat/webapps/test root@172.16.3.50:/usr/share/tomcat/webapps/

# 在第二台上修改之前拷贝过来的文件内容
$ vim /usr/share/tomcat/webapps/test/index.jsp
<%@ page language="java" %>
<%@ page import="java.util.*" %>
<html>
    <head>
        <title>Server Two</title>
    </head>
    <body>
        <font size=10 color="#32CD99" > Tomcat Second Server  </font>
        <table align="centre" border="1">
        <tr>
                <td>Session ID</td>
                <% session.setAttribute("maxie.com","maxie.com"); %>
                <td><%= session.getId() %></td>
        </tr>
        <tr>
                <td>Created on</td>
                        <td><%= session.getCreationTime() %></td>
                </tr>
        </table>
        <br>
        <% out.println("hello world");
        %>
    </body>
</html>

# 启动两台Tomcat服务
$ systemctl start tomcat
$ ss -tnl
State       Recv-Q Send-Q Local Address:Port               Peer Address:Port
LISTEN      0      50              *:3306                        *:*
LISTEN      0      128             *:22                          *:*
LISTEN      0      128     127.0.0.1:631                         *:*
LISTEN      0      100     127.0.0.1:25                          *:*
LISTEN      0      100            :::8009                       :::*
LISTEN      0      100            :::8080                       :::*
LISTEN      0      128            :::22                         :::*
LISTEN      0      128           ::1:631                        :::*
LISTEN      0      100           ::1:25                         :::*
LISTEN      0      1        ::ffff:127.0.0.1:8005                       :::*
```

<br>

* 打开浏览器验证即可

最终效果应为：通过调度器分配了一台Tomcat服务器之后，除非IP变动，否则将一直调度在这台Tomcat服务器上。



<br>

#### <font size=4 color="#38B0DE">配置httpd+Tomcat集群以实现会话保持</font>

* 安装并配置httpd

```
$ yum install -y httpd
$ vim /etc/httpd/conf.d/maxie.conf
Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED

<proxy balancer://tcsrvs>
	BalancerMember http://172.16.3.20:8080 route=TomcatA loadfactor=1 
	BalancerMember http://172.16.3.50:8080 route=TomcatB loadfactor=2			
	ProxySet lbmethod=byrequests
	ProxySet stickysession=ROUTEID
</Proxy>

<VirtualHost *:80>
	ServerName www1.maxie.com
	ProxyVia On
	ProxyRequests Off
	ProxyPreserveHost On
	<Proxy *>
		Require all granted
	</Proxy>
	ProxyPass / balancer://tcsrvs/
	ProxyPassReverse / balancer://tcsrvs/
	<Location />
		Require all granted
	</Location>
</VirtualHost>	
```

* Tomcat主机无需修改配置，直接打开浏览器验证即可


-------


{% note success %}### Tomcat Session Replication Cluster
{% endnote %}

实验之前，将nginx/httpd的会话保持的配置段删除，只保留调度功能

```
upstream tomcatsrv {
	server	172.16.3.20:8080;
	server	172.16.3.50:8080;
}
server {
	listen	80;
	server_name	www1.maxie.com;
	location / {
		proxy_pass	http://tomcatsrv;
	}
}
```

#### <font size=4 color="#32CD99">配置Tomcat内建的Clustering/Session Replication</font>

* 修改Tomcat的server.xml配置

```bash
$ vim /etc/tomcat/server.xml
在<Host>段中添加如下信息：

<Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"
		channelSendOptions="8">

	<Manager className="org.apache.catalina.ha.session.DeltaManager"
		expireSessionsOnShutdown="false"
		notifyListenersOnReplication="true"/>

	<Channel className="org.apache.catalina.tribes.group.GroupChannel">
	<Membership className="org.apache.catalina.tribes.membership.McastService"
	       address="228.16.3.10"
	       port="45564"
	       frequency="500"
	       dropTime="3000"/>
	<Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver"
	    address="172.16.3.20"			#另一台Tomcat为 172.16.3.50
            port="4000"
            autoBind="100"
            selectorTimeout="5000"
            maxThreads="6"/>

	<Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">
	<Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender"/>
	</Sender>
	<Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector"/>
	<Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatch15Interceptor"/>
	</Channel>

	<Valve className="org.apache.catalina.ha.tcp.ReplicationValve"
		filter=""/>
	<Valve className="org.apache.catalina.ha.session.JvmRouteBinderValve"/>

	<Deployer className="org.apache.catalina.ha.deploy.FarmWarDeployer"
		tempDir="/tmp/war-temp/"
		deployDir="/tmp/war-deploy/"
		watchDir="/tmp/war-listen/"
		watchEnabled="false"/>

	<ClusterListener className="org.apache.catalina.ha.session.JvmRouteSessionIDBinderListener"/>
	<ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener"/>
</Cluster>	
```

<br>

* 优化Tomcat

```bash
$ vim /etc/sysconfig/tomcat
# 增加栈空间大小
JAVA_OPTS="-server -Xms1g -Xmx1g"
```

![](https://ws1.sinaimg.cn/large/006tKfTcly1fh6h3og6n7j31gc160kjl.jpg)

<br>

* 创建测试页的web.xml配置文件，使其支持session replication功能

```bash
$ cp /etc/tomcat/web.xml /usr/share/tomcat/webapps/test/WEB-INF/
$ vim /usr/share/tomcat/webapps/test/WEB-INF/web.xml
在<servlet>段上面添加一条：
<distributable/>

$ systemctl restart tomcat
```

<br>

* 拷贝修改的配置至另一台Tomcat服务器之上

```
$ scp /etc/tomcat/server.xml  root@172.16.3.50:/etc/tomcat/
$ scp /etc/sysconfig/tomcat root@172.16.3.50:/etc/sysconfig/
$ scp /usr/share/tomcat/webapps/test/WEB-INF/web.xml root@172.16.3.50:/usr/share/tomcat/webapps/test/WEB-INF/
```

* 两台Tomcat重启服务

* 打开浏览器输入 http://www1.maxie.com 检查效果

![](https://ws2.sinaimg.cn/large/006tKfTcly1fh6gjasbdng30qo0ushdx.gif)




-------


{% note info %}### Tomcat + Memcached 实现session server
{% endnote %}

实验之前需要将上一个实验中的 server.xml中的 session replication的配置段删除

memcached连接器下载地址：[下载地址](连接器下载地址：http://repo1.maven.org/maven2/de/javakaffee/msm/)

####  <font size=3 color="#38B0DE">安装并配置memcached</font>

* 安装memcached

```
$ yum install -y memcached
```

* 查看memcached配置文件，并修改

```bash
$ vim /etc/sysconfig/memcached
PORT="11211"                # 监听端口
USER="memcached"            # 运行时的用户
MAXCONN="2048"              # 最大连接数，默认为1024
CACHESIZE="1024"            # 缓存内存大小，默认为64M
OPTIONS=""
```

* 启动服务

```
$ systemctl start memcached
$ ss -tnl
```

<br>

####  <font size=3 color="#38B0DE">配置Tomcat</font>

* 修改server.xml配置文件

```
$ vim /etc/tomcat/server.xml
在<Host>段添加如下信息：
<Context path="/test" docBase="test" reloadable="true" >
	<Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager"
	    memcachedNodes="mem1:172.16.3.60:11211,mem2:172.16.3.70:11211"
	    failoverNodes="mem2"
	    requestUriIgnorePattern=".*\.(ico|png|gif|jpg|css|js)$"
	    transcoderFactoryClass="de.javakaffee.web.msm.serializer.javolution.JavolutionTranscoderFactory"
	/>
</Context>

# 将配置文件发送到另一台Tomcat服务器
$ scp /etc/tomcat/server.xml root@172.16.3.50:/etc/tomcat/
```


* 下载所需的jar包

[spymemcached-2.11.1](http://repo1.maven.org/maven2/net/spy/spymemcached/2.11.1/spymemcached-2.11.1.jar)
[memcached-session-manager-2.1.1](http://repo1.maven.org/maven2/de/javakaffee/msm/memcached-session-manager/2.1.1/)
[memcached-session-manager-tc7-2.1.1](http://repo1.maven.org/maven2/de/javakaffee/msm/memcached-session-manager-tc7/2.1.1/)
[msm-javolution-serializer-2.1.1](http://repo1.maven.org/maven2/de/javakaffee/msm/msm-javolution-serializer/2.1.1/)
[javolution-5.4.3.1](http://www.manyjar.com/download?storeName=j/javolution/javolution-5.4.3.1.jar.zip)


```
$ cd /usr/share/java/tomcat
$ wget ftp://172.16.0.1/pub/Sources/7.x86_64/msm/*
$ rm -f memcached-session-manager-tc8-1.8.3.jar

# 传送jar包到另一台Tomcat
$ scp javolution-5.4.3.1.jar memcached-session-manager-* spymemcached-2.11.1.jar msm-javolution-serializer-1.8.3.jar root@172.16.3.50:/usr/share/java/tomcat/
```

* 重新启动两台Tomcat服务，并打开网页进行测试

![](https://ws1.sinaimg.cn/large/006tKfTcly1fh6hlav63fg30qo0ushdx.gif)


-------

{% note warning %}### JVM常用的分析工具
{% endnote %}

#### 安装oracle JDK 


```
$ lft 172.16.0.1/pub/Sources
> get 7.x86_64/jdk/jdk-8u25-linux-x64.rpm
$ yum install ./jdk-8u25-linux-x64.rpm 
$ vim /etc/profile.d/java.sh
export JAVA_HOME=/usr/java/latest
export PATH=$JAVA_HOME/bin:$PATH
$ . /etc/profile.d/java.sh
```

#### 安装Tomcat


```
$ lftp 172.16.0.1/pub/Sources
$ tar -xf apache-tomcat-8.0.23.tar.gz -C /usr/local/
$ cd /usr/local/
$ ln -sv apache-tomcat-8.0.23/ tomcat
$ useradd -r tomcat
$ chown -R tomcat.tomcat tomcat/
$ vim /etc/profile.d/
export CATALINA_BASE=/usr/local/tomcat 
export PATH=$CATALINA_BASE/bin:$PATH
```

#### 启动Tomcat

```
$ useradd -r tomcat 
$ su - tomcat -c '/usr/local/tomcat/catalina.sh start'
$ ss -tnl
```

#### 使用自带工具进行检测


```bash
jps             用来查看运行的所有jvm进程
jinfo           查看进程的运行环境参数，主要是jvm命令行参数
jstat           对jvm应用程序的资源和性能进行实时监控
jstack          查看所有线程的运行状态
jmap            查看jvm占用物理内存的状态
jconsole        图形化管理工具
jvisualvm       oracle JDK提供的图形化监测工具
```

* jps

```
$ jps
32474 Jps
2508 Bootstrap
```

<br>

* jinfo

![](https://ws4.sinaimg.cn/large/006tKfTcly1fh6i33rx1uj31ho3o0u12.jpg)

<br>

* jstat

```
$ jstat -gc 2508
 S0C    S1C    S0U    S1U      EC       EU        OC         OU       MC     MU    CCSC   CCSU   YGC     YGCT    FGC    FGCT     GCT
832.0  832.0   0.0    26.7   7168.0   5669.3   17552.0    13746.6   15616.0 14968.1 1792.0 1631.2     19    0.383   1      0.021    0.404
```

<br>

* jmap

![](https://ws1.sinaimg.cn/large/006tKfTcly1fh6i5y3a67j31iq0s4x6p.jpg)

<br>

* jconsole

![](https://ws2.sinaimg.cn/large/006tKfTcly1fh6i6mr2nbj30p20l3wf6.jpg)

![](https://ws1.sinaimg.cn/large/006tKfTcly1fh6i6mlatrj30p20l30tc.jpg)

<br>

* jvisualvm

![](https://ws1.sinaimg.cn/large/006tKfTcly1fh6i6zc6vyj30x10m2q3i.jpg)

![](https://ws3.sinaimg.cn/large/006tKfTcly1fh6i6z6rmyj30x10m2t9e.jpg)



-------



<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=26092806&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)








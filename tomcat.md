---
title: tomcat从入门到进阶
date: 2017-07-01 08:16:11
tags: [tomcat,java,balance,linux]
categories: [linux进阶,tomcat]
copyright: true
---


<blockquote class="blockquote-center">Tomat是由Apache软件基金会下属的Jakarta项目开发的一个Servlet容器。由于Tomcat本身也包含了一个HTTP服务器，它可以被视作一个单独的WEB服务器。不过HTTP服务器是C语言实现的Web服务器，而Tomcat则是由Java编写。
</blockquote>

什么是`Servlet`呢？ `Servlet`，全称 Java Servlet，是用Java编写的服务器端程序，主要功能在于交互式的浏览和修改数据，生成动态Web内容。

**JSP代码运行过程**

> index.jsp --> 由jasper转换 --> index_jsp.java --> 通过javac编译器 --> 生成类文件 index_jsp.class --> 在(engine上)jvm虚拟机上运行
> 基于jsp将静态输出的数据转为java代码进行输出，结果为Servlet规范的代码

![](https://ws1.sinaimg.cn/large/006tNc79ly1fh435gsf2fj318g0qktb4.jpg)

**Java代码运行过程**
> *.java --> javac --> *.class(bytecode字节码)

**JVM运行时区域**

```
方法区         用于存储被JVM加载的class信息、常量、静态变量，方法等
堆            是jvm所管理的内存中占用空间最大的一部分，也是GC管理的主要区域，用来存储对象信息
栈            线程私有，存储线程自己的局部变量
PC寄存器       线程私有的内存空间，程序的指令指针
GC            垃圾回收，回收堆中不再使用的空间
```


-------

<!-- more -->

{% note primary %}### JDK
{% endnote %}

在Linux下想要运行`tomcat`，就必须依赖`JDK`环境了，这里我们使用的JDK版本是 `java-1.8.0-openjdk`。openjdk是jdk的一个分支，也是其开源的项目。

### <font szie=4 color="#236B8E">安装JDK </font>

由于使用的是`Centos 7`，所以在base仓库就已经提供了3种openjdk版本：

```
$ yum list all *jdk*
java-1.6.0-openjdk
java-1.7.0-openjdk
java-1.8.0-openjdk
```

这里我们使用`java-1.8.0-openjdk`版本


```
$ yum install java-1.8.0-openjdk
$ java -version
```

为了防止其他程序要使用`java`时找不到`JAVA_HOME`，我们这里手动配置`JAVA_HOME`

```
$ vim /etc/profile.d/java.sh
export JAVA_HOME=/usr
$ . /etc/profile.d/java.sh
```

如果是使用`Oracle`版本的JDK，其默认安装在`/usr/java/jdk_VERSION`路径下

```
$ vim /etc/profile.d/java.sh
export JAVA_HOME=/usr/java/jdk_VERSION
export PATH=$JAVA_HOME/bin:$PATH
$ . /etc/profile.d/java.sh
```


安装完`jdk`之后，我们就可以开始安装和配置Tomcat了！


-------


{% note success %}### Tomcat安装与配置
{% endnote %}

#### <font size=4 color="#32CD99">安装Tomcat</font>

* 使用base仓库安装

```
$ yum install -y tomcat tomcat-lib tomcat-admin-webapps tomcat-webapps tomcat-docs-webapp
```

* 使用官方二进制版本安装

```
$ wget http://mirrors.hust.edu.cn/apache/tomcat/tomcat-8/v8.5.16/bin/apache-tomcat-8.5.16.tar.gz
$ tar -xf  apache-tomcat-8.5.16.tar.gz -C /usr/local/
$ cd /usr/local
$ ln -sv apache-tomcat-8.5.16 tomcat
```
注意这里使用软连接的方式，是为了生产环境中，如果需要版本升级时，可以很好的进行替换操作，只需将连接修改至新版本即可。

如果使用了二进制版本安装，我们就需要手动添加环境变量了：

```
$ vim /etc/profile.d/tomcat.sh 
export CATALINA_BASE=/usr/local/tomcat 
export PATH=$CATALINA_BASE/bin:$PATH
$ . /etc/profile.d/tomcat.sh
```

<br>


#### <font size=4 color="#32CD99">Tomcat程序环境 </font>

**tomcat的目录结构**

```
bin         脚本，及启动时用到的类
conf        配置文件目录
lib         库文件，Java类库，jar
logs        日志文件目录
temp        临时文件目录
webapps     webapp的默认目录
work        工作目录
ROOT        存放主站的文件，就是访问 / 的显示的页面
```

<br>

**rpm包安装的程序环境**


```
配置文件目录：/etc/tomcat
主配置文件：/etc/tomcat/server.xml
认证用户配置文件：/etc/tomcat/tomcat-users.xml
webapps存放位置：/var/lib/tomcat/webapps/
Unit File：/usr/lib/systemd/system/tomcat.service
环境配置文件：/etc/sysconfig/tomcat
```

<br>

**运行Tomcat进程的用户**

```
默认为tomcat用户，但无权监听80端口
```

<br>

**使用authbind程序使tomcat用户可以监听80端口**

```
$ wget https://s3.amazonaws.com/aaronsilber/public/authbind-2.1.1-0.1.x86_64.rpm
$ yum install -y ./authbind-2.1.1-0.1.x86_64.rpm
$ chmod 755 /etc/authbind/port/80 
$ chown test.test /etc/authbind/port/80 
$ authbind --deep systemctl restart tomcat
```

[authbind-github下载](https://github.com/tootedom/authbind-centos-rpm)

<br>

**tomcat的配置文件**

```
配置文件路径          /etc/tomcat/conf 

server.xml          主配置文件
web.xml             每个webapp只有"部署"后才能被访问，它的部署方式通常由web.xml进行定义，其存放位置为WEB-INF/目录中；此文件为所有的webapps提供默认部署相关的配置
context.xml         每个webapp都可以专用的配置文件，它通常由专用的配置文件context.xml来定义，其存放位置为WEB-INF/目录中；此文件为所有的webapps提供默认配置
tomcat-users.xml    用户认证的账号和密码文件
catalina.policy     当使用-security选项启动tomcat时，用于为tomcat设置安全策略；
catalina.properties Java属性的定义文件，用于设定类加载器路径，以及一些与JVM调优相关参数
logging.properties  日志系统相关的配置
```

<br>

**二进制安装中 catalina.sh脚本使用方法**

```
debug             测试模式
debug -security   安全策略的测试模式
run               运行为守护进程
run -security     安全策略模式启动
start             运行为守护进程
start  -security  安全策略模式启动
stop              停止
stop n            等待几秒后停止
stop -force       强制停止
stop n -force     几秒后强制停止
version           版本

$ catalina.sh start         #启动tomcat
$ catalina.sh version       #查看tomcat版本
```

<br>

#### <font size=4 color="#32CD99">JSP WebAPP的组织结构 </font>

```
路径                 /var/lib/tomcat/webapps

/                   webapps的根目录
    index.jsp       主页文件
    WEB-INF/        当前webapp的'私有资源路径'；通常用于存储当前webapp的web.xml和context.xml配置文件
    META-INF/       类似于WEB-INF/
    classes/        类文件，当前webapp所提供的类
    lib/            类文件，当前webapp所提供的类，被打包为jar格式
```


<br>

#### <font size=4 color="#32CD99">部署deploy webapp的相关操作</font>


```
deploy      将webapp的源文件放置于目标目录(网页程序文件存放目录)，配置tomcat服务器能够基于web.xml和context.xml文件中定义的路径来访问此webapp
undeploy    反部署，停止webapp，并从tomcat实例上卸载webapp
start       启动处于停止状态的webapp
stop        停止webapp，不再向用户提供服务；其类依然在jvm上
redeploy    重新部署
```

**部署有两种方式**

```bash
自动部署：auto deploy(可能需要重启)
手动部署:
	冷部署：把webapp复制到指定的位置，而后才启动tomcat
	热部署：在不停止tomcat的前提下进行部署

部署工具：manager、ant脚本、tcd(tomcat client deployer)等
```


<br>

#### <font size=4 color="#32CD99">tomcat的两个管理应用</font>

**manager**

```bash
不用关闭tomcat，完成webapp的热部署
使用此功能，需要先配置用户和密码：
	conf/tomcat-user.xml
	$ vim tomcat-user.xml
	<role rolename="manager-gui">
	<user username="tomcat" password="tomcat" roles="manager-gui" />

	修改完之后，重启tomcat
	$ systemctl restart tomcat 

	expire session：清除超过指定时间的会话

	只要把webapp放到路径下，然后在网页控制页面中的deploy填写 /test /test2 类似这样
	并创建WEB-INF、META-INF、index.jsp即可
```

<br>

**host-manager**

```bash
此管理应用，需要另一个配置。
	<role rolename="admin-gui">n
	<user username="tomcat" password="tomcat" roles="admin-gui" />

但是在这里通过图形化界面添加的 虚拟主机，重启tomcat后，就会失效，需要定义在 server.xml
```



<br>

#### <font size=4 color="#32CD99">Tomcat的常用组件配置</font>


```bash
Server：代表tomcat instance，即表现出的一个java进程；监听在8005端口，只接收“SHUTDOWN”。各server监听的端口不能相同，因此，在同一物理主机启动多个实例时，需要修改其监听端口为不同的端口
Service：用于实现将一个或多个connector组件关联至一个engine组件

Connector组件：
    负责接收请求，常见的有三类http/https/ajp；

    进入tomcat的请求可分为两类：
    	(1) standalone : 请求来自于客户端浏览器；
    	(2) 由其它的web server反代：来自前端的反代服务器；
    		nginx --> http connector --> tomcat 
    		httpd(proxy_http_module) --> http connector --> tomcat
    		httpd(proxy_ajp_module) --> ajp connector --> tomcat 
    		http(mod_jk) --> ajp connector --> tomcat 
    
    参数：
        address：监听的IP地址；默认为本机所有可用地址
        maxThreads：最大并发连接数，默认为200
        enableLookups：是否启用DNS查询功能
        acceptCount：等待队列的最大长度
        
Engine组件：
    Servlet实例，即servlet引擎，其内部可以一个或多个host组件来定义站点； 通常需要通过defaultHost来定义默认的虚拟主机
    
Host组件：
    位于engine内部用于接收请求并进行相应处理的主机或虚拟主机
    
    参数：
        (1)'appBase'：此Host的'webapps的默认存放目录'，指存放非归档的web应用程序的目录或归档的WAR文件目录路径；可以使用基于$CATALINA_BASE变量所定义的路径的相对路径；
        (2) autoDeploy：在Tomcat处于运行状态时，将某webapp放置于appBase所定义的目录中时，是否'自动将其部署至tomcat；'
        (3) unpackWARs：是否自动解开 WAR 文件

注意：'这里如果是新建的HOST，主页的文件资源必须放在appBase指定的目录下的ROOT目录下，否则将无法访问'

Context组件:(类似于nginx中的alias)
    参数：
        path：URL路径
        reloadable：是否支持自动装载
        docBase：系统文件路径

Valve组件：
    参数：
        定义访问日志：org.apache.catalina.valves.AccessLogValve
        定义访问控制：org.apache.catalina.valves.RemoteAddrValve 
        pattern：日志格式
        prefix：日志前缀
        suffix：日志后缀
    日志路径：
        rpm安装：/var/log/tomcat/
        绿色安装：/usr/local/tomcat/logs/
```


<br>
综合示例：

```bash
<Host name="www.maxie.com" appBase="/web/apps" unpackWARs="true" autoDeploy="true">
	<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
		prefix="node1_access" suffix=".log"
		pattern="%h %l %u %t &quot;%r&quot; %s %b" />
	<Context path="/test" docBase="test" reloadable="">
		<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
		prefix="node1_test_access_" suffix=".log"
		# 设置为combined格式的日志
		pattern="%h %l %u %t %r %s %b %{Referer}i %{User-Agent}i" />      
	</Context>
</Host>		
```




-------


{% note info %}### 配置几个Tomcat示例
{% endnote %}


####  <font size=3 color="#38B0DE"> 简单测试页 配置</font>


* 安装Tomcat

```bash
安装所需要的包：
$ yum install -y java-1.8.0-openjdk-devel tomcat tomcat-webapps tomcat-admin-webapps tomcat-docs-webapp 

配置tomcat.users.xml 
$ vim /etc/tomcat/tomcat.users.xml
<role rolename="admin-gui"/>
<user username="tomcat" password="tomcat" roles="admin-gui"/>
<role rolename="manager-gui"/>
<user username="maxie" password="maxie" roles="manager-gui"/>

修改网卡地址为内网地址
```

* 配置Tomcat测试页

```
$ mkdir /usr/share/tomcat/webapps/test/{classes,META-INF,WEB-INF}
$ vim /usr/share/tomcat/webapps/test/index.jsp
<%@ page language="java" %>
<%@ page import="java.util.*" %>
<html>
    <head>
        <title>Test Page</title>
    </head>
    <body>
        <font size=10 color="#38B0DE" > Tomcat One Server  </font>
        <table align="centre" border="1">
        <tr>
                <td>Session ID</td>
                <% session.setAttribute("magedu.com","magedu.com"); %>
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

$ systemctl restart tomcat
```

* 使用nginx作为反向代理tomcat

```
$ yum install nginx 
$ vim /etc/nginx/nginx.conf
upstream 
server {
	listen 80;
	server_name www1.maxie.com;
	location / {
		proxy_pass http://192.168.1.30:8080;
	}
}

$ systemctl start nginx
```

* 修改客户端HOSTS文件

```
$ sudo vim /etc/hosts
172.16.3.10 www1.maxie.com 
```

* 打开网页进行测试

![](https://ws1.sinaimg.cn/large/006tNc79ly1fh47lab2rvj31hc1pk4am.jpg)


<br>

####  <font size=3 color="#38B0DE">使用反向代理Tomcat</font>

* 使用httpd作为反代服务器(需要将之前nginx服务关闭，防止端口冲突)

```bash
$ yum install httpd 
$ cd /etc/httpd 
$ vim conf.d/maxie-http.conf 
<VirtualHost *:80>
	ServerName www1.maxie.com
	DocumentRoot "/data/maxie/"
	ProxyRequests Off              # 关闭正向代理
	ProxyVia	  On           # 添加首部Via(由谁代理)--> 有可能会httpd被取消掉 
	ProxyPreserveHost On           # 把主机头部发送到后端；保留代理服务器上虚拟主机的头部(域名)
	<Proxy *>
		Require all granted
	</Proxy>
	ProxyPass / http://192.168.1.30:8080/          # 把/ 代理到后端服务器的地址
	#或者可以定义成：
	ProxyPass / http://192.168.1.30:8080/test/     # 把 / 代理到后端的 /test 上
	ProxyPassReverse / http://192.168.1.30:8080/   # 把重定向返回给客户端

	<Location />                                   # 设置代理的/ 允许谁访问
		Require all granted
	</Location>

</VirtualHost>	

$ httpd -M | grep proxy                                 # 确保 proxy_http 模块装载

$ httpd -t 
$ systemctl start httpd 
```


* 使用`ajp`协议进行通信(确保 proxy_ajp_module装载)

```
$ cp conf.d/maxie-http.conf conf.d/maxiecloud-ajp.conf
$ vim conf.d/maxiecloud-ajp.conf
<VirtualHost *:80>
	ServerName www1.maxiecloud.com
	DocumentRoot "/data/maxie/"
	ProxyRequests Off 			
	ProxyVia	  On 					
	ProxyPreserveHost On 		
	<Proxy *>
		Require all granted
	</Proxy>
	ProxyPass / ajp://192.168.1.30:8009/ 
	ProxyPassReverse / ajp://192.168.1.30:8009/ 

	<Location /> 
		Require all granted
	</Location>

</VirtualHost>

$ systemctl restart httpd 
```

<br>

####  <font size=3 color="#38B0DE">使用nginx/httpd负载均衡Tomcat</font>

这时需要两台Tomcat机器，两台配置一样。只需复制之前做的一台上的配置文件以及/test测试jsp文件

**使用nginx反向代理调度器对tomcat实现负载均衡**

* 停止httpd服务

```
$ systemctl stop httpd
```

* 配置nginx

```
$ vim /etc/nginx/conf.d/maxie.conf 
upstream tomcatsrv {
	server 192.168.1.50:8080;
	server 192.168.1.60:8080;
}
server {
    listen          80;
    server_name     www.maxie.com;
    
    location / {
    	proxy_pass http://tomcatsrv;
    }
}

$ systemctl restart nginx 
```

* 打开网页进行测试

![](https://ws2.sinaimg.cn/large/006tNc79gy1fh48p33ku2g30qo0us4qv.gif)

如需设置会话保持功能：

```
$ vim /etc/nginx/conf.d/maxie.conf
在upstream中添加
hash $request_uri consistent;
或者
ip_hash;
或者
hash $cookie_name consistent;
```

<br>

**使用httpd作为反向代理时，对后端2台tomcat实现负载均衡**

* 停止nginx服务

```
$ systemctl stop nginx
```

* 配置httpd

```
$ vim /etc/httpd/conf.d/maxie-http.conf
<Proxy balancer://tomcatsrv>
	BalancerMember http://192.168.1.50:8080
	BalancerMember http://192.168.1.60:8080
	ProxySet lbmethod=byrequests
</Proxy>


<VirtualHost *:80>
	ServerName www.maxie.com
	ProxyRequests Off                  # 关闭正向代理
	ProxyVia	  On               # 添加首部Via(由谁代理)--> 有可能会httpd被取消掉 
	ProxyPreserveHost On               # 把主机头部发送到后端；保留代理服务器上虚拟主机的头部(域名)
	<Proxy *>
		Require all granted
	</Proxy>
	ProxyPass / balancer://tomcatsrv/              # 把/ 代理到后端服务器的地址
	
	ProxyPassReverse / balancer://tomcatsrv/       # 把重定向返回给客户端

	<Location />                                   # 设置代理的/ 允许谁访问
		Require all granted
	</Location>

</VirtualHost>	

$ httpd -t
$ systemctl restart httpd
```

* 打开网页测试即可，效果如nginx代理一样

<br>


* httpd负载均衡实现会话粘性并开启httpd內建的负载均衡状态页

```
$ vim /etc/httpd/conf.d/maxie-http.conf
Header add Set-Cookie "MYID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED

<Proxy balancer://tomcatsrv>
        BalancerMember http://192.168.1.50:8080 route=tom1 loadfactor=2
        BalancerMember http://192.168.1.60:8080 route=tom2 loadfactor=1
        ProxySet lbmethod=byrequests
        ProxySet stickysession=MYID
</Proxy>
<VirtualHost *:80>
    ServerName wwww.maxie.com
    ProxyRequests Off
    ProxyVia      On
    ProxyPreserveHost On
    <Proxy *>
        Require all granted
    </Proxy>
    ProxyPass / balancer://tomcatsrv/
    ProxyPassReverse / balancer://tomcatsrv/

    <Location />
        Require all granted
    </Location>

    <Location /http-stats>                  # 开启管理负载均衡的接口
        SetHandler balancer-manager         # 启动balancer-manager这个內建功能
        ProxyPass !                         # !表示 不反代，只在本机处理
        Require all granted
    </Location>

</VirtualHost>

$ systemctl restart httpd
```

* 打开网页测试

![](https://ws4.sinaimg.cn/large/006tNc79gy1fh48hvej25g30qo0usqva.gif)



-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=425100254&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)




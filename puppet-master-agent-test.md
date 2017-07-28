---
title: 自动化运维工具puppet的模块练习
date: 2017-07-22 18:51:54
tags: [puppet,运维技术]
categories: [puppet,运维技术]
copyright: true
---

上一节我们主要是在`standalone`模型上进行练习，而在`生产`环境中，我们都是使用的是`master/agent`模型。

下面我们就如何制作模块、puppet的master/agent进行详细的练习

### 环境准备

虚拟机：

```bash
master节点        172.16.1.40/16

agent节点：
    node1节点         172.16.1.100/16
    node2节点         172.16.1.70/16
    node3节点         172.16.1.60/16
```

软件包：

```bash
master节点        puppet、puppet-server、facter
agent节点         puppet、facter
```

软件包下载地址：[puppet](https://www.dropbox.com/s/8ofkk2huwe8xhuh/puppet-3.8.7-1.el7.noarch.rpm?dl=0)、[puppet-server](https://www.dropbox.com/s/8y6rn9f4qhd13q8/puppet-server-3.8.7-1.el7.noarch.rpm?dl=0)、[facter](https://www.dropbox.com/s/mwmteh7g143mt5l/facter-2.4.6-1.el7.x86_64.rpm?dl=0)

*注意：这里需要科学上网，才能下载软件包   :)*

<!-- more -->

-------

### chrony时间同步模块制作

#### 安装配置chrony服务

```bash
$ yum install chrony
$ vim /etc/chrony.conf
# 这里填写我们自己的ntp时间服务器，如果服务器可以上网，也可以填网络上的时间服务器
server ntp.maxie.io iburst

# Ignore stratum in source selection.
stratumweight 0

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Enable kernel RTC synchronization.
rtcsync

# In first three updates step the system clock instead of slew
# if the adjustment is larger than 10 seconds.
makestep 10 3

# Allow NTP client access from local network.
#allow 192.168/16

# Listen for commands only on localhost.
bindcmdaddress 127.0.0.1
bindcmdaddress ::1

# Serve time even if not synchronized to any NTP server.
#local stratum 10

keyfile /etc/chrony.keys

# Specify the key used as password for chronyc.
commandkey 1

# Generate command key if missing.
generatecommandkey

# Disable logging of client accesses.
noclientlog

# Send a message to syslog if a clock adjustment is larger than 0.5 seconds.
logchange 0.5

logdir /var/log/chrony
#log measurements statistics tracking
```


#### 制作模块

```bash
$ mkdir /root/modules
$ cd modules/
$ mkdir -pv  chrony/{manifests,files,templates,lib,spec,tests}
$ cd chrony/manifests/
$ vim init.pp
# Class: chrony
#
# This module manages CHRONY
#
#

class chrony {
        package{'chrony':
                ensure  => latest,
        } ->

        file{'chrony.conf':
                ensure  => file,
                path    => '/etc/chrony.conf',
                source  => 'puppet:///modules/chrony/chrony.conf',
        } ~>

        service{'chronyd':
                ensure  => running,
                enable  => true,
        }
}


$ cp /etc/chrony.conf ../files/
$ cd /root/modules
$ cp -a chrony/ /etc/puppet/modules/

$ puppet apply -d -v --noop -e 'include chrony'
$ puppet apply -d -v  -e 'include chrony'
```

-------



### nginx反代模块制作

准备：

```bash
$ mkdi /etc/puppet/modules/nginx/{manifests,files,templates,lib,spec,tests}
$ cd /etc/puppet/modules/nginx/
```

#### 制作模板文件

* 制作单tomcat节点，反代apache+tomcat的httpd请求的nginx模板文件

```ruby
$ vim /etc/puppet/modules/nginx/templates/nginx-webproxy.conf.erb
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
# 使用內建变量，自动生成进程数
worker_processes <%= @processorcount %>;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        root         /usr/share/nginx/html;

        include /etc/nginx/default.d/*.conf;

    #根据环境配置的域名，自动生成
	server_name	<%= @domain %>;
	index 	index.html;

        location / {
       		proxy_set_header    X-Forwarded-For $remote_addr;
        	proxy_buffering        off;
        	proxy_pass        http://node2.maxie.io:808;
        }
	

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
```



* 制作双tomcat+apache的负载均衡代理的nginx配置模板文件

```ruby
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes <%= @processorcount %>;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    # 定义负载均衡
    upstream tomcatsrvs {
	server node2.maxie.io:808;
        server node3.maxie.io:808;
    }

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        root         /usr/share/nginx/html;

        include /etc/nginx/default.d/*.conf;

	server_name	<%= @domain %>;
	index 	index.html;

        location / {
       		proxy_set_header    X-Forwarded-For $remote_addr;
        	proxy_buffering        off;
        	proxy_pass        http://tomcatsrvs;
        }
	

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

}
```

#### 配置模块

* init.pp

```ruby
$ vim manifests/init.pp
class nginx {
    package{'nginx':
            ensure  => latest,
    } ->

    service{'nginx':
            ensure  => running,
            enable  => true,
    }
}
```

* webproxy.pp

```ruby
$ vim manifests/webproxy.pp
class nginx::webproxy inherits nginx {
	file{'nginx.conf':
		ensure	=> file,
		path	=> '/etc/nginx/nginx.conf',
		content	=> template('nginx/nginx-webproxy.conf.erb'),
	}
	
	Package['nginx'] -> File['nginx.conf']  ~> Service['nginx']
}
```

* tomcatsrvs.pp

```ruby
$ vim manifests/tomcatsrvs.pp
class nginx::tomcatsrvs inherits nginx {
	file{'nginx-tomcat.conf':
		ensure	=> file,
		path	=> '/etc/nginx/nginx.conf',
		content	=> template('nginx/nginx-tomcat.conf.erb'),
	}
	
	Package['nginx'] -> File['nginx-tomcat.conf']  ~> Service['nginx']
}
```


#### 将模块分配给node1节点使其作为反代服务器

不过这里我们还没有配置master/agent节点，所以这步需要在我们配置好了master节点与其他3个agent节点之后，在`master`节点的`site.pp`文件中写入如下信息：


```ruby
node 'base' {
	include	chrony
} 
node 'node1.maxie.io' {
	include	nginx
	include	nginx::tomcatsrvs	
}
```

#### 别忘了测试！

如果虚拟机够用，最好是再做一台puppet，安装`puppet`和`facter`，对我们制作好的模块模块进行测试


```bash
$ puppet apply -d -v --noop -e 'include nginx'

$ puppet apply -d -v --noop -e 'include nginx::webproxy'

$ puppet apply -d -v --noop -e 'include nginx::tomcatsrvs'
```

确保我们制作的模块可以正常使用

-------

### mariadb数据库模块制作

初始化：

```bash
$ mkdir -pv /etc/puppet/modules/mariadb/{manifests,templates,files,lib,tests}

$ cp /etc/my.cnf.d/server.cnf /etc/puppet/modules/mariadb/templates/server.cnf.erb
```

#### 制作模板文件


```bash
$ cd /etc/puppet/modules/mariadb/
$ vim templates/server.conf.erb
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see
#
# See the examples of server my.cnf files in /usr/share/mysql/
#

# this is read by the standalone daemon and embedded servers
[server]
skip_name_resolve=ON
innodb_file_per_table=ON
log-bin=mysql_bin

# this is only for the mysqld standalone daemon
[mysqld]

# this is only for embedded server
[embedded]

# This group is only read by MariaDB-5.5 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mysqld-5.5]

# These two groups are only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

[mariadb-5.5]



'制作sql脚本'
$ vim files/solodb.sql
create database solo;

grant all on solo.* to 'solo'@'172.16.%.%' identified by 'root@123';

flush privileges;
```

#### 制作模块

* init.pp

```ruby
$ vim manifests/init.pp
class mariadb($datadir='/var/lib/mysql') {
	package{'mariadb-server':
		ensure	=> installed,
	}

	file{"$datadir":
		ensure	=> directory,
		owner	=> mysql,
		group	=> mysql,
		require	=> [ Package['mariadb-server'], Exec['createdir'], ],	
	}
	
	exec{'createdir':
		command	=> "mkdir -pv $datadir",
		require	=> Package['mariadb-server'],
		path	=> '/bin:/sbin:/usr/bin:/usr/sbin',
		creates	=> "$datadir",
	}

	file{'server.cnf':
		ensure	=> file,
		path	=> '/etc/my.cnf.d/server.cnf',
		content	=> template('mariadb/server.cnf.erb'),
		require	=> Package['mariadb-server'],
		notify	=> Service['mariadb'],
	}

	service{'mariadb':
		ensure	=> running,
		enable	=> true,
		require	=> [ Exec['createdir'], File["$datadir"], ],
	}
}
```


* database.pp

```ruby
$ vim manifests/database.pp
class mariadb::database inherits mariadb {
	file{'solodb.sql':
		ensure	=> file,
		path	=> '/var/lib/mysql/solodb.sql',
		source	=> 'puppet:///modules/mariadb/solodb.sql'
	}	

	# only run once
	exec{'createdb':
		command	=> 'mysql < /var/lib/mysql/solodb.sql',
		path    => '/bin:/sbin:/usr/bin:/usr/sbin',
		require	=> Package['mariadb-server'],
		# 注意，引用变量时，外面不能再用单引号，需要换成双引号
		unless  => "mysql -usolo -proot@123 -h$ipaddress",
	}

	Service['mariadb'] -> File['solodb.sql'] -> Exec['createdb']
}
```



#### 别忘了测试！

```bash
$ puppet apply -d -v --noop -e 'include mariadb'

$ puppet apply -d -v --noop -e 'include mariadb::database'
```

确保我们制作的模块可以正常使用

-------

### httpd反代tomcat模块制作

初始化：

```bash
$ cd /etc/puppet/modules
$ mkdir -pv httpd/{manifests,templates,files,lib,tests}
$ cd httpd
```

#### 制作模板配置文件

* httpd主配置文件httpd.conf.erb

```ruby
$ vim templates/httpd.conf.erb
# 只需将默认的httpd.conf中的listen 80修改为808即可
Listen 808
```

* 虚拟主机配置文件vhost.conf.erb

```ruby
$ vim templates/vhost.conf.erb
<VirtualHost <%= @ipaddress %>:808>
        ServerName <%= @domian %>:808
        ProxyRequests Off
        ProxyVia On
        ProxyPreserveHost On
        <Proxy *>
                Require all granted
        </Proxy>
        ProxyPass       /       http://<%= @ipaddress %>:80/

        <Location />
                Require all granted
        </Location>
#       DocumentRoot "/web/blog/"
#       <Directory "/web/blog/">
#               Options FollowSymLinks
#               AllowOverride None
#               Require all granted
#               DirectoryIndex index.html
#       </Directory>
        CustomLog "/web/blog/logs/maxie_access.log" combined
</VirtualHost>
```

#### 制作模块

* init.pp

```ruby
$ vim manifests/init.pp
class httpd{
        package{'httpd':
                ensure  => latest,
        }

        service{'httpd':
                ensure  => running,
                enable  => true,
        }
}
```

* httpdconf.pp

```ruby
class httpd::httpdconf inherits httpd {
	file{'httpd.conf':
		ensure	=> file,
		path	=> '/etc/httpd/conf/httpd.conf',
		content	=> template('httpd/httpd.conf.erb'),
	}

	Package['httpd'] -> File['httpd.conf'] ~> Service['httpd']
}
```

* vhost.conf.erb

```ruby
class httpd::vhost inherits httpd {
	exec{'logdir':
		command	=> 'mkdir -p /web/blog/logs/',
		path	=> '/usr/bin:/usr/sbin/:/bin:/sbin',
		creates	=> '/web/blog/logs',
		before	=> [ File['vhost.conf'], Service['httpd'] ],
	}

	file{'vhost.conf':
		ensure	=> file,
		path	=> '/etc/httpd/conf.d/vhost.conf',
		content	=> template('httpd/vhost.conf.erb'),
	}
	

	Package['httpd'] -> File['vhost.conf'] ~> Service['httpd']
}
```


#### 别忘了测试！


```bash
$ puppet apply -d -v --noop -e 'include httpd'
$ puppet apply -d -v --noop -e 'include httpd::httpdconf'
$ puppet apply -d -v --noop -e 'include httpd::vhost'

$ puppet apply -d -v  -e 'include httpd'
$ puppet apply -d -v  -e 'include httpd::httpdconf'
$ puppet apply -d -v  -e 'include httpd::vhost'
```

确保模块的正常运行


-------


### tomcat模块制作

初始化：

```bash
$ mkdir -pv /etc/puppet/modules/tomcat/{manifests,templates,files,lib,tests,spec}
$ cd tomcat/
```

authbind软件下载地址：[authbind](https://www.dropbox.com/s/qdwxol39yq3aygf/authbind-2.1.1-0.1.x86_64.rpm?dl=0)

这里我们使用程序是`solo blog`
下载地址：[solo-blog](https://www.dropbox.com/s/oho6l1l9k18zibm/solo-2.1.0.textClipping?dl=0)

使用的tomcat版本是：`tomcat-7.0.54-2.el7_1.noarch`
使用的是epel源中提供的tomcat版本

jdk版本：

```bash
$ java -version
openjdk version "1.8.0_65"
OpenJDK Runtime Environment (build 1.8.0_65-b17)
OpenJDK 64-Bit Server VM (build 25.65-b01, mixed mode)
```


#### 制作模板文件

* server.xml.erb

```ruby
<?xml version='1.0' encoding='utf-8'?>

<Server port="8005" shutdown="SHUTDOWN">
  
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  
  <Listener className="org.apache.catalina.core.JasperListener" />
  
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  
  <GlobalNamingResources>
  
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  
  <Service name="Catalina">

  
    <Connector port="80" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
  
    <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />


  
    <Engine name="Catalina" defaultHost="localhost">

  
      <Realm className="org.apache.catalina.realm.LockOutRealm">
  
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">


        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log." suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
```

* server-mem.xml.erb

```ruby
<?xml version='1.0' encoding='utf-8'?>

<Server port="8005" shutdown="SHUTDOWN">
  
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  
  <Listener className="org.apache.catalina.core.JasperListener" />
  
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  
  <GlobalNamingResources>
  
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  
  <Service name="Catalina">

  
    <Connector port="80" protocol="HTTP/1.1"
               connectionTimeout="20000"
	       URIEncoding="UTF-8"
	       Server="mAX io site"
               redirectPort="8443" />
  
    <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />


    <Engine name="Catalina" defaultHost="localhost">

      <Realm className="org.apache.catalina.realm.LockOutRealm">

        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">


<Context path="/test" docBase="test" reloadable="true" >
            <Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager"
                memcachedNodes="mem1:node2.maxie.io:11211,mem2:node3.maxie.io:11211"
                failoverNodes="mem2"
                requestUriIgnorePattern=".*\.(ico|png|gif|jpg|css|js)$"
                transcoderFactoryClass="de.javakaffee.web.msm.serializer.javolution.JavolutionTranscoderFactory"
            />
        </Context>

  
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log." suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
```


* tomcat-users.xml.erb

```ruby
<?xml version='1.0' encoding='utf-8'?>

<tomcat-users>

<role rolename="admin-gui"/>
<role rolename="manager-gui"/>
<user username="root" password="root@123" roles="manager-gui"/>
<user username="tomcat" password="root@123" roles="admin-gui"/>
<!-- <user name="admin" password="adminadmin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" /> -->
</tomcat-users>
```

#### 制作要拷贝的文件

* local.properties

```bash
$ vim files/local.properties
#
# Copyright (c) 2010-2017, b3log.org & hacpai.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Description: Solo local environment configurations.
# Version: 1.1.3.9, Sep 13, 2016
# Author: Liang Ding
#

#### MySQL runtime ####
runtimeDatabase=MYSQL
jdbc.username=solo
jdbc.password=root@123
jdbc.driver=com.mysql.jdbc.Driver
jdbc.URL=jdbc:mysql://node2.maxie.io:3306/solo?useUnicode=yes&characterEncoding=utf8
jdbc.pool=druid

# The minConnCnt MUST larger or equal to 3
jdbc.minConnCnt=5
jdbc.maxConnCnt=10

# Be care to change the transaction isolation 
jdbc.transactionIsolation=REPEATABLE_READ

# The specific table name prefix
jdbc.tablePrefix=b3_solo
```

* latke.properties

```
#
# Copyright (c) 2010-2017, b3log.org & hacpai.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Description: B3log Latke configurations. Configures the section "Server" carefully.
# Version: 1.4.3.9, Dec 23, 2015
# Author: Liang Ding
#

#### Server ####
# Browser visit protocol
serverScheme=http
# Browser visit domain name
serverHost=maxie.io
# Browser visit port, 80 as usual, THIS IS NOT SERVER LISTEN PORT!
serverPort=80

#### Runtime Mode ####
#runtimeMode=DEVELOPMENT
runtimeMode=PRODUCTION
```

* tom1-index.jsp：node1节点的index.jsp测试页

```jsp
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
                     <% session.setAttribute("maxie.io","maxie.io"); %>
                      <td><%= session.getId() %></td>
          </tr>
            <tr>
                    <td>Created on</td>
                            <td><%= session.getCreationTime() %></td>
                </tr>
            </table>
           <br>
		<% out.println("China No.1");
		%>
    </body>
</html>

```


* tom2-index.jsp：node2节点的index.jsp测试页

```jsp
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
                     <% session.setAttribute("maxie.io","maxie.io"); %>
                      <td><%= session.getId() %></td>
          </tr>
            <tr>
                    <td>Created on</td>
                            <td><%= session.getCreationTime() %></td>
                </tr>
            </table>
           <br>
		<% out.println("Taiwan No.2");
		%>
    </body>
</html>
```

#### 制作资源清单

* init.pp

```puppet
class tomcat {
	package{['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps']:
		ensure	=> installed,
	} 
}
```

* conf.pp 默认配置文件 只修改了8080 为80端口

```puppet
class tomcat::conf inherits tomcat{
	file{'tomcat-user.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/tomcat-users.xml',
		owner	=> tomcat,
		group	=> tomcat,
		content	=> template('/etc/puppet/modules/tomcat/templates/tomcat-users.xml.erb'),
		replace	=> true,
	}
	
	file{'server.xml':
		ensure	=> file,
		path	=> '/etc/tomcat/server.xml',
		owner	=> tomcat,
		group	=> tomcat,
		content => template('tomcat/server.xml.erb'),
		require => File['tomcat-user.xml'],
		replace	=> true,
	}
	
	
	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps'] -> File['tomcat-user.xml'] 
}
```

* blog.pp

```puppet
class tomcat::blog inherits tomcat {

	file{'ROOT':
                ensure  => directory,
                path    => '/usr/share/tomcat/webapps/ROOT/',
                source  => 'puppet:///modules/tomcat/ROOT/',
                replace => true,
                recurse => true,
                owner   => 'tomcat',
                group   => 'tomcat',
        }

	file{'local.properties':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/ROOT/WEB-INF/classes/local.properties',
		replace	=> true,
		owner	=> 'tomcat',
		group	=> 'tomcat',
		source	=> 'puppet:///modules/tomcat/local.properties',
		require	=> File['ROOT'],
	}
	
	file{'latke.properties':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/ROOT/WEB-INF/classes/local.properties',
		replace	=> true,
		owner	=> 'tomcat',
		group	=> 'tomcat',
		source	=> 'puppet:///modules/tomcat/latke.properties',
		require	=> File['ROOT'],
	}
	
	Package['tomcat'] -> File['ROOT']
	
}
```

* memone.pp ： node2节点的测试页的资源清单

```puppet
class tomcat::memone inherits tomcat {
	exec{'mkdir':
		command	=> 'mkdir -p /usr/share/tomcat/webapps/test/{WEB-INF,classes,META-INF}',
		path    => '/bin:/sbin:/usr/bin:/usr/sbin',
		creates => '/usr/share/tomcat/webapps/test/',
	}

	file{'index.jsp':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/test/index.jsp',
		source	=> 'puppet:///modules/tomcat/tom1-index.jsp',
		require	=> Exec['mkdir'],
	} 

	file{'javolution-5.4.3.1.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/javolution-5.4.3.1.jar',
		source	=> 'puppet:///modules/tomcat/javolution-5.4.3.1.jar',
		require	=> Exec['mkdir'],
	}
	
	file{'memcached-session-manager-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/memcached-session-manager-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/memcached-session-manager-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'memcached-session-manager-tc7-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/memcached-session-manager-tc7-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/memcached-session-manager-tc7-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'msm-javolution-serializer-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/msm-javolution-serializer-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/msm-javolution-serializer-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'spymemcached-2.11.1.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/spymemcached-2.11.1.jar',
		source	=> 'puppet:///modules/tomcat/spymemcached-2.11.1.jar',
		require	=> Exec['mkdir'],
	}

	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps'] -> Exec['mkdir']
}
```

* memtwo.pp ：node3节点的测试页的资源清单

```puppet
class tomcat::memtwo inherits tomcat {
	exec{'mkdir':
		command	=> 'mkdir -p /usr/share/tomcat/webapps/test/{WEB-INF,classes,META-INF}',
		path    => '/bin:/sbin:/usr/bin:/usr/sbin',
		creates => '/usr/share/tomcat/webapps/test/',
	}

	file{'index.jsp':
		ensure	=> file,
		path	=> '/usr/share/tomcat/webapps/test/index.jsp',
		source	=> 'puppet:///modules/tomcat/tom2-index.jsp',
		require	=> Exec['mkdir'],
	} 

	file{'javolution-5.4.3.1.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/javolution-5.4.3.1.jar',
		source	=> 'puppet:///modules/tomcat/javolution-5.4.3.1.jar',
		require	=> Exec['mkdir'],
	}
	
	file{'memcached-session-manager-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/memcached-session-manager-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/memcached-session-manager-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'memcached-session-manager-tc7-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/memcached-session-manager-tc7-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/memcached-session-manager-tc7-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'msm-javolution-serializer-1.8.3.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/msm-javolution-serializer-1.8.3.jar',
		source	=> 'puppet:///modules/tomcat/msm-javolution-serializer-1.8.3.jar',
		require	=> Exec['mkdir'],
	}

	file{'spymemcached-2.11.1.jar':
		ensure	=> file,
		path	=> '/usr/share/java/tomcat/spymemcached-2.11.1.jar',
		source	=> 'puppet:///modules/tomcat/spymemcached-2.11.1.jar',
		require	=> Exec['mkdir'],
	}

	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps'] -> Exec['mkdir']
}
```

* authbind.pp ：启动tomcat的软件，使tomcat运行在80端口

```puppet
class tomcat::authbind inherits tomcat {
	file{'authbind':
		ensure	=> file,
		path	=> '/tmp/authbind-2.1.1-0.1.x86_64.rpm',
		source	=> 'puppet:///modules/tomcat/authbind-2.1.1-0.1.x86_64.rpm'
	} 

	package{'authbind':
		ensure	=> installed,
		source	=> '/tmp/authbind-2.1.1-0.1.x86_64.rpm',
		provider => rpm,
	}

	exec{'authbind':
		command	=> 'setsid authbind --deep /usr/libexec/tomcat/server start',
		path	=> '/bin:/sbin:/usr/bin:/usr/sbin',
		require	=> Package['authbind']
	}

	Package['java-1.8.0-openjdk-devel','tomcat','tomcat-admin-webapps','tomcat-webapps'] -> File['authbind'] -> Package['authbind']

}
```

#### 别忘了测试！


```bash
$ puppet apply -d -v --noop -e 'include tomcat'
$ puppet apply -d -v --noop -e 'include tomcat::memconf'
$ puppet apply -d -v --noop -e 'include tomcat::blog'
$ puppet apply -d -v --noop -e 'include tomcat::memone'
$ puppet apply -d -v --noop -e 'include tomcat::memtwo'
$ puppet apply -d -v --noop -e 'include tomcat::authbind'
```

确保模块的正常运行

**注意各个模块的依赖关系，以及执行顺序在master/agent节点时需要特别注意**

```
尽量把依赖关系基本没有的都放到最前面执行，把依赖最多的放到最后执行即可。
当测试都完成了，没有报错时，才能一台一台的分发。
因为就算测试没有问题，真正部署时，也会有各种各样的问题，这时就需要我们解决问题了
```

-------

### memcached模块制作

初始化：

```bash
$ mkdir -pv /etc/puppet/modules/memcached/{manifests,files,templates,lib,tests,spec}
$ cd /etc/puppet/modules/memcached
```

#### 制作memcached模块

* init.pp

```puppet
class memcached {
	package{'memcached':
		ensure	=> latest,
	} ->

	service{'memcached':
		ensure	=> running,
		enable	=> true,
	}
}
```


#### 别忘了测试！


```bash
$ puppet apply -d -v --noop -e 'include memcahced'
```

确保模块的正常运行


-------

### master/agent配置

初始化：

```bash
所有节点：
$ ntpdate 172.16.0.1
$ vim /etc/hosts
172.16.1.40 master.maxie.io master
172.16.1.100 node1.maxie.io node1
172.16.1.70 node2.maxie.io node2
172.16.1.60 node3.maxie.io node3
```

#### master节点

* 安装puppet、puppet-server、facter

```bash
$ lftp 172.16.0.1/pub/Sources/7.x86_64/puppet
> mget puppet-3.8.7-1.el7.noarch.rpm puppet-server-3.8.7-1.el7.noarch.rpm facter-2.4.6-1.el7.x86_64.rpm

$ yum install ./*.rpm -y

# 生成CA证书，并自建CA
$ puppet master --no-daemonize -v
Info: Creating a new SSL key for master.maxie.io
Info: csr_attributes file loading from /etc/puppet/csr_attributes.yaml
Info: Creating a new SSL certificate request for master.maxie.io
Info: Certificate Request fingerprint (SHA256): 37:CB:C0:91:35:5D:F2:83:B7:16:36:73:30:80:74:2A:90:77:8A:C1:4F:10:4E:BE:14:E8:58:CC:83:CB:B7:76
Notice: master.maxie.io has a waiting certificate request
Notice: Signed certificate request for master.maxie.io
Notice: Removing file Puppet::SSL::CertificateRequest master.maxie.io at '/var/lib/puppet/ssl/ca/requests/master.maxie.io.pem'
Notice: Removing file Puppet::SSL::CertificateRequest master.maxie.io at '/var/lib/puppet/ssl/certificate_requests/master.maxie.io.pem'
Notice: Starting Puppet master version 3.8.7

	'注意：这里如果报错是Could not create PID，需要执行以下命令'
		$ killall puppet 
		$ rm -rf /var/lib/puppet/ssl
		$ puppet master --no-daemonize -v

```

* 检测并发送安装包

```bash
# 查看端口是否启动,再打开一个终端
$ ss -tnl | grep 8140


# 将rpm包发送给agent
$ scp -r ./*.rpm node2:/root
$ scp -r ./*.rpm node1:/root
$ scp -r ./*.rpm node3:/root
```


#### agent节点

* 安装puppet、facter

```bash
$ rm -f puppet-server*
$ yum install -y ./*.rpm
```

* 生成证书请求

```bash
$ puppet agent --server master.maxie.io --no-daemonize -v
Info: Caching certificate for ca
Info: csr_attributes file loading from /etc/puppet/csr_attributes.yaml
Info: Creating a new SSL certificate request for node1.maxie.io
Info: Certificate Request fingerprint (SHA256): F4:63:3E:68:8A:E2:C2:B4:83:81:C6:E1:7C:28:40:92:6A:56:26:3D:CC:39:8A:30:E7:D1:39:E4:11:F3:CB:68
```

#### master节点签署agent节点证书

```bash
$ puppet cert sign --all
```

#### agent节点查看收到的CA证书


```bash
$ puppet agent --server master.maxie.io --no-daemonize -v
Info: Caching certificate for ca
Info: csr_attributes file loading from /etc/puppet/csr_attributes.yaml
Info: Creating a new SSL certificate request for node1.maxie.io
Info: Certificate Request fingerprint (SHA256): F4:63:3E:68:8A:E2:C2:B4:83:81:C6:E1:7C:28:40:92:6A:56:26:3D:CC:39:8A:30:E7:D1:39:E4:11:F3:CB:68
Info: Caching certificate for ca
Info: Caching certificate for node1.maxie.io
Notice: Starting Puppet client version 3.8.7
Info: Caching certificate_revocation_list for ca
Warning: Unable to fetch my node definition, but the agent run will continue:
Warning: undefined method 'include?' for nil:NilClass
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Caching catalog for node1.maxie.io
Info: Applying configuration version '1500621510'
Info: Creating state file /var/lib/puppet/state/state.yaml
Notice: Finished catalog run in 0.01 seconds
```

不过这里，我们还没有在master节点的site.pp站点资源清单定义要分发给Node1节点什么模块，所以会有警告信息



#### master节点配置agent各个节点应该拥有的模块

```bash
$ vim /etc/puppet/manifests/site.pp
node 'base' {
	include	chrony
} 
node 'node1.maxie.io' {
	include	nginx
	include	nginx::tomcatsrvs	
}

node 'node2.maxie.io' {
# 我们将数据库安装在node2上，node3也使用node2的数据库
	include	mariadb
	include	mariadb::database
	include	httpd
	include	httpd::httpdconf
	include	httpd::vhost
	include	tomcat
	include	tomcat::memconf
	include	tomcat::blog
	include tomcat::memone
	include	memcached
	include	tomcat::authbind
}

node 'node3.maxie.io' {
	include	httpd
	include	httpd::httpdconf
	include	httpd::vhost
	include	tomcat
	include	tomcat::memconf
	include	tomcat::blog
	include tomcat::memtwo
	include	memcached
	include	tomcat::authbind
}
```

#### agent各个节点手动获取自己的配置模块

```bash
$ puppet agent --server master.maxie.io --no-daemonize -v
Notice: Starting Puppet client version 3.8.7
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Caching catalog for node1.maxie.io
Info: Applying configuration version '1500622364'
Info: Computing checksum on file /etc/chrony.conf
Info: /Stage[main]/Chrony/File[chrony.conf]: Filebucketed /etc/chrony.conf to puppet with sum f9b03c5e44a754c3ffd8e135a0a3b35e
Notice: /Stage[main]/Chrony/File[chrony.conf]/content: content changed '{md5}f9b03c5e44a754c3ffd8e135a0a3b35e' to '{md5}37d1ea0abc9e2a92adb512e392fdb033'
Info: /Stage[main]/Chrony/File[chrony.conf]: Scheduling refresh of Service[chronyd]
Notice: /Stage[main]/Chrony/Service[chronyd]: Triggered 'refresh' from 1 events
Notice: Finished catalog run in 0.74 seconds
```

只要不报错，并出现`Notice: Finished catalog run in 0.74 seconds`即表示成功

不过建议在执行`puppet agent --server master.maxie.io --no-daemonize -v` 这条命令时，加上 `-d`和`--noop` 选项，表示debug之意。防止出现错误。如果测试成功，再去掉即可。



#### 上面这些我们都使用的 no-daemonize 模式，现在只需修改配置文件，然后使用systemctl启动agent服务即可

```bash
$ vim /etc/puppet/puppet.conf
[main]
listen = true
[agent]
server = master.maxie.io

$ systemctl start puppetagent.service
```

#### 配置kick功能

使用master节点的`kick`功能，可以手动让某个agent节点强制其马上同步`site.pp`的内容，也可以同步所有agent节点

* agent节点配置

```bash
$ vim /etc/puppet/auth.conf
# 在行尾设置如下信息：
# deny everything else; this ACL is not strictly necessary, but
# illustrates the default policy.
path /
auth any
allow master.maxie.io

#
path /run
method save
auth any
allow master.maxie.io

#重启服务
$ systemctl restart puppetagent.service
$ ss -tnl | grep 8139
```


* master节点kick agent节点

```bash
$ puppet kick node1.maxie.io 
$ puppet kick node2.maxie.io 
$ puppet kick node3.maxie.io 

或者kick 所有agent

$ puppet kick --all
```


### 完整的模块包

下载地址：[LNAMT模块组合包](https://www.dropbox.com/sh/436jvd4aiygwxqd/AACCoZgUwFqG8qFZ-2d4tgA4a?dl=0)

solo博客程序包：[solo-blog](https://www.dropbox.com/s/oho6l1l9k18zibm/solo-2.1.0.textClipping?dl=0)

authbind程序包：[authbind](https://www.dropbox.com/s/qdwxol39yq3aygf/authbind-2.1.1-0.1.x86_64.rpm?dl=0)

tomcat连接memcached所需的包：[msm包](https://www.dropbox.com/sh/a9hi3r1fmd35tqn/AACfBEovYGrgWmJ65B7XZzS7a?dl=0)



-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=421091994&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


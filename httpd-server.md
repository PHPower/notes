---
title: Linux安装httpd服务实现虚拟主机、https功能
date: 2017-06-01 15:28:13
tags: [linux,httpd,https,server,config]
categories: linux进阶
copyright: true
---

<blockquote class="blockquote-center">httpd是一个开源软件，且一般用作web服务器来使用。目前最流行的web服务器软件叫做httpd，httpd还有一个俗称叫apache，Apache是一个软件基金会，httpd也是这个软件基金会的一个项目。
在早期的http server就叫做apache，到了http server 2.0以后就改名为httpd了。所以有时候听到apache服务器和httpd服务器其实都是指得是一个意思。
httpd是一个高度模块化软件，由核心（core）和模块（module）组成。这些模块大都是动态模块，因此可以随时加载。
</blockquote>

`httpd`服务的主配置文件：`/etc/httpd/conf/httpd.conf`
`httpd`服务的其他配置文件目录：`/etc/httpd/conf.d/`
默认的主页目录：`/var/www/html/`

![](https://ws2.sinaimg.cn/large/006tNc79ly1fg5r1i4nprj30m8020jrm.jpg)

<!-- more -->

#### 此次搭建的目标如下：

##### 1、建立httpd服务，要求如下：

```
(1) 提供两个基于名称的虚拟主机：
    www1.maxie.com，页面文件目录为/web/www/html/www1；
    错误日志为/var/log/httpd/www1/error_log，访问日志为/var/log/httpd/www1/access_log；
	
    www2.maxie.com，页面文件目录为/web/www/html//www2；
    错误日志为/var/log/httpd/www2/error_log，访问日志为/var/log/httpd/www2/access_log；

(2) 通过www1.maxie.com/server-status输出其状态信息，且要求只允许提供账号的用户访问；
(3) www1不允许192.168.1.0/24网络中的主机访问；
```


##### 2、为上面的第2个虚拟主机提供https服务，使得用户可以通过https安全的访问此web站点；

```
(1) 要求使用证书认证，证书中要求使用国家（CN），州（Beijing），城市（Beijing），组织为(CAorg)；
(2) 设置部门为Ops, 主机名为www2.maxie.com；
```

-------

**此次的所有实验环境如下：**

```
CentOS6：
操作系统（OS）：CentOS release 6.8 (Final)
内核版本（Kernel）：2.6.32-642.el6.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

```
CentOS7：
操作系统（OS）：CentOS Linux release 7.2.1511 (Core)
内核版本（Kernel）：3.10.0-327.el7.x86_64
虚拟机环境：VMware Fusion 专业版 8.5.3 (4696910)
```

客户端环境：
![](https://ws4.sinaimg.cn/large/006tNc79ly1fg5rfg0cjsj30ga0a8dj6.jpg)


-------


{% note primary %}### 在CentOS6上完成如上实验
{% endnote %}



#### 第一题操作步骤：

##### 1、安装httpd服务	

```
$ yum install httpd 
```

##### 2、编辑httpd配置文件
	
```bash
$ vim /etc/httpd/conf/httpd.conf
修改其中下面的值：
		DocumentRoot "/web/www/html"
		<Directory "/web/www/html">
		ServerName www.maxie.com:80
		
```


##### 3、创建网页主目录并进行httpd语法检查

```bash
$ mkdir -pv /web/www/html
$ httpd -t
```
	
##### 4、启动服务，并测试	
	
```
$ vim /web/www/html/index.html 
hello world 
$ service httpd start 
```

##### 5、测试完之后，开始配置虚拟主机。
打开浏览器输入 `http://www.maxie.com`，测试是否能打开并显示 `hello world`的信息

##### 6、注释掉Main主机的配置文件，也就是主配置文件内的"DocumentRoot"这一行信息需要注释掉

```
$ vim /etc/httpd/conf/httpd.conf
#DocumentRoot "/web/www/html"
$ httpd -t
```

##### 7、开始配置虚拟主机文件：

我们这里把第二题中的https的配置也一同配置好了，但是不启用，注释掉即可，之后再配置https时，取消注释，修改端口号即可：


```
[root@httpd-6 ssl]# vim /etc/httpd/conf.d/www1.maxie.com.conf
<VirtualHost *:80>
    DocumentRoot /web/www/html/www1/
    ServerName www1.maxie.com
        <Directory "/web/www/html/www1/">
                Options None
                AllowOverride None

                Order allow,deny
                Deny from 192.168.1.0/24
                Allow from all
        </Directory>

        <Location "/server-status">
                AuthType Basic
                AuthName "please input admin account and passwd!!!"
                AuthUserFile "/etc/httpd/conf.d/.htpasswd"
                SetHandler server-status
                Require valid-user
        </Location>
    ErrorLog /var/log/httpd/www1/error_log
    CustomLog /var/log/httpd/www2/access_log common
</VirtualHost>

[root@httpd-6 ssl]# vim /etc/httpd/conf.d/www2.maxie.com.conf
<VirtualHost *:80>
    DocumentRoot /web/www/html/www2/
    ServerName www2.maxie.com
#SSLEngine on
#SSLCipherSuite DEFAULT:!EXP:!SSLv2:!DES:!IDEA:!SEED:+3DES
#SSLCertificateFile /etc/httpd/ssl/httpd.crt
#SSLCertificateKeyFile /etc/httpd/ssl/httpd.key
        <Directory "/web/www/html/www2/">
                Options None
                AllowOverride None
                Order allow,deny
                Allow from all
        </Directory>

    ErrorLog /var/log/httpd/www2/error_log
    CustomLog /var/log/httpd/www2/access_log common
</VirtualHost>
```

##### 8、配置完成后，检查语法，并重启服务

```
$ httpd -t 
$ service httpd restart 
```

##### 9、打开浏览器验证这两个虚拟主机是否配置成功

在浏览器输入`http://www1.maxie.com` 和 `http://www2.maxie.com`

![](https://ws1.sinaimg.cn/large/006tNc79ly1fg5rz33j9tj31hg0oajye.jpg)

**至此第一题要求已完成**

-------

#### 第二题操作步骤：

##### 1、使用另一台虚拟机作为我们的CA服务器，并在其上进行自签的操作

```
生成CA私钥：
[root@lamp-server ~]# (umask 077;openssl genrsa -out /etc/pki/CA/private/cakey.pem)
Generating RSA private key, 1024 bit long modulus
.............++++++
.........................................................++++++
e is 65537 (0x10001)

CA自签：
[root@lamp-server ~]# openssl req -new -x509 -key /etc/pki/CA/private/cakey.pem -out /etc/pki/CA/cacert.pem
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:CN
State or Province Name (full name) []:Beijing
Locality Name (eg, city) [Default City]:Beijing
Organization Name (eg, company) [Default Company Ltd]:CAorg
Organizational Unit Name (eg, section) []:CA
Common Name (eg, your name or your servers hostname) []:ca.com
Email Address []:

[root@lamp-server ~]# ll /etc/pki/CA/cacert.pem
-rw-r--r-- 1 root root 944 5月  27 12:19 /etc/pki/CA/cacert.pem

[root@lamp-server ~]# ll /etc/pki/CA/
总用量 20
-rw-r--r--  1 root root  944 5月  27 12:19 cacert.pem
drwxr-xr-x. 2 root root 4096 6月  29 2015 certs
drwxr-xr-x. 2 root root 4096 6月  29 2015 crl
drwxr-xr-x. 2 root root 4096 6月  29 2015 newcerts
drwx------. 2 root root 4096 5月  27 12:18 private

[root@lamp-server ~]# touch /etc/pki/CA/{serial,index.txt}
[root@lamp-server ~]# echo 01 >/etc/pki/CA/serial
```

###### 2、在httpd服务器上的操作

```
[root@httpd-6 ssl]# yum install mod_ssl                                 #安装ssl组件
[root@httpd-6 ssl]# vim /etc/httpd/conf.d/www2.maxie.com.conf           #取消之前注释信息

[root@httpd-6 ssl]# (umask 077; openssl genrsa -out httpd.key)          #生成http的私钥
Generating RSA private key, 1024 bit long modulus
...............................++++++
....................++++++
e is 65537 (0x10001)
[root@httpd-6 ssl]# ll
总用量 4
-rw------- 1 root root 887 5月  25 12:46 httpd.key

[root@httpd-6 ssl]# openssl req -new -key httpd.key -out httpd.csr          #生成签署请求证书
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:CN
State or Province Name (full name) []:Beijing
Locality Name (eg, city) [Default City]:Beijing
Organization Name (eg, company) [Default Company Ltd]:CAorg
Organizational Unit Name (eg, section) []:Ops
Common Name (eg, your name or your server's hostname) []:www2.maxie.com
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:

[root@httpd-6 ssl]# scp httpd.csr root@172.16.1.20:/root                #将要签署的证书发送给CA服务器，请求其签署
root@172.16.1.20's password:
httpd.csr                                                              100%  651     0.6KB/s   00:00
```

##### 3、在CA服务器上进行签署证书的操作

```
[root@lamp-server ~]# openssl ca -in httpd.csr -out /etc/pki/CA/certs/httpd.crt             #对httpd服务器的请求证书进行签署操作
Using configuration from /etc/pki/tls/openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1 (0x1)
        Validity
            Not Before: May 27 04:24:27 2017 GMT
            Not After : May 27 04:24:27 2018 GMT
        Subject:
            countryName               = CN
            stateOrProvinceName       = Beijing
            organizationName          = CAorg
            organizationalUnitName    = Ops
            commonName                = www2.maxie.com
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Comment:
                OpenSSL Generated Certificate
            X509v3 Subject Key Identifier:
                EA:D7:21:76:1C:9C:89:61:DB:B9:6A:5C:37:DD:FD:F6:C3:5A:B9:2E
            X509v3 Authority Key Identifier:
                keyid:EC:0D:8A:1D:98:03:F8:E5:BC:13:C4:9E:89:C6:30:FE:22:10:9D:E0

Certificate is to be certified until May 27 04:24:27 2018 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated

[root@lamp-server ~]# ls
anaconda-ks.cfg  httpd.csr  local.repo
[root@lamp-server ~]#
[root@lamp-server ~]# ls /etc/pki/CA/certs/
httpd.crt
[root@lamp-server ~]# scp /etc/pki/CA/certs/httpd.crt root@172.16.1.62:/etc/httpd/ssl       #将签署好的证书发送给httpd服务器
The authenticity of host '172.16.1.62 (172.16.1.62)' can't be established.
RSA key fingerprint is 8f:a7:5e:07:a3:43:a1:0b:6f:9e:62:74:e0:60:f3:a1.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.16.1.62' (RSA) to the list of known hosts.
root@172.16.1.62's password:
httpd.crt                                                              100% 3056     3.0KB/s   00:00
```

##### 4、在Httpd服务器上接收证书，在CA服务器上发送CA的证书到客户端，导入浏览器内，测试https是否配置成功

下面操作在客户端上执行：(Mac客户端)
		
![](https://ws1.sinaimg.cn/large/006tNc79ly1fg5swsct4sj31020een46.jpg)

打开浏览器导入证书，并输入网址进行测试：

![](https://ws2.sinaimg.cn/large/006tNc79ly1fg5t3iglm3g30qo0uwx75.gif)


-------


{% note success %}### 在CentOS7上完成如上实验
{% endnote %}

为了区别于CentOS6，我们这里两台虚拟主机的FQDN为：

```
1、www.maxiecloud.com
2www.mcy95.com
```

#### 第一题操作步骤:

##### 1、安装httpd服务	

```
$ yum install httpd 
```

##### 2、编辑httpd配置文件
	
```bash
$ vim /etc/httpd/conf/httpd.conf
修改其中下面的值：
		DocumentRoot "/web/www/html"
		<Directory "/web/www/html">
		ServerName www.maxiecloud.com:80
		
```


##### 3、创建网页主目录并进行httpd语法检查

```bash
$ mkdir -pv /web/www/html
$ httpd -t
```
	
##### 4、启动服务，并测试	
	
```
$ vim /web/www/html/index.html 
hello world 
$ systemctl start httpd.service 
```

##### 5、测试完之后，开始配置虚拟主机。

打开浏览器输入 `http://www.maxiecloud.com`，测试是否能打开并显示 `hello world`的信息

##### 6、在CentOS7上无需注释掉Main主机的配置文件


##### 7、开始配置虚拟主机文件：

我们这里把第二题中的https的配置也一同配置好了，但是不启用，注释掉即可，之后再配置https时，取消注释，修改端口号即可：

```
[root@httpd-7 ~]# vim /etc/httpd/conf.d/maxiecloud.conf
	<VirtualHost *:80>
	        ServerName www.maxiecloud.com
	        DocumentRoot "/web/www/html/maxiecloud/"
	        <Directory "/web/www/html/maxiecloud/">
	                Options None
	                AllowOverride None
	                Require not ip 192.168.1.0/24
	                Require all granted
	        </Directory>
	
          <Location "/server-status">
                AuthType Basic
                AuthName "please input admin account and passwd!!!"
                AuthUserFile "/etc/httpd/conf.d/.htpasswd"
                SetHandler server-status
                Require valid-user
            </Location>
	      
	        CustomLog "/var/log/httpd/maxiecloud/access_log"  combined
	        ErrorLog "/var/log/httpd/maxiecloud/error_log"
	</VirtualHost>

[root@httpd-7 ~]# cp /etc/httpd/conf.d/maxiecloud.conf /etc/httpd/conf.d/mcy95.conf

[root@httpd-7 ~]# vim /etc/httpd/conf.d/mcy95.conf
	<VirtualHost *:80>
	        ServerName www.mcy95.com
	        DocumentRoot "/web/www/html/mcy95/"
#SSLEngine on
#SSLCipherSuite DEFAULT:!EXP:!SSLv2:!DES:!IDEA:!SEED:+3DES
#SSLCertificateFile /etc/httpd/ssl/httpd.crt
#SSLCertificateKeyFile /etc/httpd/ssl/httpd.key

	        <Directory "/web/www/html/mcy95/">
	                Options None
	                AllowOverride None
	                Require all granted
	        </Directory>
	        CustomLog "/var/log/httpd/mcy95/access_log"  combined
	        ErrorLog "/var/log/httpd/mcy95/error_log"
	</VirtualHost>

[root@httpd-7 ~]# mkdir /web/www/html/{mcy95,maxiecloud}
```

##### 8、创建虚拟机主机的日志记录

```
[root@httpd-7 ~]# mkdir /var/log/httpd/{maxiecloud,mcy95}
[root@httpd-7 ~]# httpd -t
```

##### 9、重启服务测试：

```
[root@httpd-7 ~]# httpd -t
[root@httpd-7 ~]# systemctl restart httpd.service
```

##### 10、浏览器键入两个虚拟主机地址

`http://www.maxiecloud.com/`

![](https://ws1.sinaimg.cn/large/006tNc79ly1fg5tkuu9ygj31hc0pkahw.jpg)

`http://www.mcy95.com/`


**测试server-status页面**（CentOS6与CentOS7)

![](https://ws1.sinaimg.cn/large/006tNbRwly1fg5u0060dug30qo0uw7wv.gif)


**至此第一题已经全部完成**


-------

#### 第二题操作步骤：

##### 1、创建CA服务器，生成CA自签证书

```
$ (umask 077;openssl genrsa -out /etc/pki/CA/private/cakey.pem 2048)
$ openssl req -new -x509 -key /etc/pki/CA/private/cakey.pem -out /etc/pki/CA/cacert.pem -days 2017
$ touch /etc/pki/CA/{serial,index.txt}
$ echo 01 >/etc/pki/CA/serial
```

##### 2、httpd服务器制作私钥以及签署请求，并发送给CA服务器：

```
[root@httpd-7 ~]# yum install mod_ssl                                 #安装ssl组件
[root@httpd-7 ~]# vim /etc/httpd/conf.d/mcy95.conf                    #取消之前注释信息

[root@httpd-7 ~]# mkdir /etc/httpd/ssl
[root@httpd-7 ~]# cd /etc/httpd/ssl

[root@httpd-7 ssl]# (umask 077;openssl genrsa -out httpd.key 2048)
Generating RSA private key, 2048 bit long modulus
.........................................................................................+++
....+++
e is 65537 (0x10001)
[root@httpd-7 ssl]# ls
httpd.key

[root@httpd-7 ssl]# openssl req -new -key httpd.key -out httpd.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:CN
State or Province Name (full name) []:Beijing
Locality Name (eg, city) [Default City]:Beijing
Organization Name (eg, company) [Default Company Ltd]:MageEdu
Organizational Unit Name (eg, section) []:www.mcy95.com
Common Name (eg, your name or your server's hostname) []:^C
[root@httpd-7 ssl]# openssl req -new -key httpd.key -out httpd.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:CN
State or Province Name (full name) []:Beijing
Locality Name (eg, city) [Default City]:Beijing
Organization Name (eg, company) [Default Company Ltd]:MageEdu
Organizational Unit Name (eg, section) []:Ops
Common Name (eg, your name or your server's hostname) []:www.mcy95.com
Email Address []:mcy95@magedu.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
[root@httpd-7 ssl]#
[root@httpd-7 ssl]# ll
总用量 8
-rw-r--r-- 1 root root 1054 5月  31 20:47 httpd.csr
-rw------- 1 root root 1679 5月  31 20:45 httpd.key

[root@httpd-7 ssl]# scp httpd.csr root@172.16.1.62:/root
The authenticity of host '172.16.1.62 (172.16.1.62)' can't be established.
RSA key fingerprint is 8f:a7:5e:07:a3:43:a1:0b:6f:9e:62:74:e0:60:f3:a1.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.16.1.62' (RSA) to the list of known hosts.
root@172.16.1.62's password:
httpd.csr                                                              100% 1054     1.0KB/s   00:00
```

##### 3、让CA签署请求证书，并发送签署后的证书到httpd服务器：

```
[root@CA-server ~]# openssl ca -in /root/httpd.csr -out /etc/pki/CA/certs/httpd.crt
Using configuration from /etc/pki/tls/openssl.cnf
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 1 (0x1)
        Validity
            Not Before: May 31 12:48:52 2017 GMT
            Not After : May 31 12:48:52 2018 GMT
        Subject:
            countryName               = CN
            stateOrProvinceName       = Beijing
            organizationName          = MageEdu
            organizationalUnitName    = Ops
            commonName                = www.mcy95.com
            emailAddress              = mcy95@magedu.com
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Comment:
                OpenSSL Generated Certificate
            X509v3 Subject Key Identifier:
                29:5A:D6:5B:DD:FE:0F:62:4C:01:BE:4F:92:69:66:E5:F0:5B:4A:C3
            X509v3 Authority Key Identifier:
                keyid:53:C0:E9:71:97:CA:91:D9:D4:2A:71:5D:3F:AE:D3:C6:BA:5F:73:0D

Certificate is to be certified until May 31 12:48:52 2018 GMT (365 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
[root@CA-server ~]#

[root@CA-server ~]# scp /etc/pki/CA/certs/httpd.crt root@172.16.1.61:/etc/httpd/ssl
The authenticity of host '172.16.1.61 (172.16.1.61)' can't be established.
RSA key fingerprint is d3:a9:c3:ce:e3:ce:69:04:db:26:c0:fb:1f:26:81:05.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.16.1.61' (RSA) to the list of known hosts.
root@172.16.1.61's password:
httpd.crt                                                              100% 4588     4.5KB/s   00:00
```

##### 4、在客户端导入CA的自签证书，通过浏览器验证是否配置完成https：


下面操作在客户端上执行：(Mac客户端)
		
![](https://ws1.sinaimg.cn/large/006tNc79ly1fg5swsct4sj31020een46.jpg)

打开浏览器导入证书，并测试


**至此，第二题的配置就全部完成了**



-------


{% note danger %}###  LAMP之搭建phpwind,wordpress,discuz
{% endnote %}

实验环境为CentOS7

**哔哩哔哩视频源：**

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=10983961&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>

-------

{% note warning %}###  LAMP之搭建phpMyadmin
{% endnote %}

实验环境为CentOS7

**哔哩哔哩视频源：**

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=10994770&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>


-------

{% note primary %}###  CentOS6配置httpd虚拟主机以及https功能
{% endnote %}

实验环境为CentOS6

**哔哩哔哩视频源：**

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=11000344&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>


-------


上述实验文档：[dropbox共享](https://www.dropbox.com/s/dhl5zfnfd0s6rxl/6.5%E8%AF%BE%E5%90%8E%E5%8D%9A%E5%AE%A2%E4%BD%9C%E4%B8%9A.txt?dl=0
)

-------



<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=29789260&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



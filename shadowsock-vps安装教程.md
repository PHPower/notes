---
title: shadowsock VPS CentOS 完整安装教程
date: 2017-03-28 22:07:11
tags: [linux,,vps,shadowsocks]
categories: shadowsocks
---

**首先需要在购买的VPS上安装`Python`、`pip`和`shadowsocks`**

>   yum install python-setuptools && easy_install pip
> 
>   pip install shadowsocks

<!-- more -->

**对shadowsocks进行配置**

>   vi /etc/shadowsocks.json
> 

shadowsocks.json文件内容如下：

>   
>   
>       { "server":"你的 IP地址", 
>
>       "server_port":"自定义端口", 
>
>       "local_address":"127.0.0.1", 
>
>       "local_port":1080, 
>
>       "password":"MyPass", 
>
>       "timeout":600,
>
>        "method":"rc4-md5" }

复制完成后，按 Esc 键退出编辑模式，此时putty黑框左下角的 -- INSERT -- 字样消失，按下 : 键，输入 wq 后回车，此时文件保存完毕并退出了vi编辑器。（“ : ”的输入方法为“Shift+字母L右侧的分号键”）

**各参数意义：**

server:服务器（VPS）IP地址

server_port：服务器端口

local_port:本地端端口

password:用来加密的密码

timeout:超时时间（秒）

method:加密方法，可选择 “bf-cfb”, “aes-256-cfb”, “des-cfb”, “rc4″


**继续配置shadowsocks服务**

>    vi /etc/supervisord.conf

将以下内容复制到此文件的尾部。在vi中光标快速到文件尾部，使用大写`G键`即可；使用`o键`即可在文件尾部下的一行开始输入文本。

> [program:shadowsocks]
command=ssserver -c /etc/shadowsocks.json
autostart=true
autorestart=true
user=root
log_stderr=true
logfile=/var/log/shadowsocks.log
>

复制完成后，按下回车键给文件尾部留出空行，然后按 Esc 键退出编辑模式，此时putty黑框左下角的 -- INSERT -- 字样消失，按下 : 键，输入 wq 后回车，此时文件保存完毕并退出了vi编辑器。

**编辑Linux下开机启动任务文件**

>    vi /etc/rc.local

将以下内容，复制到此文件的空行处即可。

> service supervisord start

复制完成后，按下回车键给文件尾部留出空行，然后按 Esc 键退出编辑模式，此时putty黑框左下角的 -- INSERT -- 字样消失，按下 : 键，输入 wq 后回车，此时文件保存完毕并退出了vi编辑器。


**如果你vps的操作系统是CentOS7，则需要关闭防火墙firewall**

**防火墙开启需要设置的端口**

> firewall-cmd --zone=public --add-port=443/tcp --permanent

**各参数含义：**

--zone：作用域

--add-port=8388/tcp：添加端口，格式为：端口/通讯协议

--permanent：永久生效，没有此参数重启后失效


**设置完防火墙后，需要重启防火墙**

> firewall-cmd --reload

**最后执行命令**

>    reboot

此时，你的VPS重新启动，服务端已经完全配置完毕，使用shadowsocks客户端即可实现科学上网。

**如果不想重启vps，则执行以下命令，即可立即使ss生效**

> ssserver -c /etc/shadowsocks.json -d start


-------


**shadowsocks客户端配置**

至此，shadowsocks的服务端已经部署完成。剩下的就是下载客户端安装到你的手机和电脑上，记得修改客户端的相关设置保持和你的服务端参数一致。

> [Android客户端下载链接](https://play.google.com/store/apps/details?id=com.github.shadowsocks)
> 
> [Windows客户端下载链接](https://github.com/shadowsocks/shadowsocks-windows)
> 
> [MacOS客户端下载链接](https://github.com/shadowsocks/shadowsocks-iOS/wiki/Shadowsocks-for-OSX-%E5%B8%AE%E5%8A%A9)
> 
> [IOS客户端下载链接](https://itunes.apple.com/us/app/shadowrocket-for-shadowsocks/id932747118)



**至此，关于在VPS上搭建shadowsocks的教程已经全部讲解完毕。如果有什么问题，可以在留言区留言。**


-------

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



<!--author：maxie（马驰原）-->
<!--QQ：17045930-->


---
title: 开源堡垒机JumpServer的安装
date: 2017-04-02 18:09:53
tags: [linux,堡垒机,开源,jumpserver]
categories: Linux
---

<blockquote class="blockquote-center">完全开源、极致省力、界面美观、功能完整

    --JumpServer的特性
</blockquote>

Jumpserver Jumpserver 是一款由python编写开源的跳板机(堡垒机)系统，实现了跳板机应有的功能。基于ssh协议来管理，客户端无需安装agent。

<!-- 标签 方式，要求版本在0.4.5或以上 -->
{% fullimage /images/jumpserver.jpg, jumpserver, %}






<!-- more -->


**支持常见系统:**

1. CentOS, RedHat, Fedora, Amazon Linux
2. Debian
3. SUSE, Ubuntu
4. FreeBSD
5. 其他ssh协议硬件设备


###  安装JumpServer

{% note primary %} 安装的环境为CentOS7{% endnote %}

 此次具体安装过程如下：

#### 1.安装依赖


`yum install -y git `

![](https://ww4.sinaimg.cn/large/006tNbRwly1fe8k1n4x18j313i08q0u5.jpg)

#### 2.下载JumpSerer

注意安装时当前所在的工作目录，不要在/root目录下安装。

```bash
cd /opt
git clone https://github.com/jumpserver/jumpserver.git
```

![](https://ww1.sinaimg.cn/large/006tNbRwly1fe8kadz13vj313i05w40f.jpg)

#### 3.开始安装JumpServer


```bash
cd jumpserver/install/
./install.py
```

![](https://ww3.sinaimg.cn/large/006tNbRwly1fe8kd37km2j313k0eiad1.jpg)
![](https://ww1.sinaimg.cn/large/006tNbRwly1fe8kew6owij313i07cju1.jpg)
这里如果之前安装过MySQL就无需再安装了。
jumpserver自动配置的数据库，用户名是：jumpserver；密码是5Lov@wife
![](https://ww2.sinaimg.cn/large/006tNbRwly1fe8khw9eadj313k06c75y.jpg)
这里是为之后管理员创建普通用户，在创建时直接给用户的邮箱发送账号和密码。
![](https://ww4.sinaimg.cn/large/006tNbRwly1fe8knu8cxhj313i04s0t9.jpg)
![](https://ww3.sinaimg.cn/large/006tNbRwly1fe8kpsafusj313i05ct93.jpg)
这里为管理员设置密码，接下来就是登陆ip看看我们的jumpserver是否运行正常！
![](https://ww3.sinaimg.cn/large/006tNbRwly1fe8kr4o3b0j313i07owfx.jpg)


###  验证JumpServer

浏览器输入 123.56.100.148:8000
就可以查看我们搭建的jumpserver是否成功了！

![](https://ww1.sinaimg.cn/large/006tNbRwly1fe8kyg57apj31hc0uuq4i.jpg)


**果真搭起来了，让我们输入密码进入吧**

![](https://ww4.sinaimg.cn/large/006tNbRwly1fe8kyzcmyfj31hc0uun31.jpg)

**这里的主机是我搭起来之后添加的。。 :)**


*至此，Centos7搭建JumpServer开源堡垒机的教程就完啦！*


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=79938&auto=0&height=66"></iframe>


本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



<!--author：maxie（马驰原）-->
<!--QQ：17045930-->




---
title: Linux文件系统结构介绍
date: 2017-03-24 20:48:02
tags: [linux,FHS]
categories: linux基础知识
---

**按照分层结构分析**
    


>Linux中不同发行版本之间的文件系统差别很少，主要表现在系统管理的特色工具以及软件包管理方式的不同，文件目录结构基本都是一样的。
>这是因为FHS（Filesystem Hierarchy Standard）定义了Linux操作系统中的主要目录及目录内容。


-------

# Linux的文件是什么？

一个对于UNIX系统文件的简单描述，对于Linux也适用：

> 对于UNIX操作系统，everything is a file（一切皆文件）；若非文件，则为进程

*下面的图就很好的阐述了Linux文件系统的层次关系（[高清图下载地址(PDF格式)](http://www.blackmoreops.com/wp-content/uploads/2015/06/Linux-File-System-Hierarchy-blackMORE-Ops.pdf)）*


![FHS](https://ww3.sinaimg.cn/large/006tNbRwly1fdy8q57bayj31kw1494qq.jpg)

<!-- more -->

-------


## Linux文件系统描述

   **由上图可以看出来其实Linux文件系统结构是一个倒置的树状结构。**
    







-------





| 目录 | 描述 |
| :-: |--- |
| `/` |第一层次结构的’根’，整个文件系统层次结构的根目录 |
| `/boot` |  存放引导文件目录、内核文件(vmlinuz)、引导加载器(bootloader,grub)例如kernel、initrd；不可单独分区 |
| `/bin` |提供所有用户使用的基本命令；不能关联至独立分区，系统启动即会用到的横须；例如：cat、ls、cp|
| `/sbin` | 必要的系统二进制文件；管理类的基本命令； 例如：init、ip、mount |
| `/lib` | 启动时程序依赖的基本共享库文件以及内核模块文件(lib/modules) |
| `/lib64` | 专用于x86_64系统上的辅助共享库文件存放位置 |
| `/cgroup` | 用来做资源限制和资源隔离 |
| `/dev` | device，存放系统设备文件； 例如：/dev/null |
| `/etc` | 各种系统包括应用的配置文件 |
| `/home` | 用户的家目录，包含保存的文件、个人设置等，一般为单独的分区 |
| `/root` | root用户的家目录 |
| `/lost+found` | 垃圾回收站 |
| `/media` | 各类移动存储设备挂载点； 例如：CD-rom,USB，HardDisk |
| `/misc` | 存放杂项、不好归类的文件 |
| `/tmp` | 临时文件，在系统重启时目录中文件不会被保留 |
| `/mnt` | 临时挂载点 |
| `/opt` | 第三方应用的安装位置 |
| `/net` | 网络文件 |
| `/selinux` | SElinux安全组件 |
| `/srv` | 站点的具体数据，由系统提供 |
| `/var` | 变量文件——在正常运行的系统中其内容不断变化的文件，如日志，脱机文件和临时电子邮件。 |
| `/var/cache` | 应用程序缓存数据。这些数据是在本地生成的一个耗时的I/O或计算结果。应用程序必须能够再生或恢复数据。缓存的文件可以被删除而不导致数据丢失 |
| `/var/lib` | 状态信息。由程序在运行时维护的持久性数据。 例如：数据库、包装的系统元数据等 |
| `/var/lock` | 锁文件 |
| `/var/log` | 日志文件，包含大量日志文件 |
| `/var/log/messages` | 系统日志 |
| `/var/log/dmesg` | 系统硬件信息/内核信息 |
| `/var/log/cron` | 计划任务日志 |
| `/proc` | 虚拟文件系统，将内核与进程状态归档为文本文件。 例如：uptime、network |
| `/sys` | 虚拟文件系统，记录系统硬件的一些运行信息 |
| `/usr` | UNIX Software Resource，用于存储只读用户数据的第二层次；包含绝大多数的(多)用户工具和应用程序 |
| `/usr/bin` | 非必要可执行文件(在单用户模式中不需要) |
| `/usr/include` | 标准包含文件；存放头文件 |
| `/usr/lib` | /usr/bin和/usr/sbin中二进制文件的库 |
| `/usr/sbin` | 非必要的系统二进制文件  |
| `/usr/share` | 帮助文件 |
| `/usr/src` | 源代码； 例如：内核源代码及其头文件 |
| `/usr/local` | 本地数据的第三层次，具体到本台主机。通常而言有进一步的子目录 |


-------


## Linux中的文件类型

* [元数据 metedata](https://zh.wikipedia.org/wiki/%E5%85%83%E6%95%B0%E6%8D%AE)：用于标识数据的特性，比如数据的属主和属组、数据修改时间、数据大小、访问时间、属性等等

    **使用stat命令可以查看其元数据信息**
    
```bash
$ stat maxie.txt

  File: ‘maxie.txt’
  Size: 15              Blocks: 8          IO Block: 4096   regular file
Device: ca01h/51713d    Inode: 1557867     Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2017-03-24 22:11:35.199180520 +0800
Modify: 2017-03-24 22:11:35.199180520 +0800
Change: 2017-03-24 22:11:35.209180707 +0800
 Birth: -
```

* 数据 data：存放数据资源

**使用cat命令可以查看文件内存放的数据**


```bash
$ cat maxie.txt
```

-------


## Linux文件名规则

1. 文件名最长255个字节
2. 包括路径在内文件名称最长4096个字节
3. 除了`/`和`NULL`，所有字符都有效，但是用特殊字符的目录和文件不推荐使用，有些字符需要引号来引用他们
4. 区别文件名大小写
5. 尽量不要使用`-`号开头来命名文件(*作者亲身经历啊，真难删啊*)




<br></br>

**注：**
    *1.[FHS官方文档网址](http://www.pathname.com/fhs/)*    



-------
<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=857896&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



<!--author：maxie（马驰原）-->
<!--QQ：17045930-->




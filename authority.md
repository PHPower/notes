---
title: 用户及权限管理
date: 2017-01-17 17:36:59
tags: [linux,authority]
categories: linux基础知识
---

# Linux权限管理

对于Linux而言，文件其实就是一切，而**文件的权限**则至关重要。

## 权限概念

通过`ls -l`可以查看当前目录下所有文件以及目录的详细信息

```bash
[centos@node /]$ ls -l
total 60
lrwxrwxrwx   1 root root     7 May  3  2016 bin -> usr/bin
dr-xr-xr-x   4 root root  4096 Jul 25 16:23 boot
drwxr-xr-x  19 root root  2920 Jan  9 08:17 dev
drwxr-xr-x  81 root root  4096 Jan 17 09:00 etc
drwxr-xr-x   3 root root  4096 Jan 17 09:00 home
lrwxrwxrwx   1 root root     7 May  3  2016 lib -> usr/lib
lrwxrwxrwx   1 root root     9 May  3  2016 lib64 -> usr/lib64
drwx------   2 root root 16384 May 12  2016 lost+found
drwxr-xr-x   2 root root  4096 Aug 12  2015 media
······
```

-------


### 文件类型

`dr-xr-xr-x   4 root root  4096 Jul 25 16:23 boot`

这其中的`d`所占的第一个位置表示的是Linux中文件的类型。

> f：表示常规文件
> d：文件目录（完成路径映射，而非Windows系统中文件夹的功能）
> b：block device，块设备文件，支持以“block”为单位进行随机访问
> c：character device，字符设备，支持以“character”为单位进行线性访问
> l：symbolic link，符号链接文件（软链接）
> p：pipe，命名管道
> s：socket，套接字文件

![](https://ww3.sinaimg.cn/large/006tNbRwgy1fdwvuk5o6uj30zk0zkn86.jpg)

<!-- more -->

### 文件权限

`dr-xr-xr-x   4 root root  4096 Jul 25 16:23 boot`

`r-xr-xr-x`：
1. 前三位：定义user（owner）的权限
2. 中三位：定义group权限
3. 右三位：定义other权限

> r：readable，可读权限
> w：writable，可写权限
> x：excutable，可执行权限

而对于文件来说：

```
r：代表可获取文件的数据
w：代表可修改文件的数据
x：可将此文件运行为进程
```

对于目录来说：

```
r：可使用ls命令获取其下所有的文件列表
w：可修改此目录下的文件列表，即创建或删除文件
x：可cd至此目录中，且使用ls -l来获取文件的详细属性信息
```

-------


## 权限组合机制


| Linux文件系统表示 | 二进制表示 | 八进制表示 |
| --- | --- | --- |
| --- | 000 | 0 |
| --x  | 001 | 1 |
| -w- | 010 | 2 |
| -wx | 011 | 3 |
| r-- | 100 | 4 |
| r-x | 101 | 5 |
| rw-  | 110 | 6 |
| rwx | 111 | 7 |

_常用权限：664、775、750、600、755_


-------


## 权限管理命令

Linux的三类用户：
> u：属主
> g：属组
> o：其他用户
> a：所有用户

### chmod命令

chmod的三种用法：

```bash
chmod [OPTION]... MODE[,MODE]... FILE...
chmod [OPTION]... OCTAL-MODE FILE...
chmod [OPTION]... --reference=RFILE FILE...
```

1.`chmod [OPTION]... MODE[,MODE]... FILE...`

**MODE表示法：**

（1） _赋权表示法：直接操作一类用户所有权限位rwx_

```bash
[centos@node ~]$ chmod u=rwx fstab
[centos@node ~]$ ll
total 20
-rwxr--r-- 1 centos centos  313 Jan 17 19:00 fstab

[centos@node ~]$ chmod u=rw,g=rw,o= fstab
[centos@node ~]$ ll
total 20
-rw-rw---- 1 centos centos  313 Jan 17 19:00 fstab

[centos@node ~]$ chmod a=rw fstab
[centos@node ~]$ ll
total 20
-rw-rw-rw- 1 centos centos  313 Jan 17 19:00 fstab
```

（2） _授权表示法：直接操作一类用户的一个权限位或多个_

```bash
[centos@node ~]$ chmod u+x,g+x fstab
[centos@node ~]$ ll
total 20
-rwxrwxrw- 1 centos centos  313 Jan 17 19:00 fstab

[centos@node ~]$ chmod u-x fstab
[centos@node ~]$ ll
total 20
-rw-r---w- 1 centos centos  313 Jan 17 19:00 fstab
```

2.`chmod [OPTION]... OCTAL-MODE FILE...`

使用8进制对权限进行修改：

```bash
[centos@node ~]$ chmod 750 fstab 
[centos@node ~]$ ll
total 20
-rwxr-x--- 1 centos centos  313 Jan 17 19:00 fstab
```

3.`chmod [OPTION]... --reference=RFILE FILE...`

授予FILE以RFILE的权限。

```bash
[centos@node ~]$ chmod --reference=/var/log/messages fstab 
```

4.OPTION选项：

-R，--recursive：递归修改（推荐使用授权表示法时使用）


```bash
[centos@node ~]$ chmod -R g=rwx test        #使用-R选项会修改目录以及其下的所有文件、目录权限
[centos@node ~]$ ll -a test
total 8
drwxrwx--- 2 centos centos 4096 Jan 17 19:27 .
drwx------ 4 centos centos 4096 Jan 17 19:00 ..
-rw-rwxr-- 1 centos centos    0 Jan 17 19:26 test1
-rw-rwxr-- 1 centos centos    0 Jan 17 19:27 test2
-rw-rwxr-- 1 centos centos    0 Jan 17 19:27 test3
-rw-rwxr-- 1 centos centos    0 Jan 17 19:27 test4
-rw-rwxr-- 1 centos centos    0 Jan 17 19:27 test5
```

***注意：用户只能修改属主为自己的那些文件的权限***

-------

## 从属关系管理命令

### chown命令

chown的两种用法：

```bash
chown [OPTION]... [OWNER][:[GROUP]] FILE...
chown [OPTION]... --reference=RFILE FILE...
```

**OPTION**：

-R：递归修改

```bash
[root@node centos]# chown -R docker:mygrp test
[root@node centos]# ll -a test
total 8
drwxrwx--- 2 docker mygrp  4096 Jan 17 19:27 .
drwx------ 4 centos centos 4096 Jan 17 19:00 ..
-rw-rwxr-- 1 docker mygrp     0 Jan 17 19:26 test1
-rw-rwxr-- 1 docker mygrp     0 Jan 17 19:27 test2
-rw-rwxr-- 1 docker mygrp     0 Jan 17 19:27 test3
-rw-rwxr-- 1 docker mygrp     0 Jan 17 19:27 test4
-rw-rwxr-- 1 docker mygrp     0 Jan 17 19:27 test5

[root@node centos]# chown -R :centos test
[root@node centos]# ll -a test
total 8
drwxrwx--- 2 docker centos 4096 Jan 17 19:27 .
drwx------ 4 centos centos 4096 Jan 17 19:00 ..
-rw-rwxr-- 1 docker centos    0 Jan 17 19:26 test1
-rw-rwxr-- 1 docker centos    0 Jan 17 19:27 test2
-rw-rwxr-- 1 docker centos    0 Jan 17 19:27 test3
-rw-rwxr-- 1 docker centos    0 Jan 17 19:27 test4
-rw-rwxr-- 1 docker centos    0 Jan 17 19:27 test5
```

***注意：修改属组只有管理员（root）可以修改***

-------

## 文件权限的反向掩码（遮罩码）

文件的默认权限：666-umask

目录的默认权限：777-umask

**注意：之所以文件用666去减，表示文件默认不能拥有执行权限**

### umask命令

```bash
[root@node ~]# umask
0022
[root@node ~]# umask 133            #设置umask的值：umask UMASK
[root@node ~]# umask
0133
[root@node ~]# mkdir test
[root@node ~]# ll
总用量 4
drw-r--r-- 2 root root 4096 1月  17 19:59 test
```

***注意：umask MASK只对当前shell进程有效***


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=27583305&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)




<!--author：maxie（马驰原）-->
<!--QQ：17045930-->


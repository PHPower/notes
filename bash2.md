---
title: Bash的基础特性（2）
date: 2017-01-17 08:54:05
tags: [linux,bash]
categories: Bash
---

# 文件名通配 globbing

匹配模式：对多个文件名进行通配

Shell通配符：

| 字符 | 含义 | 实例 |
| :-- | :-- | :-- |
| * | 匹配任意长度的任意字符 | p*a，p与a之间可以有多个字符，也可以一个也没有。如：pa，p123a，p2a。 |
| ? | 匹配任意单个字符 | p?a，p与a之间有且只能有一个字符，可以是任意字符。如：p3a，pda。 |
| [ ] | 匹配指定范围内的任意单个字符 | [abc]，匹配abc中任意一个单个字符的文件。如：a，b，c。 |
| [\^ ] | 匹配指定范围外的任意单个字符 | [\^abc]，匹配除abc中任意一个单个字符的文件。如：d，e，f。 |

*注意：在进行文件名通配时，不分区字符大小写*

![](https://ww3.sinaimg.cn/large/006tNbRwgy1fdwvumo2tdj30zk0zkal0.jpg)

<!-- more -->

## 特殊格式通配符

```bash
[A-Z]：所有大写字母
[0-9]：所有数字
[[:upper:]]：所有大写字母
[[:lower:]]：所有小写字母
[[:alpha:]]：所有字母
[[:digit:]]：所有数字
[[:alnum:]]：所有的数字和字母
[[:space:]]：所有空白字符
[[:punct:]]：所有标点符号
```

### 通配符练习

* 显示/var目录下所有以l字母开头，以一个小写字母结尾，且中间出现一位任意字符的文件或目录。

```bash
[centos@node ~]$ ls -ld /var/l?[[:lower:]]          
drwxr-xr-x. 26 root root 4096 Jan  6 10:50 /var/lib
drwxr-xr-x.  8 root root 4096 Jan  8 16:33 /var/log
```

* 显示/etc目录下，以任意一位数字开头，且以非数字结尾的文件或目录

```bash
[centos@node ~]$ ls -ld /etc/[[:digit:]]*[^[:digit:]]       #[[:digit:]]可以使用[0-9]替换
-rw-r--r--. 1 root root 0 Jan 12 10:05 /etc/3abc23y
```

* 显示/etc目录下，以非字母开头，后面跟一个字母及其他任意长度任意字符的文件或目录

```bash
[centos@node ~]$ ls -ld /etc/[^a-z][a-z]*
-rw-r--r--. 1 root root 0 Jan 12 10:07 /etc/1bwd2a1d

[centos@node ~]$ ls -ld /etc/[^[:alpha:]][a-z]*
-rw-r--r--. 1 root root 0 Jan 12 10:07 /etc/1bwd2a1d
```
* 复制/etc目录下，所有以m字母开头，以非数字结尾的文件或目录至/tmp/magedu.com目录

```bash
[centos@node ~]$ mkdir /tmp/magedu.com
[centos@node ~]$ cp -r /etc/m*[^[:digit:]] /tmp/magedu.com/
[centos@node ~]$ ls -l /tmp/magedu.com/
total 36
-r--r--r--. 1 centos centos   33 Jan 12 10:14 machine-id
-rw-r--r--. 1 centos centos  111 Jan 12 10:14 magic
-rw-r--r--. 1 centos centos 1968 Jan 12 10:14 mail.rc
-rw-r--r--. 1 centos centos 5122 Jan 12 10:14 makedumpfile.conf.sample
-rw-r--r--. 1 centos centos 5171 Jan 12 10:14 man_db.conf
-rw-r--r--. 1 centos centos  936 Jan 12 10:14 mke2fs.conf
drwxr-xr-x. 2 centos centos   41 Jan 12 10:14 modprobe.d
drwxr-xr-x. 2 centos centos    6 Jan 12 10:14 modules-load.d
-rw-r--r--. 1 centos centos    0 Jan 12 10:14 motd
lrwxrwxrwx. 1 centos centos   17 Jan 12 10:14 mtab -> /proc/self/mounts
-rw-r--r--. 1 centos centos  570 Jan 12 10:14 my.cnf
drwxr-xr-x. 2 centos centos   31 Jan 12 10:14 my.cnf.d
```

* 复制/usr/share/man目录下，所有以man开头，后跟一个数字结尾的文件或目录至/tmp/man目录下

```bash
[centos@node ~]$ mkdir /tmp/man
[centos@node ~]$ cp -r /usr/share/man/man[[:digit:]] /tmp/man/
[centos@node ~]$ ls -l /tmp/man
total 192
drwxr-xr-x. 2 centos centos 36864 Jan 12 10:18 man1
drwxr-xr-x. 2 centos centos     6 Jan 12 10:18 man2
drwxr-xr-x. 2 centos centos 49152 Jan 12 10:18 man3
drwxr-xr-x. 2 centos centos    49 Jan 12 10:18 man4
drwxr-xr-x. 2 centos centos 12288 Jan 12 10:18 man5
drwxr-xr-x. 2 centos centos     6 Jan 12 10:18 man6
drwxr-xr-x. 2 centos centos  4096 Jan 12 10:18 man7
drwxr-xr-x. 2 centos centos 24576 Jan 12 10:18 man8
drwxr-xr-x. 2 centos centos     6 Jan 12 10:18 man9
```

* 复制/etc目录下，所有以.conf结尾，且以m,n,r,p开头的文件或目录至/tmp/conf.d目录下

```bash
[centos@node ~]$ mkdir /tmp/conf.d
[centos@node ~]$ cp -r /etc/[mnrp]*.conf /tmp/conf.d
[centos@node ~]$ ls -l /tmp/conf.d
total 28
-rw-r--r--. 1 centos centos 5171 Jan 12 10:21 man_db.conf
-rw-r--r--. 1 centos centos  936 Jan 12 10:21 mke2fs.conf
-rw-r--r--. 1 centos centos 1728 Jan 12 10:21 nsswitch.conf
-rw-r--r--. 1 centos centos   80 Jan 12 10:21 resolv.conf
-rw-r--r--. 1 centos centos  458 Jan 12 10:21 rsyncd.conf
-rw-r--r--. 1 centos centos 3232 Jan 12 10:21 rsyslog.conf
```


-------


# IO重定向及管道
## 程序IO
### 输入输出设备
**Linux设备一切皆文件**

输入设备：文件。键盘设备、文件系统上的常规文件、网卡设备文件等。

输出设备：文件。显示器、文件系统上的常规文件。网卡设备文件等。

### 程序的三种数据流
1. 输入的输入流： <-- 标准输入（stdin），键盘；
2. 输出的数据流： --> 标准输出（stdout），显示器；
3. 错误的输出流： --> 标准错误输出（stderr），显示器；

### 文件描述符 File Descriptor

标准输出：0
标准输出：1
错误输出：2

## IO重定向

### 输出重定向： >

特性：覆盖输出


```bash
[centos@node ~]$ cat /etc/issue > /tmp/issue.out
[centos@node ~]$ cat /tmp/issue.out
\S
Kernel \r on an \m
```

*注意：在root用户执行输出重定向时，不会提示是否覆盖原文件，所以在管理员模式下慎用*

### 输出重写向： >>

特性：追加输出


```bash
[centos@node ~]$ cat /etc/fstab >> /tmp/issue.out 
[centos@node ~]$ cat /tmp/issue.out
\S
Kernel \r on an \m


#
# /etc/fstab
# Created by anaconda on Fri Jan  6 10:46:24 2017
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/cl-root     /                       xfs     defaults        0 0
UUID=829a249d-bacd-4ead-b51c-e80e15acef21 /boot                   xfs     defaults        0 0
/dev/mapper/cl-swap     swap                    swap    defaults        0 0
```

### 错误输出流重定向： 2>，2>>


```bash
[centos@node ~]$ cat1 issue.out 2> test.txt
[centos@node ~]$ cat test.txt
-bash: cat1: command not found

[centos@node ~]$ cat issue.out1 2>> test.txt
[centos@node ~]$ cat test.txt
-bash: cat1: command not found
cat: issue.out1: No such file or directory
```

### 输入重定向： <


```bash
[centos@node ~]$ cat >  issue.out  <  test.txt          #从test.txt读取数据 然后输入到issue.out中
[centos@node ~]$ cat issue.out
-bash: cat1: command not found
cat: issue.out1: No such file or directory
```

## 管道
定义：连接程序，实现将前一个命令的输出直接定向给后一个程序当做输入数据流

语法：COMMAND | COMMAND1 | COMMAND2 | ...


```bash
[centos@node ~]$ cat /etc/issue | tr 'a-z' 'A-Z'
\S
KERNEL \R ON AN \M

[centos@node ~]$ who | head -2 | tr 'a-z' 'A-Z'
ROOT     TTY1         2017-01-06 10:52
ROOT     PTS/3        2017-01-12 10:00 (192.168.168.103)
```


-------
本文出自[Maxie's Notes](http://maxiecloud.com)，转载请务必保留此出处。


![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)

<br></br>
<br></br>

<!--author：maxie（马驰原）-->
<!--QQ：17045930-->






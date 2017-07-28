---
title: 磁盘配额(Quota)详解
date: 2017-04-30 13:00:59
tags: [linux,disk,quota]
categories: linux磁盘管理
---

<blockquote class="blockquote-center">Quota这个配额，字面上的意思来看就是有多少“限额”的意思。
如果是在计算机主机的磁盘使用量上呢？
以Linux来说，就是有多少容量限制的意思。
我们可以使用quota来限制Linux中用户或者组对磁盘的使用。
</blockquote>

**Quota的一般用途**

`quota` 比较常使用的几个情况是：

* 针对 WWW server，例如对每个人的网页空间的容量限制
* 针对 mail server，例如对每个人的邮件空间限制。
* 针对 ftp server，例如对每个人的最大可用网络共享空间的限制。

上面主要介绍了一些针对网络服务的设计。

下面是针对Linux系统主机上面的设置：

* 限制某一群组所能使用的最大磁盘限额（使用grpquota）
* 限制某一使用者的最大磁盘限额（使用usrquota）
* 限制某一目录的最大磁盘配额：针对旧版CentOS来说，就是以挂载点的方式进行限制，`xfs`文件系统的限制方法使用project这种模式，不过在此文章内先不介绍。

`quota`的用途大概就是这些了。

<!-- more -->

{% note primary %}## Quota的规范设置项目
{% endnote %}

`quota`针对文件系统的限制主要分为下面几个部分：

* 容量限制或文件数量限制（block或inode）

```bash
限制inode用量：可以管理使用者可创建的“文件数量”
限制block数量：管理使用者磁盘容量的限制，大多时候使用这种方式
```

* 柔性劝导与硬性规定（soft/hard）

既然是规范，当然就有限制值。不管是 inode/block ，限制值都有两个，分别是 soft 与 hard。 通常 hard 限制值要比 soft 还要高。举例来说，若限制项目为 block ，可以限制 hard 为 500MBytes 而 soft 为 400MBytes。这两个限值的意义为：

```bash
hard：表示使用者的用量绝对不会超过这个限制值，以上面的设置为例，使用者所能使用的磁盘容量绝对不会超过500MBytes，若超过这个值则系统会锁住该用户的磁盘使用权
soft：表示使用者在低于 soft 限值时 （此例中为 400MBytes），可以正常使用磁盘，但若超过 soft 且低于 hard 的限值 （介于 400~500MBytes 之间时），每次使用者登陆系统时，系统会主动发出磁盘即将爆满的警告讯息， 且会给予一个宽限时间 （grace time）。
```

* 宽限时间（grace time）

刚刚上面就谈到宽限时间了！这个宽限时间只有在使用者的磁盘用量介于 soft 到 hard 之间时，才会出现且会倒数的一个咚咚！ 由于达到 hard 限值时，使用者的磁盘使用权可能会被锁住。为了担心使用者没有注意到这个磁盘配额的问题， 因此设计了 soft 。当你的磁盘用量即将到达 hard 且超过 soft 时，系统会给予警告，但也会给一段时间让使用者自行管理磁盘。 一般默认的宽限时间为七天，如果七天内你都不进行任何磁盘管理，那么 soft 限制值会即刻取代 hard 限值来作为 quota 的限制。

以上面设置的例子来说，假设你的容量高达 450MBytes 了，那七天的宽限时间就会开始倒数， 若七天内你都不进行任何删除文件的动作来替你的磁盘用量瘦身， 那么七天后你的磁盘最大用量将变成 400MBytes （那个 soft 的限制值），此时你的磁盘使用权就会被锁住而无法新增文件了。


-------

{% note success %}## 一个EXT3文件系统的Quota实作范例
{% endnote %}

坐而言不如起而行，所以这里我们使用一个范例来设计一下如何处理Quota的设置流程。

1. 目的与账号：限制我想要让3个用户在一个组中。这3个用户分别是：maxie1，maxie2，maxie3，三个用户的密码都是123456，同属于myquotagrp这个组。
2. 账号的磁盘容量限制值：让3个用户都能够得到100MBytes的磁盘使用量（hard），文件数量不予限制。此外，只要容量超过80MBytes，就予以警告（soft）
3. 群组的限制：让群组内的用户只能使用200MBytes的容量。也就是说，如果有2个用户都使用了80MBytes时，最后一个用户只能使用（200-80*2=40MBytes）的磁盘容量了。


### 第一步，先让我们将账号的相关属性、参数和其他环境搞定好再说吧！


```bash
# 由于需要设置的账号和环境较多，我们这里使用 script 来创建环境

[root@centos7 ~]# vim addcount.sh
#创建所需的组
groupadd myquotagrp

#创建3个实验用户
for username in maxie1 maxie2 maxie3
do
        useradd -g myquotagrp $username
        echo "123456" | passwd --stdin $username
done

mkdir /mnt/myquota

[root@centos7 ~]# sh addcount.sh

检查是否执行成功：
root@centos7 ~]# id maxie1
uid=1001(maxie1) gid=1001(myquotagrp) 组=1001(myquotagrp)
[root@centos7 ~]# id maxie2
uid=1002(maxie2) gid=1001(myquotagrp) 组=1001(myquotagrp)
[root@centos7 ~]# id maxie3
uid=1003(maxie3) gid=1001(myquotagrp) 组=1001(myquotagrp)
```

### 第二步创建文件系统并挂载至/mnt/myquota

先使用之前学过的`fdisk`命令创建一个分区

```bash
[root@centos7 ~]# fdisk /dev/sdb
欢迎使用 fdisk (util-linux 2.23.2)。

更改将停留在内存中，直到您决定将更改写入磁盘。
使用写入命令前请三思。

Device does not contain a recognized partition table
使用磁盘标识符 0x38b1700d 创建新的 DOS 磁盘标签。

The device presents a logical sector size that is smaller than
the physical sector size. Aligning to a physical sector (or optimal
I/O) size boundary is recommended, or performance may be impacted.

命令(输入 m 获取帮助)：n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): p
分区号 (1-4，默认 1)：
起始 扇区 (2048-209715199，默认为 2048)：
将使用默认值 2048
Last 扇区, +扇区 or +size{K,M,G} (2048-209715199，默认为 209715199)：+10G
分区 1 已设置为 Linux 类型，大小设为 10 GiB

命令(输入 m 获取帮助)：p

磁盘 /dev/sdb：107.4 GB, 107374182400 字节，209715200 个扇区
Units = 扇区 of 1 * 512 = 512 bytes
扇区大小(逻辑/物理)：512 字节 / 4096 字节
I/O 大小(最小/最佳)：4096 字节 / 4096 字节
磁盘标签类型：dos
磁盘标识符：0x38b1700d

   设备 Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    20973567    10485760   83  Linux

命令(输入 m 获取帮助)：w
The partition table has been altered!

Calling ioctl() to re-read partition table.
正在同步磁盘。
[root@centos7 ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  100G  0 disk
├─sda1   8:1    0  500M  0 part /boot
├─sda2   8:2    0   40G  0 part /
├─sda3   8:3    0   20G  0 part /usr
├─sda4   8:4    0    1K  0 part
├─sda5   8:5    0    2G  0 part [SWAP]
├─sda6   8:6    0    1M  0 part
├─sda7   8:7    0    1G  0 part /data
└─sda8   8:8    0   10G  0 part
sdb      8:16   0  100G  0 disk
└─sdb1   8:17   0   10G  0 part
```

格式化分区，创建文件系统

```bash
[root@centos7 ~]# mkfs.ext4 /dev/sdb1
mke2fs 1.42.9 (28-Dec-2013)
Discarding device blocks: 完成
文件系统标签=
OS type: Linux
块大小=4096 (log=2)
分块大小=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
655360 inodes, 2621440 blocks
131072 blocks (5.00%) reserved for the super user
第一个数据块=0
Maximum filesystem blocks=2151677952
80 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: 完成
正在写入inode表: 完成
Creating journal (32768 blocks): 完成
Writing superblocks and filesystem accounting information: 完成
```

挂载分区至/mnt/myquota下

```bash
[root@centos7 ~]# mount /dev/sdb1 /mnt/myquota/
[root@centos7 ~]# vim /etc/fstab
UID="485c4a7c-dd90-40c3-8fd4-164888a0ff67" /mnt/myquota ext4 defaults,usrquota,grpquota 0 0
[root@centos7 ~]# mount -o remount /dev/sdb1
```

### 第三步开始配置磁盘配额

进入`/mnt/myquota`目录下开始设置磁盘配额：

```bash
[root@centos7 ~]# cd /mnt/myquota/

禁用SElinux
[root@centos7 myquota]# setenforce 0
[root@centos7 myquota]# getenforce
Disabled

创建磁盘配额数据库
[root@centos7 myquota]# quotacheck -cug /mnt/myquota/
[root@centos7 myquota]# ll
总用量 32
-rw------- 1 root root  6144 4月  28 19:59 aquota.group
-rw------- 1 root root  6144 4月  28 19:59 aquota.user
drwx------ 2 root root 16384 4月  28 19:52 lost+found
```

启动磁盘配额数据库:

```bash
[root@centos7 myquota]# quotaon /mnt/myquota/
[root@centos7 myquota]# quotaon -p /mnt/myquota/
group quota on /mnt/myquota (/dev/sdb1) is on
user quota on /mnt/myquota (/dev/sdb1) is on
```

开始对之前创建的用户和组进行磁盘配额设置：

```bash
[root@centos7 myquota]# edquota maxie1
Disk quotas for user maxie1 (uid 1001):
  Filesystem                   blocks       soft       hard     inodes     soft     hard
  /dev/sdb1                         0      81920     102400          0        0        0

通过-p选项，直接复制maxie1的配置信息，作为其他两个用户的磁盘配额配置信息：
[root@centos7 myquota]# edquota -p maxie1 maxie2
[root@centos7 myquota]# edquota -p maxie1 maxie3

创建对组的磁盘配额：
[root@centos7 myquota]# edquota -g myquotagrp
Disk quotas for group myquotagrp (gid 1001):
  Filesystem                   blocks       soft       hard     inodes     soft     hard
  /dev/sdb1                         0          0     204800          0        0        0
```

### 第四步，测试磁盘配额

修改/mnt/myquota目录的权限

```bash
[root@centos7 mnt]# chmod 777 myquota/
```

* 测试用户磁盘配额


```bash
maxie1@centos7 myquota]$ pwd
/mnt/myquota
[maxie1@centos7 myquota]$ dd if=/dev/zero of=maxie1file bs=1M count=50
记录了50+0 的读入
记录了50+0 的写出
52428800字节(52 MB)已复制，0.0307593 秒，1.7 GB/秒
[maxie1@centos7 myquota]$ ll -h
总用量 51M
-rw------- 1 root   root       7.0K 4月  28 19:59 aquota.group
-rw------- 1 root   root       7.0K 4月  28 19:59 aquota.user
drwx------ 2 root   root        16K 4月  28 19:52 lost+found
-rw-r--r-- 1 maxie1 myquotagrp  50M 4月  28 20:17 maxie1file
[maxie1@centos7 myquota]$ dd if=/dev/zero of=maxie1file bs=1M count=81
sdb1: warning, user block quota exceeded.
记录了81+0 的读入
记录了81+0 的写出
84934656字节(85 MB)已复制，0.0545585 秒，1.6 GB/秒
[maxie1@centos7 myquota]$ dd if=/dev/zero of=maxie1file bs=1M count=101
sdb1: warning, user block quota exceeded.
sdb1: write failed, user block limit reached.
dd: 写入"maxie1file" 出错: 超出磁盘限额
记录了101+0 的读入
记录了100+0 的写出
104857600字节(105 MB)已复制，0.0665764 秒，1.6 GB/秒
[maxie1@centos7 myquota]$ ll -h
总用量 101M
-rw------- 1 root   root       7.0K 4月  28 19:59 aquota.group
-rw------- 1 root   root       7.0K 4月  28 19:59 aquota.user
drwx------ 2 root   root        16K 4月  28 19:52 lost+found
-rw-r--r-- 1 maxie1 myquotagrp 100M 4月  28 20:17 maxie1file
```

* 测试组的磁盘配额：

先使用maxie1和maxie2用户在目录中各创建一个80MBytes的文件，再切换到maxie3用户测试

```bash
[maxie1@centos7 myquota]$ su maxie2
密码：
[maxie2@centos7 myquota]$ dd if=/dev/zero of=maxie1file2 bs=1M count=80
记录了80+0 的读入
记录了80+0 的写出
83886080字节(84 MB)已复制，0.0498647 秒，1.7 GB/秒
[maxie2@centos7 myquota]$ ll -h
总用量 161M
-rw------- 1 root   root       7.0K 4月  28 19:59 aquota.group
-rw------- 1 root   root       7.0K 4月  28 19:59 aquota.user
drwx------ 2 root   root        16K 4月  28 19:52 lost+found
-rw-r--r-- 1 maxie1 myquotagrp  80M 4月  28 20:19 maxie1file
-rw-r--r-- 1 maxie2 myquotagrp  80M 4月  28 20:20 maxie1file2

#切换到maxie3，测试组的磁盘配额限制
[maxie2@centos7 myquota]$ su maxie3
密码：
[maxie3@centos7 myquota]$ dd if=/dev/zero of=filemaxie3 bs=1M count=30
30+0 records in
30+0 records out
31457280 bytes (31 MB) copied, 0.0162361 s, 1.9 GB/s

[maxie3@centos7 myquota]$ ll -h
total 191M
-rw------- 1 root   root       7.0K Apr 28 19:59 aquota.group
-rw------- 1 root   root       7.0K Apr 28 19:59 aquota.user
-rw-r--r-- 1 maxie3 myquotagrp  30M Apr 28 20:22 filemaxie3
drwx------ 2 root   root        16K Apr 28 19:52 lost+found
-rw-r--r-- 1 maxie1 myquotagrp  80M Apr 28 20:19 maxie1file
-rw-r--r-- 1 maxie2 myquotagrp  80M Apr 28 20:20 maxie1file2

[maxie3@centos7 myquota]$ du -sh .
191M	.

[maxie3@centos7 myquota]$ dd if=/dev/zero of=filemaxie3 bs=1M count=40
40+0 records in
40+0 records out
41943040 bytes (42 MB) copied, 0.0265194 s, 1.6 GB/s

[maxie3@centos7 myquota]$ dd if=/dev/zero of=filemaxie3 bs=1M count=50
sdb1: write failed, group block limit reached.
dd: error writing ‘filemaxie3’: Disk quota exceeded
41+0 records in
40+0 records out
41943040 bytes (42 MB) copied, 0.027217 s, 1.5 GB/s

[maxie3@centos7 myquota]$ ll -h
total 201M
-rw------- 1 root   root       7.0K Apr 28 19:59 aquota.group
-rw------- 1 root   root       7.0K Apr 28 19:59 aquota.user
-rw-r--r-- 1 maxie3 myquotagrp  40M Apr 28 20:23 filemaxie3
drwx------ 2 root   root        16K Apr 28 19:52 lost+found
-rw-r--r-- 1 maxie1 myquotagrp  80M Apr 28 20:19 maxie1file
-rw-r--r-- 1 maxie2 myquotagrp  80M Apr 28 20:20 maxie1file2
[maxie3@centos7 myquota]$ du -sh .
201M	.
```

-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=16714264&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


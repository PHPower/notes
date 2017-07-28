---
title: dd命令详解
date: 2017-04-27 15:15:28
tags: [linux,dd,command]
categories: linux基础知识
---

<blockquote class="blockquote-center">dd命令可从标准输入或文件中读取数据，根据指定的格式来转换数据，再输出到文件、设备或标准输出。
dd命令非常强大，让我们一起来学习吧！
</blockquote>



## dd命令

{% note primary %}### 命令语法
{% endnote %}

dd [OPERAND]...
dd OPTION

<!-- more -->

-------


{% note success %}### 命令选项
{% endnote %}


```bash
if=文件名          输入文件名，缺省为标准输入。即指定源文件。
of=文件名          输出文件名，缺省为标准输出。即指定目的文件。
ibs=bytes         一次读入bytes个字节，即指定一个块大小为bytes个字节。
obs=bytes         一次输出bytes个字节，即指定一个块大小为bytes个字节。
bs=bytes          同时设置读入/输出的块大小为bytes个字节。
cbs=bytes         一次转换bytes个字节，即指定转换缓冲区大小。
skip=blocks       从输入文件开头跳过blocks个块后再开始复制。
seek=blocks       从输出文件开头跳过blocks个块后再开始复制。
count=blocks      仅拷贝blocks个块，块大小等于ibs指定的字节数。
```

**其中的关键字用法：**

```bash
conv=<关键字>，关键字可以有以下11种：
conversion      用指定的参数转换文件。
ascii           转换ebcdic为ascii
ebcdic          转换ascii为ebcdic
ibm             转换ascii为alternate ebcdic
block           把每一行转换为长度为cbs，不足部分用空格填充
unblock         使每一行的长度都为cbs，不足部分用空格填充
lcase           把大写字符转换为小写字符
ucase           把小写字符转换为大写字符
swab            交换输入的每对字节
noerror         出错时不停止
notrunc         不截短输出文件
sync            将每个输入块填充到ibs个字节，不足部分用空（NUL）字符补齐。
--help          显示帮助信息
--version       显示版本信息
```

-------

{% note info %}### dd命令提供的各种功能
{% endnote %}

**备份**

使用dd命令，可以将一个磁盘上的数据整个的备份到另一个磁盘上。

```bash
dd if=/dev/sdx of=/dev/sdy
将本地的/dev/sdx整盘备份到/dev/sdy

dd if=/dev/sdx of=/path/to/image
将/dev/sdx全盘数据备份到指定路径的image文件

dd if=/dev/sdx | gzip >/path/to/image.gz
备份/dev/sdx全盘数据，并利用gzip工具进行压缩，保存到指定路径
```


**恢复**

```bash
dd if=/path/to/image of=/dev/sdx
将备份文件恢复到指定盘

gzip -dc /path/to/image.gz | dd of=/dev/sdx
将压缩的备份文件恢复到指定盘
```

**拷贝内存资料到硬盘**

```bash
dd if=/dev/mem of=/root/mem.bin bs=1024
将内存里的数据拷贝到root目录下的mem.bin文件
```

**从光盘拷贝iso镜像**

```bash
dd if=/dev/cdrom of=/root/cd.iso
拷贝光盘数据到root文件夹下，并保存为cd.iso文件
```

**销毁磁盘数据**

```bash
dd if=/dev/urandom of=/dev/sda1
利用随机的数据填充硬盘，在某些必要的场合可以用来销毁数据，执行此操作以后，/dev/sda1将无法挂载，创建和拷贝操作无法执行
```

**测试硬盘读写速度**

```bash
dd if=/dev/zero of=/root/1Gb.file bs=1024 count=1000000
dd if=/root/1Gb.file bs=64k | dd of=/dev/null
通过上两个命令输出的执行时间，可以计算出测试硬盘的写/读／速度
```

**修复硬盘**

```bash
dd if=/dev/sda of=/dev/sda
当硬盘较长时间（比如1,2年）放置不使用后，磁盘上会产生消磁点。当磁头读到这些区域时会遇到困难，并可能导致I/O错误。当这种情况影响到硬盘的第一个扇区时，可能导致硬盘报废。上边的命令有可能使这些数据起死回生,且这个过程是安全高效的
```


-------


{% note danger %}### 使用dd命令制作USB启动盘
{% endnote %}

* 第一步，格式化U盘，为了格式化我们首先需要umount U盘：

```bash
$ sudo fdisk -l
```
![](http://ww3.sinaimg.cn/large/006tNc79ly1ff1bbawpirj30hw08vq4z.jpg)

使用上面命令我们可以查看到,`/dev/sdb`是我的U盘设备

下面让我们`umount` U盘，并格式化：

```bash
$ sudo umount /dev/sdb
$ sudo mkfs.vfat /dev/sdb -I
```

我们把U盘格式化成了`FAT`格式

* 第二步，开始制作启动U盘：

```bash
$ sudo dd if=~/home/maxie/CentOS7-Everything.iso of=/dev/sdb
```

上面命令把`ISO`镜像写入到U盘，等待几分钟即可。

**在Mac上使用dd命令制作启动盘**

* 第一步，查看存储设备：

```bash
$ diskutil list
```

* 第二步，使用dd命令拷贝ISO镜像到U盘：


```bash
$ sudo dd if=CentOS7-Everything.iso of=/dev/disk2
```

-------

{% note warning %}### Mac下使用命令制作Linux启动USB盘
{% endnote %}

由于作者使用的是`Mac`本，而且`Mac`使用的是`bash`，所以研究了一下，怎么在`Mac`上制作USB启动盘。

下面就让我们开始制作启动盘吧！

* 第一步，在终端下，将ISO镜像转换为DMG格式：

```bash
$ hdiutil convert -format UDRW -o ~/linux.dmg /tmp/linux.iso

正在读取Master Boot Record（MBR：0）…
正在读取Linux                       （Apple_ISO：1）…
正在读取（Windows_NTFS_Hidden：2）…
.......................................................................................................................
经过时间：14.829s
速度：145.1M 字节/秒
节省：0.0%
created: /tmp/linux.dmg
```

* 第二步，插入USB，然后在终端下，查找该设备的设备名：


```bash
$ diskutil list
/dev/disk0
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *121.3 GB   disk0
   1:                        EFI                         209.7 MB   disk0s1
   2:                  Apple_HFS Macintosh HD            120.5 GB   disk0s2
   3:                 Apple_Boot Recovery HD             650.0 MB   disk0s3
/dev/disk1
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *15.8 GB    disk1
   1:               Windows_NTFS wxy-u3                  15.8 GB    disk1s1
```

通过上面命令查看到U盘设备名是：/dev/disk1


* 卸载USB盘，但是不要`推出`：

```bash
$ diskutil umountDisk /dev/disk1
Unmount of all volumes on disk1 was successful
```

* 第四步，镜像上面生成的DMG内容到USB盘：


```bash
$ sudo dd if=linux.dmg of=/dev/rdisk1 bs=1m
Password:
2151+1 records in
2151+1 records out
2256076800 bytes transferred in 90.277905 secs (24990354 bytes/sec)
```

此处要千万注意，指定的of别写错了，否则悔之晚矣。另外，of参数指定的设备名，可以用上面找到的/dev/disk1，也可以用/dev/rdisk1，此处的“r”据说会写入较快。

另外，如果报错：“dd: Invalid number `1m'”，可能是使用的不同版本的dd，可以换为bs=1M试试。

如果报错：“dd: /dev/diskN: Resource busy”，可能是上面的步骤中没有完成卸载USB盘。

* 第五步，推出USB盘。在上面复制之后，系统可能会报错，“此电脑不能读取能插入的磁盘”，不必理会，直接推出即可。


```bash
$ diskutil eject /dev/disk1
```


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=404783635&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


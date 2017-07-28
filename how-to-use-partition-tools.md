---
title: Linux中分区工具的使用详解
date: 2017-04-22 17:16:04
tags: [linux,fdisk,partition,command]
categories: linux磁盘管理
---

<blockquote class="blockquote-center">对磁盘磁盘分区有什么好处？
优化I/O性能
实现磁盘空间配额限制
提高修复速度
隔离系统和程序
安装多个OS
采用不同文件系统
</blockquote>

**Linux中必要有的分区：**

`/`：根分区，是所有文件/目录的"父亲"。
`/boot`：boot分区，系统启动引导的分区。
`/app`：app分区，一般在生产环境中需要此分区，做到程序与系统隔离。
`swap`：swap分区是一个特殊的分区，它是相当于内存的存在。

<!-- more -->

## 分区策略

{% note primary %}### MBR分区表
{% endnote %}

在MBR分区表的设置中，引导扇区是每个分区(partition)的第一扇区，而主引导扇区是硬盘的第一扇区。

主引导扇区由三个部分组成：

1. 主引导记录MBR
2. 硬盘分区表DPT
3. 硬盘有效标志

在主引导扇区里MBR占用446bytes(字节)，分区表占用64bytes(字节)，硬盘有效标志占2bytes(字节)。

而MBR有一个特点就是：
**只有4个分区：3主分区+1扩展分区(N个逻辑分区)**


{% note success %}### GPT分区表
{% endnote %}


GPT的分区信息是在分区中，而不象MBR一样在主引导扇区，为保护GPT不受MBR类磁盘管理软件的危害，GPT在主引导扇区建立了一个保护分区（Protective MBR）的MBR分区表（此分区并不必要），这种分区的类型标识为0xEE，这个保护分区的大小在Windows下为128MB，Mac OS X下为200MB，在Window磁盘管理器里名为GPT保护分区，可让MBR类磁盘管理软件把GPT看成一个未知格式的分区，而不是错误地当成一个未分区的磁盘。

另外，为了保护分区表，GPT的分区信息使用128位UUID(Universally Unique Identifier) 表示磁盘和分区GPT分区表自动备份在头和尾两份，并有CRC校验位


-------


## 管理分区

**lsblk命令**：
    列出Linux中块设备
    
    注意：这个命令只能列出内存中的块设备信息

{% note info %}### 分区表管理工具
{% endnote %}

创建分区表工具：

```bash
fdisk       创建MBR分区
gdisk       创建GPT分区
parted      高级分区操作（创建，复制，调整大小等）
partprobe   重新设置内存中的内核分区表版本(CentOS6不适用此命令)
```

{% note danger %}### fdisk/gdisk工具
{% endnote %}

**fdisk命令：**
用于观察硬盘实体使用情况，也可对硬盘分区。它采用传统的问答式界面，而非类似DOS fdisk的cfdisk互动式操作界面，因此在使用上较为不便，但功能却丝毫不打折扣。


```bash
$ fdisk DEVICE

各选项意义：
-b <分区大小>       指定每个分区的大小
-l                 列出指定的设备的分区表状况
-s <分区编号>       将指定的分区大小输出到标准输出上，单位为区块
-u                 搭配 -l 参数列表，会用分区数目取代柱面数目，来表示每个分区的起始地址
-v                 显示版本信息 
```

**fdisk的子命令**

```bash
p           列出分区列表
t           更改分区类型
n           创建新分区
d           删除分区
w           保存并退出
q           不保存并退出
```

实例：

```bash
[root@node /]# fdisk  /dev/sdb

WARNING: DOS-compatible mode is deprecated. Its strongly recommended to
         switch off the mode (command 'c') and change display units to
         sectors (command 'u').

Command (m for help): p

Disk /dev/sdb: 214.7 GB, 214748364800 bytes
255 heads, 63 sectors/track, 26108 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x45ef120e

   Device Boot      Start         End      Blocks   Id  System

Command (m for help): n
Command action
   e   extended
   p   primary partition (1-4)
p
Partition number (1-4): 1
First cylinder (1-26108, default 1):
Using default value 1
Last cylinder, +cylinders or +size{K,M,G} (1-26108, default 26108): +10G

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```

**gdisk命令**

gdisk命令使用方法与fdisk相似，只是gdisk 是为GPT分区创建的工具。

{% note warning %}### 同步分区表
{% endnote %}

在使用 `fdisk/gdisk`工具对硬盘进行分区之后，有时会提示**硬盘分区表与内存中的分区表不同步**，这是因为**1.可能是硬盘是很旧之前挂载上来的；2.没有手动同步分区表**

那么如何同步分区表，让我们来看看吧！


**第一步**：先查看是否内核已经识别到了新的分区：

```bash
[root@node /]# cat /proc/partitions
major minor  #blocks  name

   8        0  209715200 sda
   8        1     204800 sda1
   8        2   62914560 sda2
   8       16  209715200 sdb
   8       17   10490413 sdb1
 253        0   20971520 dm-0
 253        1    2097152 dm-1
 253        2   10485760 dm-2
 253        3   20971520 dm-3
 
[root@node /]# lsblk
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                   8:0    0  200G  0 disk
├─sda1                8:1    0  200M  0 part /boot
└─sda2                8:2    0   60G  0 part
  ├─vg0-root (dm-0) 253:0    0   20G  0 lvm  /
  ├─vg0-swap (dm-1) 253:1    0    2G  0 lvm  [SWAP]
  ├─vg0-usr (dm-2)  253:2    0   10G  0 lvm  /usr
  └─vg0-var (dm-3)  253:3    0   20G  0 lvm  /var
sdb                   8:16   0  200G  0 disk
└─sdb1                8:17   0   10G  0 part
sr0                  11:0    1  2.1G  0 rom  /centos6-my
```

上面这个两条命令：

1. cat /proc/partiotion：查看内核是否已经识别新的分区
2. lsblk：这条命令我们在上面说过，也是查看分区的一个信息
3. 只要是我们创建了分区之后，使用这两条命令都没有查看到我们创建的分区名，那我们就要执行接下来的操作了，就是手动同步分区表。


**第二步**：通知内核重新读取硬盘分区表

对于CentOS6：

```bash
新增分区：
 partx -a /dev/DEVICE     一般执行3次，强制生效
 kpartx -a -f /dev/DEVICE 
删除分区：
 partx -d --nr M-N /dev/DEVICE
```

对于Centos5，7：

```bash
新增，删除分区：
 partprobe [/dev/DEVICE]
```

上面这条命令后如果不跟任何设备名，则表示更新所有设备的分区表信息。


-------


### 制作脚本自动使用fdisk创建分区

此脚本目前只能实现简单的创建功能，希望`dalao` 多多指点


```bash
[root@node ~]# cat disk-make.sh
#!/bin/bash
#FileName: disk-make.sh
#Description: just auto make a disk partition use fidsk command.
#Author: Maxie
#Date: 2017-04-20
#Version: 1.0


Hard='/dev/sda'

#grep the extended partition exist or not.
Exten=`fdisk -l $Hard|grep Extended`

#grep the max number of the partition table
Maxnum=`fdisk -l $Hard|grep -o "^/dev/sda[1-9]\>"|tr -d [[:punct:]]|tr -d 'A-Za-z'|sort -n|tail -1`

#now judge the extended and maxnum.
if [[  -z $Exten ]];then
        if [[ $Maxnum -ge 4 ]];then
#if maxnum = 4,cant make major partition and extend partition.just exit.
                echo "Disk partitions error!..."
                exit 1
        elif [ $Maxnum -eq 1 -o $Maxnum -eq 2 ];then
#       echo "1---3"
#judge the max number in 1 and 3, and make partition of the number 3
                cat << EOF
                e|E)use all free disk greate is Extended;
                *)Quit;
EOF
                Sdanum=$((Maxnum+1))
                read Opt
                case $Opt in
                e|E)
fdisk $Hard &> /opt/fdisk.log <<EOF
n
e
$Sdanum


w

EOF
                ;;
                *)
                echo "None operating ,Exit"
                exit 2
                ;;
                esac
        else
#make partition of the number 4,the last number of the partition.
                cat << EOF
        e|E)use all free disk greate is Extended;
        *)Quit;
EOF
                read Opt
                case $Opt in
                e|E)
                fdisk $Hard &> /opt/fdisk.log <<EOF
                n
                e


                w
EOF

                ;;
                *)
                echo "None operating ,Exit"
                exit 2
                ;;
                esac

        fi

elif [[ ! -z $Exten ]] && [[ $Maxnum -eq 3 ]]; then
	echo "Please input new partition szie(MB),Only number."
	read ESize
	CK=`echo "$ESize" | grep "[[:punct:]]\+"`
		while [[ $ESize -le 1 || -n $CK ]]
		do
			echo "That wrong, Please try again"
#Variable initialization
			ESize=
			read ESize
			CK=`echo "$ESize" | grep "[[:punct:]]\+"`
		done
#Variable initialization, use :- just output 50 and clear Eanswer's value
	Eanswer=${ESize:-50}
	fdisk $Hard &> /opt/fdisk.log <<EOF
	n

	l

	+${ESize}M

	w

EOF

else
        echo 'Please input new partition size(MB),Only number.'
        read Size
        Pun=`echo "$Size"|grep "[[:punct:]]\+"`
                while [[ $Size -le 1 || -n $Pun ]]
                do
                        echo "Wrong try again!"
                        Size=
                        read Size
                        Pun=`echo "$Size"|grep "[[:punct:]]\+"`
                done
        answer=${Size:-50}
        fdisk $Hard &> /opt/fdisk.log <<EOF
        n

        +${Size}M
        w

EOF
fi
```


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=406000222&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


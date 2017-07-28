---
title: Linux破坏性实验
date: 2017-05-13 15:21:25
tags: [linux,kernel,damage,recover]
categories: linux进阶
---

<blockquote class="blockquote-center">在学习Linux的过程中，不免由于"手速"过快的原因，导致执行 "rm -rf"命令时，删除了我们不想删除的文件。
这时，身为小白的我们想到的第一个解决办法就是 "重装系统"，这也不失为一个好的解决办法；
但是如果里面有我们辛辛苦苦写了几个星期的一些脚本和笔记呢？
这时候就需要使用Linux自带的 "Rescue installed system(救援模式)" 来为我们恢复了！
</blockquote>

插入 `CentOS`系统光盘，或者挂载光盘到虚拟机中；

开机按 `F2` 或者 `ESC键` ，进入到`Boot Menu`；

选择`CD-ROM Drive`即可进入到光盘启动。

进入到光盘界面，使用上下箭头选择模式，这里我们要进入到 "Rescue installed system(救援模式)"，所以选择 `第三项`

![](http://ww3.sinaimg.cn/large/006tKfTcly1ffjrt1jp05j319k0y0th7.jpg)


<!-- more -->

**注意：**
此次实验的环境为：

```bash
内核版本：2.6.32-642.el6.x86_64
系统版本：CentOS release 6.8 (Final)
虚拟机版本：VMware Fusion 专业版 8.5.3 (4696910)
```

{% note primary %}### Liunx破坏性实验(easy mode)
{% endnote %}


在这一章节，我们只做一些 一学就懂，一做就明白的实验。

#### 第一个实验：修改/etc/inittab文件中的runlevel修改成了6

`/etc/inittab`文件存放的是我们系统启动时的启动级别。

运行级别：为系统运行或维护等目的而设定；

0-6：7个级别

```bash
		0：关机
		1：单用户模式(root自动登录), single, 维护模式     无网络功能
		2: 多用户模式，启动网络功能，但不会启动NFS(默认所有模式都关闭)；维护模式
		3：多用户模式，正常模式；文本界面
		4：预留级别；可同3级别
		5：多用户模式，正常模式；图形界面
		6：重启
```

这里我们设置成 `6` 就是无限重启


```bash
$ vim /etc/inittab
id:6:initdefault:
```

![](http://ww1.sinaimg.cn/large/006tKfTcly1ffjtx4lx4xg30dw08oe8e.gif)

**解决方法：**

1. 在菜单界面，按a即可 进入grub启动选项界面；
2. 在一串选项的后面，键入 数字3 或 数字5，都可以进入多用户模式，不同的是一个是字符界面，一个是图形界面
3. 这样我们就能正常启动linux系统啦
4. 但是，不要高兴得太早，现在我们只是手动的修改了启动选项，启动配置文件还没有修改。
5. 进入系统后，修改 `/etc/inittab` 文件的runlevel等级为5即可。

![](http://ww4.sinaimg.cn/large/006tKfTcly1ffju507jp0j30zm0k6ndf.jpg)

注意最后面的 数字5

这里我们选择了 以图形化界面启动系统


-------

#### 第二个实验，忘记root（超级管理员）用户密码，如何破解？

1. 开机进入倒计时的时候，按下a键，进入到grub内核启动参数的编辑界面
2. 直接在后面输入 `single` 或者 `S` 或者 `single s` 都可以进入到 `单用户模式`
3. 系统以单用户模式启动后，无需输入任何密码，就以 `root`用户的身份登录到了系统，这样我们就可以使用 `passwd` 命令修改 `root`用户的密码了！

![](http://ww2.sinaimg.cn/large/006tNc79ly1ffjuytqqcrj30zi0jsaq5.jpg)

![](http://ww4.sinaimg.cn/large/006tNc79ly1ffjw76nq0xj318e0x2k0r.jpg)

-------


#### 第三个实验，删除/boot/vmlinuz-2.6.32-642.el6.x86_64文件，如何恢复？

1、 挂载系统光盘
2、 进入救援模式：

* 在出现VMware的界面，快速按`ESC键`，进入`boot menu`，选择`CD-ROM`选项
* 进入到光盘引导之后，选择第三项，救援模式

3、 进入到救援模式后，选择按照默认的选择一步一步的走到 `shell start shell`的界面时：
    回车进入一个`shell`终端内

![](http://ww4.sinaimg.cn/large/006tNc79ly1ffjwucb5xgg30jg0c6e8a.gif)

4、回到了我们熟悉的命令行界面，现在我们开始正式的恢复之前删除的 `vmlinuz`文件

**步骤如下：**

```bash
$ chroot /mnt/sysimage          #切根到我们真正的系统根目录上
$ mount /dev/sr0 /mnt           #挂载系统光盘
$ cp /mnt/isolinux/vmlinuz /boot/vmlinuz-`uname -r`  #拷贝光盘内的内核文件到我们的/boot目录下
$ sync
$ exit
$ reboot
```
![](http://ww1.sinaimg.cn/large/006tNc79ly1ffjx7q5m0eg30jg0c6u1d.gif)

这样就大功告成啦


{% note success %}### Linux扇区破坏性实验(normal mode)
{% endnote %}

现在开始的实验，非常危险!!!
请朋友们，在执行如下操作的时候，确保为`实验机`做了 `快照`、`备份`或者`镜像`等操作。

#### 第一个实验，破坏MBR前446个字节的信息，并恢复。

1、先执行`dd`命令，破坏MBR的前446字节
    
```bash
$ dd if=/dev/zero of=/dev/sda bs=1 count=446        #把前446字节都重写为0
$ hexdump -C -n 512 -v /dev/sda                     #查看/dev/sda的前512字节，确认446字节都被重写为0
$ reboot
```

2、开始恢复：

* 进入救援模式
* 切根

```bash
$ chroot /dev/sda
```

* 安装grub

```bash
$ grub-install /dev/sda
```

* 等待安装完毕，查看/dev/sda的信息

```bash
$ hexdump -C -n 512 /dev/sda
```

* 修复成功，重启即可

```bash
$ sync
$ exit 
$ reboot
```


-------


#### 第二个实验，破坏MBR后续的2048个字节，并恢复。(stage1.5阶段的破坏)

1、先执行`dd`命令，进行破坏

```bash
$ dd if=/dev/zero of=/dev/sda bs=1 count=2048 skip=512 seek=512       
$ hexdump -C -n 2048 -v /dev/sda   
```

2、开始恢复

* 进入救援模式
* 切根
* 进入grub命令行

```bash
$ grub
grub> root (hd0,0)          #boot分区在硬盘上的分区位置
grub> setup (hd0)           #boot分区在哪个硬盘上
grub> quit
```

* 重启，并退出救援模式

```bash
$ exit
$ reboot
```

* 修复成功！

![](http://ww2.sinaimg.cn/large/006tNc79ly1ffjxxi76mwg30jg0c67wt.gif)


-------

#### 第三个实验，删除/boot/grub/*，并恢复

1、执行删除操作

```bash
$ rm -rf /boot/grub/*
```

2、进入救援模式，开始恢复

* 切根
* 安装grub

```bash
$ grub-install /dev/sda
```

* 由于`grub-install`命令并不会为我们产生 grub.conf 配置文件，所以需要我们手写


```bash
$ vim /boot/grub/grub.conf
default 0
timeout 5
titile CentOS 6.8(Final)
    kernel /vmlinuz-2.6.32-642.el6.x86_64 root=/dev/mapper/vg0-root selinux=0
    initrd /initramfs-2.6.32-642.el6.x86_64.img
```

* 修复完成，退出救援模式，并重启

```bash
$ sync
$ exit
$ reboot
```

* 修复完成啦！！！

![](http://ww4.sinaimg.cn/large/006tNc79ly1ffjyfficrbg30jg0c6e87.gif)

-------


**以上这些就是我在学习过程中总结的各种实验步骤，希望dalao们多多指点！**


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=469535480&auto=1&height=66"></iframe> 

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



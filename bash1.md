---
title: Bash的基础特性（1）
date: 2017-01-10 16:30:55
tags: [linux,bash]
categories: Bash
---

# Bash 
> Bash是一个为GNU计划编写的Unxi Shell。它的名字是一系列缩写：Bourne-Again SHell.
> Bourne shell是一个早期的重要shell，由史蒂夫·伯恩在1978年前后编写，并同Version 7 Unix一起发布。
> Bash则在1987年由布莱恩·福克斯创造


![](https://ww3.sinaimg.cn/large/006tNbRwgy1fdwvunovm0j30zk0zkgvd.jpg)

<!-- more -->

-------

## 基础特性之一：命令历史（历史记录）
执行shell进程时会在其会话中保存此前用户提交执行过的命令。

通过在命令行输入`history`命令来达到查看历史记录的目的。

而`history`命令默认存放的是1000条执行过的命令，想要修改存放数量就必须对环境变量进行修改。



### history的四个环境变量

* `HISTSIZE`：shell进程可保留的命令历史的条数；

```bash
[root@localhost ~]# echo $HISTSIZE
1000
[root@localhost ~]# HISTSIZE="1200"
[root@localhost ~]# echo $HISTSIZE
1200
```


* `HISTFILE`：持久保存命令的文件；

通过`ls -al ~`的命令，可以得知`HISTFILE`存放于root用户的家目录下名为`.bash_history`的文件

```bash
[root@localhost /]# ls -al ~
total 40
dr-xr-x---.  2 root root  167 Jan 10 12:11 .
dr-xr-xr-x. 17 root root  224 Jan  6 10:50 ..
-rw-------.  1 root root 1287 Jan  6 10:50 anaconda-ks.cfg
-rw-------.  1 root root 6286 Jan 10 17:28 .bash_history
-rw-r--r--.  1 root root   18 Dec 29  2013 .bash_logout
-rw-r--r--.  1 root root  176 Dec 29  2013 .bash_profile
-rw-r--r--.  1 root root  176 Dec 29  2013 .bashrc
-rw-r--r--.  1 root root  100 Dec 29  2013 .cshrc
-rw-------.  1 root root   58 Jan  9 17:41 .lesshst
-rw-r--r--.  1 root root  129 Dec 29  2013 .tcshrc
-rw-------.  1 root root  896 Jan  9 18:31 .viminfo
```


* `HISEFILESIZE`：保存命令的文件大小

```bash
[root@localhost /]# echo $HISTFILESIZE
1000
```

* `HISTCONTROL`：控制命令历史记录

变量值有三种可选：
    1. ignoredups：忽略两条命令之间重复项（默认值）
    2. ignorespace：忽略以空白字符开头的命令。在输入COMMAND之前，单击键盘Space键，即可实现忽略这条COMMAND
    3. ignoreboth：以上两者同时生效


```bash
[root@localhost /]# HISTCONTROL=ignoreboth
[root@localhost /]# echo $HISTCONTROL
ignoreboth
```



**修改变量值的方法：**
`NAME='VALUE'`
*注意：这样的修改变量的方式，只会对当前shell进程生效。*


### history的命令用法
`history [-c] [-d offset] [n]`：

* -c：清空history所有记录
* -d offset：删除指定历史记录
* n：显示最近的n条历史记录

`history -anrw [filename]`：

* -r：从历史文件读取命令历史到历史列表中
* -w：把历史列表中的命令追加到历史文件中
* filename：存储在root用户家目录下的`.bash_history`



### 调用命令历史列表中的命令

`!#`：再一次执行历史列表中的第#条命令

```bash
[root@localhost ~]# !227
echo $HISTFILESIZE
1000
```

`!!`：再一次执行上一条命令（与键盘⬆️箭头功能相同）

```bash
[root@localhost /]# !!
cat /etc/system-release
CentOS Linux release 7.3.1611 (Core)
```

`!STRING`：再一次执行命令历史列表中一个以STRING开头的命令

```bash
[root@localhost ~]# !ty
type history
history is a shell builtin
```

*注意：能重复执行的命令有时候依赖于幂等性（幂等性：重复执行多次，结果不变）*

### 调用上一条命令的最后一个参数
1. 键盘快捷键：`ESC`+`.`
2. 在调用的命令后使用`!$`

```bash
[root@localhost ~]# ls /etc/sysconfig/network-scripts/ifcfg-ens33 
/etc/sysconfig/network-scripts/ifcfg-ens33
[root@localhost ~]# cat !$
cat /etc/sysconfig/network-scripts/ifcfg-ens33
TYPE="Ethernet"
BOOTPROTO="dhcp"
···
```

-------

## 基础特性之二：命令、路径补全机制

### 命令补全
shell程序在接收到用户命令的请求，分析完成之后，最左侧的字符串会被当做命令。
给定的打头字符串如果能唯一标识某命令程序文件，则直接补全；不能唯一标识的某命令程序文件，再单击`TAB`键一次，会给出列表进行补全。

##### 命令查找机制
查找内部命令：根据`PATH`环境变量中设定的目录，自左而右逐个搜索目录下的文件名

### 路径补全
根据给定的起始下，以对应路径下的打头字符串来逐一匹配起始路径下的每个文件；
**`tab`键：**

* 如果能唯一标识，则直接补全
* 否则，再一次`TAB`，给出列表


-------


## 基础特性之三：命令的执行状态结果
### 命令执行的“状态结果”
bash通过状态返回值来输出此结果：

* 成功：输出0
* 失败：输出非0，1-255之间

命令执行完成之后，其状态返回值保存于bash的特殊变量`$?`中

*注意：只能获取最近的一条命令的返回值*

### 引用命令的“执行结果”

```bash
$(COMMAND)
或者
`COMMAND`
```
## 基础特性之四：键盘快捷键

`Ctrl+a`：跳转至命令行行首
`Ctrl+e`：跳转至命令行行尾
`Ctrl+u`：删除行首至光标所在处之间的所有字符
`Ctrl+k`：删除光标所在处至行尾之间的所有字符
`Ctrl+l`：相当于clear命令


-------

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)

<br></br>
<br></br>

<!--author：maxie（马驰原）-->
<!--QQ：17045930-->



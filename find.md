---
title: find命令
date: 2017-03-19 13:48:39
tags: [command,linux]
categories: linux基础知识
---

# Find命令详解

定义：find是一个实时查找工具，通过遍历指定起始路径下文件系统层级结构完成文件查找。


> 实时查找：遍历所有文件进行条件匹配
> 非实时查找：根据索引查找


-------


## 工作特性
 
 1.查找速度略慢
 2.精确查找
 3.实时查找
 
 ![](https://ww4.sinaimg.cn/large/006tNbRwgy1fds8rirz6ej30yq0zk4ci.jpg)
 
 
 <!-- more -->
 
 
## 命令用法

`find [OPTIONS] [查找起始路径] [查找条件] [处理动作]`

* **查找起始路径：指定具体搜索目标起始路径，默认为当前目录**

* **查找条件：指定的查找标准，可以根据文件名、大小、类型、从属关系、权限等等标准进行；默认为找出指定路径下的所有文件**

* **处理动作：对符合查找条件的文件做出的操作，例如删除等操作；默认为输出至标准输出**



##### 查找条件：

表达式：选项（OPTIONS）和测试(TEST)

    测试：通常结果为布尔型
    
    
-------


* 根据文件名查找：

        -name "pattern"
        -iname "pattern"  #此选项不区分大小写（支持glob风格的通配符:*,?,[],[^]
        -regex pattern：基于正则表达式模式查找文件，匹配范围是整个路径


-------


* 根据文件的从属关系查找：
        
        -user USERNAME : 查找属主为指定用户(USERNAME)的所有文件
        -group GRPNAME : 查找属组为指定组(GRPNAME)的所有文件
        -uid UID : 查找属主为指定UID的所有文件
        -gid GID : 查找属组指定GID的所有文件
        -nouser : 查找没有属主的所有文件
        -nogroup : 查找没有属组的所有文件


-------


* 根据文件类型查找：


```bash
-type TYPE :
    f：普通文件
    d：目录文件
    l：符号链接文件
    b：块设备文件
    c：字符设备文件
    p：管道文件
    s：套接字文件     
```


*eg：*

```bash
[centos@station1 ~]$ find /dev -type b -ls
  1599    0 brw-rw----   1 root     disk       8,   7 Mar 19 03:01 /dev/sda7
  1598    0 brw-rw----   1 root     disk       8,   6 Mar 19 03:01 /dev/sda6
  1597    0 brw-rw----   1 root     disk       8,   5 Mar 19 03:01 /dev/sda5
  1596    0 brw-rw----   1 root     disk       8,   4 Mar 19 03:01 /dev/sda4
  1595    0 brw-rw----   1 root     disk       8,   3 Mar 19 03:01 /dev/sda3
  1594    0 brw-rw----   1 root     disk       8,   2 Mar 19 03:01 /dev/sda2
  1593    0 brw-rw----   1 root     disk       8,   1 Mar 19 03:01 /dev/sda1
  1592    0 brw-rw----   1 root     disk       8,   0 Mar 19 03:01 /dev/sda
  9811    0 brw-rw----   1 root     cdrom     11,   0 Mar 19 03:01 /dev/sr0

[centos@station1 ~]$ find /dev -type b
/dev/sda7
/dev/sda6
/dev/sda5
/dev/sda4
/dev/sda3
/dev/sda2
/dev/sda1
/dev/sda
/dev/sr0
```

-------


##### 组合测试

与、或、非

* 与：-a，默认组合逻辑

```bash
[centos@station1 tmp]$ find /home/ -user centos -type f -group centos -ls
134338680    4 -rw-r--r--   1 centos   centos         18 Aug  3  2016 /home/centos/.bash_logout
134338681    4 -rw-r--r--   1 centos   centos        198 Jan 23 17:15 /home/centos/.bash_profile
134338682    4 -rw-r--r--   1 centos   centos        231 Jan 23 17:17 /home/centos/.bashrc
134338663    4 -rw-------   1 centos   centos        735 Jan 25 09:14 /home/centos/.bash_history
134338665    0 -rw-rw-r--   1 centos   centos          0 Jan 15 09:33 /home/centos/test
```

* 或：-o，优先判断`-o`之后的参数

* 非：-not或！
    
        !A -a !B = !(A -o B)
        !A -o !B = !(A -a B)
   
   

-------

   
        
##### 根据文件大小查询


```
-size [+|-]#UNIT
    常用单位：k、M，G
    不带+ -号是表示精确查找：
        
        #UNIT：查找范围的文件
            (#-1,#]
            
        -#UNIT：查找小于指定的数值的文件
            [0,#-1]
        
        +#UNIT：查找大于指定的数据的文件    
            （#，∞）
```


-------


##### 根据时间戳查找：

* 以"天"为单位查找：
    
        -atime[+|-]#：根据访问文件的时间查找
        #：[#,#+1)
        -#：[0,#）
        +#：(#+1,∞)或(∞,#+1)
        
        -mtime：根据修改文件数据的时间查找
        
        -ctime：根据修改文件状态的时间查找

* 以"分钟"为单位查找：
        
            *用法与-atime相同*
            
        -amin:根据访问文件的时间查找
        -mmin:根据修改文件数据的时间查找
        -cmin:根据修改文件状态的时间查找

*eg:*


```bash
[centos@station1 ~]$ find ~root  -type d -atime -1 -ls
201326785    4 dr-xr-x---  16 root     root         4096 Mar 19 03:23 ./
134309211    0 drwx------   2 root     root           28 Mar 19  2017 ./.ssh
201374116    0 drwxr-xr-x   4 root     root           34 Mar 19 02:07 ./.cache
 48309    0 drwxr-xr-x   2 root     root           50 Mar 19 06:24 ./.cache/abrt
 48312    0 drwx------   2 root     root           30 Mar 19 03:01 ./.cache/imsettings
67352306    0 drwxr-xr-x   8 root     root          154 Mar 19 03:01 ./.config
···
···


[centos@station1 ~]$ find ~root  -type d -amin -1 -ls
201326785    4 dr-xr-x---  16 root     root         4096 Mar 19 03:23 ./
134309211    0 drwx------   2 root     root           28 Mar 19  2017 ./.ssh

[centos@station1 ~]$ find ~root  -amin -1 -ls
201326785    4 dr-xr-x---  16 root     root         4096 Mar 19 03:23 ./
134309211    0 drwx------   2 root     root           28 Mar 19  2017 ./.ssh
134309216    4 -rw-r--r--   1 root     root          397 Mar 19  2017 ./.ssh/authorized_keys
201356937    4 -rw-------   1 root     root         2639 Mar 19  2017 ./anaconda-ks.cfg

```

-------


##### 根据权限查找：


```bash
-perm [+|-]mode

    mode：精确权限匹配

    /mode：任何一类用户（u,g,o)权限中的任何一位(r,w,x)符合条件即满足。
    即：6中必有4+2，也就是r和w权限，只要有r或者w权限即为满足条件（9位权限之间存在”或“关系）

    -mode：每一类用户(u,g,o)的权限中的每一位(r,w,x)同时符合条件即满足（9位权限之间存在”与“关系）
```

*eg:*

```bash
[centos@station1 ~] find ~root -type f -perm -222  -ls         #表示每一位中的权限小于等于2就匹配
201351560    0 -rwxrwxrwx   1 root     root            0 Mar 19 06:38 ./1.txt

[centos@station1 ~]$ find root~ -type d -perm /611  -ls          #表示属主有读或者写权限，或者属组有执行权限，或者其他有执行权限，都可以被搜索到
201326785    4 dr-xr-x---  16 root     root         4096 Mar 19 06:41 ./
134309211    0 drwx------   2 root     root           28 Mar 19  2017 ./.ssh
201374116    0 drwxr-xr-x   4 root     root           34 Mar 19 02:07 ./.cache
 48309    0 drwxr-xr-x   2 root     root           50 Mar 19 06:24 ./.cache/abrt
 48312    0 drwx------   2 root     root           30 Mar 19 03:01 ./.cache/imsettings
67352306    0 drwxr-xr-x   8 root     root          154 Mar 19 03:01 ./.config
134347075    0 drwxr-xr-x   2 root     root            6 Mar 19 02:06 ./.config/abrt
201374121    0 drwxr-xr-x   2 root     root            6 Mar 19 02:07 ./.config/imsettings
201374137    0 drwxr-xr-x   2 root     root           28 Mar 19 02:07 ./.config/akonadi
  1275    4 drwx------   2 root     root         4096 Mar 19 02:07 ./.config/pulse

```


##### 处理动作


```
-print：输出至标准输出（默认值）
-ls：类似于对查找到的文件执行”ls -l“命令，输出文件的详细信息
-delete：删除查找到的文件
-fls /PATH/TO/SOMEFILE：把查找到的所有文件的详细信息保存至指定文件中
-ok COMMAND {} \; ：对查找到的每个文件执行由COMMAND表示的命令（每次操作都会由用户进行确认）

[centos@station1 test]$ find -perm /002 -exec mv {} {}.danger \;  	#这里的{}是引用find命令匹配到的所有文件
[centos@stations test]$ ll
total 0
-rw-r-----. 1 root root 0 Feb  9 09:06 a
-rw-rw-rw-. 1 root root 0 Feb  9 09:06 b.danger
-rw-r-----. 1 root root 0 Feb  9 09:06 c
-rwxrwxr-x. 1 root root 0 Feb  9 09:06 d
-rwxrwxrwx. 1 root root 0 Feb  9 09:06 e.danger
-rw-r--r--. 1 root root 0 Feb  9 09:06 f
-rw-r--r--. 1 root root 0 Feb  9 09:06 g
```


*==注意：==find传递查找到的文件路径至后面的命令时，是先查找出所有符合条件的文件路径，并一次性传递给后面的命令*

*但是有些命令不能接收过长的参数，命令执行会失败；另一种方式可规避此问题*

==find | xargs COMMAND    对于需要执行的命令则使用管道符将find查找到的文件路径传给xargs来执行要操作的命令==


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=28859948&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。


![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



<!--author：maxie（马驰原）-->
<!--QQ：17045930-->





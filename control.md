---
title: Linux命令执行控制
date: 2017-03-23 16:19:33
tags: [linux]
categories: linux基础知识
---

# && 与 ||


#### 一、&&

    方式：`COMMAND1 && COMMAND2`

>   如果`COMMAND1`执行成功，则执行`COMMAND2`
>   如果`COMMAND1`执行失败，则不会执行`COMMAND2`




* 实例：
    

```bash
[centos@node test]$ mv tmp.log 1.log && ls -l
total 0
-rw-r--r--. 1 root root 0 Mar 24 14:54 1.log
[centos@node test]$ mvdd 1.log tmp.log && ls -l
bash: mvdd: command not found...
```

![](https://ww3.sinaimg.cn/large/006tNbRwgy1fdwvul0t1rj30zk0zkq78.jpg)


<!-- more -->

-------

#### 二、||

    方式：`COMMAND1 || COMMAND2`

>   如果`COMMAND1`执行成功，则不会执行`COMMAND2`
>   如果`COMMAND1`执行失败，则执行`COMMAND2`

* 实例：


```bash

[centos@node test]$ cat 1.log || cd ~
hello world
maxie					
[centos@node  ~]$ cat11 1.log || cd ~
-bash: cat11: command not found
[centos@node  ~]$ pwd
/home/centos

```


<br></br>




<br></br>

-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=29588431&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



<br></br>
<br></br>

<!--author：maxie（马驰原）-->
<!--QQ：17045930-->


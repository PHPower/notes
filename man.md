---
title: 学会使用命令帮助
date: 2017-03-25 19:52:22
tags: [linux,man]
categories: linux基础知识
---

**Linux中如何获取帮助信息**

> 在刚接触Linux操作系统的时候，遇到不懂的命令时，我就会到[Goolge](https://www.google.com.hk)、[Runoob](http://www.runoob.com/linux/linux-command-manual.html)、[Linuxde](http://man.linuxde.net/)上去查阅相关资料，这样虽然能获得到关于命令的详细解释；但是对于刚接触Linux的是非常不好的，时间长了就会产生依赖性，从而导致之后在学习linux中自带的帮助命令（man、info、help等）有了抵触感。
> 
> 而且一旦依赖于这些网站，在没有网络的情况下，就是“两手一抹黑”，不知道怎么办。
> 
> 所以说学好Linux自带的帮助命令，是熟练掌握Linux的前提。

<!-- more -->


-------

## 命令执行方式

>一般正常的Linux发行版本内的命令都是带有帮助文件的。当用户执行了一个命令之后，系统的kernel会在当前用户的`PATH`环境变量中读取存放在`PATH`中的路径，根据给定的路径，去匹配要执行的命令文件，直到找到并执行命令为止。

**which命令**：用于查找并显示给定命令的绝对路径。使用which命令，就可以看到某个系统命令是否存在，以及执行的到底是哪一个为止的命令


```bash
$ which 命令名
```


**whatis命令**：用于查询一个命令执行什么功能，并将查询结果输出到屏幕上。

```bash
$ whatis 命令名
```

不过在执行`whatis`命令之前，需要生成man数据库。
> CentOS 7：
> `$ mandb`
> 
> CentOS 6：
> `$ makewhatis` 


-------

## 命令帮助获取的方式
    
在Linux中，有系统內建命令，还有外部命令。

**type命令**可以查看命令的类型

```bash
$ type echo
echo is a shell builtin
```

说明`echo`这个命令是內建命令，使用**help**查看命令的帮助

```bash
$ help echo
```

**外部命令获取帮助的方法**

* 第一种是`--help`的方式

```bash
$ ls --help
```

* 第二种是使用`man`命令

```bash
$ man ls
```

-------

## man手册页详解


man手册有9个章节，其中2，3，9适用于编程开发，1，4，5适用于系统运维。


| 章节编号 | 章节主要内容 |
| :-:| :-: |
| 1 | 用户命令和守护进程 |
| 2 | 系统调用和内核服务 |
| 3 | C库调用 |
| 4 | 设备文件及特殊文件 |
| 5 | 文件格式与规则 |
| 6 | 游戏及其他 |
| 7 | 杂项 |
| 8 | 管理类命令 |
| 9 | linux内核API |


-------

## man的段落说明

以下列出几个常用的章节


```
NAME            --命令名称及功能简要说明
SYNOPSIS        --用法说明，包括可用选项
DESCRIPTION     --关于命令的详细说明
OPTIONS         --说明每一个选项的意义
EXAMPLES        --使用示例
FILES           --此命令相关的文件
BUGS            --提交BUG
AUTHORS         --作者
SEE ALSO        --另外的参照
```

## man命令的使用参数

```bash
[章节号]         --查看指定章节关于命令的帮助手册
-a              --列出关于命令的所有帮助
-k KEYWORD      --列出所有关于KEYWORD的页面
-f KEYWORD      --相当于whatis命令
-w              --打印man帮助文件的路径
-M PATH         --指定手册的搜寻路径
```

-------

## man命令的操作方法

> `space键`：向文件尾部翻一屏
> `b键`：向文件首部翻一屏
> `d键`：向文件尾部翻半屏
> `u键`：向文件首部翻半屏
> `enter键`：向文件尾部翻一行
> `k键`：向文件首部翻一行
> `q键`：退出man手册
> `#`：跳转至第#行
> `1G`：回到文件首部
> `G键`：翻至文件尾部



## info命令

**info命令**：就内容来说，info页面比man page编写的要更好，更容易理解，也更有好，但man page使用起来确实更容易的多。

**使用info命令**

```bash
$ info COMMAND
```

**选项**

```bash
-d：添加包含info格式帮助文档的目录
-f：指定要读取info格式的帮助文档
-n：指定首先访问的info帮助文件的节点
-o：输出被选择的节点内容到指定文件
```



-------

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=346 height=86 src="//music.163.com/outchain/player?type=2&id=29732659&auto=0&height=66"></iframe>

<!--author：maxie（马驰原）-->
<!--QQ：17045930-->



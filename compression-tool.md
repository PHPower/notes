---
title: 压缩和解压缩
date: 2017-04-08 15:45:32
tags: [linux,compress]
categories: linux基础知识
---

<blockquote class="blockquote-center">压缩的目的
时间换空间
CPU的时间 --> 磁盘空间
</blockquote>

**常见的压缩文件拓展名：**

```bash
*.Z         --compress  压缩文件
*.gz        --gzip      压缩文件
*.bz2       --bzip2     压缩文件
*.xz        --xz        压缩文件
*.tar       --tar       打包文件,并没有经过压缩
*.tar.gz    --tar       打包文件,其中并且经过 gzip 的压缩
*.tar.bz2   --tar       打包文件,其中并且经过 bzip2 的压缩
*.tar.xz    --tar       打包文件,其中并且经过 xz 的压缩
```

Linux上常见的压缩命令就是`gzip`和`bzip2`，还有新兴的`xz`，至于`compress`已经"退环境"了，不再适合当前的版本了。

<!-- more -->

# 压缩与解压缩工具

{% note primary %}## compress/uncompress工具
{% endnote %}

compress这个压缩工具是非常老旧的一款，我们现在使用的 CentOS6.8 与 CentOS7 默认都没有安装这个软件到系统当中。如果想在系统中使用，需要先安装 `ncompress` 这个软件才可以。

```bash
$ yum install -y ncompress
```
![](https://ww3.sinaimg.cn/large/006tNbRwly1fefcgrj5n0j310y1f4gvr.jpg)

安装完成之后，我们就可以开始使用 `compress` 软件来对文件进行压缩/解压缩的操作了！


```
$ compress [-cdv] FILE

各选项意义：
-c          --压缩结果输出至标准输出,不删除原文件
-d          --解压缩,相当于uncompress
-v          --显示压缩过程
```

![](https://ww2.sinaimg.cn/large/006tNbRwly1fefcs2iv3mj310y0rw44l.jpg)

**注意：**从上图我们可以看出，`compress` 在压缩文件时，会自动删除原文件。我们使用`-c`选项，并把标准输出中的内容重定向至一个压缩文件中，这样我们即压缩了文件，又保留了原文件，岂不美哉~

还有一个小tips，就是使用 `zcat` 命令可以查看 `compress` 压缩的文件内的文本内容


```bash
$ zcat file.Z
```

-------

{% note success %}## gzip/gunzip工具
{% endnote %}

`gzip` 可以说是Linux中应用最广泛，使用最多的压缩命令了。使用 `gzip` 创建的压缩文件的后缀是 `*.gz`


```bash
$ gzip [-cdv#] FILE

各选项意义：
-c          --将压缩的数据输出至标准输出,可以通过重定向来处理
-d          --解压缩,相当于gunzip
-v          --显示压缩过程信息
-#          --压缩比，默认为6，越大越好，但也越慢，越耗CPU
```

![](https://ww1.sinaimg.cn/large/006tNbRwly1fefd4ytimej310y0rwaha.jpg)

与 `compress` 类似，使用 `gzip` 压缩文件后，会自动把原文件删除，所以日常使用时我们要在 `gzip` 后面加上 `-c` 选项，再重定向至压缩文件中，这样我们即压缩了文件，也保留了原文件。

而且我们可以对比 `compress` 看出， `gzip` 的压缩比明显更好，压缩后的文件占用空间更少；我们还可以使用 `zcat` 查看压缩后的文件中的内容。

-------


{% note info %}## bzip2/bunzip2工具
{% endnote %}

如果说 `gzip` 是为了替代 `compress` 出现的，那么 `bzip2` 就是为了替代 `gzip` 出现的。 `bzip2` 的压缩比比 `gzip` 还要好，但是目前来说使用最广泛的还是 `gzip`。

让我们看看如何使用 `bzip2` 吧！

```bash
$ bzip2 [-cdkv#] FILE

各参数意义：
-c          --将压缩的数据输出至标准输出,可以通过重定向来处理
-d          --解压缩,相当于bunzip2
-v          --显示压缩过程信息
-#          --压缩比，默认为6，越大越好，但也越慢，越耗CPU
```

![](https://ww3.sinaimg.cn/large/006tNbRwly1fefdgfkhb0j310y0rwwlu.jpg)

使用方法与 `gzip` 其实并没有什么区别，只是要查看使用 `bzip2` 压缩的文件内的文本内容，就需要使用 `bzcat` 这个命令来查看了。

-------

{% note danger %}## xz/unxz工具
{% endnote %}

`xz` 是一个使用 [LZMA/LZMA2](https://zh.wikipedia.org/wiki/LZMA) 压缩算法的无损数据压缩文件格式。和 `gzip` 与 `bzip2` 一样，同时支持多文件压缩，但是不能将多于一个目标文件压缩进同一个档案(包)里。`xz` 生成的压缩文件比 `gzip/bzip2` 生成的压缩文件更小，而且压缩速度也很快。其生成的压缩文件扩展名为 `*.xz`


```bash
$ xz [-kdv#]         

各选项意义：
-k          --保留原文件，无需使用重定向
-d          --解压缩，与unxz效果相同
-v          --显示压缩时的信息
-#          --压缩比，默认为6
```
![](https://ww4.sinaimg.cn/large/006tNbRwly1fefjjezcgmj310y0rwjx5.jpg)

由于压缩的文件比较小，所以对比 `gzip/bzip2` 的优势不是那么明显，但是也还是可以看出 `xz` 以略微的优势占领了上风。

使用 `xzcat`同样可以看到压缩后文件内的文本内容。


-------

# 打包(归档)命令

上面我们说完了压缩/解压缩命令，但是前面的命令只能压缩单一文件，而不能对目录进行压缩的操作。
下面我们讲一讲，如何使用打包命令将目录包成一个大文件。


{% note warning %}## tar工具
{% endnote %}

`tar` 可以将多个目录或文件打包成一个大文件，同时它还可以搭配 `gzip/bzip2/xz` 将此大文件进行压缩。

`tar` 的参数非常多，下面只列取一些常用的选项

```bash
$ tar [-j|-J|-z] [cv] [-f 创建的归档的文件名] FILE         --打包与压缩
$ tar [-j|-J|-z] [xv] [-f 创建的归档的文件名] [-C 目录]    --此选项是将归档文件解压到指定目录
$ tar [-j|-J|-z] [tv] [-f 创建的归档的文件名]              --查看归档文件内的文件列表

各选项意义：
-c          --创建归档文件
-f          --指定归档的文件名(f必须与归档文件名在一起，例如：cf，xf；而非：fc)
-x          --展开归档，通常与-v，-C结合使用
-t          --查看归档文件内的文件列表
-v          --在归档/解包的过程中将正在处理的档名显示出来
-j          --通过 bzip2 将文件归档并压缩；后缀名最好为 *.tar.bz2
-J          --通过 xz 将文件归档并压缩；后缀名最好为 *.tar.xz
-z          --通过 gzip 将文件归档并压缩；后缀名最好为 *.tar.gz
-C          --解压缩时，指定解压缩的位置
-P          --保留绝对路径
-p          --保留文件的原本权限和属性，常用于备份重要的文档
--exclude=FILE      --压缩的过程中，不要将 FILE 这个文件打包
```

其实，在生产环境与日常操作练习时，我们只需使用以下的几种方式即可：

```bash
压  缩: tar -zcv -f filename.tar.gz
查  询: tar -ztv -f filename.tar.gz
解压缩: tar -zxv -f filename.tar.gz
```
由于现在流行使用的压缩工具大多是 `gz` 格式的，我们这里就列举了 `gz` 的三种操作方法。至于其他两种，替换 `-z` 即可。

![](https://ww2.sinaimg.cn/large/006tNbRwly1fefkii0eikj310y0rwgsb.jpg)

上图中，我们可以看到有三个归档文件，是三种不同类型的，我执行了以下的命令：

```bash
$ tar -zcvf etc.tar.gz /etc
$ tar -Jcvf etc.tar.xz /etc
$ tar -jcf etc.tar.bz2 /etc
```

通过对比，明显看出 `xz` 的优势蛮大的，`bzip2` 与 `gzip` 倒是不分伯仲。

当我们把/etc目录归档好了之后，就可以使用 `-t` 选项查看我们备份了哪些目录和文件了。

![](https://ww3.sinaimg.cn/large/006tNbRwly1fefknl2lvej310y0rwqdp.jpg)

不过由于文件内容过多，我们只取前10行的内容。

现在我们想把其中的 `etc/fstab` 文件取出来，就可以使用 `tar -zxcf etc.tar.gz etc/fstab` 命令取出文件了！

![](https://ww3.sinaimg.cn/large/006tNbRwly1fefkrjz1iij310608m76k.jpg)

这样，我们就把归档文件内的 `etc/fstab` 文件单个取出来来啦！

下面我们将把 `etc.tar.gz` 文件解压到 `/tmp` 目录下，这时就需要使用 `-C` 选项了。

![](https://ww2.sinaimg.cn/large/006tNbRwly1fefl0x01z2j310y0rwgtd.jpg)

注意 `-C` 选项的位置，在归档文件名之后，目标位置之前。

-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=28458114&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


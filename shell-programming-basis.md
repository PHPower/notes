---
title: bash脚本编程基础（一）
date: 2017-04-12 19:12:50
tags: [linux,shell,bash,programming]
categories: linux基础知识
---

<blockquote class="blockquote-center">Bash(Bourne Again Shell)，是一款在大多数Linux系统中默认的shell。
值得注意的是shell与shell script是两个不同的概念。
</blockquote>

**常见的shell**

> Bourne Shell (/usr/bin/sh或/bin/sh)
> Bourne Again Shell (/bin/bash)
> C Shell (/usr/bin/csh)
> K Shell (/usr/bin/ksh)
> Z Shell (/usr/bin/zsh)
> Shell for Root (/sbin/sh)

要想成为一个使用Linux的dalao，就离不开shell，那么也就是说离不开shell编程。很多时候服务器都需要编写一些计划任务来定时运行的，所以掌握一些基本的shell编程基础很有必要。

<!-- more -->

-------

{% note primary %}## 什么是Shell脚本
{% endnote %}

先看个例子吧！

```bash
#!/bin/bash
cd /root
mkdir script
cd script
for ((i=0; i<10; i++)); do
    touch test_$i.txt
done
```

例子解释：

*  第一行：指定脚本的解释器，这里使用的是/bin/bash
*  第二行：切换到`root`用户的家目录
*  第三行：创建一个目录`script`
*  第四行：切换到`script`目录下
*  第五行：for循环以及循环的条件
*  第六行：创建一个test_1..10.txt的文件
*  第七行：循环结束


```bash
cd mkdir touch 都是系统內建的程序。
for do done 是bash脚本语言的关键字。
```

-------

{% note success %}## shell和shell脚本的概念
{% endnote %}

shell是指一种应用程序，这个应用程序提供了一个界面，用户通过这个界面访问操作系统内核的服务。

Ken Thompson的sh是第一种Unix Shell，Windows Explorer是一个典型的图形界面Shell。shell脚本（shell script），是一种为shell编写的脚本程序。

业界所说的shell通常都是指shell脚本，但读者朋友要知道，shell和shell script是两个不同的概念。

由于习惯的原因，简洁起见，本文出现的“shell编程”都是指shell脚本编程，不是指开发shell自身（如Windows Explorer扩展开发）。

环境shell编程跟java、php编程一样，只要有一个能编写代码的文本编辑器和一个能解释执行的脚本解释器就可以了。

OS当前主流的操作系统都支持shell编程，本文档所述的shell编程是指Linux下的shell，讲的基本都是POSIX标准下的功能，所以，也适用于Unix及BSD（如Mac OS）。

LinuxLinux默认安装就带了shell解释器。

Mac OSMac OS不仅带了sh、bash这两个最基础的解释器，还内置了ksh、csh、zsh等不常用的解释器。

Windows上的模拟器windows出厂时没有内置shell解释器，需要自行安装，为了同时能用grep, awk, curl等工具，最好装一个cygwin或者mingw来模拟linux环境。

cygwin
mingw

-------

{% note info %}## 脚本解释器 sh
{% endnote %}

即Bourne shell，POSIX（Portable Operating System Interface）标准的shell解释器，它的二进制文件路径通常是/bin/sh，由Bell Labs开发。

bashBash是Bourne shell的替代品，属GNU Project，二进制文件路径通常是/bin/bash。业界通常混用bash、sh、和shell，比如你会经常在招聘运维工程师的文案中见到：熟悉Linux Bash编程，精通Shell编程。

在CentOS里，/bin/sh是一个指向/bin/bash的符号链接:
![](http://ww3.sinaimg.cn/large/006tNc79ly1fek5u6o8ltj30zw0bqgq5.jpg)

但在Mac OS上不是，/bin/sh和/bin/bash是两个不同的文件，尽管它们的大小只相差100字节左右:
![](http://ww1.sinaimg.cn/large/006tNc79ly1fek5vty07dj310006swhd.jpg)

-------

{% note danger %}## 运行bash脚本
{% endnote %}

运行shell脚本有两种方法：

**1、作为可执行程序**

将下面的代码输入到test.sh文件中，并给予权限。


```bash
#!/bin/bash
cd /root
mkdir script
cd script
for ((i=0; i<10; i++)); do
    touch test_$i.txt
done
```

给予文件执行权限

```bash
$ chmod +x test.sh
```

执行脚本

```bash
$ ./test.sh
```

*注意：*

* 一定要写成`./test.sh`，而不是`test.sh`，运行其他二进制程序也一样。
* 直接写成`test.sh`，系统会去`$PATH`环境变量中的路径中查找有没有叫`test.sh`文件。
* 你的当前目录一般不在`$PATH`设置的路径中，所以写成`test.sh`是不会找到命令的，要用`./test.sh`告诉系统，就在当前目录查找。


**2、作为解释器参数**

这种运行方式是，直接运行解释器，其参数就是shell脚本的文件名，如：

```bash
$ bash test.sh
$ sh test.sh
$ /bin/bash test.sh
$ /bin/sh test.sh
```

这种方式运行的脚本，不用在第一行指定注释信息，也就是`shebang`

-------

{% note warning %}## 变量
{% endnote %}

定义变量：

```bash
$ name=value
或者
$ name="value"
```

注意：变量名和等号之间不能有空格。

**变量命名法则：**

1. 首个字母必须为字母或下划线
2. 中间不能有空格，可以使用下划线
3. 不能程序中的保留字：例如if、for
4. 见名知义
5. 统一命名规则：驼峰原则

**变量种类**

1. 本地变量：生效范围为当前shell进程；对当前shell之外的其他shell，包括当前shell的子进程均无效
2. 环境变量：生效范围为当前shell及其它shell进程，使用`export`定义变量
3. 局部变量：生效范围为当前shell进程中某代码片段，通常在函数里面，使用local定义变量
4. 位置变量：$1,$2,$3，用于让脚本在脚本在代码中调用通过命令行传递给它的参数。
5. 特殊变量：$?,$0,$*,$@,$#

除了使用上面那样的方式给变量赋值，还可以用语句给变量赋值，如：

```bash
for I in `ls /etc`
```
* 说明：上面的意思就是把`ls /etc`的命令输出结果赋值给变量`I`，并循环显示出来。

**使用变量**

使用一个定义过的变量，只要在变量名之前加上`$`符号即可。比如：

```bash
$ name="value"
$ echo $value
或者
$ echo ${value}
```
变量名外的花括号是可选的，可加可不加，加花括号是为了帮助解释器识别变量的边界，比如下面这种情况：

```bash
for skill in Java Python C Go; do
    echo "I am good at ${skill}program."
done
```

推荐给所有变量加上花括号，这是shell编程的好习惯。

对于已定义的变量，可以被重新定义，比如：

```bash
$ name="value"
$ echo ${name}
$ name="maxie"
$ echo ${maxie}
```

**只读变量**

使用`readonly`命令可以将变量定义为只读变量，只读变量的值不能被改变。

下面的例子就说明了这一切：

```bash
$ name="maxie"
$ readonly name
$ name="value"
-bash: name: 只读变量
```

**删除变量**

使用`unset`命令可以删除变量。

```bash
$ unset name
```
变量被删除后不能再次被使用，unset命令不能删除只读变量

```bash
$ name="value"
$ unset name
$ echo $name
```

-------

{% note default %}## 字符串
{% endnote %}

字符串是 shell 编程中最常用最有用的数据类型（除了数字和字符串，也没啥其它类型好用了）。

字符串可以用单引号，也可以用双引号，也可以不用引号。

**单引号**


```bash
$ str='this is a string'
```
单引号的特性：

* 单引号里的任何字符都会原样输出，单引号中的变量不会被替换
* 单引号里不能出现单引号（嵌套）

**双引号**

```bash
$ name="maxie"
$ HELLO="Hello, I know u r ${name}! \n "
```
双引号的特性：

* 双引号里可以有变量，并且会被替换
* 双引号可以使转义字符生效

**获取字符串长度**

```bash
$ alpha="abcde"
$ echo ${#alpha}
5
```

**提取字符串**

从以下实例的字符串第4个字符开始截取4个字符：

```bash
BJ="BeiJing is a nice city"
$ echo ${BJ:3:4}
Jing
```


-------


{% note primary %}## 数组
{% endnote %}

Bash Shell 只支持一维数组（不支持多维数组），初始化时不需要定义数组大小

获取数组中的元素要利用下标，下标可以是整数或算术表达式，其值应大于或等于0。

数组中可以存放多个值，与大部分编程语言类似，数组元素的下标由0开始。

**定义数组**

在shell中，用括号来表示数组，数组元素用“空格”符号分隔开。

定义数组的一般形式为：

```bash
数组名=(值1 值2 值3 ... 值n)
```

例如：

```bash
array=(value1 value2 value3)
```

或者

```bash
array=(
value1
value2
value3
)
```

还可以单独定义数组的各个分量：

```bash
array[1]=value1
array[2]=value2
array[3]=value3
```

可以不使用连续的下标，而且下标的范围没有限制。

**读取数组**

读取数组元素值的一般格式是：

```bash
${数组名[下标]}
```

例如：

```bash
values=${array[n]}
```

实例：

```bash
#!/bin/bash
my_array=(A B "C" D)

echo "第一个元素为: ${my_array[0]}"
echo "第二个元素为: ${my_array[1]}"
echo "第三个元素为: ${my_array[2]}"
echo "第四个元素为: ${my_array[3]}"
```

执行脚本，输出结果如下所示：

```bash
$ chmod +x test.sh 
$ ./test.sh
第一个元素为: A
第二个元素为: B
第三个元素为: C
第四个元素为: D
```

使用 @ 或者 * 符号可以获取数组中的所有元素，例如：

```bash
echo ${array[@]}
```

实例：

```bash
#!/bin/bash

my_array[0]=A
my_array[1]=B
my_array[2]=C
my_array[3]=D

echo "数组的元素为: ${my_array[*]}"
echo "数组的元素为: ${my_array[@]}"
```

执行脚本，输出结果如下所示：

```bash
$ chmod +x test.sh 
$ ./test.sh
数组的元素为: A B C D
数组的元素为: A B C D
```

**获取数组的长度**

获取数组长度的方法与获取字符串长度的方法相同，例如：


```bash
# 取得数组元素的个数
length=${#array[@]}
# 或者
length=${#array[*]}
# 取得数组单个元素的长度
lengthn=${#array[n]}
```

实例：

```bash
#!/bin/bash

my_array[0]=A
my_array[1]=B
my_array[2]=C
my_array[3]=D

echo "数组元素个数为: ${#my_array[*]}"
echo "数组元素个数为: ${#my_array[@]}"
```

执行脚本，输出结果如下所示：

```bash
$ chmod +x test.sh 
$ ./test.sh
数组元素个数为: 4
数组元素个数为: 4
```


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=28695603&auto=1&height=66"></iframe>


![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。



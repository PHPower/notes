---
title: bash脚本编程基础（二）
date: 2017-04-14 19:01:13
tags: [linux,shell,bash,programming]
categories: linux基础知识
---

<blockquote class="blockquote-center">在编写脚本的同时，我们不仅要让功能实现，也要让使用者能看懂我们写的脚本。所以要在必要的地方加上注释。
</blockquote>

**注释**

在`bash`中除了第一行的`"shebang"`，其余的行如果有`#`号开头的行，解释器都会忽略这些行，因为这些行都被视为是代码的注释信息。

`bash`中没有多行注释，只能每行加一个`#`号。

像这样：

![](http://ww4.sinaimg.cn/large/006tNc79ly1femfa3r7eqj310y0rwn02.jpg)

如果在开发过程中，遇到大段的代码需要临时注释起来，过一会儿又取消注释，怎么办呢？

每一行加一个`#`号太费劲了，可以把这一段要注释的代码用一对花括号括起来，定义成一个函数，不调用这个函数，这样我们就实现了 "多行注释" 的效果。

<!-- more -->

{% note primary %}## 如何传递参数
{% endnote %}

我们可以在执行`shell`脚本时，向脚本传递参数，脚本内获取参数的格式为：`$n`

> n 代表一个数字，1 为执行脚本的第一个参数， 2 为执行脚本的第二个参数，以此类推...

**实例：**

以下实例，我们将向脚本传递 2 个参数，并分别输出，注意 `$0` 是脚本本身：

```bash
#!/bin/bash

echo "现在我们开始传递参数！"
echo "脚本名为:${0}"
echo "第一个参数为:${1}"
echo "第一个参数为:${2}"
```

执行脚本前，需要给脚本授予执行权限。

![](http://ww1.sinaimg.cn/large/006tNc79ly1femfjftwkbj310y0rwtck.jpg)

另外，还有几个特殊字符用来处理参数：

```bash
$#          --传递到脚本的参数的个数
$*          --以一个单字符串显示所有向脚本传递的参数
$$          --脚本运行的当前进程号
$!          --后台运行的最后一个进程号
$@          --与$*相同，但是使用时加引号，并在引号中返回每个参数
$-          --显示shell使用的当前选项，与set命令功能相同
$?          --显示最后命令的退出状态。0 表示没有错误，1-255 表示有错。
```

执行脚本，输出结果如下所示：

![](http://ww3.sinaimg.cn/large/006tNc79ly1femft847auj310007cq4d.jpg)

\* 与 @ 的区别：

* 相同点：都是引用所有参数。
* 不同点：只有在双引号中体现出。

> 假设在脚本运行时写了三个参数 1、2、3，则 * 表示“1 2 3”（相当于传递了一个参数），而 @ 表示 "1" "2" "3"(传递了三个参数）


```bash
#!/bin/bash

echo "传递参数实例:"
echo "第一个参数为:${1}"
echo "第二个参数为:${2}"

echo " \$* 演示"
    
    for I in "$*"; do
        echo "${I}"
    done

echo " \$@ 演示"
    
    for I in "$@"; do
        echo "${I}"
    done
```

执行脚本，输出结果如下所示：

![](http://ww2.sinaimg.cn/large/006tNc79ly1femg1h8kcvj310209ijs8.jpg)


-------

{% note success %}## 基本运算符{% endnote %}

Shell 和其他编程语言一样，支持多种运算符，包括：

* 算数运算符
* 关系运算符
* 布尔运算符
* 字符串运算符
* 文件测试运算符

原生bash不支持简单的数学运算，但是可以通过其他命令来实现，例如 awk 和 expr，expr 最常用。

expr 是一款表达式计算工具，使用它能完成表达式的求值操作。

例如，两个数相加(特别注意：使用的是反引号 ` 而不是单引号 ')：


```bash
#!/bin/bash

var=`expr 2 + 2`
echo "两数之和为: ${var}"
```
执行脚本，输出结果如下：

```bash
两数之和为: 4
```

这里要注意两点：

1. 表达式和运算符之间要有空格，例如 2+2 是不对的，必须写成 2 + 2，这与我们熟悉的大多编程语言不一样。
2. 完整的表达式要被 反引号 包含，注意这个字符不是常用的单引号，在`ESC`键的下面。

### 算数运算符

下面列出了常用的算数运算符，假定变量 a 为 10，变量 b 为 20：

```bash
+ 加法运算  `expr $a + $b` 结果为 30
- 减法运算  `expr $a - $b` 结果为 -10
* 乘法运算  `expr $a * $b` 结果为 200
/ 除法运算  `expr $b / $a` 结果为 2
% 取余运算  `expr $b % %b` 结果为 0
= 赋值     a=${b} 将变量 b 的值赋值给 a
== 相等   用于比较两个数字，相等则返回 true  [ $a == $b ] 返回 false
!= 不相等 用于比较两个数字,不相等则返回 true  [ $a != $b]  返回 false
```

*注意*：条件表达式要放在方括号之间，并且要有空格，例如: `[$a==$b]`是错误的，必须写成`[ $a == $b ]`

实例：

```bash
#!/bin/bash

a=10
b=20

var=`expr $a + $b`
echo "a + b = $var"
echo ""

var=`expr $a - $b`
echo "a - b = $var"
echo ""


var=`expr $a * $b`
echo "a * b = $var"
echo ""

var=`expr $b / $a`
echo "b / a = $var"
echo ""


var=`expr $b % $a`
echo "a + b = $var"
echo ""

if  [ $a == $b  ]; then
        echo "a 等于 b"
fi

if [ $a != $b  ]; then
        echo "a 不等于 b"
fi
```

执行脚本，输出结果如下：

![](http://ww2.sinaimg.cn/large/006tNc79ly1femgy7fjj4j31000codgj.jpg)

*注意*：

* 乘号前面必须加反斜杠才能实现乘法运算
* if..then..fi是条件判断语句

### 关系运算符

关系运算符只支持数字，不支持字符串，除非字符串的值是数字。

下面列出了常用的关系运算符，我们假定变量 a 为 10，变量 b 为 20.

```bash
-eq     检测两个数是否相等，相等返回 true                    [ $a -eq $b ] 返回 false
-ne     检测两个数是否不相等，不相等返回 true                  [ $a -ne $b ] 返回 true
-gt     检测左侧数字是否大于右侧数字，如果是，则返回 true        [ $a -gt $b ] 返回 false
-ge     检测左侧数字是否大于等于右侧数字，如果是，则返回 true    [ $a -ge $b ] 返回 false
-lt     检测左侧数字是否小于右侧数字，如果是，则返回 true       [ $a -lt $b ] 返回 true
-le     检测左侧数字是否小于等于右侧数字，如果，则返回 true     [ $a -le $b ] 返回 true 
```

**实例**

```bash
#!/bin/bash

a=10
b=20

if [ $a -eq $b ]
then
   echo "$a -eq $b : a 等于 b"
else
   echo "$a -eq $b: a 不等于 b"
fi
if [ $a -ne $b ]
then
   echo "$a -ne $b: a 不等于 b"
else
   echo "$a -ne $b : a 等于 b"
fi
if [ $a -gt $b ]
then
   echo "$a -gt $b: a 大于 b"
else
   echo "$a -gt $b: a 不大于 b"
fi
if [ $a -lt $b ]
then
   echo "$a -lt $b: a 小于 b"
else
   echo "$a -lt $b: a 不小于 b"
fi
if [ $a -ge $b ]
then
   echo "$a -ge $b: a 大于或等于 b"
else
   echo "$a -ge $b: a 小于 b"
fi
if [ $a -le $b ]
then
   echo "$a -le $b: a 小于或等于 b"
else
   echo "$a -le $b: a 大于 b"
fi
```
执行脚本，输出结果如下：

![](http://ww4.sinaimg.cn/large/006tNc79ly1femhi2naluj310207imy9.jpg)

### 布尔运算符

下面列出了常用的布尔运算符，我们假定变量 a 为 10，变量 b 为 20


```bash
!       非运算，表达式为 true 则返回 false ，否则返回 true
-o      或运算，有一个表达式为 true 则返回 true
-a      与运算，两个表达式都为 true 则返回 true
```

**实例**


```bash
a=10
b=20

if [ $a != $b ]
then
   echo "$a != $b : a 不等于 b"
else
   echo "$a != $b: a 等于 b"
fi
if [ $a -lt 100 -a $b -gt 15 ]
then
   echo "$a -lt 100 -a $b -gt 15 : 返回 true"
else
   echo "$a -lt 100 -a $b -gt 15 : 返回 false"
fi
if [ $a -lt 100 -o $b -gt 100 ]
then
   echo "$a -lt 100 -o $b -gt 100 : 返回 true"
else
   echo "$a -lt 100 -o $b -gt 100 : 返回 false"
fi
if [ $a -lt 5 -o $b -gt 100 ]
then
   echo "$a -lt 100 -o $b -gt 100 : 返回 true"
else
   echo "$a -lt 100 -o $b -gt 100 : 返回 false"
fi
```
执行脚本，输出结果如下：

![](http://ww3.sinaimg.cn/large/006tNc79ly1femhv314ojj310005ggmo.jpg)

### 逻辑运算符

以下介绍shell的逻辑运算符，假定变量 a 为 10，变量 b 为 20：

```bash
&&      逻辑 AND
||      逻辑 OR
```

**实例**

```bash
#!/bin/bash

a=10
b=20

if [[ $a -lt 100 && $b -gt 100 ]]
then
   echo "返回 true"
else
   echo "返回 false"
fi

if [[ $a -lt 100 || $b -gt 100 ]]
then
   echo "返回 true"
else
   echo "返回 false"
fi
```

执行脚本，输出结果如下：

![](http://ww4.sinaimg.cn/large/006tNc79ly1femhywfblaj310003a3ys.jpg)

### 字符串运算符

下面列出了常用的字符串运算符，假定变量 a 为 “abc”， 变量 b 为 “efg”：

```bash
=       检测两个字符串是否相等，相等返回 true
!=      检测两个字符串是否不相等，不相等返回 true
-z      检测字符串长度是否为 0 ，如果为 0 则返回 true
-n      检测字符串长度是否不为 0 ，如果不为0 则返回 true
str     检测字符串是否为不为空，不为空则返回 true
```

**实例**

```bash
#!/bin/bash

a="abc"
b="efg"

if [ $a = $b ]
then
   echo "$a = $b : a 等于 b"
else
   echo "$a = $b: a 不等于 b"
fi
if [ $a != $b ]
then
   echo "$a != $b : a 不等于 b"
else
   echo "$a != $b: a 等于 b"
fi
if [ -z $a ]
then
   echo "-z $a : 字符串长度为 0"
else
   echo "-z $a : 字符串长度不为 0"
fi
if [ -n $a ]
then
   echo "-n $a : 字符串长度不为 0"
else
   echo "-n $a : 字符串长度为 0"
fi
if [ $a ]
then
   echo "$a : 字符串不为空"
else
   echo "$a : 字符串为空"
fi
```

执行脚本，输出结果如下：

![](http://ww2.sinaimg.cn/large/006tNc79ly1femi6x7sshj30zw068t9p.jpg)


### 文件测试运算符

文件测试是用于检测 Linux文件的各种属性

属性检测描述如下：

```bash
-b file    检测文件是否是块设备文件，如果是，则返回 true。    
-c file    检测文件是否是字符设备文件，如果是，则返回 true。    
-d file    检测文件是否是目录，如果是，则返回 true。    
-f file    检测文件是否是普通文件（既不是目录，也不是设备文件），如果是，则返回 true。    
-g file    检测文件是否设置了 SGID 位，如果是，则返回 true。    
-k file    检测文件是否设置了粘着位(Sticky Bit)，如果是，则返回 true。    
-p file    检测文件是否是具名管道，如果是，则返回 true。    
-u file    检测文件是否设置了 SUID 位，如果是，则返回 true。    
-r file    检测文件是否可读，如果是，则返回 true。   
-w file    检测文件是否可写，如果是，则返回 true。    
-x file    检测文件是否可执行，如果是，则返回 true。    
-s file    检测文件是否为空（文件大小是否大于0），不为空返回 true。   
-e file    检测文件（包括目录）是否存在，如果是，则返回 true。    
```

**实例**

```bash
#!/bin/bash

a="abc"
b="efg"

if [ $a = $b ]
then
   echo "$a = $b : a 等于 b"
else
   echo "$a = $b: a 不等于 b"
fi
if [ $a != $b ]
then
   echo "$a != $b : a 不等于 b"
else
   echo "$a != $b: a 等于 b"
fi
if [ -z $a ]
then
   echo "-z $a : 字符串长度为 0"
else
   echo "-z $a : 字符串长度不为 0"
fi
if [ -n $a ]
then
   echo "-n $a : 字符串长度不为 0"
else
   echo "-n $a : 字符串长度为 0"
fi
if [ $a ]
then
   echo "$a : 字符串不为空"
else
   echo "$a : 字符串为空"
fi
```

执行脚本，输出结果如下：

![](http://ww3.sinaimg.cn/large/006tNc79ly1femigh5j08j310208idgt.jpg)


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=32341272&auto=1&height=66"></iframe>

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。


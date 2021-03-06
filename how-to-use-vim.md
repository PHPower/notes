---
title: vim编辑器入门使用教程
date: 2017-04-06 13:59:28
tags: [linux,vim]
categories: linux基础知识
---

<blockquote class="blockquote-center">Vim是一个高度可配置的文本编辑器，用于创建和更改任何类型的文本非常高效。
它与大多数UNIX系统、Linux系统和Apple OS X一起被列为“vi”
</blockquote>

**vim的功能包括：**
* 广泛的插件系统
* 支持数百种编程语言和文件格式
* 强大的搜索和替换功能
* 与许多工具集成

![](https://ww2.sinaimg.cn/large/006tNbRwly1fecxo9nswuj31040rw77l.jpg)


<!-- more -->


-------

下面是vim添加插件之后的效果，很酷吧！

![](https://ww4.sinaimg.cn/large/006tNbRwly1fecxocn6odj31040rwq5x.jpg)

让我们一起来学习如何使用这款风靡各个操作系统之间的文本编辑器吧！

-------

# vim基本概念

基本上vim可以分为三种模式。分别是：

1. 命令模式（Command mode）
2. 插入模式（Insert mode）
3. 末行模式（Last line mode）

各模式的功能如下：

{% note primary %}（1）命令模式：
    在**命令模式**，我们可以控制屏幕光标的移动，字符或行的删除，移动复制文本。在**命令模式**可以随时切换到**插入模式**与**末行模式**。  {% endnote %}



{% note success %}（2）插入模式：
    在**插入模式**，我们可以进行文字的输入、删除、修改等操作。按**[ESC]**键可回到**命令模式**。  {% endnote %}


{% note warning %}（3）末行模式：
    在**末行模式**，我们可以将文件保存或退出vim，也可以设置vim的编辑环境。如设置是否显示行号、括号匹配高亮显示和语法高亮等等。 {% endnote %}


-------

{% note primary %}# 如何在Linux中使用vim
{% endnote %}



了解了**vim**的三个模式之后，我们就开始学习如何在Linux使用**vim**来编辑文件吧！

在Linux的命令行输入

```bash
$ vim [FILENAME]
```

即可打开文件开始编辑了。
* 如果文件事先存在，这时**vim**将会把存在的文件打开，并把光标移动至文本首行的行首。
* 如果文件不存在，**vim**将会为我们打开一个新的文件，并让我们编辑。

*下面这张图就是在当前工作目录下打开一个新的文件。（这时我们处在命令模式）*

![](https://ww2.sinaimg.cn/large/006tNbRwly1fecyffn7vqj310y0rwtaf.jpg)


-------


{% note warning %}## 各模式使用方法
{% endnote %}

当我们使用**vim**打开一个文件后的最要紧的就是进行文本的输入，然后保存。
所以，熟练掌握各模式之间切换的方法至关重要。

### 各模式之间切换


* **命令模式 --> 插入模式**

使用以下**实体键**可以在命令模式**切换**到插入模式

```bash
i:insert,在光标所在处输入
a:append,在光标所在处的后方输入
o:在光标所在出下方打开一个新行
A:在光标所在出的行尾输入
I:在光标所在处的行首输入
O:在光标所在处的上方打开一个新行
```

* **插入模式 --> 命令模式**

按**[ESC]**即可从插入模式退出到命令模式。如果为了万全，可以按两次。

* **命令模式 --> 末行模式**

按 **:** 即可进入到末行模式

* **末行模式 --> 命令模式**

按**[ESC]**即可从末行模式退出到命令模式。如果为了万全，可以按两次。


### 命令模式下的操作方法

{% note warning %}#### 光标跳转
{% endnote %}

**字符间跳转：**

```bash
h键          --向左跳转一个字符
l键          --向右跳转一个字符
j键          --向下跳转一个字符
k键          --向上跳转一个字符
```
如果键盘上有上、下、左、右箭头的导航键，也可以使用其来完成光标的移动。

**单词间跳转：**


```bash
w键          --跳到下一个单词的词首
b键          --跳到当前或前一个单词的词首
e键          --跳到当前或后一个单词的词尾
```

**行首/尾间跳转：**

```bash
^键          --跳转至行首第一个非空白字符
0键          --跳转至行首(tab键不算）
$键          --跳转至行尾
```

**行间跳转：**

```bash
#G           --跳转至由#号指定的行的行首
1G/gg        --跳转至第一行的行首(这两种方法都可以)
G键          --跳转至最后一行的行首
```

**翻屏操作：**

```bash
Ctrl+f键         --向文件尾部翻一屏
Ctrl+b键         --向文件首部翻一屏
Ctrl+d键         --向文件尾部翻半屏
Ctrl+u键         --向文件首部翻半屏
Enter键          --按行向后翻
b键              --按行向前翻
```

**当前页跳转：**

```bash
H键          --跳转至当前页的页首
M键          --跳转至当前页的中间行位置
L键          --跳转至当前页的页底
```

**句间跳转：**

```bash
)键          --跳转至前一句
(键          --跳转至后一句
```

**段间跳转：**

```bash
}键          --跳转至前一段
{键          --跳转至后一段
```

{% note success %}#### 替换和删除
{% endnote %}

**字符编辑：**

```bash
x键          --删除光标所在处的字符
6x键         --删除光标所在处起始的 6 个字符
nx键         --删除光标所在处的后 n 个字符
xp键         --交换光标所在处的字符以及后面字符的位置
```

**替换命令：**

```bash
r键          --替换光标所在处的字符，用任意键替换当前字符
nrc键        --用 c 替换光标所在处的后 n 个字符
6rA         --用 A 替换光标所在处的后 6 个字符
```

**删除命令：**

```bash
d键          --删除命令，可结合光标跳转字符实现范围删除
d$键         --删除光标所在处到行尾的字符
d^键         --删除光标所在处到行首的字符
dd键         --删除光标所在行
ndd键        --删除光标所在处的行起始共 n 行
```

**改变命令：**

从**命令模式**执行操作之后直接进入到**插入模式**

```bash
c键          --改变命令，工作行为相似于d命令
c$键         --删除光标所在处至行尾的字符，并进入插入模式
c^键         --删除光标所在处至行首的字符，并进入插入模式
cw键         --删除光标所在处至当前词尾的字符，并进入插入模式
cc键         --删除光标所在的行，并进入插入模式
```

{% note info %}#### 其他操作命令
{% endnote %}


**复制粘贴：**

在vim从正文中删除的内容并没有真正丢失，而是被剪切并复制到一个内存缓冲区中。

```bash
p键          --小写字母 p ，将缓冲区的内容粘贴至光标所在处的后方
P键          --大写字母 P ，将缓冲区的内容粘贴至光标所在处的前方
```

如果缓冲区的内容是字符或字，直接粘贴在光标的前面或后面；如果缓冲区的内容为整行正文，执行上述粘贴命令将会粘贴在当前光标所在行的上一行或下一行。


```bash
y键          --复制命令
yy键         --复制当前行到内存缓冲区
nyy键        --复制 n 行内容到内存缓冲区
```

**撤销和重复：**

在编辑文档的过程中，为消除某个错误的编辑命令造成的后果，可以用撤消命令。

```bash
u键          --撤销此前的操作
nu键         --撤销此前 n 个操作

Ctrl+r键     --撤销此前的撤销操作

.键          --重复执行前一个修改正文的命令
```

-------

### 插入模式下的操作方法

{% note default %}#### 进入插入模式
{% endnote %}

在命令模式下定位好光标位置后，可以用以下命令进入到**插入模式**：

```bash
i:insert,在光标所在处输入
a:append,在光标所在处的后方输入
o:在光标所在出下方打开一个新行
A:在光标所在出的行尾输入
I:在光标所在处的行首输入
O:在光标所在处的上方打开一个新行
```

{% note danger %}#### 退出插入模式
{% endnote %}

退出插入模式的方法是，按 ESC 键或组合键 Ctrl+[ ，退出插入模式之后，将会进入编辑模式 。


-------

### 末行模式下的操作方法

Vim的**末行模式**下，可以使用复杂的命令。在**命令模式**下键入 : ，光标就跳到屏幕最后一行，并在那里显示冒号，此时已进入末行模式，用户输入的内容均显示在屏幕的最后一行，按回车键，Vim 执行命令。


{% note primary %}#### 打开、保存、退出
{% endnote %}

在已经启动的vim中打开一个文件需要用`:e`命令

```bash
:e /PATH/TO/SOMEFILE
```

保存当前编辑的文件需要用`:w`命令

```bash
:w
```

另存为当前编辑的文件

```bash
:w /path/to/somefile
```

在命令模式下，可以使用`:q`或者`ZZ`退出vim

```bash
:q          --在未修改文件内容的情况下退出
:q!         --放弃修改，退出vim
ZZ键        --保存并退出
:wq         --保存并退出
```

{% note success %}#### 地址定界
{% endnote %}

在命令模式下每一行正文都有自己的行号，用以下命令可以将光标移动至指定行

```bash
:n           --将光标移动至第 n 行
:.           --表示当前行
:$           --表示正文的最后一行
:n,m         --指定行范围，n 为起始行,m为结束行(m>n)
:n,+n        --指定行范围，n为起始行，+n 为 n 的偏移量。
:1,$         --第一行至最后一行
:%           --表示全文
:233         --将光标移动至第 233 行
:233w file   --将第 233 行写入 file 文件内
:3,5w file   --将第 3 行至第 5 行写入file文件内
:1,.w file   --将第1行至当前行写入 file 文件
:.,$w file   --将当前行至最后一行写入 file 文件
:.,.+5w file --从当前行开始将 6 行内容写入 file 文件
:1,$w file   --将所有内容写入 file 文件
```

{% note info %}#### 查找与替换
{% endnote %}

**末行模式**可以进行字符串搜索，给出一个字符串，可以通过搜索该字符串到达指定行。如果希望进行正向搜索，将待搜索的字符串置于两个 **/** 之间；如果希望反向搜索，则将字符串放在两个 **？** 之间。

```bash
:/PATTERN           --正向搜索，将光标移到下一个包含字符串 PATTERN 的行
:?PATTERN           --反向搜索，将光标移到上一个包含字符串 PATTERN 的行
```
使用 `n` 键进行在匹配到的字符串之间向下跳转
使用 `N` 键进行在匹配到的字符串之间向下跳转


在末行模式也可以对正文内容进行替换的操作，使用 `:s` 命令：

```bash
s/要查找的内容/替换为的内容/修饰符
:%s/str1/str2/          --用字符串 str2 替换全文行中第一次出现的字符串 str1
:s/str1/str2/g          --用字符串 str2 替换当前光标所在行中所有的 str1
:n,ms/str1/str2/g       --将从 n 行到 m 行的所有 str1 替换成 str2
```

从上述命令可以看到：

* `%` 表示替换范围是所有行，即全文内容
* `s` 后面跟一串替换的命令
* `g` 是修饰符，表示全局替换
* `i` 是修饰符，表示查找时忽略字符大小写
* `/` 是分隔符，而且此分隔符可以替换成其他特殊字符；如：@、#

另外一个实用的命令，统计全文中字符串 `str1` 出现的次数：

```bash
:%s/str1/&/gn
```


{% note warning %}#### 删除功能
{% endnote %}

在末行模式下，也可以实现删除正文的功能：

```bash
:d                              --删除光标当前所在行
:nd                             --删除光标所在处的行以及下面 n-1 行的内容
:.,$d                           --删除当前行至行尾的内容
:g/^\(.*\)$\n\1$/d              --删除连续相同的行，保留最后一行
:g/\%(^\1$\n\)\@<=\(.*\)$/d     --删除连续相同的行，保留最开始一行
:g/^\s*$\n\s*$/d                --删除连续多个空行，只保留一行空行
:5,20s/^#//g                    --删除5到20行开头的 # 注释
```

### 定制vim的工作特性

在末行模式下进行定制，仅对当前 `vim` 进程有效。

永久有效：
1. 全局：/etc/vimrc文件
2. 用户个人：~/.vimrc（一般没有，需要手动创建）

使用 `:set` 命令进行设置：

```bash
:set [option]           --选项的设置
```

{% note warning %}常见的功能选项包括
{% endnote %}


```bash
autoindent          --设置该选项，则正文自动缩进
ignorecase          --设置该选项，则忽略规则表达式中大小写字母的区别
number              --设置该选项，则显示正文行号
ruler               --设置该选项，则在屏幕底部显示光标所在行、列的位置
tabstop             --设置按 Tab 键跳过的空格数。例如 :set tabstop=n，n 默认值为 8
hlsearch            --设置该选项，则搜索高亮显示
syntax              --设置该选项，则启动语法高亮
help                --获取帮助
```


### 分屏功能

如果想同时查看多个文件，就需要用到 `vim` 的分屏功能。
`vim` 的分屏，主要有两种方式：
1. 上下分屏（水平）
2. 左右分屏（垂直）


```bash
:sp             --上下分屏
:vsp            --左右分屏
```

也可以在终端的命令行就启用分屏功能：


```bash
$ vim -o file1 file2 ...    --水平分屏
$ vim -O file1 file2 ...    --垂直分屏
```

理论上，一个`vim`窗口可以，可以分为多个屏幕，切换屏幕需要使用键盘组合键以及方向键：

```bash
Ctrl+w+←        --切换到当前分屏的左边一屏
Ctrl+w+→        --切换到当前分屏的右边一屏
Ctrl+w+↓        --切换到当前分屏的下边一屏
Ctrl+w+↑        --切换到当前分屏的上边一屏
```

-------

# vim插件

vim“编辑器之神”的称号并不是浪得虚名，然而，这个荣誉的背后，或许近半的功劳要归功于强大的插件支持特性，以及社区开发的各种各样功能强大的插件。

插件的配置，请参考下面的链接：

1. Vim配置、插件和使用技巧：http://www.jianshu.com/p/a0b452f8f720
2. 手把手教你把Vim改装成一个IDE编程环境：http://blog.csdn.net/wooin/article/details/1858917


-------

# vim官方文档

1. vim官方文档：http://vimdoc.sourceforge.net/
2. vim维基中文文档：https://wiki.archlinux.org/index.php/Vim_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)

-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=29378196&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



<!--author：maxie（马驰原）-->
<!--QQ：17045930-->


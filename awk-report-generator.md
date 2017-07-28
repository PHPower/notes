---
title: Linux文本三剑客之"awk"
date: 2017-05-21 12:47:39
tags: [linux,awk,editor,command]
categories: linux进阶
---



<blockquote class="blockquote-center">awk是一个强大的文本分析工具。
它不仅是Liunx中，也是任何环境中现有功能最强大的数据处理引擎之一。
相对于“grep“的查找，”sed“的编译，awk在其对数据分析并生成报告时，显得尤为强大。
</blockquote>

当你第一次拿起双手在电脑上使用 awk 命令处理一个或者多个文件的时候，它会依次读取文件的每一行内容, 然后对其进行处理，awk 命令默认从 stdio 标准输入获取文件内容, awk 使用一对单引号来表示 一些可执行的脚本代码，在可执行脚本代码里面，使用一对花括号来表示一段可执行代码块，可以同时存在多个代码块。 awk 的每个花括号内同时又可以有多个指令，每一个指令用分号分隔，awk 其实就是一个脚本编程语言。



{% fullimage /images/Fallen-leaves.png, jumpserver, %}



<!-- more -->



{% note primary %}### awk语法以及基本使用方法
{% endnote %}

#### awk命令的基本语法

```
awk [OPTIONS] 'program' FILE...
```
options 这个表示一些可选的参数选项，反正就是你爱用不用，不用可以拉到。。。 

**常用选项有：**

```bash
-F fs：字段分隔符；fs指定输入分隔符，fs可以是字符串或正则表达式，如-F: 
-v var=value：用于实现自定义变量
-f FILENAME：直接从文件内读取执行的 'program'  
```


program 这个表示 awk 的可执行脚本代码，这个是必须要有的。 
其中`program`的格式如下：

```bash
'program'：PATTERN{ACTION STATEMENTS}
ACTION STATEMENTS：动作语句，可以有多个；语句之间用分号分隔
```

file 这个表示 awk 需要处理的文件，注意是纯文本文件，不是你的 mp3，也不是 mp4 啥的。。


-------


#### awk的內建命令与变量


##### 一、內建命令


1、print打印

`print item1,item2 ...`

要点：
（1）逗号分隔符
（2）输出的各 item 可以是字符串，也可以是数值；当前记录的字段、变量或awk的表达式
（3）如果省略 item，通常相当于执行 print $0 打印整行字


2、printf 命令

格式化输出：
`printf ”FORMAT“,item1,item2,....`

要点：
（1）FORMAT：必须给出
（2）printf：不会自动换行，需要显示给出换行符: \n 
（3）FORMAT中需要分别为后面的每个item指定一个格式化符号

**格式符：**

```
%c          显示字符的ACSII码
%d,%i       显示十进制整数；d表示显示10进制，i表示整数
%e,%E       显示为科学计数法数值显示
%f          显示为浮点数  float
%g,%G       以科学计数法或浮点形式显示数值
%s          显示字符串
%u          无符号整数
%%          显示%自身
```

**实例：**

```
awk '{FS=":";printf "%s\n",$1}' /etc/passwd

[root@centos7 ~]# awk -F: '{printf "Username:   %s\n",$1}' /etc/passwd
Username:   root
Username:   bin
Username:   daemon
Username:   adm

[root@centos7 ~]# awk -F: '{printf "Username:  %s UID: %d \n",$1,$3}' /etc/passwd
Username:   root UID:   0
Username:   bin UID:   1
Username:   daemon UID:   2
```
												
**格式符的修饰符：**
 
```
#[.#]:
	第一个数字用来控制 显示的宽度
	第二个数字用来表示 小数点的精度
	%3.1f
```

默认为右对齐

	[root@centos7 ~]# awk -F: '{printf "Username: %10s  UID: %d\n",$1,$3}' /etc/passwd
	Username:       root  UID: 0
	Username:        bin  UID: 1
	Username:     daemon  UID: 2

-：减号表示左对齐

	root@centos7 ~]# awk -F: '{printf "Username: %-10s  UID: %d\n",$1,$3}' /etc/passwd
	Username: root        UID: 0
	Username: bin         UID: 1
	Username: daemon      UID: 2

+：加号表示显示数值的符号（正数负数）


##### 二、內建变量

**特殊内置变量：**

```
$0 这个表示文本处理时的当前行

$1 表示文本行被分隔后的第 1 个字段列

$2 表示文本行被分割后的第 2 个字段列

$3 表示文本行被分割后的第 3 个字段列

$n 表示文本行被分割后的第 n 个字段列
```

`awk`中的內建变量，无需使用 $ 符号直接可以调用变量的值

（1）FS：input field seperator，指定分隔符，默认为空白字符；

`awk -v FS=":" '{print $1 }' /etc/passwd `

（2）OFS：output field seperator，指定输出分隔符，默认为空白字符
	
`awk -v FS=":" -v OFS=":" '{print $1}' /etc/passwd`

（3）RS：input record seperator，输入时的换行符

`awk -v RS=" " '{print}' /etc/passwd`

（4）ORS：output record seperator，输出时的换行符

（5）NF：number of field，字段数量
	{print NF}：显示文本的每行字段数量
	{print $NF}：显示每行末尾字段的信息

（6）NR：number of record，行数（默认输出每一行的行号），最后一行的行号即为这个文件的总行数
	{print NR}

（7）FNR：files number of record，统计多个文件的行数，分别打印(各文件分别计数)
	{print FNR}

（8）FILENAME：当前正在处理的文件名

（9）ARGC：命令行参数的个数
	ARGV：数组，保存命令行中所给定的各参数


```
[root@centos7 ~]# awk 'BEGIN{print ARGC}' /etc/fstab
2
[root@centos7 ~]# awk 'BEGIN{print ARGV[0]}' /etc/fstab /etc/issue
awk
[root@centos7 ~]# awk 'BEGIN{print ARGV[1]}' /etc/fstab /etc/issue
/etc/fstab
```

自定义变量：
(1)-v var=value ：自定义变量
	var：变量名，区分大小写
	value：值
	
(2)在'program'中直接定义：
	
```
[root@centos7 ~]# awk -v test="hello" 'BEGIN{print test}'
hello
[root@centos7 ~]# awk 'BEGIN{test="hello";print test}'
hello
```

##### 三、操作符

* 算数操作符：

```bash
x+y，x-y，x*y，x-y，x/y，x^y，x%y
-x
+x：转换为数值
```

* 字符串操作符：没有符号的操作符(字符串连接)

* 赋值操作符：

```bash
=，+=，-=，*=，/=，%=，^=，++，--
```

* 比较操作符：

```
>,>=,<,<=,!=不等于,==等值比较
```

* 模式匹配符：

```
~：左侧字符串是否匹配右侧的模式
！~：左侧字符串是否不匹配右侧的模式

```

*  逻辑操作符：

```
&&：与
||：或
! ：非
```


函数调用：

```
function_name() ：进行调用函数
或者
function_name(arg1,arg2,arg3)
```

**条件表达式：**

`selector? if-true-expression:if-false-expression `

selector：条件表达式，后面跟 ? 号
如果条件为真，则执行 if-true-expression
否则，执行 if-false-expression

**实例：**


```
[root@centos7 ~]# awk -F: '{$3>=1000?usertype="Common User":usertype="System User";printf "Username: %15s %s\n",$1,usertype}' /etc/passwd
Username:            root System User
Username:             bin System User
Username:          daemon System User
```
$3>=1000?  ：以 : 为分隔符，判断第三个字段的值是否大于1000
如果为真，执行变量赋值：usertype="Common User"
否则，执行变量赋值：usertype="System User"

-------


{% note success %}### awk进阶使用方法
{% endnote %}

#### PATTERN 模式匹配

awk中的模式匹配功能，有点类似于地址定界的功能。

(1) empty（匹配每一行）:空模式

(2) /regular expression/：能够其中基本正则表达式匹配到的行，对其进行处理，未匹配到的行不做任何操作
	仅能够处理能够被此处的模式匹配到的行

如果想对其中模式匹配到的取反，可以使用：!/regular expression/ 进行取反操作


```
[root@centos7 ~]# awk '/^UUID/{print $1}' /etc/fstab
UUID=ab341a4b-a908-47c0-9553-bcf79b05ce43
UUID=531365c9-8be5-40a1-bd9e-9bc980d21cda
....
[root@centos7 ~]# awk '!/^UUID/{print $1}' /etc/fstab

#
#
#
...
```


（3） relational expression：关系表达式
	结果有真，有假；结果为”真“，才会处理
	真表示：结果为非0值，或者非空字符串；0表示假


```
[root@centos7 ~]# awk -F: '$3>=1000{print $1,$3}' /etc/passwd
nfsnobody 65534
hacker 1000
maxie1 1001

其中 $3>=1000 就是关系表达式，如果为真才会打印 $1 $3

注意： 这里的{print $1 $3} 之前没有分号，因为这是一个语句

[root@centos7 ~]# awk -F: '$NF=="/bin/bash"{print $1,$NF}' /etc/passwd
root /bin/bash
hacker /bin/bash
maxie1 /bin/bash
您在 /var/spool/mail/root 中有新邮件
[root@centos7 ~]# awk -F: '$NF~"/bin/bash"{print $1,$NF}' /etc/passwd
root /bin/bash
hacker /bin/bash
maxie1 /bin/bash
[root@centos7 ~]# awk -F: '$NF~/bash$/{print $1,$NF}' /etc/passwd
root /bin/bash
hacker /bin/bash
maxie1 /bin/bash
```

这里 $NF 表示的是 每一行最后一个字段的值

注意：在使用模式匹配时，要在前后加上 // 符号


（4）line ranges ：行范围（地址定界）

startline,endline：
	
/pattern1/,/pattern2/这样来定义
或者
(NR>=number&&NR<=number)这样的格式来定义
	
	NR：每一行的行号

注意：不支持直接给出数字的方式


```
[root@centos7 ~]# awk -F: '/^b/,/^sync/{print $1}' /etc/passwd
bin
daemon
adm
lp
sync

[root@centos7 ~]# awk -F: '(NR<=10){print $1}' /etc/passwd
root
bin
daemon
adm
lp
sync
shutdown
halt
mail
operator
[root@centos7 ~]# awk -F: '(NR<=10&&NR>=2){print $1}' /etc/passwd
bin
daemon
adm
lp
sync
shutdown
halt
mail
operator
```

	
（5）BEGIN/END模式：

BEGIN{}：仅在开始处理文件中的文本之前执行一次（可以打印表头）

END{}：仅在文本处理完成之后执行一次


```
[root@centos7 ~]# awk -F: 'BEGIN{print "username        uid      \n----------------------"} {printf "%-15s %s\n",$1,$3} END{print "======================="}' /etc/passwd
username        uid
----------------------
root            0
bin             1
daemon          2
....
hacker          1000
maxie1          1001
dhcpd           177
=======================
```

-------

{% note info %}### awk中各控制语句的用法
{% endnote %}

#### 1、if-else 语句

语法：

```
if(condition) statement  [else statement]	
```

如果有多个语句 则是 {statements}

实例：
	
```
[root@centos7 ~]# awk -F: '{if($3>=1000) print $1,$3}' /etc/passwd
nfsnobody 65534
hacker 1000
maxie1 1001
[root@centos7 ~]# awk -F: '{if($3>=1000) {print $1,$3} else {print "system user"}}' /etc/passwd


对一行中字段数量大于6的，进行打印 print $0，也就是匹配的整行

[root@centos7 ~]# awk '{if(NF>6) print}' /etc/fstab
#Created by anaconda on Sun Mar 19 02:00:07 2017
#Accessible filesystems, by reference, are maintained under '/dev/disk'
#See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info

[root@centos7 ~]# df -h | awk -F"%" '/^\/dev/{print $1}' | awk 'BEGIN{ print "Disk full\n------------"}{if($NF>=15) print $1}'
Disk full
------------
/dev/sda3
/dev/sda1
```

先对设备进行取出，并以%为分隔符，取出$1的值；再对$NF,也就是最后一个字段的值进行判断

使用场景：对awk取得的整行或某个字段做条件判断


#### 2、while 循环

语法：

```
while(condition) statement
```

条件为真，进入循环
条件为假，退出循环


使用场景：对一行内的多个字段 逐一/类似 处理时使用； 对数组中的各元素逐一处理时使用


实例：

```bash
'对每一行的每一个字段进行计算字段长度'
[root@centos7 ~]# awk '/^[[:space:]]*linux16/{i=1;while(i<=NF) {print $i,length($i); i++}}' /etc/grub2.cfg
linux16 7
/vmlinuz-3.10.0-514.el7.x86_64 30
root=UUID=ab341a4b-a908-47c0-9553-bcf79b05ce43 46
ro 2
rhgb 4
quiet 5
```

```bash
'只有当一个字段内字符长度大于7时，才打印'
[root@centos7 ~]# awk '/^[[:space:]]*linux16/{i=1;while(i<=NF) {if(length($i)>=7) {print $i,length($i)} i++}}' /etc/grub2.cfg
linux16 7
/vmlinuz-3.10.0-514.el7.x86_64 30
root=UUID=ab341a4b-a908-47c0-9553-bcf79b05ce43 46
LANG=en_US.UTF-8 16
```

#### 3、do while 循环（至少会执行一次循环体）

语法：

```
do statement while(condition)
```

#### 4、for 循环
语法：

```
for(expr1;expr2;expr3) statement

expr1：控制变量初始化
expr2：条件判断
expr3：控制变量数值修正表达式
```


```
for(variable assignment;condition;iteration process) {for-body}
```

实例：

```bash
'对每一行的每一个字段进行计算字段长度'
[root@centos7 ~]# awk '/^[[:space:]]*linux16/{for(i=1;i<=NF;i++) {print $i,length($i)}}' /etc/grub2.cfg
linux16 7
/vmlinuz-3.10.0-514.el7.x86_64 30
root=UUID=ab341a4b-a908-47c0-9553-bcf79b05ce43 46
ro 2
rhgb 4

[root@centos7 ~]# awk '/^[[:space:]]*linux16/{for(i=1;i<=NF;i++) {if(length($i)>=7) {print $i,length($i)} }}' /etc/grub2.cfg
linux16 7
/vmlinuz-3.10.0-514.el7.x86_64 30
root=UUID=ab341a4b-a908-47c0-9553-bcf79b05ce43 46
LANG=en_US.UTF-8 16

```
**特殊用法：**

```bash
'能够遍历数组中的元素'

语法：
for(var in array) {for-body}

若要遍历数组中的每个元素，要使用for循环：
for(var in array) {for-body}

[root@centos7 ~]# awk 'BEGIN{weekdays["mon"]="Monday";weekdays["tue"]="Tuesday";for(i in weekdays) {print weekdays[i]}}'
Tuesday
Monday
```

#### 5、array数组：

关联数组：array[index-expression]

index-expression：

```
(1)可使用任意字符串;字符串需要使用双引号
(2)如果某数组元素不存在，在引用时，awk 会自动创建此 元素，并将其初始化为”空串“
```

若要判断数组中是否存在某元素，要使用”index in array“格式进行：

weekdays["mon"]="Monday"


```
[root@centos7 ~]# awk 'BEGIN{weekdays["mon"]="Monday";weekdays["tue"]="Tuesday";print weekdays["tue"]}'
Tuesday
[root@centos7 ~]# awk 'BEGIN{weekdays["mon"]="Monday";weekdays["tue"]="Tuesday";print weekdays["mon"]}'
Monday
[root@centos7 ~]# awk 'BEGIN{weekdays[0]="Monday";weekdays[1]="123";print weekdays[0]}'
Monday
[root@centos7 ~]# awk 'BEGIN{weekdays[0]="Monday";weekdays[1]="123";print weekdays[1]}'
123
```


若要遍历数组中的每个元素，要使用for循环：
for(var in array) {for-body}


```
[root@centos7 ~]# awk 'BEGIN{weekdays["mon"]="Monday";weekdays["tue"]="Tuesday";for(i in weekdays) {print weekdays[i]}}'
Tuesday
Monday
```

注意：var 会遍历 array 的每个索引，但顺序可能不同


实例：

```bash
'1、统计 netstat -tnl 中state状态有几种，各出现了几次'
[root@centos7 ~]# netstat -tnl | awk '/^tcp\>/{state[$NF]++}END{for(i in state) {print i,state[i]}}'
LISTEN 4

'2、统计 httpd 的 /var/log/httpd/access_log 文件中 ip地址的访问次数'
[root@centos7 ~]# awk '{ip[$1]++}END{for(i in ip) print i,ip[i]}' /var/log/httpd/access_log
172.16.1.122
172.16.1.11
::1

'3、netstat -tna 查看连接到本机IP地址和状态'
[root@centos7 ~]# netstat -tan | awk  -v FS='[[:space:]:]+' '$(NF-2)~/\.+/{if (1!=NR) IpState[$6"  "$NF]++}END{for(i in IpState) {print i,IpState[i]}}'
172.16.1.11  ESTABLISHED 2
```


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=16532462&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)





---
title: Linux用户和用户组管理
date: 2017-03-30 19:02:48
tags: [linux,user,command]
categories: linux基础知识
---
<blockquote class="blockquote-center">共产主义是一种伪科学, 演变成一种伪宗教, 最终表现为僵化的集权式的邪恶政治集团!

Richard Pipes (《共产主义实录》作者)</blockquote>


> Linux系统是一个多用户、多任务的操作系统
> 任何一个要想使用系统内部资源的用户，必须首先向Linux系统管理员申请一个账号，然后以这个用户的身份登录到系统中。这个账号一方面可以帮助系统管理员对使用系统的用户进行管理，并限制他们对系统资源的访问；另一方面也可以为用户提供安全性保护。每个用户账号都拥有一个惟一的用户名和各自的口令。用户在登录时键入正确的用户名和口令后，就能够进入系统和自己的主目录。 


#### Linux下用户的角色分类

Linux下用户是根据角色定义的，具体分为三种角色：

1. 管理员：默认为**root**用户（**UID=0**），拥有对操作系统最高管理权限（甚至可以kill itself）
2. 普通用户：只能对自己目录下的文件进行访问和修改，具有登陆系统的权限。
3. 系统用户（**伪用户**）：这类用户的特点是不能登录操作系统，他们的存在主要是方便系统管理，满足相应的系统进程对文件属主的要求。

#### 用户和组的关系

用户和用户组的**对应关系**有：一对一、一对多、多对一和多对多。
下图展示了这种关系：

![](https://ww1.sinaimg.cn/large/006tNbRwly1fe53jbpg39j30br066q3o.jpg)

<!-- more -->
 
  **一对一**：即一个用户可以存在一个组中，也可以是组中的唯一成员。
  **一对多**：即一个用户可以存在多个用户组中。那么此用户具有多个组的共同权限。
  **多对一**：多个用户可以存在一个组中，这些用户具有和组相同的权限。
  **多对多**：多个用户可以存在多个组中。其实就是上面三个对应关系的扩展。

    
-------

    
#### 用户组的概念

**用户组**是具有相同特征用户的逻辑集合，有时我们需要让很多个用户具有相同的权限，比如查看、修改、删除一个目录下的文件。一种方法是分别对每个用户进行权限的授权，如果用户数特别多的话，这样显然不符合我们省事的宗旨；另一种方法就是建立一个小组，把这些需要拥有权限的用户们加到这个组中，然后让这个组具有对这个目录下的文件，查看、修改、删除的权限，这样组内用户都具有了和组一样的权限。

这就是用户组，将用户分组是Linux系统中对用户进行管理及控制访问权限。


-------


#### 安全上下文的概念

我们都知道**程序=指令+数据**

在Linux运行中的程序是以**进程**（process）的方式存在的。

进程是应用的实际载体，是系统资源分配和调度的基本单位。

Linux中每个进程都会由发起者，而这个进程能够做的事情，取决去发起进程的发起者的权限。


-------

#### 用户和用户组的主要配置文件


| 配置文件位置| 存储的信息 |
| --- | --- |
| /etc/passwd | 用户及其属性信息 |
| /etc/group | 用户组及其属性信息  |
| /etc/shadow | 用户和其对应的密码及其相关属性 |
| /etc/gshadow | 用户组密码及其相关属性 |


##### 系统用户配置文件(/etc/passwd)

此文件是Linux用户管理中最重要的一个文件。这个文件记录了Linux系统中每个用户的一些基本属性，并且对所有用户可读。

文件内每一行记录对应一个用户，其格式和具体含义具体如下：

> 用户名:密码占位符:UID:GID:注释信息:用户家目录:用户默认shell
> 
> 

```bash
# head /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
```

**passwd文件每个字段的详细含义**

**用户名**：用户账号的字符串。

**密码占位符**：这个位置在之前是存放着用户的密码，但是由于考虑每个用户都能访问，这样对于系统的安全性是不安全的。所以现在许多Linux版本都使用了shadow技术，把真正加密后的用户口令存放到/etc/shadow文件中，而在/etc/passwd文件的口令字段中只存放一个特殊的字符，例如用“x”或者“*”来表示。 

**用户标识号**：用户的UID，每个用户都有一个UID，并且是唯一的，通常UID号的取值范围是0～65535，**0是超级用户root的标识号**。而在Linux系统中，普通用户UID默认从**500**开始，****开始是从**1000**开始。UID是Linux下确认用户权限的标志，用户的角色和权限都是通过UID来实现的，因此多个用户公用一个UID是非常危险的，会造成系统权限和管理的混乱，例如将普通用户的UID设置为0后，这个普通用户就具有了root用户的权限，这是极度危险的操作。因此要尽量保持用户UID的唯一性。

**组标识号**：组的GID，与用户的UID类似，这个字段记录了用户所属的用户组。它对应着/etc/group文件中的一条记录。

**注释性描述**：字段是对用户的描述信息，比如用户的email，住址。

**家目录**：也就是用户登录到系统之后默认所处的目录，也可以叫做用户的主目录、家目录、根目录等等。

**默认shell**：就是用户登录系统后默认使用的命令解释器，shell是用户和linux内核之间的接口，用户所作的任何操作，都是通过shell传递给系统内核的。linux下常用的shell有sh、bash、csh、zsh等，管理员可以根据用户的习惯，为每个用户设置不同的shell。



-------

##### 用户影子文件(/etc/shadow)

用户影子文件，由于/etc/passwd文件是所有用户都可读的，这样会导致用户的密码容易泄露。因此Linux将密码信息从/etc/passwd中分离出来。单独的放到了一个文件中，这个文件就是/etc/shadow，该文件只有root用户拥有读权限，从而保证了用户密码的安全性。

**/etc/shadow文件内容的格式：**

>用户名:加密口令:最近一次修改密码的时间:密码最短使用期限:密码最长使用时间:警告时间:密码过期时间:保留字段
>
>

```bash
# head /etc/shadow
root:$6$VmyBrA3R5Q.fFp/:17246:0:99999:7:::
bin:*:16659:0:99999:7:::
```



-------


##### 用户组配置文件(/etc/group)

用户组配置文件，用户组的所有信息都存放在此文件中

**/etc/group文件内容的格式：**

> 组名:口令:组标识号:组内用户列表

```bash
# head /etc/group
root:x:0:
bin:x:1:
```

##### 创建用户时默认配置文件（/etc/login.defs)

下面是Centos的/etc/login.defs文件


```bash
CentOS版本信息：

LSB Version:    :core-4.1-amd64:core-4.1-noarch
Distributor ID: CentOS
Description:    CentOS Linux release 7.2.1511 (Core)
Release:        7.2.1511
Codename:       Core

配置文件：

MAIL_DIR        /var/spool/mail  #当创建用户时，同时在/var/spool/mail中创建一个用户mail文件
PASS_MAX_DAYS   99999 #指定密码保持有效最大天数
PASS_MIN_DAYS   0   #表示自从上次修改密码以来多少天后用户才被允许修改密码 
PASS_MIN_LEN    5   #指定密码最小长度
PASS_WARN_AGE   7   #密码到期前多少天系统警告用户密码即将到期

UID_MIN                  1000   #UID最小为1000
UID_MAX                 60000   #最大UID为60000

SYS_UID_MIN               201   #系统用户UID最小为201
SYS_UID_MAX               999   #系统用户UID最大为999

CREATE_HOME     yes     #是否创建用户主目录

UMASK           077     #系统的UMASK码

USERGROUPS_ENAB yes     #是否为用户创建与之同名的用户组

ENCRYPT_METHOD SHA512   #系统加密算法
```

##### 主目录配置文件(/etc/skel目录下）

在创建一个新用户后，会在新用户的主目录下看到类似.bash_profile, .bashrc, .bash_logout等文件，这些文件是怎么来的呢，如果我想让新建立的用户在主目录下默认拥有自己指定的配置文件，该如何设置呢？
/etc/skel目录就是解决这个问题的，/etc/skel目录定义了新建用户在主目录下默认的配置文件，更改/etc/skel目录下的内容就可以改变新建用户默认主目录的配置文件信息。


-------


#### 用户和组管理命令

##### 用户管理命令：

**添加新的账号使用useradd命令**

其语法如下：
>   useradd [OPTIONS] LOGIN
>   useradd    选项   用户名

其中各选项以及含义如下：
			
		-u UID：指定用户的UID
		-o：不检查UID的唯一性
		-g GID：指定GID，也可以使用组名来指定
		-c COMMENT：指定用户的注释信息
		-d HOME_DIR：以指定的路径为用户的家目录，默认在/home下创建
		-s SHELL：指明用户使用的shell
		-G GROUP1[,GROUP2,…]：为用户指明附加组，组需实现存在
		-r：创建系统用户
		-M：不创建用户的家目录
		-m：默认选项，创建用户的家目录
		

实例1

```
# useradd -d /usr/maxie -s /bin/csh maxie
```
此命令创建了一个用户`maxie`，其中`-d`选项为用户指定其家目录位置，`-s`选项指定用户使用的默认shell为csh。

实例2

```
# useradd -u 1006 -g insieme -G root,maxie cloud
```
此命令创建了一个用户`cloud`，其中`-u`选项是指定用户的UID，`-g`选项指定用户的主组为insime，`-G`选项为用户指明其附加组

**修改用户属性使用usermod命令**

使用usermod命令可以修改账号的相关属性，比如：用户UID、家目录、用户主组、登录shell登录shell等等。

其语法如下：
> usermod [OPTIONS] LOGIN
> usermod  选项     用户名

其中各选项以及含义如下：
            
     -c<备注>：修改用户帐号的备注文字； 
	 -d<登入目录>：修改用户的家目录； 
	 -e<有效期限>：修改帐号的有效期限； 
	 -f<缓冲天数>：修改在密码过期后多少天即关闭该帐号； 
	 -g<群组>：修改用户所属的群组； 
	 -G<群组>：修改用户所属的附加群组； 
	 -l<帐号名称>：修改用户帐号名称； 
	 -L：锁定用户密码，使密码无效；直接修改/etc/shaodw文件，在密码前加!号即可
	 -s：修改用户登入后所使用的shell； 
	 -u：修改用户ID； 
	 -U：解除密码锁定。

实例

```
# usermod -s /bin/zsh -l maxiecloud -g cloud maxie
```
此命令将用户`maxie`的登录shell改为zsh，用户名改为maxiecloud，主组改为cloud组。

**删除用户使用userdel命令**

如果一个账号不再使用，可以从系统中删除，必要时还要删除用户的家目录。

其语法格式如下：

> userdel [OPTIONS] LOGIN
> userdel 选项      用户名

常用选项：

-r：删除用户的同时，删除用户的家目录

实例

```
# userdel -r maxiecloud
```
此命令删除了`maxiecloud`用户以及其家目录。


**修改用户密码使用passwd命令**

用户账号刚创建时没有密码，但是被系统锁定，无法使用，必须为其制定密码后才能登陆系统。

其语法格式如下：
> passwd [OPTIONS] LOGIN
> passwd 选项       用户名


其中各选项以及含义如下：

     --stdin：从标准输入接收用户密码
     -l:锁定指定用户
	 -u:解锁指定用户
	 -e:强制用户下次登录修改密码
	 -n mindays: 指定最短使用期限
	 -x maxdays： 最大使用期限
	 -w warndays： 提前多少天开始警告
	 -i inactivedays： 非活动期限
	 -d：使账户无口令（密码）
	 
实例1

```
# passwd cloud
New password:******* 
Re-enter new password:*******
```
此命令为`cloud`用户修改密码。


密码设定策略：
    1. 使用数字、大写字母、字符、数字、特殊符号组合
    2. 足够长（大于8位）
    3. 使用随机密码
    4. 定期更换（生产环境：平均2个月修改一次）

实例2

```
# passwd -d cloud
```
此命令为`cloud`用户指定空口令，下次cloud用户登录时，系统不再询问口令。


##### 用户组管理命令

每个用户都有一个用户组，系统可以对一个用户组中的所有用户进行集中管理。不同Linux 系统对用户组的规定有所不同，如Linux下的用户属于与它同名的用户组，这个用户组在创建用户时同时创建。

**增加一个新的用户组使用groupadd命令**

其语法如下：

> groupadd [OPTIONS] GROUP
> groupadd 选项       用户组


其中各选项以及含义如下：

    -g GID 指定新用户组的组标识号（GID）。
    -o 一般与-g选项同时使用，表示新用户组的GID可以与系统已有用户组的GID相同。

实例

```
# groupadd maxie
```
此命令向系统添加了一个新组maxie，新组的GID是在当前已有的最大GID号的基础上加1

**删除一个已有的用户组使用groupdel命令**

其语法如下：

> groupdel [OPTIONS] GROUP
> groupdel 选项       用户组

实例

```
# groupdel maxie
```
此命令从系统中删除组`maxie`

**修改用户组的属性使用groupmod命令**

其语法如下：

> groupmod [OPTIONS] GROUP
> groupmod 选项       用户组


其中各选项以及含义如下：

    -g GID 为用户组指定新的组标识号。
    -o 与-g选项同时使用，用户组的新GID可以与系统已有用户组的GID相同。
    -n新用户组 将用户组的名字改为新名字

实例1

```
# groupmod -g 102 maxie
```
此命令将组`maxie`的GID改为102




-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=37653063&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)



<!--author：maxie（马驰原）-->
<!--QQ：17045930-->


---
title: rpm命令使用详解
date: 2017-04-17 22:59:49
tags: [linux,rpm,package,command]
categories: Linux包管理
---

<blockquote class="blockquote-center">rpm是Red Hat公司在1995年引入的Linux包管理器
在后来被其他Linux发行版所广泛引用，所以rpm也被称为RPM is Package Manager.
</blockquote>

rpm命令选项分为三组：

* 用于查询和检查包
* 用于安装、升级和删除包
* 用于执行其他功能

还应该注意 `rpm` 是操作 `RPM` 的主要命令，而 `.rpm` 是 `RPM` 文件使用的扩展名。所以 "一个rpm" 或 “某某rpm” 一般是指 RPM文件，而 `rpm` 通常指命令。

<!-- more -->

{% note primary %}## 本次的实验环境
{% endnote %}

![](http://ww3.sinaimg.cn/large/006tNc79ly1feqk0g4j0dj31ac07mq5j.jpg)


## 程序包管理器

不同的发行版，也有不同的包管理器，虽然RedHat发行的 `rpm`包管理器是公认的包管理器，但是也不全是所有发行版都使用的是其包管理器。

> Debian发行版： `dpkg`包管理器，`.deb`文件
> RedHat发行版： `rpm`包管理器, `.rpm`文件
> S.u.S.E发行版： `rpm`包管理器, `.rpm`文件
> Genntoo发行版： `ports`包管理器

## 包概念简介

### rpm包命名方式

`rpm`的包一般都是以 `Name-Version-release.arch.rpm` 的格式呈现在目录中的。


```bash
Name            --包名
VERSION         --版本号,一般是 major.minor.release的格式
release         --编译版本号
arch            --CPU架构,常见的有 i386,i686,x86_64
```

我们可以使用一条命令查看 `CentOS`系统光盘自带的`Packages`中有几种类型的`rpm`包。

```bash
$ grep -o "\<[^.]\+\>.rpm$" | cut -d"." -f1  | sort | uniq -c
   2072 i686
   3044 noarch
   4247 x86_64
```

其中：

* i686：32位CPU架构
* x86_64：64位CPU架构
* noarch：无关硬件架构，任何架构的CPU都可以安装


在这些包中还有主包和子包的区分：

```bash
Application-VERSION-ARCH.rpm        --主包
Application-devle-VERSION-ARCH.rpm  --开发子包
Application-utils-VERSION-ARCH.rpm  --工具子包
Application-libs-VERSION-ARCH.rpm   --依赖库子包
```

需要注意的一点是：

* `rpm`包与包可能存在依赖关系，甚至循环依赖，处理好这些依赖关系是学好`rpm`命令的重点。


-------

### 包管理器

程序包管理器的功能：

    将编译好的应用程序的各组成文件打包成一个或几个程序包文件，从而方便快捷的实现程序包的安装、卸载、升级和校验等管理操作。

`rpm`包文件的组成：

```bash
RPM包内的文件
RPM的元数据、名称、版本、依赖性、描述等
安装rpm包时运行的脚本
```

`rpm`数据库：

一般存放在/var/lib/rpm目录下

存放以下这些文件：
```bash
程序包名称以及版本
依赖关系
功能说明
包安装后生成的各文件路径以及校验码信息
```

-------

### 程序包的来源

获取程序包的途径：

1. 系统发行版的光盘或官方的服务器
https://www.centos.org/download
http://mirrors.aliyun.com
http://mirrors.163.com

2. 项目的官方站点
http://httpd.apache.org/download.cgi#apache24
http://nginx.org/en/download.html

3. 第三方组织：Fedora-EPEL
https://dl.fedoraproject.org/pub/epel/

RPMforge：RHEL推荐使用

或者使用专用搜索引擎
http://pkgs.org
http://rpmfind.net
http://rpm.pbone.net
http://sourceforge.net

 
*注意：*第三方包建议要检查其合法性（来源合法性以及程序包的完整性）


-------

## rpm包管理

我们可以使用 `rpm`命令对包进行安装、升级、卸载、查询、校验以及数据库维护等操作。

{% note success %}### 安装rpm包
{% endnote %}

`rpm {-i|--install} [install-options] PACKAGE_FILE …
`

安装时常用的选项：

```bash
-v          verbose，显示安装时的详细信息
-h          hash，以50个hash标记，也就是#号的形式显示安装程序包的执行进度条
```

常用格式为：
`rpm -ivh PACKAGE_FILE`

注意这里是`PACKAGE_FILE`，是需要包的全名，例如`tree-1.6.0-10.el7.x86_64.rpm`


常用长选项有：

```bash
--test              测试安装，但不真正执行安装，即dry run模式
--nodeps            忽略依赖关系
--replacepkgs | replacefiles（只覆盖某个重复的文件）
--nosignature       不检查来源合法性
--nodigest          不检查包完整性
--noscripts         不执行程序包脚本
	%pre：安装前脚本；--nopre 不执行安装前的脚本
	%post：安装后脚本；--nopost
	%preun：卸载前脚本；--nopreun
	%postun：卸载后脚本；--nopostun
```

实例：

![](http://ww2.sinaimg.cn/large/006tNc79ly1feql1v03u5j318k06m40z.jpg)


{% note info %}### 升级rpm包
{% endnote %}


```bash
rpm {-U|--upgrade} [install-options] PACKAGE_FILE ...
rpm {-F|--freshen} [install-options] PACKAGE_FILE …
```

其中`U`选项表示：
    upgrade：安装时，如果有旧版程序包，则“升级”；如果不存在旧版程序包，则“安装”
    
其中`F`选项表示：
    fresh：安装时，如果有旧版程序包，则“升级”；如果不存在旧版程序包，则“不执行任何操作”
    
常用格式：

```bash
rpm -Uvh PACKAGE_FILE…
rpm -Fvh PACKAGE_FILE…
```

长选项：

```bash
--oldpackage        降级安装
--force             强制安装
```

对内核升级：
内核的升级比较特殊，因为在生产环境中基本不会对内核升级。而Linux提供了一个很方便的东西，那就是允许多内核并存。
这样我们无需"真正的升级"，而是安装另一个新的内核即可。

```bash
rpm -ivh kernel-3.10.0-514.el7.x86_64.rpm
```

实例：

![](http://ww4.sinaimg.cn/large/006tNc79ly1feqlmvvbjjj318g07k410.jpg)


这个实例是在`centos7.2`上强制完成的，升级内核的操作十分危险，建议没有特殊需求，不要对内核进行升级！！！

{% note danger %}### 查询rpm包
{% endnote %}

使用查询命令，我们可以知道某个`rpm`包中有什么信息，以及可以查看我们已经安装了那些`rpm`包

`rpm {-q|--query} [select-options] [query-options]`

常用选项：

```bash
-a                  所有包
-f                  查看指定的文件由哪个程序包安装生成
-p PACKAGE_FILE     针对尚未安装的程序包文件做查询操作；配合 -l 选项一起使用
-l                  查看已安装的包包含哪些文件；
--changelog         查询rpm包的修改日志
-c                  查询程序的配置文件
-d                  查询程序的文档
-i                  查询程序的信息information（已安装的程序包）
--provides          列出指定程序包所提供的CAPBILITY
--whatprovides CAPBILITY    查询指定的CAPBILITY由那个包提供
--whatrequires CAPBILITY    查询指定的CAPBILITY被哪个包所依赖
--scripts           程序包自带的脚本
-R                  查询指定的程序包所依赖的CAPBILITY
```

*注意：*

当删除了一个程序的/usr/bin/下的执行文件之后，还是可以通过 `rpm -qf` 查询到，这是因为在安装这个包时，会在`rpm`数据中保存信息。


**实例：**

![](http://ww2.sinaimg.cn/large/006tNc79ly1feqm5y3auij319e0u0tgx.jpg)

{% note warning %}### 校验rpm包
{% endnote %}

`rpm {-V|--verify} [select-options] [verify-options]`

校验时是，比对`rpm`数据库中的信息与当前的信息是否一致
如果被修改过，不管是否再修改回去，都是会提示的。

提示信息详解：

```bash
S file Size differs                     文件大小被修改
M Mode differs (includes permissions and file type)         权限被修改
5 digest (formerly MD5 sum) differs     MD5被修改，内容改变（内容被修改，就会提示）
D Device major/minor number mismatch    主次设备号不匹配
L readLink(2) path mismatch：           readlink路径不匹配
U User ownership differs                属主修改
G Group ownership differs               属组修改
T mTime differs                         时间戳修改（最近修改时间）
P caPabilities differ                   caPabilitie被修改
```

常用选项：

```bash
-V          检查已安装的软件名称
-K          手动检测完整性，以及Key的信息
--nofiles   不检查
-Va         检查所有包
-f          检查某个文件的完整性
-p          检查某个rpm文件的档名
```

**包来源合法性验证以及完整性验证**：
    完整性验证：SHA256
    来源合法性验证：RSA
    
![RPM包制作数字签名过程](http://ww4.sinaimg.cn/large/006tNc79ly1feqnex09ckj30jj0dj77r.jpg)

![RPM包数字签名验证过程](http://ww4.sinaimg.cn/large/006tNc79ly1feqnexswksj30to0kwq5q.jpg)
    

**公钥加密**：
    对称加密：加密、解密使用同一密钥
    非对称加密：密钥是对儿的
        public key：公钥，公开给所有人
        secret key：私钥，不能公开


**导入所需要的公钥**：

```bash
$ rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
$ rpm -qa "gpg-pubkey*"
gpg-pubkey-f4a80eb5-53a7ff4b
```

导入key后，我们再安装包时就不会提示警告没有key的信息啦！

**卸载key**

```bash
$ rpm -qa "gpg-pubkey*"
gpg-pubkey-f4a80eb5-53a7ff4b
$ rpm -e gpg-pubkey-f4a80eb5-53a7ff4b
```

**实例：**

![](http://ww1.sinaimg.cn/large/006tNc79ly1feqn8dae1yj318i09kmzn.jpg)

我们在README文件中添加一个空行，导致文件被修改。

{% note default %}### 卸载rpm包
{% endnote %}

`rpm {-e|--erase} [--allmatches] [--nodeps] [--noscripts] [--test] PACKAGE_NAME ...
`

常用选项：

```bash
--allmatch      卸载所有匹配指定名称的程序包的各版本
--nodeps        忽略依赖关系
--test          卸载测试，dry run模式
```

**实例：**

![](http://ww3.sinaimg.cn/large/006tNc79ly1feqncs4b5ij318g03cwf5.jpg)


{% note primary %}### RPM数据库
{% endnote %}

`rpm`数据库的位置一般在：`/var/lib/rpm/`目录下

`rpm {--initdb | --rebuilddb}`

--initdb：初始化数据库
    如果事先不存在数据库，则新建之
    否则，不执行任何操作

--rebuilddb：重新构建，通过读取当前系统上所有已经安装过的程序包进行创建

--dbpath：指定初始化数据库的位置, --dbpath=/PATH/TO/


恢复 RPM Database 前，一定先将原有数据进行备份，然后再使用恢复命令！
通常，恢复方法有下面三种：

1. 只移除 `/var/lib/rpm/__db*` 文件，然后执行 `rpm --rebuilddb`命令
2. 当上面的方法没能恢复数据库时，转移 `/var/lib/rpm` 文件夹，然后执行 `rpm --rebuilddb`命令
3. 当前面两个方法都没奏效时，则表示情况比较严重，需要重新创建 RPM 数据库，再进行重建数据库操作。首先，选择一个目录创建新的数据库，执行 `rpm --initdb --dbpath new_db_path`然后，执行重构数据库命令：`rpm --rebuilddb`


查看数据库文件：

![](http://ww3.sinaimg.cn/large/006tNc79ly1feqnls5z6sj318g0i2aj6.jpg)


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=433018366&auto=0&height=66"></iframe>

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。


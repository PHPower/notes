---
title: 自动化运维工具puppet简介(1)
date: 2017-07-22 15:54:03
tags: [linux,puppet,运维技术]
categories: [puppet,运维技术]
copyright: true
---

![](https://ws3.sinaimg.cn/large/006tNc79ly1fhspzejvf0j308m04j3yb.jpg)

> puppet是一个IT基础设施自动化管理工具，它能够帮助系统管理员管理基础设施的整个生命周期：
> 供应(provisioning)、配置(configuration)、联动(orcherstraion)及报告(reporting)
> 基于puppet，可实现自动化重复任务、快速部署关键性应用以及在本地或云端完成主动管理变更


**puppet主要使用的场景：**

```bash
1. 初始化配置：initialize configuration
2. 审计：fixex 、updates、audits
```

**puppet的三层模型：**

```bash
configuration language      配置语言，能描述资源、依赖关系的语言，进行输出
transaction layer           描述资源的依赖关系
resource abstraction layer  资源层
```

**puppet运行时的两种模型：**


```bash
standalone      单机模型；手动应用资源清单
master/agent    主从模型；由agent周期性地向master请求清单并自动应用于本地
```

-------

<!-- more -->


### puppet的"资源"

资源抽象的纬度：

* 类型：具有类似属性的组件，例如package，service，file
* 将资源的属性或状态与其实现方式分离
* 仅描述资源的目标状态，也即期望其实现的结果状态，而不是具体过程


#### 查看资源类型

`puppet descrbe`命令：查看资源类型

```bash
puppet describe [-h|--help] [-s|--short] [-p|--providers] [-l|--list] [-m|--meta] [type]
	-l：列出所有资源类型；
	-s：显示指定类型的简要帮助信息；
	-m：显示指定类型的元参数，一般与-s一同使用；
```

#### 资源定义

向资源类型的属性复制来实现，可称为资源类型实例化

定义了资源实例的文件即清单，`manifest`

**一个清单，可以定义多个资源；资源清单支持幂等性，但是资源内的执行的内容可能不是幂等性，需要手动写入规则**

* 定义资源的语法

```puppet
type{'title':
    attribute1  => value1,
    attribute2  => value2,
    ...
}
```

**注意：type必须使用小写字符；title是一个字符串，在同一类型中必须唯一**

#### 资源类型中的特殊属性


```bash
Namevar     简称为name，通常也是使用name
ensure      资源的目标状态
providers   指明资源的管理接口
```


#### 资源类型

查看指定类型的帮助：
`$ puppet describe TYPE`

* group：管理组类型

```bash
属性：

name        组名
gid         GID组ID
ensure      目标的状态 	--> 创建系统组时必须给定此参数
	absent：删除
	present：创建
system      是否为系统组，true or false
members     成员用户
```

* user：管理用户

```bash
属性：

name        用户名
uid         UID
gid         基本组GID组ID  --> 这里的基本组，必须事先存在，否则会报错
groups      附加组，不能包含基本组
comment     注释
expiry      过期时间
home        家目录
shell       默认shell类型
system      是否为系统组，true or false
ensure      目标的状态 absent/present
```

* package：定义包管理属性

```bash
ensure：目标的状态
	present：相当于installed 安装，并且为安装最新版
	absent：不安装
	latest：安装最新版

name：包名
	不同版本linux的包名可能也不一样，需要进判断

source：程序包来源，仅对不会自动下载相关程序包的provider有用，例如rpm或者dpkg
```

示例：安装jdk

```bash
$ wget jdk....
$ vim jdk.pp 
package{'jdk':
	ensure 	=> installed,
	source 	=> '/root/jdk-7u79-linux-x64.rpm',
	provider => rpm,
}

# 测试安装
$ puppet apply --verbose --debug --noop jdk.pp
# 安装
$ puppet apply --verbose --debug jdk.pp
```


* service：服务相关的配置

```bash
属性：

ensure      stopped、running 或者 false、true
enable      是否开机自启，true 、 false、 manual(手动启动)
name        服务名
path        脚本搜索路径，默认为/etc/init.d，centos7应为 /usr/lib/systemd/system
hasrestart  命令是否有restart命令，如果没有，则使用stop，然后start
hasstatus   探测服务状态。
restart     自定义restart命令。通常用于自定义为reload。防止服务重启导致服务不可用
start       手动定义启动命令
stop        手动定义停止命令
status      手动定义启动命令
binary      定义程序的文件路径 --> 没有Unit File的程序，需要指定这项
```

示例：定义redis服务

```bash
$ vim rediservice.pp
package{'redis':
	ensure 	=> present,
}

service{'redis':
	ensure 	=>	running,
	enable 	=> 	true,
	require =>	Package['redis'],
}
```

* file：文件相关配置

```bash
ensure      确保文件存在
	file：普通文件，其内容
	directory：目录，可通过soure，递归复制 
path        文件路径
source      源文件
content     文件内容
target      符号链接的目标文件
owner       属主
group       属组
mode        权限
	rwx , 777都可以定义
atime/ctime/mtime：时间戳

-> ：表示此资源必须要在下一个资源之前执行
~> ：表示此资源如果变化了，则通知下一个资源，进行fresh刷写操作
```

示例：

```
示例1：

$ cp /etc/redis.conf /root/
$ sed -i 's@127.0.0.1@172.16.1.100@g' redis.conf 
$ vim file.pp
file{'/etc/redis.conf':
	ensure 	=> file,
	source  => '/root/redis.conf',
	owner 	=> 'redis',
	group 	=> 'root',
	mode 	=> '0644',
}
$ puppet apply --verbose --debug --noop file.pp
$ puppet apply --verbose --debug file.pp

'根据文件的md5值，判断是否一样，一样则不复制'


示例2：自定义文件内容
file{'/tmp/test.txt':
	ensure 	=> file,
	content => 'Hello World.',
}


示例3：创建链接文件
file{'/tmp/test.txt.link':
	ensure => link,
	source => '/etc/fstab',
}


示例4：创建目录
file{'/tmp/pam.d':
	ensure 	=> directory
	source => '/etc/pam.d',
	recurse => true,
}
```

* exec：执行外部命令

```bash
command     运行的命令
	cwd：要切换至哪个目录下，进行'运行命令'
creates     文件路径，仅此路径表示的文件不存在时，command方才执行
user/group  运行命令的用户身份
path        类似于linux中$PATH功能
onlyif      此属性指定一个命令，此命令正常(退出码为0)运行时，当前command才会运行
unless      此属性指定一个命令，此命令非正常(退出码为非0)运行时，当前command才会运行
refresh     重新执行当前command的替代命令
refreshonly 仅接受到订阅的通知，才进行刷新
```

示例：

```puppet
exec{'mkdir':
	command 	=> 'mkdir /tmp/testdir',
	path 		=> '/bin:/sbin/:/usr/bin:/usr/sbin',
	creates 	=> '/tmp/testdir',
}
```


* cron：计划任务

```puppet
command     要执行的任务；
ensure      present/absent；
hour        小时
minute      分钟
monthday    月日
month       月
weekday     周
user        以哪个用户的身份运行命令
target      添加为哪个用户的任务
name        cron job的名称
```

示例：

```puppet
cron{'timesync':
	command => '/usr/sbin/ntpdate 10.1.0.1 &> /dev/null',
	ensure  => present,
	minute  => '*/3',
	user    => 'root',
}	
```

* notify：发送通知

```puppet
message     信息内容
name        信息名称
```


#### 元参数

* 依赖关系 before/require

```bash
A before B：B依赖于A，定义在A资源中
	{
		...
		before => Type['B'],
		...
	}

B require A：B依赖于A，定义在B资源中
	{
		...
		require => Type['A']
		...
	}
```


* 通知关系 notify/subscribe

```puppet
'notify：通知'
	A notify B：B依赖于A，且A发生变化后会通知B;
		{
			。。。
			notify => Type['B']
		}

'subscribe：订阅'
	B subscribe A：B依赖于A，且B监控A资源的变化产生的事件
		{
			...
			subscribe => Type['A'],
			...
		}
```


* 通知元参数

A notify B：B依赖于A，接受由A触发refresh；
B subscribe A：B依赖于A，接受由A触发refresh；


示例：

```puppet
example1：

file{'test.txt':
	path    => '/tmp/test.txt',
	ensure  => file,
	source  => '/etc/fstab',
}

file{'test.symlink':
	path    => '/tmp/test.symlink',
	ensure  => link,
	target  => '/tmp/test.txt',
	require => File['test.txt'],
}

file{'test.dir':
	path    => '/tmp/test.dir',
	ensure  => directory,
	source  => '/etc/yum.repos.d/',
	recurse => true,
}



example2：链式依赖
service{'httpd':
	ensure  => running,
	enable  => true,
	restart => 'systemctl restart httpd.service',
#       subscribe       => File['httpd.conf'],
}

package{'httpd':
	ensure  => installed,
}

file{'httpd.conf':
	path    => '/etc/httpd/conf/httpd.conf',
	source  => '/root/manifests/httpd.conf',
	ensure  => file,
	notify  => Service['httpd'],
}

# 链式依赖配置
Package['httpd'] -> File['httpd.conf'] -> Service['httpd']	
```

-------


### puppet变量

定义变量：
`$variable_name = value`

puppet的变量名称必须以"$"符号开头('无论赋值还是调用')，赋值操作符为"="号

#### 数据类型

```bash
字符型     引号可有可无；但单引号为强引用，双引号为弱引用
数值型     默认均识别为字符串，仅在数值上下文才以数值对待
数组       []中以逗号分隔元素列表
布尔型值    true, false；不能加引号
hash       {}中以逗号分隔k/v数据列表； 键为字符型，值为任意puppet支持的类型；{ 'mon' => 'Monday', 'tue' => 'Tuesday', }
undef      未定义 
```

#### 正则表达式


```puppet
(?<ENABLED OPTION>:<PATTERN>)
(?-<DISABLED OPTION>:<PATTERN>)
```

OPTIONS：

```puppet
i       忽略字符大小写；
m       把.号当换行符；
x       忽略<PATTERN>中的空白字符
```


#### puppet内建变量

打印当前系统所有的变量
`$ facter -p`

* 内建变量分类：

```bash
master端变量 
agent端变量 
parser变量
```

#### 变量作用域 Scope


```puppet
top scope       $::var_name
node scope      $node::var_name
class scope     $class::var_name
```


-------

### puppet流程控制语句

#### if语句

语法格式：

```puppet
if  CONDITION {
	...
} else {
	...
}
```


* CONDITION的给定方式：

    (1) 变量
    (2) 比较表达式 
    (3) 有返回值的函数
	
	
```bash
	if $osfamily =~ /(?i-mx:debian)/ {
		$webserver = 'apache2'
	} else {
		$webserver = 'httpd'
	}

	package{"$webserver":
		ensure  => installed,
		before  => [ File['httpd.conf'], Service['httpd'] ],
	}

	file{'httpd.conf':
		path    => '/etc/httpd/conf/httpd.conf',
		source  => '/root/manifests/httpd.conf',
		ensure  => file,
	}

	service{'httpd':
		ensure  => running,
		enable  => true,
		restart => 'systemctl restart httpd.service',
		subscribe => File['httpd.conf'],
	}		
```

#### case语句

语法格式：

```puppet
case CONTROL_EXPRESSION {
	case1: { ... }
	case2: { ... }
	case3: { ... }
	...
	default: { ... }
}
```

* CONTROL_EXPRESSION:
					
    (1) 变量
    (2) 表达式 
    (3) 有返回值的函数


* 各case的给定方式

    (1) 直接字串；
    (2) 变量 
    (3) 有返回值的函数
    (4) 正则表达式模式；
    (5) default 
    
* 示例

```puppet
case $osfamily {
	"RedHat": { $webserver='httpd' }
	/(?i-mx:debian)/: { $webserver='apache2' }
	default: { $webserver='httpd' }
}

package{"$webserver":
	ensure  => installed,
	before  => [ File['httpd.conf'], Service['httpd'] ],
}

file{'httpd.conf':
	path    => '/etc/httpd/conf/httpd.conf',
	source  => '/root/manifests/httpd.conf',
	ensure  => file,
}

service{'httpd':
	ensure  => running,
	enable  => true,
	restart => 'systemctl restart httpd.service',
	subscribe => File['httpd.conf'],
}	
```

#### selector语句

语法：

```bash
CONTROL_VARIABLE ? {
	case1 => value1,
	case2 => value2,
	...
	default => valueN,
}
```

* CONTROL_VARIABLE的给定方法：

```bash
(1) 变量
(2) 有返回值的函数
```

* 各case的给定方式


```bash
(1) 直接字串；
(2) 变量 
(3) 有返回值的函数
(4) 正则表达式模式；
(5) default 
```

注意：不能使用列表格式；但可以是其它的selector

* 示例

```puppet
示例1：
$pkgname = $operatingsystem ? {
	/(?i-mx:(ubuntu|debian))/       => 'apache2',
	/(?i-mx:(redhat|fedora|centos))/        => 'httpd',
	default => 'httpd',
}

package{"$pkgname":
	ensure  => installed,
}			



示例2：
$webserver = $osfamily ? {
	"Redhat" => 'httpd',
	/(?i-mx:debian)/ => 'apache2',
	default => 'httpd',
}


package{"$webserver":
	ensure  => installed,
	before  => [ File['httpd.conf'], Service['httpd'] ],
}

file{'httpd.conf':
	path    => '/etc/httpd/conf/httpd.conf',
	source  => '/root/manifests/httpd.conf',
	ensure  => file,
}

service{'httpd':
	ensure  => running,
	enable  => true,
	restart => 'systemctl restart httpd.service',
	subscribe => File['httpd.conf'],
}	


示例3：
$ vim create.pp
$username = 'fdfs'

group{"$username":
	ensure 	=> present,
	system 	=> true,
} ->

user{"$username":
	ensure => present,
	gid    => "$username",
}

$ puppet apply -v -d create.pp
```



-------

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)









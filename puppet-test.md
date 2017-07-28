---
title: 自动化运维工具puppet基础功能练习
date: 2017-07-22 17:17:53
tags: [puppet,运维技术]
categories: [puppet,运维技术]
copyright: true
---

>上一章，我们学习了`puppet`的基本使用方法，下面我们就做一些练习吧。


### 环境准备

由于我们这次练习是在`standalone`模式下，所以只需要一台虚拟机即可满足


* 虚拟机环境

```bash
$ lsb_release -a
LSB Version:	:core-4.1-amd64:core-4.1-noarch:cxx-4.1-amd64:cxx-4.1-noarch:desktop-4.1-amd64:desktop-4.1-noarch:languages-4.1-amd64:languages-4.1-noarch:printing-4.1-amd64:printing-4.1-noarch
Distributor ID:	CentOS
Description:	CentOS Linux release 7.2.1511 (Core)
Release:	7.2.1511
Codename:	Core
```

* 需要安装的软件包

```bash
facter-2.4.6-1.el7.x86_64.rpm
puppet-3.8.7-1.el7.noarch.rpm
```

下载软件包链接：[puppet](https://www.dropbox.com/s/8ofkk2huwe8xhuh/puppet-3.8.7-1.el7.noarch.rpm?dl=0)、[facter](https://www.dropbox.com/s/mwmteh7g143mt5l/facter-2.4.6-1.el7.x86_64.rpm?dl=0)


<!-- more -->

-------

### 基本练习

准备工作：

```bash
$ cd ~
$ mkdir manifests
$ cd manifests
```

#### 创建一个nginx组

```puppet
$ vim nginx.pp
group{'nginx':
        name    => 'nginx',
        ensure  => present,
        system  => true,
}

$ puppet apply -d -v nginx.pp
```

#### 创建redis用户和组

```puppet
$ vim redis.pp
user{'redis':
        name    => 'redis',
        ensure  => present,
        system  => true,
        require => Group['redis'],
}

group{'redis':
        name    => 'redis',
        ensure  => present,
        system  => true,
}

$ puppet apply -d -v --noop redis.pp
$ puppet apply -d -v redis.pp
```

#### 安装一个redis程序包，使用本地安装包

```puppet
$ wget ftp://172.16.0.1/pub/Sources/7.x86_64/redis/redis-3.2.3-1.el7.x86_64.rpm
或者
$ wget http://dl.fedoraproject.org/pub/epel/7/x86_64/r/redis-3.2.3-1.el7.x86_64.rpm

$ vim package.pp
package{'redis':
        ensure  => installed,
        source  => '/root/manifests/redis-3.2.3-1.el7.x86_64.rpm',
        provider        => yum,
}
```

#### 启动redis服务，并设置开机自启

```puppet
$ vim service.pp
service{'redis':
	ensure	=> running,
	enable	=> true,
}
```

#### 安装一个nginx，并启动服务，设置开机自启

```puppet
$ vim nginx.pp
package{'nginx':
    ensure  => installed,
}

service{'nginx':
        ensure  => running,
        enable  => true,
        require => Package['nginx'],
}
```

#### 修改nginx的配置文件为我们自定义的的配置

```puppet
$ vim file.pp
file{'nginx':
        ensure  =>      file,
        path    =>      '/etc/nginx/nginx.conf',
        source  =>      '/root/manifests/nginx.conf',
        owner   =>      'nginx',
        group   =>      'root',
        mode    =>      0644,
}
```

#### 配置文件修改后，通知给service

```puppet
$ vim service2.pp
package{'nginx':
        ensure  => installed,
}

file{'nginx':
        path    => '/etc/nginx/nginx.conf',
        source  => '/root/manifests/nginx.conf',
        ensure  => file,
        require => Package['nginx'],
}

service{'nginx':
        ensure  => running,
        enable  => true,
        require => Package['nginx'],
        subscribe       => File['nginx'],
}

$ vim nginx.conf 
server {
    listen       8080 default_server;
    listen       [::]:80 default_server;
    server_name  _;
    root         /usr/share/nginx/html;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;

    location / {
            proxy_pass      http://172.16.1.70:80;
    }

    location ~* \.(jpg|jpeg|png|gif) {
            proxy_pass      http://172.16.1.30:80;
    }
}

$ puppet apply -d -v --noop service2.pp
$ puppet apply -d -v service2.pp

$ ss -tnl
```

#### 配置链式依赖

-> ：表示此资源必须要在下一个资源之前执行
~> ：表示此资源如果变化了，则通知下一个资源，进行fresh刷写操作


```puppet
$ vim service2.pp
package{'nginx':
        ensure  => installed,
} ->	#表示package资源要先于file资源执行


file{'nginx':
        path    => '/etc/nginx/nginx.conf',
        source  => '/root/manifests/nginx.conf',
        ensure  => file,
} ~>	# 表示file资源如果变化，则通知service资源进行刷写fresh操作

service{'nginx':
        ensure  => running,
        enable  => true,
}


或者使用此配置，功能相同

package{'nginx':
    ensure  => installed,
}

file{'nginx':
        path    => '/etc/nginx/nginx.conf',
        source  => '/root/manifests/nginx.conf',
        ensure  => file,
}

service{'nginx':
        ensure  => running,
        enable  => true,
}

Package['nginx'] -> File['nginx'] ~> Service['nginx']


$ puppet apply -d -v --noop service2.pp
$ puppet apply -d -v service2.pp
```


#### 复制目录

```puppet
$ vim dir.pp
file{'/tmp/pam.d':
		# 指明为目录
        ensure  => directory,
        source  => '/etc/pam.d',
        # 递归复制
        recurse => true,
}

$ puppet apply -d -v --noop dir.pp
$ puppet apply -d -v dir.pp
```

#### 创建目录

```puppet
$ vim exec1.pp
exec{'/usr/bin/mkdir':
        command => 'mkdir /tmp/testdir',
        path    => '/usr/bin',
        # 如果目录存在，则不执行创建操作
        creates => '/tmp/testdir',
}
```

#### 创建用户，只有当程序包安装了，才会创建

```puppet
$ vim exec2.pp
package{'mogilefs':
        ensure  => latest,
        provider        => yum,
}

exec{'adduser':
        command => 'useradd -r mogilefs',
        path    => '/usr/sbin/:/usr/bin/:/bin:/sbin',
        unless  => 'id mogilefs',
        refreshonly     => true,
        subscribe       => Package['mogilefs'],
}
```

#### 创建定时任务

```puppet
$ vim cron.pp
cron{'timesync':
        command => '/usr/bin/ntpdate 172.16.0.1 &> /dev/null',
        ensure  => present,
        minute  => '*/3',
        user    => 'root',
}

$ puppet apply -d -v cron.pp
$ crontab -l
# HEADER: This file was autogenerated at 2017-07-19 21:37:24 +0800 by puppet.
# HEADER: While it can still be managed manually, it is definitely not recommended.
# HEADER: Note particularly that the comments starting with 'Puppet Name' should
# HEADER: not be deleted, as doing so could cause duplicate cron jobs.
# Puppet Name: timesync
*/3 * * * * /usr/bin/ntpdate 172.16.0.1 &> /dev/null


# 删除定时任务
$ vim cron.pp
cron{'timesync':
        command => '/usr/bin/ntpdate 172.16.0.1 &> /dev/null',
        # 删除
        ensure  => absent,
        minute  => '*/3',
        user    => 'root',
}

$ puppet apply -d -v cron.pp
```


#### 定义通知脚本

```puppet
$ vim notify.pp
notify{'sayhi':
    message => 'how old r u ?',
    name    => 'hi',
}

$ puppet apply notify.pp
```


-------


### 进阶练习

#### 使用变量创建一个用户和组

```puppet
$ vim var.pp
$username = 'maxie'

group{"$username":
        ensure  => present,
        system  => true,
} ->

user{"$username":
        ensure  => present,
        gid     => "$username",
}

$ puppet apply -d -v var.pp


# 删除用户和组
$username = 'maxie'

group{"$username":
        ensure  => absent,
        system  => true,
        require => User[$username],
}

user{"$username":
        ensure  => absent,
        gid     => "$username",
}

$ puppet apply -d -v var.pp
```

#### 使用case定义一个变量，并根据某个系统变量的值，来进行赋值

```puppet
$ vim case.pp
case $operatingsystem {
        RedHat, CentOS, Fedora: { $webserver = 'httpd' }
        /(?i-mx:debian|ubuntu)/: { $webserver = 'apache2' }
        default: { $webserver = 'httpd' }
}

package{"$webserver":
        ensure  => installed,
}

$ puppet apply -d -v --noop case.pp
$ puppet apply -d -v case.pp

$ rpm -q httpd
httpd-2.4.6-40.el7.centos.x86_64
```

#### 使用selector定义一个变量，并根据某个系统变量的值，来进行赋值


```puppet
$ vim select.pp
$webserver = $opeartingsystem ? {
        /(?i-mx:ubuntu|debian)/ => 'apache2',
        /(?i-mx:redhat|centos|fedora)/ => 'httpd',
        default => 'httpd',
}

package{"$webserver":
        ensure  => present,
}

$ puppet apply -v -d --noop select.pp
$ puppet apply -v -d select.pp
```

#### 定义一个类，并引用其

```puppet
$ vim class1.pp
class nginx {
        package{'nginx':
                ensure  =>      installed,
        } ->

        file{'nginx':
                ensure  =>      file,
                path    =>      '/etc/nginx/nginx.conf',
                source  =>      '/root/manifests/nginx.conf',
                owner   =>      'root',
                group   =>      'root',
                mode    =>      0644,
        } ~>

        service{'nginx':
                ensure  =>      running,
                enable  =>      true,
        }
}

# transfer class
include nginx

$ puppet apply -d -v --noop class1.pp
$ puppet apply -d -v class1.pp
```

#### 定义一个类，引用多个变量，判断系统的类别是centos7、还是6。对MySQL进行安装

```puppet
$ vim mysql-install.pp
class dbserver($version,$server) {
	package{"$version":
		ensure	=> latest,
	} ->

	service{"$server":
		ensure	=> running,
		enable	=> true,
	}

}

if $operatingsystem == "CentOS" {
	$dbpkg = $operatingsystemmajrelease ? {
		7 => 'mariadb-server',
		default => 'mysqld-server',
	}

	$service = $operatingsystemmajrelease ? {
		7 => 'mariadb.service',
		default => 'mysqld',
	}
}

class{'dbserver':
	version => "$dbpkg",
	server	=> "$service",
}
```

#### 创建多个子类，继承父类

```puppet
$ vim nginx-install.pp
class nginx {
	package{'nginx':
		ensure	=>	installed,
	} ->

	service{'nginx':
		ensure	=>	running,
		enable	=>	true,
	}
}

class nginx::web inherits nginx{
	file{'nginx':
		ensure	=>	file,
		path	=>	'/etc/nginx/nginx.conf',
		source	=>	'/root/manifests/nginx-web.conf',
	}

	Package['nginx'] -> File['nginx'] ~> Service['nginx']
}

class nginx::webproxy inherits nginx{

}

class nginx::mysqlproxy inherits nginx{

}

include nginx::web
```

#### 在子类中覆盖父类的值，或者在子类中增加父类某个属性的值


```puppet
# 覆盖
$ vim nginx-install.pp
class nginx::webproxy inherits nginx{
        file{'nginx':
                ensure  =>      file,
                path    =>      '/etc/nginx/nginx.conf',
                source  =>      '/root/manifests/nginx-webproxy.conf',
        }

        # 覆盖父类中的Service资源的enable的值为false
        Service['nginx']{
                enable  =>      false,
        }

        Package['nginx'] -> File['nginx'] ~> Service['nginx']

}


# 新增

class nginx::webproxy inherits nginx{
        file{'nginx':
                ensure  =>      file,
                path    =>      '/etc/nginx/nginx.conf',
                source  =>      '/root/manifests/nginx-webproxy.conf',
        }

        Service['nginx']{
                enable  =>      false,
                # 新增依赖关系
                require +>      File['nginx'],
        }


}
```



-------

### 模板练习

#### 实现nginx配置文件中work_process的数量为 CPU核心数


```puppet
$ vim template.pp 
package{'nginx':
        ensure  =>      installed,
}

file{'nginx.conf':
        ensure  =>      file,
        path    =>      '/etc/nginx/nginx.conf',
        content =>      template('/root/manifests/nginx.conf.erb'),
}

$ vim nginx.conf.erb
# 只修改这一项即可
worker_processes <%= @processorcount %>;

$ puppet apply -d -v template.pp
```


#### 使用模块自带函数，使用facter获取的变量，对模板文件进行设置，并使得获取的变量进行乘法运算


```puppet
$ vim template.pp 
package{'nginx':
        ensure  =>      installed,
}

file{'nginx.conf':
        ensure  =>      file,
        path    =>      '/etc/nginx/nginx.conf',
        content =>      template('/root/manifests/nginx.conf.erb'),
}

$ vim nginx.conf.erb
# 注意这里是字符串相乘，也就是字符串相加，最后得出的数应为@processorcount@processorcount，拼接而成，如果@processorcount为1，则最后的数为11
worker_processes <%= Integer(@processorcount) * 2 %>;

$ puppet apply -d -v template.pp

$ vim /etc/nginx/nginx.conf
worker_processes 2;
```

#### 使用模板语言中对变量运算的方法，对worker进程进行加减


```puppet
$ vim nginx.conf.erb
worker_processes <%= Integer(@processorcount) + 1 %>;

$ puppet apply -d -v template.pp

$ vim /etc/nginx/nginx.conf 
worker_processes 2;
```





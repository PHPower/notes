---
title: Ansible自动化运维工具的基本使用以及部署
date: 2017-07-07 20:15:55
tags: [ansible,linux,automation]
categories: [linux进阶,ansible]
copyright: true
---

![](https://ws1.sinaimg.cn/large/006tNbRwly1fhbl91dv81j30bj03djr7.jpg)

<blockquote class="blockquote-center">Ansible在我们运维工作中的主要工作就是帮助我们批量自动化部署一些生产上的需求。
由于Ansible是用Python开发的，是一款非常轻量级的自动化部署工具。
而且Ansible是通过SSH协议来进行管理其他机器的，我们只需要在安装Ansible的主机上编写一个SSH无密钥登陆的脚本，即可实现批量管理机器的工作。
</blockquote>

其实自动化运维工具还有很多，比如`puppet`、`saltstack`、`chef`、`cfengine`，这些都可以说是`Ansible`的**前辈**了。但是为什么现在大多数运维岗位的在职人员都使用的是`Ansible`这款工具呢？
下面就来说一说它的优点：

```bash
1. Agentless：去中心化。也就是使用Ansible无需安装服务端和客户端，只需使用SSH即可。只要一台机器安装了Ansible程序，都是一台强大的管理端。
2. Stupied Simple："傻瓜般的简单"。意味着上手非常简单，学习曲线平滑
3. SSH By Default：默认通过SSH连接通信，非常安全。无需安装客户端
4. YAML No Code：使用YAML语言定制剧本 --> playbook
5. sudo：支持sudo
6. 模块化：调用特定模块，完成特定任务，支持自定义模块
7. 幂等性：同一个命令/文件 可以被执行多次
```


-------

<!-- more -->

安装epel之前需要配置epel yum源，可以使用阿里云的 `http://mirrors.aliyun.com/epel/7/x86_64/`

**拓扑图：**

![](https://ws1.sinaimg.cn/large/006tNbRwly1fhbmg4t2tgj30ge0e6wex.jpg)

{% note primary %}### Ansible的安装与配置
{% endnote %}

Ansible 1.9和2.0的区别：

```
（1） 最大区别是2.0的API调用方式发生变化，1.9原有的api调用方式在2.0不再支持
（2） 2.0增加了重要的功能： ansible-console
（3） Ansible 2.0的模块数量增加很多，500+个模块数量
```

####  <font size=3 color="#38B0DE">安装</font>

```bash
$ yum install -y ansible
$ ssh-keygen                        # 生成公钥和私钥
$ ssh-copy-id root@172.16.1.100     # 传送密钥至远程主机以及本机，实现ssh免密钥登陆
$ ssh-copy-id root@172.16.1.70
$ ssh-copy-id root@172.16.1.20
```

<br>

####  <font size=3 color="#38B0DE">Ansible配置文件</font>

配置文件路径：

```bash
/etc/ansible                所有的配置文件都在此目录下
/etc/ansible/ansible.cfg    主配置文件
/etc/ansible/hosts          仓库文件
/etc/ansible/roles          剧本文件       
```

主配置文件：

```bash
$ vim /etc/ansible/ansible.cfg
[defaults]
#inventory      = /etc/ansible/hosts        # 主机列表配置文件
#library        = /usr/share/my_modules/    # 库文件存放目录 
#remote_tmp     = $HOME/.ansible/tmp        # 生成的临时py命令文件存放在远程主机的目录
#local_tmp      = $HOME/.ansible/tmp        # 本机的临时命令执行目录
#forks          = 5                         # 默认并发数
#poll_interval  = 15                        # 默认的线程池
#sudo_user      = root                      # 默认sudo 用户
#ask_sudo_pass = True                       
#ask_pass      = True
#transport      = smart
#remote_port    = 22                        # 远程ssh端口号
#module_lang    = C
#module_set_locale = False

roles_path	   = /etc/ansible/roles          # 默认从ansible-galaxy下载路径

host_key_checking = False                   # 检查对应服务器的host_key

[privilege_escalation]
[paramiko_connection]
[ssh_connection]
[accelerate]
[selinux]
[colors]                                    # 执行命令后输出的颜色
```

<br>

####  <font size=3 color="#38B0DE">Ansible命令集</font>


```bash
/usr/bin/ansible                    # Ansible AD-Hoc 临时命令执行工具，常用于临时命令的执行
/usr/bin/ansible-doc                # Ansible 模块功能查看工具，类似于Linux中的man文档
/usr/bin/ansible-galaxy             # 从galaxy.ansible.com网站下载/上传优秀代码或者 Roles模块，基于网络；有可能需要使用到科学上网
/usr/bin/ansible-playbook           # Ansible 定制自动化的任务集编排工具
/usr/bin/ansible-pull               # Ansible 远程执行命令的工具(使用较少，海量机器时使用，对运维的架构能力要求较高)
/usr/bin/ansible-vault              # Ansible 文件加密工具
/usr/bin/ansible-console            # Ansible 基于Linux Consoble界面可与用户交互的命令执行工具
/usr/share/ansible_plugins          # Ansible 高级自定义插件目录(需要Python基础)
    action  （(可能使用较多)）
    callback (可能使用较多)
    connection
    filter
    lookup
    vars
```


<br>

####  <font size=3 color="#38B0DE">Ansible命令使用说明</font>

先看一个最简单的命令：

```bash
# 调用ping模块检测 web组内的所有主机是否存活
$ vim /etc/ansible/hosts 
[web]
172.16.1.100
172.16.1.70
172.16.1.20
172.16.4.10

$ ansible web -m ping
172.16.1.21 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
172.16.1.70 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
172.16.1.100 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

<br>

**Ansible命令使用详解：**

```bash
$ ansible -h
Usage: ansible <host-pattern> [options]

Options:
  -a MODULE_ARGS, --args=MODULE_ARGS                            #模块的参数,如果执行默认COMMAND的模块，即是命令参数,如：“date”,"pwd"等等
                        module arguments                        #模块参数

  --ask-become-pass     ask for privilege escalation password   # Ansible su切换用户的时候使用该参数输入密码

  -k, --ask-pass        ask for SSH password                    #登录密码，提示输入SSH密码而不是假设基于密钥的验证

  --ask-su-pass         ask for su password                     #su切换密码

  -K, --ask-sudo-pass   ask for sudo password                   #提示密码使用sudo,sudo表示提权操作

  --ask-vault-pass      ask for vault password                  # ansible-valut 加密文件

  -B SECONDS, --background=SECONDS                              #后台运行超时时间
                        run asynchronously, failing after X seconds
                        (default=N/A)

  -C, --check           don't make any changes; instead, try to predict some    #只是测试一下会改变什么内容，不会真正去执行;相反,试图预测一些可能发生的变化
                        of the changes that may occur

  -c CONNECTION, --connection=CONNECTION                        # 连接类型使用。可能的选项是paramiko(SSH),SSH和地方。当地主要是用于crontab或启动。
                        connection type to use (default=smart)

  -e EXTRA_VARS, --extra-vars=EXTRA_VARS                        # 调用外部变量

  -f FORKS, --forks=FORKS                                       # Ansible一次命令执行并发的线程数,默认是5
                        specify number of parallel processes to use
                        (default=5)

  -h, --help            show this help message and exit         #打开帮助文档API

  -i INVENTORY, --inventory-file=INVENTORY                      #指定库存主机文件的路径,默认为/etc/ansible/hosts
                        specify inventory host file
                        (default=/etc/ansible/hosts)

  -l SUBSET, --limit=SUBSET                                     #进一步限制所选主机/组模式  --limit=192.168.91.135 只对这个ip执行
                        further limit selected hosts to an additional pattern

  --list-hosts          outputs a list of matching hosts; does not execute
                        anything else

  -m MODULE_NAME, --module-name=MODULE_NAME                     #执行模块的名字，默认使用 command 模块，所以如果是只执行单一命令可以不用 -m参数
                        module name to execute (default=command)

  -M MODULE_PATH, --module-path=MODULE_PATH                     #要执行的模块的路径，默认为/usr/share/ansible/
                        specify path(s) to module library
                        (default=/usr/share/ansible/)

  -o, --one-line        condense output                         #压缩输出，摘要输出.尝试一切都在一行上输出。

  -P POLL_INTERVAL, --poll=POLL_INTERVAL                        #调查背景工作每隔数秒。需要- b
                        set the poll interval if using -B (default=15)

  --private-key=PRIVATE_KEY_FILE                                #私钥路径，使用这个文件来验证连接
                        use this file to authenticate the connection

  -S, --su              run operations with su    用 su 命令

  -R SU_USER, --su-user=SU_USER                                 #指定SU的用户，默认是root用户
                        run operations with su as this user (default=root)

  -s, --sudo            run operations with sudo (nopasswd)    

  -U SUDO_USER, --sudo-user=SUDO_USER                           #sudo到哪个用户，默认为 root  
                        desired sudo user (default=root)

  -T TIMEOUT, --timeout=TIMEOUT                                 #指定SSH默认超时时间，  默认是10S
                        override the SSH timeout in seconds (default=10)

  -t TREE, --tree=TREE  log output to this directory            #将日志内容保存在该输出目录,结果保存在一个文件中在每台主机上。

  -u REMOTE_USER, --user=REMOTE_USER                            #远程用户， 默认是root用户
                        connect as this user (default=root)

  --vault-password-file=VAULT_PASSWORD_FILE  
                        vault password file

  -v, --verbose         verbose mode (-vvv for more, -vvvv to enable    #详细信息
                        connection debugging)

  --version             show program's version number and exit  #输出ansible的版本
```


**主要组成部分：**

```
1. ANSIBLE PLAYBOOKS ：任务剧本（任务集），编排定义 Ansible 任务集的配置文件，由 Ansible 顺序依次执行，通常是 JSON 格式的 YML 文件；
2. INVENTORY ： Ansible 管理主机的清单；
3. MODULES ： Ansible 执行命令的功能模块，多数为内置的核心模块，也可自定义；
4. PLUGINS ：模块功能的补充，如连接类型插件、循环插件、变量插件、过滤插件等，该功能不常用。
5. API ：供第三方程序调用的应用程序编程接口
6. ANSIBLE ：该部分图中表示的不明显，组合 INVENTORY 、API 、 MODULES 、 PLUGINS 的绿框大家可以理解为是ansible 命令工具，其为核心执行工具；
```



<br>

####  <font size=3 color="#38B0DE">Ansible主机清单配置</font>

路径：`/etc/ansible/hosts`

使用方法：

```bash
# 定义一个主机组
[web]
172.16.1.100
172.16.1.70
172.16.1.20
172.16.4.10
```


-------

{% note info %}### Ansible中模块的使用
{% endnote %}


#### <font size=4 color="#32CD99">Ansible模块</font>

* command模块：使用ansible自带模块执行命令 如果要用 > < | & ' ' 使用shell模块

```bash
$ ansible web -m command -a 'ls -l /root'
172.16.1.70 | SUCCESS | rc=0 >>
total 16
-rw-r--r--  1 root root   29 Jun 20 23:11 1.log
-rw-------. 1 root root 2642 May 25 23:19 anaconda-ks.cfg
-rw-r--r--  1 root root  171 May 25 17:34 local.repo
-rw-r--r--  1 root root   58 Jun 20 23:10 run.sh.log

172.16.1.21 | SUCCESS | rc=0 >>
total 12
-rw-------. 1 root root 2640 May 27 19:26 anaconda-ks.cfg
-rw-r--r--  1 root root  171 May 27 11:30 local.repo
-rw-r--r--  1 root root   58 Jun 20 23:09 run.sh.log

172.16.1.100 | SUCCESS | rc=0 >>
total 32
-rw-------. 1 root root 2640 May 26 15:00 anaconda-ks.cfg
drwxr-xr-x  2 root root 4096 Jun 21 03:27 ansible-yml
-rw-------  1 root root  419 Jun 20 14:43 crypt.yml

# 相关选项如下：
creates：一个文件名，当该文件存在，则该命令不执行
free_form：要执行的linux指令
chdir：在执行指令之前，先切换到该目录
removes：一个文件名，当该文件不存在，则该选项不执行
executable：切换shell来执行指令，该执行路径必须是一个绝对路径
```

<br>

* shell模块：调用bash执行命令

```bash
$ ansible web -m shell -a 'useradd maxieuser && echo root@123 | passwd --stdin maxieuser'
172.16.1.70 | SUCCESS | rc=0 >>
Changing password for user maxieuser.
passwd: all authentication tokens updated successfully.

172.16.1.21 | SUCCESS | rc=0 >>
Changing password for user maxieuser.
passwd: all authentication tokens updated successfully.

172.16.1.100 | SUCCESS | rc=0 >>
Changing password for user maxieuser.
passwd: all authentication tokens updated successfully.
```

<br>

* copy模块：复制本地文件至远程服务器，并能够修改其属性

源文件复制：
![](https://ws1.sinaimg.cn/large/006tNbRwly1fhbnqixyt9j31hy1fae81.jpg)

```bash
# 相关的选项
backup：在覆盖之前，将源文件备份，备份文件包含时间信息。有两个选项：yes|no
content：用于替代“src”，可以直接设定指定文件的值
dest：必选项。要将源文件复制到的远程主机的绝对路径，如果源文件是一个目录，那么该路径也必须是个目录
directory_mode：递归设定目录的权限，默认为系统默认权限
force：如果目标主机包含该文件，但内容不同，如果设置为yes，则强制覆盖，如果为no，则只有当目标主机的目标位置不存在该文件时，才复制。默认为yes
others：所有的file模块里的选项都可以在这里使用
src：被复制到远程主机的本地文件，可以是绝对路径，也可以是相对路径。如果路径是一个目录，它将递归复制。在这种情况下，如果路径使用“/”来结尾，则只复制目录里的内容，如果没有使用“/”来结尾，则包含目录在内的整个内容全部复制，类似于rsync。
```

<br>

* file模块：设置文件属性

```bash
$ ansible web -m file -a 'path=/tmp/df.txt mode="0600" owner="maxie" group="root"'
172.16.4.10 | SUCCESS => {
    "changed": true,
    "gid": 0,
    "group": "root",
    "mode": "0600",
    "owner": "maxie",
    "path": "/tmp/df.txt",
    "size": 370,
    "state": "file",
    "uid": 500
}
$ ansible web -m shell -a 'ls -l /tmp/df*'
172.16.4.10 | SUCCESS | rc=0 >>
-rw------- 1 maxie root 370 Apr 24 14:40 /tmp/df.txt


# 相关选项
force：需要在两种情况下强制创建软链接，一种是源文件不存在，但之后会建立的情况下；另一种是目标软链接已存在，需要先取消之前的软链，然后创建新的软链，有两个选项：yes|no
group：定义文件/目录的属组
mode：定义文件/目录的权限
owner：定义文件/目录的属主
path：必选项，定义文件/目录的路径
recurse：递归设置文件的属性，只对目录有效
src：被链接的源文件路径，只应用于state=link的情况
dest：被链接到的路径，只应用于state=link的情况
state：
       directory：如果目录不存在，就创建目录
       file：即使文件不存在，也不会被创建
       link：创建软链接
       hard：创建硬链接
       touch：如果文件不存在，则会创建一个新的文件，如果文件或目录已存在，则更新其最后修改时间
       absent：删除目录、文件或者取消链接文件
```

<br>

* fetch模块：从远程服务器拉取文件至本机；只能fetch文件，不能fetch目录；如果需要拉目录，先打包，再拉到本机。

```
$ ansible web -m fetch -a 'src=/tmp/df.txt dest=/tmp'
172.16.4.10 | SUCCESS => {
    "changed": true,
    "checksum": "d77170b4ae2eb1b70d7a3787ceba087639c1ee4d",
    "dest": "/tmp/172.16.4.10/tmp/df.txt",
    "md5sum": "9a83dbdbebebe174cbdc65ef39a0d905",
    "remote_checksum": "d77170b4ae2eb1b70d7a3787ceba087639c1ee4d",
    "remote_md5sum": null
}
```

<br>

* cron模块：定时执行任务的模块

```bash
$ ansible web -m cron -a 'name="disk check" minute="15" hour="3" job="df -lh >> df.log" weekday=0'
172.16.1.70 | SUCCESS => {
    "changed": true,
    "envs": [],
    "jobs": [
        "disk check"
    ]
}
172.16.1.20 | SUCCESS => {
    "changed": true,
    "envs": [],
    "jobs": [
        "disk check"
    ]
}
172.16.1.100 | SUCCESS => {
    "changed": true,
    "envs": [],
    "jobs": [
        "disk check"
    ]
}
$ crontab -l
#Ansible: disk check
15 3 * * 0 df -lh >> df.log


'删除计划任务：'
$ ansible web -m cron -a 'state=absent name="disk check"'
172.16.1.70 | SUCCESS => {
    "changed": true,
    "envs": [],
    "jobs": []
}
172.16.1.20 | SUCCESS => {
    "changed": true,
    "envs": [],
    "jobs": []
}
172.16.1.100 | SUCCESS => {
    "changed": true,
    "envs": [],
    "jobs": []
}
[root@test-1 ~]# crontab -l

# 相关的选项
- a "": 设置管理节点生成定时任务
action: cron
backup=    # 如果设置，创建一个crontab备份
cron_file=          #如果指定, 使用这个文件cron.d，而不是单个用户crontab
day=       # 日应该运行的工作( 1-31, *, */2, etc )
hour=      # 小时 ( 0-23, *, */2, etc )
job=       #指明运行的命令是什么
minute=    #分钟( 0-59, *, */2, etc )
month=     # 月( 1-12, *, */2, etc )
name=     #定时任务描述
reboot    # 任务在重启时运行，不建议使用，建议使用special_time
special_time       # 特殊的时间范围，参数：reboot（重启时）,annually（每年）,monthly（每月）,weekly（每周）,daily（每天）,hourly（每小时）

state        #指定状态，prsent表示添加定时任务，也是默认设置，absent表示删除定时任务

user         # 以哪个用户的身份执行
weekday      # 周 ( 0-6 for Sunday-Saturday, *, etc )
```


<br>

* yum模块：yum安装软件

```bash
$ ansible mageduweb -m yum -a 'name=httpd state=latest'  //安装httpd包

# 相关选项
conf_file           #设定远程yum安装时所依赖的配置文件。如配置文件没有在默认的位置。
disable_gpg_check   #是否禁止GPG checking，只用于`present' or `latest'。
disablerepo         #临时禁止使用yum库。 只用于安装或更新时。
enablerepo          #临时使用的yum库。只用于安装或更新时。
name=               #所安装的包的名称
state               #present安装， latest安装最新的, absent 卸载软件。
update_cache        #强制更新yum的缓存。
```

<br>

* service模块：服务程序管理

```bash
$ ansible web -m service -a 'name=httpd state=started'

# 相关选项
arguments           #命令行提供额外的参数
enabled             #设置开机启动。
name=               #服务名称
runlevel            #开机启动的级别，一般不用指定。
sleep               #在重启服务的过程中，是否等待。如在服务关闭以后等待2秒再启动。
state               #started启动服务， stopped停止服务， restarted重启服务， reloaded重载配置
```

<br>

* user模块：用户管理

```bash
$ ansible web -m user -a 'name=tom comment="tom user" shell=/bin/bash uid=1007 groups=maxie home=/home/tomhome'

# 相关选项
comment         # 用户的描述信息
createhom       # 是否创建家目录
force           # 在使用`state=absent'是, 行为与`userdel --force'一致.
group           # 指定基本组
groups          # 指定附加组，如果指定为('groups=')表示删除所有组
home            # 指定用户家目录
login_class     #可以设置用户的登录类 FreeBSD, OpenBSD and NetBSD系统.
move_home       # 如果设置为`home='时, 试图将用户主目录移动到指定的目录
name=           # 指定用户名
non_unique      # 该选项允许改变非唯一的用户ID值
password        # 指定用户密码
remove          # 在使用 `state=absent'时, 行为是与 `userdel --remove'一致.
shell           # 指定默认shell
state           #设置帐号状态，不指定为创建，指定值为absent表示删除
system          # 当创建一个用户，设置这个用户是系统用户。这个设置不能更改现有用户。
uid             #指定用户的uid
update_password # 更新用户密码
expires         #指明密码的过期时间
```

<br>

* group模块：组管理

```bash
$ ansible web -m group -a 'name=test gid=1001'

# 相关选项
gid       # 设置组的GID号
name=     # 管理组的名称
state     # 指定组状态，默认为创建，设置值为absent为删除
system    # 设置值为yes，表示为创建系统组
```

<br>

* ping模块：检测主机是否存活


<br>

* setup模块：获取指定主机的facts
facts就是变量，内建变量 。每个主机的各种信息，cpu颗数、内存大小等。会存在facts中的某个变量中。调用后返回很多对应主机的信息，在后面的操作中可以根据不同的信息来做不同的操作

```
$ ansible web -m setup
```

<br>

* selinux模块：管理selinux

```bash
$ ansible web -m selinux -a 'state=disabled'

# 相关选项
conf                                    #指定应用selinux的配置文件。
state=enforcing|permissive|disabled     #对应于selinux配置文件的SELINUX。
policy=targeted|minimum|mls             #对应于selinux配置文件的SELINUXTYPE
```

<br>

* script脚本模块：将本地的脚本复制到远程主机并在远程主机执行

```
$ ansible web -m script -a '/root/run.sh'
```

<br>

* hostname模块：与系统命令无关，直接修改  比如centos6和centos7

```
$ ansible 172.16.1.100 -m hostname -a 'name=master'
172.16.1.100 | SUCCESS => {
    "ansible_facts": {
        "ansible_domain": "",
        "ansible_fqdn": "master",
        "ansible_hostname": "master",
        "ansible_nodename": "master"
    },
    "changed": true,
    "name": "master"
}
```

-------

{% note success %}### Ansible实践练习题
{% endnote %}

#### <font size=4 color="#32CD99">使用yml配置文件，执行拷贝文件的功能</font>

```
$ vim copy.yml
---

- hosts: web
  remote_user: root

  tasks:
    - name: coyp file
      copy: src=/etc/issue dest=/tmp/my.txt owner=maxiecloud backup=yes mode=0660

$ ansible-playbook nginx.yml

PLAY [web] *********************************************************************

TASK [setup] *******************************************************************
ok: [172.16.4.10]
ok: [172.16.1.70]
ok: [172.16.1.20]
ok: [172.16.1.100]

TASK [coyp file] ***************************************************************
changed: [172.16.4.10]
changed: [172.16.1.70]
changed: [172.16.1.20]
changed: [172.16.1.100]

PLAY RECAP *********************************************************************
172.16.1.100               : ok=2    changed=1    unreachable=0    failed=0
172.16.1.20                : ok=2    changed=1    unreachable=0    failed=0
172.16.1.70                : ok=2    changed=1    unreachable=0    failed=0
172.16.4.10                : ok=2    changed=1    unreachable=0    failed=0

$ ansible web -m shell -a 'ls -l /tmp/*.txt'
172.16.4.10 | SUCCESS | rc=0 >>
-rw-rw---- 1 maxiecloud root 79 Apr 24 19:51 /tmp/my.txt

172.16.1.20 | SUCCESS | rc=0 >>
-rw-rw---- 1 maxiecloud root 79 Jun 21 02:21 /tmp/my.txt

172.16.1.70 | SUCCESS | rc=0 >>
-rw-rw---- 1 maxiecloud root 79 Jun 21 02:22 /tmp/my.txt

172.16.1.100 | SUCCESS | rc=0 >>
-rw-rw---- 1 maxiecloud root 79 Jun 20 17:50 /tmp/my.txt
```


#### <font size=4 color="#32CD99">使用yml配置文件，启动&安装HTTPD</font>


```
$ vim httpd.yml
---

- hosts: web
  remote_user: root
  tasks:
  - name: "remove appache"
    command: yum remove -y -q httpd httpd-devel
  - name: "install apache"
    command: yum install -y -q httpd httpd-devel
  - name: "stop nginx"
    service: name=nginx state=stopped
  - name: "restart httpd"
    service: name=httpd state=restarted

$ ansible-playbook  httpd.yml
```


#### <font size=4 color="#32CD99">使用yml，创建用户，并配置其属性</font>

```
$ vim adduser.yml
---
- hosts: web
  remote_user: root

  tasks:
    - name: useradd maxie1
      user: name=maxie1 home=/home/maxie1 shell=/bin/bash uid=1200
    - name: useradd maxie2
      user: name=maxie2 home=/home/maxie2 shell=/bin/bash uid=1201

$ ansible-playbook adduser.yml
```


#### <font size=4 color="#32CD99">使用YML配置文件，使用变量 -m setup，并在yml中引用变量</font>


```
$ vim nginx.yml
---

- hosts: web
  remote_user: root

  tasks:
    - name: install nginx
      command: yum install -y -q nginx
    - name: install httpd
      command: yum install -y -q httpd
    - name: nginx processor
      template: src=/root/ansible-yml/nginx.conf.j2 dest=/etc/nginx/nginx.conf
    - name: stop httpd
      service: name=httpd state=stopped
    - name: start nginx
      service: name=nginx state=started
    - name: grep nginx
      shell: ss -tnlp | grep nginx

$ ansible web -m setup  | grep processor_vcpus
```


#### <font size=4 color="#32CD99">使用变量配置nginx中虚拟主机的监听端口号</font>


```
$ vim /etc/ansible/hosts
[web]
172.16.1.100 webport=8080 server_name=www1.maxie.com
172.16.1.70 webport=8081 server_name=www2.maxie.com
172.16.1.20 webport=8082 server_name=www3.maxie.com

$ vim ansible-yml/maxie.conf.j2
server {
        listen {{ webport }};
        server_name {{ server_name }};
        root    /data/web/;
        location / {
                root    /data/web/;
                index   index.html;
        }
}

$ vim nginx.yml
---

- hosts: web
  remote_user: root

  tasks:
    - name: install nginx
      command: yum install -y -q nginx
    - name: install httpd
      command: yum install -y -q httpd
    - name: nginx processor
      template: src=/root/ansible-yml/nginx.conf.j2 dest=/etc/nginx/nginx.conf
    - name: stop httpd
      service: name=httpd state=stopped
    - name: start nginx
      service: name=nginx state=started
    - name: grep nginx
      shell: ss -tnlp | grep nginx
```

#### <font size=4 color="#32CD99">roles实验</font>

```bash
# 1、在/etc/ansible/roles目录下创建：
	$ mkdir nginx/{tasks,files,vars,templates,handlers}


# 2、在tasks目录下创建各个任务yml文件：
	$ vim nginx/tasks/init.yml 
	---
	 - name: init nginx
	   copy: src=README dest=/etc/nginx/conf.d

	 - name: init nginx.conf
	   template: src=maxie.conf.j2 dest=/etc/nginx/conf.d/maxie.conf
	   notify: restart nginx

	$ vim nginx/tasks/install.yml
	---
	  - name: install nginx
	    yum: name=nginx state=installed


# 3、在files和template目录下 创建我们之前设置要拷贝的文件：
	$ vim nginx/files/README
	Just For ReadMe

	$ vim nginx/templates/maxie.conf.j2
	server {
	        listen {{ webport }};
	        server_name {{ server_name }};
	        root    /data/web/;
	        location / {
	                root    /data/web/;
	                index   index.html;
	        }
	}


# 4、在handler下创建main.yml 
	$ vim nginx/handlers/main.yml
	---

	- name: restart nginx
	  service: name=nginx state=restarted


# 5、创建变量的mail.yml
	$ vim nginx/vars/mail.yml 
	server_name: www.maxie.com
	webport: 8080


# 6、创建tasks的main.yml 
	$ vim nginx/tasks/main.yml 
	---

	- include: install.yml
	- include: init.yml


# 7、创建主yml
	$ cd /etc/ansible
	$ vim nginx.yml 
	---

	- hosts: web
	  remote_user: root
	  roles:
	  - nginx


# 8、测试
	$ ansible-playbook nginx.yml

	PLAY [web] *********************************************************************

	TASK [setup] *******************************************************************
	ok: [172.16.1.70]
	ok: [172.16.1.21]
	ok: [172.16.1.100]

	TASK [nginx : install nginx] ***************************************************
	ok: [172.16.1.21]
	ok: [172.16.1.70]
	ok: [172.16.1.100]

	TASK [nginx : init nginx] ******************************************************
	ok: [172.16.1.21]
	ok: [172.16.1.70]
	ok: [172.16.1.100]

	TASK [nginx : init nginx.conf] *************************************************
	changed: [172.16.1.70]
	changed: [172.16.1.21]
	changed: [172.16.1.100]

	RUNNING HANDLER [nginx : restart nginx] ****************************************
	changed: [172.16.1.70]
	changed: [172.16.1.21]
	changed: [172.16.1.100]

	PLAY RECAP *********************************************************************
	172.16.1.100               : ok=5    changed=2    unreachable=0    failed=0
	172.16.1.21                : ok=5    changed=2    unreachable=0    failed=0
	172.16.1.70                : ok=5    changed=2    unreachable=0    failed=0
```


-------

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


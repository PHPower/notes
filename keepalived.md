---
title: Keepalived+Nginx/LVS实现Web站点高可用 
date: 2017-06-24 16:14:44
tags: [keepalived,nginx,lvs,HA]
categories: [Nginx,LVS,linux进阶]
copyright: true
---

当公司需要实现内部Web网站对外提供服务时，为了提高用户体验，要尽可能的保证Web站点的可用性。这时，我们就需要对Web系统做高可用(High Availability)，计划使用两台Nginx做HA，通过使用keepalived工具达到我们的目的。

但是解决办法不只有Nginx+Keepalived，也可以使用LVS+Keealived，不过在中小型以及不是特别大型的企业，是基本没有使用LVS做负载均衡的，这里我们只做简单的介绍。

在之前的章节，我们已经说过如何对Nginx配置反向代理以及负载均衡的配置，这里就不过多介绍了。

### 1. Keepalived介绍

`Keepalived`是一个基于`vrrp`协议来实现的服务器高可用解决方案，可以利用其实现避免IP单点故障，类似的工具还有`heartbeat`、`corosync`。不过其不会单独出现，而是搭配着 LVS、Nginx、HAproxy，一起协同工作达到高可用的目的。

#### 1.1 VRRP协议

`VRRP`全称Vritual Router Redundancy Protocol，虚拟路由冗余协议。通过把几台提供路由功能的设备组成一个虚拟路由设备，使用一定的机制保证虚拟路由的高可用，从而达到保持业务的连续性与可靠性。

在这组成的一个虚拟路由器中，有`master`和`backup`之分。master是主节点，在一个虚拟路由器中，只能有一个master，但可以有多个backup；backup是备用节点，也就是当master挂掉之后，backup接手master节点的所有资源，当有多个backup节点时，根据其`priority`(优先级)的值的大小，来选择谁作为master的替代者。当backup节点的优先级值相同时，根据其IP地址的大小，来决定。

![](https://ws2.sinaimg.cn/large/006tKfTcly1fgwe6875u7j305y06jt8n.jpg)

#### 1.2 VRRP工作逻辑

![](https://ws3.sinaimg.cn/large/006tKfTcly1fgwebjw84pj30l80jm75q.jpg)



-------

<!-- more -->



{% note primary %}### 2.配置前提
{% endnote %}

#### 2.1 各节点时间必须同步

可以使用`ntp`、`chrony`等工具进行时间同步

**配置一台时间服务器**

```
$ yum install -y chrony
$ vim /etc/chrony.conf
server 172.16.0.1 iburst        #设置互联网的时间服务器，这里我们使用的是一台可以连接互联网的服务器
allow 192.168/16                #允许哪些网段/地址的机器通过我们本机来同步时间
local stratum 10                #如果本机时间不准确，是否允许其他机器同步时间。如果注释掉，则为不允许

$ systemctl start chronyd.service
```

配置完成之后，其他节点安装`chrony`之后，只需在配置文件中添加一行 `server 192.168.1.10 iburst`即可。因为我们这台时间服务器对内的网卡是 `192.168.1.10/24`

#### 2.2 确保iptables和selinux规则对我们放行

实验环境下，我们直接将防火墙规则清空，关闭selinux

```
$ iptables -F
$ systemctl stop firewalld.service
$ setenforce 0
```

#### 2.3 查看网卡是否支持 MULTICAST(多播通信)

在vrrp协议中我们要将我们虚拟路由器中各节点的优先级进行广播，这样在我们故障时，其他节点发现在多播域内自己的优先级最高，可以实现故障切换。

多播地址(组播)：`224.0.0.0 -- 239.255.255.255`


```
查看是否支持多播
$ ifconfig | grep MULTICAST

开启多播功能
$ ip link set multicast on dev eth0 
```




-------

{% note info %}### 3.配置Keepalived+Nginx
{% endnote %}

#### 3.1 拓扑结构


```
                   +-------------+
                   |    ROUTER   |
                   +-------------+
                          |
                          +
    MASTER            keep|alived         BACKUP
  172.16.3.10       172.16.3.100       172.16.3.40
+-------------+    +-------------+    +-------------+
|   nginx01   |----|  virtualIP  |----|   nginx02   |
+-------------+    +-------------+    +-------------+
  192.168.1.10            |            192.168.1.20
           +--------------+--------------+
           |                             |
    +-------------+               +-------------+
    |    web01    |               |    web02    |
    +-------------+               +-------------+
```

![](https://ws1.sinaimg.cn/large/006tKfTcly1fgwey5f2q2j30no0zxjsq.jpg)



#### 3.2 安装Keepalived

本机环境是`CentOS 7.2-1511 x86_64`

```
$ yum install -y keepalived
$ keepalived -v
Keepalived v1.2.13 (11/20,2015)
```

#### 3.3 配置Nginx监控脚本

Keepalvied提供可以调用外部脚本来达到对资源进行监控，这里我们顶一个对`Nginx`进程的监控脚本。
该脚本检测Nginx的运行状态，


```
! Configuration File for keepalived

global_defs {
   notification_email {
     root@localhost
   }
   notification_email_from KA@localhost
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id vs1
   vrrp_mcast_group4 224.16.3.100
}

vrrp_script chk_ngx {
    script "killall -0 nginx && exit 0 || exit 1"
    interval 4
    weight -10
    fall 4
    rise 4
}

vrrp_instance VI_1 {
    state MASTER
    interface eno16777736
    virtual_router_id 51
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass maxie95
    }
    virtual_ipaddress {
	       172.16.3.100/16 dev eno16777736 label eno16777736:0
    }

    track_script {
        chk_ngx
    }
}
```

在其他备用BACKUP主机上，只需要将：
`route_id vs1` >> `route_id vsN`    只需要修改`vs`后的数字为backup的机器编号即可
`state MASTER` >> `state BACKUP`    在这之前我们说过，Master只能有一个，所以其他BAKCUP都要修改这里
`priority 100` >> `priority 90`     其他BACKUP节点的优先级一定要比Master节点小


#### 3.4 配置选项说明

**global_defs**：全局配置段

| 选项 | 说明 |
| --- | --- |
| notification_email | 通知邮件配置块 |
| root@localhost | 通知邮件收件人 |
| notification_email_from | 通知邮件发件人 |
| smtp_server | 邮件服务器地址 |
| smtp_connect_timeout | 邮件服务器连接超时时长 |
| router_id | 机器表示，通常设置为本机的hostname |
| vrrp_mcast_group4 | vrrp的多播地址(ipv4) |

<br>

**vrrp_instance**：vrrp实例配置段

| 选项 | 说明 |
| --- | --- |
| state | 指定vrrp_instance的初始状态。但如果master的优先级比某个backup还低，那么在通告时，那台backup就会抢占master |
| interface | 实例绑定的网卡。必须是本机已有的网卡 |
| virtual_router_id | 设置虚拟路由器标识(范围0-255)。只有相同的标识，才能实现在多播域内通告优先级以及其他信息 |
| priority | 设置本机节点的优先级，优先级最高的为真正的MASTER |
| advert_int | 每隔多长时间通告并检查一次，默认为1秒 |
| authentication | 定义认证方式和密码。MASTER/BACKUP必须一样 |
| virtual_ipaddress | 设置VIP地址，也就是虚拟IP地址。可以设置多个VIP；只有当节点为MASTER时，此IP才会生效 |
| track_script | 调用自定义的脚本，即在vrrp_scrpit块指定的名字。 |

<br>

**vrrp_script**：通知keepalived在什么情况下切换主备节点。可以有多个`vrrp_script`


| script | 自定义的脚本。可以是脚本文件的路径，也可以是一行命令； |
| --- | --- |
| interval 4 | 每4秒检测一次 |
| weight -10 | 检测失败(脚本返回值为非0任意数字)时，优先级减10 |
| fall 3 | 连续检测2次失败才算真正的失败。才会执行上面的weight -10，减去优先级 |
| rise 3 | 检测3次成功才算成功，不修改优先级 |

* 只有当`script`的返回状态结果为任意非`0`数字时，才会执行降权操作。
* 当`script`正常执行时，也就是返回值为0时，不做任何操作。

* 脚本示例：可以在`script`中调用，直接引用脚本路径即可

该脚本检测ngnix的运行状态，并在nginx进程不存在时尝试重新启动ngnix，如果启动失败则停止keepalived，准备让其它机器接管

```
#!/bin/bash
counter=$(ps -C nginx --no-heading|wc -l)
if [ "${counter}" = "0" ]; then
    /usr/local/bin/nginx
    sleep 2
    counter=$(ps -C nginx --no-heading|wc -l)
    if [ "${counter}" = "0" ]; then
        /etc/init.d/keepalived stop
    fi
fi
```

**notify**：自定义通知脚本

```
notify_master <STRING>|<QUOTED-STRING>          当前节点成为MASTER时触发的脚本
notify_backup <STRING>|<QUOTED-STRING>          当前节点成为BACKUP时触发的脚本
notify_fault  <STRING>|<QUOTED-STRING>          当前节点转为FAULT(失败)状态时触发的脚本

notify <STRING>|<QUOTED-STRING>                 通用格式的通知触发机制，一个脚本可完成以上三种状态的转换时的通知
```

* 通知脚本示例：

```
$ vim /etc/keepalived/notify.sh
#!/bin/bash
#
contact="root@localhost"

notify() {
	local mailsubject="$(hostname) to be $1, VIP is folating"
	local mailbody="$(date + '$F $T'): vrrp transition, $(hostname) changed to be $1"
	echo "$mailbody" | mail -s "$mailsubject" $contact
}

case $1 in
master)
	systemctl start nginx
	notify master
	;;
backup)
	systemctl start nginx
	notify backup
	;;
fault)
	notify fault
	;;
*)
	echo "Usage: $(basename $0) {master|backup|fault}"
	exit 1
	;;
esac
```

**抢占/非抢占模式**：

```
nopreempt               定义工作模式为非抢占模式
preempt_delay 300       抢占式模式下，节点上线后触发新选举操作的延迟时长为300秒
```


-------

{% note success %}### 4.测试Keepalived+Nginx的效果
{% endnote %}

#### 4.1 测试keepalived的主备切换功能

* 在主备都正常启动keepalived时，停掉MASTER节点的keepalived服务

```
MASTER:
$ systemctl stop keepalived

BACKUP:
$ systemctl status keepalived
```
![](https://ws3.sinaimg.cn/large/006tKfTcly1fgwin8kmirj311s0cbkb5.jpg)

这时，VIP地址漂移到BACKUP主机上。

* 原MASTER节点再启动keepalived服务，抢回VIP地址

```
MASTER:
$ systemctl start keepalived
$ systemctl status keepalived
```
![](https://ws3.sinaimg.cn/large/006tKfTcly1fgwitjzx2lj31kw0ig4qq.jpg)


#### 4.2 通过tcpdump查看发送通告信息

执行上面的实验，观察`tcpdump`命令结果输出的信息的变化：

![](https://ws1.sinaimg.cn/large/006tKfTcly1fgwiymz96jg30qk0fc4r6.gif)


```
[root@vs1 ~]# tcpdump -i eno16777736 -nn host 224.16.3.100
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eno16777736, link-type EN10MB (Ethernet), capture size 65535 bytes
17:40:24.749943 IP 172.16.3.40 > 224.16.3.100: VRRPv2, Advertisement, vrid 51, prio 98, authtype simple, intvl 2s, length 20
17:40:33.421434 IP 172.16.3.40 > 224.16.3.100: VRRPv2, Advertisement, vrid 51, prio 98, authtype simple, intvl 2s, length 20
17:40:35.590278 IP 172.16.3.10 > 224.16.3.100: VRRPv2, Advertisement, vrid 51, prio 100, authtype simple, intvl 2s, length 20
17:40:35.590697 IP 172.16.3.40 > 224.16.3.100: VRRPv2, Advertisement, vrid 51, prio 98, authtype simple, intvl 2s, length 20
17:40:35.591009 IP 172.16.3.10 > 224.16.3.100: VRRPv2, Advertisement, vrid 51, prio 100, authtype simple, intvl 2s, length 20
17:40:37.595546 IP 172.16.3.10 > 224.16.3.100: VRRPv2, Advertisement, vrid 51, prio 100, authtype simple, intvl 2s, length 20
```

-------

{% note warning %}### 5.配置双主模式
{% endnote %}

#### 5.1 添加配置

只需要在原有的配置上添加1个VIP地址以及vrrp_intance的配置即可


```
$ vim /etc/keepalived/keepalived.conf
添加一个vrrp_intance配置：

vrrp_instance VI_2 {
    state BACKUP
    interface eno16777736
    virtual_router_id 61
    priority 98
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass maxie19
    }
    virtual_ipaddress {
        172.16.3.200/16 dev eno16777736 label eno16777736:1
    }

    track_script {
        chk_down
        chk_ngx
    }

    notify_master "/etc/keepalived/notify.sh master"
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault "/etc/keepalived/notify.sh fault"
}

$ systemctl restart keepalived
```

**注意：**记得也要在另一台"MASTER"节点上配置，并修改 `state`、`priority`


#### 5.2 测试

![](https://ws4.sinaimg.cn/large/006tKfTcly1fgwj7o76hwg30qk0fcu10.gif)

```
# maxie @ maxie in ~ [15:02:55]
$ curl http://172.16.3.200
RS1 Node1 192.168.1.30

# maxie @ maxie in ~ [15:13:06]
$ curl http://172.16.3.200
RS2 Node2 192.168.1.40

# maxie @ maxie in ~ [15:13:07]
$ curl http://172.16.3.100
RS2 Node2 192.168.1.40

# maxie @ maxie in ~ [15:13:08]
$ curl http://172.16.3.100
RS1 Node1 192.168.1.30
```



-------


**参考：**

* [使用Keepalived实现Nginx高可用性](http://debugo.com/keepalived-nginx/)
* [虚拟路由器冗余协议【原理篇】VRRP详解](http://zhaoyuqiang.blog.51cto.com/6328846/1166840)
* [Linux 高可用（HA）集群之keepalived详解](http://freeloda.blog.51cto.com/2033581/1280962)
* [VRRP 技术白皮书 - Huawei](enterprise.huawei.com/ilink/cnenterprise/download/HW_201057)




-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=29588431&auto=0&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)




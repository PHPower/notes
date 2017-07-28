---
title: Redis-Cluster集群搭建
date: 2017-07-16 08:46:17
tags: [redis,cluster,linux]
categories: [linux进阶,redis]
copyright: true
---

![](https://ws2.sinaimg.cn/large/006tKfTcly1fhlgavtpqpj30at03mq2s.jpg)

<blockquote class="blockquote-center">Redis 集群是一个提供在多个Redis间节点间共享数据的程序集。
Redis集群并不支持处理多个keys的命令,因为这需要在不同的节点间移动数据,从而达不到像Redis那样的性能,在高负载的情况下可能会导致不可预料的错误。
Redis集群通过分区来提供一定程度的可用性,在实际环境中当某个节点宕机或者不可达的情况下继续处理命令。
</blockquote>

**Redis集群的优势：**

* 自动分割数据到不同的节点上。
* 整个集群的部分节点失败或者不可达的情况下能够继续处理命令。

<br>

**Redis集群的数据分片：**

```bash
Redis 集群没有使用一致性hash, 而是引入了哈希槽的概念


Redis 集群有16384个哈希槽,每个key通过CRC16校验后对16384取模来决定放置哪个槽.集群的每个节点负责一部分hash槽

举个例子,比如当前集群有3个节点,那么:
* 节点 A 包含 0 到 5500号哈希槽.
* 节点 B 包含5501 到 11000 号哈希槽.
* 节点 C 包含11001 到 16384号哈希槽.


这种结构很容易添加或者删除节点. 比如如果我想新添加个节点D, 我需要从节点 A, B, C中得部分槽到D上. 如果我像移除节点A,需要将A中得槽移到B和C节点上,然后将没有任何槽的A节点从集群中移除即可. 
由于从一个节点将哈希槽移动到另一个节点并不会停止服务,所以无论添加删除或者改变某个节点的哈希槽的数量都不会造成集群不可用的状态
```

<br>

**Redis集群的主从复制模型：**

为了使在部分节点失败或者大部分节点无法通信的情况下集群仍然可用，所以集群使用了主从复制模型,每个节点都会有N-1个复制品.

在我们例子中具有A，B，C三个节点的集群,在没有复制模型的情况下,如果节点B失败了，那么整个集群就会以为缺少5501-11000这个范围的槽而不可用.

然而如果在集群创建的时候（或者过一段时间）我们为每个节点添加一个从节点A1，B1，C1,那么整个集群便有三个master节点和三个slave节点组成，这样在节点B失败后，集群便会选举B1为新的主节点继续服务，整个集群便不会因为槽找不到而不可用了

不过当B和B1 都失败后，集群是不可用的.


<br>

**Redis 一致性保证**

Redis 并不能保证数据的强一致性. 这意味这在实际中集群在特定的条件下可能会丢失写操作.
第一个原因是因为集群是用了异步复制. 

`写操作过程：`
* 客户端向主节点B写入一条命令.
* 主节点B向客户端回复命令状态.
* 主节点将写操作复制给他得从节点 B1, B2 和 B3.

主节点对命令的复制工作发生在返回命令回复之后， 因为如果每次处理命令请求都需要等待复制操作完成的话， 那么主节点处理命令请求的速度将极大地降低 —— 我们必须在性能和一致性之间做出权衡。 注意：Redis 集群可能会在将来提供同步写的方法。 Redis 集群另外一种可能会丢失命令的情况是集群出现了网络分区， 并且一个客户端与至少包括一个主节点在内的少数实例被孤立。

举个例子 假设集群包含 A 、 B 、 C 、 A1 、 B1 、 C1 六个节点， 其中 A 、B 、C 为主节点， A1 、B1 、C1 为A，B，C的从节点， 还有一个客户端 Z1 假设集群中发生网络分区，那么集群可能会分为两方，大部分的一方包含节点 A 、C 、A1 、B1 和 C1 ，小部分的一方则包含节点 B 和客户端 Z1 .

Z1仍然能够向主节点B中写入, 如果网络分区发生时间较短,那么集群将会继续正常运作,如果分区的时间足够让大部分的一方将B1选举为新的master，那么Z1写入B中得数据便丢失了.

注意， 在网络分裂出现期间， 客户端 Z1 可以向主节点 B 发送写命令的最大时间是有限制的， 这一时间限制称为节点超时时间（node timeout）， 是 Redis 集群的一个重要的配置选项：




-------

<!-- more -->

{% note primary %}### 搭建Redis集群
{% endnote %}

[官方搭建cluster文档](https://redis.io/topics/cluster-tutorial)

#### <font szie=4 color="#007FFF">搭建之前的准备工作</font>

* 准备三台虚拟机(至少3台)

```
NODE1   172.16.1.100/16
NODE2   172.16.1.70/16
NODE3   172.16.1.30/16
```

* 配置文件(最少选项的集群配置文件)

```bash
$ vim /etc/redis.conf
# 监听的端口
port 6379
# 监听地址，为了方便直接使用本机所有地址
bind 0.0.0.0
# 登陆Redis密码
requirepass mypass

#### REDIS CLUSTER  ####
# 开启集群
cluster-enabled yes
# 集群配置文件，无需创建，自动生成
cluster-config-file nodes-6379.conf
# 集群超时时间
cluster-node-timeout 15000
```

要让集群正常运作至少需要三个主节点，不过在刚开始试用集群功能时， 强烈建议使用六个节点： 其中三个为主节点， 而其余三个则是各个主节点的从节点。



#### <font szie=4 color="#007FFF">启动redis，并配置集群</font>


```bash
$ systemctl restart redis 
$ ss -tnl
$ ll /var/lib/redis/
total 4
-rw-r--r-- 1 redis redis 112 Jun 20 07:59 nodes-6379.conf

# 配置集群 --> NODE1节点
$ redis -a mypass
127.0.0.1:6379> CLUSTER NODES
ae97e9700ef65e6ccf648c8a77a339cdfe7366c1 :6379 myself,master - 0 0 0 connected
127.0.0.1:6379> CLUSTER MEET 172.16.1.70 6379
OK
127.0.0.1:6379> CLUSTER MEET 172.16.1.30 6379
OK
127.0.0.1:6379> CLUSTER NODES
76a6fdbc6fe619ef120cf230145cb4b43c80aeaf 172.16.1.70:6379 master - 0 1497917025809 1 connected
7349f132ca8cefc148b203ff3e02f8afb1692962 172.16.1.30:6379 master - 0 1497917026819 2 connected
ae97e9700ef65e6ccf648c8a77a339cdfe7366c1 172.16.1.100:6379 myself,master - 0 0 0 connected
127.0.0.1:6379> CLUSTER INFO
# 显示集群状态为 失败；这里是因为我们没有配置slots
cluster_state:fail
cluster_slots_assigned:0
cluster_slots_ok:0
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:3
cluster_size:0
cluster_current_epoch:2
cluster_my_epoch:0
cluster_stats_messages_sent:47
cluster_stats_messages_received:4
```

#### <font szie=4 color="#007FFF">配置各个节点的SLOTS</font>

```bash
# 修改各个节点的/var/redis/node-6379.conf文件

NODE1节点：
	$ vim /var/lib/redis/nodes-6379.conf
	ae97e9700ef65e6ccf648c8a77a339cdfe7366c1 172.16.1.100:6379 myself,master - 0 0 0 connected 0-5000

NODE2节点：
	$ vim /var/lib/redis/nodes-6379.conf
	76a6fdbc6fe619ef120cf230145cb4b43c80aeaf 172.16.1.70:6379 myself,master - 0 0 1 connected 5001-10000

NODE3节点：
	$ vim /var/lib/redis/nodes-6379.conf
	7349f132ca8cefc148b203ff3e02f8afb1692962 172.16.1.30:6379 myself,master - 0 0 2 connected 10001-16383
```


#### <font szie=4 color="#007FFF">重启redis(三台节点)</font>


```bash
$ systemctl restart redis 
```

如果重启后，查看各节点的slots不对的话，需要手动设置成如下信息：

```bash
$ vim /var/lib/redis/node-6379.conf
NODE1:
	ae97e9700ef65e6ccf648c8a77a339cdfe7366c1 172.16.1.100:6379 myself,master - 0 0 0 connected 0-5000
	7349f132ca8cefc148b203ff3e02f8afb1692962 172.16.1.30:6379 master - 0 1497917554765 2 connected 10001-16383
	76a6fdbc6fe619ef120cf230145cb4b43c80aeaf 172.16.1.70:6379 master - 0 1497917555774 1 disconnected 5001-10000

NODE2:
	76a6fdbc6fe619ef120cf230145cb4b43c80aeaf 172.16.1.70:6379 myself,master - 0 0 1 connected 5001-10000
	ae97e9700ef65e6ccf648c8a77a339cdfe7366c1 172.16.1.100:6379 master - 0 1497941001839 0 connected 0-5000
	7349f132ca8cefc148b203ff3e02f8afb1692962 172.16.1.30:6379 master - 0 1497941002952 2 connected 10001-16383

NODE3:
	ae97e9700ef65e6ccf648c8a77a339cdfe7366c1 172.16.1.100:6379 master - 0 1497941049586 0 connected 0-5000
	7349f132ca8cefc148b203ff3e02f8afb1692962 172.16.1.30:6379 myself,master - 0 0 2 connected 10001-16383
	76a6fdbc6fe619ef120cf230145cb4b43c80aeaf 172.16.1.70:6379 master - 0 1497941050596 1 connected 5001-10000
```



#### <font szie=4 color="#007FFF">重启redis，并重新meet</font>


```bash
$ systemctl restart redis
$ redis-cli -a mypass
127.0.0.1:6379> CLUSTER MEET 172.16.1.70 6379
OK
127.0.0.1:6379> CLUSTER MEET 172.16.1.30 6379
OK
127.0.0.1:6379> CLUSTER INFO
# 集群状态为OK
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
# 3个节点
cluster_known_nodes:3
cluster_size:3
cluster_current_epoch:2
cluster_my_epoch:0
cluster_stats_messages_sent:37
cluster_stats_messages_received:37
```



-------

{% note success %}### redis-trib.rb脚本搭建redis cluster
{% endnote %}

在上面的配置完初始化的配置文件后，执行如下操作

#### <font size=4 color="#32CD99">下载redis-trib.rb的ruby脚本</font>

因为从epel安装的`redis`不自带`redis-trib.rb`脚本，这时就需要我们自己去下载了

```bash
$ wget http://download.redis.io/redis-stable/src/redis-trib.rb
```

不过需要运行`ruby`脚本，我们还需要ruby环境：

```bash
$ yum install ruby ruby-devel rubygems rpm-build
```

还需要ruby连接gem的软件包

```bash
$ wget --no-check-certificate https://rubygems.org/downloads/redis-3.3.3.gem
$ gem install redis-3.3.3.gem
```


#### <font size=4 color="#32CD99">脚本使用帮助</font>

* 查看脚本帮助

```bash
$ ruby redis-trib.rb help
Usage: redis-trib <command> <options> <arguments ...>

  create          host1:port1 ... hostN:portN
                  --replicas <arg>
  check           host:port
  info            host:port
  fix             host:port
                  --timeout <arg>
  reshard         host:port
                  --from <arg>
                  --to <arg>
                  --slots <arg>
                  --yes
                  --timeout <arg>
                  --pipeline <arg>
  rebalance       host:port
                  --weight <arg>
                  --auto-weights
                  --use-empty-masters
                  --timeout <arg>
                  --simulate
                  --pipeline <arg>
                  --threshold <arg>
  add-node        new_host:new_port existing_host:existing_port
                  --slave
                  --master-id <arg>
  del-node        host:port node_id
  set-timeout     host:port milliseconds
  call            host:port command arg arg .. arg
  import          host:port
                  --from <arg>
                  --copy
                  --replace
  help            (show this help)

For check, fix, reshard, del-node, set-timeout you can specify the host and port of any working node in the cluster.
```

* 各选项详解

```bash
1、create：创建集群
2、check：检查集群
3、info：查看集群信息
4、fix：修复集群
5、reshard：在线迁移slot
6、rebalance：平衡集群节点slot数量
7、add-node：将新节点加入集群
8、del-node：从集群中删除节点
9、set-timeout：设置集群节点间心跳连接的超时时间
10、call：在集群全部节点上执行命令
11、import：将外部redis数据导入集群
```

#### <font size=4 color="#32CD99">使用脚本create创建集群</font>

* create命令可选replicas参数，replicas表示需要有几个slave。最简单命令使用如下

```bash
$ ruby redis-trib.rb create 172.16.1.100:6379 172.16.1.70:6379 172.16.1.30:6379
```

* slave节点的创建命令(需要最少6的节点，此命令)

```bash
$ ruby redis-trib.rb create --replicas 1 172.16.1.101:6379 172.16.1.102:6379 172.16.1.103:6379 
```

<br>

* 创建流程如下：

> 1、首先为每个节点创建ClusterNode对象，包括连接每个节点。检查每个节点是否为独立且db为空的节点。执行load_info方法导入节点信息。
> 2、检查传入的master节点数量是否大于等于3个。只有大于3个节点才能组成集群。
> 3、计算每个master需要分配的slot数量，以及给master分配slave。分配的算法大致如下：
    * 先把节点按照host分类，这样保证master节点能分配到更多的主机中。
    * 不停遍历遍历host列表，从每个host列表中弹出一个节点，放入interleaved数组。直到所有的节点都弹出为止。
    * master节点列表就是interleaved前面的master数量的节点列表。保存在masters数组。
    * 计算每个master节点负责的slot数量，保存在slots_per_node对象，用slot总数除以master数量取整即可。
    * 遍历masters数组，每个master分配slots_per_node个slot，最后一个master，分配到16384个slot为止。
    * 接下来为master分配slave，分配算法会尽量保证master和slave节点不在同一台主机上。对于分配完指定slave数量的节点，还有多余的节点，也会为这些节点寻找master。分配算法会遍历两次masters数组。
    * 第一次遍历masters数组，在余下的节点列表找到replicas数量个slave。每个slave为第一个和master节点host不一样的节点，如果没有不一样的节点，则直接取出余下列表的第一个节点。
    * 第二次遍历是在对于节点数除以replicas不为整数，则会多余一部分节点。遍历的方式跟第一次一样，只是第一次会一次性给master分配replicas数量个slave，而第二次遍历只分配一个，直到余下的节点被全部分配出去。

> 4、打印出分配信息，并提示用户输入“yes”确认是否按照打印出来的分配方式创建集群。
> 5、输入“yes”后，会执行flush_nodes_config操作，该操作执行前面的分配结果，给master分配slot，让slave复制master，对于还没有握手（cluster meet）的节点，slave复制操作无法完成，不过没关系，flush_nodes_config操作出现异常会很快返回，后续握手后会再次执行flush_nodes_config。
> 6、给每个节点分配epoch，遍历节点，每个节点分配的epoch比之前节点大1。
> 7、节点间开始相互握手，握手的方式为节点列表的其他节点跟第一个节点握手。
> 8、然后每隔1秒检查一次各个节点是否已经消息同步完成，使用ClusterNode的get_config_signature方法，检查的算法为获取每个节点cluster nodes信息，排序每个节点，组装成node_id1:slots|node_id2:slot2|...的字符串。如果每个节点获得字符串都相同，即认为握手成功。
> 9、此后会再执行一次flush_nodes_config，这次主要是为了完成slave复制操作。
> 10、最后再执行check_cluster，全面检查一次集群状态。包括和前面握手时检查一样的方式再检查一遍。确认没有迁移的节点。确认所有的slot都被分配出去了。
> 11、至此完成了整个创建流程，返回[OK] All 16384 slots covered.


#### <font size=4 color="#32CD99">开始创建集群</font>

* 下载redis源码包、编译安装

```bash
$ wget http://download.redis.io/releases/redis-3.2.9.tar.gz
$ tar -xf redis-3.2.9.tar.gz
$ cd redis-3.2.9
$ yum groupinstall -y "Development Tools"
$ make && make install 
```

* 修改配置文件

```bash
$ cp /root/redis-3.2.9/redis.conf /root
$ mkdir /root/cluster-test
$ cd /root/
$ mkdir -pv cluster-test/700{0,1,2,3,4,5} 

# 拷贝配置文件
$ cp /root/redis.conf /root/cluster-test/7000
$ cp /root/redis.conf /root/cluster-test/7001
$ cp /root/redis.conf /root/cluster-test/7002
$ cp /root/redis.conf /root/cluster-test/7003
$ cp /root/redis.conf /root/cluster-test/7004
$ cp /root/redis.conf /root/cluster-test/7005

#修改端口号
$ sed -i "s/6379/7000/g" /root/cluster-test/7000/redis.conf
$ sed -i "s/6379/7001/g" /root/cluster-test/7001/redis.conf
$ sed -i "s/6379/7002/g" /root/cluster-test/7002/redis.conf
$ sed -i "s/6379/7003/g" /root/cluster-test/7003/redis.conf
$ sed -i "s/6379/7004/g" /root/cluster-test/7004/redis.conf
$ sed -i "s/6379/7005/g" /root/cluster-test/7005/redis.conf

# 查看目录结构
$ tree ./
./
├── 7000
│   └── redis.conf
├── 7001
│   └── redis.conf
├── 7002
│   └── redis.conf
├── 7003
│   └── redis.conf
├── 7004
│   └── redis.conf
└── 7005
    └── redis.conf
```

* 启动节点

```bash
$ redis-server 7000/redis.conf
$ redis-server 7001/redis.conf
$ redis-server 7002/redis.conf
$ redis-server 7003/redis.conf
$ redis-server 7004/redis.conf
$ redis-server 7005/redis.conf
```

* 拷贝redis-trib.rb脚本

```bash
$ cp /root/redis-3.2.9/src/redis-trib.rb /usr/local/bin
```


* 启动脚本

```bash
$ redis-trib.rb create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005
>>> Creating cluster
>>> Performing hash slots allocation on 6 nodes...
Using 3 masters:
127.0.0.1:7000
127.0.0.1:7001
127.0.0.1:7002
Adding replica 127.0.0.1:7003 to 127.0.0.1:7000
Adding replica 127.0.0.1:7004 to 127.0.0.1:7001
Adding replica 127.0.0.1:7005 to 127.0.0.1:7002
M: db4a46c913c35fe91dc2fd06c7b4b535f7bccb80 127.0.0.1:7000
   slots:0-5460 (5461 slots) master
M: 484bec734b24bb06fb79b7c9b70487a809e951f8 127.0.0.1:7001
   slots:5461-10922 (5462 slots) master
M: 731c2c52bb535536035dc4eaf5ba962c4de611c6 127.0.0.1:7002
   slots:10923-16383 (5461 slots) master
S: e28ead4ed999bff578737f1aaa722ebd1baec40d 127.0.0.1:7003
   replicates db4a46c913c35fe91dc2fd06c7b4b535f7bccb80
S: 0b630e0f408c4f7ecc873642bb745f11e22d1095 127.0.0.1:7004
   replicates 484bec734b24bb06fb79b7c9b70487a809e951f8
S: e9b60427dafd3a8bfbd28c64da91da8403ec6060 127.0.0.1:7005
   replicates 731c2c52bb535536035dc4eaf5ba962c4de611c6
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join...
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: db4a46c913c35fe91dc2fd06c7b4b535f7bccb80 127.0.0.1:7000
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
M: 484bec734b24bb06fb79b7c9b70487a809e951f8 127.0.0.1:7001
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
S: e9b60427dafd3a8bfbd28c64da91da8403ec6060 127.0.0.1:7005
   slots: (0 slots) slave
   replicates 731c2c52bb535536035dc4eaf5ba962c4de611c6
M: 731c2c52bb535536035dc4eaf5ba962c4de611c6 127.0.0.1:7002
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 0b630e0f408c4f7ecc873642bb745f11e22d1095 127.0.0.1:7004
   slots: (0 slots) slave
   replicates 484bec734b24bb06fb79b7c9b70487a809e951f8
S: e28ead4ed999bff578737f1aaa722ebd1baec40d 127.0.0.1:7003
   slots: (0 slots) slave
   replicates db4a46c913c35fe91dc2fd06c7b4b535f7bccb80
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

#### <font size=4 color="#32CD99">check检查集群</font>

检查集群状态的命令，没有其他参数，只需要选择一个集群中的一个节点即可。执行命令如下：

```bash
$ redis-trib.rb check 127.0.0.1:7000
>>> Performing Cluster Check (using node 127.0.0.1:7000)
M: db4a46c913c35fe91dc2fd06c7b4b535f7bccb80 127.0.0.1:7000
   slots:0-5460 (5461 slots) master
   1 additional replica(s)
M: 484bec734b24bb06fb79b7c9b70487a809e951f8 127.0.0.1:7001
   slots:5461-10922 (5462 slots) master
   1 additional replica(s)
S: e9b60427dafd3a8bfbd28c64da91da8403ec6060 127.0.0.1:7005
   slots: (0 slots) slave
   replicates 731c2c52bb535536035dc4eaf5ba962c4de611c6
M: 731c2c52bb535536035dc4eaf5ba962c4de611c6 127.0.0.1:7002
   slots:10923-16383 (5461 slots) master
   1 additional replica(s)
S: 0b630e0f408c4f7ecc873642bb745f11e22d1095 127.0.0.1:7004
   slots: (0 slots) slave
   replicates 484bec734b24bb06fb79b7c9b70487a809e951f8
S: e28ead4ed999bff578737f1aaa722ebd1baec40d 127.0.0.1:7003
   slots: (0 slots) slave
   replicates db4a46c913c35fe91dc2fd06c7b4b535f7bccb80
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```



#### <font size=4 color="#32CD99">check检查集群</font>

info命令用来查看集群的信息。info命令也是先执行load_cluster_info_from_node获取完整的集群信息。然后显示ClusterNode的info_string结果，示例如下：


```bash
$ ruby redis-trib.rb info 127.0.0.1:7000
127.0.0.1:7000  (db4a46c9...) -> 0 keys | 5461 slots | 1 slaves.
127.0.0.1:7001 (484bec73...) -> 0 keys | 5462 slots | 1 slaves.
127.0.0.1:7002 (731c2c52...) -> 1 keys | 5461 slots | 1 slaves.
[OK] 1 keys in 3 masters.
0.00 keys per slot on average.
```


#### <font size=4 color="#32CD99">测试集群功能</font>

```bash
$ redis-cli -c -p 7000
127.0.0.1:7000> SET mykey maxie
-> Redirected to slot [14687] located at 127.0.0.1:7002
OK
127.0.0.1:7002> GET mykey
"maxie"
127.0.0.1:7002> exit
[root@test-1 ~]# redis-cli -c -p 7005
127.0.0.1:7005> GET mykey
-> Redirected to slot [14687] located at 127.0.0.1:7002
"maxie"
127.0.0.1:7002>
```

#### <font size=4 color="#32CD99">录屏操作</font>

<embed height="415" width="544" quality="high" allowfullscreen="true" type="application/x-shockwave-flash" src="//static.hdslb.com/miniloader.swf" flashvars="aid=12248513&page=1" pluginspage="//www.adobe.com/shockwave/download/download.cgi?P1_Prod_Version=ShockwaveFlash"></embed>

-------

### VPS测速

![](https://ws2.sinaimg.cn/large/006tNc79ly1fhltd2hclwj31dg0use4j.jpg)

-------


<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=472361236&auto=1&height=66"></iframe>

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)


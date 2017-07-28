---
title: redis-cli命令总结
date: 2017-07-16 07:39:10
tags: [redis,command,linux]
categories: [linux,command,redis]
copyright: true
---

<blockquote class="blockquote-center">Redis提供了丰富的命令（command）对数据库和各种数据类型进行操作，这些command可以在Linux终端使用。
</blockquote>

官方下载地址：[redis](https://redis.io/download)
官方文档地址：[redis文档](https://redis.io/commands)

### 连接操作相关的命令

* QUIT：关闭连接（CONNECTION）
* AUTH：简单密码认证

-------



### 对value操作的命令

* EXISTS(KEY)：确认一个KEY是否存在
* DEL(KEY)：删除一个KEY
* TYPE(KEY)：返回值的类型
* KEYS(PATTERN)：返回满足给定PATTERN的所有KEY
* RANDOMKEY：随机返回KEY空间的一个KEY
* RENAME(OLDNAME, NEWNAME)：将KEY由OLDNAME重命名为NEWNAME，若NEWNAME存在则删除NEWNAME表示的KEY
* DBSIZE：返回当前数据库中KEY的数目
* EXPIRE：设定一个KEY的活动时间（S）
* TTL：获得一个KEY的活动时间
* SELECT(INDEX)：按索引查询
* MOVE(KEY, DBINDEX)：将当前数据库中的KEY转移到有DBINDEX索引的数据库
* FLUSHDB：删除当前选择数据库中的所有KEY
* FLUSHALL：删除所有数据库中的所有KEY


-------


<!-- more -->

### 对String操作的命令

* SET(KEY, VALUE)：给数据库中名称为KEY的STRING赋予值VALUE
* GET(KEY)：返回数据库中名称为KEY的STRING的VALUE
* GETSET(KEY, VALUE)：给名称为KEY的STRING赋予上一次的VALUE
* MGET(KEY1, KEY2,…, KEY N)：返回库中多个STRING（它们的名称为KEY1，KEY2…）的VALUE
* SETNX(KEY, VALUE)：如果不存在名称为KEY的STRING，则向库中添加STRING，名称为KEY，值为VALUE
* SETEX(KEY, TIME, VALUE)：向库中添加STRING（名称为KEY，值为VALUE）同时，设定过期时间TIME
* MSET(KEY1, VALUE1, KEY2, VALUE2,…KEY N, VALUE N)：同时给多个STRING赋值，名称为KEY I的STRING赋值VALUE I
* MSETNX(KEY1, VALUE1, KEY2, VALUE2,…KEY N, VALUE N)：如果所有名称为KEY I的STRING都不存在，则向库中添加STRING，名称KEY I赋值为VALUE I
* INCR(KEY)：名称为KEY的STRING增1操作
* INCRBY(KEY, INTEGER)：名称为KEY的STRING增加INTEGER
* DECR(KEY)：名称为KEY的STRING减1操作
* DECRBY(KEY, INTEGER)：名称为KEY的STRING减少INTEGER
* APPEND(KEY, VALUE)：名称为KEY的STRING的值附加VALUE
* SUBSTR(KEY, START, END)：返回名称为KEY的STRING的VALUE的子串



-------

### 对List操作的命令

* RPUSH(KEY, VALUE)：在名称为KEY的LIST尾添加一个值为VALUE的元素
* LPUSH(KEY, VALUE)：在名称为KEY的LIST头添加一个值为VALUE的 元素
* LLEN(KEY)：返回名称为KEY的LIST的长度
* LRANGE(KEY, START, END)：返回名称为KEY的LIST中START至END之间的元素（下标从0开始，下同）
* LTRIM(KEY, START, END)：截取名称为KEY的LIST，保留START至END之间的元素
* LINDEX(KEY, INDEX)：返回名称为KEY的LIST中INDEX位置的元素
* LSET(KEY, INDEX, VALUE)：给名称为KEY的LIST中INDEX位置的元素赋值为VALUE
* LREM(KEY, COUNT, VALUE)：删除COUNT个名称为KEY的LIST中值为VALUE的元素。COUNT为0，删除所有值为VALUE的元素，COUNT>0从头至尾删除COUNT个值为VALUE的元素，COUNT<0从尾到头删除|COUNT|个值为VALUE的元素。 LPOP(KEY)：返回并删除名称为KEY的LIST中的首元素 RPOP(KEY)：返回并删除名称为KEY的LIST中的尾元素 BLPOP(KEY1, KEY2,… KEY N, TIMEOUT)：LPOP命令的BLOCK版本。即当TIMEOUT为0时，若遇到名称为KEY I的LIST不存在或该LIST为空，则命令结束。如果TIMEOUT>0，则遇到上述情况时，等待TIMEOUT秒，如果问题没有解决，则对KEYI+1开始的LIST执行POP操作。
* BRPOP(KEY1, KEY2,… KEY N, TIMEOUT)：RPOP的BLOCK版本。参考上一命令。
* RPOPLPUSH(SRCKEY, DSTKEY)：返回并删除名称为SRCKEY的LIST的尾元素，并将该元素添加到名称为DSTKEY的LIST的头部


-------


### 对Set操作的命令

* SADD key member [member ...]：设定一个集合
* SPOP key [count] ：随机弹出元素，指定个数
* SRANDMEMBER key [count] ： 随机取出成员，指定取出的个数
* SREM key member [member ...]：移除(弹出)某个元素
* SCARD key ：查看元素成员个数
* SINTER key [key ...] ： 取出几个集合的交集
* SINTERSTORE destination key [key ...]：取出交集并存储
* SUNION key [key ...]：取出并集
* SUNIONSTORE destination key [key ...]：取出并集并存储
* SDIFF key [key ...]：差集 --> 顺序很关键
* SDIFFSTORE destination key [key ...]：差集存储
* SISMEMBER key member ： 判断某个集合是否存在某个成员
* SMEMBERS key：查看一个集合的所有成员
* SMOVE source destination member：移动成员到另一个集合中


-------

### 对zset（sorted set）操作的命令

* ZADD(KEY, SCORE, MEMBER)：向名称为KEY的ZSET中添加元素MEMBER，SCORE用于排序。如果该元素已经存在，则根据SCORE更新该元素的顺序。
* ZREM(KEY, MEMBER) ：删除名称为KEY的ZSET中的元素MEMBER
* ZINCRBY(KEY, INCREMENT, MEMBER) ：如果在名称为KEY的ZSET中已经存在元素MEMBER，则该元素的SCORE增加INCREMENT；否则向集合中添加该元素，其SCORE的值为INCREMENT
* ZRANK(KEY, MEMBER) ：返回名称为KEY的ZSET（元素已按SCORE从小到大排序）中MEMBER元素的RANK（即INDEX，从0开始），若没有MEMBER元素，返回“NIL”
* ZREVRANK(KEY, MEMBER) ：返回名称为KEY的ZSET（元素已按SCORE从大到小排序）中MEMBER元素的RANK（即INDEX，从0开始），若没有MEMBER元素，返回“NIL”
* ZRANGE(KEY, START, END)：返回名称为KEY的ZSET（元素已按SCORE从小到大排序）中的INDEX从START到END的所有元素
* ZREVRANGE(KEY, START, END)：返回名称为KEY的ZSET（元素已按SCORE从大到小排序）中的INDEX从START到END的所有元素
* ZRANGEBYSCORE(KEY, MIN, MAX)：返回名称为KEY的ZSET中SCORE >= MIN且SCORE <= MAX的所有元素 ZCARD(KEY)：返回名称为KEY的ZSET的基数 ZSCORE(KEY, ELEMENT)：返回名称为KEY的ZSET中元素ELEMENT的SCORE ZREMRANGEBYRANK(KEY, MIN, MAX)：删除名称为KEY的ZSET中RANK >= MIN且RANK <= MAX的所有元素 ZREMRANGEBYSCORE(KEY, MIN, MAX) ：删除名称为KEY的ZSET中SCORE >= MIN且SCORE <= MAX的所有元素
* ZUNIONSTORE / ZINTERSTORE(DSTKEYN, KEY1,…,KEYN, WEIGHTS W1,…WN, AGGREGATE SUM|MIN|MAX)：对N个ZSET求并集和交集，并将最后的集合保存在DSTKEYN中。对于集合中每一个元素的SCORE，在进行AGGREGATE运算前，都要乘以对于的WEIGHT参数。如果没有提供WEIGHT，默认为1。默认的AGGREGATE是SUM，即结果集合中元素的SCORE是所有集合对应元素进行SUM运算的值，而MIN和MAX是指，结果集合中元素的SCORE是所有集合对应元素中最小值和最大值。


-------

### 对Hash操作的命令

* HSET(KEY, FIELD, VALUE)：向名称为KEY的HASH中添加元素FIELD<—>VALUE
* HGET(KEY, FIELD)：返回名称为KEY的HASH中FIELD对应的VALUE
* HMGET(KEY, FIELD1, …,FIELD N)：返回名称为KEY的HASH中FIELD I对应的VALUE
* HMSET(KEY, FIELD1, VALUE1,…,FIELD N, VALUE N)：向名称为KEY的HASH中添加元素FIELD I<—>VALUE I
* HINCRBY(KEY, FIELD, INTEGER)：将名称为KEY的HASH中FIELD的VALUE增加INTEGER
* HEXISTS(KEY, FIELD)：名称为KEY的HASH中是否存在键为FIELD的域
* HDEL(KEY, FIELD)：删除名称为KEY的HASH中键为FIELD的域
* HLEN(KEY)：返回名称为KEY的HASH中元素个数
* HKEYS(KEY)：返回名称为KEY的HASH中所有键
* HVALS(KEY)：返回名称为KEY的HASH中所有键对应的VALUE
* HGETALL(KEY)：返回名称为KEY的HASH中所有的键（FIELD）及其对应的VALUE


-------

### 持久化

* save：将数据同步保存到磁盘
* bgsave：将数据异步保存到磁盘
* lastsave：返回上次成功将数据保存到磁盘的Unix时戳
* shundown：将数据同步保存到磁盘，然后关闭服务



-------

### 远程服务控制

* INFO：提供服务器的信息和统计
* MONITOR：实时转储收到的请求
* SLAVEOF：改变复制策略设置
* CONFIG：在运行时配置Redis服务器


-------

### redis-cli命令

#### 语法


```bash
redis-cli [OPTIONS] [cmd [arg [arg ...]]]
```

#### 选项

```bash
-h HOST         IP
-p PORT         端口
-a PASSWORD     密码
-n DBID         默认数据库
```

#### 清空数据库子命令


```bash
FLUSHDB：Remove all keys from the current database
	清空当前数据库
FLUSHALL：Remove all keys from all databases
	清空所有数据库
```




-------

本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)




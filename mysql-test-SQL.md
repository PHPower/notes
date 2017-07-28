---
title: MySQL练习题
date: 2017-07-05 11:22:05
tags: [mysql,linux]
categories: [linux进阶,mysql]
copyright: true
---

![](https://ws2.sinaimg.cn/large/006tNbRwly1fh8z1osd1aj309t03zt8o.jpg)

<blockquote class="blockquote-center">这章节，我们对之前所学的MySQL进行一些练习，使用的模板是网络上使用的hellodb.sql
</blockquote>

[hellodb.sql下载地址](https://www.dropbox.com/s/spcnov3w3q29yhk/hellodb.sql?dl=0)

不过需要注意的是，这个模板过于老旧，现在我们使用的`MySQL/MariaDB`的默认存储引擎都是`InnoDB`存储引擎，而模板中使用的则是`MyISAM`，所以我们需要手动进行修改：

```bash
$ sed -i 's@ENGINE=MyISAM@ENGINE=InnoDB@g' hellodb.sql
```

### <font size=4 color="#38B0DE">实验环境：</font>


```bash
$ yum info mariadb
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
Installed Packages
Name        : mariadb
Arch        : x86_64
Epoch       : 1
Version     : 5.5.44
Release     : 2.el7.centos
Size        : 48 M
Repo        : installed
From repo   : anaconda
Summary     : A community developed branch of MySQL
URL         : http://mariadb.org
License     : GPLv2 with exceptions and LGPLv2 and BSD
Description : MariaDB is a community developed branch of MySQL.
            : MariaDB is a multi-user, multi-threaded SQL database server.
            : It is a client/server implementation consisting of a server daemon
            : (mysqld) and many different client programs and libraries. The
            : base package contains the standard MariaDB/MySQL client programs
            : and generic MySQL files.
```

这次我们使用的是`MariaDB 5.5.44`


**将hellodb.sql导入至数据库中：**

```
$ mysql -proot@123 < hellodb.sql
```

-------

<!-- more -->

### <font size=4 color="#3299CC">查看各需要操作的表的表结构</font>

* students表

```bash
> desc students;
+-----------+---------------------+------+-----+---------+----------------+
| Field     | Type                | Null | Key | Default | Extra          |
+-----------+---------------------+------+-----+---------+----------------+
| StuID     | int(10) unsigned    | NO   | PRI | NULL    | auto_increment |
| Name      | varchar(50)         | NO   |     | NULL    |                |
| Age       | tinyint(3) unsigned | NO   |     | NULL    |                |
| Gender    | enum('F','M')       | NO   |     | NULL    |                |
| ClassID   | tinyint(3) unsigned | YES  |     | NULL    |                |
| TeacherID | int(10) unsigned    | YES  |     | NULL    |                |
+-----------+---------------------+------+-----+---------+----------------+
6 rows in set (0.00 sec)
```

<br>

* classes表

```bash
> desc classes;
+----------+----------------------+------+-----+---------+----------------+
| Field    | Type                 | Null | Key | Default | Extra          |
+----------+----------------------+------+-----+---------+----------------+
| ClassID  | tinyint(3) unsigned  | NO   | PRI | NULL    | auto_increment |
| Class    | varchar(100)         | YES  |     | NULL    |                |
| NumOfStu | smallint(5) unsigned | YES  |     | NULL    |                |
+----------+----------------------+------+-----+---------+----------------+
3 rows in set (0.00 sec)
```

<br>

* teachers表

```bash
> desc teachers;
+--------+----------------------+------+-----+---------+----------------+
| Field  | Type                 | Null | Key | Default | Extra          |
+--------+----------------------+------+-----+---------+----------------+
| TID    | smallint(5) unsigned | NO   | PRI | NULL    | auto_increment |
| Name   | varchar(100)         | NO   |     | NULL    |                |
| Age    | tinyint(3) unsigned  | NO   |     | NULL    |                |
| Gender | enum('F','M')        | YES  |     | NULL    |                |
+--------+----------------------+------+-----+---------+----------------+
4 rows in set (0.00 sec)
```

<br>

* scores表

```bash
> desc scores;
+----------+----------------------+------+-----+---------+----------------+
| Field    | Type                 | Null | Key | Default | Extra          |
+----------+----------------------+------+-----+---------+----------------+
| ID       | int(10) unsigned     | NO   | PRI | NULL    | auto_increment |
| StuID    | int(10) unsigned     | NO   |     | NULL    |                |
| CourseID | smallint(5) unsigned | NO   |     | NULL    |                |
| Score    | tinyint(3) unsigned  | YES  |     | NULL    |                |
+----------+----------------------+------+-----+---------+----------------+
4 rows in set (0.00 sec)
```

<br>

* courese表

```bash
> desc courses;
+----------+----------------------+------+-----+---------+----------------+
| Field    | Type                 | Null | Key | Default | Extra          |
+----------+----------------------+------+-----+---------+----------------+
| CourseID | smallint(5) unsigned | NO   | PRI | NULL    | auto_increment |
| Course   | varchar(100)         | NO   |     | NULL    |                |
+----------+----------------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)
```


### <font size=4 color="#32CD99">初阶练习题</font>


* 在students表中，查询年龄大于25岁，且为男性的同学的名字和年龄

```bash
> SELECT Name,Age FROM students WHERE age > 25 AND Gender='M';
+--------------+-----+
| Name         | Age |
+--------------+-----+
| Xie Yanke    |  53 |
| Ding Dian    |  32 |
| Yu Yutong    |  26 |
| Shi Qing     |  46 |
| Tian Boguang |  33 |
| Xu Xian      |  27 |
| Sun Dasheng  | 100 |
+--------------+-----+
7 rows in set (0.00 sec)
```

<br>

* 以ClassID为分组依据，显示每组的平均年龄

```bash
> SELECT ClassID,avg(age) FROM students GROUP BY ClassID;
+---------+----------+
| ClassID | avg(age) |
+---------+----------+
|    NULL |  63.5000 |
|       1 |  20.5000 |
|       2 |  36.0000 |
|       3 |  20.2500 |
|       4 |  24.7500 |
|       5 |  46.0000 |
|       6 |  20.7500 |
|       7 |  19.6667 |
+---------+----------+
8 rows in set (0.00 sec)
```

<br>

* 显示第2题中平均年龄大于30的分组及平均年龄；

```bash
> SELECT ClassID,avg(age) AS AGE FROM students GROUP BY ClassID HAVING  AGE > 30;
+---------+---------+
| ClassID | AGE     |
+---------+---------+
|    NULL | 63.5000 |
|       2 | 36.0000 |
|       5 | 46.0000 |
+---------+---------+
3 rows in set (0.00 sec)
```

<br>

* 显示以L开头的名字的同学的信息；

```bash
> SELECT * FROM students WHERE Name RLIKE '^L.*';
+-------+-------------+-----+--------+---------+-----------+
| StuID | Name        | Age | Gender | ClassID | TeacherID |
+-------+-------------+-----+--------+---------+-----------+
|     8 | Lin Daiyu   |  17 | F      |       7 |      NULL |
|    14 | Lu Wushuang |  17 | F      |       3 |      NULL |
|    17 | Lin Chong   |  25 | M      |       4 |      NULL |
+-------+-------------+-----+--------+---------+-----------+
3 rows in set (0.00 sec)
```

<br>

* 显示TeacherID非空的同学的相关信息；

```bash
> SELECT * FROM students WHERE TeacherID is not null;
+-------+-------------+-----+--------+---------+-----------+
| StuID | Name        | Age | Gender | ClassID | TeacherID |
+-------+-------------+-----+--------+---------+-----------+
|     1 | Shi Zhongyu |  22 | M      |       2 |         3 |
|     2 | Shi Potian  |  22 | M      |       1 |         7 |
|     3 | Xie Yanke   |  53 | M      |       2 |        16 |
|     4 | Ding Dian   |  32 | M      |       4 |         4 |
|     5 | Yu Yutong   |  26 | M      |       3 |         1 |
+-------+-------------+-----+--------+---------+-----------+
5 rows in set (0.00 sec)
```

<br>

* 以年龄排序后，显示年龄最大的前10位同学的信息；

```bash
> SELECT * FROM students ORDER BY  age DESC LIMIT 10;
+-------+--------------+-----+--------+---------+-----------+
| StuID | Name         | Age | Gender | ClassID | TeacherID |
+-------+--------------+-----+--------+---------+-----------+
|    25 | Sun Dasheng  | 100 | M      |    NULL |      NULL |
|     3 | Xie Yanke    |  53 | M      |       2 |        16 |
|     6 | Shi Qing     |  46 | M      |       5 |      NULL |
|    13 | Tian Boguang |  33 | M      |       2 |      NULL |
|     4 | Ding Dian    |  32 | M      |       4 |         4 |
|    24 | Xu Xian      |  27 | M      |    NULL |      NULL |
|     5 | Yu Yutong    |  26 | M      |       3 |         1 |
|    17 | Lin Chong    |  25 | M      |       4 |      NULL |
|    23 | Ma Chao      |  23 | M      |       4 |      NULL |
|    18 | Hua Rong     |  23 | M      |       7 |      NULL |
+-------+--------------+-----+--------+---------+-----------+
10 rows in set (0.00 sec)
```

<br>

* 查询年龄大于等于20岁，小于等于25岁的同学的信息；用三种方法；

```bash
> SELECT * FROM students WHERE age>=20 and age<=25;

> SELECT * FROM students WHERE age BETWEEN 20 AND 25;

> SELECT * FROM (SELECT * FROM students WHERE age>=20) AS a  WHERE a.age <= 25;

+-------+---------------+-----+--------+---------+-----------+
| StuID | Name          | Age | Gender | ClassID | TeacherID |
+-------+---------------+-----+--------+---------+-----------+
|     1 | Shi Zhongyu   |  22 | M      |       2 |         3 |
|     2 | Shi Potian    |  22 | M      |       1 |         7 |
|     9 | Ren Yingying  |  20 | F      |       6 |      NULL |
|    11 | Yuan Chengzhi |  23 | M      |       6 |      NULL |
|    16 | Xu Zhu        |  21 | M      |       1 |      NULL |
|    17 | Lin Chong     |  25 | M      |       4 |      NULL |
|    18 | Hua Rong      |  23 | M      |       7 |      NULL |
|    21 | Huang Yueying |  22 | F      |       6 |      NULL |
|    22 | Xiao Qiao     |  20 | F      |       1 |      NULL |
|    23 | Ma Chao       |  23 | M      |       4 |      NULL |
+-------+---------------+-----+--------+---------+-----------+
10 rows in set (0.00 sec)
```

<br>

### <font size=4 color="#007FFF">中阶练习题</font>

* 以ClassID分组，显示每班的同学的人数

```bash
> SELECT Classid,count(Name) FROM students GROUP BY ClassID;
+---------+-------------+
| Classid | count(Name) |
+---------+-------------+
|    NULL |           2 |
|       1 |           4 |
|       2 |           3 |
|       3 |           4 |
|       4 |           4 |
|       5 |           1 |
|       6 |           4 |
|       7 |           3 |
+---------+-------------+
8 rows in set (0.00 sec)
```

<br>

* 以Gender分组，显示其年龄之和

```bash
> SELECT Gender,sum(Age) FROM students GROUP BY Gender; 
+--------+----------+
| Gender | sum(Age) |
+--------+----------+
| F      |      190 |
| M      |      495 |
+--------+----------+
2 rows in set (0.00 sec)
```

<br>

* 以ClassID分组，显示其平均年龄大于25的班级

```bash
> SELECT ClassID,avg(age) AS AGE FROM students GROUP BY Gender HAVING AGE > 25; 
+---------+---------+
| ClassID | AGE     |
+---------+---------+
|       2 | 33.0000 |
+---------+---------+
1 row in set (0.00 sec)
```

<br>

* 以Gender分组，显示各组中年龄大于25的学员的年龄之和

```bash
> SELECT Gender,sum(age) FROM (SELECT Age,Gender FROM students WHERE age > 25 ) as t GROUP BY Gender;
+--------+----------+
| Gender | sum(age) |
+--------+----------+
| M      |      317 |
+--------+----------+
1 row in set (0.00 sec)
```

<br>

* 显示前5位同学的姓名、课程及成绩

```bash
> SELECT Name,Course,Score FROM (SELECT * FROM students LIMIT 5) AS T1,courses AS C1,scores AS S1 WHERE T1.StuID = S1.StuID AND S1.CourseID = C1.CourseID;
+-------------+----------------+-------+
| Name        | Course         | Score |
+-------------+----------------+-------+
| Shi Zhongyu | Kuihua Baodian |    77 |
| Shi Zhongyu | Weituo Zhang   |    93 |
| Shi Potian  | Kuihua Baodian |    47 |
| Shi Potian  | Daiyu Zanghua  |    97 |
| Xie Yanke   | Kuihua Baodian |    88 |
| Xie Yanke   | Weituo Zhang   |    75 |
| Ding Dian   | Daiyu Zanghua  |    71 |
| Ding Dian   | Kuihua Baodian |    89 |
| Yu Yutong   | Hamo Gong      |    39 |
| Yu Yutong   | Dagou Bangfa   |    63 |
+-------------+----------------+-------+
10 rows in set (0.00 sec)
```

<br> 

* 显示其成绩高于80的同学的名称及课程

```bash
> SELECT Name,Course,Score FROM students AS T1,courses AS C1,(SELECT * FROM scores WHERE Score > 80) AS S1 WHERE T1.StuID = S1.StuID AND S1.CourseID = C1.CourseID;
+-------------+----------------+-------+
| Name        | Course         | Score |
+-------------+----------------+-------+
| Shi Zhongyu | Weituo Zhang   |    93 |
| Shi Potian  | Daiyu Zanghua  |    97 |
| Xie Yanke   | Kuihua Baodian |    88 |
| Ding Dian   | Kuihua Baodian |    89 |
| Shi Qing    | Hamo Gong      |    96 |
| Xi Ren      | Hamo Gong      |    86 |
| Xi Ren      | Dagou Bangfa   |    83 |
| Lin Daiyu   | Jinshe Jianfa  |    93 |
+-------------+----------------+-------+
8 rows in set (0.00 sec)
```

<br>

* 求前8位同学每位同学自己两门课的平均成绩，并按降序排列

```bash
> SELECT Name,AVG_SCORE FROM (SELECT * FROM students LIMIT 8) AS T1,(SELECT StuID,avg(score) AS AVG_SCORE FROM scores GROUP BY StuID) AS S1 WHERE T1.StuID = S1.StuID ORDER BY AVG_SCORE desc;
+-------------+-----------+
| Name        | AVG_SCORE |
+-------------+-----------+
| Shi Qing    |   96.0000 |
| Shi Zhongyu |   85.0000 |
| Xi Ren      |   84.5000 |
| Xie Yanke   |   81.5000 |
| Ding Dian   |   80.0000 |
| Lin Daiyu   |   75.0000 |
| Shi Potian  |   72.0000 |
| Yu Yutong   |   51.0000 |
+-------------+-----------+
8 rows in set (0.00 sec)
```

<br>

* 显示每门课程课程名称及学习了这门课的同学的个数

```bash
> SELECT course,count(name) FROM (SELECT Name,Course FROM students,courses,scores WHERE students.StuID = scores.StuID AND scores.CourseID = courses.CourseID) as A GROUP BY course;
+----------------+-------------+
| Course         | count(name) |
+----------------+-------------+
| Dagou Bangfa   |           2 |
| Daiyu Zanghua  |           2 |
| Hamo Gong      |           3 |
| Jinshe Jianfa  |           1 |
| Kuihua Baodian |           4 |
| Taiji Quan     |           1 |
| Weituo Zhang   |           2 |
+----------------+-------------+
7 rows in set (0.00 sec)

> SELECT courses.Course,count(StuID) FROM scores LEFT JOIN courses ON scores.CourseID = courses.CourseID GROUP BY scores.CourseID;
+----------------+--------------+
| Course         | count(StuID) |
+----------------+--------------+
| Hamo Gong      |            3 |
| Kuihua Baodian |            4 |
| Jinshe Jianfa  |            1 |
| Taiji Quan     |            1 |
| Daiyu Zanghua  |            2 |
| Weituo Zhang   |            2 |
| Dagou Bangfa   |            2 |
+----------------+--------------+
7 rows in set (0.00 sec)
```



<br>

### <font size=4 color="#38B0DE">高阶练习题</font>

* 如何显示其年龄大于平均年龄的同学的名字？

```bash
> SELECT Name,Age FROM students WHERE age > (SELECT avg(Age) From students);
+--------------+-----+
| Name         | Age |
+--------------+-----+
| Xie Yanke    |  53 |
| Ding Dian    |  32 |
| Shi Qing     |  46 |
| Tian Boguang |  33 |
| Sun Dasheng  | 100 |
+--------------+-----+
5 rows in set (0.00 sec)
```

<br>

* 如何显示其学习的课程为第1、2，4或第7门课的同学的名字？

```bash
> SELECT Name FROM students,(select DISTINCT StuID  FROM scores WHERE CourseID IN (1,2,4,7)) as s WHERE students.StuID = s.StuID;
+-------------+
| Name        |
+-------------+
| Shi Zhongyu |
| Shi Potian  |
| Xie Yanke   |
| Ding Dian   |
| Yu Yutong   |
| Shi Qing    |
| Xi Ren      |
| Lin Daiyu   |
+-------------+
8 rows in set (0.00 sec)
```

<br>

* 如何显示其成员数最少为3个的班级的同学中年龄大于同班同学平均年龄的同学？

```bash
# 等值连接
> select student.name,student.age,student.classid,class.avg_age from  (select students.name as name ,students.age as age,students.classid as classid from students,(select count(name) as num,classid as classid from students group by classid having num>=3) as first WHERE first.classid=students.classid) as student,(select avg(age) as avg_age,classid as classid from students group by classid) AS class WHERE student.age > class.avg_age AND student.ClassID = class.ClassID;
+---------------+-----+---------+---------+
| name          | age | classid | avg_age |
+---------------+-----+---------+---------+
| Shi Potian    |  22 |       1 | 20.5000 |
| Xie Yanke     |  53 |       2 | 36.0000 |
| Ding Dian     |  32 |       4 | 24.7500 |
| Yu Yutong     |  26 |       3 | 20.2500 |
| Yuan Chengzhi |  23 |       6 | 20.7500 |
| Xu Zhu        |  21 |       1 | 20.5000 |
| Lin Chong     |  25 |       4 | 24.7500 |
| Hua Rong      |  23 |       7 | 19.6667 |
| Huang Yueying |  22 |       6 | 20.7500 |
+---------------+-----+---------+---------+
9 rows in set (0.00 sec)

# 右外连接
> select student.name,student.age,student.classid,class.avg_age from  (select students.name as name ,students.age as age,students.classid as classid from students right join (select count(name) as num,classid as classid from students group by classid having num>=3) as first on first.classid=students.classid) as student,(select avg(age) as avg_age,classid as classid from students group by classid) AS class WHERE student.age >= class.avg_age AND student.ClassID = class.ClassID;
+---------------+-----+---------+---------+
| name          | age | classid | avg_age |
+---------------+-----+---------+---------+
| Shi Potian    |  22 |       1 | 20.5000 |
| Xie Yanke     |  53 |       2 | 36.0000 |
| Ding Dian     |  32 |       4 | 24.7500 |
| Yu Yutong     |  26 |       3 | 20.2500 |
| Yuan Chengzhi |  23 |       6 | 20.7500 |
| Xu Zhu        |  21 |       1 | 20.5000 |
| Lin Chong     |  25 |       4 | 24.7500 |
| Hua Rong      |  23 |       7 | 19.6667 |
| Huang Yueying |  22 |       6 | 20.7500 |
+---------------+-----+---------+---------+
9 rows in set (0.00 sec)
```

<br>

* 统计各班级中年龄大于全校同学平均年龄的同学


```bash
> SELECT Name,Age,ClassID FROM students WHERE age > (SELECT avg(age) as avg_age  FROM students);
+--------------+-----+---------+
| Name         | Age | ClassID |
+--------------+-----+---------+
| Xie Yanke    |  53 |       2 |
| Ding Dian    |  32 |       4 |
| Shi Qing     |  46 |       5 |
| Tian Boguang |  33 |       2 |
| Sun Dasheng  | 100 |    NULL |
+--------------+-----+---------+
5 rows in set (0.00 sec)
```


-------

<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=330 height=86 src="//music.163.com/outchain/player?type=2&id=29816874&auto=1&height=66"></iframe>


本文出自[Maxie's Notes](http://maxiecloud.com)博客，转载请务必保留此出处。

![](https://ww1.sinaimg.cn/large/006tNbRwly1fdzc80odsuj30gn0ilq5m.jpg)




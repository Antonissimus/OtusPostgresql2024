## Описание/Пошаговая инструкция выполнения домашнего задания:
### 1. создайте новый кластер PostgresSQL 14
Будем использовать версию 15, установленную в [домашке3](<../HW3(Физический уровень)/hw.md>)
### 2. зайдите в созданный кластер под пользователем postgres

```bash
sudo psql -h localhost -U postgres
```

### 3. создайте новую базу данных testdb

```sql
CREATE DATABASE testdb;
```

### 4. зайдите в созданную базу данных под пользователем postgres

```
postgres=# \c testdb
You are now connected to database "testdb" as user "postgres".
testdb=#
```
### 5. создайте новую схему testnm

```sql
CREATE SCHEMA testnm;
```

### 6. создайте новую таблицу t1 с одной колонкой c1 типа integer

```sql
create table t1(c1 integer);
```

### 7. вставьте строку со значением c1=1

```
testdb=# insert into t1 values(1);
INSERT 0 1
```

### 8. создайте новую роль readonly

```
testdb=# create role readonly
testdb-# ;
CREATE ROLE
```
### 9. дайте новой роли право на подключение к базе данных testdb

```
testdb=# grant connect on DATABASE testdb TO readonly;
GRANT
```

### 10. дайте новой роли право на использование схемы testnm

```
testdb=# grant usage on SCHEMA testnm to readonly;
GRANT
```

### 11. дайте новой роли право на select для всех таблиц схемы testnm

```
testdb=# grant SELECT on all TABLEs in SCHEMA testnm TO readonly;
GRANT
```
### 12. создайте пользователя testread с паролем test123

```
testdb=# CREATE USER testread with password 'test123';
CREATE ROLE
```

### 13. дайте роль readonly пользователю testread

```
testdb=# GRANT readonly TO testread;
GRANT ROLE
```
### 14. зайдите под пользователем testread в базу данных testdb

Выходим из psql и заходим снова:
```
anton@PG1:~/postgres14$ sudo psql -h localhost -U testread testdb
[sudo] password for anton:
Password for user testread:
psql (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
Type "help" for help.

testdb=>
```

### 15. сделайте select * from t1;

```
testdb=> select * from t1;
ERROR:  permission denied for table t1
```
### 16. получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)
НЕТ
### 17. напишите что именно произошло в тексте домашнего задания

### 18. у вас есть идеи почему? ведь права то дали?
Похоже что таблица t1 создалать не там где мы ожидали. В схеме public вместо testnm. А права мы накидывали именно на testnm [10](#10-дайте-новой-роли-право-на-использование-схемы-testnm)

### 19. посмотрите на список таблиц

```
testdb=> \dt
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | t1   | table | postgres
(1 row)
```
### 20. подсказка в шпаргалке под пунктом 20
ага
### 21. а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)
Роль мы явно не задавали. Взялясь роль "по умолчанию". 
### 22. вернитесь в базу данных testdb под пользователем postgres

```
anton@PG1:~/postgres14$ sudo psql -h localhost -U postgres
Password for user postgres:
psql (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
Type "help" for help.

postgres=#
```

### 23. удалите таблицу t1

```
testdb=# drop table t1;
DROP TABLE
```

### 24. создайте ее заново но уже с явным указанием имени схемы testnm

```
testdb=# create table testnm.t1(c1 integer);
CREATE TABLE
```

### 25. вставьте строку со значением c1=1

```
testdb=# insert into testnm.t1 values(1);
INSERT 0 1
```

### 26. зайдите под пользователем testread в базу данных testdb

```
anton@PG1:~/postgres14$ sudo psql -h localhost -U testread testdb
Password for user testread:
psql (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
Type "help" for help.

testdb=>
```

### 27. сделайте select * from testnm.t1;

```
testdb=> select * from testnm.t1;
ERROR:  permission denied for table t1
```

### 28. получилось?
НЕТ
### 29. есть идеи почему? если нет - смотрите шпаргалку

Думаю потому что не дали права роли на новую таблицу.

### 30. как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку

посмотрел шпаргалку:

```
testdb=# ALTER default privileges in SCHEMA testnm grant SELECT on TABLES to readonly;
ALTER DEFAULT PRIVILEGES
```
### 31. сделайте select * from testnm.t1;

```
testdb=> select * from testnm.t1;
ERROR:  permission denied for table t1
```
### 32. получилось?
нет
### 33. есть идеи почему? если нет - смотрите шпаргалку
нет....
```
testdb=> \c testdb postgres
Password for user postgres:
You are now connected to database "testdb" as user "postgres".
testdb=# grant SELECT on all TABLEs in SCHEMA testnm TO readonly;
GRANT
```

### 34. сделайте select * from testnm.t1;

```
testdb=# \c testdb testread
Password for user testread:
You are now connected to database "testdb" as user "testread".
testdb=> select * from testnm.t1;
 c1
----
  1
(1 row)


```

### 35. получилось?
да
### 36. ура!
ура...
### 37. теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);

```
testdb=> create table t2(c1 integer);
ERROR:  permission denied for schema public
LINE 1: create table t2(c1 integer);
                     ^
```

### 38. а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly? 

Вроде только на select давали, на редактирование прав нет...

### 39. есть идеи как убрать эти права? если нет - смотрите шпаргалку

Нужно создать новую роль edit, дать ей нужные права и присвоить пользователю.

### 40. если вы справились сами то расскажите что сделали и почему, если смотрели шпаргалку - объясните что сделали и почему выполнив указанные в ней команды

```
testdb=# grant CREATE ON SCHEMA testnm TO editable;
GRANT
testdb=# grant INSERT on all TABLEs in SCHEMA testnm TO editable;
GRANT
testdb=# GRANT editable TO testread;
GRANT ROLE
```
Дал нужные права в схеме testnm

### 41. теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);

```
testdb=# \c testdb testread
Password for user testread:
You are now connected to database "testdb" as user "testread".
testdb=> create table testnm.t3(c1 integer);
CREATE TABLE
testdb=> insert into testnm.t3 values (2);
INSERT 0 1
```
### 42. расскажите что получилось и почему

Поскольку пользователь testread теперь с ролью editable, он может вностить изменения в схему testnm.

Прочитав подсказку я понял что в конце сделал не то что нужно было. Запуталось..
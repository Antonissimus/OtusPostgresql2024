## Описание/Пошаговая инструкция выполнения домашнего задания:
### 1. Создаем ВМ/докер c ПГ.

Используем имеющуюся.

### 2. Создаем БД, схему и в ней таблицу.

```
anton@pg1:~$ sudo -u postgres psql
psql (16.6 (Ubuntu 16.6-0ubuntu0.24.04.1))
Type "help" for help.

postgres=# CREATE DATABASE testdb;
CREATE DATABASE
postgres=# \c testdb
You are now connected to database "testdb" as user "postgres".
testdb=# CREATE SCHEMA testschema;
CREATE SCHEMA
testdb=# CREATE TABLE testschema.testtable (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INT
);
CREATE TABLE
testdb=#

```
### 3. Заполним таблицы автосгенерированными 100 записями.
```
testdb=# INSERT INTO testschema.testtable (name, age)
SELECT
    'Name' || generate_series(1, 100),
    floor(random() * 100)::int
FROM generate_series(1, 100);
INSERT 0 10000
testdb=# select * from testschema.testtable limit 10;
 id |  name  | age
----+--------+-----
  1 | Name1  |   3
  2 | Name2  |  91
  3 | Name3  |  12
  4 | Name4  |  77
  5 | Name5  |  10
  6 | Name6  |  80
  7 | Name7  |  13
  8 | Name8  |  91
  9 | Name9  |  40
 10 | Name10 |  92
(10 rows)

testdb=#
```
### 4. Под линукс пользователем Postgres создадим каталог для бэкапов
```bash
sudo -u postgres mkdir -p /mnt/data/backups
```
### 5. Сделаем логический бэкап используя утилиту COPY
```bash
anton@pg1:~$ sudo -u postgres psql -d testdb -c "COPY testschema.testtable TO '/mnt/data/backups/testtable_backup.csv' WITH CSV HEADER;"
```
```bash
sudo cat /mnt/data/backups/testtable_backup.csv | head
```
```
id,name,age
1,Name1,3
2,Name2,91
3,Name3,12
4,Name4,77
5,Name5,10
6,Name6,80
7,Name7,13
8,Name8,91
9,Name9,40
```
### 6. Восстановим в 2 таблицу данные из бэкапа.

```sql
CREATE TABLE testschema.testtable2 (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INT
);
```

```bash
sudo -u postgres psql -d testdb -c "COPY testschema.testtable2 FROM '/mnt/data/backups/testtable_backup.csv' WITH CSV HEADER;"
```
Проверим:
```
testdb=# select * from testschema.testtable2 limit 10;
 id |  name  | age
----+--------+-----
  1 | Name1  |   3
  2 | Name2  |  91
  3 | Name3  |  12
  4 | Name4  |  77
  5 | Name5  |  10
  6 | Name6  |  80
  7 | Name7  |  13
  8 | Name8  |  91
  9 | Name9  |  40
 10 | Name10 |  92
(10 rows)

```

### 7. Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц

```bash
sudo -u postgres pg_dump -d testdb -t testschema.testtable -t testschema.testtable2 -F c -b -v -f /mnt/data/backups/testdb_tables_backup.custom
```
### 8. Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!
Проверим что есть в бэкапе
```
anton@pg1:~$ sudo -u postgres pg_restore --list /mnt/data/backups/testdb_tables_backup.custom
;
; Archive created at 2025-02-01 12:27:15 UTC
;     dbname: testdb
;     TOC Entries: 18
;     Compression: gzip
;     Dump Version: 1.15-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 16.6 (Ubuntu 16.6-0ubuntu0.24.04.1)
;     Dumped by pg_dump version: 16.6 (Ubuntu 16.6-0ubuntu0.24.04.1)
;
;
; Selected TOC Entries:
;
217; 1259 16404 TABLE testschema testtable postgres
219; 1259 16411 TABLE testschema testtable2 postgres
218; 1259 16410 SEQUENCE testschema testtable2_id_seq postgres
3412; 0 0 SEQUENCE OWNED BY testschema testtable2_id_seq postgres
216; 1259 16403 SEQUENCE testschema testtable_id_seq postgres
3413; 0 0 SEQUENCE OWNED BY testschema testtable_id_seq postgres
3253; 2604 16407 DEFAULT testschema testtable id postgres
3254; 2604 16414 DEFAULT testschema testtable2 id postgres
3403; 0 16404 TABLE DATA testschema testtable postgres
3405; 0 16411 TABLE DATA testschema testtable2 postgres
3414; 0 0 SEQUENCE SET testschema testtable2_id_seq postgres
3415; 0 0 SEQUENCE SET testschema testtable_id_seq postgres
3258; 2606 16416 CONSTRAINT testschema testtable2 testtable2_pkey postgres
3256; 2606 16409 CONSTRAINT testschema testtable testtable_pkey postgres
```

Создадим новую базу:
```sql
CREATE DATABASE testdb_new;
CREATE SCHEMA testschema;
```

Восстановим вторую таблицу:
```bash
sudo -u postgres pg_restore -d testdb_new -t testschema.testtable2 /mnt/data/backups/testdb_tables_backup.custom
```
Тут возник затык - ошибок нет и при этом ничего не восстановилось.

Если восстанавливать всю схему, то срабатывает:
```bash
sudo -u postgres pg_restore -d testdb_new -n testschema /mnt/data/backups/testdb_tables_backup.custom
```
Короче так и не понял почему...(



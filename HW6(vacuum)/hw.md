## Описание/Пошаговая инструкция выполнения домашнего задания:
### 1. Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB
Будем использовать локальную vm в hyper-v:
2CPU, 4096RAM
### 2. Установить на него PostgreSQL 15 с дефолтными настройками
```
root@PG1:/home/anton# sudo -u postgres pg_lsclusters 15 main status
Ver Cluster Port Status Owner    Data directory   Log file
15  main    5432 online postgres /mnt/pgdata/main /var/log/postgresql/postgresql-15-main.log
```
### 3. Создать БД для тестов: выполнить pgbench -i postgres
```
root@PG1:/home/anton# sudo -u postgres pgbench -i postgres
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.23 s (drop tables 0.02 s, create tables 0.01 s, client-side generate 0.09 s, vacuum 0.05 s, primary keys 0.05 s).
```

### 4. Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres
```
root@PG1:/home/anton# sudo -u postgres pgbench -c8 -P 6 -T 60 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 6.0 s, 784.0 tps, lat 10.152 ms stddev 6.681, 0 failed
progress: 12.0 s, 810.0 tps, lat 9.873 ms stddev 6.321, 0 failed
progress: 18.0 s, 811.8 tps, lat 9.851 ms stddev 6.289, 0 failed
progress: 24.0 s, 780.8 tps, lat 10.241 ms stddev 6.701, 0 failed
progress: 30.0 s, 773.7 tps, lat 10.339 ms stddev 6.952, 0 failed
progress: 36.0 s, 777.5 tps, lat 10.285 ms stddev 6.588, 0 failed
progress: 42.0 s, 745.5 tps, lat 10.727 ms stddev 7.402, 0 failed
progress: 48.0 s, 768.7 tps, lat 10.406 ms stddev 6.743, 0 failed
progress: 54.0 s, 728.0 tps, lat 10.984 ms stddev 7.743, 0 failed
progress: 60.0 s, 529.2 tps, lat 15.109 ms stddev 11.221, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 45063
number of failed transactions: 0 (0.000%)
latency average = 10.646 ms
latency stddev = 7.335 ms
initial connection time = 22.427 ms
tps = 751.048811 (without initial connection time)
```
### 5. Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
готово
### 6. Протестировать заново
```
root@PG1:/home/anton# sudo -u postgres pgbench -c8 -P 6 -T 60 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 6.0 s, 742.8 tps, lat 10.713 ms stddev 7.269, 0 failed
progress: 12.0 s, 813.7 tps, lat 9.825 ms stddev 6.385, 0 failed
progress: 18.0 s, 791.0 tps, lat 10.116 ms stddev 6.678, 0 failed
progress: 24.0 s, 784.2 tps, lat 10.192 ms stddev 6.937, 0 failed
progress: 30.0 s, 729.8 tps, lat 10.962 ms stddev 7.095, 0 failed
progress: 36.0 s, 693.5 tps, lat 11.528 ms stddev 7.924, 0 failed
progress: 42.0 s, 694.3 tps, lat 11.518 ms stddev 7.797, 0 failed
progress: 48.0 s, 730.7 tps, lat 10.943 ms stddev 7.086, 0 failed
progress: 54.0 s, 717.7 tps, lat 11.138 ms stddev 7.379, 0 failed
progress: 60.0 s, 697.2 tps, lat 11.480 ms stddev 7.792, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 44377
number of failed transactions: 0 (0.000%)
latency average = 10.810 ms
latency stddev = 7.250 ms
initial connection time = 23.812 ms
tps = 739.658088 (without initial connection time)
```
### 7. Что изменилось и почему?
Особо ничего не помянялось.... Видимо из-за отсутствия дефицита ресурсов (4G RAM) и небольшого количества параллельных сессий ... 
### 8. Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
```
postgres=# CREATE SCHEMA otus;
CREATE TABLE otus.users (Name varchar);
CREATE SCHEMA
CREATE TABLE
postgres=# select count(*) from otus.users;
  count
---------
 1000000
(1 row)
```

### 9. Посмотреть размер файла с таблицей
```
postgres=# SELECT pg_size_pretty(pg_total_relation_size('otus.users'));
 pg_size_pretty
----------------
 65 MB
(1 row)
```

### 10. 5 раз обновить все строчки и добавить к каждой строчке любой символ
```sql
-- выполняем 5 раз
UPDATE otus.users SET "name" = left("name", length("name") - 1);
```
```
postgres=# SELECT pg_size_pretty(pg_total_relation_size('otus.users'));
 pg_size_pretty
----------------
 329 MB
(1 row)
```

### 11. Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум
```sql
SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'users';
```
```
relname|n_live_tup|n_dead_tup|ratio%|last_autovacuum              |
-------+----------+----------+------+-----------------------------+
users  |   1000000|         0|   0.0|2024-11-03 18:26:02.751 +0300|
```
### 12. Подождать некоторое время, проверяя, пришел ли автовакуум
Пришел.
### 13. 5 раз обновить все строчки и добавить к каждой строчке любой символ
```sql
-- выполняем 5 раз
UPDATE otus.users SET "name" = left("name", length("name") - 1);
```
### 14. Посмотреть размер файла с таблицей
```
postgres=# SELECT pg_size_pretty(pg_total_relation_size('otus.users'));
 pg_size_pretty
----------------
 329 MB
(1 row)
```
### 15. Отключить Автовакуум на конкретной таблице
```sql
ALTER TABLE otus.users SET (autovacuum_enabled = off);

```
### 16. 10 раз обновить все строчки и добавить к каждой строчке любой символ
```sql
-- выполняем 10 раз
UPDATE otus.users SET "name" = left("name", length("name") - 1);
```
### 17. Посмотреть размер файла с таблицей
```
postgres=# SELECT pg_size_pretty(pg_total_relation_size('otus.users'));
 pg_size_pretty
----------------
 457 MB
(1 row)
```
### 18. Объясните полученный результат
Мертвые строки сохраняются в таблице пустыми и заполняются при последующих апдейтах. Размер увеличился, поскольку мы увеличили кол-во апдейтов в 2 раза.
### 19. Не забудьте включить автовакуум)
```sql
ALTER TABLE otus.users SET (autovacuum_enabled = on);
```
```
relname|n_live_tup|n_dead_tup|ratio%|last_autovacuum              |
-------+----------+----------+------+-----------------------------+
users  |   1000000|         0|   0.0|2024-11-03 18:56:10.113 +0300|
```
```
postgres=# SELECT pg_size_pretty(pg_total_relation_size('otus.users'));
 pg_size_pretty
----------------
 457 MB
(1 row)
```

### 20. Задание со * - Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице. Не забыть вывести номер шага цикла.
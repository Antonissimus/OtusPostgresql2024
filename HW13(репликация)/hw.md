## Описание/Пошаговая инструкция выполнения домашнего задания:
### 1. На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение.

Делаем базу repldb на первой виртуалке и подключаемся к ней:
```
testdb_new=# CREATE database repldb;
CREATE DATABASE
testdb_new=# \c repldb
You are now connected to database "repldb" as user "postgres".
```
Создаем 2 таблицы:
```
CREATE TABLE test (
    id SERIAL PRIMARY KEY,
    data TEXT
);

CREATE TABLE test2 (
    id SERIAL PRIMARY KEY,
    data TEXT
);
```
Создадим пользователя и дадим ему права:
```
CREATE USER repl_user WITH REPLICATION ENCRYPTED PASSWORD '12345';
GRANT ALL PRIVILEGES ON DATABASE repldb TO repl_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test TO repl_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test2 TO repl_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test TO repl_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test2 TO repl_user;
GRANT USAGE, SELECT ON SEQUENCE test_id_seq TO repl_user;
GRANT USAGE, SELECT ON SEQUENCE test2_id_seq TO repl_user;

```


### 2. Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2.
Создаем публикацию test на ВМ1:
```
repldb=# CREATE PUBLICATION pub_test FOR TABLE test;
WARNING:  wal_level is insufficient to publish logical changes
HINT:  Set wal_level to "logical" before creating subscriptions.
CREATE PUBLICATION
```
необходимо подправить конфигурацию перезапустить сервер.


### 3. На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение.

Проделываем на второй похожие шаги:
```
postgres=# CREATE database repldb;
CREATE DATABASE
postgres=# \c repldb;
You are now connected to database "repldb" as user "postgres".
repldb=# CREATE TABLE test (
    id SERIAL PRIMARY KEY,
    data TEXT
);

CREATE TABLE test2 (
    id SERIAL PRIMARY KEY,
    data TEXT
);
CREATE TABLE
CREATE TABLE
repldb=# CREATE USER repl_user WITH REPLICATION ENCRYPTED PASSWORD '12345';
GRANT ALL PRIVILEGES ON DATABASE repldb TO repl_user;
CREATE ROLE
GRANT
repldb=# GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test TO repl_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test2 TO repl_user;
GRANT
GRANT
repldb=# GRANT USAGE, SELECT ON SEQUENCE test_id_seq TO repl_user;
GRANT USAGE, SELECT ON SEQUENCE test2_id_seq TO repl_user;
GRANT
GRANT
repldb=#
```
Подписывемся на test с первой виртуалки
```
repldb=# CREATE SUBSCRIPTION sub_test
CONNECTION 'host=192.168.1.106 port=5555 user=repl_user password=12345 dbname=repldb'
PUBLICATION pub_test;
NOTICE:  created replication slot "sub_test" on publisher
CREATE SUBSCRIPTION
repldb=#
```



### 4. Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ 1.
Создаем публикацию test на ВМ2:
```
CREATE PUBLICATION pub_test2 FOR TABLE test2;
```
Делаем подписку с ВМ1:
```
CREATE SUBSCRIPTION sub_test2
CONNECTION 'host=192.168.1.107 port=5555 user=repl_user password=repl_password dbname=repldb'
PUBLICATION pub_test2;
```

### 5. 3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ 1 и 2 ).

Проделываем на третьей похожие шаги:
```
postgres=# CREATE database repldb;
CREATE DATABASE
postgres=# \c repldb;
You are now connected to database "repldb" as user "postgres".
repldb=# CREATE TABLE test (
    id SERIAL PRIMARY KEY,
    data TEXT
);

CREATE TABLE test2 (
    id SERIAL PRIMARY KEY,
    data TEXT
);
CREATE TABLE
CREATE TABLE
repldb=# CREATE USER repl_user WITH REPLICATION ENCRYPTED PASSWORD '12345';
GRANT ALL PRIVILEGES ON DATABASE repldb TO repl_user;
CREATE ROLE
GRANT
repldb=# GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test TO repl_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE test2 TO repl_user;
GRANT
GRANT
repldb=# GRANT USAGE, SELECT ON SEQUENCE test_id_seq TO repl_user;
GRANT USAGE, SELECT ON SEQUENCE test2_id_seq TO repl_user;
GRANT
GRANT
repldb=#
```
Подписываемся:
```
CREATE SUBSCRIPTION sub_test_vm1
CONNECTION 'host=192.168.1.106 port=5555 user=repl_user password=12345 dbname=repldb'
PUBLICATION pub_test;

CREATE SUBSCRIPTION sub_test2_vm2
CONNECTION 'host=192.168.1.107 port=5555 user=repl_user password=12345 dbname=repldb'
PUBLICATION pub_test2;
```
Сделаем небольшую проверку, вставим строку на ВМ1:
```
INSERT INTO test (data) VALUES ('Data from VM 1')
```
вставим строку на ВМ2:
```
INSERT INTO test2 (data) VALUES ('Data from VM 2')
```
Проверим на 1й:
```
repldb=# select * from test2;
 id |          data
----+------------------------
  1 | Data from VM 2
(1 row)
```
Теперь на второй:
```
repldb=# select * from test;
 id |          data
----+------------------------
  3 | Data from VM 1
(1 row)
```

На третью тоже всё доехало

### * реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ 3. Написать с какими проблемами столкнулись.
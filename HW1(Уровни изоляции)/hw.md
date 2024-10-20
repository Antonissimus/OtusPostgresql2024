### По поводу виртуальных машин
Виртуальная машина создана в hyper V на ноутбуке.
Установлен docker и загружен образ postgres:15.
Создание сервера и сессий описано в  [hw2](<../HW2(Установка PostgreSql)/hw.md>).
Используется схема otus, созданная в [hw2](<../HW2(Установка PostgreSql)/hw.md>).

### Процесс выполнения
1. Запущено 2 сессии.
2. В каждой сессий запущена команда
```sql
\set AUTOCOMMIT off
```
3. В первой сессии выполняем команды
```sql
create table otus.persons2(id serial, first_name text, second_name text); 
insert into otus.persons2(first_name, second_name) values('ivan', 'ivanov'); 
insert into otus.persons2(first_name, second_name) values('petr', 'petrov');
commit;
```
4. Проверяем текущий уровень изоляции:
```
otusdb=# show transaction isolation level;
 transaction_isolation
-----------------------
 read committed
(1 row)

otusdb=#
```
5. Делаем новый запрос в первой сессии:
```sql
 insert into otus.persons2(first_name, second_name) values('sergey', 'sergeev');
```
6. Делаем select во второй сессии:
```
otusdb=# select * from otus.persons2;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
7. Новая запись не видна во второй сессии, поскольку транзакция в первой еще не завершена. 
8. Завершаем транзакцию в первой сессии.
9. Делаем select во второй сессии:
```
otusdb=*# select * from otus.persons2;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```
10. Запись теперь видна, тк транзакция завершилась и данные записались из памяти в таблицу.
11. Запускаем новые сессии:
```sql
set transaction isolation level repeatable read;
```

12. Выполняем команду в первой сессии:
```sql
insert into otus.persons2(first_name, second_name) values('sveta', 'svetova');
```
13. Делаем select во второй сессии:
```
otusdb=*# select * from otus.persons2;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```
14. Поскольку транзакция не завершена
15. коммитим первую сессию и снова селект:
```
otusdb=*# select * from otus.persons2;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
```
16. транзакция в первой завершилась, но из-за того что мы не завершили транзакцию во второй сессии и видим данные до начала транзакции
17. После завершения видим обновленные данные:
```
otusdb=*# commit;
COMMIT
otusdb=# select * from otus.persons2;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
  4 | sveta      | svetova
(4 rows)
```
Теперь не осталось открытых транзакция и все данные сохранены в таблице.


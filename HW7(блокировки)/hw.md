## Описание/Пошаговая инструкция выполнения домашнего задания:
### 1. Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.

Добавим в файл postgresql.conf следующие строки:
```ini
log_lock_waits = on
deadlock_timeout = 200ms
```
Перезапустим контейнер чтобы примениить изменения:
```
anton@vm-git:~/postgres$ sudo docker compose restart
[+] Restarting 1/1
 ✔ Container postgres  Started
```
### 2. Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.

Создадим временную таблицу 
```sql
CREATE TABLE test_table (id SERIAL PRIMARY KEY, value INT);
INSERT INTO test_table (value) VALUES (1);
```
откроем три сеанса и в каждом выполним UPDATE:

в 1м (pid 476)
```
test=# BEGIN;
UPDATE test_table SET value = 10 WHERE id = 1;
BEGIN
UPDATE 1
test=*#
```
во 2м (pid 477)
```
test=# BEGIN;
UPDATE test_table SET value = 20 WHERE id = 1;
BEGIN
```
в 3м (pid 479)
```
test=# BEGIN;
UPDATE test_table SET value = 30 WHERE id = 1;
BEGIN
```
Первый UPDATE выполниkся успешно, а остальные будут ждать, пока первая транзакция не завершится

Посмотрим на блокировки:
```sql
SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'test_table'::regclass order by pid;
```
результат:
```
locktype|relation  |mode            |granted|pid|wait_for|
--------+----------+----------------+-------+---+--------+
relation|test_table|RowExclusiveLock|true   |476|{}      |
relation|test_table|RowExclusiveLock|true   |477|{476}   |
tuple   |test_table|ExclusiveLock   |true   |477|{476}   |
relation|test_table|RowExclusiveLock|true   |479|{477}   |
tuple   |test_table|ExclusiveLock   |false  |479|{477}   |
```
*locktype* - тип заблокированого объекта  (таблица, строка)
*relation* - конкретный объект 
*mode* - режим блокировки 
*granted* - флаг выдана блокировка или нет

Видно, что первый сеанс (476) блокирует другие два. Также понятно, что цепочка такая 476 <- 477 <- 479. 

после коммита первой сессии:
```
locktype|relation  |mode            |granted|pid|wait_for|
--------+----------+----------------+-------+---+--------+
relation|test_table|RowExclusiveLock|true   |477|{}      |
relation|test_table|RowExclusiveLock|true   |479|{477}   |
tuple   |test_table|ExclusiveLock   |true   |479|{477}   |
```
после коммита второй сессии:
```
locktype|relation  |mode            |granted|pid|wait_for|
--------+----------+----------------+-------+---+--------+
relation|test_table|RowExclusiveLock|true   |479|{}      |
```

Посмотрим что в логах:
```
2025-01-31 12:34:47.757 UTC [477] LOG:  process 477 still waiting for ShareLock on transaction 2032 after 200.144 ms
2025-01-31 12:34:47.757 UTC [477] DETAIL:  Process holding the lock: 476. Wait queue: 477.
2025-01-31 12:34:47.757 UTC [477] CONTEXT:  while updating tuple (0,1) in relation "test_table"
2025-01-31 12:34:47.757 UTC [477] STATEMENT:
        UPDATE test_table SET value = 20 WHERE id = 1
2025-01-31 12:34:53.035 UTC [479] LOG:  process 479 still waiting for ExclusiveLock on tuple (0,1) of relation 17722 of database 16384 after 200.140 ms
2025-01-31 12:34:53.035 UTC [479] DETAIL:  Process holding the lock: 477. Wait queue: 479.
2025-01-31 12:34:53.035 UTC [479] STATEMENT:
        UPDATE test_table SET value = 30 WHERE id = 1
2025-01-31 12:35:49.458 UTC [27] LOG:  checkpoint starting: time
2025-01-31 12:35:53.202 UTC [27] LOG:  checkpoint complete: wrote 37 buffers (0.2%); 0 WAL file(s) added, 0 removed, 0 recycled; write=3.717 s, sync=0.005 s, total=3.744 s; sync files=31, longest=0.004 s, average=0.001 s; distance=149 kB, estimate=1388 kB; lsn=0/2ED1218, redo lsn=0/2ED11D8
2025-01-31 12:44:38.641 UTC [477] LOG:  process 477 acquired ShareLock on transaction 2032 after 591083.254 ms
2025-01-31 12:44:38.641 UTC [477] CONTEXT:  while updating tuple (0,1) in relation "test_table"
2025-01-31 12:44:38.641 UTC [477] STATEMENT:
        UPDATE test_table SET value = 20 WHERE id = 1
2025-01-31 12:44:38.642 UTC [479] LOG:  process 479 acquired ExclusiveLock on tuple (0,1) of relation 17722 of database 16384 after 585807.534 ms
2025-01-31 12:44:38.642 UTC [479] STATEMENT:
        UPDATE test_table SET value = 30 WHERE id = 1
2025-01-31 12:44:38.844 UTC [479] LOG:  process 479 still waiting for ShareLock on transaction 2033 after 201.857 ms
2025-01-31 12:44:38.844 UTC [479] DETAIL:  Process holding the lock: 477. Wait queue: 479.
2025-01-31 12:44:38.844 UTC [479] CONTEXT:  while locking tuple (0,2) in relation "test_table"
2025-01-31 12:44:38.844 UTC [479] STATEMENT:
        UPDATE test_table SET value = 30 WHERE id = 1
2025-01-31 12:45:36.591 UTC [479] LOG:  process 479 acquired ShareLock on transaction 2033 after 57947.954 ms
2025-01-31 12:45:36.591 UTC [479] CONTEXT:  while locking tuple (0,2) in relation "test_table"
2025-01-31 12:45:36.591 UTC [479] STATEMENT:
        UPDATE test_table SET value = 30 WHERE id = 1
2025-01-31 12:45:49.398 UTC [27] LOG:  checkpoint starting: time
2025-01-31 12:45:49.745 UTC [27] LOG:  checkpoint complete: wrote 4 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.306 s, sync=0.007 s, total=0.346 s; sync files=4, longest=0.004 s, average=0.002 s; distance=0 kB, estimate=1249 kB; lsn=0/2ED1538, redo lsn=0/2ED1500
```
По логу эта цепочка тоже прослеживается.

### 3. Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?



в 1м (pid 10688)
```
BEGIN;
UPDATE test_table SET value = 10 WHERE id = 1;
```
во 2м (pid 10690)
```
BEGIN;
UPDATE test_table SET value = 20 WHERE id = 2;
UPDATE test_table SET value = 30 WHERE id = 1;
```
в 3м (pid 10692)
```
BEGIN;
UPDATE test_table SET value = 40 WHERE id = 3;
UPDATE test_table SET value = 50 WHERE id = 2;
```

снова в 1м (pid 10688)
```
BEGIN;
UPDATE test_table SET value = 10 WHERE id = 3;
```
```
ERROR:  deadlock detected
DETAIL:  Process 10688 waits for ShareLock on transaction 777; blocked by process 10692.
Process 10692 waits for ShareLock on transaction 776; blocked by process 10690.
Process 10690 waits for ShareLock on transaction 775; blocked by process 10688.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,15) in relation "test_table"
```

Посмотрим что в логах:
```
2025-02-01 11:07:57.373 UTC [10690] prsuser@prsdb LOG:  process 10690 still waiting for ShareLock on transaction 775 after 200.351 ms
2025-02-01 11:07:57.373 UTC [10690] prsuser@prsdb DETAIL:  Process holding the lock: 10688. Wait queue: 10690.
2025-02-01 11:07:57.373 UTC [10690] prsuser@prsdb CONTEXT:  while updating tuple (0,13) in relation "test_table"
2025-02-01 11:07:57.373 UTC [10690] prsuser@prsdb STATEMENT:  UPDATE test_table SET value = 30 WHERE id = 1
2025-02-01 11:08:29.883 UTC [10692] prsuser@prsdb LOG:  process 10692 still waiting for ShareLock on transaction 776 after 200.440 ms
2025-02-01 11:08:29.883 UTC [10692] prsuser@prsdb DETAIL:  Process holding the lock: 10690. Wait queue: 10692.
2025-02-01 11:08:29.883 UTC [10692] prsuser@prsdb CONTEXT:  while updating tuple (0,14) in relation "test_table"
2025-02-01 11:08:29.883 UTC [10692] prsuser@prsdb STATEMENT:  UPDATE test_table SET value = 50 WHERE id = 2
2025-02-01 11:08:50.369 UTC [10688] prsuser@prsdb WARNING:  there is already a transaction in progress
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb LOG:  process 10688 detected deadlock while waiting for ShareLock on transaction 777 after 200.219 ms
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb DETAIL:  Process holding the lock: 10692. Wait queue: .
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb CONTEXT:  while updating tuple (0,15) in relation "test_table"
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb STATEMENT:  UPDATE test_table SET value = 10 WHERE id = 3
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb ERROR:  deadlock detected
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb DETAIL:  Process 10688 waits for ShareLock on transaction 777; blocked by process 10692.
        Process 10692 waits for ShareLock on transaction 776; blocked by process 10690.
        Process 10690 waits for ShareLock on transaction 775; blocked by process 10688.
        Process 10688: UPDATE test_table SET value = 10 WHERE id = 3
        Process 10692: UPDATE test_table SET value = 50 WHERE id = 2
        Process 10690: UPDATE test_table SET value = 30 WHERE id = 1
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb HINT:  See server log for query details.
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb CONTEXT:  while updating tuple (0,15) in relation "test_table"
2025-02-01 11:08:50.587 UTC [10688] prsuser@prsdb STATEMENT:  UPDATE test_table SET value = 10 WHERE id = 3
2025-02-01 11:08:50.587 UTC [10690] prsuser@prsdb LOG:  process 10690 acquired ShareLock on transaction 775 after 53414.509 ms
2025-02-01 11:08:50.587 UTC [10690] prsuser@prsdb CONTEXT:  while updating tuple (0,13) in relation "test_table"
2025-02-01 11:08:50.587 UTC [10690] prsuser@prsdb STATEMENT:  UPDATE test_table SET value = 30 WHERE id = 1

```

Можно увидеть, что виновник взаимной блокировки процесс 10692: Process holding the lock: 10692. Также видно какие запросы привели к блокировке.

Process 10688: UPDATE test_table SET value = 10 WHERE id = 3
Process 10692: UPDATE test_table SET value = 50 WHERE id = 2
Process 10690: UPDATE test_table SET value = 30 WHERE id = 1

### 4. Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?
Да, могут.  

Если PostgreSQL решит использовать блокировку на уровне таблицы (например, AccessExclusiveLock), то первая транзакция, начавшая UPDATE, заблокирует всю таблицу. Вторая транзакция будет ждать, пока первая не завершится. В этом случае взаимная блокировка невозможна, так как вторая транзакция просто будет ждать. 

Если UPDATE выполняется на таблице с большим количеством строк, PostgreSQL может блокировать строки по одной (RowExclusiveLock). В этом случае две транзакции могут начать блокировать разные строки, и если они попытаются заблокировать строки, уже заблокированные другой транзакцией, это может привести к взаимной блокировке.


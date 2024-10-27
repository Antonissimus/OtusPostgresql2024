## Описание/Пошаговая инструкция выполнения домашнего задания:
### 1. Развернуть виртуальную машину любым удобным способом

Будем использовать локальную vm в hyper-v:
2CPU, 2048RAM

### 2. Поставить на неё PostgreSQL 15 любым способом

Будем использовать postgres 15, установленный на хост в прошлых домашках.

### 3. Настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины

Перед настройкой инициализируем и снимем начальные показания pgbench:
```
postgres@PG1:/home/anton$ pgbench -i
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.09 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.27 s (drop tables 0.00 s, create tables 0.02 s, client-side generate 0.15 s, vacuum 0.05 s, primary keys 0.05 s).
postgres@PG1:/home/anton$ pgbench
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
maximum number of tries: 1
number of transactions per client: 10
number of transactions actually processed: 10/10
number of failed transactions: 0 (0.000%)
latency average = 2.573 ms
initial connection time = 2.803 ms
tps = 388.606070 (without initial connection time)
```
# **tps = 388.606070**

Запуск с параметрами:

```
postgres@PG1:/home/anton$ pgbench -c 50 -j 2 -P 60 -T 600 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 60.0 s, 682.7 tps, lat 73.047 ms stddev 94.864, 0 failed
progress: 120.0 s, 644.4 tps, lat 77.486 ms stddev 101.311, 0 failed
progress: 180.0 s, 650.1 tps, lat 77.006 ms stddev 92.028, 0 failed
progress: 240.0 s, 606.0 tps, lat 82.535 ms stddev 105.369, 0 failed
progress: 300.0 s, 601.6 tps, lat 83.060 ms stddev 126.373, 0 failed
progress: 360.0 s, 612.1 tps, lat 81.673 ms stddev 100.578, 0 failed
progress: 420.0 s, 598.8 tps, lat 83.483 ms stddev 108.495, 0 failed
progress: 480.0 s, 659.2 tps, lat 75.884 ms stddev 94.270, 0 failed
progress: 540.0 s, 629.2 tps, lat 79.456 ms stddev 100.795, 0 failed
progress: 600.0 s, 650.1 tps, lat 76.916 ms stddev 96.886, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 380108
number of failed transactions: 0 (0.000%)
latency average = 78.921 ms
latency stddev = 102.283 ms
initial connection time = 71.352 ms
tps = 633.449562 (without initial connection time)
```

# **tps = 633.449562**


Исходные значения параметров:
```
name                |setting|unit|context   |sourcefile                             |sourceline|
--------------------+-------+----+----------+---------------------------------------+----------+
checkpoint_timeout  |300    |s   |sighup    |                                       |          |
effective_cache_size|524288 |8kB |user      |                                       |          |
log_checkpoints     |on     |    |sighup    |                                       |          |
maintenance_work_mem|65536  |kB  |user      |                                       |          |
max_connections     |100    |    |postmaster|/etc/postgresql/15/main/postgresql.conf|        66|
max_wal_size        |1024   |MB  |sighup    |/etc/postgresql/15/main/postgresql.conf|       242|
shared_buffers      |16384  |8kB |postmaster|/etc/postgresql/15/main/postgresql.conf|       128|
wal_buffers         |512    |8kB |postmaster|                                       |          |
work_mem            |4096   |kB  |user      |                                       |          |
```

1. настройка *shared_buffers*:

    Текущее значение 16384 x 8Kb = 131.072 Mb. Попробуем настроить на 512 Mb (25% от всего доступного объема).

    Зашел в /etc/postgresql/15/main/postgresql.conf. Установил shared_buffers = 512MB. Перезапустил кластер.

```
postgres@PG1:/home/anton$ pgbench -c 50 -j 2 -P 60 -T 600 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 60.0 s, 639.1 tps, lat 77.967 ms stddev 98.084, 0 failed
progress: 120.0 s, 637.2 tps, lat 78.499 ms stddev 95.045, 0 failed
progress: 180.0 s, 660.2 tps, lat 75.688 ms stddev 95.546, 0 failed
progress: 240.0 s, 671.1 tps, lat 74.531 ms stddev 93.424, 0 failed
progress: 300.0 s, 652.5 tps, lat 76.629 ms stddev 96.560, 0 failed
progress: 360.0 s, 668.4 tps, lat 74.833 ms stddev 92.543, 0 failed
progress: 420.0 s, 662.2 tps, lat 75.455 ms stddev 96.860, 0 failed
progress: 480.0 s, 632.3 tps, lat 79.044 ms stddev 94.818, 0 failed
progress: 540.0 s, 638.2 tps, lat 78.380 ms stddev 95.696, 0 failed
progress: 600.0 s, 670.0 tps, lat 74.612 ms stddev 91.723, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 391924
number of failed transactions: 0 (0.000%)
latency average = 76.537 ms
latency stddev = 95.047 ms
initial connection time = 112.730 ms
tps = 653.173831 (without initial connection time)
```

# **tps = 653.173831**

Попробуем увеличить до 1024...

```
postgres@PG1:/home/anton$ pgbench -c 50 -j 2 -P 60 -T 600 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 60.0 s, 665.7 tps, lat 74.918 ms stddev 90.289, 0 failed
progress: 120.0 s, 672.9 tps, lat 74.291 ms stddev 95.105, 0 failed
progress: 180.0 s, 662.9 tps, lat 75.387 ms stddev 94.047, 0 failed
progress: 240.0 s, 655.3 tps, lat 76.337 ms stddev 95.889, 0 failed
progress: 300.0 s, 647.3 tps, lat 77.210 ms stddev 96.107, 0 failed
progress: 360.0 s, 652.9 tps, lat 76.579 ms stddev 94.655, 0 failed
progress: 420.0 s, 661.5 tps, lat 75.561 ms stddev 92.645, 0 failed
progress: 480.0 s, 660.1 tps, lat 75.774 ms stddev 93.086, 0 failed
progress: 540.0 s, 664.2 tps, lat 75.283 ms stddev 94.172, 0 failed
progress: 600.0 s, 652.1 tps, lat 76.693 ms stddev 95.032, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 395739
number of failed transactions: 0 (0.000%)
latency average = 75.804 ms
latency stddev = 94.119 ms
initial connection time = 76.643 ms
tps = 659.494684 (without initial connection time)
```

# **tps = 659.494684**

Практически нет изменений - вернем на 512MB.

2. настройка *wal_buffers*:
   
Значение по умолчанию 512x8Kb
Попробуем поставить автонастройку:
```sql
alter system set wal_buffers = -1;
```
После рестарта значение в pg_settings увиличилось: 2048x8Kb, не если смотреть командой show wal_buffers; Значение старое. По результатам это таже видно, изменений нет...

```
postgres@PG1:/home/anton$ pgbench -c 50 -j 2 -P 60 -T 600 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 60.0 s, 651.7 tps, lat 76.508 ms stddev 94.163, 0 failed
progress: 120.0 s, 645.4 tps, lat 77.458 ms stddev 99.350, 0 failed
progress: 180.0 s, 653.6 tps, lat 76.529 ms stddev 97.406, 0 failed
progress: 240.0 s, 653.9 tps, lat 76.458 ms stddev 94.139, 0 failed
progress: 300.0 s, 648.4 tps, lat 77.081 ms stddev 95.430, 0 failed
progress: 360.0 s, 655.6 tps, lat 76.248 ms stddev 95.846, 0 failed
progress: 420.0 s, 647.3 tps, lat 77.120 ms stddev 96.233, 0 failed
progress: 480.0 s, 653.2 tps, lat 76.665 ms stddev 95.178, 0 failed
progress: 540.0 s, 648.0 tps, lat 77.152 ms stddev 96.359, 0 failed
progress: 600.0 s, 648.9 tps, lat 77.039 ms stddev 99.399, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 390416
number of failed transactions: 0 (0.000%)
latency average = 76.838 ms
latency stddev = 96.377 ms
initial connection time = 77.984 ms
tps = 650.614222 (without initial connection time)
```
# **tps = 650.614222** 

Увеличим в 2 раза 

```sql
alter system set wal_buffers = 4096;
```
```
postgres@PG1:/home/anton$ pgbench -c 50 -j 2 -P 60 -T 600 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 60.0 s, 623.3 tps, lat 79.979 ms stddev 100.706, 0 failed
progress: 120.0 s, 659.4 tps, lat 75.850 ms stddev 91.699, 0 failed
progress: 180.0 s, 646.6 tps, lat 77.322 ms stddev 98.416, 0 failed
progress: 240.0 s, 625.7 tps, lat 79.883 ms stddev 102.622, 0 failed
progress: 300.0 s, 632.2 tps, lat 79.106 ms stddev 103.108, 0 failed
progress: 360.0 s, 644.4 tps, lat 77.589 ms stddev 96.103, 0 failed
progress: 420.0 s, 649.7 tps, lat 76.919 ms stddev 94.679, 0 failed
progress: 480.0 s, 657.5 tps, lat 76.065 ms stddev 99.217, 0 failed
progress: 540.0 s, 632.5 tps, lat 79.028 ms stddev 99.457, 0 failed
progress: 600.0 s, 670.4 tps, lat 74.587 ms stddev 93.098, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 386556
number of failed transactions: 0 (0.000%)
latency average = 77.610 ms
latency stddev = 97.947 ms
initial connection time = 77.841 ms
tps = 644.127000 (without initial connection time)
```
# **tps = 644.127000** 
Пораметр особо не влияет на tps, стало даже похуже.

3. настройка *max_connections*:

Установим max_connections = 400 и попромуем нагрузить 

```
postgres@PG1:/home/anton$ pgbench -c 390 -j 2 -P 60 -T 600 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 60.0 s, 336.1 tps, lat 1114.392 ms stddev 1364.931, 0 failed
progress: 120.0 s, 316.6 tps, lat 1233.745 ms stddev 1732.281, 0 failed
progress: 180.0 s, 336.1 tps, lat 1160.889 ms stddev 1579.609, 0 failed
progress: 240.0 s, 350.0 tps, lat 1119.217 ms stddev 1344.540, 0 failed
progress: 300.0 s, 342.4 tps, lat 1133.779 ms stddev 1516.810, 0 failed
progress: 360.0 s, 304.8 tps, lat 1283.114 ms stddev 1699.522, 0 failed
progress: 420.0 s, 307.1 tps, lat 1266.865 ms stddev 1808.346, 0 failed
progress: 480.0 s, 329.2 tps, lat 1185.489 ms stddev 1545.267, 0 failed
progress: 540.0 s, 336.0 tps, lat 1156.994 ms stddev 1569.464, 0 failed
progress: 600.0 s, 337.2 tps, lat 1156.458 ms stddev 1515.842, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 390
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 198110
number of failed transactions: 0 (0.000%)
latency average = 1181.420 ms
latency stddev = 1571.402 ms
initial connection time = 713.061 ms
tps = 329.703076 (without initial connection time)
```

# **tps = 329.703076** 

Видно что результат хуже. Думаю это из-за аграниченной памяти.

3. настройка с помощью [автонастройщика](https://www.pgconfig.org/#/?max_connections=400&pg_version=15&environment_name=WEB&total_ram=2&cpus=2&drive_type=SSD&arch=x86-64&os_type=linux) :

```conf
# Generated by PGConfig 3.1.4 (1fe6d98dedcaad1d0a114617cfd08b4fed1d8a01)
# https://api.pgconfig.org/v1/tuning/get-config?format=conf&&log_format=csvlog&max_connections=400&pg_version=15&environment_name=WEB&total_ram=2GB&cpus=2&drive_type=SSD&arch=x86-64&os_type=linux

# Memory Configuration
shared_buffers = 512MB
effective_cache_size = 2GB
work_mem = 1MB
maintenance_work_mem = 102MB

# Checkpoint Related Configuration
min_wal_size = 2GB
max_wal_size = 3GB
checkpoint_completion_target = 0.9
wal_buffers = -1

# Network Related Configuration
listen_addresses = '*'
max_connections = 400

# Storage Configuration
random_page_cost = 1.1
effective_io_concurrency = 200

# Worker Processes Configuration
max_worker_processes = 8
max_parallel_workers_per_gather = 2
max_parallel_workers = 2
```
Запустим для 50 подключнений:

```
postgres@PG1:/home/anton$ pgbench -c 50 -j 2 -P 60 -T 600 postgres
pgbench (15.8 (Ubuntu 15.8-1.pgdg24.04+1))
starting vacuum...end.
progress: 60.0 s, 645.1 tps, lat 77.255 ms stddev 92.868, 0 failed
progress: 120.0 s, 654.4 tps, lat 76.403 ms stddev 92.959, 0 failed
progress: 180.0 s, 662.5 tps, lat 75.503 ms stddev 91.293, 0 failed
progress: 240.0 s, 664.9 tps, lat 75.203 ms stddev 97.625, 0 failed
progress: 300.0 s, 656.1 tps, lat 76.212 ms stddev 95.350, 0 failed
progress: 360.0 s, 674.6 tps, lat 74.074 ms stddev 93.708, 0 failed
progress: 420.0 s, 642.3 tps, lat 77.781 ms stddev 100.660, 0 failed
progress: 480.0 s, 649.7 tps, lat 77.028 ms stddev 98.638, 0 failed
progress: 540.0 s, 665.6 tps, lat 75.134 ms stddev 91.772, 0 failed
progress: 600.0 s, 644.7 tps, lat 77.548 ms stddev 100.201, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 50
number of threads: 2
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 393653
number of failed transactions: 0 (0.000%)
latency average = 76.207 ms
latency stddev = 95.549 ms
initial connection time = 77.681 ms
tps = 655.999414 (without initial connection time)
```
# **tps = 655.999414**

### 4. Нагрузить кластер через утилиту через утилиту pgbench (https://postgrespro.ru/docs/postgrespro/14/pgbench)

см выше

### 5. Написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему

Удалось добиться tps = ~655. В основном за счет параметра *shared_buffers = 512*. Как видно, предложенный [вариант](https://www.pgconfig.org/#/?max_connections=400&pg_version=15&environment_name=WEB&total_ram=2&cpus=2&drive_type=SSD&arch=x86-64&os_type=linux) содержит то же значение. Размер кэша данных оказал самое сильное влияние. Чем больше кэш, тем быстрее манипуляции с данными.
## Описание/Пошаговая инструкция выполнения домашнего задания:
Будем использовать максимальную версию демо базы с сайта postgrespro

```
wget https://edu.postgrespro.com/demo-big-en.zip
sudo apt-get install unzip
sudo unzip demo-big-en.zip -d ./datasets/
sudo docker run -it --rm -v "$(pwd)"/datasets/demo-big-en-20170815.sql:/script.sql --network proxy postgres:16 ps
ql -h postgres -U pgroot -d demo -f /script.sql
```
### 1. Реализовать прямое соединение двух или более таблиц
```sql
SELECT f.flight_no, 
       f.scheduled_departure, 
       f.scheduled_arrival, 
       dep.airport_name AS departure_airport, 
       arr.airport_name AS arrival_airport
FROM flights f
INNER JOIN airports dep ON f.departure_airport = dep.airport_code
INNER JOIN airports arr ON f.arrival_airport = arr.airport_code
limit 5;
```
```
flight_no|scheduled_departure          |scheduled_arrival            |departure_airport               |arrival_airport               |
---------+-----------------------------+-----------------------------+--------------------------------+------------------------------+
PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|Domodedovo International Airport|Kurumoch International Airport|
PG0212   |2017-09-04 18:20:00.000 +0300|2017-09-04 19:35:00.000 +0300|Domodedovo International Airport|Rostov-on-Don Airport         |
PG0416   |2017-09-13 19:20:00.000 +0300|2017-09-13 19:55:00.000 +0300|Domodedovo International Airport|Voronezh International Airport|
PG0055   |2017-09-03 14:10:00.000 +0300|2017-09-03 15:25:00.000 +0300|Domodedovo International Airport|Donskoye Airport              |
PG0341   |2017-08-31 10:50:00.000 +0300|2017-08-31 11:55:00.000 +0300|Domodedovo International Airport|Petrozavodsk Airport          |
```
Этот запрос возвращает информацию о рейсах, включая названия аэропортов вылета и прибытия. Используется INNER JOIN, чтобы исключить рейсы без указанных аэропортов.

### 2. Реализовать левостороннее (или правостороннее) соединение двух или более таблиц
```sql
SELECT t.ticket_no, 
       t.passenger_name, 
       tf.flight_id, 
       tf.fare_conditions
FROM tickets t
LEFT JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
limit 5;
```
```
ticket_no    |passenger_name   |flight_id|fare_conditions|
-------------+-----------------+---------+---------------+
0005432000284|MIKHAIL SEMENOV  |   187662|Economy        |
0005432000285|ELENA ZAKHAROVA  |   187570|Business       |
0005432000286|ILYA PAVLOV      |   187570|Economy        |
0005432000287|ELENA BELOVA     |   187728|Economy        |
0005432000288|VYACHESLAV IVANOV|   187728|Business       |
```
Этот запрос возвращает все билеты, даже если для них нет связанных рейсов. Для таких билетов поля из таблицы ticket_flights будут NULL
### 3. Реализовать кросс соединение двух или более таблиц
```sql
SELECT a.airport_name, f.flight_no
FROM airports a
CROSS JOIN flights f
limit 5;
```
```
airport_name             |flight_no|
-------------------------+---------+
Yakutsk Airport          |PG0216   |
Mirny Airport            |PG0216   |
Khabarovsk-Novy Airport  |PG0216   |
Yelizovo Airport         |PG0216   |
Yuzhno-Sakhalinsk Airport|PG0216   |
```
Этот запрос возвращает все возможные комбинации аэропортов и рейсов. Кросс-соединение редко используется на практике, так как оно может генерировать огромное количество строк
### 4. Реализовать полное соединение двух или более таблиц
```sql
SELECT t.ticket_no, 
       t.passenger_name, 
       tf.flight_id, 
       tf.fare_conditions
FROM tickets t
FULL JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
limit 5;
```
```
ticket_no    |passenger_name   |flight_id|fare_conditions|
-------------+-----------------+---------+---------------+
0005432000284|MIKHAIL SEMENOV  |   187662|Economy        |
0005432000285|ELENA ZAKHAROVA  |   187570|Business       |
0005432000286|ILYA PAVLOV      |   187570|Economy        |
0005432000287|ELENA BELOVA     |   187728|Economy        |
0005432000288|VYACHESLAV IVANOV|   187728|Business       |
```
Этот запрос возвращает все билеты и все рейсы, даже если нет совпадений. Если билет не связан с рейсом, то поля из ticket_flights будут NULL, и наоборот
### 5. Реализовать запрос, в котором будут использованы разные типы соединений
```sql
SELECT f.flight_no, 
       f.scheduled_departure, 
       t.passenger_name, 
       tf.fare_conditions
FROM flights f
INNER JOIN ticket_flights tf ON f.flight_id = tf.flight_id
LEFT JOIN tickets t ON tf.ticket_no = t.ticket_no
limit 5;
```
```
flight_no|scheduled_departure          |passenger_name   |fare_conditions|
---------+-----------------------------+-----------------+---------------+
PG0242   |2016-08-15 12:05:00.000 +0300|MIKHAIL SEMENOV  |Economy        |
PG0242   |2016-08-16 12:05:00.000 +0300|ELENA ZAKHAROVA  |Business       |
PG0242   |2016-08-16 12:05:00.000 +0300|ILYA PAVLOV      |Economy        |
PG0242   |2016-08-17 12:05:00.000 +0300|ELENA BELOVA     |Economy        |
PG0242   |2016-08-17 12:05:00.000 +0300|VYACHESLAV IVANOV|Business       |
```
Этот запрос использует INNER JOIN для связи рейсов и билетов, а также LEFT JOIN для вывода информации о пассажирах, даже если она отсутствует
### 6. Сделать комментарии на каждый запрос
сделано
### 7. К работе приложить структуру таблиц, для которых выполнялись соединения
```
flights:
    flight_id serial4 NOT NULL,
	flight_no bpchar(6) NOT NULL,
	scheduled_departure timestamptz NOT NULL,
	scheduled_arrival timestamptz NOT NULL,
	departure_airport bpchar(3) NOT NULL,
	arrival_airport bpchar(3) NOT NULL,
	status varchar(20) NOT NULL,
	aircraft_code bpchar(3) NOT NULL,
	actual_departure timestamptz NULL,
	actual_arrival timestamptz NULL,

airports (view):
    airport_code,
    airport_name,
    city,
    coordinates,
    timezone

tickets:
    ticket_no bpchar(13) NOT NULL,
	book_ref bpchar(6) NOT NULL,
	passenger_id varchar(20) NOT NULL,
	passenger_name text NOT NULL,
	contact_data jsonb NULL,

ticket_flights:
	ticket_no bpchar(13) NOT NULL,
	flight_id int4 NOT NULL,
	fare_conditions varchar(10) NOT NULL,
	amount numeric(10, 2) NOT NULL,
```
### * Придумайте 3 своих метрики на основе показанных представлений, отправьте их через ЛК

Не делал
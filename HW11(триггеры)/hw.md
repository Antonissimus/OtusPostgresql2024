## Описание/Пошаговая инструкция выполнения домашнего задания:

Скрипт и развернутое описание задачи:
```sql
-- ДЗ тема: триггеры, поддержка заполнения витрин

DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;

SET search_path = pract_functions, publ

-- товары:
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, 'Спички хозайственные', .50),
		(2, 'Автомобиль Ferrari FXX K', 185000000.01);

-- Продажи
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);

-- отчет:
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

-- с увеличением объёма данных отчет стал создаваться медленно
-- Принято решение денормализовать БД, создать таблицу
CREATE TABLE good_sum_mart
(
	good_name   varchar(63) NOT NULL,
	sum_sale	numeric(16, 2)NOT NULL
);

-- Создать триггер (на таблице sales) для поддержки.
-- Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE

-- Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?
-- Подсказка: В реальной жизни возможны изменения цен.


```
### 1. Создать триггер на таблице sales, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)

1. Создадим функцию для триггера, которая будет вызываться при страбатывании:
```sql
-- DROP FUNCTION pract_functions.update_good_sum_mart();

CREATE OR REPLACE FUNCTION pract_functions.update_good_sum_mart()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Обработка операции DELETE
    IF TG_OP = 'DELETE' THEN
        UPDATE pract_functions.good_sum_mart
        SET sum_sale = sum_sale - (OLD.sales_qty * (SELECT good_price FROM pract_functions.goods WHERE goods_id = OLD.good_id))
        WHERE good_name = (SELECT good_name FROM pract_functions.goods WHERE goods_id = OLD.good_id);
        RETURN OLD;
    END IF;

    -- Обработка операции UPDATE
    IF TG_OP = 'UPDATE' THEN
        -- Уменьшаем сумму на старую продажу
        UPDATE pract_functions.good_sum_mart
        SET sum_sale = sum_sale - (OLD.sales_qty * (SELECT good_price FROM pract_functions.goods WHERE goods_id = OLD.good_id))
        WHERE good_name = (SELECT good_name FROM pract_functions.goods WHERE goods_id = OLD.good_id);

        -- Увеличиваем сумму на новую продажу
        UPDATE pract_functions.good_sum_mart
        SET sum_sale = sum_sale + (NEW.sales_qty * (SELECT good_price FROM pract_functions.goods WHERE goods_id = NEW.good_id))
        WHERE good_name = (SELECT good_name FROM pract_functions.goods WHERE goods_id = NEW.good_id);
        RETURN NEW;
    END IF;

    -- Обработка операции INSERT
    IF TG_OP = 'INSERT' THEN
        -- Увеличиваем сумму на новую продажу
        UPDATE pract_functions.good_sum_mart
        SET sum_sale = sum_sale + (NEW.sales_qty * (SELECT good_price FROM pract_functions.goods WHERE goods_id = NEW.good_id))
        WHERE good_name = (SELECT good_name FROM pract_functions.goods WHERE goods_id = NEW.good_id);

        -- Если товара еще нет в витрине, добавляем его
        IF NOT FOUND THEN
            INSERT INTO good_sum_mart (good_name, sum_sale)
            VALUES (
                (SELECT good_name FROM pract_functions.goods WHERE goods_id = NEW.good_id),
                (NEW.sales_qty * (SELECT good_price FROM pract_functions.goods WHERE goods_id = NEW.good_id))
            );
        END IF;
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$function$
;
```
2. Создадим триггер:
```sql
CREATE TRIGGER pract_functions.sales_trigger
AFTER INSERT OR UPDATE OR DELETE ON sales
FOR EACH ROW EXECUTE FUNCTION update_good_sum_mart();
```
3. Заполним витрину начальными данными:
```sql
INSERT INTO good_sum_mart (good_name, sum_sale)
SELECT G.good_name, SUM(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
```

4. Проверим:
```sql
select * from good_sum_mart;
```
```
good_name               |sum_sale    |
------------------------+------------+
Спички хозайственные    |       65.50|
Автомобиль Ferrari FXX K|185000000.01|
```
Добавим 1 Ferrari :
```sql
INSERT INTO pract_functions.sales
(good_id, sales_time, sales_qty)
VALUES(2, now(), 1);
```
```sql
select * from good_sum_mart;
```
```
good_name               |sum_sale    |
------------------------+------------+
Спички хозайственные    |       65.50|
Автомобиль Ferrari FXX K|370000000.02|
```
Удалим одну продажу:
```sql
delete from sales where sales_id = 7;
```
```sql
select * from good_sum_mart;
```
```
good_name               |sum_sale    |
------------------------+------------+
Автомобиль Ferrari FXX K|370000000.02|
Спички хозайственные    |        5.50|
```

Работает.
### * Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?
- Актуальность данных: Витрина, поддерживаемая триггерами, всегда содержит актуальные данные, так как обновляется автоматически при каждом изменении в таблице sales. В случае отчета, создаваемого "по требованию", данные могут быть устаревшими, если они не были пересчитаны после последних изменений.

- Снижение нагрузки на БД: При использовании витрины с триггерами, данные пересчитываются только при изменении, а не каждый раз при запросе отчета. Это снижает нагрузку на базу данных, особенно при большом объеме данных.

- Упрощение запросов: Запросы к витрине становятся проще и быстрее, так как данные уже агрегированы и готовы к использованию. Это особенно полезно для сложных отчетов, которые могут требовать множества вычислений.

- Поддержка изменений цен: В реальной жизни цены на товары могут меняться. Витрина, поддерживаемая триггерами, может учитывать эти изменения, если триггеры корректно обрабатывают обновления цен. В случае отчета "по требованию" это может быть сложнее реализовать, так как потребуется пересчет всех исторических данных при изменении цены.
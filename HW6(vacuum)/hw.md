## Описание/Пошаговая инструкция выполнения домашнего задания:
### 1. Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB
### 2. Установить на него PostgreSQL 15 с дефолтными настройками
### 3. Создать БД для тестов: выполнить pgbench -i postgres
### 4. Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres
### 5. Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
### 6. Протестировать заново
### 7. Что изменилось и почему?
### 8. Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
### 9. Посмотреть размер файла с таблицей
### 10. 5 раз обновить все строчки и добавить к каждой строчке любой символ
### 11. Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум
### 12. Подождать некоторое время, проверяя, пришел ли автовакуум
### 13. 5 раз обновить все строчки и добавить к каждой строчке любой символ
### 14. Посмотреть размер файла с таблицей
### 15. Отключить Автовакуум на конкретной таблице
### 16. 10 раз обновить все строчки и добавить к каждой строчке любой символ
### 17. Посмотреть размер файла с таблицей
### 18. Объясните полученный результат
### 19. Не забудьте включить автовакуум)
### 20. Задание со * - Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице. Не забыть вывести номер шага цикла.
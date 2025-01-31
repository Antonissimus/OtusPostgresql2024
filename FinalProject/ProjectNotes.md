# Ход выполнения проекта
Тема проекта - миграция БД web приложения с MS SQL Server на PostgreSQL.
## 1. Подготовка окружения
Кластер postgres развернут в облаке. Операционная система - Linux (Ubuntu 22.04). Параметры виртуальной машины: 8CPU, 16 RAM, 160Gb. БД и приложение установлены в Docker.
### 1.1. Установка postgresql
### 1.2. Первоначальная настройка конфигурации postgresql
### 1.3. Создание пользователя для приложения
## 2. Миграция MS SQL на postgresql
### 2.1. Перенос таблиц
Поскольку есть доступ к коду приложения, самый простой способ создания табличной структуры - с помощью миграции DOT.NET Entity Framework core.
```c#
dotnet ef migrations add InitialIdentity --verbose --context IdentityDbContext
dotnet ef migrations add InitialIdentity --verbose --context PrsDbContext
dotnet ef database update --context ApplicationDbContext
dotnet ef database update --context PrsDbContext
```
### 2.2. Перенос функций и процедур
### 2.3. Перенос представлений
### 2.4. Перенос данных
## 3. Настройка бэкапирования
## 4. Настройка мониторинга
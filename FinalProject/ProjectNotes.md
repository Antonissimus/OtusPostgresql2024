# Ход выполнения проекта
Тема проекта - миграция БД web приложения с MS SQL Server на PostgreSQL.
## 1. Подготовка окружения
Кластер postgres развернут в облаке. Операционная система - Linux (Ubuntu 22.04). Параметры виртуальной машины: 8CPU, 16 RAM, 160Gb. БД и приложение установлены в Docker.
### 1.1. Установка postgresql
### 1.2. Первоначальная настройка конфигурации postgresql
### 1.3. Создание пользователя для приложения
## 2. Миграция MS SQL на postgresql
### 2.1. Перенос таблиц
### 2.2. Перенос функций и процедур
### 2.3. Перенос представлений
### 2.4. Перенос данных
## 3. Настройка бэкапирования
## 4. Настройка мониторинга для кластера postgresql 17
- На виртуальной машине 1(ВМ1) развернут кластер postgresql 17 и docker.
- На ВМ2 развернут docker.
### 4.1. Развернуть на ВМ1 в docker postgres_exporter(для prometheus). Использовать docker compose.
- Создать нового пользователя и дать нужные права:
```bash
sudo -u postgres psql
```
```sql
CREATE USER pgexporter WITH PASSWORD 'secure_password'; --супер пароль
ALTER USER pgexporter SET SEARCH_PATH TO pg_catalog,pg_statistic;
GRANT CONNECT ON DATABASE postgres TO pgexporter;
GRANT CONNECT ON DATABASE prsdb TO pgexporter;
GRANT pg_monitor TO pgexporter;
```

- Создать директорию для конфигурации postgres_exporter:
```bash
mkdir -p /mnt/app/exporter
cd /mnt/app/exporter
```
- Создать файл /mnt/app/exporter/[docker-compose.yaml](vm1/exporter/docker-compose.yaml)
- Создать файл /mnt/app/exporter/.env и определить в нем необходимые значения
- Запустить контейнер:
```bash
sudo docker compose up -d
```
- Проверить метрики:
```bash
curl "http://localhost:9188/metrics"
```

### 4.2. Развернуть на ВМ2 в docker prometheus и graphana. Использовать docker compose.
- Создать директорию для конфигурации prometheus и grafana:
```bash
mkdir -p /mnt/app/prometheus_stack/{prometheus,grafana}
cd /mnt/app/prometheus_stack
```
- Создать файл /mnt/app/prometheus_stack/[docker-compose.yaml](vm2/prometheus_grafana/docker-compose.yaml)
- Создать файл /mnt/app/prometheus_stack/.env и определить в нем необходимые значения
- Создать файл /mnt/app/prometheus_stack/prometheus/[prometheus.yml](vm2/prometheus_grafana/prometheus.yml)
- Запустить контейнер:
```bash
sudo docker compose up -d
```
- Проверить доступность сервисов через браузер:
![prometheus](image.png)
![grafana](image-1.png)

### 4.3. Настроить graphana для отображения метрик postgreSQL.
При первом входе использовать стандартые данные (admin:admin) поменять пароль на более безопасный.
- В боковом меню выбрать **Connections** -> **Data Sources**.
- Нажать **Add data source** и выберите **Prometheus**.
- В поле URL введите настроенный путь( например http://prometheus:9090 ) и нажмите **Save & Test**.
### 4.4. Сконфигурировать всю систему мониторинга.
- В боковом меню выбрать **Dashboards**.
- Нажать кнопку **New** -> **Import**.
- Введите ID дашборда - 9628 и нажать **Load**.
- Выбрать настроенный источник Prometheus нажать **Import**
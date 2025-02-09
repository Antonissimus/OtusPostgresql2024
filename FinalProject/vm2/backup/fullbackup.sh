#!/bin/bash

# Параметры
BACKUP_DIR="/mnt/backups"
DATE=$(date +%d%m%Y)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"
TAR_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"
PG_DUMP="/usr/bin/pg_dumpall"

# Создание директории для бэкапов, если она не существует
mkdir -p $BACKUP_DIR

# Логирование начала бэкапа
echo "Начало бэкапа: $(date)"

# Выполнение бэкапа
echo "Выполнение бэкапа в файл: $BACKUP_FILE"
$PG_DUMP -p 5556 -f $BACKUP_FILE

# Проверка успешности выполнения бэкапа
if [ $? -eq 0 ]; then
    echo "Бэкап успешно создан: $BACKUP_FILE"
else
    echo "Ошибка при создании бэкапа"
    exit 1
fi

# Архивирование бэкапа
echo "Архивирование бэкапа в файл: $TAR_FILE"
tar -czf $TAR_FILE -C $BACKUP_DIR $(basename $BACKUP_FILE)

# Проверка успешности архивирования
if [ $? -eq 0 ]; then
    echo "Бэкап успешно заархивирован: $TAR_FILE"
else
    echo "Ошибка при архивировании бэкапа"
    exit 1
fi

# Удаление исходного файла бэкапа
echo "Удаление исходного файла бэкапа: $BACKUP_FILE"
rm -f $BACKUP_FILE

# Логирование завершения бэкапа
echo "Завершение бэкапа: $(date)"

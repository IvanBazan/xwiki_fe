#!/bin/bash
set -e

BACKUP_DIR="/opt/backups/xwiki"
DATE=$(date +%Y%m%d_%H%M%S)

# Создаем директорию для бэкапов
mkdir -p $BACKUP_DIR/$DATE

# Определяем имена контейнеров (измените под вашу установку)
POSTGRES_CONTAINER="xwiki-postgres"
XWIKI_CONTAINER="xwiki"
XWIKI_VOLUME="xwiki"

# 1. Бэкап БД
echo "1. Бэкап базы данных..."
docker exec $POSTGRES_CONTAINER pg_dump -U xwiki -d xwiki -Fc > $BACKUP_DIR/$DATE/xwiki_db.dump

# 2. Бэкап данных ИЗ КОНТЕЙНЕРА
echo "2. Бэкап данных из контейнера..."
docker exec xwiki tar czf /tmp/xwiki_data_full.tar.gz -C /usr/local/xwiki/data .
docker cp xwiki:/tmp/xwiki_data_full.tar.gz $BACKUP_DIR/$DATE/
docker exec xwiki rm -f /tmp/xwiki_data_full.tar.gz

# 3. Бэкап конфигов
echo "3. Бэкап конфигурации..."
docker exec xwiki sh -c '
    tar czf /tmp/configs.tar.gz \
        /usr/local/tomcat/webapps/ROOT/WEB-INF/xwiki.cfg \
        /usr/local/tomcat/webapps/ROOT/WEB-INF/xwiki.properties \
        /usr/local/tomcat/conf/server.xml 2>/dev/null || true
'
docker cp xwiki:/tmp/configs.tar.gz $BACKUP_DIR/$DATE/ 2>/dev/null || true

# 4. Проверка
echo "4. Проверка бэкапа..."
ls -lh $BACKUP_DIR/$DATE/
echo ""
echo "Содержимое архива данных (первые 20 файлов):"
docker run --rm -v $BACKUP_DIR/$DATE/:/backup alpine sh -c "tar tzf /backup/xwiki_data_full.tar.gz | head -20"

echo "=== БЭКАП ЗАВЕРШЕН ==="
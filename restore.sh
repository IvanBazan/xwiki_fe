#!/bin/bash
set -e

BACKUP_DIR="/opt/backups/xwiki/latest"
COMPOSE_DIR="/opt/xwiki_fe"

cd "$COMPOSE_DIR"

# 1. Очистка
docker-compose down -v

# 2. Создаем том (если нужно)
docker volume create xwiki_data 2>/dev/null || true

# 3. Распаковка данных
docker run --rm -v xwiki_data:/data -v "$BACKUP_DIR":/backup alpine \
    sh -c "tar xzf /backup/xwiki_data_full.tar.gz -C /data"

# 4. Запуск всех сервисов
docker-compose up -d

# 5. Ожидание PostgreSQL
sleep 20

# 6. Восстановление БД
CID=$(docker ps -q --filter "name=xwiki-postgres")
docker cp "$BACKUP_DIR/xwiki_db.dump" "${CID}:/tmp/dump.dump"
docker exec "$CID" pg_restore -U xwiki -d xwiki --clean --no-owner -Fc /tmp/dump.dump

# 7. Перезапуск XWiki для применения изменений
docker-compose restart xwiki
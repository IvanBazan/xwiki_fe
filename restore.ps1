# 1. Очистка
docker-compose down -v

# 2. Распаковка данных (из нового бэкапа)
docker volume create xwiki_data 2>$null
docker run --rm -v xwiki_data:/data -v ${PWD}:/backup alpine sh -c "tar xzf /backup/xwiki_data_full.tar.gz -C /data"

# 3. Запуск PostgreSQL
docker-compose up -d postgres
Start-Sleep -Seconds 20

# 4. Получаем ID контейнера
$cid = docker ps --filter "name=xwiki-postgres" --format "{{.ID}}"

# 5. Копируем и восстанавливаем дамп
docker cp xwiki_db.dump "${cid}:/tmp/dump.dump"
docker exec $cid pg_restore -U xwiki -d xwiki --no-owner -Fc /tmp/dump.dump

# 6. Запускаем XWiki
docker-compose up -d xwiki

# 7. Готово
echo "GOTOVO! http://localhost:8080"
echo "Logi: docker-compose logs -f xwiki"
diff --git a/docs/troubleshooting.md b/docs/troubleshooting.md
index e69de29bb2d1d6434b8b29ae775ad8c2e48c5391..1720ab1e994303c2fa915f1b07d45a8f0903feb2 100644
--- a/docs/troubleshooting.md
+++ b/docs/troubleshooting.md
@@ -0,0 +1,46 @@
+<!-- Траблшутинг -->
+
+# Troubleshooting
+
+Частые проблемы и быстрые способы их решить.
+
+## Kibana/Elasticsearch не открываются
+
+- Проверь контейнеры: `make ps` или `docker ps`.  
+- Посмотри логи: `docker compose -f docker/docker-compose.yml logs elasticsearch | tail`, то же для `kibana`.  
+- Elasticsearch долго стартует — подожди до 2 минут; если всё ещё нет ответа, удостоверься, что каталогу данных `~/detection-sandbox/config/elasticsearch/esdata` хватает прав (`chown 1000:1000`).
+
+## Нет дашбордов или data view
+
+`make deploy` автоматически импортирует `export.ndjson`. Если пропустили шаг — импортируй вручную из корня репозитория:
+
+```bash
+curl -sS -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
+  -H "kbn-xsrf: true" \
+  --form file=@"./export.ndjson"
+```
+
+## В Discover пусто
+
+1. Расширь таймпикер (Last 1 hour / Last 24 hours).  
+2. Убедись, что выбираешь правильный data view (`juice-shop-access-*` или `system-audit-*`).  
+3. Посмотри, создались ли индексы: `curl -s "http://localhost:9200/_cat/indices?v" | grep juice`.  
+4. Проверяй логи Filebeat/Logstash:  
+   ```bash
+   docker compose -f docker/docker-compose.yml logs filebeat --tail 200
+   docker compose -f docker/docker-compose.yml logs logstash --tail 200
+   ```
+5. Убедись, что пути в volume для логов существуют на хосте (логи Juice Shop и auditd).
+
+## Чекер даёт FAIL, хотя события видны
+
+- По умолчанию окно — последние 30 минут. Запусти чекер с увеличенным окном (`WINDOW="now-2h" make check-..."`).  
+- Открой соответствующий скрипт в `iac/scripts/` и проверь, по каким полям/URI он фильтрует — возможно, поле в твоих данных отличается.  
+- Если Elasticsearch возвращает ошибку, чекер завершается кодом 2 — проверь HTTP-код в выводе.
+
+## auditd не пишет события
+
+- Проверь статус: `sudo systemctl status auditd`.  
+- Убедись, что правила загружены: `sudo augenrules --check`.  
+- В `setup.sh` путь для `authorized_keys` жёстко задан (`/home/sbykov/...`). Если пользователь другой, поправь правило и перезагрузи auditd.  
+- Проверяй сырые события: `sudo ausearch -k cron_changes -i | tail`.

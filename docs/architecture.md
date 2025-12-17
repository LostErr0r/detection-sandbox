diff --git a/docs/architecture.md b/docs/architecture.md
index e69de29bb2d1d6434b8b29ae775ad8c2e48c5391..6636c5f0e5848b9e394663f08012ff512ce91613 100644
--- a/docs/architecture.md
+++ b/docs/architecture.md
@@ -0,0 +1,30 @@
+<!-- Архитектура и состав стенда -->
+
+# Архитектура
+
+Стенд построен вокруг небольшого ELK-кластера и тестового приложения OWASP Juice Shop. Все компоненты разворачиваются локально в Docker, а вспомогательные скрипты занимаются настройкой auditd, шаблонов индексов и дашбордов.
+
+## Компоненты
+
+- **Elasticsearch 7.17.18** — хранилище событий, поднимается из `docker/docker-compose.yml`.  
+- **Logstash 7.17.18** — принимает данные от Filebeat (pipeline-файл монтируется из `~/detection-sandbox/config/logstash/pipeline/logstash.conf`).  
+- **Kibana 7.17.18** — визуализация и работа с дашбордами.  
+- **Filebeat 7.17.18** — собирает логи контейнеров и системные аудит-логи с хоста, использует конфиг `~/detection-sandbox/config/filebeat/filebeat.yml`.  
+- **OWASP Juice Shop** — уязвимое веб-приложение, чей трафик и логи служат источником событий (см. `app/juice-shop/docker-compose.yml`).  
+- **Настройка окружения** — `setup.sh` ставит Docker/Compose, gobuster, auditd и создаёт каталоги данных для Elasticsearch (`~/detection-sandbox/config/elasticsearch/esdata`).
+
+## Поток данных
+
+1. **Генерация событий**: атаки против Juice Shop или действий в системе (auditd).  
+2. **Сбор**: Filebeat читает логи приложений и аудит-логи с хоста и отправляет их в Logstash.  
+3. **Обогащение и маршрутизация**: Logstash парсит события и пишет их в Elasticsearch.  
+4. **Индексация**: применяются index template для `juice-shop-access-*` и `system-audit-*` (`templates/*.json`) с заданными маппингами.  
+5. **Визуализация**: Kibana использует импортированные сохранённые объекты из `export.ndjson` (автоматически накатывается в `iac/scripts/deploy.sh`) для готовых дашбордов и data view.
+
+## Файлы и точки входа
+
+- **Docker Compose**: `docker/docker-compose.yml` (ELK + Filebeat) и `app/juice-shop/docker-compose.yml` (Juice Shop).  
+- **Шаблоны индексов**: `templates/juice-shop-access-template.json`, `templates/system-audit-template.json`.  
+- **Сценарии атак**: `attacks/web/*` и `attacks/auditd/*`.  
+- **Чекеры**: `iac/scripts/check-*.sh` — bash-скрипты, обращающиеся в Elasticsearch.  
+- **Утилиты Make**: цели `make deploy`, `make up/down`, `make attack-*`, `make check-*` описаны в `Makefile`.

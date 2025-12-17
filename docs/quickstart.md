# Быстрый старт

Руководство для быстрого развёртывания стенда ELK + Juice Shop, запуска атак и проверки того, что события попадают в Elasticsearch и видны в Kibana.

## Требования

- Ubuntu или совместимый Linux c `apt`
- `sudo`-права для установки пакетов и настройки auditd
- Доступ в интернет для загрузки Docker-образов

## 1. Подготовка окружения

В корне репозитория запусти установочный скрипт (ставит Docker, docker compose, gobuster, auditd и добавляет правила аудита):

```bash
./setup.sh
```

> Скрипт создаёт каталоги данных под `~/detection-sandbox` и добавляет auditd-правила (по умолчанию следят за `~/.ssh/authorized_keys` пользователя `sbykov`). Перед запуском при необходимости поправь путь в `setup.sh`, чтобы он соответствовал твоему пользователю.

После выполнения перелогинься или выполни `newgrp docker`, чтобы применилось членство в группе `docker`.

## 2. Развёртывание

Запусти полный стенд (ELK + Juice Shop, шаблоны индексов, импорт дашбордов):

```bash
make deploy
```

Команда вызывает `iac/scripts/deploy.sh`, которая поднимает два Docker Compose (`docker/docker-compose.yml` и `app/juice-shop/docker-compose.yml`), ждёт готовности Elasticsearch/Kibana и накатывает `templates/*.json` плюс `export.ndjson`.

Альтернативно можно управлять контейнерами вручную:

```bash
make up     # только поднять ELK + Juice Shop
make down   # остановить все контейнеры стенда
make ps     # посмотреть статус контейнеров
```

## 3. Проверка сервисов

- **Elasticsearch**: `curl -s http://localhost:9200 | head`
- **Kibana**: открой `http://localhost:5601`
- **Juice Shop**: открой `http://localhost:3000`

Оба веб-интерфейса должны открываться без ошибок, а Elasticsearch — отдавать JSON с информацией о кластере.

## 4. Проверка индексов

Убедись, что появились индексы для логов Juice Shop и auditd:

```bash
curl -s "http://localhost:9200/_cat/indices?v" | grep -E "juice-shop-access|system-audit"
```

Если индексы создаются, ingestion работает корректно.

## 5. Запуск атак

Для генерации событий воспользуйся готовыми сценариями (подробности — в разделе [Атаки](attacks.md)):

```bash
make attack-bruteforce   # bruteforce /rest/user/login
make attack-sqli         # SQLi payload-ы в логине
make attack-xss          # XSS payload-ы в поиске
make attack-dirsearch    # gobuster по каталогу приложения
make attack-auditd       # цепочка сценариев auditd
```

## 6. Проверка попадания событий

Запусти чекеры, которые обращаются в Elasticsearch за последние 30 минут:

```bash
make check-bruteforce
make check-sqli
make check-xss
make check-dirsearch
make check-auditd
```

На выходе будет PASS/FAIL и счётчик подходящих событий. Если данные не видны, см. [Troubleshooting](troubleshooting.md).

## 7. Остановка стенда

Когда закончил, останови контейнеры:


```bash
make down
```
=======
в правиле/алерте указан правильный индекс и фильтры
=======
diff --git a/docs/quickstart.md b/docs/quickstart.md
index 2510caeb3e2aef9ef096cfa83d07f849ac4da8fb..b9b0bc83fad1c7259a929074faf2686319e2723a 100644
--- a/docs/quickstart.md
+++ b/docs/quickstart.md
@@ -1,139 +1,91 @@
 # Быстрый старт
 
-## Цель
-Развернуть стенд **detection-sandbox** (ELK + Juice Shop) и убедиться, что:
-- контейнеры поднялись,
-- Elasticsearch и Kibana доступны,
-- данные попадают в индексы,
-- в Kibana Discover появляются события.
+Руководство для быстрого развёртывания стенда ELK + Juice Shop, запуска атак и проверки того, что события попадают в Elasticsearch и видны в Kibana.
 
 ## Требования
-- Linux (Ubuntu)
-- Docker + Docker Compose
-- GNU Make
 
-## Запуск стенда
+- Ubuntu или совместимый Linux c `apt`
+- `sudo`-права для установки пакетов и настройки auditd
+- Доступ в интернет для загрузки Docker-образов
 
-Перейди в корень репозитория:
+## 1. Подготовка окружения
+
+В корне репозитория запусти установочный скрипт (ставит Docker, docker compose, gobuster, auditd и добавляет правила аудита):
 
 ```bash
-cd ~/detection-sandbox
+./setup.sh
 ```
 
-Запусти деплой:
-
-make deploy
-
-Ожидаемо при старте ты увидишь, что поднимаются контейнеры ELK и Juice Shop (elasticsearch, logstash, kibana, filebeat + juice shop).
-
-Проверка доступности сервисов
-Elasticsearch
-
-Проверь, что Elasticsearch отвечает:
-
-curl -s http://localhost:9200 | head
-
-
-Ожидаемый результат: JSON с информацией о кластере (name, cluster_name, version и т.п.).
-
-Kibana
-
-Открой в браузере:
-
-Kibana: http://localhost:5601
-
-Ожидаемый результат: открывается интерфейс Kibana без ошибок.
-
-Juice Shop
-
-Открой в браузере:
-
-Juice Shop: http://localhost:3000
-
-Ожидаемый результат: открывается приложение OWASP Juice Shop.
-
-Проверка, что логи попадают в Elasticsearch
-
-Посмотри список индексов:
-
-curl -s "http://localhost:9200/_cat/indices?v" | head -n 50
-
-
-Ожидаемо должны появляться индексы, связанные с логами стенда. В проекте используются шаблоны для:
-
-juice-shop-access-* (логи веб-доступа Juice Shop)
-
-system-audit-* (события Linux audit/system audit)
+> Скрипт создаёт каталоги данных под `~/detection-sandbox` и добавляет auditd-правила (по умолчанию следят за `~/.ssh/authorized_keys` пользователя `sbykov`). Перед запуском при необходимости поправь путь в `setup.sh`, чтобы он соответствовал твоему пользователю.
 
-Если индексы есть — значит ingestion работает.
+После выполнения перелогинься или выполни `newgrp docker`, чтобы применилось членство в группе `docker`.
 
-Проверка в Kibana (Discover)
+## 2. Развёртывание
 
-Открой Kibana → Discover.
+Запусти полный стенд (ELK + Juice Shop, шаблоны индексов, импорт дашбордов):
 
-Выбери Data View/Index pattern:
-
-juice-shop-access-* (если создан)
-
-system-audit-* (если создан)
-
-Убедись, что выбран корректный time range (например Last 15 minutes или Last 1 hour).
-
-Ожидаемый результат: в таблице событий появляются записи.
-
-Troubleshooting
-1) “В Discover пусто”
-
-Проверь по порядку:
-
-Контейнеры запущены:
-
-docker ps
-
-Есть ли индексы:
-
-curl -s "http://localhost:9200/_cat/indices?v"
-Расширь time range в Kibana (часто проблема именно в этом):
-
-поставь Last 1 hour или Last 24 hours
+```bash
+make deploy
+```
 
-Посмотри логи Logstash/Filebeat:
+Команда вызывает `iac/scripts/deploy.sh`, которая поднимает два Docker Compose (`docker/docker-compose.yml` и `app/juice-shop/docker-compose.yml`), ждёт готовности Elasticsearch/Kibana и накатывает `templates/*.json` плюс `export.ndjson`.
 
-docker logs logstash --tail 200
-docker logs filebeat --tail 200
+Альтернативно можно управлять контейнерами вручную:
 
-Частые причины:
+```bash
+make up     # только поднять ELK + Juice Shop
+make down   # остановить все контейнеры стенда
+make ps     # посмотреть статус контейнеров
+```
 
-парсинг не совпадает с форматом логов,
+## 3. Проверка сервисов
 
-Logstash не может записать в ES,
+- **Elasticsearch**: `curl -s http://localhost:9200 | head`
+- **Kibana**: открой `http://localhost:5601`
+- **Juice Shop**: открой `http://localhost:3000`
 
-время события не попадает в выбранное окно (timezone/timepicker).
+Оба веб-интерфейса должны открываться без ошибок, а Elasticsearch — отдавать JSON с информацией о кластере.
 
-2) “Чекер FAIL, а в Discover вижу”
+## 4. Проверка индексов
 
-Почти всегда это одно из:
+Убедись, что появились индексы для логов Juice Shop и auditd:
 
-чекер смотрит в окно now-30m, а событие было раньше → увеличь окно в скрипте/параметрах
+```bash
+curl -s "http://localhost:9200/_cat/indices?v" | grep -E "juice-shop-access|system-audit"
+```
 
-чекер ищет другой индекс/поле, чем у тебя реально записалось
+Если индексы создаются, ingestion работает корректно.
 
-Если чекер — это make check-*, открой соответствующий скрипт в iac/scripts/ и проверь:
+## 5. Запуск атак
 
-какой index pattern он запрашивает,
+Для генерации событий воспользуйся готовыми сценариями (подробности — в разделе [Атаки](attacks.md)):
 
-какой time window,
+```bash
+make attack-bruteforce   # bruteforce /rest/user/login
+make attack-sqli         # SQLi payload-ы в логине
+make attack-xss          # XSS payload-ы в поиске
+make attack-dirsearch    # gobuster по каталогу приложения
+make attack-auditd       # цепочка сценариев auditd
+```
 
-какие поля/URI/коды ответа он ожидает.
+## 6. Проверка попадания событий
 
-3) “Kibana rule/alert не видит индекс”
+Запусти чекеры, которые обращаются в Elasticsearch за последние 30 минут:
 
-Проверь:
+```bash
+make check-bruteforce
+make check-sqli
+make check-xss
+make check-dirsearch
+make check-auditd
+```
 
-выбран ли правильный Data View/Index pattern
+На выходе будет PASS/FAIL и счётчик подходящих событий. Если данные не видны, см. [Troubleshooting](troubleshooting.md).
 
-есть ли данные в этом индексе прямо сейчас (Discover)
+## 7. Остановка стенда
 
-время (time range) совпадает с моментом атаки/события
+Когда закончил, останови контейнеры:
 
-в правиле/алерте указан правильный индекс и фильтры
+```bash
+make down
+```


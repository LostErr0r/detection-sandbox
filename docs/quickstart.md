# Быстрый старт

## Цель
Развернуть стенд **detection-sandbox** (ELK + Juice Shop) и убедиться, что:
- контейнеры поднялись,
- Elasticsearch и Kibana доступны,
- данные попадают в индексы,
- в Kibana Discover появляются события.

## Требования
- Linux (Ubuntu)
- Docker + Docker Compose
- GNU Make

## Запуск стенда

Перейди в корень репозитория:

```bash
cd ~/detection-sandbox


Запусти деплой:

make deploy

Ожидаемо при старте ты увидишь, что поднимаются контейнеры ELK и Juice Shop (elasticsearch, logstash, kibana, filebeat + juice shop).

Проверка доступности сервисов
Elasticsearch

Проверь, что Elasticsearch отвечает:

curl -s http://localhost:9200 | head


Ожидаемый результат: JSON с информацией о кластере (name, cluster_name, version и т.п.).

Kibana

Открой в браузере:

Kibana: http://localhost:5601

Ожидаемый результат: открывается интерфейс Kibana без ошибок.

Juice Shop

Открой в браузере:

Juice Shop: http://localhost:3000

Ожидаемый результат: открывается приложение OWASP Juice Shop.

Проверка, что логи попадают в Elasticsearch

Посмотри список индексов:

curl -s "http://localhost:9200/_cat/indices?v" | head -n 50


Ожидаемо должны появляться индексы, связанные с логами стенда. В проекте используются шаблоны для:

juice-shop-access-* (логи веб-доступа Juice Shop)

system-audit-* (события Linux audit/system audit)

Если индексы есть — значит ingestion работает.

Проверка в Kibana (Discover)

Открой Kibana → Discover.

Выбери Data View/Index pattern:

juice-shop-access-* (если создан)

system-audit-* (если создан)

Убедись, что выбран корректный time range (например Last 15 minutes или Last 1 hour).

Ожидаемый результат: в таблице событий появляются записи.

Troubleshooting
1) “В Discover пусто”

Проверь по порядку:

Контейнеры запущены:

docker ps

Есть ли индексы:

curl -s "http://localhost:9200/_cat/indices?v"
Расширь time range в Kibana (часто проблема именно в этом):

поставь Last 1 hour или Last 24 hours

Посмотри логи Logstash/Filebeat:

docker logs logstash --tail 200
docker logs filebeat --tail 200

Частые причины:

парсинг не совпадает с форматом логов,

Logstash не может записать в ES,

время события не попадает в выбранное окно (timezone/timepicker).

2) “Чекер FAIL, а в Discover вижу”

Почти всегда это одно из:

чекер смотрит в окно now-30m, а событие было раньше → увеличь окно в скрипте/параметрах

чекер ищет другой индекс/поле, чем у тебя реально записалось

Если чекер — это make check-*, открой соответствующий скрипт в iac/scripts/ и проверь:

какой index pattern он запрашивает,

какой time window,

какие поля/URI/коды ответа он ожидает.

3) “Kibana rule/alert не видит индекс”

Проверь:

выбран ли правильный Data View/Index pattern

есть ли данные в этом индексе прямо сейчас (Discover)

время (time range) совпадает с моментом атаки/события

в правиле/алерте указан правильный индекс и фильтры
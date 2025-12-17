# detection-sandbox

Учебный стенд для отработки обнаружения атак: разворачивает ELK (Elasticsearch, Logstash, Kibana, Filebeat) и OWASP Juice Shop, содержит готовые сценарии атак и чекеры, а также дашборды для быстрой валидации.

## Быстрый старт

### Требования
- Ubuntu или совместимый Linux с `apt`
- `sudo`-права для установки пакетов и настройки auditd
- Доступ в интернет для загрузки Docker-образов
- Рекомендованные ресурсы: **4 CPU и 8 ГБ RAM** (минимум 2 CPU / 4 ГБ RAM, но ELK будет работать медленнее)

### Подготовка окружения
Запусти скрипт установки зависимостей и правил auditd:
```bash
./setup.sh
```
> Скрипт создаёт каталоги данных в `~/detection-sandbox` и добавляет правила auditd. Если пользователь отличается от `sbykov`, поправь путь к `authorized_keys` в `setup.sh` перед запуском.

После завершения перелогинься или выполни `newgrp docker`, чтобы применилось членство в группе `docker`.

### Развёртывание стенда
Подними ELK, Juice Shop, шаблоны индексов и импорт дашбордов одной командой:
```bash
make deploy
```
Полезные цели Make:
```bash
make up     # только запустить контейнеры
make down   # остановить стенд
make ps     # статус контейнеров
```

### Проверка сервисов
- Elasticsearch: `curl -s http://localhost:9200 | head`
- Kibana: открой `http://localhost:5601`
- Juice Shop: открой `http://localhost:3000`

### Проверка индексов
Убедись, что ingestion работает и есть индексы логов:
```bash
curl -s "http://localhost:9200/_cat/indices?v" | grep -E "juice-shop-access|system-audit"
```

## Запуск атак
Готовые сценарии для генерации событий (веб и auditd). Основные цели:
```bash
make attack-bruteforce   # bruteforce POST /rest/user/login
make attack-sqli         # SQLi payload-ы в логине
make attack-xss          # XSS в поиске товаров
make attack-dirsearch    # gobuster по каталогу приложения
make attack-auditd       # цепочка сценариев auditd
```

## Проверки (чекеры)
Проверяют, что события попали в Elasticsearch за последние 30 минут:
```bash
make check-bruteforce
make check-sqli
make check-xss
make check-dirsearch
make check-auditd
```
Если нужно расширить окно, передай `WINDOW="now-2h"` (см. скрипты в `iac/scripts/`).

## Troubleshooting
- Расширь таймпикер в Kibana и выбери нужный data view (`juice-shop-access-*` / `system-audit-*`).
- Посмотри индексы и логи:  
  `curl -s "http://localhost:9200/_cat/indices?v"`  
  `docker compose -f docker/docker-compose.yml logs filebeat --tail 200`  
  `docker compose -f docker/docker-compose.yml logs logstash --tail 200`
- Импортируй дашборды вручную при необходимости:
  ```bash
  curl -sS -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
    -H "kbn-xsrf: true" \
    --form file=@"./export.ndjson"
  ```
- Убедись, что auditd активен (`sudo systemctl status auditd`) и правила загружены (`sudo augenrules --check`).

Подробности см. в `docs/quickstart.md` и `docs/troubleshooting.md`.

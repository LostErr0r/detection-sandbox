<!-- Чекеры -->

# Проверки (чекеры)

Чекеры — это bash-скрипты, которые обращаются к Elasticsearch и подсчитывают количество событий за окно времени (по умолчанию последние 30 минут). Они помогают быстро понять, попали ли результаты атак в индексы.

## Web (Juice Shop)

| Команда | Описание | Скрипт | Индекс / окно |
| --- | --- | --- | --- |
| `make check-bruteforce` | Ищет `POST /rest/user/login` и проверяет, что их не меньше 10 за окно. | `iac/scripts/check-juice-login-traces.sh` | `juice-shop-access-*`, `now-30m` |
| `make check-sqli` | Ищет SQLi-попытки на `/rest/user/login` (по параметрам, статусам и т.д.). | `iac/scripts/check-juice-sqli-traces.sh` | `juice-shop-access-*`, `now-30m` |
| `make check-xss` | Считает события поиска по товарам, куда отправлялись XSS-пейлоады. | `iac/scripts/check-juice-xss-traces.sh` | `juice-shop-access-*`, `now-30m` |
| `make check-dirsearch` | Проверяет, что сканер директорий (gobuster) оставил следы в логах. | `iac/scripts/check-juice-dirsearch-traces.sh` | `juice-shop-access-*`, `now-30m` |

Чекеры выводят `PASS`/`FAIL` и количество совпавших событий. Если видишь `FAIL`, сначала посмотри, пришли ли события в Discover за нужный период и в правильный индекс.

## auditd

| Команда | Описание | Скрипт | Индекс / окно |
| --- | --- | --- | --- |
| `make check-auditd` | Запускает универсальный счётчик аудита: cron, authorized_keys, sudo, useradd/userdel. | `iac/scripts/check-auditd-check-all.sh` | `system-audit-*`, `now-30m` |

Параметры можно переопределить переменными окружения перед запуском:

```bash
ES=http://localhost:9200 INDEX="system-audit-*" WINDOW="now-1h" make check-auditd
```

## Общие рекомендации

- Убедись, что jq установлен: скрипты используют его для разбора ответа Elasticsearch (`sudo apt install jq -y`).  
- Если чекер смотрит на `now-30m`, а атака была ранее, увеличь окно (`WINDOW="now-2h"`).  
- При ошибках Elasticsearch (HTTP-коды 4xx/5xx) чекеры завершатся с кодом 2 — проверь доступность кластера и корректность index pattern.

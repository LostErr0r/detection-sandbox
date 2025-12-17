<!-- Обзор -->

# detection-sandbox

`detection-sandbox` — учебный стенд для практики по обнаружению атак: разворачивает ELK (Elasticsearch, Logstash, Kibana, Filebeat) и уязвимое приложение OWASP Juice Shop, создаёт индексы и дашборды, а также даёт готовые сценарии атак и проверки их фиксации в логах.

## Что входит

- **Стенд наблюдения**: Elasticsearch + Kibana + Logstash + Filebeat, разворачиваемые через Docker Compose.  
- **Тестовое приложение**: OWASP Juice Shop, откуда собираются логи доступа.  
- **Набор атак**: веб-атаки (bruteforce, SQLi, XSS, dirsearch) и сценарии на `auditd` (cron, authorized_keys, sudo, useradd).  
- **Проверки**: bash-скрипты, которые обращаются в Elasticsearch и показывают, зафиксировались ли события за последние 30 минут.  
- **Дашборды и шаблоны индексов**: `export.ndjson` и готовые index template для `juice-shop-access-*` и `system-audit-*`.

## Как пользоваться

1. Подготовь окружение через `./setup.sh` (Docker, auditd, зависимости).
2. Запусти стенд: `make deploy`.
3. В браузере открой Kibana (`http://localhost:5601`) и Juice Shop (`http://localhost:3000`).
4. Запусти одну из атак (`make attack-*`), затем проверь её попадание в Elasticsearch (`make check-*`).

Детальные инструкции по развёртыванию — в разделе [Быстрый старт](quickstart.md), описание компонентов — в [Архитектуре](architecture.md), атаки и проверки — в разделах [Атаки](attacks.md) и [Проверки](checks.md), а типовые проблемы собраны в [Troubleshooting](troubleshooting.md).
проверки — в разделах [Атаки](attacks.md) и [Проверки](checks.md), а типовые проблемы собраны в [Troubleshooting](troubleshooting.md).


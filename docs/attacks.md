<!-- Сценарии атак -->

# Атаки

В репозитории есть готовые скрипты для генерации событий, которые затем должны появиться в Elasticsearch. Запускать их лучше через цели `make attack-*`, чтобы использовать пути и параметры по умолчанию.

## Веб-атаки против OWASP Juice Shop

Все веб-сценарии используют `http://localhost:3000` и логи пишутся в индекс `juice-shop-access-*`.

| Команда | Что делает | Где лежит |
| --- | --- | --- |
| `make attack-bruteforce` | Подбирает пароль к `POST /rest/user/login` для пользователя `admin@juice-sh.op` по вордлисту. | `attacks/web/bruteforce/bruteforce.sh` |
| `make attack-sqli` | Прогоняет список SQLi payload-ов в параметре email на `POST /rest/user/login`. | `attacks/web/sqli/sqli-login.sh` |
| `make attack-xss` | Отправляет XSS-пейлоады в параметр `q` поиска товаров `GET /rest/products/search`. | `attacks/web/xss/xss_script.sh` |
| `make attack-dirsearch` | Запускает `gobuster dir` по каталогу приложения, исключая HTTP 200. Требует установленный `gobuster`. | `attacks/web/dirsearch/dirsearch.sh` |

### Советы

- Если Juice Shop работает не на `localhost:3000`, скорректируй `TARGET`/`TARGET_URL` в соответствующих скриптах.  
- В `dirsearch.sh` можно поменять вордлист (`dirsearch.txt`) или количество потоков (`THREADS`).  
- Между запросами в скриптах уже есть небольшая задержка, чтобы не перегружать стенд.

## Сценарии для auditd

Эти атаки меняют системные файлы/учётки и требуют `sudo`. События должны индексироваться в `system-audit-*`.

| Команда | Что делает | Где лежит |
| --- | --- | --- |
| `make attack-auditd-cron-add` | Создаёт файл задания `/etc/cron.d/evil-job` с запуском `/tmp/evil.sh`. | `attacks/auditd/cron-job-T1053/cron_add.sh` |
| `make attack-auditd-cron-remove` | Удаляет созданный cron-файл. | `attacks/auditd/cron-job-T1053/cron_remove.sh` |
| `make attack-auditd-authkeys` | Добавляет тестовый ключ в `~/.ssh/authorized_keys`. | `attacks/auditd/authorized_keys-T1098/authorized_keys.sh` |
| `make attack-auditd-sudo` | Выполняет подозрительную команду через `sudo`. | `attacks/auditd/sudo-T1078/sudo_suspicious.sh` |
| `make attack-auditd-useradd` | Добавляет локального пользователя `eviluser` с домашним каталогом. | `attacks/auditd/useradd-T1098/useradd.sh` |
| `make attack-auditd` | Запускает все сценарии в правильном порядке (cron add → remove → authkeys → sudo → useradd). | цель `attack-auditd` в `Makefile` |

### Советы

- Перед запуском убедись, что auditd активен и правила из `setup.sh` подгружены (`sudo ausearch -k cron_changes` и т.п.).  
- Скрипты аккуратно используют `sudo`. Если тестируешь в контейнере/VM без sudo — скорректируй команды или пути.

## Что дальше

После любой атаки запускай соответствующий чекер из раздела [Проверки](checks.md), чтобы убедиться, что события попали в Elasticsearch, а затем открывай Discover/дашборды в Kibana для ручного анализа.
=======
diff --git a/docs/attacks.md b/docs/attacks.md
index e69de29bb2d1d6434b8b29ae775ad8c2e48c5391..55e8abad1202bc6b19d0bb774bbe3527a8187895 100644
--- a/docs/attacks.md
+++ b/docs/attacks.md
@@ -0,0 +1,44 @@
+<!-- Сценарии атак -->
+
+# Атаки
+
+В репозитории есть готовые скрипты для генерации событий, которые затем должны появиться в Elasticsearch. Запускать их лучше через цели `make attack-*`, чтобы использовать пути и параметры по умолчанию.
+
+## Веб-атаки против OWASP Juice Shop
+
+Все веб-сценарии используют `http://localhost:3000` и логи пишутся в индекс `juice-shop-access-*`.
+
+| Команда | Что делает | Где лежит |
+| --- | --- | --- |
+| `make attack-bruteforce` | Подбирает пароль к `POST /rest/user/login` для пользователя `admin@juice-sh.op` по вордлисту. | `attacks/web/bruteforce/bruteforce.sh` |
+| `make attack-sqli` | Прогоняет список SQLi payload-ов в параметре email на `POST /rest/user/login`. | `attacks/web/sqli/sqli-login.sh` |
+| `make attack-xss` | Отправляет XSS-пейлоады в параметр `q` поиска товаров `GET /rest/products/search`. | `attacks/web/xss/xss_script.sh` |
+| `make attack-dirsearch` | Запускает `gobuster dir` по каталогу приложения, исключая HTTP 200. Требует установленный `gobuster`. | `attacks/web/dirsearch/dirsearch.sh` |
+
+### Советы
+
+- Если Juice Shop работает не на `localhost:3000`, скорректируй `TARGET`/`TARGET_URL` в соответствующих скриптах.  
+- В `dirsearch.sh` можно поменять вордлист (`dirsearch.txt`) или количество потоков (`THREADS`).  
+- Между запросами в скриптах уже есть небольшая задержка, чтобы не перегружать стенд.
+
+## Сценарии для auditd
+
+Эти атаки меняют системные файлы/учётки и требуют `sudo`. События должны индексироваться в `system-audit-*`.
+
+| Команда | Что делает | Где лежит |
+| --- | --- | --- |
+| `make attack-auditd-cron-add` | Создаёт файл задания `/etc/cron.d/evil-job` с запуском `/tmp/evil.sh`. | `attacks/auditd/cron-job-T1053/cron_add.sh` |
+| `make attack-auditd-cron-remove` | Удаляет созданный cron-файл. | `attacks/auditd/cron-job-T1053/cron_remove.sh` |
+| `make attack-auditd-authkeys` | Добавляет тестовый ключ в `~/.ssh/authorized_keys`. | `attacks/auditd/authorized_keys-T1098/authorized_keys.sh` |
+| `make attack-auditd-sudo` | Выполняет подозрительную команду через `sudo`. | `attacks/auditd/sudo-T1078/sudo_suspicious.sh` |
+| `make attack-auditd-useradd` | Добавляет локального пользователя `eviluser` с домашним каталогом. | `attacks/auditd/useradd-T1098/useradd.sh` |
+| `make attack-auditd` | Запускает все сценарии в правильном порядке (cron add → remove → authkeys → sudo → useradd). | цель `attack-auditd` в `Makefile` |
+
+### Советы
+
+- Перед запуском убедись, что auditd активен и правила из `setup.sh` подгружены (`sudo ausearch -k cron_changes` и т.п.).  
+- Скрипты аккуратно используют `sudo`. Если тестируешь в контейнере/VM без sudo — скорректируй команды или пути.
+
+## Что дальше
+
+После любой атаки запускай соответствующий чекер из раздела [Проверки](checks.md), чтобы убедиться, что события попали в Elasticsearch, а затем открывай Discover/дашборды в Kibana для ручного анализа.


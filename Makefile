ROOT := $(shell pwd)

ELK_COMPOSE := $(ROOT)/docker/docker-compose.yml
JS_COMPOSE  := $(ROOT)/app/juice-shop/docker-compose.yml

ES := http://localhost:9200

.PHONY: up down restart ps deploy templates \
        attack-bruteforce attack-sqli attack-xss attack-dirsearch \
        check-bruteforce check-sqli check-xss check-dirsearch

up:
	docker compose -f $(ELK_COMPOSE) up -d
	docker compose -f $(JS_COMPOSE) up -d

down:
	docker compose -f $(JS_COMPOSE) down
	docker compose -f $(ELK_COMPOSE) down

restart: down up

ps:
	docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

deploy:
	$(ROOT)/iac/scripts/deploy.sh


# --- Attacks (используем твои текущие скрипты) ---
attack-bruteforce:
	$(ROOT)/attacks/web/bruteforce/bruteforce.sh

attack-sqli:
	$(ROOT)/attacks/web/sqli/sqli-login.sh

attack-xss:
	$(ROOT)/attacks/web/xss/xss_script.sh

attack-dirsearch:
	$(ROOT)/attacks/web/dirsearch/dirsearch.sh

# --- Checks (через Elasticsearch) ---
check-bruteforce:
	$(ROOT)/iac/scripts/check-juice-login-traces.sh

check-sqli:
	$(ROOT)/iac/scripts/check-juice-sqli-traces.sh

check-xss:
	$(ROOT)/iac/scripts/check-juice-xss-traces.sh

check-dirsearch:
	$(ROOT)/iac/scripts/check-juice-dirsearch-traces.sh

# -------------------------------
# Auditd attacks + checks
# -------------------------------
AUDITD_DIR := attacks/auditd
AUDITD_CRON_DIR := $(AUDITD_DIR)/cron-job-T1053
AUDITD_AUTHKEYS_DIR := $(AUDITD_DIR)/authorized_keys-T1098
AUDITD_SUDO_DIR := $(AUDITD_DIR)/sudo-T1078
AUDITD_USERADD_DIR := $(AUDITD_DIR)/useradd-T1098

.PHONY: attack-auditd attack-auditd-cron-add attack-auditd-cron-remove \
        attack-auditd-authkeys attack-auditd-sudo attack-auditd-useradd \
        check-auditd

# Запустить ВСЕ auditd сценарии (в правильном порядке: add -> remove)
attack-auditd: attack-auditd-cron-add attack-auditd-cron-remove attack-auditd-authkeys attack-auditd-sudo attack-auditd-useradd

# --- Attacks auditd
attack-auditd-cron-add:
	bash ./$(AUDITD_CRON_DIR)/cron_add.sh

attack-auditd-cron-remove:
	bash ./$(AUDITD_CRON_DIR)/cron_remove.sh

attack-auditd-authkeys:
	bash ./$(AUDITD_AUTHKEYS_DIR)/authorized_keys.sh

attack-auditd-sudo:
	bash ./$(AUDITD_SUDO_DIR)/sudo_suspicious.sh

attack-auditd-useradd:
	bash ./$(AUDITD_USERADD_DIR)/useradd.sh

check-auditd:
	bash ./iac/scripts/check-auditd-check-all.sh

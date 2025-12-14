#!/usr/bin/env bash
set -euo pipefail

# ---- helpers ----
log() { echo -e "\n[+] $*\n"; }
need_sudo() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
      echo "[-] sudo не найден. Запусти скрипт от root или установи sudo."
      exit 1
    fi
  fi
}
sudo_run() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then sudo "$@"; else "$@"; fi
}

need_sudo

# ---- vars ----
ESDATA_DIR="${HOME}/detection-sandbox/config/elasticsearch/esdata"
AUDIT_RULES_FILE="/etc/audit/rules.d/99-local.rules"

# Пользователь, которому дадим доступ к каталогу (по умолчанию текущий)
TARGET_USER="${SUDO_USER:-$USER}"

log "Обновление системы (apt update && apt upgrade)"
sudo_run apt update
sudo_run apt upgrade -y

log "Установка make и gobuster"
sudo_run apt install -y make gobuster

log "Создание каталога для Elasticsearch data и выставление прав"
mkdir -p "${ESDATA_DIR}"
sudo_run chown -R 1000:1000 "${ESDATA_DIR}"
sudo_run chmod -R 775 "${ESDATA_DIR}"

log "Установка зависимостей для репозитория Docker"
sudo_run apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

log "Добавление GPG ключа Docker"
sudo_run mkdir -p /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo_run gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

log "Добавление репозитория Docker"
CODENAME="$(lsb_release -cs)"
ARCH="$(dpkg --print-architecture)"
echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  | sudo_run tee /etc/apt/sources.list.d/docker.list >/dev/null

log "Установка Docker Engine"
sudo_run apt update
sudo_run apt install -y docker-ce docker-ce-cli containerd.io

log "Установка docker compose plugin (v2+)"
sudo_run apt install -y docker-compose-plugin

log "Добавление пользователя '${TARGET_USER}' в группу docker"
sudo_run usermod -aG docker "${TARGET_USER}"

log "Установка auditd и plugins, включение сервиса"
sudo_run apt install -y auditd audispd-plugins
sudo_run systemctl enable --now auditd

log "Создание/обновление файла правил auditd: ${AUDIT_RULES_FILE}"
# ВАЖНО: путь /home/sbykov/.ssh/authorized_keys оставлен как в твоём примере.
# Если нужно автоматически подставлять текущего пользователя — смотри комментарий ниже.
sudo_run tee "${AUDIT_RULES_FILE}" >/dev/null <<'EOF'
# 1) Изменения cron
-w /etc/cron.d/       -p rwa -k cron_changes
-w /etc/crontab       -p rwa -k cron_changes
-w /var/spool/cron/   -p rwa -k cron_changes

# 2) Изменения SSH authorized_keys (персистентность через T1098)
-w /home/sbykov/.ssh/authorized_keys -p rwa -k ssh_authkeys

# 3) Выполнение sudo с командами (контроль execve)
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/sudo -k sudo_cmd_64
-a always,exit -F arch=b32 -S execve -F exe=/usr/bin/sudo -k sudo_cmd_32

# 4) Изменение /etc/passwd
-w /etc/passwd -p rwa -k passwd_changes
-w /etc/shadow -p rwa -k shadow_changes
EOF

log "Загрузка правил auditd и перезапуск сервиса"
sudo_run augenrules --load
sudo_run systemctl restart auditd

log "Проверка статуса auditd (кратко)"
sudo_run systemctl --no-pager --full status auditd | sed -n '1,25p'

log "Готово."
echo "[i] ВАЖНО: для применения членства в группе docker нужно перелогиниться (logout/login) или выполнить: newgrp docker"
echo "[i] Проверка: docker version && docker compose version"

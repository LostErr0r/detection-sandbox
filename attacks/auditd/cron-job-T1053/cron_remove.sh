#!/usr/bin/env bash
set -euo pipefail

echo "[T1053.003] REMOVE cron-job (/etc/cron.d/evil-job)"

if [ ! -f /etc/cron.d/evil-job ]; then
  echo "[!] /etc/cron.d/evil-job not found — creating it first so removal is logged."
  sudo bash -c 'echo "* * * * * root /bin/true" > /etc/cron.d/evil-job'
  sudo chmod 600 /etc/cron.d/evil-job
fi

sudo rm -f /etc/cron.d/evil-job

echo "[*] Confirm removed:"
sudo ls -l /etc/cron.d/ | grep evil-job || echo "evil-job not present ✅"

echo "[*] Local verify (ausearch):"
sudo ausearch -k cron_changes -i | grep -E "evil-job|/etc/cron" || true


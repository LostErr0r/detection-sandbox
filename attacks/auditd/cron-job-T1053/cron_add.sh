#!/usr/bin/env bash
set -euo pipefail

echo "[T1053.003] ADD cron-job (/etc/cron.d/evil-job)"

# payload, чтобы cron было что запускать
sudo bash -c 'cat > /tmp/evil.sh <<EOF
#!/bin/bash
echo "evil cron ran at $(date)" >> /tmp/evil-cron.log
EOF
chmod +x /tmp/evil.sh'

# add job
sudo bash -c 'echo "* * * * * root /tmp/evil.sh" > /etc/cron.d/evil-job'
sudo chmod 600 /etc/cron.d/evil-job

echo "[*] Created:"
sudo ls -l /etc/cron.d/evil-job

echo "[*] Local verify (ausearch):"
sudo ausearch -k cron_changes -i | grep -E "evil-job|/etc/cron" || true

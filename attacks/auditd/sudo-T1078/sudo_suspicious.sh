#!/usr/bin/env bash
set -euo pipefail

echo "[T1078/T1068] Run sudo with suspicious command"

# “подозрительно”: выполнение из /tmp
sudo bash -c 'echo "owned $(date)" >> /tmp/sudo-poc.log'

echo "[*] Local verify (ausearch):"
sudo ausearch -k sudo_cmd -i | tail -n 30 || true


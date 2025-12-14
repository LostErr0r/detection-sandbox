#!/usr/bin/env bash
set -euo pipefail

USER="backdoor"

echo "[T1098] Create local user: $USER"

# создаём
sudo useradd -m -s /bin/bash "$USER" || true

echo "[*] Local verify:"
id "$USER" || true
grep "$USER" /etc/passwd || true

echo "[*] Local audit verify (ausearch):"
sudo ausearch -k passwd_changes -x useradd -i | tail -n 50 || true

# cleanup (чтобы стенд не засирать)
sudo userdel -r "$USER" 2>/dev/null || true
echo "[*] Cleanup: userdel -r $USER"

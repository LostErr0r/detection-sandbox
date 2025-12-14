#!/usr/bin/env bash
set -euo pipefail

echo "[T1098/T1574.004] Append SSH key to ~/.ssh/authorized_keys"

mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

echo 'ssh-ed25519 AAAATEST2 attacker@evil' >> ~/.ssh/authorized_keys

echo "[*] Local verify (ausearch):"
sudo ausearch -k ssh_authkeys -i | tail -n 30 || true

